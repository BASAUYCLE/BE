USE BikeShopDB;
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Disputes' AND xtype='U')
BEGIN
    CREATE TABLE Disputes (
        dispute_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        order_id    BIGINT NOT NULL UNIQUE,
        buyer_id    BIGINT NOT NULL,
        inspector_id BIGINT,
        status      VARCHAR(50) NOT NULL,
        reason      NVARCHAR(500) NOT NULL,
        proof_images VARCHAR(1000) NOT NULL,
        inspector_note NVARCHAR(1000),
        admin_note  NVARCHAR(1000),
        resolved_by BIGINT,
        shipping_provider NVARCHAR(100),
        tracking_code VARCHAR(200),
        shipping_receipt_url VARCHAR(500),
        return_shipped_at DATETIME2,
        resolved_at DATETIME2,
        created_at  DATETIME2 DEFAULT GETDATE(),
        updated_at  DATETIME2 DEFAULT GETDATE(),

        CONSTRAINT FK_Disputes_Orders  FOREIGN KEY (order_id)  REFERENCES Orders(order_id),
        CONSTRAINT FK_Disputes_Buyers  FOREIGN KEY (buyer_id)  REFERENCES Users(user_id),
        CONSTRAINT FK_Disputes_Inspectors FOREIGN KEY (inspector_id) REFERENCES Users(user_id),
        CONSTRAINT FK_Disputes_ResolvedBy FOREIGN KEY (resolved_by) REFERENCES Users(user_id)
    );
    PRINT 'Table Disputes created successfully.';
END
ELSE
BEGIN
    PRINT 'Table Disputes already exists.';
END
GO

-- Add delivered_at to Orders if not exists
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('Orders') AND name = 'delivered_at'
)
BEGIN
    ALTER TABLE Orders ADD delivered_at DATETIME2;
    PRINT 'Column delivered_at added to Orders table.';
END
ELSE
BEGIN
    PRINT 'Column delivered_at already exists in Orders table.';
END
GO
