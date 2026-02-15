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

-- 3. Create Brands Table (Hãng xe)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Brands' AND xtype='U')
BEGIN
    CREATE TABLE Brands (
        brand_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        brand_name VARCHAR(100) NOT NULL UNIQUE,
        brand_logo_url VARCHAR(500),
        brand_origin_country VARCHAR(100),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Table Brands created successfully.';
END
ELSE
BEGIN
    PRINT 'Table Brands already exists.';
END
GO

-- Seed data for Brands
IF EXISTS (SELECT * FROM sysobjects WHERE name='Brands' AND xtype='U')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Brands)
    BEGIN
        INSERT INTO Brands (brand_name, brand_origin_country) VALUES 
            ('Giant', 'Taiwan'),
            ('Merida', 'Taiwan'),
            ('Pinarello', 'Italy'),
            ('Specialized', 'USA'),
            ('Trek', 'USA'),
            ('Others', 'Unknown');
        PRINT 'Seed data for Brands inserted.';
    END
    ELSE
    BEGIN
        PRINT 'Brands table already has data. Skipping seed.';
    END
END
GO

-- 4. Create Categories Table (Loại xe)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Categories' AND xtype='U')
BEGIN
    CREATE TABLE Categories (
        category_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        category_name VARCHAR(100) NOT NULL UNIQUE,
        category_description NVARCHAR(500),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Table Categories created successfully.';
END
ELSE
BEGIN
    PRINT 'Table Categories already exists.';
END
GO

-- Seed data for Categories
IF EXISTS (SELECT * FROM sysobjects WHERE name='Categories' AND xtype='U')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Categories)
    BEGIN
        INSERT INTO Categories (category_name, category_description) VALUES 
            ('Road Bike', N'Xe đạp đường trường'),
            ('Mountain Bike', N'Xe đạp địa hình'),
            ('Gravel Bike', N'Xe đạp đa địa hình'),
            ('City Bike', N'Xe đạp thành phố'),
            ('E-Bike', N'Xe đạp điện'),
            ('Others', N'Loại xe khác');
        PRINT 'Seed data for Categories inserted.';
    END
    ELSE
    BEGIN
        PRINT 'Categories table already has data. Skipping seed.';
    END
END
GO

-- 5. Create BicyclePosts Table (Bài đăng bán xe)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='BicyclePosts' AND xtype='U')
BEGIN
    CREATE TABLE BicyclePosts (
        post_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        
        -- Foreign Keys
        seller_id BIGINT NOT NULL,
        brand_id BIGINT NOT NULL,
        category_id BIGINT NOT NULL,
        
        -- Basic Info
        bicycle_name NVARCHAR(200) NOT NULL,
        bicycle_color NVARCHAR(50),
        price DECIMAL(18,2) NOT NULL,
        bicycle_description NVARCHAR(MAX),
        
        -- Technical Specs
        groupset NVARCHAR(100),           -- Shimano 105, Ultegra, SRAM Force...
        frame_material NVARCHAR(50),      -- Carbon, Aluminum, Steel, Titanium, Other
        brake_type NVARCHAR(30),          -- Rim, Disc, Other
        size VARCHAR(200) CHECK (size IN ('XS (42 - 47) / 147 - 155 cm',
         'S (48 - 52) / 155 - 165 cm', 'M (53 - 55) / 165 - 175 cm',
          'L (56 - 58) / 175 - 183 cm', 'XL (59 - 60) / 183 - 191 cm',
           'XXL (61 - 63) / 191 - 198 cm')),  -- Valid sizes only
        model_year INT,
        
        -- Status (PENDING → ADMIN_APPROVED → AVAILABLE)
        post_status VARCHAR(200) NOT NULL DEFAULT 'PENDING' 
            CHECK (post_status IN ('PENDING', 'ADMIN_APPROVED', 'AVAILABLE', 
             'DEPOSITED', 'SOLD', 'REJECTED', 'DRAFTED')),
        
        -- Timestamps
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        
        -- Foreign Key Constraints
        CONSTRAINT FK_BicyclePosts_Users FOREIGN KEY (seller_id) REFERENCES Users(user_id),
        CONSTRAINT FK_BicyclePosts_Brands FOREIGN KEY (brand_id) REFERENCES Brands(brand_id),
        CONSTRAINT FK_BicyclePosts_Categories FOREIGN KEY (category_id) REFERENCES Categories(category_id)
    );
    PRINT 'Table BicyclePosts created successfully.';
