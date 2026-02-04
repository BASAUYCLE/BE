USE BikeShopDB;
GO

PRINT '=== BAT DAU SEEDING USERS ===';

-- 1. Tạo Admin (nếu chưa có)
IF NOT EXISTS (SELECT 1 FROM Users WHERE user_email = 'admin123@gmail.com')
BEGIN
    INSERT INTO Users (
        user_email, user_password_hash, user_full_name, user_phone_number, 
        user_role, is_verified, cccd_front, cccd_back, created_at, updated_at
    ) 
    VALUES (
        'admin123@gmail.com', 
        '$2a$10$BIsHM3zGXn2riugRdfwUfOs6BpQVJTJ3ojqusyI4/skiMdnZGp6W.', 
        N'Quan Tri Vien Ten Moi', 
        '0987654321', 
        'ADMIN', 
        'VERIFIED', 
        'https://i.ibb.co/MxSTh3yW/Sa478b28e874244edacbf335b08be106d-D-jpg-720x720q80-jpg.jpg', 
        'https://i.ibb.co/FbFZnNgZ/img2025030419102716782700-jpg.jpg', 
        '2026-01-29 21:48:50.4368260', 
        '2026-01-29 23:02:02.2146310'
    );
    PRINT '-> Tao Admin thanh cong.';
END
ELSE
BEGIN
    PRINT '-> Admin da ton tai (SKIP).';
END

-- 2. Tạo Inspector (nếu chưa có)
IF NOT EXISTS (SELECT 1 FROM Users WHERE user_email = 'inspector123@gmail.com')
BEGIN
    INSERT INTO Users (
        user_email, user_password_hash, user_full_name, user_phone_number, 
        user_role, is_verified, cccd_front, cccd_back, created_at, updated_at
    ) 
    VALUES (
        'inspector123@gmail.com', 
        '$2a$10$BIsHM3zGXn2riugRdfwUfOs6BpQVJTJ3ojqusyI4/skiMdnZGp6W.', 
        N'Nhan Vien Kiem Dinh', 
        '0987654321', 
        'INSPECTOR', 
        'VERIFIED', 
        'https://i.ibb.co/MxSTh3yW/Sa478b28e874244edacbf335b08be106d-D-jpg-720x720q80-jpg.jpg', 
        'https://i.ibb.co/FbFZnNgZ/img2025030419102716782700-jpg.jpg', 
        '2026-01-29 21:48:50.4368260', 
        '2026-01-29 23:02:02.2146310'
    );
    PRINT '-> Tao Inspector thanh cong.';
END
ELSE
BEGIN
    PRINT '-> Inspector da ton tai (SKIP).';
END

PRINT '=== HOAN TAT ===';
GO
