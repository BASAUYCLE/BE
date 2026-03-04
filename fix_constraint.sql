USE BikeShopDB;
GO

DECLARE @ConstraintName nvarchar(200)
SELECT @ConstraintName = Name 
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('BicyclePosts')
AND definition LIKE '%post_status%';

IF @ConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE BicyclePosts DROP CONSTRAINT ' + @ConstraintName)
    PRINT 'Dropped constraint: ' + @ConstraintName
END
ELSE
BEGIN
    PRINT 'No constraint found on post_status'
END
GO

ALTER TABLE BicyclePosts
ADD CONSTRAINT CK_BicyclePosts_Status 
CHECK (post_status IN ('PENDING', 'ADMIN_APPROVED', 'AVAILABLE', 
                       'DEPOSITED', 'SOLD', 'REJECTED', 'DRAFTED', 'HIDDEN'));
PRINT 'Added new constraint CK_BicyclePosts_Status';
GO



ALTER TABLE Orders ALTER COLUMN order_total_amount decimal(18,2) NULL;

UPDATE SystemConfig SET config_value = '36' WHERE config_key = 'DEPOSIT_RATE';

-- Bước 1: Xem tên constraint hiện tại
SELECT name, definition 
FROM sys.check_constraints 
WHERE parent_object_id = OBJECT_ID('Transactions');

-- Xóa constraint cũ
ALTER TABLE Transactions DROP CONSTRAINT CK__Transacti__trans__00200768;

-- Thêm lại với POSTING_FEE
ALTER TABLE Transactions ADD CONSTRAINT CK__Transacti__trans__00200768 
CHECK (transaction_type IN ('REFUND', 'PURCHASE', 'DEPOSIT', 'TOP_UP', 'POSTING_FEE'));

-- Xóa UNIQUE constraint trên vnp_txn_ref
ALTER TABLE Transactions DROP CONSTRAINT UQ__Transact__A169B9F05C71DCA3;

-- Xóa constraint cũ
ALTER TABLE BicyclePosts DROP CONSTRAINT CK_BicyclePosts_Status;

-- Thêm lại với PROCESSING và HIDDEN
ALTER TABLE BicyclePosts ADD CONSTRAINT CK_BicyclePosts_Status 
CHECK (post_status IN ('PENDING', 'ADMIN_APPROVED', 'AVAILABLE', 
  'PROCESSING', 'DEPOSITED', 'SOLD', 'REJECTED', 'DRAFTED', 'HIDDEN'));
