USE BikeShopDB;
GO

-- ========================================
-- CẬP NHẬT CONSTRAINT CHO BẢNG Transactions
-- Phải xóa constraint cũ trước rồi tạo mới
-- ========================================

DECLARE @TxnConstraint nvarchar(200)
SELECT @TxnConstraint = Name 
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('Transactions')
AND definition LIKE '%transaction_type%';

IF @TxnConstraint IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Transactions DROP CONSTRAINT ' + @TxnConstraint)
    PRINT 'Dropped old transaction_type constraint: ' + @TxnConstraint
END
GO

ALTER TABLE Transactions ADD CONSTRAINT CK_Transactions_Type 
CHECK (transaction_type IN ('TOP_UP', 'DEPOSIT', 'PURCHASE', 'REFUND', 'POSTING_FEE', 'PAY_REMAINING'));
PRINT 'Added constraint CK_Transactions_Type with PAY_REMAINING';
GO
