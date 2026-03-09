USE BikeShopDB;
GO

-- ========================================
-- 1. FIX BẢNG ORDERS (Drop + Recreate)
-- ========================================
IF EXISTS (SELECT * FROM sysobjects WHERE name='Orders' AND xtype='U')
BEGIN
    DROP TABLE Orders;
    PRINT 'Dropped table Orders';
END
GO

CREATE TABLE Orders (
    order_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    post_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    shipping_address_id BIGINT,
    total_price DECIMAL(18,2) NOT NULL,
    deposit_amount DECIMAL(18,2),
    order_status VARCHAR(20) NOT NULL DEFAULT 'DEPOSITED'
        CHECK (order_status IN ('DEPOSITED','PAID','SHIPPING','COMPLETED','CANCELLED')),
    shipping_method NVARCHAR(100),
    shipping_tracking_number NVARCHAR(200),
    proof_image NVARCHAR(500),
    shipped_at DATETIME2,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Orders_Posts FOREIGN KEY (post_id) REFERENCES BicyclePosts(post_id),
    CONSTRAINT FK_Orders_Buyers FOREIGN KEY (buyer_id) REFERENCES Users(user_id),
    CONSTRAINT FK_Orders_Addresses FOREIGN KEY (shipping_address_id) REFERENCES UserAddresses(address_id)
);
PRINT 'Created table Orders (new schema)';
GO

-- ========================================
-- 2. FIX CONSTRAINT BẢNG Transactions
--    Thêm POSTING_FEE + Xóa UNIQUE vnp_txn_ref
-- ========================================

-- 2a. Xóa constraint transaction_type (tự tìm tên)
DECLARE @TxnConstraint nvarchar(200)
SELECT @TxnConstraint = Name 
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('Transactions')
AND definition LIKE '%transaction_type%';

IF @TxnConstraint IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Transactions DROP CONSTRAINT ' + @TxnConstraint)
    PRINT 'Dropped transaction_type constraint: ' + @TxnConstraint
END
GO

-- 2b. Thêm lại với POSTING_FEE và PAY_REMAINING
ALTER TABLE Transactions ADD CONSTRAINT CK_Transactions_Type 
CHECK (transaction_type IN ('TOP_UP', 'DEPOSIT', 'PURCHASE', 'REFUND', 'POSTING_FEE', 'PAY_REMAINING'));
PRINT 'Added constraint CK_Transactions_Type with POSTING_FEE and PAY_REMAINING';
GO

-- 2c. Xóa UNIQUE constraint trên vnp_txn_ref (tự tìm tên)
DECLARE @UniqueConstraint nvarchar(200)
SELECT @UniqueConstraint = Name 
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('Transactions')
AND type = 'UQ';

IF @UniqueConstraint IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Transactions DROP CONSTRAINT ' + @UniqueConstraint)
    PRINT 'Dropped UNIQUE constraint: ' + @UniqueConstraint
END
GO

-- ========================================
-- 3. FIX CONSTRAINT BẢNG BicyclePosts
--    Thêm PROCESSING
-- ========================================

DECLARE @PostConstraint nvarchar(200)
SELECT @PostConstraint = Name 
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('BicyclePosts')
AND definition LIKE '%post_status%';

IF @PostConstraint IS NOT NULL
BEGIN
    EXEC('ALTER TABLE BicyclePosts DROP CONSTRAINT ' + @PostConstraint)
    PRINT 'Dropped post_status constraint: ' + @PostConstraint
END
GO

ALTER TABLE BicyclePosts ADD CONSTRAINT CK_BicyclePosts_Status 
CHECK (post_status IN ('PENDING', 'ADMIN_APPROVED', 'AVAILABLE', 
    'PROCESSING', 'DEPOSITED', 'SOLD', 'REJECTED', 'DRAFTED', 'HIDDEN'));
PRINT 'Added constraint CK_BicyclePosts_Status with PROCESSING';
GO

-- ========================================
-- 4. TẠO BẢNG SystemConfig (nếu chưa có)
-- ========================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SystemConfig' AND xtype='U')
BEGIN
    CREATE TABLE SystemConfig (
        config_key VARCHAR(50) PRIMARY KEY,
        config_value VARCHAR(200) NOT NULL,
        description NVARCHAR(500),
        updated_at DATETIME2 DEFAULT GETDATE()
    );

    INSERT INTO SystemConfig VALUES ('DEPOSIT_RATE', '10', N'Tỷ lệ đặt cọc (%)', GETDATE());
    INSERT INTO SystemConfig VALUES ('POSTING_FEE', '50000', N'Phí đăng bài (VND)', GETDATE());
    INSERT INTO SystemConfig VALUES ('AUTO_CONFIRM_DAYS', '7', N'Tự động xác nhận sau X ngày', GETDATE());

    PRINT 'Created table SystemConfig with default values';
END
ELSE
BEGIN
    PRINT 'Table SystemConfig already exists';
END
GO

PRINT '===== ALL FIXES COMPLETED =====';
GO
