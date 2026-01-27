USE master;
GO

-- 1. Create Database if not exists
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'BikeShopDB')
BEGIN
    CREATE DATABASE BikeShopDB;
    PRINT 'Database BikeShopDB created successfully.';
END
ELSE
BEGIN
    PRINT 'Database BikeShopDB already exists.';
END
GO

USE BikeShopDB;
GO

-- 2. Create Users Table if not exists
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
BEGIN
    CREATE TABLE Users (
        user_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        user_email VARCHAR(255) NOT NULL UNIQUE,
        user_password_hash VARCHAR(255) NOT NULL,
        user_full_name NVARCHAR(100) NOT NULL,
        user_phone_number VARCHAR(15),
        
        -- Role check constraint
        user_role VARCHAR(20) NOT NULL CHECK (user_role IN ('MEMBER', 'INSPECTOR', 'ADMIN')),
        
        -- Using NVARCHAR for is_verified to match Java String type ("PENDING", "VERIFIED")
        is_verified NVARCHAR(20) DEFAULT 'PENDING',
        
        -- Base64 images can be large
        cccd_front NVARCHAR(MAX),
        cccd_back NVARCHAR(MAX),
        
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Table Users created successfully.';
END
ELSE
BEGIN
    PRINT 'Table Users already exists.';
END
GO
