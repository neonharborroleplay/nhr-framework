CREATE TABLE IF NOT EXISTS `nhr_characters` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(16) NOT NULL,
  `license` VARCHAR(64) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `charinfo` LONGTEXT NOT NULL,
  `money` LONGTEXT NOT NULL,
  `job` LONGTEXT NOT NULL,
  `gang` LONGTEXT NOT NULL,
  `jobs` LONGTEXT NOT NULL,
  `gangs` LONGTEXT NOT NULL,
  `metadata` LONGTEXT NOT NULL,
  `position` LONGTEXT NOT NULL,
  `last_seen` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_nhr_citizenid` (`citizenid`),
  KEY `idx_nhr_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_bans` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `license` VARCHAR(64) NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `expires_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_bans_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_vehicles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(16) NOT NULL,
  `plate` VARCHAR(12) NOT NULL,
  `model` VARCHAR(64) NOT NULL,
  `props` LONGTEXT NOT NULL,
  `garage` VARCHAR(32) NOT NULL DEFAULT 'legion',
  `state` ENUM('stored','out','impounded') NOT NULL DEFAULT 'stored',
  `fuel` TINYINT UNSIGNED NOT NULL DEFAULT 100,
  `engine` SMALLINT UNSIGNED NOT NULL DEFAULT 1000,
  `body` SMALLINT UNSIGNED NOT NULL DEFAULT 1000,
  `finance_balance` INT UNSIGNED NOT NULL DEFAULT 0,
  `finance_payment` INT UNSIGNED NOT NULL DEFAULT 0,
  `finance_due` TIMESTAMP NULL,
  PRIMARY KEY (`id`), UNIQUE KEY `uq_nhr_plate` (`plate`), KEY `idx_nhr_vehicle_owner` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(16) NOT NULL,
  `kind` VARCHAR(24) NOT NULL,
  `amount` INT UNSIGNED NOT NULL,
  `description` VARCHAR(120) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_transactions_owner` (`citizenid`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_inventories` (
  `inventory_id` VARCHAR(80) NOT NULL,
  `items` LONGTEXT NOT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`inventory_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_societies` (
  `name` VARCHAR(40) NOT NULL,
  `balance` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_society_transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `society` VARCHAR(40) NOT NULL,
  `citizenid` VARCHAR(16) NOT NULL,
  `kind` VARCHAR(20) NOT NULL,
  `amount` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_society_log` (`society`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_evidence` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `evidence_type` VARCHAR(24) NOT NULL,
  `data` LONGTEXT NOT NULL,
  `coords` LONGTEXT NOT NULL,
  `collected_by` VARCHAR(16) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_evidence_open` (`collected_by`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_audit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `actor` VARCHAR(64) NOT NULL,
  `action` VARCHAR(48) NOT NULL,
  `target` VARCHAR(64) NULL,
  `details` LONGTEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_audit_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_reports` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(16) NOT NULL,
  `message` VARCHAR(500) NOT NULL,
  `status` ENUM('open','claimed','closed') NOT NULL DEFAULT 'open',
  `staff` VARCHAR(64) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_reports_status` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_doors` (
  `door_id` VARCHAR(48) NOT NULL,
  `locked` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`door_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_properties` (
  `property_id` VARCHAR(48) NOT NULL,
  `citizenid` VARCHAR(16) NOT NULL,
  `ownership_type` ENUM('owned','rental') NOT NULL DEFAULT 'owned',
  `rent_due` TIMESTAMP NULL,
  `purchased_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`property_id`), KEY `idx_nhr_property_owner` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_property_keys` (
  `property_id` VARCHAR(48) NOT NULL,
  `citizenid` VARCHAR(16) NOT NULL,
  `granted_by` VARCHAR(16) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`property_id`, `citizenid`), KEY `idx_nhr_property_keyholder` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_property_furniture` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `property_id` VARCHAR(48) NOT NULL,
  `model` VARCHAR(64) NOT NULL,
  `x` DECIMAL(10,4) NOT NULL,
  `y` DECIMAL(10,4) NOT NULL,
  `z` DECIMAL(10,4) NOT NULL,
  `heading` DECIMAL(7,3) NOT NULL DEFAULT 0,
  `placed_by` VARCHAR(16) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_furniture_property` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_appearances` (
  `citizenid` VARCHAR(16) NOT NULL,
  `appearance` LONGTEXT NOT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_phone_numbers` (
  `citizenid` VARCHAR(16) NOT NULL,
  `phone_number` VARCHAR(12) NOT NULL,
  PRIMARY KEY (`citizenid`), UNIQUE KEY `uq_nhr_phone_number` (`phone_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_phone_contacts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(16) NOT NULL,
  `name` VARCHAR(48) NOT NULL,
  `phone_number` VARCHAR(12) NOT NULL,
  PRIMARY KEY (`id`), KEY `idx_nhr_contacts_owner` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_phone_messages` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sender` VARCHAR(12) NOT NULL,
  `recipient` VARCHAR(12) NOT NULL,
  `body` VARCHAR(500) NOT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_messages_recipient` (`recipient`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_mdt_reports` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `author` VARCHAR(16) NOT NULL,
  `title` VARCHAR(100) NOT NULL,
  `body` LONGTEXT NOT NULL,
  `suspect` VARCHAR(16) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_mdt_suspect` (`suspect`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_citations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(16) NOT NULL,
  `officer` VARCHAR(16) NOT NULL,
  `amount` INT UNSIGNED NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `paid` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_citations_owner` (`citizenid`, `paid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_warrants` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(16) NOT NULL,
  `officer` VARCHAR(16) NOT NULL,
  `reason` VARCHAR(500) NOT NULL,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_warrants_owner` (`citizenid`, `active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_businesses` (
  `business_id` VARCHAR(48) NOT NULL,
  `label` VARCHAR(80) NOT NULL,
  `owner` VARCHAR(16) NULL,
  `price` INT UNSIGNED NOT NULL,
  `is_open` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`business_id`), KEY `idx_nhr_business_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_invoices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `issuer` VARCHAR(16) NOT NULL,
  `recipient` VARCHAR(16) NOT NULL,
  `society` VARCHAR(40) NULL,
  `amount` INT UNSIGNED NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `status` ENUM('unpaid','paid','cancelled') NOT NULL DEFAULT 'unpaid',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `idx_nhr_invoice_recipient` (`recipient`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_licenses` (
  `citizenid` VARCHAR(16) NOT NULL,
  `license_type` VARCHAR(32) NOT NULL,
  `issued_by` VARCHAR(16) NOT NULL,
  `issued_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`, `license_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_dealer_stock` (
  `model` VARCHAR(64) NOT NULL,
  `stock` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nhr_crafting_progress` (
  `citizenid` VARCHAR(16) NOT NULL,
  `discipline` VARCHAR(32) NOT NULL,
  `xp` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`, `discipline`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
