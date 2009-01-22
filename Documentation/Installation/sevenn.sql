-- MySQL dump 10.8
--
-- Host: localhost    Database: sevenn
-- ------------------------------------------------------
-- Server version	4.1.7-standard

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE="NO_AUTO_VALUE_ON_ZERO" */;

--
-- Table structure for table `edge`
--

DROP TABLE IF EXISTS `edge`;
CREATE TABLE `edge` (
  `title` varchar(255) default NULL,
  `edge_id` int(11) NOT NULL auto_increment,
  `in_network` int(11) default NULL,
  `from_node` int(11) default NULL,
  `to_node` int(11) default NULL,
  `weight` text,
  `use_function` int(11) default NULL,
  PRIMARY KEY  (`edge_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `edge`
--


/*!40000 ALTER TABLE `edge` DISABLE KEYS */;
LOCK TABLES `edge` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `edge` ENABLE KEYS */;

--
-- Table structure for table `function`
--

DROP TABLE IF EXISTS `function`;
CREATE TABLE `function` (
  `title` varchar(255) default NULL,
  `function_id` int(11) NOT NULL auto_increment,
  `function` text,
  `notation` enum('infix','prefix','postfix') default 'infix',
  PRIMARY KEY  (`function_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `function`
--


/*!40000 ALTER TABLE `function` DISABLE KEYS */;
LOCK TABLES `function` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `function` ENABLE KEYS */;

--
-- Table structure for table `network`
--

DROP TABLE IF EXISTS `network`;
CREATE TABLE `network` (
  `title` char(255) default NULL,
  `network_id` int(11) NOT NULL auto_increment,
  `type` char(255) default 'iterative',
  PRIMARY KEY  (`network_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `network`
--


/*!40000 ALTER TABLE `network` DISABLE KEYS */;
LOCK TABLES `network` WRITE;
INSERT INTO `network` VALUES ('memory1',5,'iterative');
UNLOCK TABLES;
/*!40000 ALTER TABLE `network` ENABLE KEYS */;

--
-- Table structure for table `node`
--

DROP TABLE IF EXISTS `node`;
CREATE TABLE `node` (
  `title` varchar(255) default NULL,
  `node_id` int(11) NOT NULL auto_increment,
  `in_network` int(11) default NULL,
  `value` int(32) default NULL,
  `use_function` int(11) default NULL,
  PRIMARY KEY  (`node_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `node`
--


/*!40000 ALTER TABLE `node` DISABLE KEYS */;
LOCK TABLES `node` WRITE;
INSERT INTO `node` VALUES ('a1',1,5,NULL,NULL),('a3',4,5,NULL,NULL),('a2',3,5,NULL,NULL),('b1',5,5,NULL,NULL),('b2',6,5,NULL,NULL);
UNLOCK TABLES;
/*!40000 ALTER TABLE `node` ENABLE KEYS */;

--
-- Table structure for table `options_differential`
--

DROP TABLE IF EXISTS `options_differential`;
CREATE TABLE `options_differential` (
  `for_network` int(11) default NULL,
  `solver` enum('ode','matlab','mathematica') default 'ode'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `options_differential`
--


/*!40000 ALTER TABLE `options_differential` DISABLE KEYS */;
LOCK TABLES `options_differential` WRITE;
INSERT INTO `options_differential` VALUES (6,'ode');
UNLOCK TABLES;
/*!40000 ALTER TABLE `options_differential` ENABLE KEYS */;

--
-- Table structure for table `options_iterative`
--

DROP TABLE IF EXISTS `options_iterative`;
CREATE TABLE `options_iterative` (
  `for_network` int(11) default NULL,
  `steps` int(32) default NULL,
  `increment` int(32) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `options_iterative`
--


/*!40000 ALTER TABLE `options_iterative` DISABLE KEYS */;
LOCK TABLES `options_iterative` WRITE;
INSERT INTO `options_iterative` VALUES (5,0,0);
UNLOCK TABLES;
/*!40000 ALTER TABLE `options_iterative` ENABLE KEYS */;

--
-- Table structure for table `variable`
--

DROP TABLE IF EXISTS `variable`;
CREATE TABLE `variable` (
  `title` char(255) default NULL,
  `variable_id` int(11) NOT NULL auto_increment,
  `in_network` int(11) default NULL,
  `value` int(32) default NULL,
  `default_value` int(32) default NULL,
  PRIMARY KEY  (`variable_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `variable`
--


/*!40000 ALTER TABLE `variable` DISABLE KEYS */;
LOCK TABLES `variable` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `variable` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

