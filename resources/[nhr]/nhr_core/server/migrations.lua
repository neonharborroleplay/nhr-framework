GlobalState.nhrMigrationsReady=false
local migrations={
    {version='007_phone_mdt',statements={
        [[CREATE TABLE IF NOT EXISTS nhr_phone_numbers (citizenid VARCHAR(16) NOT NULL,phone_number VARCHAR(12) NOT NULL,PRIMARY KEY(citizenid),UNIQUE KEY uq_nhr_phone_number(phone_number)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
        [[CREATE TABLE IF NOT EXISTS nhr_phone_contacts (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,citizenid VARCHAR(16) NOT NULL,name VARCHAR(48) NOT NULL,phone_number VARCHAR(12) NOT NULL,PRIMARY KEY(id),KEY idx_nhr_contacts_owner(citizenid)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
        [[CREATE TABLE IF NOT EXISTS nhr_phone_messages (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,sender VARCHAR(12) NOT NULL,recipient VARCHAR(12) NOT NULL,body VARCHAR(500) NOT NULL,is_read TINYINT(1) NOT NULL DEFAULT 0,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(id),KEY idx_nhr_messages_recipient(recipient,created_at)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
        [[CREATE TABLE IF NOT EXISTS nhr_mdt_reports (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,author VARCHAR(16) NOT NULL,title VARCHAR(100) NOT NULL,body LONGTEXT NOT NULL,suspect VARCHAR(16) NULL,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(id),KEY idx_nhr_mdt_suspect(suspect,created_at)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]
    }},
    {version='008_legal',statements={
        [[CREATE TABLE IF NOT EXISTS nhr_citations (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,citizenid VARCHAR(16) NOT NULL,officer VARCHAR(16) NOT NULL,amount INT UNSIGNED NOT NULL,reason VARCHAR(255) NOT NULL,paid TINYINT(1) NOT NULL DEFAULT 0,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(id),KEY idx_nhr_citations_owner(citizenid,paid)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
        [[CREATE TABLE IF NOT EXISTS nhr_warrants (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,citizenid VARCHAR(16) NOT NULL,officer VARCHAR(16) NOT NULL,reason VARCHAR(500) NOT NULL,active TINYINT(1) NOT NULL DEFAULT 1,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(id),KEY idx_nhr_warrants_owner(citizenid,active)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]
    }},
    {version='008_vehicle_finance',up=function()
        local columns={finance_balance='INT UNSIGNED NOT NULL DEFAULT 0',finance_payment='INT UNSIGNED NOT NULL DEFAULT 0',finance_due='TIMESTAMP NULL'}
        for name,definition in pairs(columns)do if not MySQL.single.await(('SHOW COLUMNS FROM nhr_vehicles LIKE \'%s\''):format(name))then MySQL.query.await(('ALTER TABLE nhr_vehicles ADD COLUMN %s %s'):format(name,definition))end end
    end},
    {version='009_commerce',statements={
        [[CREATE TABLE IF NOT EXISTS nhr_businesses (business_id VARCHAR(48) NOT NULL,label VARCHAR(80) NOT NULL,owner VARCHAR(16) NULL,price INT UNSIGNED NOT NULL,PRIMARY KEY(business_id),KEY idx_nhr_business_owner(owner)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
        [[CREATE TABLE IF NOT EXISTS nhr_invoices (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,issuer VARCHAR(16) NOT NULL,recipient VARCHAR(16) NOT NULL,society VARCHAR(40) NULL,amount INT UNSIGNED NOT NULL,reason VARCHAR(255) NOT NULL,status ENUM('unpaid','paid','cancelled') NOT NULL DEFAULT 'unpaid',created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(id),KEY idx_nhr_invoice_recipient(recipient,status)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
        [[CREATE TABLE IF NOT EXISTS nhr_licenses (citizenid VARCHAR(16) NOT NULL,license_type VARCHAR(32) NOT NULL,issued_by VARCHAR(16) NOT NULL,issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(citizenid,license_type)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
        [[CREATE TABLE IF NOT EXISTS nhr_dealer_stock (model VARCHAR(64) NOT NULL,stock INT UNSIGNED NOT NULL DEFAULT 0,PRIMARY KEY(model)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
        [[CREATE TABLE IF NOT EXISTS nhr_crafting_progress (citizenid VARCHAR(16) NOT NULL,discipline VARCHAR(32) NOT NULL,xp INT UNSIGNED NOT NULL DEFAULT 0,PRIMARY KEY(citizenid,discipline)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]
    }},
    {version='010_operations',up=function()
        if not MySQL.single.await("SHOW COLUMNS FROM nhr_businesses LIKE 'is_open'")then
            MySQL.query.await('ALTER TABLE nhr_businesses ADD COLUMN is_open TINYINT(1) NOT NULL DEFAULT 0 AFTER price')
        end
    end},
    {version='011_civilian',statements={
        [[CREATE TABLE IF NOT EXISTS nhr_property_keys (property_id VARCHAR(48) NOT NULL,citizenid VARCHAR(16) NOT NULL,granted_by VARCHAR(16) NOT NULL,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(property_id,citizenid),KEY idx_nhr_property_keyholder(citizenid)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]
    }},
    {version='012_property_life',statements={
        [[CREATE TABLE IF NOT EXISTS nhr_property_furniture (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,property_id VARCHAR(48) NOT NULL,model VARCHAR(64) NOT NULL,x DECIMAL(10,4) NOT NULL,y DECIMAL(10,4) NOT NULL,z DECIMAL(10,4) NOT NULL,heading DECIMAL(7,3) NOT NULL DEFAULT 0,placed_by VARCHAR(16) NOT NULL,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(id),KEY idx_nhr_furniture_property(property_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]
    }},
    {version='013_leases',up=function()
        if not MySQL.single.await("SHOW COLUMNS FROM nhr_properties LIKE 'ownership_type'")then MySQL.query.await("ALTER TABLE nhr_properties ADD COLUMN ownership_type ENUM('owned','rental') NOT NULL DEFAULT 'owned' AFTER citizenid")end
        if not MySQL.single.await("SHOW COLUMNS FROM nhr_properties LIKE 'rent_due'")then MySQL.query.await('ALTER TABLE nhr_properties ADD COLUMN rent_due TIMESTAMP NULL AFTER ownership_type')end
    end}
}

MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS nhr_schema_migrations (version VARCHAR(64) NOT NULL,applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(version)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    for _,migration in ipairs(migrations)do
        if not MySQL.scalar.await('SELECT 1 FROM nhr_schema_migrations WHERE version=?',{migration.version})then
            local ok,err=pcall(function()
                for _,statement in ipairs(migration.statements or{})do MySQL.query.await(statement)end
                if migration.up then migration.up()end
            end)
            if ok then MySQL.insert.await('INSERT INTO nhr_schema_migrations (version) VALUES (?)',{migration.version})
            else print(('[NHR] migration %s failed: %s'):format(migration.version,err))end
        end
    end
    GlobalState.nhrMigrationsReady=true
end)
