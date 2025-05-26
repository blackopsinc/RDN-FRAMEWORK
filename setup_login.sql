-- Create the legacy _login table for compatibility
USE rdn;

DROP TABLE IF EXISTS `_login`;
CREATE TABLE `_login` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user` varchar(64) NOT NULL,
  `pass` varchar(255) NOT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user` (`user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default admin user with password 'changeme123!'
INSERT INTO `_login` (`user`, `pass`) VALUES ('admin', 'changeme123!');

-- Also update the _keys table to use the correct column name
UPDATE `_keys` SET `key_value` = 'default_client_key_value' WHERE `key_name` = 'default_client_key';
UPDATE `_keys` SET `key_value` = 'default_global_key_value' WHERE `key_name` = 'default_global_key';
UPDATE `_keys` SET `key_value` = 'default_session_key_value' WHERE `key_name` = 'default_session_key';
UPDATE `_keys` SET `key_value` = 'default_api_key_value' WHERE `key_name` = 'default_api_key';

-- Fix the key table structure for compatibility
ALTER TABLE `_keys` ADD COLUMN IF NOT EXISTS `key` TEXT;
UPDATE `_keys` SET `key` = `key_value`;
ALTER TABLE `_keys` ADD COLUMN IF NOT EXISTS `type` VARCHAR(32);
UPDATE `_keys` SET `type` = `key_type`;
