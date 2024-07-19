-- MySQL dump 10.11
--
-- Host: localhost    Database: rdn_server
-- ------------------------------------------------------
-- Server version	5.0.77

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Docker Hack 
--

ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'changeme';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;


--
-- Table structure for table `_audit`
--

DROP TABLE IF EXISTS `_audit`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `_audit` (
  `id` int(32) NOT NULL auto_increment,
  `date` datetime NOT NULL,
  `type` varchar(256) NOT NULL,
  `client` varchar(256) NOT NULL,
  `host` varchar(256) NOT NULL,
  `cmd` varchar(256) NOT NULL,
  `data` longtext,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `_audit`
--

LOCK TABLES `_audit` WRITE;
/*!40000 ALTER TABLE `_audit` DISABLE KEYS */;
/*!40000 ALTER TABLE `_audit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `_hosts`
--

DROP TABLE IF EXISTS `_hosts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `_hosts` (
  `id` int(32) NOT NULL auto_increment,
  `type` varchar(32) NOT NULL,
  `os` varchar(32) NOT NULL,
  `user` varchar(32) NOT NULL,
  `pass` varchar(32) NOT NULL,
  `ip` varchar(64) NOT NULL,
  `fqdn` varchar(32) NOT NULL,
  `group` varchar(32) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `_hosts`
--

LOCK TABLES `_hosts` WRITE;
/*!40000 ALTER TABLE `_hosts` DISABLE KEYS */;
INSERT INTO `_hosts` VALUES (1,'web','nix','','','http://localhost:8080/server/client?cmd=','localhost','web');
/*!40000 ALTER TABLE `_hosts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `_keys`
--

DROP TABLE IF EXISTS `_keys`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `_keys` (
  `id` int(32) NOT NULL auto_increment,
  `type` varchar(256) NOT NULL,
  `key` varchar(256) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `_keys`
--

LOCK TABLES `_keys` WRITE;
/*!40000 ALTER TABLE `_keys` DISABLE KEYS */;
INSERT INTO `_keys` VALUES (1,'client',''),(2,'global',''),(3,'session','');
/*!40000 ALTER TABLE `_keys` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `_login`
--

DROP TABLE IF EXISTS `_login`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `_login` (
  `id` int(32) NOT NULL auto_increment,
  `user` varchar(32) NOT NULL,
  `pass` varchar(32) NOT NULL,
  `email` varchar(32) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `_login`
--

LOCK TABLES `_login` WRITE;
/*!40000 ALTER TABLE `_login` DISABLE KEYS */;
INSERT INTO `_login` VALUES (1,'admin','changeme','root@localhost');
/*!40000 ALTER TABLE `_login` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-10-12 21:22:30


