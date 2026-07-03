-- =========================================================================
-- d87-garage Database Install
-- Creates player_vehicles table used by config/config.lua (database.columns)
-- Run once against your server database.
-- =========================================================================

CREATE TABLE IF NOT EXISTS `player_vehicles` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `vehicle` VARCHAR(60) NOT NULL,
    `garage` VARCHAR(50) DEFAULT NULL,
    `state` TINYINT NOT NULL DEFAULT 1,
    `mods` LONGTEXT DEFAULT NULL,
    `plate` VARCHAR(15) NOT NULL,
    `depotprice` INT NOT NULL DEFAULT 0,
    `fuel` INT NOT NULL DEFAULT 100,
    `engine` INT NOT NULL DEFAULT 1000,
    `body` INT NOT NULL DEFAULT 1000,
    PRIMARY KEY (`id`),
    UNIQUE KEY `plate` (`plate`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