END
ELSE
BEGIN
    PRINT 'Table BicyclePosts already exists.';
END
GO

-- 6. Create BicycleImages Table (Ảnh xe đạp)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='BicycleImages' AND xtype='U')
BEGIN
    CREATE TABLE BicycleImages (
        image_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        
        -- Foreign Key
        post_id BIGINT NOT NULL,
        
        -- Image Info
        image_url VARCHAR(500) NOT NULL,
        
        -- Loại ảnh bắt buộc theo tiêu chí kiểm định
        image_type VARCHAR(50) NOT NULL CHECK (image_type IN (
            'OVERALL_DRIVE_SIDE',      -- Toàn thân phải (bên dĩa)
            'OVERALL_NON_DRIVE_SIDE',  -- Toàn thân trái
            'COCKPIT_AREA',            -- Tay lái
            'DRIVETRAIN_CLOSEUP',      -- Bộ đề
            'FRONT_BRAKE',             -- Phanh trước
            'REAR_BRAKE',              -- Phanh sau
            'DEFECT_POINT'             -- Điểm lỗi (optional)
        )),
        
        is_thumbnail BIT DEFAULT 0,
        
        -- Timestamps
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        
        -- Foreign Key Constraint
        CONSTRAINT FK_BicycleImages_BicyclePosts FOREIGN KEY (post_id) 
            REFERENCES BicyclePosts(post_id) ON DELETE CASCADE
    );
    PRINT 'Table BicycleImages created successfully.';
END
ELSE
BEGIN
    PRINT 'Table BicycleImages already exists.';
END
GO

-- 7. Create InspectionReports Table (Báo cáo kiểm định)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='InspectionReports' AND xtype='U')
BEGIN
    CREATE TABLE InspectionReports (
        report_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        
        -- Foreign Keys
        post_id BIGINT NOT NULL,
        inspector_id BIGINT NOT NULL,
        
        -- Inspection Result
        inspection_result VARCHAR(20) NOT NULL CHECK (inspection_result IN ('PASS', 'FAIL')),
        
        -- Condition Assessment
        overall_condition VARCHAR(50),  -- Excellent, Good, Fair, Poor
        
        -- Notes from Inspector
        notes NVARCHAR(MAX),
        
        -- Timestamps
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        
        -- Foreign Key Constraints
        CONSTRAINT FK_InspectionReports_BicyclePosts FOREIGN KEY (post_id) 
            REFERENCES BicyclePosts(post_id) ON DELETE CASCADE,
        CONSTRAINT FK_InspectionReports_Users FOREIGN KEY (inspector_id) 
            REFERENCES Users(user_id)
    );
    PRINT 'Table InspectionReports created successfully.';
END
ELSE
BEGIN
    PRINT 'Table InspectionReports already exists.';
END
GO

-- 8. Create Wishlists Table (Danh sách yêu thích)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Wishlists' AND xtype='U')
BEGIN
    CREATE TABLE Wishlists (
        wishlist_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        
        -- Foreign Keys
        user_id BIGINT NOT NULL,
        post_id BIGINT NOT NULL,
        
        -- Timestamps
        created_at DATETIME2 DEFAULT GETDATE(),
        
        -- Foreign Key Constraints
        CONSTRAINT FK_Wishlists_Users FOREIGN KEY (user_id) REFERENCES Users(user_id),
        CONSTRAINT FK_Wishlists_BicyclePosts FOREIGN KEY (post_id) 
            REFERENCES BicyclePosts(post_id) ON DELETE CASCADE,
        
        -- Prevent duplicate wishlist entries
        CONSTRAINT UQ_Wishlists_User_Post UNIQUE (user_id, post_id)
    );
    PRINT 'Table Wishlists created successfully.';
END
ELSE
BEGIN
    PRINT 'Table Wishlists already exists.';
END
GO

PRINT '========================================';
PRINT 'All tables created successfully!';
PRINT '========================================';
