ALTER TABLE Transactions
ADD bank_name NVARCHAR(100) NULL,
    bank_account_number VARCHAR(50) NULL,
    bank_account_holder NVARCHAR(100) NULL;
GO
