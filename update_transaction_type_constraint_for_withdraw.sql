-- SQL Server: Thêm giá trị WITHDRAW vào CHECK constraint của cột transaction_type (bảng Transactions)

DECLARE @TxConstraintName nvarchar(200);
SELECT @TxConstraintName = Name
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('Transactions')
  AND parent_column_id = (
    SELECT column_id FROM sys.columns
    WHERE object_id = OBJECT_ID('Transactions') AND name = 'transaction_type'
  );

IF @TxConstraintName IS NOT NULL
BEGIN
  EXEC('ALTER TABLE Transactions DROP CONSTRAINT ' + @TxConstraintName);
  PRINT 'Dropped: ' + @TxConstraintName;
END
GO

ALTER TABLE Transactions ADD CONSTRAINT CHK_Transactions_Type
CHECK (transaction_type IN (
  'TOP_UP',
  'DEPOSIT',
  'PURCHASE',
  'REFUND',
  'POSTING_FEE',
  'PAY_REMAINING',
  'DISPUTE_REFUND',
  'RELEASE_MONEY',
  'WITHDRAW'
));
PRINT 'CHK_Transactions_Type updated to include WITHDRAW.';
GO
