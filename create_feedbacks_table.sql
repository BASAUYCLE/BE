USE BikeShopDB;
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Feedbacks' AND xtype='U')
BEGIN
    CREATE TABLE Feedbacks (
        feedback_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        order_id    BIGINT NOT NULL UNIQUE,
        buyer_id    BIGINT NOT NULL,
        seller_id   BIGINT NOT NULL,
        post_id     BIGINT NOT NULL,
        rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment     NVARCHAR(1000),
        created_at  DATETIME2 DEFAULT GETDATE(),
        updated_at  DATETIME2 DEFAULT GETDATE(),

        CONSTRAINT FK_Feedbacks_Orders  FOREIGN KEY (order_id)  REFERENCES Orders(order_id),
        CONSTRAINT FK_Feedbacks_Buyers  FOREIGN KEY (buyer_id)  REFERENCES Users(user_id),
        CONSTRAINT FK_Feedbacks_Sellers FOREIGN KEY (seller_id) REFERENCES Users(user_id),
        CONSTRAINT FK_Feedbacks_Posts   FOREIGN KEY (post_id)   REFERENCES BicyclePosts(post_id)
    );
    PRINT 'Table Feedbacks created successfully.';
END
ELSE
BEGIN
    PRINT 'Table Feedbacks already exists.';
END
GO
