-- MySQL dump 10.11
--
-- Host: localhost    Database: rdn
-- ------------------------------------------------------
-- Server version	8.0.x
-- Enhanced RDN Framework Database Schema v7.0.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Docker Setup and User Management
--
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'changeme';
CREATE USER IF NOT EXISTS 'rdn_user'@'%' IDENTIFIED BY 'rdn_secure_pass';
GRANT SELECT, INSERT, UPDATE, DELETE ON rdn.* TO 'rdn_user'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

--
-- Create Database
--
CREATE DATABASE IF NOT EXISTS rdn CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE rdn;

--
-- Table structure for table `_audit`
--
DROP TABLE IF EXISTS `_audit`;
CREATE TABLE `_audit` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `event_type` varchar(64) NOT NULL,
  `severity` enum('low','medium','high','critical') DEFAULT 'medium',
  `client_ip` varchar(45) NOT NULL,
  `user_agent` text,
  `session_id` varchar(128),
  `user_id` int,
  `host_id` int,
  `command` varchar(512),
  `parameters` json,
  `response_code` int,
  `execution_time` decimal(10,3),
  `data` longtext,
  `checksum` varchar(64),
  PRIMARY KEY (`id`),
  KEY `idx_timestamp` (`timestamp`),
  KEY `idx_event_type` (`event_type`),
  KEY `idx_client_ip` (`client_ip`),
  KEY `idx_severity` (`severity`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_host_id` (`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Table structure for table `_hosts`
--
DROP TABLE IF EXISTS `_hosts`;
CREATE TABLE `_hosts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `type` enum('web','ssh','rdp','api','database','custom') NOT NULL DEFAULT 'web',
  `os` enum('linux','windows','macos','freebsd','other') NOT NULL DEFAULT 'linux',
  `architecture` varchar(32) DEFAULT 'x86_64',
  `username` varchar(64),
  `password_hash` varchar(255),
  `private_key` text,
  `connection_string` varchar(512) NOT NULL,
  `fqdn` varchar(255) NOT NULL,
  `ip_address` varchar(45),
  `port` int DEFAULT 80,
  `group_name` varchar(64) NOT NULL DEFAULT 'default',
  `tags` json,
  `status` enum('active','inactive','maintenance','error') DEFAULT 'active',
  `last_seen` timestamp NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `health_check_url` varchar(512),
  `health_check_interval` int DEFAULT 300,
  `timeout` int DEFAULT 30,
  `retry_count` int DEFAULT 3,
  `ssl_verify` boolean DEFAULT true,
  `notes` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_name` (`name`),
  KEY `idx_type` (`type`),
  KEY `idx_os` (`os`),
  KEY `idx_group` (`group_name`),
  KEY `idx_status` (`status`),
  KEY `idx_last_seen` (`last_seen`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Table structure for table `_keys`
--
DROP TABLE IF EXISTS `_keys`;
CREATE TABLE `_keys` (
  `id` int NOT NULL AUTO_INCREMENT,
  `key_type` enum('client','global','session','api','encryption') NOT NULL,
  `key_name` varchar(128) NOT NULL,
  `key_value` text NOT NULL,
  `algorithm` varchar(32) DEFAULT 'AES-256',
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NULL,
  `last_used` timestamp NULL,
  `usage_count` bigint DEFAULT 0,
  `is_active` boolean DEFAULT true,
  `created_by` int,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_key_name` (`key_name`),
  KEY `idx_key_type` (`key_type`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Table structure for table `_users`
--
DROP TABLE IF EXISTS `_users`;
CREATE TABLE `_users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `salt` varchar(64) NOT NULL,
  `role` enum('admin','operator','viewer','api') DEFAULT 'viewer',
  `permissions` json,
  `two_factor_secret` varchar(32),
  `two_factor_enabled` boolean DEFAULT false,
  `backup_codes` json,
  `failed_login_attempts` int DEFAULT 0,
  `locked_until` timestamp NULL,
  `last_login` timestamp NULL,
  `last_login_ip` varchar(45),
  `password_changed_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `must_change_password` boolean DEFAULT false,
  `api_key` varchar(128),
  `api_key_expires` timestamp NULL,
  `session_timeout` int DEFAULT 3600,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_active` boolean DEFAULT true,
  `notes` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_username` (`username`),
  UNIQUE KEY `unique_email` (`email`),
  UNIQUE KEY `unique_api_key` (`api_key`),
  KEY `idx_role` (`role`),
  KEY `idx_last_login` (`last_login`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Table structure for table `_sessions`
--
DROP TABLE IF EXISTS `_sessions`;
CREATE TABLE `_sessions` (
  `id` varchar(128) NOT NULL,
  `user_id` int NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `user_agent` text,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `last_activity` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  `data` json,
  `is_active` boolean DEFAULT true,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_last_activity` (`last_activity`),
  FOREIGN KEY (`user_id`) REFERENCES `_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Table structure for table `_commands`
--
DROP TABLE IF EXISTS `_commands`;
CREATE TABLE `_commands` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `command_id` varchar(64) NOT NULL,
  `user_id` int NOT NULL,
  `host_id` int NOT NULL,
  `command` text NOT NULL,
  `parameters` json,
  `status` enum('pending','running','completed','failed','timeout') DEFAULT 'pending',
  `priority` enum('low','normal','high','urgent') DEFAULT 'normal',
  `scheduled_at` timestamp NULL,
  `started_at` timestamp NULL,
  `completed_at` timestamp NULL,
  `timeout_seconds` int DEFAULT 300,
  `retry_count` int DEFAULT 0,
  `max_retries` int DEFAULT 3,
  `output` longtext,
  `error_output` longtext,
  `exit_code` int,
  `execution_time` decimal(10,3),
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_command_id` (`command_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_host_id` (`host_id`),
  KEY `idx_status` (`status`),
  KEY `idx_scheduled_at` (`scheduled_at`),
  KEY `idx_created_at` (`created_at`),
  FOREIGN KEY (`user_id`) REFERENCES `_users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`host_id`) REFERENCES `_hosts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Table structure for table `_notifications`
--
DROP TABLE IF EXISTS `_notifications`;
CREATE TABLE `_notifications` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `type` enum('email','webhook','sms','slack','discord') NOT NULL,
  `recipient` varchar(255) NOT NULL,
  `subject` varchar(255),
  `message` text NOT NULL,
  `data` json,
  `status` enum('pending','sent','failed','retry') DEFAULT 'pending',
  `attempts` int DEFAULT 0,
  `max_attempts` int DEFAULT 3,
  `sent_at` timestamp NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `error_message` text,
  PRIMARY KEY (`id`),
  KEY `idx_type` (`type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Table structure for table `_system_config`
--
DROP TABLE IF EXISTS `_system_config`;
CREATE TABLE `_system_config` (
  `id` int NOT NULL AUTO_INCREMENT,
  `config_key` varchar(128) NOT NULL,
  `config_value` text,
  `config_type` enum('string','integer','boolean','json','encrypted') DEFAULT 'string',
  `description` text,
  `is_sensitive` boolean DEFAULT false,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` int,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_config_key` (`config_key`),
  KEY `idx_is_sensitive` (`is_sensitive`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Insert default data
--

-- Default admin user (password: changeme123!)
INSERT INTO `_users` (`username`, `email`, `password_hash`, `salt`, `role`, `permissions`, `must_change_password`) VALUES 
('admin', 'admin@localhost', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'randomsalt123', 'admin', '{"all": true}', true);

-- Default encryption keys
INSERT INTO `_keys` (`key_type`, `key_name`, `key_value`, `algorithm`) VALUES 
('client', 'default_client_key', '', 'AES-256'),
('global', 'default_global_key', '', 'AES-256'),
('session', 'default_session_key', '', 'AES-256'),
('api', 'default_api_key', '', 'AES-256');

-- Sample hosts with enhanced security
INSERT INTO `_hosts` (`name`, `type`, `os`, `connection_string`, `fqdn`, `group_name`, `tags`, `health_check_url`) VALUES 
('localhost', 'web', 'linux', 'http://localhost:8080/server/client?cmd=', 'localhost', 'local', '{"environment": "development", "critical": false}', 'http://localhost:8080/health');

-- System configuration
INSERT INTO `_system_config` (`config_key`, `config_value`, `config_type`, `description`) VALUES 
('system.version', '7.0.0', 'string', 'RDN Framework version'),
('security.session_timeout', '3600', 'integer', 'Default session timeout in seconds'),
('security.max_login_attempts', '5', 'integer', 'Maximum failed login attempts before lockout'),
('security.lockout_duration', '900', 'integer', 'Account lockout duration in seconds'),
('security.password_min_length', '12', 'integer', 'Minimum password length'),
('security.require_2fa', 'false', 'boolean', 'Require two-factor authentication'),
('notifications.enabled', 'true', 'boolean', 'Enable notification system'),
('backup.enabled', 'true', 'boolean', 'Enable automatic backups'),
('backup.retention_days', '7', 'integer', 'Backup retention period in days');

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Enhanced schema completed
