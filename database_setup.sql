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

        -- Unique constraint: user can only add a post once
        CONSTRAINT UQ_Wishlists_User_Post UNIQUE (user_id, post_id),

        -- Foreign Key Constraints
        CONSTRAINT FK_Wishlists_Users FOREIGN KEY (user_id) REFERENCES Users(user_id),
        CONSTRAINT FK_Wishlists_BicyclePosts FOREIGN KEY (post_id)
            REFERENCES BicyclePosts(post_id) ON DELETE CASCADE
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

-- Create Provinces Table
CREATE TABLE Provinces (
    province_code VARCHAR(10) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    name_with_type NVARCHAR(150) NOT NULL,
    type VARCHAR(20) NOT NULL
);

-- Create Communes Table
CREATE TABLE Communes (
    commune_code VARCHAR(10) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    name_with_type NVARCHAR(150) NOT NULL,
    type VARCHAR(20) NOT NULL,
    province_code VARCHAR(10) NOT NULL,
    CONSTRAINT FK_Communes_Provinces FOREIGN KEY (province_code) REFERENCES Provinces(province_code)
);

-- Insert Provinces
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('11', N'Hà Nội', N'Thành phố Hà Nội', 'thanh-pho');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('12', N'Hồ Chí Minh', N'Thành phố Hồ Chí Minh', 'thanh-pho');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('13', N'Đà Nẵng', N'Thành phố Đà Nẵng', 'thanh-pho');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('14', N'Hải Phòng', N'Thành phố Hải Phòng', 'thanh-pho');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('15', N'Cần Thơ', N'Thành phố Cần Thơ', 'thanh-pho');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('16', N'Huế', N'Thành phố Huế', 'thanh-pho');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('17', N'An Giang', N'Tỉnh An Giang', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('18', N'Bắc Ninh', N'Tỉnh Bắc Ninh', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('19', N'Cà Mau', N'Tỉnh Cà Mau', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('20', N'Cao Bằng', N'Tỉnh Cao Bằng', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('21', N'Đắk Lắk', N'Tỉnh Đắk Lắk', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('22', N'Điện Biên', N'Tỉnh Điện Biên', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('23', N'Đồng Nai', N'Tỉnh Đồng Nai', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('24', N'Đồng Tháp', N'Tỉnh Đồng Tháp', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('25', N'Gia Lai', N'Tỉnh Gia Lai', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('26', N'Hà Tĩnh', N'Tỉnh Hà Tĩnh', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('27', N'Hưng Yên', N'Tỉnh Hưng Yên', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('28', N'Khánh Hòa', N'Tỉnh Khánh Hòa', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('29', N'Lai Châu', N'Tỉnh Lai Châu', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('30', N'Lâm Đồng', N'Tỉnh Lâm Đồng', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('31', N'Lạng Sơn', N'Tỉnh Lạng Sơn', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('32', N'Lào Cai', N'Tỉnh Lào Cai', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('33', N'Nghệ An', N'Tỉnh Nghệ An', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('34', N'Ninh Bình', N'Tỉnh Ninh Bình', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('35', N'Phú Thọ', N'Tỉnh Phú Thọ', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('36', N'Quảng Ngãi', N'Tỉnh Quảng Ngãi', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('37', N'Quảng Ninh', N'Tỉnh Quảng Ninh', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('38', N'Quảng Trị', N'Tỉnh Quảng Trị', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('39', N'Sơn La', N'Tỉnh Sơn La', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('40', N'Tây Ninh', N'Tỉnh Tây Ninh', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('41', N'Thái Nguyên', N'Tỉnh Thái Nguyên', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('42', N'Thanh Hóa', N'Tỉnh Thanh Hóa', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('43', N'Tuyên Quang', N'Tỉnh Tuyên Quang', 'tinh');
INSERT INTO Provinces (province_code, name, name_with_type, type) VALUES ('44', N'Vĩnh Long', N'Tỉnh Vĩnh Long', 'tinh');

-- Total provinces: 34

-- Insert Communes
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10251', N'Mỹ Đức', N'Xã Mỹ Đức', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1035', N'Phú Diễn', N'Phường Phú Diễn', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10507', N'Định Công', N'Phường Định Công', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10763', N'Bất Bạt', N'Xã Bất Bạt', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11019', N'Vật Lại', N'Xã Vật Lại', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11275', N'Yên Bài', N'Xã Yên Bài', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11531', N'Chương Mỹ', N'Phường Chương Mỹ', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11787', N'Xuân Mai', N'Xã Xuân Mai', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12043', N'Phú Nghĩa', N'Xã Phú Nghĩa', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12299', N'Yên Xuân', N'Xã Yên Xuân', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12555', N'Phúc Lợi', N'Phường Phúc Lợi', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12811', N'Việt Hưng', N'Phường Việt Hưng', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1291', N'Tây Tựu', N'Phường Tây Tựu', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13067', N'Hòa Lạc', N'Xã Hòa Lạc', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13323', N'Thanh Oai', N'Xã Thanh Oai', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13579', N'Bình Minh', N'Xã Bình Minh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13835', N'Dân Hòa', N'Xã Dân Hòa', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14091', N'Ba Đình', N'Phường Ba Đình', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14347', N'Giảng Võ', N'Phường Giảng Võ', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14603', N'Ngọc Hà', N'Phường Ngọc Hà', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14859', N'Cầu Giấy', N'Phường Cầu Giấy', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15115', N'Nghĩa Đô', N'Phường Nghĩa Đô', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15371', N'Phù Đổng', N'Xã Phù Đổng', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1547', N'Thượng Cát', N'Phường Thượng Cát', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15627', N'Hoài Đức', N'Xã Hoài Đức', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15883', N'An Khánh', N'Xã An Khánh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16139', N'Phúc Sơn', N'Xã Phúc Sơn', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16395', N'Sơn Đồng', N'Xã Sơn Đồng', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16651', N'Chuyên Mỹ', N'Xã Chuyên Mỹ', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16907', N'Vĩnh Tuy', N'Phường Vĩnh Tuy', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17163', N'Hồng Hà', N'Phường Hồng Hà', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17419', N'Cửa Nam', N'Phường Cửa Nam', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17675', N'Yên Nghĩa', N'Phường Yên Nghĩa', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17931', N'Hồng Vân', N'Xã Hồng Vân', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1803', N'Xuân Đỉnh', N'Phường Xuân Đỉnh', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18187', N'Vĩnh Hưng', N'Phường Vĩnh Hưng', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18443', N'Bồ Đề', N'Phường Bồ Đề', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18699', N'Kiều Phú', N'Xã Kiều Phú', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18955', N'Phú Cát', N'Xã Phú Cát', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19211', N'Sóc Sơn', N'Xã Sóc Sơn', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19467', N'Kim Anh', N'Xã Kim Anh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19723', N'Nội Bài', N'Xã Nội Bài', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19979', N'Trung Giã', N'Xã Trung Giã', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20235', N'Quốc Oai', N'Xã Quốc Oai', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20491', N'Long Biên', N'Phường Long Biên', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2059', N'Xuân Phương', N'Phường Xuân Phương', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20747', N'Khương Đình', N'Phường Khương Đình', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21003', N'Phú Lương', N'Phường Phú Lương', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21259', N'Dương Nội', N'Phường Dương Nội', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21515', N'Kiến Hưng', N'Phường Kiến Hưng', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21771', N'Hà Đông', N'Phường Hà Đông', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22027', N'Hai Bà Trưng', N'Phường Hai Bà Trưng', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22283', N'Thượng Phúc', N'Xã Thượng Phúc', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22539', N'Thạch Thất', N'Xã Thạch Thất', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22795', N'Hạ Bằng', N'Xã Hạ Bằng', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23051', N'Nam Phù', N'Xã Nam Phù', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2315', N'Đại Xuyên', N'Xã Đại Xuyên', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23307', N'Thanh Trì', N'Xã Thanh Trì', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23563', N'Đại Mỗ', N'Phường Đại Mỗ', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23819', N'Vân Đình', N'Xã Vân Đình', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24075', N'Yên Hòa', N'Phường Yên Hòa', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24331', N'Ô Chợ Dừa', N'Phường Ô Chợ Dừa', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24587', N'Kim Liên', N'Phường Kim Liên', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24843', N'Láng', N'Phường Láng', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25099', N'Đống Đa', N'Phường Đống Đa', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25355', N'Văn Miếu-Quốc Tử Giám', N'Phường Văn Miếu-Quốc Tử Giám', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25611', N'Phú Thượng', N'Phường Phú Thượng', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2571', N'Phương Liệt', N'Phường Phương Liệt', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25867', N'Hoàng Mai', N'Phường Hoàng Mai', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26123', N'Từ Liêm', N'Phường Từ Liêm', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26379', N'Đông Ngạc', N'Phường Đông Ngạc', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26635', N'Hòa Phú', N'Xã Hòa Phú', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('267', N'Minh Châu', N'Xã Minh Châu', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26891', N'Tây Phương', N'Xã Tây Phương', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27147', N'Hòa Xá', N'Xã Hòa Xá', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27403', N'Bát Tràng', N'Xã Bát Tràng', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27659', N'Thuận An', N'Xã Thuận An', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27915', N'Bạch Mai', N'Phường Bạch Mai', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28171', N'Thanh Xuân', N'Phường Thanh Xuân', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2827', N'Tùng Thiện', N'Phường Tùng Thiện', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28427', N'Sơn Tây', N'Phường Sơn Tây', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28683', N'Đan Phượng', N'Xã Đan Phượng', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28939', N'Chương Dương', N'Xã Chương Dương', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29195', N'Phượng Dực', N'Xã Phượng Dực', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29451', N'Ứng Thiên', N'Xã Ứng Thiên', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29707', N'Hồng Sơn', N'Xã Hồng Sơn', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29963', N'Hưng Đạo', N'Xã Hưng Đạo', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30219', N'Tam Hưng', N'Xã Tam Hưng', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30475', N'Ứng Hòa', N'Xã Ứng Hòa', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30731', N'Hát Môn', N'Xã Hát Môn', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3083', N'Đoài Phương', N'Xã Đoài Phương', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30987', N'Phúc Thọ', N'Xã Phúc Thọ', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31243', N'Đa Phúc', N'Xã Đa Phúc', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31499', N'Phúc Lộc', N'Xã Phúc Lộc', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31755', N'Hoàn Kiếm', N'Phường Hoàn Kiếm', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32011', N'Yên Sở', N'Phường Yên Sở', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32267', N'Tây Hồ', N'Phường Tây Hồ', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3339', N'Gia Lâm', N'Xã Gia Lâm', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3595', N'Suối Hai', N'Xã Suối Hai', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3851', N'Ba Vì', N'Xã Ba Vì', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4107', N'Cổ Đô', N'Xã Cổ Đô', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4363', N'Hoàng Liệt', N'Phường Hoàng Liệt', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4619', N'Lĩnh Nam', N'Phường Lĩnh Nam', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4875', N'Tương Mai', N'Phường Tương Mai', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5131', N'Thanh Liệt', N'Phường Thanh Liệt', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('523', N'Ngọc Hồi', N'Xã Ngọc Hồi', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5387', N'Đại Thanh', N'Xã Đại Thanh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5643', N'Thường Tín', N'Xã Thường Tín', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5899', N'Ô Diên', N'Xã Ô Diên', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6155', N'Quảng Bị', N'Xã Quảng Bị', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6411', N'Trần Phú', N'Xã Trần Phú', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6667', N'Liên Minh', N'Xã Liên Minh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6923', N'Thư Lâm', N'Xã Thư Lâm', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7179', N'Đông Anh', N'Xã Đông Anh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7435', N'Phú Xuyên', N'Xã Phú Xuyên', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7691', N'Quảng Oai', N'Xã Quảng Oai', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('779', N'Tây Mỗ', N'Phường Tây Mỗ', 'phuong', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7947', N'Dương Hòa', N'Xã Dương Hòa', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8203', N'Phúc Thịnh', N'Xã Phúc Thịnh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8459', N'Vĩnh Thanh', N'Xã Vĩnh Thanh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8715', N'Thiên Lộc', N'Xã Thiên Lộc', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8971', N'Quang Minh', N'Xã Quang Minh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9227', N'Hương Sơn', N'Xã Hương Sơn', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9483', N'Mê Linh', N'Xã Mê Linh', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9739', N'Tiến Thắng', N'Xã Tiến Thắng', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9995', N'Yên Lãng', N'Xã Yên Lãng', 'xa', '11');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10252', N'Hiệp Bình', N'Phường Hiệp Bình', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1036', N'Khánh Hội', N'Phường Khánh Hội', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10508', N'Linh Xuân', N'Phường Linh Xuân', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10764', N'Bình Trưng', N'Phường Bình Trưng', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11020', N'An Khánh', N'Phường An Khánh', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11276', N'Phú An', N'Phường Phú An', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11532', N'Thuận Giao', N'Phường Thuận Giao', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11788', N'Bình Hòa', N'Phường Bình Hòa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12044', N'Thủ Dầu Một', N'Phường Thủ Dầu Một', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12300', N'Lái Thiêu', N'Phường Lái Thiêu', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12556', N'An Phú', N'Phường An Phú', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12812', N'Rạch Dừa', N'Phường Rạch Dừa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1292', N'Bình Chánh', N'Xã Bình Chánh', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13068', N'Long Hòa', N'Xã Long Hòa', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13324', N'Minh Thạnh', N'Xã Minh Thạnh', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13580', N'Tân Tạo', N'Phường Tân Tạo', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13836', N'Long Nguyên', N'Phường Long Nguyên', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14092', N'Trừ Văn Thố', N'Xã Trừ Văn Thố', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14348', N'Bến Cát', N'Phường Bến Cát', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14604', N'Dầu Tiếng', N'Xã Dầu Tiếng', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14860', N'Tân Khánh', N'Phường Tân Khánh', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15116', N'Tân Uyên', N'Phường Tân Uyên', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15372', N'Phước Hòa', N'Xã Phước Hòa', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1548', N'Vĩnh Lộc', N'Xã Vĩnh Lộc', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15628', N'Chánh Hiệp', N'Phường Chánh Hiệp', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15884', N'Thới Hòa', N'Phường Thới Hòa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16140', N'Tây Nam', N'Phường Tây Nam', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16396', N'Thanh An', N'Xã Thanh An', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16652', N'Tân Nhựt', N'Xã Tân Nhựt', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16908', N'Dĩ An', N'Phường Dĩ An', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17164', N'Tân Đông Hiệp', N'Phường Tân Đông Hiệp', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17420', N'Phú Lợi', N'Phường Phú Lợi', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17676', N'Côn Đảo', N'Đặc Khu Côn Đảo', 'dac-khu', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17932', N'Long Điền', N'Xã Long Điền', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1804', N'Tân Vĩnh Lộc', N'Xã Tân Vĩnh Lộc', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18188', N'Bình Hưng Hòa', N'Phường Bình Hưng Hòa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18444', N'Nhiêu Lộc', N'Phường Nhiêu Lộc', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18700', N'Chợ Quán', N'Phường Chợ Quán', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18956', N'An Đông', N'Phường An Đông', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19212', N'Chợ Lớn', N'Phường Chợ Lớn', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19468', N'Bình Tiên', N'Phường Bình Tiên', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19724', N'Phú Lâm', N'Phường Phú Lâm', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19980', N'Tân Hưng', N'Phường Tân Hưng', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20236', N'Tân Thuận', N'Phường Tân Thuận', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20492', N'Vườn Lài', N'Phường Vườn Lài', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2060', N'An Thới Đông', N'Xã An Thới Đông', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20748', N'Minh Phụng', N'Phường Minh Phụng', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21004', N'Hòa Bình', N'Phường Hòa Bình', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21260', N'Đông Hưng Thuận', N'Phường Đông Hưng Thuận', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21516', N'Trung Mỹ Tây', N'Phường Trung Mỹ Tây', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21772', N'Tân Thới Hiệp', N'Phường Tân Thới Hiệp', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22028', N'Thới An', N'Phường Thới An', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22284', N'An Phú Đông', N'Phường An Phú Đông', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22540', N'Gia Định', N'Phường Gia Định', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22796', N'Bình Thạnh', N'Phường Bình Thạnh', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23052', N'Bình Lợi Trung', N'Phường Bình Lợi Trung', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2316', N'Bình Khánh', N'Xã Bình Khánh', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23308', N'Thạnh Mỹ Tây', N'Phường Thạnh Mỹ Tây', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23564', N'Bình Quới', N'Phường Bình Quới', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23820', N'An Lạc', N'Phường An Lạc', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24076', N'Hạnh Thông', N'Phường Hạnh Thông', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24332', N'An Nhơn', N'Phường An Nhơn', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24588', N'Gò Vấp', N'Phường Gò Vấp', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24844', N'Thông Tây Hội', N'Phường Thông Tây Hội', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25100', N'An Hội Tây', N'Phường An Hội Tây', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25356', N'An Hội Đông', N'Phường An Hội Đông', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25612', N'Đức Nhuận', N'Phường Đức Nhuận', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2572', N'Bàn Cờ', N'Phường Bàn Cờ', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25868', N'Tân Sơn Hòa', N'Phường Tân Sơn Hòa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26124', N'Tân Sơn Nhất', N'Phường Tân Sơn Nhất', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26380', N'Tân Hòa', N'Phường Tân Hòa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26636', N'Bảy Hiền', N'Phường Bảy Hiền', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('268', N'Thạnh An', N'Xã Thạnh An', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26892', N'Bình Lợi', N'Xã Bình Lợi', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27148', N'Hưng Long', N'Xã Hưng Long', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27404', N'An Nhơn Tây', N'Xã An Nhơn Tây', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27660', N'Thái Mỹ', N'Xã Thái Mỹ', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27916', N'Nhuận Đức', N'Xã Nhuận Đức', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28172', N'Tân An Hội', N'Xã Tân An Hội', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2828', N'Xuân Hòa', N'Phường Xuân Hòa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28428', N'Củ Chi', N'Xã Củ Chi', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28684', N'Phú Hòa Đông', N'Xã Phú Hòa Đông', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28940', N'Bình Mỹ', N'Xã Bình Mỹ', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29196', N'Cần Giờ', N'Xã Cần Giờ', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29452', N'Đông Thạnh', N'Xã Đông Thạnh', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29708', N'Hóc Môn', N'Xã Hóc Môn', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29964', N'Xuân Thới Sơn', N'Xã Xuân Thới Sơn', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30220', N'Bà Điểm', N'Xã Bà Điểm', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30476', N'Nhà Bè', N'Xã Nhà Bè', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30732', N'Hiệp Phước', N'Xã Hiệp Phước', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3084', N'Bình Đông', N'Phường Bình Đông', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30988', N'Tam Bình', N'Phường Tam Bình', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31244', N'Phước Long', N'Phường Phước Long', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31500', N'Long Phước', N'Phường Long Phước', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31756', N'Long Trường', N'Phường Long Trường', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32012', N'Cát Lái', N'Phường Cát Lái', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32268', N'Bình Tây', N'Phường Bình Tây', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32524', N'Tân Sơn', N'Phường Tân Sơn', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32780', N'Phú Thọ Hòa', N'Phường Phú Thọ Hòa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33036', N'Tân Phú', N'Phường Tân Phú', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33292', N'Bàu Bàng', N'Xã Bàu Bàng', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3340', N'Phú Thuận', N'Phường Phú Thuận', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33548', N'Tam Thắng', N'Phường Tam Thắng', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33804', N'Phước Thắng', N'Phường Phước Thắng', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34060', N'Bà Rịa', N'Phường Bà Rịa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34316', N'Long Hương', N'Phường Long Hương', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34572', N'Tam Long', N'Phường Tam Long', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34828', N'Phú Mỹ', N'Phường Phú Mỹ', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35084', N'Tân Thành', N'Phường Tân Thành', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35340', N'Tân Phước', N'Phường Tân Phước', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35596', N'Tân Hải', N'Phường Tân Hải', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35852', N'Châu Pha', N'Xã Châu Pha', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3596', N'Tân Mỹ', N'Phường Tân Mỹ', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36108', N'Ngãi Giao', N'Xã Ngãi Giao', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36364', N'Bình Giã', N'Xã Bình Giã', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36620', N'Kim Long', N'Xã Kim Long', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36876', N'Châu Đức', N'Xã Châu Đức', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37132', N'Xuân Sơn', N'Xã Xuân Sơn', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37388', N'Nghĩa Thành', N'Xã Nghĩa Thành', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37644', N'Hồ Tràm', N'Xã Hồ Tràm', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37900', N'Xuyên Mộc', N'Xã Xuyên Mộc', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('38156', N'Hòa Hội', N'Xã Hòa Hội', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('38412', N'Bàu Lâm', N'Xã Bàu Lâm', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3852', N'Phú Định', N'Phường Phú Định', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('38668', N'Đất Đỏ', N'Xã Đất Đỏ', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('38924', N'Long Hải', N'Xã Long Hải', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('39180', N'Phước Hải', N'Xã Phước Hải', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('39436', N'Long Sơn', N'Xã Long Sơn', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('39692', N'Hòa Hiệp', N'Xã Hòa Hiệp', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('39948', N'Bình Châu', N'Xã Bình Châu', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('40204', N'Vũng Tàu', N'Phường Vũng Tàu', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('40460', N'Bình Cơ', N'Phường Bình Cơ', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('40716', N'Bắc Tân Uyên', N'Xã Bắc Tân Uyên', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('40972', N'An Long', N'Xã An Long', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4108', N'Chánh Hưng', N'Phường Chánh Hưng', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('41228', N'Phước Thành', N'Xã Phước Thành', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('41484', N'Bình Dương', N'Phường Bình Dương', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('41740', N'Tân Hiệp', N'Phường Tân Hiệp', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('41996', N'Hòa Lợi', N'Phường Hòa Lợi', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('42252', N'Chánh Phú Hòa', N'Phường Chánh Phú Hòa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('42508', N'Vĩnh Tân', N'Phường Vĩnh Tân', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('42764', N'Đông Hòa', N'Phường Đông Hòa', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('43020', N'Thuận An', N'Phường Thuận An', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4364', N'Long Bình', N'Phường Long Bình', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4620', N'Tăng Nhơn Phú', N'Phường Tăng Nhơn Phú', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4876', N'Bình Tân', N'Phường Bình Tân', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5132', N'Bình Trị Đông', N'Phường Bình Trị Đông', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('524', N'Xóm Chiếu', N'Phường Xóm Chiếu', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5388', N'Phú Giáo', N'Xã Phú Giáo', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5644', N'Bình Hưng', N'Xã Bình Hưng', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5900', N'Thường Tân', N'Xã Thường Tân', 'xa', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6156', N'Phú Nhuận', N'Phường Phú Nhuận', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6412', N'Cầu Kiệu', N'Phường Cầu Kiệu', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6668', N'Tân Bình', N'Phường Tân Bình', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6924', N'Phú Thạnh', N'Phường Phú Thạnh', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7180', N'Tân Định', N'Phường Tân Định', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7436', N'Cầu Ông Lãnh', N'Phường Cầu Ông Lãnh', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7692', N'Sài Gòn', N'Phường Sài Gòn', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('780', N'Vĩnh Hội', N'Phường Vĩnh Hội', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7948', N'Bến Thành', N'Phường Bến Thành', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8204', N'Diên Hồng', N'Phường Diên Hồng', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8460', N'Hòa Hưng', N'Phường Hòa Hưng', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8716', N'Bình Thới', N'Phường Bình Thới', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8972', N'Phú Thọ', N'Phường Phú Thọ', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9228', N'Bình Phú', N'Phường Bình Phú', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9484', N'Tân Sơn Nhì', N'Phường Tân Sơn Nhì', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9740', N'Tây Thạnh', N'Phường Tây Thạnh', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9996', N'Thủ Đức', N'Phường Thủ Đức', 'phuong', '12');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10253', N'Duy Xuyên', N'Xã Duy Xuyên', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1037', N'Thạnh Mỹ', N'Xã Thạnh Mỹ', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10509', N'Thu Bồn', N'Xã Thu Bồn', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10765', N'Điện Bàn', N'Phường Điện Bàn', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11021', N'Điện Bàn Đông', N'Phường Điện Bàn Đông', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11277', N'An Thắng', N'Phường An Thắng', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11533', N'Điện Bàn Bắc', N'Phường Điện Bàn Bắc', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11789', N'Điện Bàn Tây', N'Xã Điện Bàn Tây', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12045', N'Gò Nổi', N'Xã Gò Nổi', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12301', N'Hội An', N'Phường Hội An', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12557', N'Hội An Đông', N'Phường Hội An Đông', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12813', N'Hội An Tây', N'Phường Hội An Tây', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1293', N'Tân Hiệp', N'Xã Tân Hiệp', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13069', N'Đại Lộc', N'Xã Đại Lộc', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13325', N'Hà Nha', N'Xã Hà Nha', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13581', N'Thượng Đức', N'Xã Thượng Đức', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13837', N'Vu Gia', N'Xã Vu Gia', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14093', N'Phú Thuận', N'Xã Phú Thuận', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14349', N'Bến Giằng', N'Xã Bến Giằng', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14605', N'Nam Giang', N'Xã Nam Giang', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14861', N'Đắc Pring', N'Xã Đắc Pring', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15117', N'La Dêê', N'Xã La Dêê', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15373', N'La Êê', N'Xã La Êê', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1549', N'Hoàng Sa', N'Đặc Khu Hoàng Sa', 'dac-khu', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15629', N'Sông Vàng', N'Xã Sông Vàng', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15885', N'Sông Kôn', N'Xã Sông Kôn', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16141', N'Đông Giang', N'Xã Đông Giang', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16397', N'Bến Hiên', N'Xã Bến Hiên', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16653', N'Avương', N'Xã Avương', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16909', N'Tây Giang', N'Xã Tây Giang', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17165', N'Hùng Sơn', N'Xã Hùng Sơn', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17421', N'Hiệp Đức', N'Xã Hiệp Đức', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17677', N'Việt An', N'Xã Việt An', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17933', N'Phước Trà', N'Xã Phước Trà', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1805', N'Quảng Phú', N'Phường Quảng Phú', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18189', N'Khâm Đức', N'Xã Khâm Đức', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18445', N'Phước Năng', N'Xã Phước Năng', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18701', N'Phước Chánh', N'Xã Phước Chánh', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18957', N'Phước Thành', N'Xã Phước Thành', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19213', N'Phước Hiệp', N'Xã Phước Hiệp', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19469', N'Hải Châu', N'Phường Hải Châu', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19725', N'Hòa Cường', N'Phường Hòa Cường', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19981', N'Thanh Khê', N'Phường Thanh Khê', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20237', N'An Khê', N'Phường An Khê', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20493', N'An Hải', N'Phường An Hải', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2061', N'Hương Trà', N'Phường Hương Trà', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20749', N'Sơn Trà', N'Phường Sơn Trà', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21005', N'Ngũ Hành Sơn', N'Phường Ngũ Hành Sơn', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21261', N'Hòa Khánh', N'Phường Hòa Khánh', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21517', N'Liên Chiểu', N'Phường Liên Chiểu', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21773', N'Cẩm Lệ', N'Phường Cẩm Lệ', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22029', N'Hòa Xuân', N'Phường Hòa Xuân', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22285', N'Hòa Vang', N'Xã Hòa Vang', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22541', N'Hòa Tiến', N'Xã Hòa Tiến', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22797', N'Bà Nà', N'Xã Bà Nà', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23053', N'Tam Mỹ', N'Xã Tam Mỹ', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2317', N'Bàn Thạch', N'Phường Bàn Thạch', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23309', N'Tam Anh', N'Xã Tam Anh', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23565', N'Đức Phú', N'Xã Đức Phú', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23821', N'Tam Xuân', N'Xã Tam Xuân', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24077', N'Tam Kỳ', N'Phường Tam Kỳ', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2573', N'Tây Hồ', N'Xã Tây Hồ', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('269', N'Tam Hải', N'Xã Tam Hải', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2829', N'Chiên Đàn', N'Xã Chiên Đàn', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3085', N'Phú Ninh', N'Xã Phú Ninh', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3341', N'Lãnh Ngọc', N'Xã Lãnh Ngọc', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3597', N'Tiên Phước', N'Xã Tiên Phước', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3853', N'Thạnh Bình', N'Xã Thạnh Bình', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4109', N'Sơn Cẩm Hà', N'Xã Sơn Cẩm Hà', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4365', N'Trà Liên', N'Xã Trà Liên', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4621', N'Trà Giáp', N'Xã Trà Giáp', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4877', N'Trà Tân', N'Xã Trà Tân', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5133', N'Trà Đốc', N'Xã Trà Đốc', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('525', N'Núi Thành', N'Xã Núi Thành', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5389', N'Trà My', N'Xã Trà My', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5645', N'Nam Trà My', N'Xã Nam Trà My', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5901', N'Trà Tập', N'Xã Trà Tập', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6157', N'Trà Vân', N'Xã Trà Vân', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6413', N'Trà Linh', N'Xã Trà Linh', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6669', N'Trà Leng', N'Xã Trà Leng', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6925', N'Thăng Bình', N'Xã Thăng Bình', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7181', N'Thăng An', N'Xã Thăng An', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7437', N'Thăng Trường', N'Xã Thăng Trường', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7693', N'Thăng Điền', N'Xã Thăng Điền', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('781', N'Hải Vân', N'Phường Hải Vân', 'phuong', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7949', N'Thăng Phú', N'Xã Thăng Phú', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8205', N'Đồng Dương', N'Xã Đồng Dương', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8461', N'Quế Sơn Trung', N'Xã Quế Sơn Trung', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8717', N'Quế Sơn', N'Xã Quế Sơn', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8973', N'Xuân Phú', N'Xã Xuân Phú', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9229', N'Nông Sơn', N'Xã Nông Sơn', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9485', N'Quế Phước', N'Xã Quế Phước', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9741', N'Duy Nghĩa', N'Xã Duy Nghĩa', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9997', N'Nam Phước', N'Xã Nam Phước', 'xa', '13');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10254', N'Gia Viên', N'Phường Gia Viên', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1038', N'Tân Hưng', N'Phường Tân Hưng', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10510', N'Vĩnh Am', N'Xã Vĩnh Am', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10766', N'Trường Tân', N'Xã Trường Tân', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11022', N'Hồng An', N'Phường Hồng An', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11278', N'An Phong', N'Phường An Phong', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11534', N'Kim Thành', N'Xã Kim Thành', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11790', N'Thiên Hương', N'Phường Thiên Hương', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12046', N'Lưu Kiếm', N'Phường Lưu Kiếm', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12302', N'Hòa Bình', N'Phường Hòa Bình', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12558', N'Nam Triệu', N'Phường Nam Triệu', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12814', N'Việt Khê', N'Xã Việt Khê', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1294', N'Ái Quốc', N'Phường Ái Quốc', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13070', N'Lê Ích Mộc', N'Phường Lê Ích Mộc', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13326', N'An Phú', N'Xã An Phú', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13582', N'Hà Bắc', N'Xã Hà Bắc', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13838', N'Lai Khê', N'Xã Lai Khê', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14094', N'An Hưng', N'Xã An Hưng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14350', N'An Quang', N'Xã An Quang', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14606', N'An Trường', N'Xã An Trường', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14862', N'Kiến Minh', N'Xã Kiến Minh', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15118', N'Nghi Dương', N'Xã Nghi Dương', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15374', N'Tiên Lãng', N'Xã Tiên Lãng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1550', N'An Khánh', N'Xã An Khánh', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15630', N'Chấn Hưng', N'Xã Chấn Hưng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15886', N'Hùng Thắng', N'Xã Hùng Thắng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16142', N'Vĩnh Bảo', N'Xã Vĩnh Bảo', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16398', N'Nguyễn Bỉnh Khiêm', N'Xã Nguyễn Bỉnh Khiêm', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16654', N'Vĩnh Hải', N'Xã Vĩnh Hải', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16910', N'Vĩnh Hòa', N'Xã Vĩnh Hòa', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17166', N'Vĩnh Thịnh', N'Xã Vĩnh Thịnh', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17422', N'Vĩnh Thuận', N'Xã Vĩnh Thuận', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17678', N'Bạch Đằng', N'Phường Bạch Đằng', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17934', N'Hải Dương', N'Phường Hải Dương', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1806', N'Tân Minh', N'Xã Tân Minh', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18190', N'Thành Đông', N'Phường Thành Đông', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18446', N'Nam Đồng', N'Phường Nam Đồng', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18702', N'Chí Linh', N'Phường Chí Linh', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18958', N'Nguyễn Trãi', N'Phường Nguyễn Trãi', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19214', N'Lê Đại Hành', N'Phường Lê Đại Hành', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19470', N'Kinh Môn', N'Phường Kinh Môn', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19726', N'Nguyễn Đại Năng', N'Phường Nguyễn Đại Năng', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19982', N'Phạm Sư Mạnh', N'Phường Phạm Sư Mạnh', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20238', N'Nhị Chiểu', N'Phường Nhị Chiểu', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20494', N'Nam Sách', N'Xã Nam Sách', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2062', N'Hải An', N'Phường Hải An', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20750', N'Thái Tân', N'Xã Thái Tân', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21006', N'Trần Phú', N'Xã Trần Phú', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21262', N'Hợp Tiến', N'Xã Hợp Tiến', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21518', N'Thanh Hà', N'Xã Thanh Hà', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21774', N'Hà Đông', N'Xã Hà Đông', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22030', N'Cẩm Giang', N'Xã Cẩm Giang', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22286', N'Tuệ Tĩnh', N'Xã Tuệ Tĩnh', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22542', N'Tứ Kỳ', N'Xã Tứ Kỳ', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22798', N'Chí Minh', N'Xã Chí Minh', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23054', N'Ninh Giang', N'Xã Ninh Giang', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2318', N'Nam Đồ Sơn', N'Phường Nam Đồ Sơn', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23310', N'Vĩnh Lại', N'Xã Vĩnh Lại', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23566', N'Khúc Thừa Dụ', N'Xã Khúc Thừa Dụ', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23822', N'Tân An', N'Xã Tân An', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24078', N'Hồng Châu', N'Xã Hồng Châu', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24334', N'Thanh Miện', N'Xã Thanh Miện', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24590', N'Bắc Thanh Miện', N'Xã Bắc Thanh Miện', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24846', N'Hải Hưng', N'Xã Hải Hưng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25102', N'Nam Thanh Miện', N'Xã Nam Thanh Miện', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25358', N'An Thành', N'Xã An Thành', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25614', N'Cát Hải', N'Đặc Khu Cát Hải', 'dac-khu', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2574', N'Dương Kinh', N'Phường Dương Kinh', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25870', N'Kiến Thụy', N'Xã Kiến Thụy', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26126', N'Thủy Nguyên', N'Phường Thủy Nguyên', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26382', N'Hồng Bàng', N'Phường Hồng Bàng', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26638', N'Ngô Quyền', N'Phường Ngô Quyền', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26894', N'Lê Chân', N'Phường Lê Chân', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('270', N'Mao Điền', N'Xã Mao Điền', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27150', N'Đồ Sơn', N'Phường Đồ Sơn', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27406', N'Hưng Đạo', N'Phường Hưng Đạo', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27662', N'An Dương', N'Phường An Dương', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27918', N'Tứ Minh', N'Phường Tứ Minh', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28174', N'Chu Văn An', N'Phường Chu Văn An', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2830', N'Đông Hải', N'Phường Đông Hải', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28430', N'Kẻ Sặt', N'Xã Kẻ Sặt', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28686', N'Gia Lộc', N'Xã Gia Lộc', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28942', N'Yết Kiêu', N'Xã Yết Kiêu', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29198', N'Phú Thái', N'Xã Phú Thái', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3086', N'Đường An', N'Xã Đường An', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3342', N'Thượng Hồng', N'Xã Thượng Hồng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3598', N'Bình Giang', N'Xã Bình Giang', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3854', N'Gia Phúc', N'Xã Gia Phúc', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4110', N'An Lão', N'Xã An Lão', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4366', N'Kiến Hải', N'Xã Kiến Hải', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4622', N'Kiến An', N'Phường Kiến An', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4878', N'Phù Liễn', N'Phường Phù Liễn', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5134', N'An Biên', N'Phường An Biên', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('526', N'Việt Hòa', N'Phường Việt Hòa', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5390', N'Quyết Thắng', N'Xã Quyết Thắng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5646', N'Tiên Minh', N'Xã Tiên Minh', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5902', N'Trần Liễu', N'Phường Trần Liễu', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6158', N'Lê Thanh Nghị', N'Phường Lê Thanh Nghị', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6414', N'Thạch Khôi', N'Phường Thạch Khôi', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6670', N'Tân Kỳ', N'Xã Tân Kỳ', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6926', N'Nguyên Giáp', N'Xã Nguyên Giáp', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7182', N'Nam An Phụ', N'Xã Nam An Phụ', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7438', N'Bắc An Phụ', N'Phường Bắc An Phụ', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7694', N'Hà Nam', N'Xã Hà Nam', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('782', N'Cẩm Giàng', N'Xã Cẩm Giàng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7950', N'Hà Tây', N'Xã Hà Tây', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8206', N'Nguyễn Lương Bằng', N'Xã Nguyễn Lương Bằng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8462', N'Lạc Phượng', N'Xã Lạc Phượng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8718', N'Trần Nhân Tông', N'Phường Trần Nhân Tông', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8974', N'Trần Hưng Đạo', N'Phường Trần Hưng Đạo', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9230', N'Đại Sơn', N'Xã Đại Sơn', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9486', N'Bạch Long Vĩ', N'Đặc Khu Bạch Long Vĩ', 'dac-khu', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9742', N'An Hải', N'Phường An Hải', 'phuong', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9998', N'Kiến Hưng', N'Xã Kiến Hưng', 'xa', '14');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10255', N'Vĩnh Tường', N'Xã Vĩnh Tường', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1039', N'Mỹ Phước', N'Xã Mỹ Phước', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10511', N'Vĩnh Viễn', N'Xã Vĩnh Viễn', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10767', N'Xà Phiên', N'Xã Xà Phiên', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11023', N'Lương Tâm', N'Xã Lương Tâm', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11279', N'Long Bình', N'Phường Long Bình', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11535', N'Long Mỹ', N'Phường Long Mỹ', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11791', N'Long Phú 1', N'Phường Long Phú 1', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12047', N'Thạnh Xuân', N'Xã Thạnh Xuân', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12303', N'Tân Hòa', N'Xã Tân Hòa', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12559', N'Trường Long Tây', N'Xã Trường Long Tây', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12815', N'Châu Thành', N'Xã Châu Thành', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1295', N'Thạnh Phú', N'Xã Thạnh Phú', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13071', N'Đông Phước', N'Xã Đông Phước', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13327', N'Phú Hữu', N'Xã Phú Hữu', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13583', N'Đại Thành', N'Phường Đại Thành', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13839', N'Ngã Bảy', N'Phường Ngã Bảy', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14095', N'Tân Bình', N'Xã Tân Bình', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14351', N'Hòa An', N'Xã Hòa An', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14607', N'Phương Bình', N'Xã Phương Bình', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14863', N'Tân Phước Hưng', N'Xã Tân Phước Hưng', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15119', N'Hiệp Hưng', N'Xã Hiệp Hưng', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15375', N'Phụng Hiệp', N'Xã Phụng Hiệp', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1551', N'Thới Hưng', N'Xã Thới Hưng', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15631', N'Thạnh Hòa', N'Xã Thạnh Hòa', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15887', N'Bình Thủy', N'Phường Bình Thủy', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16143', N'Thốt Nốt', N'Phường Thốt Nốt', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16399', N'Thuận Hưng', N'Phường Thuận Hưng', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16655', N'Phú Tâm', N'Xã Phú Tâm', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16911', N'An Ninh', N'Xã An Ninh', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17167', N'Thuận Hòa', N'Xã Thuận Hòa', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17423', N'Hồ Đắc Kiện', N'Xã Hồ Đắc Kiện', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17679', N'Mỹ Tú', N'Xã Mỹ Tú', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17935', N'Long Hưng', N'Xã Long Hưng', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1807', N'Trường Long', N'Xã Trường Long', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18191', N'Mỹ Hương', N'Xã Mỹ Hương', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18447', N'Vĩnh Phước', N'Phường Vĩnh Phước', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18703', N'Vĩnh Châu', N'Phường Vĩnh Châu', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18959', N'Khánh Hòa', N'Phường Khánh Hòa', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19215', N'Ngã Năm', N'Phường Ngã Năm', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19471', N'Mỹ Quới', N'Phường Mỹ Quới', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19727', N'Tân Long', N'Xã Tân Long', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19983', N'Phú Lộc', N'Xã Phú Lộc', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20239', N'Vĩnh Lợi', N'Xã Vĩnh Lợi', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20495', N'Lâm Tân', N'Xã Lâm Tân', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2063', N'Long Tuyền', N'Phường Long Tuyền', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20751', N'Thạnh Thới An', N'Xã Thạnh Thới An', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21007', N'Tài Văn', N'Xã Tài Văn', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21263', N'Liêu Tú', N'Xã Liêu Tú', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21519', N'Lịch Hội Thượng', N'Xã Lịch Hội Thượng', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21775', N'Trần Đề', N'Xã Trần Đề', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22031', N'An Thạnh', N'Xã An Thạnh', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22287', N'Cù Lao Dung', N'Xã Cù Lao Dung', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22543', N'Đại Ngãi', N'Xã Đại Ngãi', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22799', N'Tân Thạnh', N'Xã Tân Thạnh', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23055', N'Long Phú', N'Xã Long Phú', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2319', N'Cái Khế', N'Phường Cái Khế', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23311', N'Nhơn Mỹ', N'Xã Nhơn Mỹ', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23567', N'Phú Lợi', N'Phường Phú Lợi', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23823', N'Sóc Trăng', N'Phường Sóc Trăng', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24079', N'Mỹ Xuyên', N'Phường Mỹ Xuyên', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24335', N'Hòa Tú', N'Xã Hòa Tú', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24591', N'Gia Hòa', N'Xã Gia Hòa', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24847', N'Nhu Gia', N'Xã Nhu Gia', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25103', N'Ngọc Tố', N'Xã Ngọc Tố', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25359', N'Trường Khánh', N'Xã Trường Khánh', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25615', N'An Lạc Thôn', N'Xã An Lạc Thôn', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2575', N'An Bình', N'Phường An Bình', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25871', N'Kế Sách', N'Xã Kế Sách', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26127', N'Thới An Hội', N'Xã Thới An Hội', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26383', N'Đại Hải', N'Xã Đại Hải', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('271', N'Phong Nẫm', N'Xã Phong Nẫm', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2831', N'Tân Lộc', N'Phường Tân Lộc', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3087', N'Ninh Kiều', N'Phường Ninh Kiều', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3343', N'Tân An', N'Phường Tân An', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3599', N'Thới An Đông', N'Phường Thới An Đông', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3855', N'Cái Răng', N'Phường Cái Răng', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4111', N'Hưng Phú', N'Phường Hưng Phú', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4367', N'Ô Môn', N'Phường Ô Môn', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4623', N'Thới Long', N'Phường Thới Long', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4879', N'Phước Thới', N'Phường Phước Thới', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5135', N'Trung Nhứt', N'Phường Trung Nhứt', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('527', N'Lai Hòa', N'Xã Lai Hòa', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5391', N'Phong Điền', N'Xã Phong Điền', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5647', N'Nhơn Ái', N'Xã Nhơn Ái', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5903', N'Thới Lai', N'Xã Thới Lai', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6159', N'Đông Thuận', N'Xã Đông Thuận', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6415', N'Trường Xuân', N'Xã Trường Xuân', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6671', N'Trường Thành', N'Xã Trường Thành', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6927', N'Cờ Đỏ', N'Xã Cờ Đỏ', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7183', N'Đông Hiệp', N'Xã Đông Hiệp', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7439', N'Trung Hưng', N'Xã Trung Hưng', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7695', N'Vĩnh Thạnh', N'Xã Vĩnh Thạnh', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('783', N'Vĩnh Hải', N'Xã Vĩnh Hải', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7951', N'Vĩnh Trinh', N'Xã Vĩnh Trinh', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8207', N'Thạnh An', N'Xã Thạnh An', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8463', N'Thạnh Quới', N'Xã Thạnh Quới', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8719', N'Vị Thanh', N'Phường Vị Thanh', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8975', N'Vị Tân', N'Phường Vị Tân', 'phuong', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9231', N'Hỏa Lựu', N'Xã Hỏa Lựu', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9487', N'Vị Thủy', N'Xã Vị Thủy', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9743', N'Vĩnh Thuận Đông', N'Xã Vĩnh Thuận Đông', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9999', N'Vị Thanh 1', N'Xã Vị Thanh 1', 'xa', '15');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10000', N'A Lưới 4', N'Xã A Lưới 4', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10256', N'A Lưới 5', N'Xã A Lưới 5', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1040', N'Phong Dinh', N'Phường Phong Dinh', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1296', N'Phong Phú', N'Phường Phong Phú', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1552', N'Phong Quảng', N'Phường Phong Quảng', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1808', N'Đan Điền', N'Xã Đan Điền', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2064', N'Quảng Điền', N'Xã Quảng Điền', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2320', N'Hương Trà', N'Phường Hương Trà', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2576', N'Kim Trà', N'Phường Kim Trà', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('272', N'Dương Nỗ', N'Phường Dương Nỗ', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2832', N'Bình Điền', N'Xã Bình Điền', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3088', N'Kim Long', N'Phường Kim Long', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3344', N'Hương An', N'Phường Hương An', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3600', N'Phú Xuân', N'Phường Phú Xuân', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3856', N'Thuận An', N'Phường Thuận An', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4112', N'Hóa Châu', N'Phường Hóa Châu', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4368', N'Mỹ Thượng', N'Phường Mỹ Thượng', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4624', N'Vỹ Dạ', N'Phường Vỹ Dạ', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4880', N'Thuận Hóa', N'Phường Thuận Hóa', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5136', N'An Cựu', N'Phường An Cựu', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('528', N'Phong Điền', N'Phường Phong Điền', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5392', N'Thủy Xuân', N'Phường Thủy Xuân', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5648', N'Phú Vinh', N'Xã Phú Vinh', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5904', N'Phú Hồ', N'Xã Phú Hồ', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6160', N'Phú Vang', N'Xã Phú Vang', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6416', N'Thanh Thủy', N'Phường Thanh Thủy', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6672', N'Hương Thủy', N'Phường Hương Thủy', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6928', N'Phú Bài', N'Phường Phú Bài', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7184', N'Vinh Lộc', N'Xã Vinh Lộc', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7440', N'Hưng Lộc', N'Xã Hưng Lộc', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7696', N'Lộc An', N'Xã Lộc An', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('784', N'Phong Thái', N'Phường Phong Thái', 'phuong', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7952', N'Phú Lộc', N'Xã Phú Lộc', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8208', N'Chân Mây-Lăng Cô', N'Xã Chân Mây-Lăng Cô', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8464', N'Long Quảng', N'Xã Long Quảng', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8720', N'Nam Đông', N'Xã Nam Đông', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8976', N'Khe Tre', N'Xã Khe Tre', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9232', N'A Lưới 1', N'Xã A Lưới 1', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9488', N'A Lưới 2', N'Xã A Lưới 2', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9744', N'A Lưới 3', N'Xã A Lưới 3', 'xa', '16');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10001', N'Núi Cấm', N'Xã Núi Cấm', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10257', N'Ba Chúc', N'Xã Ba Chúc', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1041', N'Vĩnh Thông', N'Phường Vĩnh Thông', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10513', N'Tri Tôn', N'Xã Tri Tôn', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10769', N'Ô Lâm', N'Xã Ô Lâm', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11025', N'Cô Tô', N'Xã Cô Tô', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11281', N'Vĩnh Gia', N'Xã Vĩnh Gia', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11537', N'An Châu', N'Xã An Châu', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11793', N'Bình Hòa', N'Xã Bình Hòa', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12049', N'Cần Đăng', N'Xã Cần Đăng', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12305', N'Vĩnh Hanh', N'Xã Vĩnh Hanh', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12561', N'Vĩnh An', N'Xã Vĩnh An', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12817', N'Cù Lao Giêng', N'Xã Cù Lao Giêng', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1297', N'Vĩnh Tế', N'Phường Vĩnh Tế', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13073', N'Hội An', N'Xã Hội An', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13329', N'Long Điền', N'Xã Long Điền', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13585', N'Chợ Mới', N'Xã Chợ Mới', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13841', N'Nhơn Mỹ', N'Xã Nhơn Mỹ', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14097', N'Long Kiến', N'Xã Long Kiến', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14353', N'Thoại Sơn', N'Xã Thoại Sơn', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14609', N'Óc Eo', N'Xã Óc Eo', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14865', N'Định Mỹ', N'Xã Định Mỹ', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15121', N'Phú Hòa', N'Xã Phú Hòa', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15377', N'Vĩnh Trạch', N'Xã Vĩnh Trạch', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1553', N'Châu Đốc', N'Phường Châu Đốc', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15633', N'Tây Phú', N'Xã Tây Phú', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15889', N'Thổ Châu', N'Đặc Khu Thổ Châu', 'dac-khu', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16145', N'Rạch Giá', N'Phường Rạch Giá', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16401', N'Hà Tiên', N'Phường Hà Tiên', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16657', N'Tô Châu', N'Phường Tô Châu', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16913', N'Giang Thành', N'Xã Giang Thành', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17169', N'Vĩnh Điều', N'Xã Vĩnh Điều', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17425', N'Hòn Đất', N'Xã Hòn Đất', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17681', N'Sơn Kiên', N'Xã Sơn Kiên', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17937', N'Mỹ Thuận', N'Xã Mỹ Thuận', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1809', N'An Phú', N'Xã An Phú', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18193', N'Thạnh Lộc', N'Xã Thạnh Lộc', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18449', N'Châu Thành', N'Xã Châu Thành', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18705', N'Bình An', N'Xã Bình An', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18961', N'Tân Hội', N'Xã Tân Hội', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19217', N'Tân Hiệp', N'Xã Tân Hiệp', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19473', N'Thạnh Đông', N'Xã Thạnh Đông', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19729', N'Giồng Riềng', N'Xã Giồng Riềng', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19985', N'Thạnh Hưng', N'Xã Thạnh Hưng', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20241', N'Long Thạnh', N'Xã Long Thạnh', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20497', N'Hòa Hưng', N'Xã Hòa Hưng', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2065', N'Bình Giang', N'Xã Bình Giang', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20753', N'Ngọc Chúc', N'Xã Ngọc Chúc', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21009', N'Hòa Thuận', N'Xã Hòa Thuận', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21265', N'Định Hòa', N'Xã Định Hòa', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21521', N'Gò Quao', N'Xã Gò Quao', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21777', N'Vĩnh Hòa Hưng', N'Xã Vĩnh Hòa Hưng', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22033', N'Vĩnh Tuy', N'Xã Vĩnh Tuy', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22289', N'Tây Yên', N'Xã Tây Yên', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22545', N'Đông Thái', N'Xã Đông Thái', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22801', N'An Biên', N'Xã An Biên', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23057', N'Đông Hòa', N'Xã Đông Hòa', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2321', N'Bình Sơn', N'Xã Bình Sơn', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23313', N'Tân Thạnh', N'Xã Tân Thạnh', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23569', N'Đông Hưng', N'Xã Đông Hưng', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23825', N'An Minh', N'Xã An Minh', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24081', N'Vân Khánh', N'Xã Vân Khánh', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24337', N'Vĩnh Hòa', N'Xã Vĩnh Hòa', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24593', N'U Minh Thượng', N'Xã U Minh Thượng', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24849', N'Vĩnh Bình', N'Xã Vĩnh Bình', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25105', N'Vĩnh Thuận', N'Xã Vĩnh Thuận', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25361', N'Vĩnh Phong', N'Xã Vĩnh Phong', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25617', N'Phú Quốc', N'Đặc Khu Phú Quốc', 'dac-khu', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2577', N'Mỹ Hòa Hưng', N'Xã Mỹ Hòa Hưng', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25873', N'Kiên Hải', N'Đặc Khu Kiên Hải', 'dac-khu', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26129', N'Kiên Lương', N'Xã Kiên Lương', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('273', N'Hòn Nghệ', N'Xã Hòn Nghệ', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2833', N'Nhơn Hội', N'Xã Nhơn Hội', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3089', N'Phú Hữu', N'Xã Phú Hữu', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3345', N'Tiên Hải', N'Xã Tiên Hải', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3601', N'Long Xuyên', N'Phường Long Xuyên', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3857', N'Bình Đức', N'Phường Bình Đức', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4113', N'Mỹ Thới', N'Phường Mỹ Thới', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4369', N'Vĩnh Hậu', N'Xã Vĩnh Hậu', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4625', N'Khánh Bình', N'Xã Khánh Bình', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4881', N'Tân Châu', N'Phường Tân Châu', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5137', N'Long Phú', N'Phường Long Phú', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('529', N'Sơn Hải', N'Xã Sơn Hải', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5393', N'Tân An', N'Xã Tân An', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5649', N'Châu Phong', N'Xã Châu Phong', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5905', N'Vĩnh Xương', N'Xã Vĩnh Xương', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6161', N'Phú Tân', N'Xã Phú Tân', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6417', N'Phú An', N'Xã Phú An', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6673', N'Bình Thạnh Đông', N'Xã Bình Thạnh Đông', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6929', N'Chợ Vàm', N'Xã Chợ Vàm', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7185', N'Hòa Lạc', N'Xã Hòa Lạc', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7441', N'Phú Lâm', N'Xã Phú Lâm', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7697', N'Mỹ Đức', N'Xã Mỹ Đức', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('785', N'Hòa Điền', N'Xã Hòa Điền', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7953', N'Vĩnh Thạnh Trung', N'Xã Vĩnh Thạnh Trung', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8209', N'Châu Phú', N'Xã Châu Phú', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8465', N'Bình Mỹ', N'Xã Bình Mỹ', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8721', N'Thạnh Mỹ Tây', N'Xã Thạnh Mỹ Tây', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8977', N'Thới Sơn', N'Phường Thới Sơn', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9233', N'Tịnh Biên', N'Phường Tịnh Biên', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9489', N'An Cư', N'Xã An Cư', 'xa', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9745', N'Chi Lăng', N'Phường Chi Lăng', 'phuong', '17');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10002', N'Cao Đức', N'Xã Cao Đức', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10258', N'Đông Cứu', N'Xã Đông Cứu', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1042', N'Kinh Bắc', N'Phường Kinh Bắc', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10514', N'Lương Tài', N'Xã Lương Tài', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10770', N'Lâm Thao', N'Xã Lâm Thao', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11026', N'Trung Chính', N'Xã Trung Chính', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11282', N'Trung Kênh', N'Xã Trung Kênh', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11538', N'Đồng Kỳ', N'Xã Đồng Kỳ', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11794', N'Đại Sơn', N'Xã Đại Sơn', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12050', N'Sơn Động', N'Xã Sơn Động', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12306', N'Tây Yên Tử', N'Xã Tây Yên Tử', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12562', N'Dương Hưu', N'Xã Dương Hưu', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12818', N'Yên Định', N'Xã Yên Định', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1298', N'Võ Cường', N'Phường Võ Cường', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13074', N'An Lạc', N'Xã An Lạc', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13330', N'Vân Sơn', N'Xã Vân Sơn', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13586', N'Biển Động', N'Xã Biển Động', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13842', N'Lục Ngạn', N'Xã Lục Ngạn', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14098', N'Đèo Gia', N'Xã Đèo Gia', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14354', N'Sơn Hải', N'Xã Sơn Hải', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14610', N'Tân Sơn', N'Xã Tân Sơn', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14866', N'Nam Dương', N'Xã Nam Dương', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15122', N'Kiên Lao', N'Xã Kiên Lao', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15378', N'Chũ', N'Phường Chũ', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1554', N'Vũ Ninh', N'Phường Vũ Ninh', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15634', N'Phượng Sơn', N'Phường Phượng Sơn', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15890', N'Lục Sơn', N'Xã Lục Sơn', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16146', N'Trường Sơn', N'Xã Trường Sơn', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16402', N'Cẩm Lý', N'Xã Cẩm Lý', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16658', N'Đông Phú', N'Xã Đông Phú', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16914', N'Nghĩa Phương', N'Xã Nghĩa Phương', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17170', N'Lục Nam', N'Xã Lục Nam', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17426', N'Bắc Lũng', N'Xã Bắc Lũng', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17682', N'Bảo Đài', N'Xã Bảo Đài', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17938', N'Lạng Giang', N'Xã Lạng Giang', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1810', N'Hạp Lĩnh', N'Phường Hạp Lĩnh', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18194', N'Mỹ Thái', N'Xã Mỹ Thái', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18450', N'Kép', N'Xã Kép', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18706', N'Tân Dĩnh', N'Xã Tân Dĩnh', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18962', N'Tiên Lục', N'Xã Tiên Lục', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19218', N'Yên Thế', N'Xã Yên Thế', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19474', N'Bố Hạ', N'Xã Bố Hạ', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19730', N'Xuân Lương', N'Xã Xuân Lương', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19986', N'Tam Tiến', N'Xã Tam Tiến', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20242', N'Tân Yên', N'Xã Tân Yên', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20498', N'Ngọc Thiện', N'Xã Ngọc Thiện', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2066', N'Nam Sơn', N'Phường Nam Sơn', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20754', N'Nhã Nam', N'Xã Nhã Nam', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21010', N'Phúc Hòa', N'Xã Phúc Hòa', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21266', N'Quang Trung', N'Xã Quang Trung', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21522', N'Hợp Thịnh', N'Xã Hợp Thịnh', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21778', N'Hiệp Hòa', N'Xã Hiệp Hòa', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22034', N'Hoàng Vân', N'Xã Hoàng Vân', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22290', N'Xuân Cẩm', N'Xã Xuân Cẩm', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22546', N'Tự Lạn', N'Phường Tự Lạn', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22802', N'Việt Yên', N'Phường Việt Yên', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23058', N'Nếnh', N'Phường Nếnh', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2322', N'Từ Sơn', N'Phường Từ Sơn', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23314', N'Vân Hà', N'Phường Vân Hà', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23570', N'Đồng Việt', N'Xã Đồng Việt', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23826', N'Bắc Giang', N'Phường Bắc Giang', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24082', N'Đa Mai', N'Phường Đa Mai', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24338', N'Tiền Phong', N'Phường Tiền Phong', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24594', N'Tân An', N'Phường Tân An', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24850', N'Yên Dũng', N'Phường Yên Dũng', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25106', N'Tân Tiến', N'Phường Tân Tiến', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25362', N'Cảnh Thụy', N'Phường Cảnh Thụy', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2578', N'Tam Sơn', N'Phường Tam Sơn', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('274', N'Sa Lý', N'Xã Sa Lý', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2834', N'Đồng Nguyên', N'Phường Đồng Nguyên', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3090', N'Phù Khê', N'Phường Phù Khê', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3346', N'Thuận Thành', N'Phường Thuận Thành', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3602', N'Mão Điền', N'Phường Mão Điền', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3858', N'Trạm Lộ', N'Phường Trạm Lộ', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4114', N'Trí Quả', N'Phường Trí Quả', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4370', N'Song Liễu', N'Phường Song Liễu', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4626', N'Ninh Xá', N'Phường Ninh Xá', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4882', N'Quế Võ', N'Phường Quế Võ', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5138', N'Phương Liễu', N'Phường Phương Liễu', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('530', N'Biên Sơn', N'Xã Biên Sơn', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5394', N'Nhân Hòa', N'Phường Nhân Hòa', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5650', N'Đào Viên', N'Phường Đào Viên', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5906', N'Bồng Lai', N'Phường Bồng Lai', 'phuong', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6162', N'Chi Lăng', N'Xã Chi Lăng', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6418', N'Phù Lãng', N'Xã Phù Lãng', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6674', N'Yên Phong', N'Xã Yên Phong', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6930', N'Văn Môn', N'Xã Văn Môn', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7186', N'Tam Giang', N'Xã Tam Giang', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7442', N'Yên Trung', N'Xã Yên Trung', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7698', N'Tam Đa', N'Xã Tam Đa', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('786', N'Tuấn Đạo', N'Xã Tuấn Đạo', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7954', N'Tiên Du', N'Xã Tiên Du', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8210', N'Liên Bão', N'Xã Liên Bão', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8466', N'Tân Chi', N'Xã Tân Chi', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8722', N'Đại Đồng', N'Xã Đại Đồng', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8978', N'Phật Tích', N'Xã Phật Tích', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9234', N'Gia Bình', N'Xã Gia Bình', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9490', N'Nhân Thắng', N'Xã Nhân Thắng', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9746', N'Đại Lai', N'Xã Đại Lai', 'xa', '18');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10003', N'Vĩnh Mỹ', N'Xã Vĩnh Mỹ', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10259', N'Vĩnh Hậu', N'Xã Vĩnh Hậu', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1043', N'Phan Ngọc Hiển', N'Xã Phan Ngọc Hiển', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10515', N'Phước Long', N'Xã Phước Long', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10771', N'Vĩnh Phước', N'Xã Vĩnh Phước', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11027', N'Phong Hiệp', N'Xã Phong Hiệp', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11283', N'Vĩnh Thanh', N'Xã Vĩnh Thanh', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11539', N'Vĩnh Lợi', N'Xã Vĩnh Lợi', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11795', N'Hưng Hội', N'Xã Hưng Hội', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12051', N'Châu Thới', N'Xã Châu Thới', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12307', N'An Xuyên', N'Phường An Xuyên', 'phuong', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12563', N'Tân Thuận', N'Xã Tân Thuận', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12819', N'Tân Tiến', N'Xã Tân Tiến', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1299', N'Đất Mũi', N'Xã Đất Mũi', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13075', N'Trần Phán', N'Xã Trần Phán', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13331', N'Thanh Tùng', N'Xã Thanh Tùng', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13587', N'Quách Phẩm', N'Xã Quách Phẩm', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13843', N'Tân Ân', N'Xã Tân Ân', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14099', N'Khánh Bình', N'Xã Khánh Bình', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14355', N'Khánh Hưng', N'Xã Khánh Hưng', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14611', N'Thới Bình', N'Xã Thới Bình', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14867', N'Trí Phải', N'Xã Trí Phải', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15123', N'Tân Lộc', N'Xã Tân Lộc', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15379', N'Biển Bạch', N'Xã Biển Bạch', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1555', N'Sông Đốc', N'Xã Sông Đốc', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15635', N'Tam Giang', N'Xã Tam Giang', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15891', N'Cái Đôi Vàm', N'Xã Cái Đôi Vàm', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16147', N'Nguyễn Việt Khái', N'Xã Nguyễn Việt Khái', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16403', N'Phú Tân', N'Xã Phú Tân', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1811', N'Đất Mới', N'Xã Đất Mới', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2067', N'Năm Căn', N'Xã Năm Căn', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2323', N'Đầm Dơi', N'Xã Đầm Dơi', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2579', N'Cái Nước', N'Xã Cái Nước', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('275', N'U Minh', N'Xã U Minh', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2835', N'Hưng Mỹ', N'Xã Hưng Mỹ', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3091', N'Lương Thế Trân', N'Xã Lương Thế Trân', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3347', N'Phú Mỹ', N'Xã Phú Mỹ', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3603', N'Hồ Thị Kỷ', N'Xã Hồ Thị Kỷ', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3859', N'Trần Văn Thời', N'Xã Trần Văn Thời', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4115', N'Nguyễn Phích', N'Xã Nguyễn Phích', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4371', N'Khánh An', N'Xã Khánh An', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4627', N'Khánh Lâm', N'Xã Khánh Lâm', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4883', N'Lý Văn Lâm', N'Phường Lý Văn Lâm', 'phuong', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5139', N'Hòa Thành', N'Phường Hòa Thành', 'phuong', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('531', N'Tân Hưng', N'Xã Tân Hưng', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5395', N'Tân Thành', N'Phường Tân Thành', 'phuong', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5651', N'Đá Bạc', N'Xã Đá Bạc', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5907', N'Bạc Liêu', N'Phường Bạc Liêu', 'phuong', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6163', N'Vĩnh Trạch', N'Phường Vĩnh Trạch', 'phuong', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6419', N'Hiệp Thành', N'Phường Hiệp Thành', 'phuong', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6675', N'Giá Rai', N'Phường Giá Rai', 'phuong', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6931', N'Láng Tròn', N'Phường Láng Tròn', 'phuong', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7187', N'Phong Thạnh', N'Xã Phong Thạnh', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7443', N'Hồng Dân', N'Xã Hồng Dân', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7699', N'Vĩnh Lộc', N'Xã Vĩnh Lộc', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('787', N'Tạ An Khương', N'Xã Tạ An Khương', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7955', N'Ninh Thạnh Lợi', N'Xã Ninh Thạnh Lợi', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8211', N'Ninh Quới', N'Xã Ninh Quới', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8467', N'Gành Hào', N'Xã Gành Hào', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8723', N'Định Thành', N'Xã Định Thành', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8979', N'An Trạch', N'Xã An Trạch', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9235', N'Long Điền', N'Xã Long Điền', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9491', N'Đông Hải', N'Xã Đông Hải', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9747', N'Hòa Bình', N'Xã Hòa Bình', 'xa', '19');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10004', N'Bế Văn Đàn', N'Xã Bế Văn Đàn', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10260', N'Độc Lập', N'Xã Độc Lập', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1044', N'Sơn Lộ', N'Xã Sơn Lộ', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10516', N'Quảng Uyên', N'Xã Quảng Uyên', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10772', N'Hạnh Phúc', N'Xã Hạnh Phúc', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11028', N'Minh Khai', N'Xã Minh Khai', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11284', N'Canh Tân', N'Xã Canh Tân', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11540', N'Kim Đồng', N'Xã Kim Đồng', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11796', N'Thạch An', N'Xã Thạch An', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12052', N'Đông Khê', N'Xã Đông Khê', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12308', N'Đức Long', N'Xã Đức Long', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12564', N'Quang Hán', N'Xã Quang Hán', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12820', N'Trà Lĩnh', N'Xã Trà Lĩnh', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1300', N'Hưng Đạo', N'Xã Hưng Đạo', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13076', N'Quang Trung', N'Xã Quang Trung', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13332', N'Đoài Dương', N'Xã Đoài Dương', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13588', N'Trùng Khánh', N'Xã Trùng Khánh', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13844', N'Đàm Thủy', N'Xã Đàm Thủy', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14100', N'Quang Long', N'Xã Quang Long', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14356', N'Đình Phong', N'Xã Đình Phong', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1556', N'Bảo Lạc', N'Xã Bảo Lạc', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1812', N'Cốc Pàng', N'Xã Cốc Pàng', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2068', N'Cô Ba', N'Xã Cô Ba', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2324', N'Khánh Xuân', N'Xã Khánh Xuân', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2580', N'Xuân Trường', N'Xã Xuân Trường', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('276', N'Thục Phán', N'Phường Thục Phán', 'phuong', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2836', N'Huy Giáp', N'Xã Huy Giáp', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3092', N'Quảng Lâm', N'Xã Quảng Lâm', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3348', N'Nam Quang', N'Xã Nam Quang', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3604', N'Lý Bôn', N'Xã Lý Bôn', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3860', N'Bảo Lâm', N'Xã Bảo Lâm', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4116', N'Yên Thổ', N'Xã Yên Thổ', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4372', N'Hạ Lang', N'Xã Hạ Lang', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4628', N'Lý Quốc', N'Xã Lý Quốc', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4884', N'Vinh Quý', N'Xã Vinh Quý', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5140', N'Thanh Long', N'Xã Thanh Long', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('532', N'Tân Giang', N'Phường Tân Giang', 'phuong', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5396', N'Cần Yên', N'Xã Cần Yên', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5652', N'Thông Nông', N'Xã Thông Nông', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5908', N'Trường Hà', N'Xã Trường Hà', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6164', N'Hà Quảng', N'Xã Hà Quảng', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6420', N'Lũng Nặm', N'Xã Lũng Nặm', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6676', N'Tổng Cọt', N'Xã Tổng Cọt', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6932', N'Nam Tuấn', N'Xã Nam Tuấn', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7188', N'Hòa An', N'Xã Hòa An', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7444', N'Bạch Đằng', N'Xã Bạch Đằng', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7700', N'Nguyễn Huệ', N'Xã Nguyễn Huệ', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('788', N'Nùng Trí Cao', N'Phường Nùng Trí Cao', 'phuong', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7956', N'Ca Thành', N'Xã Ca Thành', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8212', N'Phan Thanh', N'Xã Phan Thanh', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8468', N'Thành Công', N'Xã Thành Công', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8724', N'Tam Kim', N'Xã Tam Kim', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8980', N'Nguyên Bình', N'Xã Nguyên Bình', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9236', N'Tĩnh Túc', N'Xã Tĩnh Túc', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9492', N'Minh Tâm', N'Xã Minh Tâm', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9748', N'Phục Hòa', N'Xã Phục Hòa', 'xa', '20');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10005', N'Krông Búk', N'Xã Krông Búk', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10261', N'Cư Pơng', N'Xã Cư Pơng', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1045', N'Đức Bình', N'Xã Đức Bình', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10517', N'Ea Khăl', N'Xã Ea Khăl', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10773', N'Ea Drăng', N'Xã Ea Drăng', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11029', N'Ea Wy', N'Xã Ea Wy', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11285', N'Ea Hiao', N'Xã Ea Hiao', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11541', N'Krông Năng', N'Xã Krông Năng', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11797', N'Dliê Ya', N'Xã Dliê Ya', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12053', N'Tam Giang', N'Xã Tam Giang', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12309', N'Phú Xuân', N'Xã Phú Xuân', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12565', N'Krông Pắc', N'Xã Krông Pắc', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12821', N'Ea Knuếc', N'Xã Ea Knuếc', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1301', N'Ea Bá', N'Xã Ea Bá', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13077', N'Tân Tiến', N'Xã Tân Tiến', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13333', N'Ea Phê', N'Xã Ea Phê', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13589', N'Ea Kly', N'Xã Ea Kly', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13845', N'Ea Kar', N'Xã Ea Kar', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14101', N'Ea Ô', N'Xã Ea Ô', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14357', N'Ea Knốp', N'Xã Ea Knốp', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14613', N'Cư Yang', N'Xã Cư Yang', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14869', N'Ea Păl', N'Xã Ea Păl', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15125', N'M''Drắk', N'Xã M''Drắk', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15381', N'Ea Riêng', N'Xã Ea Riêng', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1557', N'Ea Ly', N'Xã Ea Ly', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15637', N'Cư M''ta', N'Xã Cư M''ta', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15893', N'Krông Á', N'Xã Krông Á', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16149', N'Cư Prao', N'Xã Cư Prao', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16405', N'Hòa Sơn', N'Xã Hòa Sơn', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16661', N'Dang Kang', N'Xã Dang Kang', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16917', N'Krông Bông', N'Xã Krông Bông', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17173', N'Yang Mao', N'Xã Yang Mao', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17429', N'Cư Pui', N'Xã Cư Pui', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17685', N'Liên Sơn Lắk', N'Xã Liên Sơn Lắk', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17941', N'Đắk Liêng', N'Xã Đắk Liêng', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1813', N'Phú Yên', N'Phường Phú Yên', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18197', N'Nam Ka', N'Xã Nam Ka', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18453', N'Đắk Phơi', N'Xã Đắk Phơi', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18709', N'Ea Ning', N'Xã Ea Ning', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18965', N'Krông Ana', N'Xã Krông Ana', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19221', N'Dur Kmăl', N'Xã Dur Kmăl', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19477', N'Ea Na', N'Xã Ea Na', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19733', N'Xuân Thọ', N'Xã Xuân Thọ', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19989', N'Xuân Cảnh', N'Xã Xuân Cảnh', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20245', N'Xuân Lộc', N'Xã Xuân Lộc', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20501', N'Đông Hòa', N'Phường Đông Hòa', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2069', N'Xuân Đài', N'Phường Xuân Đài', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20757', N'Hòa Xuân', N'Xã Hòa Xuân', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21013', N'Tuy An Bắc', N'Xã Tuy An Bắc', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21269', N'Tuy An Đông', N'Xã Tuy An Đông', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21525', N'Ô Loan', N'Xã Ô Loan', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21781', N'Tuy An Nam', N'Xã Tuy An Nam', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22037', N'Tuy An Tây', N'Xã Tuy An Tây', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22293', N'Hòa Thịnh', N'Xã Hòa Thịnh', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22549', N'Hòa Mỹ', N'Xã Hòa Mỹ', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22805', N'Sơn Thành', N'Xã Sơn Thành', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23061', N'Sơn Hòa', N'Xã Sơn Hòa', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2325', N'Dray Bhăng', N'Xã Dray Bhăng', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23317', N'Vân Hòa', N'Xã Vân Hòa', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23573', N'Tây Sơn', N'Xã Tây Sơn', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23829', N'Xuân Lãnh', N'Xã Xuân Lãnh', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24085', N'Phú Mỡ', N'Xã Phú Mỡ', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24341', N'Xuân Phước', N'Xã Xuân Phước', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24597', N'Đồng Xuân', N'Xã Đồng Xuân', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24853', N'Sông Cầu', N'Phường Sông Cầu', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25109', N'Suối Trai', N'Xã Suối Trai', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25365', N'Tuy Hòa', N'Phường Tuy Hòa', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25621', N'Phú Hòa 1', N'Xã Phú Hòa 1', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2581', N'Buôn Đôn', N'Xã Buôn Đôn', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25877', N'Tây Hòa', N'Xã Tây Hòa', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26133', N'Sông Hinh', N'Xã Sông Hinh', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('277', N'Hòa Hiệp', N'Phường Hòa Hiệp', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2837', N'Ea KTur', N'Xã Ea KTur', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3093', N'Vụ Bổn', N'Xã Vụ Bổn', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3349', N'Krông Nô', N'Xã Krông Nô', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3605', N'Ea Trang', N'Xã Ea Trang', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3861', N'Ea H''Leo', N'Xã Ea H''Leo', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4117', N'Ia Lốp', N'Xã Ia Lốp', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4373', N'Ia Rvê', N'Xã Ia Rvê', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4629', N'Buôn Ma Thuột', N'Phường Buôn Ma Thuột', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4885', N'Tân An', N'Phường Tân An', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5141', N'Tân Lập', N'Phường Tân Lập', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('533', N'Bình Kiến', N'Phường Bình Kiến', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5397', N'Thành Nhất', N'Phường Thành Nhất', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5653', N'Ea Kao', N'Phường Ea Kao', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5909', N'Hòa Phú', N'Xã Hòa Phú', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6165', N'Buôn Hồ', N'Phường Buôn Hồ', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6421', N'Cư Bao', N'Phường Cư Bao', 'phuong', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6677', N'Ea Drông', N'Xã Ea Drông', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6933', N'Ea Súp', N'Xã Ea Súp', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7189', N'Ea Rốk', N'Xã Ea Rốk', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7445', N'Ea Bung', N'Xã Ea Bung', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7701', N'Ea Wer', N'Xã Ea Wer', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('789', N'Phú Hòa 2', N'Xã Phú Hòa 2', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7957', N'Ea Nuôl', N'Xã Ea Nuôl', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8213', N'Ea Kiết', N'Xã Ea Kiết', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8469', N'Ea M''Droh', N'Xã Ea M''Droh', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8725', N'Quảng Phú', N'Xã Quảng Phú', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8981', N'Cuôr Đăng', N'Xã Cuôr Đăng', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9237', N'Cư M''gar', N'Xã Cư M''gar', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9493', N'Ea Tul', N'Xã Ea Tul', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9749', N'Pơng Drang', N'Xã Pơng Drang', 'xa', '21');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10006', N'Mường Nhà', N'Xã Mường Nhà', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10262', N'Na Son', N'Xã Na Son', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1046', N'Nậm Kè', N'Xã Nậm Kè', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10518', N'Xa Dung', N'Xã Xa Dung', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10774', N'Pu Nhi', N'Xã Pu Nhi', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11030', N'Mường Luân', N'Xã Mường Luân', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11286', N'Tìa Dình', N'Xã Tìa Dình', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11542', N'Phình Giàng', N'Xã Phình Giàng', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1302', N'Quảng Lâm', N'Xã Quảng Lâm', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1558', N'Nà Hỳ', N'Xã Nà Hỳ', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1814', N'Mường Chà', N'Xã Mường Chà', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2070', N'Nà Bủng', N'Xã Nà Bủng', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2326', N'Chà Tở', N'Xã Chà Tở', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2582', N'Si Pa Phìn', N'Xã Si Pa Phìn', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('278', N'Mường Nhé', N'Xã Mường Nhé', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2838', N'Mường Lay', N'Phường Mường Lay', 'phuong', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3094', N'Na Sang', N'Xã Na Sang', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3350', N'Mường Tùng', N'Xã Mường Tùng', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3606', N'Pa Ham', N'Xã Pa Ham', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3862', N'Nậm Nèn', N'Xã Nậm Nèn', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4118', N'Mường Pồn', N'Xã Mường Pồn', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4374', N'Tủa Chùa', N'Xã Tủa Chùa', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4630', N'Sín Chải', N'Xã Sín Chải', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4886', N'Sính Phình', N'Xã Sính Phình', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5142', N'Tủa Thàng', N'Xã Tủa Thàng', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('534', N'Sín Thầu', N'Xã Sín Thầu', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5398', N'Sáng Nhè', N'Xã Sáng Nhè', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5654', N'Tuần Giáo', N'Xã Tuần Giáo', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5910', N'Quài Tở', N'Xã Quài Tở', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6166', N'Mường Mùn', N'Xã Mường Mùn', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6422', N'Pú Nhung', N'Xã Pú Nhung', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6678', N'Chiềng Sinh', N'Xã Chiềng Sinh', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6934', N'Mường Ảng', N'Xã Mường Ảng', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7190', N'Nà Tấu', N'Xã Nà Tấu', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7446', N'Búng Lao', N'Xã Búng Lao', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7702', N'Mường Lạn', N'Xã Mường Lạn', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('790', N'Mường Toong', N'Xã Mường Toong', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7958', N'Mường Phăng', N'Xã Mường Phăng', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8214', N'Điện Biên Phủ', N'Phường Điện Biên Phủ', 'phuong', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8470', N'Mường Thanh', N'Phường Mường Thanh', 'phuong', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8726', N'Thanh Nưa', N'Xã Thanh Nưa', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8982', N'Thanh An', N'Xã Thanh An', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9238', N'Thanh Yên', N'Xã Thanh Yên', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9494', N'Sam Mứn', N'Xã Sam Mứn', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9750', N'Núa Ngam', N'Xã Núa Ngam', 'xa', '22');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10007', N'Thống Nhất', N'Xã Thống Nhất', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10263', N'Bình Lộc', N'Phường Bình Lộc', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1047', N'Phước Tân', N'Phường Phước Tân', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10519', N'Bảo Vinh', N'Phường Bảo Vinh', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10775', N'Xuân Lập', N'Phường Xuân Lập', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11031', N'Long Khánh', N'Phường Long Khánh', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11287', N'Hàng Gòn', N'Phường Hàng Gòn', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11543', N'Xuân Quế', N'Xã Xuân Quế', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11799', N'Xuân Đường', N'Xã Xuân Đường', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12055', N'Cẩm Mỹ', N'Xã Cẩm Mỹ', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12311', N'Sông Ray', N'Xã Sông Ray', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12567', N'Xuân Định', N'Xã Xuân Định', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12823', N'Xuân Phú', N'Xã Xuân Phú', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1303', N'Tam Phước', N'Phường Tam Phước', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13079', N'Phú Trung', N'Xã Phú Trung', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13335', N'Thuận Lợi', N'Xã Thuận Lợi', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13591', N'Đồng Tâm', N'Xã Đồng Tâm', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13847', N'Tân Lợi', N'Xã Tân Lợi', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14103', N'Đồng Phú', N'Xã Đồng Phú', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14359', N'Phước Sơn', N'Xã Phước Sơn', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14615', N'Nghĩa Trung', N'Xã Nghĩa Trung', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14871', N'Bù Đăng', N'Xã Bù Đăng', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15127', N'Thọ Sơn', N'Xã Thọ Sơn', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15383', N'Đak Nhau', N'Xã Đak Nhau', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1559', N'Đăk Ơ', N'Xã Đăk Ơ', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15639', N'Bom Bo', N'Xã Bom Bo', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15895', N'Long Bình', N'Phường Long Bình', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16151', N'Trảng Dài', N'Phường Trảng Dài', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16407', N'Hố Nai', N'Phường Hố Nai', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16663', N'Long Hưng', N'Phường Long Hưng', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16919', N'Đại Phước', N'Xã Đại Phước', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17175', N'Bình Phước', N'Phường Bình Phước', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17431', N'Đồng Xoài', N'Phường Đồng Xoài', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17687', N'Biên Hòa', N'Phường Biên Hòa', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17943', N'Trấn Biên', N'Phường Trấn Biên', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1815', N'Xuân Đông', N'Xã Xuân Đông', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18199', N'Tam Hiệp', N'Phường Tam Hiệp', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18455', N'Phước Bình', N'Phường Phước Bình', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18711', N'Phước Long', N'Phường Phước Long', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18967', N'Bình Long', N'Phường Bình Long', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19223', N'An Lộc', N'Phường An Lộc', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19479', N'Minh Hưng', N'Phường Minh Hưng', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19735', N'Chơn Thành', N'Phường Chơn Thành', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19991', N'Nha Bích', N'Xã Nha Bích', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20247', N'Tân Quan', N'Xã Tân Quan', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20503', N'Tân Hưng', N'Xã Tân Hưng', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2071', N'Bù Gia Mập', N'Xã Bù Gia Mập', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20759', N'Tân Khai', N'Xã Tân Khai', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21015', N'Minh Đức', N'Xã Minh Đức', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21271', N'Lộc Thành', N'Xã Lộc Thành', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21527', N'Lộc Ninh', N'Xã Lộc Ninh', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21783', N'Lộc Hưng', N'Xã Lộc Hưng', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22039', N'Lộc Tấn', N'Xã Lộc Tấn', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22295', N'Lộc Thạnh', N'Xã Lộc Thạnh', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22551', N'Lộc Quang', N'Xã Lộc Quang', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22807', N'Tân Tiến', N'Xã Tân Tiến', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23063', N'Thiện Hưng', N'Xã Thiện Hưng', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2327', N'Thanh Sơn', N'Xã Thanh Sơn', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23319', N'Hưng Phước', N'Xã Hưng Phước', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23575', N'Phú Nghĩa', N'Xã Phú Nghĩa', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23831', N'Đa Kia', N'Xã Đa Kia', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24087', N'Bình Tân', N'Xã Bình Tân', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24343', N'Long Hà', N'Xã Long Hà', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2583', N'Xuân Lộc', N'Xã Xuân Lộc', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('279', N'Đak Lua', N'Xã Đak Lua', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2839', N'Xuân Thành', N'Xã Xuân Thành', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3095', N'Xuân Bắc', N'Xã Xuân Bắc', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3351', N'La Ngà', N'Xã La Ngà', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3607', N'Định Quán', N'Xã Định Quán', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3863', N'Phú Vinh', N'Xã Phú Vinh', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4119', N'Phú Hòa', N'Xã Phú Hòa', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4375', N'Tà Lài', N'Xã Tà Lài', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4631', N'Nam Cát Tiên', N'Xã Nam Cát Tiên', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4887', N'Tân Phú', N'Xã Tân Phú', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5143', N'Phú Lâm', N'Xã Phú Lâm', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('535', N'Phú Lý', N'Xã Phú Lý', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5399', N'Trị An', N'Xã Trị An', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5655', N'Tân An', N'Xã Tân An', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5911', N'Tân Triều', N'Phường Tân Triều', 'phuong', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6167', N'Phú Riềng', N'Xã Phú Riềng', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6423', N'Nhơn Trạch', N'Xã Nhơn Trạch', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6679', N'Phước An', N'Xã Phước An', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6935', N'Phước Thái', N'Xã Phước Thái', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7191', N'Long Phước', N'Xã Long Phước', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7447', N'Bình An', N'Xã Bình An', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7703', N'Long Thành', N'Xã Long Thành', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('791', N'Xuân Hòa', N'Xã Xuân Hòa', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7959', N'An Phước', N'Xã An Phước', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8215', N'An Viễn', N'Xã An Viễn', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8471', N'Bình Minh', N'Xã Bình Minh', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8727', N'Trảng Bom', N'Xã Trảng Bom', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8983', N'Bàu Hàm', N'Xã Bàu Hàm', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9239', N'Hưng Thịnh', N'Xã Hưng Thịnh', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9495', N'Dầu Giây', N'Xã Dầu Giây', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9751', N'Gia Kiệm', N'Xã Gia Kiệm', 'xa', '23');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10008', N'Hòa Long', N'Xã Hòa Long', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10264', N'Phong Hòa', N'Xã Phong Hòa', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1048', N'Tân Thạnh', N'Xã Tân Thạnh', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10520', N'Sa Đéc', N'Phường Sa Đéc', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10776', N'Tân Dương', N'Xã Tân Dương', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11032', N'Phú Hựu', N'Xã Phú Hựu', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11288', N'Tân Nhuận Đông', N'Xã Tân Nhuận Đông', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11544', N'Tân Phú Trung', N'Xã Tân Phú Trung', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11800', N'Thanh Hưng', N'Xã Thanh Hưng', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12056', N'An Hữu', N'Xã An Hữu', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12312', N'Mỹ Lợi', N'Xã Mỹ Lợi', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12568', N'Mỹ Đức Tây', N'Xã Mỹ Đức Tây', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12824', N'Mỹ Thiện', N'Xã Mỹ Thiện', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1304', N'Long Phú Thuận', N'Xã Long Phú Thuận', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13080', N'Hậu Mỹ', N'Xã Hậu Mỹ', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13336', N'Hội Cư', N'Xã Hội Cư', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13592', N'Cái Bè', N'Xã Cái Bè', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13848', N'Hiệp Đức', N'Xã Hiệp Đức', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14104', N'Bình Phú', N'Xã Bình Phú', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14360', N'Ngũ Hiệp', N'Xã Ngũ Hiệp', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14616', N'Long Tiên', N'Xã Long Tiên', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14872', N'Mỹ Thành', N'Xã Mỹ Thành', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15128', N'Thạnh Phú', N'Xã Thạnh Phú', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15384', N'Mỹ Phước Tây', N'Phường Mỹ Phước Tây', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1560', N'Phú Cường', N'Xã Phú Cường', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15640', N'Thanh Hòa', N'Phường Thanh Hòa', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15896', N'Cai Lậy', N'Phường Cai Lậy', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16152', N'Nhị Quý', N'Phường Nhị Quý', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16408', N'Tân Phú', N'Xã Tân Phú', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16664', N'Tân Phước 1', N'Xã Tân Phước 1', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16920', N'Tân Phước 2', N'Xã Tân Phước 2', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17176', N'Tân Phước 3', N'Xã Tân Phước 3', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17432', N'Hưng Thạnh', N'Xã Hưng Thạnh', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17688', N'Tân Hương', N'Xã Tân Hương', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17944', N'Châu Thành', N'Xã Châu Thành', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1816', N'Tân Hồng', N'Xã Tân Hồng', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18200', N'Long Hưng', N'Xã Long Hưng', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18456', N'Long Định', N'Xã Long Định', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18712', N'Vĩnh Kim', N'Xã Vĩnh Kim', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18968', N'Kim Sơn', N'Xã Kim Sơn', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19224', N'Bình Trưng', N'Xã Bình Trưng', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19480', N'Mỹ Tho', N'Phường Mỹ Tho', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19736', N'Đạo Thạnh', N'Phường Đạo Thạnh', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19992', N'Mỹ Phong', N'Phường Mỹ Phong', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20248', N'Thới Sơn', N'Phường Thới Sơn', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20504', N'Trung An', N'Phường Trung An', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2072', N'Tân Thành', N'Xã Tân Thành', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20760', N'Mỹ Tịnh An', N'Xã Mỹ Tịnh An', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21016', N'Lương Hòa Lạc', N'Xã Lương Hòa Lạc', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21272', N'Tân Thuận Bình', N'Xã Tân Thuận Bình', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21528', N'Chợ Gạo', N'Xã Chợ Gạo', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21784', N'An Thạnh Thủy', N'Xã An Thạnh Thủy', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22040', N'Bình Ninh', N'Xã Bình Ninh', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22296', N'Gò Công Đông', N'Xã Gò Công Đông', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22552', N'Tân Điền', N'Xã Tân Điền', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22808', N'Tân Hòa', N'Xã Tân Hòa', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23064', N'Tân Đông', N'Xã Tân Đông', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2328', N'Tân Hộ Cơ', N'Xã Tân Hộ Cơ', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23320', N'Gia Thuận', N'Xã Gia Thuận', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23576', N'Vĩnh Bình', N'Xã Vĩnh Bình', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23832', N'Đồng Sơn', N'Xã Đồng Sơn', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24088', N'Phú Thành', N'Xã Phú Thành', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24344', N'Long Bình', N'Xã Long Bình', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24600', N'Vĩnh Hựu', N'Xã Vĩnh Hựu', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24856', N'Gò Công', N'Phường Gò Công', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25112', N'Long Thuận', N'Phường Long Thuận', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25368', N'Bình Xuân', N'Phường Bình Xuân', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25624', N'Sơn Qui', N'Phường Sơn Qui', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2584', N'An Phước', N'Xã An Phước', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25880', N'Tân Thới', N'Xã Tân Thới', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26136', N'Tân Phú Đông', N'Xã Tân Phú Đông', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('280', N'Phong Mỹ', N'Xã Phong Mỹ', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2840', N'An Bình', N'Phường An Bình', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3096', N'Hồng Ngự', N'Phường Hồng Ngự', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3352', N'Thường Lạc', N'Phường Thường Lạc', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3608', N'Thường Phước', N'Xã Thường Phước', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3864', N'Long Khánh', N'Xã Long Khánh', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4120', N'An Hòa', N'Xã An Hòa', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4376', N'Tam Nông', N'Xã Tam Nông', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4632', N'Phú Thọ', N'Xã Phú Thọ', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4888', N'Tràm Chim', N'Xã Tràm Chim', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5144', N'An Long', N'Xã An Long', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('536', N'Tân Long', N'Xã Tân Long', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5400', N'Bình Thành', N'Xã Bình Thành', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5656', N'Tháp Mười', N'Xã Tháp Mười', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5912', N'Thanh Mỹ', N'Xã Thanh Mỹ', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6168', N'Mỹ Quí', N'Xã Mỹ Quí', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6424', N'Đốc Binh Kiều', N'Xã Đốc Binh Kiều', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6680', N'Trường Xuân', N'Xã Trường Xuân', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6936', N'Phương Thịnh', N'Xã Phương Thịnh', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7192', N'Ba Sao', N'Xã Ba Sao', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7448', N'Mỹ Thọ', N'Xã Mỹ Thọ', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7704', N'Bình Hàng Trung', N'Xã Bình Hàng Trung', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('792', N'Thanh Bình', N'Xã Thanh Bình', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7960', N'Mỹ Hiệp', N'Xã Mỹ Hiệp', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8216', N'Cao Lãnh', N'Phường Cao Lãnh', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8472', N'Mỹ Ngãi', N'Phường Mỹ Ngãi', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8728', N'Mỹ Trà', N'Phường Mỹ Trà', 'phuong', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8984', N'Mỹ An Hưng', N'Xã Mỹ An Hưng', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9240', N'Tân Khánh Trung', N'Xã Tân Khánh Trung', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9496', N'Lấp Vò', N'Xã Lấp Vò', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9752', N'Lai Vung', N'Xã Lai Vung', 'xa', '24');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10009', N'Chư Pưh', N'Xã Chư Pưh', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10265', N'Ia Le', N'Xã Ia Le', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1049', N'Vân Canh', N'Xã Vân Canh', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10521', N'Ia Hrú', N'Xã Ia Hrú', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10777', N'An Khê', N'Phường An Khê', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11033', N'An Bình', N'Phường An Bình', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11289', N'Cửu An', N'Xã Cửu An', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11545', N'Đak Pơ', N'Xã Đak Pơ', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11801', N'Ya Hội', N'Xã Ya Hội', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12057', N'Kbang', N'Xã Kbang', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12313', N'Kông Bơ La', N'Xã Kông Bơ La', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12569', N'Tơ Tung', N'Xã Tơ Tung', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12825', N'Sơn Lang', N'Xã Sơn Lang', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1305', N'Ia Púch', N'Xã Ia Púch', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13081', N'Đak Rong', N'Xã Đak Rong', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13337', N'Kông Chro', N'Xã Kông Chro', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13593', N'Ya Ma', N'Xã Ya Ma', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13849', N'Chư Krey', N'Xã Chư Krey', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14105', N'SRó', N'Xã SRó', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14361', N'Đăk Song', N'Xã Đăk Song', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14617', N'Chơ Long', N'Xã Chơ Long', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14873', N'Ayun Pa', N'Phường Ayun Pa', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15129', N'Ia Rbol', N'Xã Ia Rbol', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15385', N'Ia Sao', N'Xã Ia Sao', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1561', N'Ia Mơ', N'Xã Ia Mơ', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15641', N'Phú Thiện', N'Xã Phú Thiện', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15897', N'Chư A Thai', N'Xã Chư A Thai', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16153', N'Ia Hiao', N'Xã Ia Hiao', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16409', N'Pờ Tó', N'Xã Pờ Tó', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16665', N'Ia Pa', N'Xã Ia Pa', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16921', N'Ia Tul', N'Xã Ia Tul', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17177', N'Phú Túc', N'Xã Phú Túc', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17433', N'Ia Dreh', N'Xã Ia Dreh', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17689', N'Ia Rsai', N'Xã Ia Rsai', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17945', N'Uar', N'Xã Uar', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1817', N'Ia Dom', N'Xã Ia Dom', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18201', N'Đak Đoa', N'Xã Đak Đoa', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18457', N'Kon Gang', N'Xã Kon Gang', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18713', N'Ia Băng', N'Xã Ia Băng', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18969', N'KDang', N'Xã KDang', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19225', N'Đak Sơmei', N'Xã Đak Sơmei', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19481', N'Mang Yang', N'Xã Mang Yang', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19737', N'Lơ Pang', N'Xã Lơ Pang', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19993', N'Kon Chiêng', N'Xã Kon Chiêng', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20249', N'Hra', N'Xã Hra', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20505', N'Ayun', N'Xã Ayun', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2073', N'Ia Nan', N'Xã Ia Nan', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20761', N'Ia Grai', N'Xã Ia Grai', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21017', N'Ia Krái', N'Xã Ia Krái', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21273', N'Ia Hrung', N'Xã Ia Hrung', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21529', N'Đức Cơ', N'Xã Đức Cơ', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21785', N'Ia Dơk', N'Xã Ia Dơk', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22041', N'Ia Krêl', N'Xã Ia Krêl', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22297', N'Ngô Mây', N'Xã Ngô Mây', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22553', N'Cát Tiến', N'Xã Cát Tiến', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22809', N'Đề Gi', N'Xã Đề Gi', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23065', N'Hòa Hội', N'Xã Hòa Hội', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2329', N'Ia Pnôn', N'Xã Ia Pnôn', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23321', N'Quy Nhơn', N'Phường Quy Nhơn', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23577', N'Quy Nhơn Tây', N'Phường Quy Nhơn Tây', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23833', N'Quy Nhơn Nam', N'Phường Quy Nhơn Nam', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24089', N'Quy Nhơn Bắc', N'Phường Quy Nhơn Bắc', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24345', N'Bình Định', N'Phường Bình Định', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24601', N'An Nhơn', N'Phường An Nhơn', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24857', N'An Nhơn Đông', N'Phường An Nhơn Đông', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25113', N'An Nhơn Tây', N'Xã An Nhơn Tây', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25369', N'An Nhơn Nam', N'Phường An Nhơn Nam', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25625', N'An Nhơn Bắc', N'Phường An Nhơn Bắc', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2585', N'Canh Vinh', N'Xã Canh Vinh', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25881', N'Bồng Sơn', N'Phường Bồng Sơn', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26137', N'Hoài Nhơn', N'Phường Hoài Nhơn', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26393', N'Tam Quan', N'Phường Tam Quan', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26649', N'Hoài Nhơn Đông', N'Phường Hoài Nhơn Đông', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26905', N'Hoài Nhơn Tây', N'Phường Hoài Nhơn Tây', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27161', N'Hoài Nhơn Nam', N'Phường Hoài Nhơn Nam', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27417', N'Hoài Nhơn Bắc', N'Phường Hoài Nhơn Bắc', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27673', N'Phù Cát', N'Xã Phù Cát', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27929', N'Xuân An', N'Xã Xuân An', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('281', N'Canh Liên', N'Xã Canh Liên', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28185', N'Hội Sơn', N'Xã Hội Sơn', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2841', N'An Hòa', N'Xã An Hòa', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28441', N'Phù Mỹ', N'Xã Phù Mỹ', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28697', N'An Lương', N'Xã An Lương', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28953', N'Bình Dương', N'Xã Bình Dương', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29209', N'Phù Mỹ Tây', N'Xã Phù Mỹ Tây', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29465', N'Phù Mỹ Nam', N'Xã Phù Mỹ Nam', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29721', N'Phù Mỹ Bắc', N'Xã Phù Mỹ Bắc', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29977', N'Tuy Phước', N'Xã Tuy Phước', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30233', N'Tuy Phước Đông', N'Xã Tuy Phước Đông', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30489', N'Tuy Phước Tây', N'Xã Tuy Phước Tây', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30745', N'Tuy Phước Bắc', N'Xã Tuy Phước Bắc', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3097', N'Phù Mỹ Đông', N'Xã Phù Mỹ Đông', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31001', N'Bình Khê', N'Xã Bình Khê', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31257', N'Bình Phú', N'Xã Bình Phú', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31513', N'Bình Hiệp', N'Xã Bình Hiệp', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31769', N'Bình An', N'Xã Bình An', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32025', N'Hoài Ân', N'Xã Hoài Ân', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32281', N'Ân Tường', N'Xã Ân Tường', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32537', N'Kim Sơn', N'Xã Kim Sơn', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32793', N'Vạn Đức', N'Xã Vạn Đức', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33049', N'Ân Hảo', N'Xã Ân Hảo', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33305', N'Vĩnh Thạnh', N'Xã Vĩnh Thạnh', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3353', N'Quy Nhơn Đông', N'Phường Quy Nhơn Đông', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33561', N'Vĩnh Thịnh', N'Xã Vĩnh Thịnh', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33817', N'Vĩnh Quang', N'Xã Vĩnh Quang', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34073', N'Vĩnh Sơn', N'Xã Vĩnh Sơn', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34329', N'An Lão', N'Xã An Lão', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34585', N'An Vinh', N'Xã An Vinh', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3609', N'Tây Sơn', N'Xã Tây Sơn', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3865', N'Ia Chia', N'Xã Ia Chia', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4121', N'Ia O', N'Xã Ia O', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4377', N'Krong', N'Xã Krong', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4633', N'Pleiku', N'Phường Pleiku', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4889', N'Hội Phú', N'Phường Hội Phú', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5145', N'Thống Nhất', N'Phường Thống Nhất', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('537', N'Nhơn Châu', N'Xã Nhơn Châu', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5401', N'Diên Hồng', N'Phường Diên Hồng', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5657', N'An Phú', N'Phường An Phú', 'phuong', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5913', N'Biển Hồ', N'Xã Biển Hồ', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6169', N'Gào', N'Xã Gào', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6425', N'Ia Ly', N'Xã Ia Ly', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6681', N'Chư Păh', N'Xã Chư Păh', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6937', N'Ia Khươl', N'Xã Ia Khươl', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7193', N'Ia Phí', N'Xã Ia Phí', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7449', N'Chư Prông', N'Xã Chư Prông', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7705', N'Bàu Cạn', N'Xã Bàu Cạn', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('793', N'An Toàn', N'Xã An Toàn', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7961', N'Ia Boòng', N'Xã Ia Boòng', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8217', N'Ia Lâu', N'Xã Ia Lâu', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8473', N'Ia Pia', N'Xã Ia Pia', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8729', N'Ia Tôr', N'Xã Ia Tôr', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8985', N'Chư Sê', N'Xã Chư Sê', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9241', N'Bờ Ngoong', N'Xã Bờ Ngoong', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9497', N'Ia Ko', N'Xã Ia Ko', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9753', N'Al Bá', N'Xã Al Bá', 'xa', '25');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10010', N'Cẩm Hưng', N'Xã Cẩm Hưng', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10266', N'Cẩm Lạc', N'Xã Cẩm Lạc', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1050', N'Sơn Kim 1', N'Xã Sơn Kim 1', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10522', N'Cẩm Trung', N'Xã Cẩm Trung', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10778', N'Yên Hòa', N'Xã Yên Hòa', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11034', N'Trần Phú', N'Phường Trần Phú', 'phuong', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11290', N'Thạch Lạc', N'Xã Thạch Lạc', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11546', N'Đồng Tiến', N'Xã Đồng Tiến', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11802', N'Thạch Khê', N'Xã Thạch Khê', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12058', N'Cẩm Bình', N'Xã Cẩm Bình', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12314', N'Thạch Hà', N'Xã Thạch Hà', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12570', N'Việt Xuyên', N'Xã Việt Xuyên', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12826', N'Đông Kinh', N'Xã Đông Kinh', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1306', N'Sơn Kim 2', N'Xã Sơn Kim 2', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13082', N'Thạch Xuân', N'Xã Thạch Xuân', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13338', N'Xuân Lộc', N'Xã Xuân Lộc', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13594', N'Can Lộc', N'Xã Can Lộc', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13850', N'Bắc Hồng Lĩnh', N'Phường Bắc Hồng Lĩnh', 'phuong', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14106', N'Nam Hồng Lĩnh', N'Phường Nam Hồng Lĩnh', 'phuong', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14362', N'Đức Thịnh', N'Xã Đức Thịnh', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14618', N'Nghi Xuân', N'Xã Nghi Xuân', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14874', N'Cổ Đạm', N'Xã Cổ Đạm', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15130', N'Tiên Điền', N'Xã Tiên Điền', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15386', N'Đức Thọ', N'Xã Đức Thọ', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1562', N'Đan Hải', N'Xã Đan Hải', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15642', N'Đức Quang', N'Xã Đức Quang', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15898', N'Hương Khê', N'Xã Hương Khê', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16154', N'Gia Hanh', N'Xã Gia Hanh', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16410', N'Trường Lưu', N'Xã Trường Lưu', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16666', N'Hồng Lộc', N'Xã Hồng Lộc', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16922', N'Lộc Hà', N'Xã Lộc Hà', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17178', N'Mai Phụ', N'Xã Mai Phụ', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17434', N'Tùng Lộc', N'Xã Tùng Lộc', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17690', N'Đồng Lộc', N'Xã Đồng Lộc', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1818', N'Vũng Áng', N'Phường Vũng Áng', 'phuong', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2074', N'Sông Trí', N'Phường Sông Trí', 'phuong', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2330', N'Hà Huy Tập', N'Phường Hà Huy Tập', 'phuong', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2586', N'Thành Sen', N'Phường Thành Sen', 'phuong', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('282', N'Thiên Cầm', N'Xã Thiên Cầm', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2842', N'Sơn Hồng', N'Xã Sơn Hồng', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3098', N'Sơn Tây', N'Xã Sơn Tây', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3354', N'Sơn Giang', N'Xã Sơn Giang', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3610', N'Sơn Tiến', N'Xã Sơn Tiến', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3866', N'Hương Sơn', N'Xã Hương Sơn', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4122', N'Tứ Mỹ', N'Xã Tứ Mỹ', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4378', N'Đức Minh', N'Xã Đức Minh', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4634', N'Kim Hoa', N'Xã Kim Hoa', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4890', N'Vũ Quang', N'Xã Vũ Quang', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5146', N'Mai Hoa', N'Xã Mai Hoa', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('538', N'Kỳ Xuân', N'Xã Kỳ Xuân', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5402', N'Thượng Đức', N'Xã Thượng Đức', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5658', N'Đức Đồng', N'Xã Đức Đồng', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5914', N'Hương Bình', N'Xã Hương Bình', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6170', N'Hương Xuân', N'Xã Hương Xuân', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6426', N'Phúc Trạch', N'Xã Phúc Trạch', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6682', N'Hà Linh', N'Xã Hà Linh', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6938', N'Hương Đô', N'Xã Hương Đô', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7194', N'Hương Phố', N'Xã Hương Phố', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7450', N'Toàn Lưu', N'Xã Toàn Lưu', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7706', N'Hải Ninh', N'Phường Hải Ninh', 'phuong', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('794', N'Hoành Sơn', N'Phường Hoành Sơn', 'phuong', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7962', N'Kỳ Anh', N'Xã Kỳ Anh', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8218', N'Kỳ Hoa', N'Xã Kỳ Hoa', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8474', N'Kỳ Văn', N'Xã Kỳ Văn', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8730', N'Kỳ Khang', N'Xã Kỳ Khang', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8986', N'Kỳ Lạc', N'Xã Kỳ Lạc', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9242', N'Kỳ Thượng', N'Xã Kỳ Thượng', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9498', N'Cẩm Xuyên', N'Xã Cẩm Xuyên', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9754', N'Cẩm Duệ', N'Xã Cẩm Duệ', 'xa', '26');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10011', N'Văn Giang', N'Xã Văn Giang', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10267', N'Mễ Sở', N'Xã Mễ Sở', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1051', N'Phố Hiến', N'Phường Phố Hiến', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10523', N'Thái Bình', N'Phường Thái Bình', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10779', N'Trần Lãm', N'Phường Trần Lãm', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11035', N'Trần Hưng Đạo', N'Phường Trần Hưng Đạo', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11291', N'Trà Lý', N'Phường Trà Lý', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11547', N'Vũ Phúc', N'Phường Vũ Phúc', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11803', N'Thái Thụy', N'Xã Thái Thụy', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12059', N'Đông Thụy Anh', N'Xã Đông Thụy Anh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12315', N'Bắc Thụy Anh', N'Xã Bắc Thụy Anh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12571', N'Thụy Anh', N'Xã Thụy Anh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12827', N'Nam Thụy Anh', N'Xã Nam Thụy Anh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1307', N'Hồng Châu', N'Phường Hồng Châu', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13083', N'Bắc Thái Ninh', N'Xã Bắc Thái Ninh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13339', N'Thái Ninh', N'Xã Thái Ninh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13595', N'Nam Thái Ninh', N'Xã Nam Thái Ninh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13851', N'Tây Thái Ninh', N'Xã Tây Thái Ninh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14107', N'Tây Thụy Anh', N'Xã Tây Thụy Anh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14363', N'Tiền Hải', N'Xã Tiền Hải', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14619', N'Tây Tiền Hải', N'Xã Tây Tiền Hải', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14875', N'Ái Quốc', N'Xã Ái Quốc', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15131', N'Đồng Châu', N'Xã Đồng Châu', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15387', N'Đông Tiền Hải', N'Xã Đông Tiền Hải', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1563', N'Tân Hưng', N'Xã Tân Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15643', N'Nam Cường', N'Xã Nam Cường', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15899', N'Hưng Phú', N'Xã Hưng Phú', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16155', N'Đông Quan', N'Xã Đông Quan', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16411', N'Nam Tiên Hưng', N'Xã Nam Tiên Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16667', N'Tiên Hưng', N'Xã Tiên Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16923', N'Hưng Hà', N'Xã Hưng Hà', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17179', N'Tiên La', N'Xã Tiên La', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17435', N'Lê Quý Đôn', N'Xã Lê Quý Đôn', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17691', N'Hồng Minh', N'Xã Hồng Minh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17947', N'Thần Khê', N'Xã Thần Khê', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1819', N'Hoàng Hoa Thám', N'Xã Hoàng Hoa Thám', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18203', N'Diên Hà', N'Xã Diên Hà', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18459', N'Ngự Thiên', N'Xã Ngự Thiên', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18715', N'Long Hưng', N'Xã Long Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18971', N'Kiến Xương', N'Xã Kiến Xương', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19227', N'Lê Lợi', N'Xã Lê Lợi', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19483', N'Quang Lịch', N'Xã Quang Lịch', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19739', N'Vũ Quý', N'Xã Vũ Quý', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19995', N'Bình Thanh', N'Xã Bình Thanh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20251', N'Bình Định', N'Xã Bình Định', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20507', N'Hồng Vũ', N'Xã Hồng Vũ', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2075', N'Tiên Lữ', N'Xã Tiên Lữ', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20763', N'Bình Nguyên', N'Xã Bình Nguyên', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21019', N'Trà Giang', N'Xã Trà Giang', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21275', N'Vũ Thư', N'Xã Vũ Thư', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21531', N'Thư Trì', N'Xã Thư Trì', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21787', N'Tân Thuận', N'Xã Tân Thuận', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22043', N'Thư Vũ', N'Xã Thư Vũ', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22299', N'Vũ Tiên', N'Xã Vũ Tiên', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22555', N'Vạn Xuân', N'Xã Vạn Xuân', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22811', N'Nam Tiền Hải', N'Xã Nam Tiền Hải', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23067', N'Quỳnh Phụ', N'Xã Quỳnh Phụ', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2331', N'Tiên Hoa', N'Xã Tiên Hoa', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23323', N'Minh Thọ', N'Xã Minh Thọ', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23579', N'Nguyễn Du', N'Xã Nguyễn Du', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23835', N'Quỳnh An', N'Xã Quỳnh An', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24091', N'Ngọc Lâm', N'Xã Ngọc Lâm', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24347', N'Đồng Bằng', N'Xã Đồng Bằng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24603', N'A Sào', N'Xã A Sào', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24859', N'Phụ Dực', N'Xã Phụ Dực', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25115', N'Tân Tiến', N'Xã Tân Tiến', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25371', N'Đông Hưng', N'Xã Đông Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25627', N'Bắc Tiên Hưng', N'Xã Bắc Tiên Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2587', N'Quang Hưng', N'Xã Quang Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25883', N'Đông Tiên Hưng', N'Xã Đông Tiên Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26139', N'Nam Đông Hưng', N'Xã Nam Đông Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26395', N'Bắc Đông Quan', N'Xã Bắc Đông Quan', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26651', N'Bắc Đông Hưng', N'Xã Bắc Đông Hưng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('283', N'Hiệp Cường', N'Xã Hiệp Cường', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2843', N'Đoàn Đào', N'Xã Đoàn Đào', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3099', N'Tiên Tiến', N'Xã Tiên Tiến', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3355', N'Tống Trân', N'Xã Tống Trân', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3611', N'Lương Bằng', N'Xã Lương Bằng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3867', N'Nghĩa Dân', N'Xã Nghĩa Dân', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4123', N'Đức Hợp', N'Xã Đức Hợp', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4379', N'Ân Thi', N'Xã Ân Thi', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4635', N'Xuân Trúc', N'Xã Xuân Trúc', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4891', N'Phạm Ngũ Lão', N'Xã Phạm Ngũ Lão', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5147', N'Nguyễn Trãi', N'Xã Nguyễn Trãi', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('539', N'Đông Thái Ninh', N'Xã Đông Thái Ninh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5403', N'Hồng Quang', N'Xã Hồng Quang', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5659', N'Khoái Châu', N'Xã Khoái Châu', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5915', N'Triệu Việt Vương', N'Xã Triệu Việt Vương', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6171', N'Việt Tiến', N'Xã Việt Tiến', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6427', N'Chí Minh', N'Xã Chí Minh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6683', N'Châu Ninh', N'Xã Châu Ninh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6939', N'Yên Mỹ', N'Xã Yên Mỹ', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7195', N'Việt Yên', N'Xã Việt Yên', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7451', N'Hoàn Long', N'Xã Hoàn Long', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7707', N'Nguyễn Văn Linh', N'Xã Nguyễn Văn Linh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('795', N'Sơn Nam', N'Phường Sơn Nam', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7963', N'Mỹ Hào', N'Phường Mỹ Hào', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8219', N'Đường Hào', N'Phường Đường Hào', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8475', N'Thượng Hồng', N'Phường Thượng Hồng', 'phuong', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8731', N'Như Quỳnh', N'Xã Như Quỳnh', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8987', N'Lạc Đạo', N'Xã Lạc Đạo', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9243', N'Đại Đồng', N'Xã Đại Đồng', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9499', N'Nghĩa Trụ', N'Xã Nghĩa Trụ', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9755', N'Phụng Công', N'Xã Phụng Công', 'xa', '27');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10012', N'Suối Hiệp', N'Xã Suối Hiệp', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10268', N'Bắc Khánh Vĩnh', N'Xã Bắc Khánh Vĩnh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1052', N'Nam Ninh Hòa', N'Xã Nam Ninh Hòa', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10524', N'Trung Khánh Vĩnh', N'Xã Trung Khánh Vĩnh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10780', N'Tây Khánh Vĩnh', N'Xã Tây Khánh Vĩnh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11036', N'Nam Khánh Vĩnh', N'Xã Nam Khánh Vĩnh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11292', N'Khánh Vĩnh', N'Xã Khánh Vĩnh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11548', N'Khánh Sơn', N'Xã Khánh Sơn', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11804', N'Tây Khánh Sơn', N'Xã Tây Khánh Sơn', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12060', N'Đông Khánh Sơn', N'Xã Đông Khánh Sơn', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12316', N'Ninh Phước', N'Xã Ninh Phước', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12572', N'Phước Hữu', N'Xã Phước Hữu', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12828', N'Phước Hậu', N'Xã Phước Hậu', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1308', N'Vạn Hưng', N'Xã Vạn Hưng', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13084', N'Thuận Nam', N'Xã Thuận Nam', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13340', N'Cà Ná', N'Xã Cà Ná', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13596', N'Phước Hà', N'Xã Phước Hà', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13852', N'Ninh Hải', N'Xã Ninh Hải', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14108', N'Xuân Hải', N'Xã Xuân Hải', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14364', N'Thuận Bắc', N'Xã Thuận Bắc', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14620', N'Công Hải', N'Xã Công Hải', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14876', N'Ninh Sơn', N'Xã Ninh Sơn', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15132', N'Lâm Sơn', N'Xã Lâm Sơn', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15388', N'Anh Dũng', N'Xã Anh Dũng', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1564', N'Tu Bông', N'Xã Tu Bông', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15644', N'Mỹ Sơn', N'Xã Mỹ Sơn', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15900', N'Bác Ái Đông', N'Xã Bác Ái Đông', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16156', N'Bác Ái', N'Xã Bác Ái', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16412', N'Bác Ái Tây', N'Xã Bác Ái Tây', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16668', N'Đông Hải', N'Phường Đông Hải', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1820', N'Vạn Thắng', N'Xã Vạn Thắng', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2076', N'Đại Lãnh', N'Xã Đại Lãnh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2332', N'Bắc Cam Ranh', N'Phường Bắc Cam Ranh', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2588', N'Nam Cam Ranh', N'Xã Nam Cam Ranh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('284', N'Đô Vinh', N'Phường Đô Vinh', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2844', N'Phước Dinh', N'Xã Phước Dinh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3100', N'Nha Trang', N'Phường Nha Trang', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3356', N'Bắc Nha Trang', N'Phường Bắc Nha Trang', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3612', N'Ninh Chử', N'Phường Ninh Chử', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3868', N'Vĩnh Hải', N'Xã Vĩnh Hải', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4124', N'Cam Lâm', N'Xã Cam Lâm', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4380', N'Cam An', N'Xã Cam An', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4636', N'Cam Hiệp', N'Xã Cam Hiệp', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4892', N'Suối Dầu', N'Xã Suối Dầu', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5148', N'Đông Ninh Hòa', N'Phường Đông Ninh Hòa', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('540', N'Phan Rang', N'Phường Phan Rang', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5404', N'Trường Sa', N'Đặc Khu Trường Sa', 'dac-khu', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5660', N'Tây Nha Trang', N'Phường Tây Nha Trang', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5916', N'Nam Nha Trang', N'Phường Nam Nha Trang', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6172', N'Cam Ranh', N'Phường Cam Ranh', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6428', N'Cam Linh', N'Phường Cam Linh', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6684', N'Ba Ngòi', N'Phường Ba Ngòi', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6940', N'Bắc Ninh Hòa', N'Xã Bắc Ninh Hòa', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7196', N'Ninh Hòa', N'Phường Ninh Hòa', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7452', N'Tân Định', N'Xã Tân Định', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7708', N'Hòa Thắng', N'Phường Hòa Thắng', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('796', N'Bảo An', N'Phường Bảo An', 'phuong', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7964', N'Tây Ninh Hòa', N'Xã Tây Ninh Hòa', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8220', N'Hòa Trí', N'Xã Hòa Trí', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8476', N'Vạn Ninh', N'Xã Vạn Ninh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8732', N'Diên Khánh', N'Xã Diên Khánh', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8988', N'Diên Lạc', N'Xã Diên Lạc', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9244', N'Diên Điền', N'Xã Diên Điền', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9500', N'Diên Lâm', N'Xã Diên Lâm', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9756', N'Diên Thọ', N'Xã Diên Thọ', 'xa', '28');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1053', N'Pa Ủ', N'Xã Pa Ủ', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1309', N'Nậm Cuổi', N'Xã Nậm Cuổi', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1565', N'Nậm Mạ', N'Xã Nậm Mạ', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1821', N'Lê Lợi', N'Xã Lê Lợi', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2077', N'Nậm Hàng', N'Xã Nậm Hàng', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2333', N'Mường Kim', N'Xã Mường Kim', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2589', N'Khoen On', N'Xã Khoen On', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2845', N'Than Uyên', N'Xã Than Uyên', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('285', N'Tà Tổng', N'Xã Tà Tổng', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3101', N'Mường Than', N'Xã Mường Than', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3357', N'Pắc Ta', N'Xã Pắc Ta', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3613', N'Nậm Sỏ', N'Xã Nậm Sỏ', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3869', N'Tân Uyên', N'Xã Tân Uyên', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4125', N'Mường Khoa', N'Xã Mường Khoa', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4381', N'Bản Bo', N'Xã Bản Bo', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4637', N'Bình Lư', N'Xã Bình Lư', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4893', N'Tả Lèng', N'Xã Tả Lèng', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5149', N'Khun Há', N'Xã Khun Há', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5405', N'Tân Phong', N'Phường Tân Phong', 'phuong', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('541', N'Mù Cả', N'Xã Mù Cả', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5661', N'Đoàn Kết', N'Phường Đoàn Kết', 'phuong', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5917', N'Sin Suối Hồ', N'Xã Sin Suối Hồ', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6173', N'Phong Thổ', N'Xã Phong Thổ', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6429', N'Sì Lở Lầu', N'Xã Sì Lở Lầu', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6685', N'Dào San', N'Xã Dào San', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6941', N'Khổng Lào', N'Xã Khổng Lào', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7197', N'Tủa Sín Chải', N'Xã Tủa Sín Chải', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7453', N'Sìn Hồ', N'Xã Sìn Hồ', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7709', N'Hồng Thu', N'Xã Hồng Thu', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7965', N'Nậm Tăm', N'Xã Nậm Tăm', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('797', N'Thu Lũm', N'Xã Thu Lũm', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8221', N'Pu Sam Cáp', N'Xã Pu Sam Cáp', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8477', N'Mường Mô', N'Xã Mường Mô', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8733', N'Hua Bum', N'Xã Hua Bum', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8989', N'Pa Tần', N'Xã Pa Tần', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9245', N'Bum Nưa', N'Xã Bum Nưa', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9501', N'Bum Tở', N'Xã Bum Tở', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9757', N'Mường Tè', N'Xã Mường Tè', 'xa', '29');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10014', N'Đam Rông 4', N'Xã Đam Rông 4', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10270', N'Di Linh', N'Xã Di Linh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10526', N'Hòa Ninh', N'Xã Hòa Ninh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1054', N'Ninh Gia', N'Xã Ninh Gia', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10782', N'Hòa Bắc', N'Xã Hòa Bắc', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11038', N'Đinh Trang Thượng', N'Xã Đinh Trang Thượng', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11294', N'Bảo Thuận', N'Xã Bảo Thuận', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11550', N'Sơn Điền', N'Xã Sơn Điền', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11806', N'Gia Hiệp', N'Xã Gia Hiệp', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12062', N'Bảo Lâm 1', N'Xã Bảo Lâm 1', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12318', N'Bảo Lâm 2', N'Xã Bảo Lâm 2', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12574', N'Bảo Lâm 3', N'Xã Bảo Lâm 3', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12830', N'Bảo Lâm 4', N'Xã Bảo Lâm 4', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13086', N'Bảo Lâm 5', N'Xã Bảo Lâm 5', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1310', N'Phan Rí Cửa', N'Xã Phan Rí Cửa', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13342', N'Đạ Huoai', N'Xã Đạ Huoai', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13598', N'Đạ Huoai 2', N'Xã Đạ Huoai 2', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13854', N'Đạ Tẻh', N'Xã Đạ Tẻh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14110', N'Đạ Tẻh 2', N'Xã Đạ Tẻh 2', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14366', N'Đạ Tẻh 3', N'Xã Đạ Tẻh 3', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14622', N'Cát Tiên', N'Xã Cát Tiên', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14878', N'Cát Tiên 2', N'Xã Cát Tiên 2', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15134', N'Cát Tiên 3', N'Xã Cát Tiên 3', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15390', N'Đắk Wil', N'Xã Đắk Wil', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15646', N'Nam Dong', N'Xã Nam Dong', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1566', N'Tuy Phong', N'Xã Tuy Phong', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15902', N'Cư Jút', N'Xã Cư Jút', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16158', N'Thuận An', N'Xã Thuận An', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16414', N'Đức Lập', N'Xã Đức Lập', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16670', N'Đắk Mil', N'Xã Đắk Mil', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16926', N'Đắk Sắk', N'Xã Đắk Sắk', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17182', N'Nam Đà', N'Xã Nam Đà', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17438', N'Krông Nô', N'Xã Krông Nô', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17694', N'Nâm Nung', N'Xã Nâm Nung', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17950', N'Quảng Phú', N'Xã Quảng Phú', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18206', N'Đắk Song', N'Xã Đắk Song', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1822', N'Hòa Thắng', N'Xã Hòa Thắng', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18462', N'Đức An', N'Xã Đức An', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18718', N'Thuận Hạnh', N'Xã Thuận Hạnh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18974', N'Trường Xuân', N'Xã Trường Xuân', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19230', N'Tà Đùng', N'Xã Tà Đùng', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19486', N'Quảng Khê', N'Xã Quảng Khê', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19742', N'Bắc Gia Nghĩa', N'Phường Bắc Gia Nghĩa', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19998', N'Nam Gia Nghĩa', N'Phường Nam Gia Nghĩa', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20254', N'Đông Gia Nghĩa', N'Phường Đông Gia Nghĩa', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20510', N'Quảng Tân', N'Xã Quảng Tân', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20766', N'Tuy Đức', N'Xã Tuy Đức', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2078', N'Phú Quý', N'Đặc Khu Phú Quý', 'dac-khu', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21022', N'Kiến Đức', N'Xã Kiến Đức', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21278', N'Nhân Cơ', N'Xã Nhân Cơ', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21534', N'Quảng Tín', N'Xã Quảng Tín', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21790', N'Vĩnh Hảo', N'Xã Vĩnh Hảo', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22046', N'Liên Hương', N'Xã Liên Hương', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22302', N'Bắc Bình', N'Xã Bắc Bình', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22558', N'Hải Ninh', N'Xã Hải Ninh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22814', N'Phan Sơn', N'Xã Phan Sơn', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23070', N'Sông Lũy', N'Xã Sông Lũy', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23326', N'Lương Sơn', N'Xã Lương Sơn', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2334', N'Hồng Thái', N'Xã Hồng Thái', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23582', N'Đông Giang', N'Xã Đông Giang', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23838', N'Tân Lập', N'Xã Tân Lập', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24094', N'Tân Minh', N'Xã Tân Minh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24350', N'Hàm Tân', N'Xã Hàm Tân', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24606', N'Sơn Mỹ', N'Xã Sơn Mỹ', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24862', N'La Gi', N'Phường La Gi', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25118', N'Phước Hội', N'Phường Phước Hội', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25374', N'Tân Hải', N'Xã Tân Hải', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25630', N'Nghị Đức', N'Xã Nghị Đức', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25886', N'Bắc Ruộng', N'Xã Bắc Ruộng', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2590', N'Đạ Huoai 3', N'Xã Đạ Huoai 3', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26142', N'Đồng Kho', N'Xã Đồng Kho', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26398', N'Tánh Linh', N'Xã Tánh Linh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26654', N'Suối Kiết', N'Xã Suối Kiết', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26910', N'Nam Thành', N'Xã Nam Thành', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27166', N'Đức Linh', N'Xã Đức Linh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27422', N'Hoài Đức', N'Xã Hoài Đức', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27678', N'Trà Tân', N'Xã Trà Tân', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27934', N'La Dạ', N'Xã La Dạ', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28190', N'Hàm Thuận Bắc', N'Xã Hàm Thuận Bắc', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28446', N'Hàm Thuận', N'Xã Hàm Thuận', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2846', N'Xuân Hương-Đà Lạt', N'Phường Xuân Hương-Đà Lạt', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('286', N'Quảng Hòa', N'Xã Quảng Hòa', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28702', N'Hồng Sơn', N'Xã Hồng Sơn', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28958', N'Hàm Liêm', N'Xã Hàm Liêm', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29214', N'Hàm Thắng', N'Phường Hàm Thắng', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29470', N'Bình Thuận', N'Phường Bình Thuận', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29726', N'Mũi Né', N'Phường Mũi Né', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29982', N'Phú Thủy', N'Phường Phú Thủy', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30238', N'Phan Thiết', N'Phường Phan Thiết', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30494', N'Tiến Thành', N'Phường Tiến Thành', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30750', N'Tuyên Quang', N'Xã Tuyên Quang', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31006', N'Hàm Thạnh', N'Xã Hàm Thạnh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3102', N'Cam Ly-Đà Lạt', N'Phường Cam Ly-Đà Lạt', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31262', N'Hàm Kiệm', N'Xã Hàm Kiệm', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31518', N'Tân Thành', N'Xã Tân Thành', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31774', N'Hàm Thuận Nam', N'Xã Hàm Thuận Nam', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3358', N'Lâm Viên-Đà Lạt', N'Phường Lâm Viên-Đà Lạt', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3614', N'Xuân Trường-Đà Lạt', N'Phường Xuân Trường-Đà Lạt', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3870', N'Lang Biang-Đà Lạt', N'Phường Lang Biang-Đà Lạt', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4126', N'1 Bảo Lộc', N'Phường 1 Bảo Lộc', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4382', N'2 Bảo Lộc', N'Phường 2 Bảo Lộc', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4638', N'3 Bảo Lộc', N'Phường 3 Bảo Lộc', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4894', N'B''Lao', N'Phường B''Lao', 'phuong', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5150', N'Đơn Dương', N'Xã Đơn Dương', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5406', N'Ka Đô', N'Xã Ka Đô', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('542', N'Quảng Sơn', N'Xã Quảng Sơn', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5662', N'Quảng Lập', N'Xã Quảng Lập', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5918', N'D''Ran', N'Xã D''Ran', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6174', N'Hiệp Thạnh', N'Xã Hiệp Thạnh', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6430', N'Lạc Dương', N'Xã Lạc Dương', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6686', N'Đức Trọng', N'Xã Đức Trọng', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6942', N'Tân Hội', N'Xã Tân Hội', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7198', N'Tà Hine', N'Xã Tà Hine', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7454', N'Tà Năng', N'Xã Tà Năng', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7710', N'Đinh Văn Lâm Hà', N'Xã Đinh Văn Lâm Hà', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7966', N'Phú Sơn Lâm Hà', N'Xã Phú Sơn Lâm Hà', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('798', N'Quảng Trực', N'Xã Quảng Trực', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8222', N'Nam Hà Lâm Hà', N'Xã Nam Hà Lâm Hà', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8478', N'Nam Ban Lâm Hà', N'Xã Nam Ban Lâm Hà', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8734', N'Tân Hà Lâm Hà', N'Xã Tân Hà Lâm Hà', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8990', N'Phúc Thọ Lâm Hà', N'Xã Phúc Thọ Lâm Hà', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9246', N'Đam Rông 1', N'Xã Đam Rông 1', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9502', N'Đam Rông 2', N'Xã Đam Rông 2', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9758', N'Đam Rông 3', N'Xã Đam Rông 3', 'xa', '30');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10015', N'Lợi Bác', N'Xã Lợi Bác', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10271', N'Thống Nhất', N'Xã Thống Nhất', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10527', N'Xuân Dương', N'Xã Xuân Dương', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1055', N'Thất Khê', N'Xã Thất Khê', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10783', N'Khuất Xá', N'Xã Khuất Xá', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11039', N'Thái Bình', N'Xã Thái Bình', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11295', N'Hữu Lũng', N'Xã Hữu Lũng', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11551', N'Tuấn Sơn', N'Xã Tuấn Sơn', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11807', N'Tân Thành', N'Xã Tân Thành', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12063', N'Vân Nham', N'Xã Vân Nham', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12319', N'Thiện Tân', N'Xã Thiện Tân', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12575', N'Yên Bình', N'Xã Yên Bình', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12831', N'Hữu Liên', N'Xã Hữu Liên', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13087', N'Cai Kinh', N'Xã Cai Kinh', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1311', N'Đoàn Kết', N'Xã Đoàn Kết', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13343', N'Chi Lăng', N'Xã Chi Lăng', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13599', N'Quan Sơn', N'Xã Quan Sơn', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13855', N'Chiến Thắng', N'Xã Chiến Thắng', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14111', N'Nhân Lý', N'Xã Nhân Lý', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14367', N'Bằng Mạc', N'Xã Bằng Mạc', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14623', N'Vạn Linh', N'Xã Vạn Linh', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14879', N'Đồng Đăng', N'Xã Đồng Đăng', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15135', N'Cao Lộc', N'Xã Cao Lộc', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15391', N'Công Sơn', N'Xã Công Sơn', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15647', N'Ba Sơn', N'Xã Ba Sơn', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1567', N'Tân Tiến', N'Xã Tân Tiến', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15903', N'Tam Thanh', N'Phường Tam Thanh', 'phuong', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16159', N'Lương Văn Tri', N'Phường Lương Văn Tri', 'phuong', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16415', N'Kỳ Lừa', N'Phường Kỳ Lừa', 'phuong', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16671', N'Đông Kinh', N'Phường Đông Kinh', 'phuong', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1823', N'Tràng Định', N'Xã Tràng Định', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2079', N'Quốc Khánh', N'Xã Quốc Khánh', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2335', N'Kháng Chiến', N'Xã Kháng Chiến', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2591', N'Quốc Việt', N'Xã Quốc Việt', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2847', N'Bình Gia', N'Xã Bình Gia', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('287', N'Châu Sơn', N'Xã Châu Sơn', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3103', N'Tân Văn', N'Xã Tân Văn', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3359', N'Hồng Phong', N'Xã Hồng Phong', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3615', N'Hoa Thám', N'Xã Hoa Thám', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3871', N'Quý Hòa', N'Xã Quý Hòa', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4127', N'Thiện Hòa', N'Xã Thiện Hòa', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4383', N'Thiện Thuật', N'Xã Thiện Thuật', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4639', N'Thiện Long', N'Xã Thiện Long', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4895', N'Bắc Sơn', N'Xã Bắc Sơn', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5151', N'Hưng Vũ', N'Xã Hưng Vũ', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5407', N'Vũ Lăng', N'Xã Vũ Lăng', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('543', N'Đình Lập', N'Xã Đình Lập', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5663', N'Nhất Hòa', N'Xã Nhất Hòa', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5919', N'Vũ Lễ', N'Xã Vũ Lễ', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6175', N'Tân Tri', N'Xã Tân Tri', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6431', N'Văn Quan', N'Xã Văn Quan', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6687', N'Điềm He', N'Xã Điềm He', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6943', N'Yên Phúc', N'Xã Yên Phúc', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7199', N'Tri Lễ', N'Xã Tri Lễ', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7455', N'Tân Đoàn', N'Xã Tân Đoàn', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7711', N'Khánh Khê', N'Xã Khánh Khê', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7967', N'Na Sầm', N'Xã Na Sầm', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('799', N'Kiên Mộc', N'Xã Kiên Mộc', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8223', N'Hoàng Văn Thụ', N'Xã Hoàng Văn Thụ', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8479', N'Thụy Hùng', N'Xã Thụy Hùng', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8735', N'Văn Lãng', N'Xã Văn Lãng', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8991', N'Hội Hoan', N'Xã Hội Hoan', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9247', N'Lộc Bình', N'Xã Lộc Bình', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9503', N'Mẫu Sơn', N'Xã Mẫu Sơn', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9759', N'Na Dương', N'Xã Na Dương', 'xa', '31');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10016', N'Mường Lai', N'Xã Mường Lai', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10272', N'Cảm Nhân', N'Xã Cảm Nhân', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10528', N'Yên Thành', N'Xã Yên Thành', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1056', N'Tà Xi Láng', N'Xã Tà Xi Láng', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10784', N'Thác Bà', N'Xã Thác Bà', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11040', N'Yên Bình', N'Xã Yên Bình', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11296', N'Bảo Ái', N'Xã Bảo Ái', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11552', N'Văn Phú', N'Phường Văn Phú', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11808', N'Yên Bái', N'Phường Yên Bái', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12064', N'Nam Cường', N'Phường Nam Cường', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12320', N'Âu Lâu', N'Phường Âu Lâu', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12576', N'Trấn Yên', N'Xã Trấn Yên', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12832', N'Hưng Khánh', N'Xã Hưng Khánh', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13088', N'Lương Thịnh', N'Xã Lương Thịnh', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1312', N'Chế Tạo', N'Xã Chế Tạo', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13344', N'Việt Hồng', N'Xã Việt Hồng', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13600', N'Quy Mông', N'Xã Quy Mông', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13856', N'Phong Hải', N'Xã Phong Hải', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14112', N'Xuân Quang', N'Xã Xuân Quang', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14368', N'Bảo Thắng', N'Xã Bảo Thắng', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14624', N'Tằng Loỏng', N'Xã Tằng Loỏng', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14880', N'Gia Phú', N'Xã Gia Phú', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15136', N'Cam Đường', N'Phường Cam Đường', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15392', N'Lào Cai', N'Phường Lào Cai', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15648', N'Cốc San', N'Xã Cốc San', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1568', N'Lao Chải', N'Xã Lao Chải', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15904', N'Hợp Thành', N'Xã Hợp Thành', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16160', N'Mường Hum', N'Xã Mường Hum', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16416', N'Dền Sáng', N'Xã Dền Sáng', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16672', N'Y Tý', N'Xã Y Tý', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16928', N'A Mú Sung', N'Xã A Mú Sung', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17184', N'Trịnh Tường', N'Xã Trịnh Tường', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17440', N'Bản Xèo', N'Xã Bản Xèo', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17696', N'Bát Xát', N'Xã Bát Xát', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17952', N'Bảo Yên', N'Xã Bảo Yên', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18208', N'Nghĩa Đô', N'Xã Nghĩa Đô', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1824', N'Cát Thịnh', N'Xã Cát Thịnh', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18464', N'Thượng Hà', N'Xã Thượng Hà', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18720', N'Xuân Hòa', N'Xã Xuân Hòa', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18976', N'Phúc Khánh', N'Xã Phúc Khánh', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19232', N'Bảo Hà', N'Xã Bảo Hà', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19488', N'Võ Lao', N'Xã Võ Lao', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19744', N'Khánh Yên', N'Xã Khánh Yên', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20000', N'Văn Bàn', N'Xã Văn Bàn', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20256', N'Dương Quỳ', N'Xã Dương Quỳ', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20512', N'Chiềng Ken', N'Xã Chiềng Ken', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20768', N'Minh Lương', N'Xã Minh Lương', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2080', N'Ngũ Chỉ Sơn', N'Xã Ngũ Chỉ Sơn', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21024', N'Nậm Chày', N'Xã Nậm Chày', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21280', N'Mường Bo', N'Xã Mường Bo', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21536', N'Bản Hồ', N'Xã Bản Hồ', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21792', N'Sa Pa', N'Phường Sa Pa', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22048', N'Tả Phìn', N'Xã Tả Phìn', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22304', N'Tả Van', N'Xã Tả Van', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22560', N'Cốc Lầu', N'Xã Cốc Lầu', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22816', N'Bảo Nhai', N'Xã Bảo Nhai', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23072', N'Bản Liền', N'Xã Bản Liền', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23328', N'Bắc Hà', N'Xã Bắc Hà', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2336', N'Khao Mang', N'Xã Khao Mang', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23584', N'Tả Củ Tỷ', N'Xã Tả Củ Tỷ', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23840', N'Lùng Phình', N'Xã Lùng Phình', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24096', N'Pha Long', N'Xã Pha Long', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24352', N'Mường Khương', N'Xã Mường Khương', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24608', N'Bản Lầu', N'Xã Bản Lầu', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24864', N'Cao Sơn', N'Xã Cao Sơn', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25120', N'Si Ma Cai', N'Xã Si Ma Cai', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25376', N'Sín Chéng', N'Xã Sín Chéng', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2592', N'Mù Cang Chải', N'Xã Mù Cang Chải', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2848', N'Púng Luông', N'Xã Púng Luông', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('288', N'Phong Dụ Thượng', N'Xã Phong Dụ Thượng', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3104', N'Trạm Tấu', N'Xã Trạm Tấu', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3360', N'Hạnh Phúc', N'Xã Hạnh Phúc', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3616', N'Phình Hồ', N'Xã Phình Hồ', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3872', N'Liên Sơn', N'Xã Liên Sơn', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4128', N'Nghĩa Lộ', N'Phường Nghĩa Lộ', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4384', N'Trung Tâm', N'Phường Trung Tâm', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4640', N'Cầu Thia', N'Phường Cầu Thia', 'phuong', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4896', N'Tú Lệ', N'Xã Tú Lệ', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5152', N'Gia Hội', N'Xã Gia Hội', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5408', N'Sơn Lương', N'Xã Sơn Lương', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('544', N'Nậm Có', N'Xã Nậm Có', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5664', N'Văn Chấn', N'Xã Văn Chấn', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5920', N'Thượng Bằng La', N'Xã Thượng Bằng La', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6176', N'Chấn Thịnh', N'Xã Chấn Thịnh', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6432', N'Nghĩa Tâm', N'Xã Nghĩa Tâm', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6688', N'Phong Dụ Hạ', N'Xã Phong Dụ Hạ', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6944', N'Châu Quế', N'Xã Châu Quế', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7200', N'Lâm Giang', N'Xã Lâm Giang', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7456', N'Đông Cuông', N'Xã Đông Cuông', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7712', N'Tân Hợp', N'Xã Tân Hợp', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7968', N'Mậu A', N'Xã Mậu A', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('800', N'Nậm Xé', N'Xã Nậm Xé', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8224', N'Xuân Ái', N'Xã Xuân Ái', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8480', N'Mỏ Vàng', N'Xã Mỏ Vàng', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8736', N'Lâm Thượng', N'Xã Lâm Thượng', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8992', N'Lục Yên', N'Xã Lục Yên', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9248', N'Tân Lĩnh', N'Xã Tân Lĩnh', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9504', N'Khánh Hòa', N'Xã Khánh Hòa', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9760', N'Phúc Lợi', N'Xã Phúc Lợi', 'xa', '32');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10017', N'Hưng Nguyên', N'Xã Hưng Nguyên', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10273', N'Hưng Nguyên Nam', N'Xã Hưng Nguyên Nam', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10529', N'Lam Thành', N'Xã Lam Thành', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1057', N'Keng Đu', N'Xã Keng Đu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10785', N'Mường Xén', N'Xã Mường Xén', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11041', N'Hữu Kiệm', N'Xã Hữu Kiệm', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11297', N'Nậm Cắn', N'Xã Nậm Cắn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11553', N'Chiêu Lưu', N'Xã Chiêu Lưu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11809', N'Na Loi', N'Xã Na Loi', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12065', N'Mường Típ', N'Xã Mường Típ', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12321', N'Na Ngoi', N'Xã Na Ngoi', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12577', N'Vạn An', N'Xã Vạn An', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12833', N'Nam Đàn', N'Xã Nam Đàn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13089', N'Đại Huệ', N'Xã Đại Huệ', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1313', N'Mường Lống', N'Xã Mường Lống', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13345', N'Thiên Nhẫn', N'Xã Thiên Nhẫn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13601', N'Kim Liên', N'Xã Kim Liên', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13857', N'Nghĩa Đàn', N'Xã Nghĩa Đàn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14113', N'Nghĩa Thọ', N'Xã Nghĩa Thọ', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14369', N'Nghĩa Lâm', N'Xã Nghĩa Lâm', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14625', N'Nghĩa Mai', N'Xã Nghĩa Mai', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14881', N'Nghĩa Hưng', N'Xã Nghĩa Hưng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15137', N'Nghĩa Khánh', N'Xã Nghĩa Khánh', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15393', N'Nghĩa Lộc', N'Xã Nghĩa Lộc', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15649', N'Nghi Lộc', N'Xã Nghi Lộc', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1569', N'Mỹ Lý', N'Xã Mỹ Lý', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15905', N'Phúc Lộc', N'Xã Phúc Lộc', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16161', N'Đông Lộc', N'Xã Đông Lộc', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16417', N'Trung Lộc', N'Xã Trung Lộc', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16673', N'Thần Lĩnh', N'Xã Thần Lĩnh', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16929', N'Hải Lộc', N'Xã Hải Lộc', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17185', N'Văn Kiều', N'Xã Văn Kiều', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17441', N'Tiền Phong', N'Xã Tiền Phong', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17697', N'Tri Lễ', N'Xã Tri Lễ', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17953', N'Mường Quàng', N'Xã Mường Quàng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18209', N'Thông Thụ', N'Xã Thông Thụ', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1825', N'Bình Chuẩn', N'Xã Bình Chuẩn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18465', N'Quỳ Châu', N'Xã Quỳ Châu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18721', N'Châu Tiến', N'Xã Châu Tiến', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18977', N'Hùng Chân', N'Xã Hùng Chân', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19233', N'Quỳ Hợp', N'Xã Quỳ Hợp', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19489', N'Tam Hợp', N'Xã Tam Hợp', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19745', N'Châu Lộc', N'Xã Châu Lộc', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20001', N'Châu Hồng', N'Xã Châu Hồng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20257', N'Mường Ham', N'Xã Mường Ham', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20513', N'Mường Chọng', N'Xã Mường Chọng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20769', N'Minh Hợp', N'Xã Minh Hợp', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2081', N'Châu Bình', N'Xã Châu Bình', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21025', N'Quỳnh Lưu', N'Xã Quỳnh Lưu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21281', N'Quỳnh Văn', N'Xã Quỳnh Văn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21537', N'Quỳnh Tam', N'Xã Quỳnh Tam', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21793', N'Quỳnh Phú', N'Xã Quỳnh Phú', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22049', N'Quỳnh Sơn', N'Xã Quỳnh Sơn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22305', N'Quỳnh Thắng', N'Xã Quỳnh Thắng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22561', N'Tân Kỳ', N'Xã Tân Kỳ', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22817', N'Tân Phú', N'Xã Tân Phú', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23073', N'Tân An', N'Xã Tân An', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23329', N'Nghĩa Đồng', N'Xã Nghĩa Đồng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2337', N'Lượng Minh', N'Xã Lượng Minh', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23585', N'Giai Xuân', N'Xã Giai Xuân', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23841', N'Nghĩa Hành', N'Xã Nghĩa Hành', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24097', N'Tiên Đồng', N'Xã Tiên Đồng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24353', N'Cát Ngạn', N'Xã Cát Ngạn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24609', N'Tam Đồng', N'Xã Tam Đồng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24865', N'Hạnh Lâm', N'Xã Hạnh Lâm', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25121', N'Sơn Lâm', N'Xã Sơn Lâm', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25377', N'Hoa Quân', N'Xã Hoa Quân', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25633', N'Kim Bảng', N'Xã Kim Bảng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25889', N'Bích Hào', N'Xã Bích Hào', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2593', N'Quỳnh Anh', N'Xã Quỳnh Anh', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26145', N'Đại Đồng', N'Xã Đại Đồng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26401', N'Xuân Lâm', N'Xã Xuân Lâm', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26657', N'Thái Hòa', N'Phường Thái Hòa', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26913', N'Tây Hiếu', N'Phường Tây Hiếu', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27169', N'Đông Hiếu', N'Xã Đông Hiếu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27425', N'Tam Quang', N'Xã Tam Quang', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27681', N'Tam Thái', N'Xã Tam Thái', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27937', N'Tương Dương', N'Xã Tương Dương', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28193', N'Yên Na', N'Xã Yên Na', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28449', N'Yên Hòa', N'Xã Yên Hòa', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2849', N'Anh Sơn', N'Xã Anh Sơn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28705', N'Nga My', N'Xã Nga My', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('289', N'Hữu Khuông', N'Xã Hữu Khuông', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28961', N'Nhôn Mai', N'Xã Nhôn Mai', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29217', N'Thành Vinh', N'Phường Thành Vinh', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29473', N'Vinh Hưng', N'Phường Vinh Hưng', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29729', N'Vinh Phú', N'Phường Vinh Phú', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29985', N'Vinh Lộc', N'Phường Vinh Lộc', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30241', N'Yên Thành', N'Xã Yên Thành', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30497', N'Quan Thành', N'Xã Quan Thành', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30753', N'Hợp Minh', N'Xã Hợp Minh', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31009', N'Vân Tụ', N'Xã Vân Tụ', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3105', N'Yên Xuân', N'Xã Yên Xuân', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31265', N'Vân Du', N'Xã Vân Du', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31521', N'Quang Đồng', N'Xã Quang Đồng', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31777', N'Giai Lạc', N'Xã Giai Lạc', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32033', N'Bình Minh', N'Xã Bình Minh', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32289', N'Đông Thành', N'Xã Đông Thành', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32545', N'Yên Trung', N'Xã Yên Trung', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32801', N'Cửa Lò', N'Phường Cửa Lò', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33057', N'Quế Phong', N'Xã Quế Phong', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33313', N'Trường Vinh', N'Phường Trường Vinh', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3361', N'Nhân Hòa', N'Xã Nhân Hòa', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3617', N'Anh Sơn Đông', N'Xã Anh Sơn Đông', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3873', N'Vĩnh Tường', N'Xã Vĩnh Tường', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4129', N'Thành Bình Thọ', N'Xã Thành Bình Thọ', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4385', N'Con Cuông', N'Xã Con Cuông', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4641', N'Môn Sơn', N'Xã Môn Sơn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4897', N'Mậu Thạch', N'Xã Mậu Thạch', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5153', N'Cam Phục', N'Xã Cam Phục', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5409', N'Châu Khê', N'Xã Châu Khê', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('545', N'Huồi Tụ', N'Xã Huồi Tụ', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5665', N'Diễn Châu', N'Xã Diễn Châu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5921', N'Đức Châu', N'Xã Đức Châu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6177', N'Quảng Châu', N'Xã Quảng Châu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6433', N'Hải Châu', N'Xã Hải Châu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6689', N'Tân Châu', N'Xã Tân Châu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6945', N'An Châu', N'Xã An Châu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7201', N'Minh Châu', N'Xã Minh Châu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7457', N'Hùng Châu', N'Xã Hùng Châu', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7713', N'Đô Lương', N'Xã Đô Lương', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7969', N'Bạch Ngọc', N'Xã Bạch Ngọc', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('801', N'Bắc Lý', N'Xã Bắc Lý', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8225', N'Văn Hiến', N'Xã Văn Hiến', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8481', N'Bạch Hà', N'Xã Bạch Hà', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8737', N'Thuần Trung', N'Xã Thuần Trung', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8993', N'Lương Sơn', N'Xã Lương Sơn', 'xa', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9249', N'Hoàng Mai', N'Phường Hoàng Mai', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9505', N'Tân Mai', N'Phường Tân Mai', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9761', N'Quỳnh Mai', N'Phường Quỳnh Mai', 'phuong', '33');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10018', N'Chất Bình', N'Xã Chất Bình', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10274', N'Kim Sơn', N'Xã Kim Sơn', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10530', N'Quang Thiện', N'Xã Quang Thiện', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1058', N'Thanh Bình', N'Xã Thanh Bình', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10786', N'Phát Diệm', N'Xã Phát Diệm', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11042', N'Lai Thành', N'Xã Lai Thành', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11298', N'Định Hóa', N'Xã Định Hóa', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11554', N'Bình Minh', N'Xã Bình Minh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11810', N'Kim Đông', N'Xã Kim Đông', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12066', N'Nam Định', N'Phường Nam Định', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12322', N'Thiên Trường', N'Phường Thiên Trường', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12578', N'Đông A', N'Phường Đông A', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12834', N'Thành Nam', N'Phường Thành Nam', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13090', N'Trường Thi', N'Phường Trường Thi', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1314', N'Thanh Liêm', N'Xã Thanh Liêm', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13346', N'Hồng Quang', N'Phường Hồng Quang', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13602', N'Nam Trực', N'Xã Nam Trực', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13858', N'Nam Minh', N'Xã Nam Minh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14114', N'Nam Đồng', N'Xã Nam Đồng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14370', N'Nam Ninh', N'Xã Nam Ninh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14626', N'Nam Hồng', N'Xã Nam Hồng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14882', N'Minh Tân', N'Xã Minh Tân', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15138', N'Hiển Khánh', N'Xã Hiển Khánh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15394', N'Vụ Bản', N'Xã Vụ Bản', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15650', N'Liên Minh', N'Xã Liên Minh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1570', N'Hà Nam', N'Phường Hà Nam', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15906', N'Ý Yên', N'Xã Ý Yên', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16162', N'Yên Đồng', N'Xã Yên Đồng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16418', N'Yên Cường', N'Xã Yên Cường', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16674', N'Vạn Thắng', N'Xã Vạn Thắng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16930', N'Vũ Dương', N'Xã Vũ Dương', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17186', N'Tân Minh', N'Xã Tân Minh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17442', N'Phong Doanh', N'Xã Phong Doanh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17698', N'Cổ Lễ', N'Xã Cổ Lễ', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17954', N'Ninh Giang', N'Xã Ninh Giang', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18210', N'Cát Thành', N'Xã Cát Thành', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1826', N'Tiên Sơn', N'Phường Tiên Sơn', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18466', N'Trực Ninh', N'Xã Trực Ninh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18722', N'Quang Hưng', N'Xã Quang Hưng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18978', N'Minh Thái', N'Xã Minh Thái', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19234', N'Ninh Cường', N'Xã Ninh Cường', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19490', N'Xuân Trường', N'Xã Xuân Trường', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19746', N'Xuân Hưng', N'Xã Xuân Hưng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20002', N'Xuân Giang', N'Xã Xuân Giang', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20258', N'Xuân Hồng', N'Xã Xuân Hồng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20514', N'Hải Hậu', N'Xã Hải Hậu', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20770', N'Hải Anh', N'Xã Hải Anh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2082', N'Mỹ Lộc', N'Phường Mỹ Lộc', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21026', N'Hải Tiến', N'Xã Hải Tiến', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21282', N'Hải Hưng', N'Xã Hải Hưng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21538', N'Hải An', N'Xã Hải An', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21794', N'Hải Quang', N'Xã Hải Quang', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22050', N'Hải Xuân', N'Xã Hải Xuân', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22306', N'Hải Thịnh', N'Xã Hải Thịnh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22562', N'Đồng Thịnh', N'Xã Đồng Thịnh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22818', N'Nghĩa Hưng', N'Xã Nghĩa Hưng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23074', N'Nghĩa Sơn', N'Xã Nghĩa Sơn', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23330', N'Hồng Phong', N'Xã Hồng Phong', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2338', N'Hoa Lư', N'Phường Hoa Lư', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23586', N'Quỹ Nhất', N'Xã Quỹ Nhất', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23842', N'Nghĩa Lâm', N'Xã Nghĩa Lâm', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24098', N'Rạng Đông', N'Xã Rạng Đông', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24354', N'Vị Khê', N'Phường Vị Khê', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24610', N'Giao Minh', N'Xã Giao Minh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24866', N'Giao Hòa', N'Xã Giao Hòa', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25122', N'Giao Thủy', N'Xã Giao Thủy', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25378', N'Giao Phúc', N'Xã Giao Phúc', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25634', N'Giao Hưng', N'Xã Giao Hưng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25890', N'Giao Bình', N'Xã Giao Bình', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2594', N'Nam Hoa Lư', N'Phường Nam Hoa Lư', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26146', N'Giao Ninh', N'Xã Giao Ninh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26402', N'Đồng Văn', N'Phường Đồng Văn', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26658', N'Lê Hồ', N'Phường Lê Hồ', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26914', N'Nguyễn Úy', N'Phường Nguyễn Úy', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27170', N'Lý Thường Kiệt', N'Phường Lý Thường Kiệt', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27426', N'Kim Thanh', N'Phường Kim Thanh', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27682', N'Tam Chúc', N'Phường Tam Chúc', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27938', N'Phù Vân', N'Phường Phù Vân', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28194', N'Châu Sơn', N'Phường Châu Sơn', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28450', N'Liêm Tuyền', N'Phường Liêm Tuyền', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2850', N'Đông Hoa Lư', N'Phường Đông Hoa Lư', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28706', N'Bình Lục', N'Xã Bình Lục', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28962', N'Bình Mỹ', N'Xã Bình Mỹ', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('290', N'Duy Tân', N'Phường Duy Tân', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29218', N'Bình An', N'Xã Bình An', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29474', N'Bình Giang', N'Xã Bình Giang', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29730', N'Bình Sơn', N'Xã Bình Sơn', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29986', N'Liêm Hà', N'Xã Liêm Hà', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30242', N'Tân Thanh', N'Xã Tân Thanh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30498', N'Thanh Lâm', N'Xã Thanh Lâm', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30754', N'Lý Nhân', N'Xã Lý Nhân', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31010', N'Nam Xang', N'Xã Nam Xang', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3106', N'Tam Điệp', N'Phường Tam Điệp', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31266', N'Bắc Lý', N'Xã Bắc Lý', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31522', N'Vĩnh Trụ', N'Xã Vĩnh Trụ', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31778', N'Trần Thương', N'Xã Trần Thương', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32034', N'Nhân Hà', N'Xã Nhân Hà', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32290', N'Nam Lý', N'Xã Nam Lý', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32546', N'Kim Bảng', N'Phường Kim Bảng', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32802', N'Duy Tiên', N'Phường Duy Tiên', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33058', N'Phủ Lý', N'Phường Phủ Lý', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3362', N'Yên Sơn', N'Phường Yên Sơn', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3618', N'Trung Sơn', N'Phường Trung Sơn', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3874', N'Yên Thắng', N'Phường Yên Thắng', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4130', N'Gia Viễn', N'Xã Gia Viễn', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4386', N'Đại Hoàng', N'Xã Đại Hoàng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4642', N'Gia Hưng', N'Xã Gia Hưng', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4898', N'Gia Phong', N'Xã Gia Phong', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5154', N'Gia Vân', N'Xã Gia Vân', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5410', N'Gia Trấn', N'Xã Gia Trấn', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('546', N'Duy Hà', N'Phường Duy Hà', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5666', N'Nho Quan', N'Xã Nho Quan', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5922', N'Gia Lâm', N'Xã Gia Lâm', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6178', N'Gia Tường', N'Xã Gia Tường', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6434', N'Phú Sơn', N'Xã Phú Sơn', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6690', N'Cúc Phương', N'Xã Cúc Phương', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6946', N'Phú Long', N'Xã Phú Long', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7202', N'Thanh Sơn', N'Xã Thanh Sơn', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7458', N'Quỳnh Lưu', N'Xã Quỳnh Lưu', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7714', N'Yên Khánh', N'Xã Yên Khánh', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7970', N'Khánh Nhạc', N'Xã Khánh Nhạc', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('802', N'Tây Hoa Lư', N'Phường Tây Hoa Lư', 'phuong', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8226', N'Khánh Thiện', N'Xã Khánh Thiện', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8482', N'Khánh Hội', N'Xã Khánh Hội', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8738', N'Khánh Trung', N'Xã Khánh Trung', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8994', N'Yên Mô', N'Xã Yên Mô', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9250', N'Yên Từ', N'Xã Yên Từ', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9506', N'Yên Mạc', N'Xã Yên Mạc', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9762', N'Đồng Thái', N'Xã Đồng Thái', 'xa', '34');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10019', N'Tân Mai', N'Xã Tân Mai', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10275', N'Tân Lạc', N'Xã Tân Lạc', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10531', N'Mường Bi', N'Xã Mường Bi', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1059', N'Liên Sơn', N'Xã Liên Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10787', N'Toàn Thắng', N'Xã Toàn Thắng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11043', N'Mường Hoa', N'Xã Mường Hoa', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11299', N'Vân Sơn', N'Xã Vân Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11555', N'Yên Thủy', N'Xã Yên Thủy', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11811', N'Lạc Lương', N'Xã Lạc Lương', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12067', N'Yên Trị', N'Xã Yên Trị', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12323', N'Thịnh Minh', N'Xã Thịnh Minh', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12579', N'Hòa Bình', N'Phường Hòa Bình', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12835', N'Kỳ Sơn', N'Phường Kỳ Sơn', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13091', N'Tân Hòa', N'Phường Tân Hòa', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1315', N'Mai Châu', N'Xã Mai Châu', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13347', N'Tam Sơn', N'Xã Tam Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13603', N'Sông Lô', N'Xã Sông Lô', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13859', N'Hải Lựu', N'Xã Hải Lựu', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14115', N'Yên Lãng', N'Xã Yên Lãng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14371', N'Lập Thạch', N'Xã Lập Thạch', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14627', N'Tiên Lữ', N'Xã Tiên Lữ', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14883', N'Thái Hòa', N'Xã Thái Hòa', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15139', N'Liên Hòa', N'Xã Liên Hòa', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15395', N'Hợp Lý', N'Xã Hợp Lý', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15651', N'Sơn Đông', N'Xã Sơn Đông', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1571', N'Pà Cò', N'Xã Pà Cò', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15907', N'Tam Đảo', N'Xã Tam Đảo', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16163', N'Đại Đình', N'Xã Đại Đình', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16419', N'Tam Dương', N'Xã Tam Dương', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16675', N'Hội Thịnh', N'Xã Hội Thịnh', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16931', N'Hoàng An', N'Xã Hoàng An', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17187', N'Tam Dương Bắc', N'Xã Tam Dương Bắc', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17443', N'Vĩnh Tường', N'Xã Vĩnh Tường', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17699', N'Thổ Tang', N'Xã Thổ Tang', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17955', N'Vĩnh Hưng', N'Xã Vĩnh Hưng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18211', N'Vĩnh An', N'Xã Vĩnh An', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1827', N'Thống Nhất', N'Phường Thống Nhất', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18467', N'Vĩnh Phú', N'Xã Vĩnh Phú', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18723', N'Vĩnh Thành', N'Xã Vĩnh Thành', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18979', N'Yên Lạc', N'Xã Yên Lạc', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19235', N'Tề Lỗ', N'Xã Tề Lỗ', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19491', N'Liên Châu', N'Xã Liên Châu', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19747', N'Tam Hồng', N'Xã Tam Hồng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20003', N'Nguyệt Đức', N'Xã Nguyệt Đức', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20259', N'Bình Nguyên', N'Xã Bình Nguyên', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20515', N'Xuân Lãng', N'Xã Xuân Lãng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20771', N'Bình Xuyên', N'Xã Bình Xuyên', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2083', N'Đạo Trù', N'Xã Đạo Trù', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21027', N'Bình Tuyền', N'Xã Bình Tuyền', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21283', N'Vĩnh Phúc', N'Phường Vĩnh Phúc', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21539', N'Vĩnh Yên', N'Phường Vĩnh Yên', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21795', N'Vân Phú', N'Phường Vân Phú', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22051', N'Hy Cương', N'Xã Hy Cương', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22307', N'Lâm Thao', N'Xã Lâm Thao', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22563', N'Xuân Lũng', N'Xã Xuân Lũng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22819', N'Phùng Nguyên', N'Xã Phùng Nguyên', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23075', N'Bản Nguyên', N'Xã Bản Nguyên', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23331', N'Phong Châu', N'Phường Phong Châu', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2339', N'Phúc Yên', N'Phường Phúc Yên', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23587', N'Phú Thọ', N'Phường Phú Thọ', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23843', N'Âu Cơ', N'Phường Âu Cơ', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24099', N'Phù Ninh', N'Xã Phù Ninh', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24355', N'Dân Chủ', N'Xã Dân Chủ', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24611', N'Phú Mỹ', N'Xã Phú Mỹ', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24867', N'Trạm Thản', N'Xã Trạm Thản', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25123', N'Bình Phú', N'Xã Bình Phú', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25379', N'Thanh Ba', N'Xã Thanh Ba', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25635', N'Quảng Yên', N'Xã Quảng Yên', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25891', N'Hoàng Cương', N'Xã Hoàng Cương', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2595', N'Xuân Hòa', N'Phường Xuân Hòa', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26147', N'Đông Thành', N'Xã Đông Thành', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26403', N'Chí Tiên', N'Xã Chí Tiên', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26659', N'Liên Minh', N'Xã Liên Minh', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26915', N'Đoan Hùng', N'Xã Đoan Hùng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27171', N'Tây Cốc', N'Xã Tây Cốc', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27427', N'Chân Mộng', N'Xã Chân Mộng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27683', N'Chí Đám', N'Xã Chí Đám', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27939', N'Bằng Luân', N'Xã Bằng Luân', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28195', N'Hạ Hòa', N'Xã Hạ Hòa', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28451', N'Đan Thượng', N'Xã Đan Thượng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2851', N'Lương Sơn', N'Xã Lương Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28707', N'Yên Kỳ', N'Xã Yên Kỳ', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28963', N'Vĩnh Chân', N'Xã Vĩnh Chân', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('291', N'Trung Sơn', N'Xã Trung Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29219', N'Văn Lang', N'Xã Văn Lang', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29475', N'Hiền Lương', N'Xã Hiền Lương', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29731', N'Cẩm Khê', N'Xã Cẩm Khê', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29987', N'Phú Khê', N'Xã Phú Khê', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30243', N'Hùng Việt', N'Xã Hùng Việt', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30499', N'Đồng Lương', N'Xã Đồng Lương', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30755', N'Tiên Lương', N'Xã Tiên Lương', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31011', N'Vân Bán', N'Xã Vân Bán', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3107', N'Cao Phong', N'Xã Cao Phong', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31267', N'Tam Nông', N'Xã Tam Nông', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31523', N'Thọ Văn', N'Xã Thọ Văn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31779', N'Vạn Xuân', N'Xã Vạn Xuân', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32035', N'Hiền Quan', N'Xã Hiền Quan', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32291', N'Thanh Thủy', N'Xã Thanh Thủy', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32547', N'Đào Xá', N'Xã Đào Xá', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32803', N'Tu Vũ', N'Xã Tu Vũ', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33059', N'Thanh Sơn', N'Xã Thanh Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33315', N'Võ Miếu', N'Xã Võ Miếu', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33571', N'Văn Miếu', N'Xã Văn Miếu', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3363', N'Mường Thàng', N'Xã Mường Thàng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33827', N'Cự Đồng', N'Xã Cự Đồng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34083', N'Hương Cần', N'Xã Hương Cần', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34339', N'Yên Sơn', N'Xã Yên Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34595', N'Khả Cửu', N'Xã Khả Cửu', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34851', N'Tân Sơn', N'Xã Tân Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35107', N'Minh Đài', N'Xã Minh Đài', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35363', N'Lai Đồng', N'Xã Lai Đồng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35619', N'Xuân Đài', N'Xã Xuân Đài', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35875', N'Long Cốc', N'Xã Long Cốc', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36131', N'Yên Lập', N'Xã Yên Lập', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3619', N'Thung Nai', N'Xã Thung Nai', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36387', N'Thượng Long', N'Xã Thượng Long', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36643', N'Sơn Lương', N'Xã Sơn Lương', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36899', N'Xuân Viên', N'Xã Xuân Viên', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37155', N'Minh Hòa', N'Xã Minh Hòa', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37411', N'Việt Trì', N'Phường Việt Trì', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37667', N'Nông Trang', N'Phường Nông Trang', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37923', N'Thanh Miếu', N'Phường Thanh Miếu', 'phuong', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3875', N'Đà Bắc', N'Xã Đà Bắc', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4131', N'Cao Sơn', N'Xã Cao Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4387', N'Đức Nhàn', N'Xã Đức Nhàn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4643', N'Quy Đức', N'Xã Quy Đức', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4899', N'Tân Pheo', N'Xã Tân Pheo', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5155', N'Kim Bôi', N'Xã Kim Bôi', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5411', N'Mường Động', N'Xã Mường Động', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('547', N'Thu Cúc', N'Xã Thu Cúc', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5667', N'Dũng Tiến', N'Xã Dũng Tiến', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5923', N'Hợp Kim', N'Xã Hợp Kim', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6179', N'Nật Sơn', N'Xã Nật Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6435', N'Lạc Sơn', N'Xã Lạc Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6691', N'Mường Vang', N'Xã Mường Vang', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6947', N'Đại Đồng', N'Xã Đại Đồng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7203', N'Ngọc Sơn', N'Xã Ngọc Sơn', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7459', N'Nhân Nghĩa', N'Xã Nhân Nghĩa', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7715', N'Quyết Thắng', N'Xã Quyết Thắng', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7971', N'Thượng Cốc', N'Xã Thượng Cốc', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('803', N'Tiền Phong', N'Xã Tiền Phong', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8227', N'Yên Phú', N'Xã Yên Phú', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8483', N'Lạc Thủy', N'Xã Lạc Thủy', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8739', N'An Bình', N'Xã An Bình', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8995', N'An Nghĩa', N'Xã An Nghĩa', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9251', N'Cao Dương', N'Xã Cao Dương', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9507', N'Bao La', N'Xã Bao La', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9763', N'Mai Hạ', N'Xã Mai Hạ', 'xa', '35');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10020', N'Lân Phong', N'Xã Lân Phong', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10276', N'Trà Bồng', N'Xã Trà Bồng', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10532', N'Đông Trà Bồng', N'Xã Đông Trà Bồng', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1060', N'Vạn Tường', N'Xã Vạn Tường', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10788', N'Tây Trà', N'Xã Tây Trà', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11044', N'Thanh Bồng', N'Xã Thanh Bồng', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11300', N'Sơn Hạ', N'Xã Sơn Hạ', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11556', N'Sơn Linh', N'Xã Sơn Linh', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11812', N'Sơn Hà', N'Xã Sơn Hà', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12068', N'Sơn Thủy', N'Xã Sơn Thủy', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12324', N'Sơn Kỳ', N'Xã Sơn Kỳ', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12580', N'Sơn Tây', N'Xã Sơn Tây', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12836', N'Sơn Tây Thượng', N'Xã Sơn Tây Thượng', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13092', N'Sơn Tây Hạ', N'Xã Sơn Tây Hạ', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1316', N'Mô Rai', N'Xã Mô Rai', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13348', N'Minh Long', N'Xã Minh Long', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13604', N'Sơn Mai', N'Xã Sơn Mai', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13860', N'Ba Vì', N'Xã Ba Vì', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14116', N'Ba Tô', N'Xã Ba Tô', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14372', N'Ba Dinh', N'Xã Ba Dinh', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14628', N'Ba Tơ', N'Xã Ba Tơ', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14884', N'Ba Vinh', N'Xã Ba Vinh', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15140', N'Ba Động', N'Xã Ba Động', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15396', N'Đặng Thùy Trâm', N'Xã Đặng Thùy Trâm', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15652', N'Bình Sơn', N'Xã Bình Sơn', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1572', N'Rờ Kơi', N'Xã Rờ Kơi', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15908', N'Kon Tum', N'Phường Kon Tum', 'phuong', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16164', N'Đăk Cấm', N'Phường Đăk Cấm', 'phuong', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16420', N'Đăk Bla', N'Phường Đăk Bla', 'phuong', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16676', N'Ngọk Bay', N'Xã Ngọk Bay', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16932', N'Ia Chim', N'Xã Ia Chim', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17188', N'Đăk Rơ Wa', N'Xã Đăk Rơ Wa', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17444', N'Đăk Pxi', N'Xã Đăk Pxi', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17700', N'Đăk Mar', N'Xã Đăk Mar', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17956', N'Đăk Ui', N'Xã Đăk Ui', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18212', N'Ngọk Réo', N'Xã Ngọk Réo', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1828', N'Ia Đal', N'Xã Ia Đal', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18468', N'Đăk Hà', N'Xã Đăk Hà', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18724', N'Ngọk Tụ', N'Xã Ngọk Tụ', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18980', N'Đăk Tô', N'Xã Đăk Tô', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19236', N'Kon Đào', N'Xã Kon Đào', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19492', N'Đăk Sao', N'Xã Đăk Sao', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19748', N'Đăk Tờ Kan', N'Xã Đăk Tờ Kan', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20004', N'Tu Mơ Rông', N'Xã Tu Mơ Rông', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20260', N'Măng Ri', N'Xã Măng Ri', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20516', N'Bờ Y', N'Xã Bờ Y', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20772', N'Sa Loong', N'Xã Sa Loong', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2084', N'Ia Tơi', N'Xã Ia Tơi', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21028', N'Dục Nông', N'Xã Dục Nông', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21284', N'Xốp', N'Xã Xốp', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21540', N'Ngọc Linh', N'Xã Ngọc Linh', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21796', N'Đăk Plô', N'Xã Đăk Plô', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22052', N'Đăk Pék', N'Xã Đăk Pék', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22308', N'Đăk Môn', N'Xã Đăk Môn', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22564', N'Sa Thầy', N'Xã Sa Thầy', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22820', N'Sa Bình', N'Xã Sa Bình', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23076', N'Ya Ly', N'Xã Ya Ly', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23332', N'Đăk Kôi', N'Xã Đăk Kôi', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2340', N'Tây Trà Bồng', N'Xã Tây Trà Bồng', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23588', N'Kon Braih', N'Xã Kon Braih', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23844', N'Đăk Rve', N'Xã Đăk Rve', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24100', N'Măng Đen', N'Xã Măng Đen', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24356', N'Măng Bút', N'Xã Măng Bút', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24612', N'Kon Plông', N'Xã Kon Plông', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2596', N'Đông Sơn', N'Xã Đông Sơn', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2852', N'Lý Sơn', N'Đặc Khu Lý Sơn', 'dac-khu', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('292', N'Đăk Long', N'Xã Đăk Long', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3108', N'Tịnh Khê', N'Xã Tịnh Khê', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3364', N'Trương Quang Trọng', N'Phường Trương Quang Trọng', 'phuong', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3620', N'An Phú', N'Xã An Phú', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3876', N'Cẩm Thành', N'Phường Cẩm Thành', 'phuong', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4132', N'Nghĩa Lộ', N'Phường Nghĩa Lộ', 'phuong', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4388', N'Trà Câu', N'Phường Trà Câu', 'phuong', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4644', N'Nguyễn Nghiêm', N'Xã Nguyễn Nghiêm', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4900', N'Đức Phổ', N'Phường Đức Phổ', 'phuong', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5156', N'Khánh Cường', N'Xã Khánh Cường', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5412', N'Sa Huỳnh', N'Phường Sa Huỳnh', 'phuong', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('548', N'Ba Xa', N'Xã Ba Xa', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5668', N'Bình Minh', N'Xã Bình Minh', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5924', N'Bình Chương', N'Xã Bình Chương', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6180', N'Trường Giang', N'Xã Trường Giang', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6436', N'Ba Gia', N'Xã Ba Gia', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6692', N'Sơn Tịnh', N'Xã Sơn Tịnh', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6948', N'Thọ Phong', N'Xã Thọ Phong', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7204', N'Tư Nghĩa', N'Xã Tư Nghĩa', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7460', N'Vệ Giang', N'Xã Vệ Giang', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7716', N'Nghĩa Giang', N'Xã Nghĩa Giang', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7972', N'Trà Giang', N'Xã Trà Giang', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('804', N'Cà Đam', N'Xã Cà Đam', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8228', N'Nghĩa Hành', N'Xã Nghĩa Hành', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8484', N'Đình Cương', N'Xã Đình Cương', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8740', N'Thiện Tín', N'Xã Thiện Tín', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8996', N'Phước Giang', N'Xã Phước Giang', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9252', N'Long Phụng', N'Xã Long Phụng', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9508', N'Mỏ Cày', N'Xã Mỏ Cày', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9764', N'Mộ Đức', N'Xã Mộ Đức', 'xa', '36');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10021', N'Quảng Đức', N'Xã Quảng Đức', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10277', N'Hoành Mô', N'Xã Hoành Mô', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10533', N'Lục Hồn', N'Xã Lục Hồn', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1061', N'Thống Nhất', N'Xã Thống Nhất', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10789', N'Hải Sơn', N'Xã Hải Sơn', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11045', N'Hải Ninh', N'Xã Hải Ninh', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11301', N'Móng Cái 1', N'Phường Móng Cái 1', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11557', N'Móng Cái 2', N'Phường Móng Cái 2', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11813', N'Móng Cái 3', N'Phường Móng Cái 3', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12069', N'Đầm Hà', N'Xã Đầm Hà', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12325', N'Vân Đồn', N'Đặc Khu Vân Đồn', 'dac-khu', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12581', N'Cô Tô', N'Đặc Khu Cô Tô', 'dac-khu', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12837', N'Đông Triều', N'Phường Đông Triều', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13093', N'Uông Bí', N'Phường Uông Bí', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1317', N'Đông Ngũ', N'Xã Đông Ngũ', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13349', N'Tiên Yên', N'Xã Tiên Yên', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13605', N'Ba Chẽ', N'Xã Ba Chẽ', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13861', N'Bình Liêu', N'Xã Bình Liêu', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1573', N'Hải Lạng', N'Xã Hải Lạng', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1829', N'Hải Hòa', N'Xã Hải Hòa', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2085', N'Hà An', N'Phường Hà An', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2341', N'Liên Hòa', N'Phường Liên Hòa', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2597', N'Quang Hanh', N'Phường Quang Hanh', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2853', N'Tuần Châu', N'Phường Tuần Châu', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('293', N'Vàng Danh', N'Phường Vàng Danh', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3109', N'Hà Tu', N'Phường Hà Tu', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3365', N'An Sinh', N'Phường An Sinh', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3621', N'Vĩnh Thực', N'Xã Vĩnh Thực', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3877', N'Quảng Hà', N'Xã Quảng Hà', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4133', N'Cái Chiên', N'Xã Cái Chiên', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4389', N'Điền Xá', N'Xã Điền Xá', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4645', N'Việt Hưng', N'Phường Việt Hưng', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4901', N'Bình Khê', N'Phường Bình Khê', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5157', N'Mạo Khê', N'Phường Mạo Khê', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5413', N'Hoàng Quế', N'Phường Hoàng Quế', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('549', N'Đường Hoa', N'Xã Đường Hoa', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5669', N'Yên Tử', N'Phường Yên Tử', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5925', N'Đông Mai', N'Phường Đông Mai', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6181', N'Hiệp Hòa', N'Phường Hiệp Hòa', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6437', N'Quảng Yên', N'Phường Quảng Yên', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6693', N'Phong Cốc', N'Phường Phong Cốc', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6949', N'Bãi Cháy', N'Phường Bãi Cháy', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7205', N'Hà Lầm', N'Phường Hà Lầm', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7461', N'Cao Xanh', N'Phường Cao Xanh', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7717', N'Hồng Gai', N'Phường Hồng Gai', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7973', N'Hạ Long', N'Phường Hạ Long', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('805', N'Hoành Bồ', N'Phường Hoành Bồ', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8229', N'Quảng La', N'Xã Quảng La', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8485', N'Mông Dương', N'Phường Mông Dương', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8741', N'Cẩm Phả', N'Phường Cẩm Phả', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8997', N'Cửa Ông', N'Phường Cửa Ông', 'phuong', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9253', N'Lương Minh', N'Xã Lương Minh', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9509', N'Kỳ Thượng', N'Xã Kỳ Thượng', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9765', N'Quảng Tân', N'Xã Quảng Tân', 'xa', '37');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10022', N'Tân Mỹ', N'Xã Tân Mỹ', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10278', N'Trường Phú', N'Xã Trường Phú', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10534', N'Lệ Ninh', N'Xã Lệ Ninh', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1062', N'Đồng Hới', N'Phường Đồng Hới', 'phuong', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10790', N'Kim Ngân', N'Xã Kim Ngân', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11046', N'Vĩnh Linh', N'Xã Vĩnh Linh', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11302', N'Cửa Tùng', N'Xã Cửa Tùng', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11558', N'Vĩnh Hoàng', N'Xã Vĩnh Hoàng', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11814', N'Vĩnh Thủy', N'Xã Vĩnh Thủy', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12070', N'Bến Quan', N'Xã Bến Quan', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12326', N'Cồn Tiên', N'Xã Cồn Tiên', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12582', N'Cửa Việt', N'Xã Cửa Việt', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12838', N'Gio Linh', N'Xã Gio Linh', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13094', N'Bến Hải', N'Xã Bến Hải', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1318', N'Đồng Thuận', N'Phường Đồng Thuận', 'phuong', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13350', N'Cam Lộ', N'Xã Cam Lộ', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13606', N'Hiếu Giang', N'Xã Hiếu Giang', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13862', N'La Lay', N'Xã La Lay', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14118', N'Tà Rụt', N'Xã Tà Rụt', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14374', N'Đakrông', N'Xã Đakrông', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14630', N'Ba Lòng', N'Xã Ba Lòng', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14886', N'Hướng Hiệp', N'Xã Hướng Hiệp', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15142', N'Hướng Lập', N'Xã Hướng Lập', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15398', N'Hướng Phùng', N'Xã Hướng Phùng', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15654', N'Khe Sanh', N'Xã Khe Sanh', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1574', N'Đồng Sơn', N'Phường Đồng Sơn', 'phuong', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15910', N'Tân Lập', N'Xã Tân Lập', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16166', N'Lao Bảo', N'Xã Lao Bảo', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16422', N'Lìa', N'Xã Lìa', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16678', N'A Dơi', N'Xã A Dơi', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16934', N'Đông Hà', N'Phường Đông Hà', 'phuong', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17190', N'Nam Đông Hà', N'Phường Nam Đông Hà', 'phuong', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17446', N'Triệu Phong', N'Xã Triệu Phong', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17702', N'Ái Tử', N'Xã Ái Tử', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17958', N'Triệu Bình', N'Xã Triệu Bình', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18214', N'Triệu Cơ', N'Xã Triệu Cơ', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1830', N'Ba Đồn', N'Phường Ba Đồn', 'phuong', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18470', N'Nam Cửa Việt', N'Xã Nam Cửa Việt', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18726', N'Quảng Trị', N'Phường Quảng Trị', 'phuong', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18982', N'Diên Sanh', N'Xã Diên Sanh', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19238', N'Mỹ Thủy', N'Xã Mỹ Thủy', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19494', N'Hải Lăng', N'Xã Hải Lăng', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19750', N'Nam Hải Lăng', N'Xã Nam Hải Lăng', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20006', N'Vĩnh Định', N'Xã Vĩnh Định', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2086', N'Bắc Gianh', N'Phường Bắc Gianh', 'phuong', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2342', N'Nam Gianh', N'Xã Nam Gianh', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2598', N'Nam Ba Đồn', N'Xã Nam Ba Đồn', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2854', N'Dân Hóa', N'Xã Dân Hóa', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('294', N'Phú Trạch', N'Xã Phú Trạch', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3110', N'Kim Điền', N'Xã Kim Điền', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3366', N'Kim Phú', N'Xã Kim Phú', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3622', N'Minh Hóa', N'Xã Minh Hóa', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3878', N'Tuyên Lâm', N'Xã Tuyên Lâm', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4134', N'Tuyên Sơn', N'Xã Tuyên Sơn', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4390', N'Đồng Lê', N'Xã Đồng Lê', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4646', N'Tuyên Phú', N'Xã Tuyên Phú', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4902', N'Tuyên Bình', N'Xã Tuyên Bình', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5158', N'Tuyên Hóa', N'Xã Tuyên Hóa', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5414', N'Tân Gianh', N'Xã Tân Gianh', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('550', N'Cồn Cỏ', N'Đặc Khu Cồn Cỏ', 'dac-khu', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5670', N'Trung Thuần', N'Xã Trung Thuần', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5926', N'Quảng Trạch', N'Xã Quảng Trạch', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6182', N'Hòa Trạch', N'Xã Hòa Trạch', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6438', N'Thượng Trạch', N'Xã Thượng Trạch', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6694', N'Phong Nha', N'Xã Phong Nha', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6950', N'Bắc Trạch', N'Xã Bắc Trạch', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7206', N'Đông Trạch', N'Xã Đông Trạch', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7462', N'Hoàn Lão', N'Xã Hoàn Lão', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7718', N'Bố Trạch', N'Xã Bố Trạch', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7974', N'Nam Trạch', N'Xã Nam Trạch', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('806', N'Tân Thành', N'Xã Tân Thành', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8230', N'Quảng Ninh', N'Xã Quảng Ninh', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8486', N'Ninh Châu', N'Xã Ninh Châu', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8742', N'Trường Ninh', N'Xã Trường Ninh', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8998', N'Trường Sơn', N'Xã Trường Sơn', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9254', N'Lệ Thủy', N'Xã Lệ Thủy', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9510', N'Cam Hồng', N'Xã Cam Hồng', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9766', N'Sen Ngư', N'Xã Sen Ngư', 'xa', '38');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10023', N'Bắc Yên', N'Xã Bắc Yên', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10279', N'Tà Xùa', N'Xã Tà Xùa', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10535', N'Tạ Khoa', N'Xã Tạ Khoa', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1063', N'Suối Tọ', N'Xã Suối Tọ', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10791', N'Xím Vàng', N'Xã Xím Vàng', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11047', N'Pắc Ngà', N'Xã Pắc Ngà', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11303', N'Chiềng Sại', N'Xã Chiềng Sại', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11559', N'Phù Yên', N'Xã Phù Yên', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11815', N'Gia Phù', N'Xã Gia Phù', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12071', N'Tường Hạ', N'Xã Tường Hạ', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12327', N'Mường Cơi', N'Xã Mường Cơi', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12583', N'Mường Bang', N'Xã Mường Bang', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12839', N'Tân Phong', N'Xã Tân Phong', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13095', N'Kim Bon', N'Xã Kim Bon', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1319', N'Mường Lạn', N'Xã Mường Lạn', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13351', N'Yên Châu', N'Xã Yên Châu', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13607', N'Chiềng Hặc', N'Xã Chiềng Hặc', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13863', N'Lóng Phiêng', N'Xã Lóng Phiêng', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14119', N'Yên Sơn', N'Xã Yên Sơn', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14375', N'Chiềng Mai', N'Xã Chiềng Mai', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14631', N'Mai Sơn', N'Xã Mai Sơn', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14887', N'Phiêng Pằn', N'Xã Phiêng Pằn', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15143', N'Chiềng Mung', N'Xã Chiềng Mung', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15399', N'Phiêng Cằm', N'Xã Phiêng Cằm', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15655', N'Mường Chanh', N'Xã Mường Chanh', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1575', N'Tân Yên', N'Xã Tân Yên', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15911', N'Tà Hộc', N'Xã Tà Hộc', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16167', N'Chiềng Sung', N'Xã Chiềng Sung', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16423', N'Bó Sinh', N'Xã Bó Sinh', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16679', N'Chiềng Khương', N'Xã Chiềng Khương', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16935', N'Mường Hung', N'Xã Mường Hung', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17191', N'Chiềng Khoong', N'Xã Chiềng Khoong', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17447', N'Mường Lầm', N'Xã Mường Lầm', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17703', N'Nậm Ty', N'Xã Nậm Ty', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17959', N'Sông Mã', N'Xã Sông Mã', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18215', N'Huổi Một', N'Xã Huổi Một', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1831', N'Ngọc Chiến', N'Xã Ngọc Chiến', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18471', N'Chiềng Sơ', N'Xã Chiềng Sơ', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18727', N'Sốp Cộp', N'Xã Sốp Cộp', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18983', N'Púng Bánh', N'Xã Púng Bánh', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19239', N'Mộc Châu', N'Phường Mộc Châu', 'phuong', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2087', N'Mường Lèo', N'Xã Mường Lèo', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2343', N'Tô Hiệu', N'Phường Tô Hiệu', 'phuong', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2599', N'Chiềng An', N'Phường Chiềng An', 'phuong', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2855', N'Chiềng Sinh', N'Phường Chiềng Sinh', 'phuong', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('295', N'Mường Bám', N'Xã Mường Bám', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3111', N'Mộc Sơn', N'Phường Mộc Sơn', 'phuong', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3367', N'Vân Sơn', N'Phường Vân Sơn', 'phuong', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3623', N'Thảo Nguyên', N'Phường Thảo Nguyên', 'phuong', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3879', N'Đoàn Kết', N'Xã Đoàn Kết', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4135', N'Lóng Sập', N'Xã Lóng Sập', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4391', N'Chiềng Sơn', N'Xã Chiềng Sơn', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4647', N'Vân Hồ', N'Xã Vân Hồ', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4903', N'Song Khủa', N'Xã Song Khủa', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5159', N'Tô Múa', N'Xã Tô Múa', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5415', N'Xuân Nha', N'Xã Xuân Nha', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('551', N'Phiêng Khoài', N'Xã Phiêng Khoài', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5671', N'Quỳnh Nhai', N'Xã Quỳnh Nhai', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5927', N'Mường Chiên', N'Xã Mường Chiên', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6183', N'Mường Giôn', N'Xã Mường Giôn', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6439', N'Mường Sại', N'Xã Mường Sại', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6695', N'Thuận Châu', N'Xã Thuận Châu', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6951', N'Chiềng La', N'Xã Chiềng La', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7207', N'Nậm Lầu', N'Xã Nậm Lầu', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7463', N'Muổi Nọi', N'Xã Muổi Nọi', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7719', N'Mường Khiêng', N'Xã Mường Khiêng', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7975', N'Co Mạ', N'Xã Co Mạ', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('807', N'Chiềng Cơi', N'Phường Chiềng Cơi', 'phuong', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8231', N'Bình Thuận', N'Xã Bình Thuận', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8487', N'Mường É', N'Xã Mường É', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8743', N'Long Hẹ', N'Xã Long Hẹ', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8999', N'Mường La', N'Xã Mường La', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9255', N'Chiềng Lao', N'Xã Chiềng Lao', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9511', N'Mường Bú', N'Xã Mường Bú', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9767', N'Chiềng Hoa', N'Xã Chiềng Hoa', 'xa', '39');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10024', N'Tân Hòa', N'Xã Tân Hòa', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10280', N'Tân Lập', N'Xã Tân Lập', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10536', N'Tân Biên', N'Xã Tân Biên', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1064', N'Lộc Ninh', N'Xã Lộc Ninh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10792', N'Phước Vinh', N'Xã Phước Vinh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11048', N'Hòa Hội', N'Xã Hòa Hội', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11304', N'Ninh Điền', N'Xã Ninh Điền', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11560', N'Hảo Đước', N'Xã Hảo Đước', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11816', N'Long Chữ', N'Xã Long Chữ', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12072', N'Long Thuận', N'Xã Long Thuận', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12328', N'Bến Cầu', N'Xã Bến Cầu', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12584', N'Hưng Điền', N'Xã Hưng Điền', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12840', N'Vĩnh Thạnh', N'Xã Vĩnh Thạnh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13096', N'Tân Hưng', N'Xã Tân Hưng', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1320', N'Thạnh Bình', N'Xã Thạnh Bình', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13352', N'Vĩnh Châu', N'Xã Vĩnh Châu', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13608', N'Bình Hiệp', N'Xã Bình Hiệp', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13864', N'Kiến Tường', N'Phường Kiến Tường', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14120', N'Bình Hòa', N'Xã Bình Hòa', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14376', N'Mộc Hóa', N'Xã Mộc Hóa', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14632', N'Nhơn Hòa Lập', N'Xã Nhơn Hòa Lập', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14888', N'Nhơn Ninh', N'Xã Nhơn Ninh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15144', N'Tân Thạnh', N'Xã Tân Thạnh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15400', N'Bình Thành', N'Xã Bình Thành', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15656', N'Thạnh Phước', N'Xã Thạnh Phước', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1576', N'Trà Vong', N'Xã Trà Vong', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15912', N'Thạnh Hóa', N'Xã Thạnh Hóa', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16168', N'Tân Tây', N'Xã Tân Tây', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16424', N'Mỹ An', N'Xã Mỹ An', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16680', N'Tân Long', N'Xã Tân Long', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16936', N'Mỹ Quý', N'Xã Mỹ Quý', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17192', N'Đông Thành', N'Xã Đông Thành', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17448', N'Đức Huệ', N'Xã Đức Huệ', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17704', N'An Ninh', N'Xã An Ninh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17960', N'Hiệp Hòa', N'Xã Hiệp Hòa', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18216', N'Hậu Nghĩa', N'Xã Hậu Nghĩa', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1832', N'Tân Châu', N'Xã Tân Châu', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18472', N'Hòa Khánh', N'Xã Hòa Khánh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18728', N'Đức Hòa', N'Xã Đức Hòa', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18984', N'Thạnh Lợi', N'Xã Thạnh Lợi', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19240', N'Bình Đức', N'Xã Bình Đức', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19496', N'Bến Lức', N'Xã Bến Lức', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19752', N'Mỹ Yên', N'Xã Mỹ Yên', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20008', N'Long Cang', N'Xã Long Cang', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20264', N'Rạch Kiến', N'Xã Rạch Kiến', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20520', N'Mỹ Lệ', N'Xã Mỹ Lệ', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20776', N'Tân Lân', N'Xã Tân Lân', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2088', N'Tân Thành', N'Xã Tân Thành', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21032', N'Cần Đước', N'Xã Cần Đước', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21288', N'Long Hựu', N'Xã Long Hựu', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21544', N'Phước Lý', N'Xã Phước Lý', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21800', N'Mỹ Lộc', N'Xã Mỹ Lộc', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22056', N'Cần Giuộc', N'Xã Cần Giuộc', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22312', N'Phước Vĩnh Tây', N'Xã Phước Vĩnh Tây', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22568', N'Tân Tập', N'Xã Tân Tập', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22824', N'Vàm Cỏ', N'Xã Vàm Cỏ', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23080', N'Tân Trụ', N'Xã Tân Trụ', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23336', N'Thuận Mỹ', N'Xã Thuận Mỹ', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2344', N'Tân Phú', N'Xã Tân Phú', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23592', N'An Lục Long', N'Xã An Lục Long', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23848', N'Tầm Vu', N'Xã Tầm Vu', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24104', N'Vĩnh Công', N'Xã Vĩnh Công', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24360', N'Tân An', N'Phường Tân An', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24616', N'Khánh Hậu', N'Phường Khánh Hậu', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2600', N'Tân Ninh', N'Phường Tân Ninh', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2856', N'Bình Minh', N'Phường Bình Minh', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('296', N'Dương Minh Châu', N'Xã Dương Minh Châu', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3112', N'Châu Thành', N'Xã Châu Thành', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3368', N'Đức Lập', N'Xã Đức Lập', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3624', N'Mỹ Hạnh', N'Xã Mỹ Hạnh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3880', N'Tuyên Thạnh', N'Xã Tuyên Thạnh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4136', N'Hậu Thạnh', N'Xã Hậu Thạnh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4392', N'Long An', N'Phường Long An', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4648', N'Mỹ Thạnh', N'Xã Mỹ Thạnh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4904', N'Vĩnh Hưng', N'Xã Vĩnh Hưng', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5160', N'Khánh Hưng', N'Xã Khánh Hưng', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5416', N'Tuyên Bình', N'Xã Tuyên Bình', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('552', N'Ninh Thạnh', N'Phường Ninh Thạnh', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5672', N'Nhựt Tảo', N'Xã Nhựt Tảo', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5928', N'Thủ Thừa', N'Xã Thủ Thừa', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6184', N'Lương Hòa', N'Xã Lương Hòa', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6440', N'Long Hoa', N'Phường Long Hoa', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6696', N'Hòa Thành', N'Phường Hòa Thành', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6952', N'Thanh Điền', N'Phường Thanh Điền', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7208', N'Trảng Bàng', N'Phường Trảng Bàng', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7464', N'An Tịnh', N'Phường An Tịnh', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7720', N'Gò Dầu', N'Phường Gò Dầu', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7976', N'Gia Lộc', N'Phường Gia Lộc', 'phuong', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('808', N'Cầu Khởi', N'Xã Cầu Khởi', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8232', N'Hưng Thuận', N'Xã Hưng Thuận', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8488', N'Phước Chỉ', N'Xã Phước Chỉ', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8744', N'Thạnh Đức', N'Xã Thạnh Đức', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9000', N'Phước Thạnh', N'Xã Phước Thạnh', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9256', N'Truông Mít', N'Xã Truông Mít', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9512', N'Tân Đông', N'Xã Tân Đông', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9768', N'Tân Hội', N'Xã Tân Hội', 'xa', '40');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10025', N'La Hiên', N'Xã La Hiên', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10281', N'Tràng Xá', N'Xã Tràng Xá', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10537', N'Quyết Thắng', N'Phường Quyết Thắng', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1065', N'Điềm Thụy', N'Xã Điềm Thụy', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10793', N'Quan Triều', N'Phường Quan Triều', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11049', N'Tân Cương', N'Xã Tân Cương', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11305', N'Đại Phúc', N'Xã Đại Phúc', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11561', N'Đại Từ', N'Xã Đại Từ', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11817', N'Đức Lương', N'Xã Đức Lương', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12073', N'Phú Thịnh', N'Xã Phú Thịnh', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12329', N'La Bằng', N'Xã La Bằng', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12585', N'Phú Lạc', N'Xã Phú Lạc', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12841', N'An Khánh', N'Xã An Khánh', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13097', N'Quân Chu', N'Xã Quân Chu', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1321', N'Gia Sàng', N'Phường Gia Sàng', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13353', N'Vạn Phú', N'Xã Vạn Phú', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13609', N'Phú Xuyên', N'Xã Phú Xuyên', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13865', N'Phổ Yên', N'Phường Phổ Yên', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14121', N'Vạn Xuân', N'Phường Vạn Xuân', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14377', N'Trung Thành', N'Phường Trung Thành', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14633', N'Phúc Lộc', N'Xã Phúc Lộc', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14889', N'Thượng Minh', N'Xã Thượng Minh', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15145', N'Đồng Phúc', N'Xã Đồng Phúc', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15401', N'Bằng Vân', N'Xã Bằng Vân', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15657', N'Bằng Thành', N'Xã Bằng Thành', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1577', N'Phan Đình Phùng', N'Phường Phan Đình Phùng', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15913', N'Nghiên Loan', N'Xã Nghiên Loan', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16169', N'Cao Minh', N'Xã Cao Minh', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16425', N'Ba Bể', N'Xã Ba Bể', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16681', N'Chợ Rã', N'Xã Chợ Rã', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16937', N'Ngân Sơn', N'Xã Ngân Sơn', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17193', N'Nà Phặc', N'Xã Nà Phặc', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17449', N'Hiệp Lực', N'Xã Hiệp Lực', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17705', N'Nam Cường', N'Xã Nam Cường', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17961', N'Quảng Bạch', N'Xã Quảng Bạch', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18217', N'Yên Thịnh', N'Xã Yên Thịnh', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1833', N'Tích Lương', N'Phường Tích Lương', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18473', N'Chợ Đồn', N'Xã Chợ Đồn', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18729', N'Yên Phong', N'Xã Yên Phong', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18985', N'Nghĩa Tá', N'Xã Nghĩa Tá', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19241', N'Phủ Thông', N'Xã Phủ Thông', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19497', N'Cẩm Giàng', N'Xã Cẩm Giàng', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19753', N'Vĩnh Thông', N'Xã Vĩnh Thông', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20009', N'Bạch Thông', N'Xã Bạch Thông', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20265', N'Phong Quang', N'Xã Phong Quang', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20521', N'Đức Xuân', N'Phường Đức Xuân', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20777', N'Bắc Kạn', N'Phường Bắc Kạn', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2089', N'Linh Sơn', N'Phường Linh Sơn', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21033', N'Văn Lang', N'Xã Văn Lang', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21289', N'Cường Lợi', N'Xã Cường Lợi', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21545', N'Na Rì', N'Xã Na Rì', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21801', N'Trần Phú', N'Xã Trần Phú', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22057', N'Côn Minh', N'Xã Côn Minh', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22313', N'Xuân Dương', N'Xã Xuân Dương', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22569', N'Tân Kỳ', N'Xã Tân Kỳ', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22825', N'Thanh Mai', N'Xã Thanh Mai', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23081', N'Thanh Thịnh', N'Xã Thanh Thịnh', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23337', N'Chợ Mới', N'Xã Chợ Mới', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2345', N'Phúc Thuận', N'Phường Phúc Thuận', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23593', N'Yên Bình', N'Xã Yên Bình', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2601', N'Thành Công', N'Xã Thành Công', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2857', N'Tân Thành', N'Xã Tân Thành', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('297', N'Thượng Quan', N'Xã Thượng Quan', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3113', N'Kha Sơn', N'Xã Kha Sơn', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3369', N'Tân Khánh', N'Xã Tân Khánh', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3625', N'Đồng Hỷ', N'Xã Đồng Hỷ', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3881', N'Quang Sơn', N'Xã Quang Sơn', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4137', N'Trại Cau', N'Xã Trại Cau', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4393', N'Nam Hòa', N'Xã Nam Hòa', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4649', N'Văn Hán', N'Xã Văn Hán', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4905', N'Văn Lăng', N'Xã Văn Lăng', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5161', N'Sông Công', N'Phường Sông Công', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5417', N'Bá Xuyên', N'Phường Bá Xuyên', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('553', N'Sảng Mộc', N'Xã Sảng Mộc', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5673', N'Bách Quang', N'Phường Bách Quang', 'phuong', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5929', N'Phú Lương', N'Xã Phú Lương', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6185', N'Vô Tranh', N'Xã Vô Tranh', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6441', N'Yên Trạch', N'Xã Yên Trạch', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6697', N'Hợp Thành', N'Xã Hợp Thành', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6953', N'Định Hóa', N'Xã Định Hóa', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7209', N'Bình Yên', N'Xã Bình Yên', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7465', N'Trung Hội', N'Xã Trung Hội', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7721', N'Phượng Tiến', N'Xã Phượng Tiến', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7977', N'Phú Đình', N'Xã Phú Đình', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('809', N'Phú Bình', N'Xã Phú Bình', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8233', N'Bình Thành', N'Xã Bình Thành', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8489', N'Kim Phượng', N'Xã Kim Phượng', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8745', N'Lam Vỹ', N'Xã Lam Vỹ', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9001', N'Võ Nhai', N'Xã Võ Nhai', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9257', N'Dân Tiến', N'Xã Dân Tiến', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9513', N'Nghinh Tường', N'Xã Nghinh Tường', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9769', N'Thần Sa', N'Xã Thần Sa', 'xa', '41');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10026', N'Đông Sơn', N'Phường Đông Sơn', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10282', N'Đông Tiến', N'Phường Đông Tiến', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10538', N'Nguyệt Viên', N'Phường Nguyệt Viên', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1066', N'Trung Sơn', N'Xã Trung Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10794', N'Sầm Sơn', N'Phường Sầm Sơn', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11050', N'Nam Sầm Sơn', N'Phường Nam Sầm Sơn', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11306', N'Bỉm Sơn', N'Phường Bỉm Sơn', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11562', N'Quang Trung', N'Phường Quang Trung', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11818', N'Ngọc Sơn', N'Phường Ngọc Sơn', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12074', N'Tân Dân', N'Phường Tân Dân', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12330', N'Hải Lĩnh', N'Phường Hải Lĩnh', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12586', N'Tĩnh Gia', N'Phường Tĩnh Gia', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12842', N'Đào Duy Từ', N'Phường Đào Duy Từ', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13098', N'Trúc Lâm', N'Phường Trúc Lâm', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1322', N'Mường Mìn', N'Xã Mường Mìn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13354', N'Nghi Sơn', N'Phường Nghi Sơn', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13610', N'Các Sơn', N'Xã Các Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13866', N'Trường Lâm', N'Xã Trường Lâm', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14122', N'Tống Sơn', N'Xã Tống Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14378', N'Hà Long', N'Xã Hà Long', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14634', N'Lĩnh Toại', N'Xã Lĩnh Toại', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14890', N'Triệu Lộc', N'Xã Triệu Lộc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15146', N'Đông Thành', N'Xã Đông Thành', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15402', N'Hậu Lộc', N'Xã Hậu Lộc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15658', N'Hoa Lộc', N'Xã Hoa Lộc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1578', N'Na Mèo', N'Xã Na Mèo', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15914', N'Nga Sơn', N'Xã Nga Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16170', N'Nga Thắng', N'Xã Nga Thắng', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16426', N'Hồ Vương', N'Xã Hồ Vương', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16682', N'Tân Tiến', N'Xã Tân Tiến', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16938', N'Nga An', N'Xã Nga An', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17194', N'Ba Đình', N'Xã Ba Đình', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17450', N'Hoằng Hóa', N'Xã Hoằng Hóa', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17706', N'Hoằng Tiến', N'Xã Hoằng Tiến', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17962', N'Hoằng Thanh', N'Xã Hoằng Thanh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18218', N'Hoằng Lộc', N'Xã Hoằng Lộc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1834', N'Sơn Điện', N'Xã Sơn Điện', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18474', N'Hoằng Châu', N'Xã Hoằng Châu', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18730', N'Hoằng Sơn', N'Xã Hoằng Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18986', N'Hoằng Phú', N'Xã Hoằng Phú', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19242', N'Hoằng Giang', N'Xã Hoằng Giang', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19498', N'Lưu Vệ', N'Xã Lưu Vệ', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19754', N'Quảng Yên', N'Xã Quảng Yên', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20010', N'Quảng Ngọc', N'Xã Quảng Ngọc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20266', N'Quảng Ninh', N'Xã Quảng Ninh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20522', N'Quảng Bình', N'Xã Quảng Bình', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20778', N'Tiên Trang', N'Xã Tiên Trang', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2090', N'Sơn Thủy', N'Xã Sơn Thủy', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21034', N'Quảng Chính', N'Xã Quảng Chính', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21290', N'Nông Cống', N'Xã Nông Cống', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21546', N'Thắng Lợi', N'Xã Thắng Lợi', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21802', N'Trung Chính', N'Xã Trung Chính', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22058', N'Trường Văn', N'Xã Trường Văn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22314', N'Thăng Bình', N'Xã Thăng Bình', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22570', N'Tượng Lĩnh', N'Xã Tượng Lĩnh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22826', N'Thiệu Tiến', N'Xã Thiệu Tiến', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23082', N'Thiệu Toán', N'Xã Thiệu Toán', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23338', N'Yên Định', N'Xã Yên Định', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2346', N'Tam Lư', N'Xã Tam Lư', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23594', N'Yên Trường', N'Xã Yên Trường', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23850', N'Yên Phú', N'Xã Yên Phú', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24106', N'Quý Lộc', N'Xã Quý Lộc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24362', N'Yên Ninh', N'Xã Yên Ninh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24618', N'Định Tân', N'Xã Định Tân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24874', N'Thọ Xuân', N'Xã Thọ Xuân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25130', N'Thọ Long', N'Xã Thọ Long', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25386', N'Xuân Hòa', N'Xã Xuân Hòa', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25642', N'Sao Vàng', N'Xã Sao Vàng', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25898', N'Lam Sơn', N'Xã Lam Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2602', N'Tam Thanh', N'Xã Tam Thanh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26154', N'Thọ Lập', N'Xã Thọ Lập', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26410', N'Xuân Tín', N'Xã Xuân Tín', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26666', N'Xuân Lập', N'Xã Xuân Lập', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26922', N'Vĩnh Lộc', N'Xã Vĩnh Lộc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27178', N'Tây Đô', N'Xã Tây Đô', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27434', N'Biện Thượng', N'Xã Biện Thượng', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27690', N'Triệu Sơn', N'Xã Triệu Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27946', N'Thọ Bình', N'Xã Thọ Bình', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28202', N'Thọ Ngọc', N'Xã Thọ Ngọc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28458', N'Hợp Tiến', N'Xã Hợp Tiến', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2858', N'Quang Chiểu', N'Xã Quang Chiểu', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28714', N'An Nông', N'Xã An Nông', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28970', N'Tân Ninh', N'Xã Tân Ninh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29226', N'Đồng Tiến', N'Xã Đồng Tiến', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29482', N'Hồi Xuân', N'Xã Hồi Xuân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29738', N'Nam Xuân', N'Xã Nam Xuân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('298', N'Thiệu Quang', N'Xã Thiệu Quang', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29994', N'Thiên Phủ', N'Xã Thiên Phủ', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30250', N'Hiền Kiệt', N'Xã Hiền Kiệt', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30506', N'Phú Lệ', N'Xã Phú Lệ', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30762', N'Trung Thành', N'Xã Trung Thành', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31018', N'Trung Hạ', N'Xã Trung Hạ', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3114', N'Tam Chung', N'Xã Tam Chung', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31274', N'Linh Sơn', N'Xã Linh Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31530', N'Đồng Lương', N'Xã Đồng Lương', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31786', N'Văn Phú', N'Xã Văn Phú', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32042', N'Giao An', N'Xã Giao An', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32298', N'Bá Thước', N'Xã Bá Thước', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32554', N'Thiết Ống', N'Xã Thiết Ống', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('32810', N'Văn Nho', N'Xã Văn Nho', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33066', N'Điền Quang', N'Xã Điền Quang', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33322', N'Điền Lư', N'Xã Điền Lư', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33578', N'Quý Lương', N'Xã Quý Lương', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3370', N'Nhi Sơn', N'Xã Nhi Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('33834', N'Cổ Lũng', N'Xã Cổ Lũng', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34090', N'Pù Luông', N'Xã Pù Luông', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34346', N'Ngọc Lặc', N'Xã Ngọc Lặc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34602', N'Thạch Lập', N'Xã Thạch Lập', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('34858', N'Ngọc Liên', N'Xã Ngọc Liên', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35114', N'Minh Sơn', N'Xã Minh Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35370', N'Nguyệt Ấn', N'Xã Nguyệt Ấn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35626', N'Kiên Thọ', N'Xã Kiên Thọ', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('35882', N'Cẩm Thạch', N'Xã Cẩm Thạch', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36138', N'Cẩm Thủy', N'Xã Cẩm Thủy', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3626', N'Pù Nhi', N'Xã Pù Nhi', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36394', N'Cẩm Tú', N'Xã Cẩm Tú', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36650', N'Cẩm Vân', N'Xã Cẩm Vân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('36906', N'Cẩm Tân', N'Xã Cẩm Tân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37162', N'Kim Tân', N'Xã Kim Tân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37418', N'Vân Du', N'Xã Vân Du', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37674', N'Ngọc Trạo', N'Xã Ngọc Trạo', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('37930', N'Thạch Bình', N'Xã Thạch Bình', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('38186', N'Thành Vinh', N'Xã Thành Vinh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('38442', N'Thạch Quảng', N'Xã Thạch Quảng', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('38698', N'Như Xuân', N'Xã Như Xuân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3882', N'Công Chính', N'Xã Công Chính', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('38954', N'Thượng Ninh', N'Xã Thượng Ninh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('39210', N'Hóa Quỳ', N'Xã Hóa Quỳ', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('39466', N'Xuân Bình', N'Xã Xuân Bình', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('39722', N'Thanh Phong', N'Xã Thanh Phong', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('39978', N'Thanh Quân', N'Xã Thanh Quân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('40234', N'Xuân Du', N'Xã Xuân Du', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('40490', N'Mậu Lâm', N'Xã Mậu Lâm', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('40746', N'Thường Xuân', N'Xã Thường Xuân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('41002', N'Thắng Lộc', N'Xã Thắng Lộc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('41258', N'Xuân Chinh', N'Xã Xuân Chinh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4138', N'Phú Xuân', N'Xã Phú Xuân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('41514', N'Hạc Thành', N'Phường Hạc Thành', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('41770', N'Hà Trung', N'Xã Hà Trung', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('42026', N'Thiệu Hóa', N'Xã Thiệu Hóa', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('42282', N'Quan Sơn', N'Xã Quan Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('42538', N'Như Thanh', N'Xã Như Thanh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4394', N'Thanh Kỳ', N'Xã Thanh Kỳ', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4650', N'Xuân Thái', N'Xã Xuân Thái', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4906', N'Yên Thọ', N'Xã Yên Thọ', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5162', N'Mường Lý', N'Xã Mường Lý', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5418', N'Yên Khương', N'Xã Yên Khương', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('554', N'Thọ Phú', N'Xã Thọ Phú', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5674', N'Yên Thắng', N'Xã Yên Thắng', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5930', N'Mường Lát', N'Xã Mường Lát', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6186', N'Mường Chanh', N'Xã Mường Chanh', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6442', N'Thiệu Trung', N'Xã Thiệu Trung', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6698', N'Bát Mọt', N'Xã Bát Mọt', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6954', N'Luận Thành', N'Xã Luận Thành', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7210', N'Lương Sơn', N'Xã Lương Sơn', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7466', N'Vạn Xuân', N'Xã Vạn Xuân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7722', N'Tân Thành', N'Xã Tân Thành', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7978', N'Hải Bình', N'Phường Hải Bình', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('810', N'Trung Lý', N'Xã Trung Lý', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8234', N'Yên Nhân', N'Xã Yên Nhân', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8490', N'Định Hòa', N'Xã Định Hòa', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8746', N'Hàm Rồng', N'Phường Hàm Rồng', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9002', N'Hoạt Giang', N'Xã Hoạt Giang', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9258', N'Vạn Lộc', N'Xã Vạn Lộc', 'xa', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9514', N'Đông Quang', N'Phường Đông Quang', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9770', N'Quảng Phú', N'Phường Quảng Phú', 'phuong', '42');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10027', N'Sủng Máng', N'Xã Sủng Máng', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10283', N'Sơn Vĩ', N'Xã Sơn Vĩ', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10539', N'Khâu Vai', N'Xã Khâu Vai', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1067', N'Giáp Trung', N'Xã Giáp Trung', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10795', N'Niêm Sơn', N'Xã Niêm Sơn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11051', N'Tát Ngà', N'Xã Tát Ngà', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11307', N'Thắng Mố', N'Xã Thắng Mố', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11563', N'Bạch Đích', N'Xã Bạch Đích', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11819', N'Yên Minh', N'Xã Yên Minh', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12075', N'Mậu Duệ', N'Xã Mậu Duệ', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12331', N'Du Già', N'Xã Du Già', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12587', N'Đường Thượng', N'Xã Đường Thượng', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12843', N'Lùng Tám', N'Xã Lùng Tám', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13099', N'Cán Tỷ', N'Xã Cán Tỷ', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1323', N'Hà Giang 2', N'Phường Hà Giang 2', 'phuong', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13355', N'Nghĩa Thuận', N'Xã Nghĩa Thuận', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13611', N'Quản Bạ', N'Xã Quản Bạ', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13867', N'Tùng Vài', N'Xã Tùng Vài', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14123', N'Yên Cường', N'Xã Yên Cường', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14379', N'Đường Hồng', N'Xã Đường Hồng', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14635', N'Bắc Mê', N'Xã Bắc Mê', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14891', N'Lao Chải', N'Xã Lao Chải', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15147', N'Thanh Thủy', N'Xã Thanh Thủy', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15403', N'Phú Linh', N'Xã Phú Linh', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15659', N'Linh Hồ', N'Xã Linh Hồ', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1579', N'Ngọc Đường', N'Xã Ngọc Đường', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15915', N'Bạch Ngọc', N'Xã Bạch Ngọc', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16171', N'Tân Quang', N'Xã Tân Quang', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16427', N'Đồng Tâm', N'Xã Đồng Tâm', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16683', N'Liên Hiệp', N'Xã Liên Hiệp', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16939', N'Bằng Hành', N'Xã Bằng Hành', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17195', N'Bắc Quang', N'Xã Bắc Quang', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17451', N'Hùng An', N'Xã Hùng An', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17707', N'Vĩnh Tuy', N'Xã Vĩnh Tuy', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17963', N'Đồng Yên', N'Xã Đồng Yên', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18219', N'Tiên Yên', N'Xã Tiên Yên', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1835', N'Tiên Nguyên', N'Xã Tiên Nguyên', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18475', N'Xuân Giang', N'Xã Xuân Giang', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18731', N'Bằng Lang', N'Xã Bằng Lang', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18987', N'Yên Thành', N'Xã Yên Thành', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19243', N'Quang Bình', N'Xã Quang Bình', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19499', N'Tân Trịnh', N'Xã Tân Trịnh', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19755', N'Thông Nguyên', N'Xã Thông Nguyên', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20011', N'Hồ Thầu', N'Xã Hồ Thầu', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20267', N'Nậm Dịch', N'Xã Nậm Dịch', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20523', N'Thái Bình', N'Xã Thái Bình', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20779', N'Thượng Lâm', N'Xã Thượng Lâm', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2091', N'Vị Xuyên', N'Xã Vị Xuyên', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21035', N'Lâm Bình', N'Xã Lâm Bình', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21291', N'Minh Quang', N'Xã Minh Quang', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21547', N'Bình An', N'Xã Bình An', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21803', N'Côn Lôn', N'Xã Côn Lôn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22059', N'Yên Hoa', N'Xã Yên Hoa', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22315', N'Thượng Nông', N'Xã Thượng Nông', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22571', N'Hồng Thái', N'Xã Hồng Thái', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22827', N'Nà Hang', N'Xã Nà Hang', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23083', N'Tân Mỹ', N'Xã Tân Mỹ', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23339', N'Yên Lập', N'Xã Yên Lập', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2347', N'Cao Bồ', N'Xã Cao Bồ', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23595', N'Tân An', N'Xã Tân An', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23851', N'Chiêm Hóa', N'Xã Chiêm Hóa', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24107', N'Hòa An', N'Xã Hòa An', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24363', N'Kiên Đài', N'Xã Kiên Đài', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24619', N'Tri Phú', N'Xã Tri Phú', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24875', N'Kim Bình', N'Xã Kim Bình', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25131', N'Yên Nguyên', N'Xã Yên Nguyên', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25387', N'Yên Phú', N'Xã Yên Phú', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25643', N'Bạch Xa', N'Xã Bạch Xa', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25899', N'Phù Lưu', N'Xã Phù Lưu', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2603', N'Mèo Vạc', N'Xã Mèo Vạc', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26155', N'Hàm Yên', N'Xã Hàm Yên', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26411', N'Bình Xa', N'Xã Bình Xa', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26667', N'Thái Sơn', N'Xã Thái Sơn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26923', N'Thái Hòa', N'Xã Thái Hòa', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27179', N'Hùng Lợi', N'Xã Hùng Lợi', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27435', N'Trung Sơn', N'Xã Trung Sơn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27691', N'Tân Long', N'Xã Tân Long', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27947', N'Xuân Vân', N'Xã Xuân Vân', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28203', N'Lực Hành', N'Xã Lực Hành', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28459', N'Yên Sơn', N'Xã Yên Sơn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2859', N'Thuận Hòa', N'Xã Thuận Hòa', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28715', N'Nhữ Khê', N'Xã Nhữ Khê', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28971', N'Tân Trào', N'Xã Tân Trào', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29227', N'Minh Thanh', N'Xã Minh Thanh', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29483', N'Sơn Dương', N'Xã Sơn Dương', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29739', N'Bình Ca', N'Xã Bình Ca', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('299', N'Ngọc Long', N'Xã Ngọc Long', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29995', N'Tân Thanh', N'Xã Tân Thanh', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30251', N'Sơn Thủy', N'Xã Sơn Thủy', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30507', N'Phú Lương', N'Xã Phú Lương', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30763', N'Trường Sinh', N'Xã Trường Sinh', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31019', N'Hồng Sơn', N'Xã Hồng Sơn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3115', N'Thượng Sơn', N'Xã Thượng Sơn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31275', N'Đông Thọ', N'Xã Đông Thọ', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31531', N'An Tường', N'Phường An Tường', 'phuong', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31787', N'Bình Thuận', N'Phường Bình Thuận', 'phuong', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3371', N'Tùng Bá', N'Xã Tùng Bá', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3627', N'Việt Lâm', N'Xã Việt Lâm', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3883', N'Quảng Nguyên', N'Xã Quảng Nguyên', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4139', N'Minh Ngọc', N'Xã Minh Ngọc', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4395', N'Hà Giang 1', N'Phường Hà Giang 1', 'phuong', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4651', N'Minh Tân', N'Xã Minh Tân', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4907', N'Nông Tiến', N'Phường Nông Tiến', 'phuong', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5163', N'Minh Xuân', N'Phường Minh Xuân', 'phuong', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5419', N'Trung Hà', N'Xã Trung Hà', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('555', N'Đồng Văn', N'Xã Đồng Văn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5675', N'Hùng Đức', N'Xã Hùng Đức', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5931', N'Kiến Thiết', N'Xã Kiến Thiết', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6187', N'Mỹ Lâm', N'Phường Mỹ Lâm', 'phuong', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6443', N'Tân Tiến', N'Xã Tân Tiến', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6699', N'Hoàng Su Phì', N'Xã Hoàng Su Phì', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6955', N'Thàng Tín', N'Xã Thàng Tín', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7211', N'Bản Máy', N'Xã Bản Máy', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7467', N'Pờ Ly Ngài', N'Xã Pờ Ly Ngài', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7723', N'Xín Mần', N'Xã Xín Mần', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7979', N'Pà Vầy Sủ', N'Xã Pà Vầy Sủ', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('811', N'Minh Sơn', N'Xã Minh Sơn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8235', N'Nấm Dẩn', N'Xã Nấm Dẩn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8491', N'Trung Thịnh', N'Xã Trung Thịnh', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8747', N'Khuôn Lùng', N'Xã Khuôn Lùng', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9003', N'Lũng Cú', N'Xã Lũng Cú', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9259', N'Sà Phìn', N'Xã Sà Phìn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9515', N'Phố Bảng', N'Xã Phố Bảng', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9771', N'Lũng Phìn', N'Xã Lũng Phìn', 'xa', '43');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10028', N'Mỹ Thuận', N'Xã Mỹ Thuận', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10284', N'Đông Thành', N'Phường Đông Thành', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10540', N'Trà Vinh', N'Phường Trà Vinh', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1068', N'Long Hữu', N'Xã Long Hữu', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('10796', N'Long Đức', N'Phường Long Đức', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11052', N'Nguyệt Hóa', N'Phường Nguyệt Hóa', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11308', N'Hòa Thuận', N'Phường Hòa Thuận', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11564', N'Càng Long', N'Xã Càng Long', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('11820', N'An Trường', N'Xã An Trường', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12076', N'Tân An', N'Xã Tân An', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12332', N'Nhị Long', N'Xã Nhị Long', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12588', N'Bình Phú', N'Xã Bình Phú', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('12844', N'Châu Thành', N'Xã Châu Thành', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13100', N'Song Lộc', N'Xã Song Lộc', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1324', N'Long Vĩnh', N'Xã Long Vĩnh', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13356', N'Hưng Mỹ', N'Xã Hưng Mỹ', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13612', N'Cầu Kè', N'Xã Cầu Kè', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('13868', N'Phong Thạnh', N'Xã Phong Thạnh', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14124', N'An Phú Tân', N'Xã An Phú Tân', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14380', N'Tam Ngãi', N'Xã Tam Ngãi', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14636', N'Tiểu Cần', N'Xã Tiểu Cần', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('14892', N'Tân Hòa', N'Xã Tân Hòa', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15148', N'Hùng Hòa', N'Xã Hùng Hòa', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15404', N'Tập Ngãi', N'Xã Tập Ngãi', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15660', N'Cầu Ngang', N'Xã Cầu Ngang', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1580', N'Cái Vồn', N'Phường Cái Vồn', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('15916', N'Mỹ Long', N'Xã Mỹ Long', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16172', N'Vinh Kim', N'Xã Vinh Kim', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16428', N'Nhị Trường', N'Xã Nhị Trường', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16684', N'Hiệp Mỹ', N'Xã Hiệp Mỹ', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('16940', N'Trà Cú', N'Xã Trà Cú', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17196', N'Đại An', N'Xã Đại An', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17452', N'Lưu Nghiệp Anh', N'Xã Lưu Nghiệp Anh', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17708', N'Hàm Giang', N'Xã Hàm Giang', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('17964', N'Long Hiệp', N'Xã Long Hiệp', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18220', N'Tập Sơn', N'Xã Tập Sơn', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('1836', N'Bình Minh', N'Phường Bình Minh', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18476', N'Duyên Hải', N'Phường Duyên Hải', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18732', N'Trường Long Hòa', N'Phường Trường Long Hòa', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('18988', N'Long Thành', N'Xã Long Thành', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19244', N'Đôn Châu', N'Xã Đôn Châu', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19500', N'Ngũ Lạc', N'Xã Ngũ Lạc', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('19756', N'An Hội', N'Phường An Hội', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20012', N'Phú Khương', N'Phường Phú Khương', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20268', N'Bến Tre', N'Phường Bến Tre', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20524', N'Sơn Đông', N'Phường Sơn Đông', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('20780', N'Phú Tân', N'Phường Phú Tân', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2092', N'Tam Bình', N'Xã Tam Bình', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21036', N'Phú Túc', N'Xã Phú Túc', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21292', N'Giao Long', N'Xã Giao Long', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21548', N'Tiên Thủy', N'Xã Tiên Thủy', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('21804', N'Tân Phú', N'Xã Tân Phú', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22060', N'Phú Phụng', N'Xã Phú Phụng', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22316', N'Chợ Lách', N'Xã Chợ Lách', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22572', N'Vĩnh Thành', N'Xã Vĩnh Thành', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('22828', N'Hưng Khánh Trung', N'Xã Hưng Khánh Trung', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23084', N'Phước Mỹ Trung', N'Xã Phước Mỹ Trung', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23340', N'Tân Thành Bình', N'Xã Tân Thành Bình', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2348', N'Ngãi Tứ', N'Xã Ngãi Tứ', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23596', N'Nhuận Phú Tân', N'Xã Nhuận Phú Tân', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('23852', N'Đồng Khởi', N'Xã Đồng Khởi', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24108', N'Mỏ Cày', N'Xã Mỏ Cày', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24364', N'Thành Thới', N'Xã Thành Thới', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24620', N'An Định', N'Xã An Định', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('24876', N'Hương Mỹ', N'Xã Hương Mỹ', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25132', N'Đại Điền', N'Xã Đại Điền', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25388', N'Quới Điền', N'Xã Quới Điền', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25644', N'Thạnh Phú', N'Xã Thạnh Phú', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('25900', N'An Qui', N'Xã An Qui', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2604', N'Trà Ôn', N'Xã Trà Ôn', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26156', N'Thạnh Hải', N'Xã Thạnh Hải', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26412', N'Thạnh Phong', N'Xã Thạnh Phong', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26668', N'Tân Thủy', N'Xã Tân Thủy', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('26924', N'Bảo Thạnh', N'Xã Bảo Thạnh', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27180', N'Ba Tri', N'Xã Ba Tri', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27436', N'Tân Xuân', N'Xã Tân Xuân', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27692', N'Mỹ Chánh Hòa', N'Xã Mỹ Chánh Hòa', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('27948', N'An Ngãi Trung', N'Xã An Ngãi Trung', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28204', N'An Hiệp', N'Xã An Hiệp', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28460', N'Hưng Nhượng', N'Xã Hưng Nhượng', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('2860', N'Trà Côn', N'Xã Trà Côn', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28716', N'Giồng Trôm', N'Xã Giồng Trôm', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('28972', N'Tân Hào', N'Xã Tân Hào', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29228', N'Phước Long', N'Xã Phước Long', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29484', N'Lương Phú', N'Xã Lương Phú', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29740', N'Châu Hòa', N'Xã Châu Hòa', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('29996', N'Lương Hòa', N'Xã Lương Hòa', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('300', N'Hòa Minh', N'Xã Hòa Minh', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30252', N'Thới Thuận', N'Xã Thới Thuận', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30508', N'Thạnh Phước', N'Xã Thạnh Phước', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('30764', N'Bình Đại', N'Xã Bình Đại', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31020', N'Thạnh Trị', N'Xã Thạnh Trị', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3116', N'Cái Nhum', N'Xã Cái Nhum', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31276', N'Lộc Thuận', N'Xã Lộc Thuận', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31532', N'Châu Hưng', N'Xã Châu Hưng', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('31788', N'Phú Thuận', N'Xã Phú Thuận', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3372', N'Tân Long Hội', N'Xã Tân Long Hội', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3628', N'Nhơn Phú', N'Xã Nhơn Phú', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('3884', N'Bình Phước', N'Xã Bình Phước', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4140', N'An Bình', N'Xã An Bình', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4396', N'Long Hồ', N'Xã Long Hồ', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4652', N'Phú Quới', N'Xã Phú Quới', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('4908', N'Thanh Đức', N'Phường Thanh Đức', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5164', N'Long Châu', N'Phường Long Châu', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5420', N'Phước Hậu', N'Phường Phước Hậu', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('556', N'Long Hòa', N'Xã Long Hòa', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5676', N'Tân Hạnh', N'Phường Tân Hạnh', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('5932', N'Tân Ngãi', N'Phường Tân Ngãi', 'phuong', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6188', N'Quới Thiện', N'Xã Quới Thiện', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6444', N'Trung Thành', N'Xã Trung Thành', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6700', N'Trung Ngãi', N'Xã Trung Ngãi', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('6956', N'Quới An', N'Xã Quới An', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7212', N'Trung Hiệp', N'Xã Trung Hiệp', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7468', N'Hiếu Phụng', N'Xã Hiếu Phụng', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7724', N'Hiếu Thành', N'Xã Hiếu Thành', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('7980', N'Lục Sĩ Thành', N'Xã Lục Sĩ Thành', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('812', N'Đông Hải', N'Xã Đông Hải', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8236', N'Vĩnh Xuân', N'Xã Vĩnh Xuân', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8492', N'Hòa Bình', N'Xã Hòa Bình', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('8748', N'Hòa Hiệp', N'Xã Hòa Hiệp', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9004', N'Song Phú', N'Xã Song Phú', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9260', N'Cái Ngang', N'Xã Cái Ngang', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9516', N'Tân Quới', N'Xã Tân Quới', 'xa', '44');
INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) VALUES ('9772', N'Tân Lược', N'Xã Tân Lược', 'xa', '44');

-- Total communes: 3321

-- ========================================
-- Create UserAddresses Table
-- ========================================
CREATE TABLE UserAddresses (
    address_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    commune_code VARCHAR(10) NOT NULL,
    street_address NVARCHAR(255),
    full_address NVARCHAR(500),
    is_default BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_UserAddresses_Users FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT FK_UserAddresses_Communes FOREIGN KEY (commune_code) REFERENCES Communes(commune_code)
);

-- ========================================
-- Create Orders Table
-- ========================================
CREATE TABLE Orders (
    order_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    post_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    shipping_address_id BIGINT NOT NULL,
    order_total_amount DECIMAL(15,2) NOT NULL,
    order_status VARCHAR(20) NOT NULL DEFAULT 'DEPOSITED'
        CHECK (order_status IN ('DEPOSITED','PAID','SHIPPING','COMPLETED','CANCELLED')),
    shipping_method NVARCHAR(100),
    shipping_tracking_number NVARCHAR(100),
    shipping_proof_image NVARCHAR(500),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    shipped_at DATETIME2,
    CONSTRAINT FK_Orders_Posts FOREIGN KEY (post_id) REFERENCES BicyclePosts(post_id),
    CONSTRAINT FK_Orders_Buyers FOREIGN KEY (buyer_id) REFERENCES Users(user_id),
    CONSTRAINT FK_Orders_Addresses FOREIGN KEY (shipping_address_id) REFERENCES UserAddresses(address_id)
);

-- 11. Create Wallets Table (Ví điện tử)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Wallets' AND xtype='U')
BEGIN
    CREATE TABLE Wallets (
        wallet_id BIGINT IDENTITY(1,1) PRIMARY KEY,

        -- Foreign Key: 1 user = 1 ví
        user_id BIGINT NOT NULL UNIQUE,

        -- Số dư ví
        balance DECIMAL(18,2) NOT NULL DEFAULT 0,

        -- Timestamps
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),

        -- Foreign Key Constraint
        CONSTRAINT FK_Wallets_Users FOREIGN KEY (user_id) REFERENCES Users(user_id)
    );
    PRINT 'Table Wallets created successfully.';
END
ELSE
BEGIN
    PRINT 'Table Wallets already exists.';
END
GO

-- 12. Create Transactions Table (Lịch sử giao dịch)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Transactions' AND xtype='U')
BEGIN
    CREATE TABLE Transactions (
        transaction_id BIGINT IDENTITY(1,1) PRIMARY KEY,

        -- Foreign Keys
        wallet_id BIGINT NOT NULL,
        user_id BIGINT NOT NULL,
        post_id BIGINT NULL,  -- Chỉ có giá trị khi DEPOSIT/PURCHASE/REFUND

        -- Loại giao dịch: TOP_UP (nạp ví), DEPOSIT (đặt cọc), PURCHASE (mua), REFUND (hoàn)
        transaction_type VARCHAR(20) NOT NULL
            CHECK (transaction_type IN ('TOP_UP', 'DEPOSIT', 'PURCHASE', 'REFUND')),

        -- Số tiền giao dịch
        amount DECIMAL(18,2) NOT NULL,

        -- Trạng thái: PENDING (chờ), SUCCESS (thành công), FAILED (thất bại)
        status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
            CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED')),

        -- Thông tin VNPay (chỉ dùng khi TOP_UP)
        vnp_txn_ref VARCHAR(100) UNIQUE,        -- Mã GD gửi VNPay
        vnp_transaction_no VARCHAR(100),         -- Mã GD phía VNPay trả về
        vnp_bank_code VARCHAR(50),               -- Ngân hàng thanh toán
        vnp_response_code VARCHAR(10),           -- Mã phản hồi (00 = thành công)

        -- Mô tả giao dịch
        description NVARCHAR(500),

        -- Timestamps
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),

        -- Foreign Key Constraints
        CONSTRAINT FK_Transactions_Wallets FOREIGN KEY (wallet_id) REFERENCES Wallets(wallet_id),
        CONSTRAINT FK_Transactions_Users FOREIGN KEY (user_id) REFERENCES Users(user_id),
        CONSTRAINT FK_Transactions_Posts FOREIGN KEY (post_id) REFERENCES BicyclePosts(post_id)
    );
    PRINT 'Table Transactions created successfully.';
END
ELSE
BEGIN
    PRINT 'Table Transactions already exists.';
END
GO

-- =============================================
-- SystemConfig Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SystemConfig' AND xtype='U')
BEGIN
    CREATE TABLE SystemConfig (
        config_key VARCHAR(50) PRIMARY KEY,
        config_value VARCHAR(200) NOT NULL,
        description NVARCHAR(500),
        updated_at DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Table SystemConfig created successfully.';
END
ELSE
BEGIN
    PRINT 'Table SystemConfig already exists.';
END
GO

-- Seed SystemConfig data
IF EXISTS (SELECT * FROM sysobjects WHERE name='SystemConfig' AND xtype='U')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM SystemConfig WHERE config_key = 'DEPOSIT_RATE')
        INSERT INTO SystemConfig (config_key, config_value, description, updated_at)
        VALUES ('DEPOSIT_RATE', '10', N'Tỷ lệ đặt cọc (%)', GETDATE());

    IF NOT EXISTS (SELECT 1 FROM SystemConfig WHERE config_key = 'POSTING_FEE')
        INSERT INTO SystemConfig (config_key, config_value, description, updated_at)
        VALUES ('POSTING_FEE', '50000', N'Phí đăng bài (VND)', GETDATE());

    IF NOT EXISTS (SELECT 1 FROM SystemConfig WHERE config_key = 'AUTO_CONFIRM_DAYS')
        INSERT INTO SystemConfig (config_key, config_value, description, updated_at)
        VALUES ('AUTO_CONFIRM_DAYS', '7', N'Tự động xác nhận sau X ngày', GETDATE());

    PRINT 'SystemConfig seed data inserted.';
END
GO

-- =============================================
-- Orders Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Orders' AND xtype='U')
BEGIN
    CREATE TABLE Orders (
        order_id BIGINT IDENTITY(1,1) PRIMARY KEY,

        -- Foreign Keys
        post_id BIGINT NOT NULL,
        buyer_id BIGINT NOT NULL,
        address_id BIGINT,

        -- Pricing
        total_price DECIMAL(18,2) NOT NULL,
        deposit_amount DECIMAL(18,2),

        -- Status
        order_status VARCHAR(20) NOT NULL DEFAULT 'DEPOSITED'
            CHECK (order_status IN ('DEPOSITED', 'PAID', 'SHIPPING', 'COMPLETED', 'CANCELLED')),

        -- Shipping info
        shipping_method NVARCHAR(100),
        shipping_tracking_number VARCHAR(200),
        proof_image VARCHAR(500),
        shipped_at DATETIME2,

        -- Timestamps
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),

        -- Foreign Key Constraints
        CONSTRAINT FK_Orders_Posts FOREIGN KEY (post_id) REFERENCES BicyclePosts(post_id),
        CONSTRAINT FK_Orders_Buyers FOREIGN KEY (buyer_id) REFERENCES Users(user_id),
        CONSTRAINT FK_Orders_Addresses FOREIGN KEY (address_id) REFERENCES UserAddresses(address_id)
    );
    PRINT 'Table Orders created successfully.';
END
ELSE
BEGIN
    PRINT 'Table Orders already exists.';
END
GO
