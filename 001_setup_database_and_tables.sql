DROP DATABASE IF EXISTS `bigdata`;

CREATE DATABASE `bigdata`;

ALTER DATABASE `bigdata` CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

USE bigdata;

CREATE TABLE `bigdata`.`genders` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  UNIQUE INDEX `name_UNIQUE` (`name` ASC));

CREATE TABLE `federate_states` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `name_UNIQUE` (`name`));

CREATE TABLE `car_manufacturers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `name_UNIQUE` (`name`));

CREATE TABLE `relationships` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`));

CREATE TABLE `bigdata`.`datasets` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `dataset` JSON NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT NOW(),
  `updated_at` TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE now(),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC));

/* data for our generator */

INSERT INTO bigdata.car_manufacturers (name) values ('BMW'), ('Audi'), ('Ford'), ('Porsche'), ('Opel'), ('Mercedes-Benz'), ('Aston Martin'), ('Toyota');
INSERT INTO bigdata.federate_states (name) VALUES ('NRW'), ('Baden-Württemberg'), ('Bayern'), ('Berlin'), ('Bremen'), ('Hamburg'), ('Brandenburg'), ('Hessen'), ('Sachsen'), ('Mecklenburg-Vorpommern'), ('Niedersachsen'), ('Rheinland-Pfalz'), ('Saarland'), ('Sachsen-Anhalt'), ('Schleswig-Holstein'), ('Thüringen');
INSERT INTO bigdata.genders (name) VALUES ('Female'), ('Male');
INSERT INTO bigdata.relationships (name) VALUES ('Single'), ('Married');
