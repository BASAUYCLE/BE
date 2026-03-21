USE BikeShopDB;
GO

-- ==========================================
-- 1. Fix Orders.order_status constraint
-- ==========================================
DECLARE @ConstraintName nvarchar(200)
SELECT @ConstraintName = Name 
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('Orders') 
AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'order_status')

IF @ConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Orders DROP CONSTRAINT ' + @ConstraintName)
    PRINT 'Dropped old order_status constraint: ' + @ConstraintName
END
GO

ALTER TABLE Orders ADD CONSTRAINT CHK_Orders_Status 
CHECK (order_status IN ('DEPOSITED','PAID','SHIPPING','DELIVERED','DISPUTED','COMPLETED','CANCELLED'));
PRINT 'Added new order_status constraint (including DELIVERED and DISPUTED).';
GO

-- ==========================================
-- 2. Fix Transactions.transaction_type constraint
-- ==========================================
DECLARE @TxConstraintName nvarchar(200)
SELECT @TxConstraintName = Name 
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('Transactions') 
AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('Transactions') AND name = 'transaction_type')

IF @TxConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Transactions DROP CONSTRAINT ' + @TxConstraintName)
    PRINT 'Dropped old transaction_type constraint: ' + @TxConstraintName
END
GO

ALTER TABLE Transactions ADD CONSTRAINT CHK_Transactions_Type 
CHECK (transaction_type IN ('TOP_UP', 'DEPOSIT', 'PURCHASE', 'REFUND', 'POSTING_FEE', 'PAY_REMAINING', 'DISPUTE_REFUND'));
PRINT 'Added new transaction_type constraint (including DISPUTE_REFUND).';
GO
