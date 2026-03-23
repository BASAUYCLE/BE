USE bike_platform;
GO

-- Thêm cột avatar_url vào bảng Users
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('Users') AND name = 'avatar_url'
)
BEGIN
    ALTER TABLE Users
    ADD avatar_url NVARCHAR(MAX);
END
GO
