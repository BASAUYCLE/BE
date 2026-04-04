USE BikeShopDB;
GO

PRINT '=== SEED 5 MEMBER USERS ===';

DECLARE @pw NVARCHAR(255) = '$2a$10$BIsHM3zGXn2riugRdfwUfOs6BpQVJTJ3ojqusyI4/skiMdnZGp6W.';
DECLARE @ccf NVARCHAR(MAX) = 'https://i.ibb.co/MxSTh3yW/Sa478b28e874244edacbf335b08be106d-D-jpg-720x720q80-jpg.jpg';
DECLARE @ccb NVARCHAR(MAX) = 'https://i.ibb.co/FbFZnNgZ/img2025030419102716782700-jpg.jpg';

IF NOT EXISTS (SELECT 1 FROM Users WHERE user_email = 'nctrung.dev@gmail.com')
INSERT INTO Users (user_email, user_password_hash, user_full_name, user_phone_number, user_role, is_verified, cccd_front, cccd_back)
VALUES ('nctrung.dev@gmail.com', @pw, N'Nguyễn Chí Trung', '0901234567', 'MEMBER', 'VERIFIED', @ccf, @ccb);

IF NOT EXISTS (SELECT 1 FROM Users WHERE user_email = 'ducphat02012004@gmail.com')
INSERT INTO Users (user_email, user_password_hash, user_full_name, user_phone_number, user_role, is_verified, cccd_front, cccd_back)
VALUES ('ducphat02012004@gmail.com', @pw, N'Trần Thị Bình', '0912345678', 'MEMBER', 'VERIFIED', @ccf, @ccb);

IF NOT EXISTS (SELECT 1 FROM Users WHERE user_email = 'Cuongtran.dbp.140264@gmail.com')
INSERT INTO Users (user_email, user_password_hash, user_full_name, user_phone_number, user_role, is_verified, cccd_front, cccd_back)
VALUES ('Cuongtran.dbp.140264@gmail.com', @pw, N'Lê Hoàng Cường', '0923456789', 'MEMBER', 'VERIFIED', @ccf, @ccb);

IF NOT EXISTS (SELECT 1 FROM Users WHERE user_email = 'ThoVL@gmail.com')
INSERT INTO Users (user_email, user_password_hash, user_full_name, user_phone_number, user_role, is_verified, cccd_front, cccd_back)
VALUES ('ThoVL@gmail.com', @pw, N'Phạm Minh Đức', '0934567890', 'MEMBER', 'VERIFIED', @ccf, @ccb);

IF NOT EXISTS (SELECT 1 FROM Users WHERE user_email = 'sangngao990@gmail.com')
INSERT INTO Users (user_email, user_password_hash, user_full_name, user_phone_number, user_role, is_verified, cccd_front, cccd_back)
VALUES ('sangngao990@gmail.com', @pw, N'Hoàng Thị Em', '0945678901', 'MEMBER', 'VERIFIED', @ccf, @ccb);

PRINT '-> 5 Member users created.';
GO

-- Get user IDs
DECLARE @u1 BIGINT = (SELECT user_id FROM Users WHERE user_email='nctrung.dev@gmail.com');
DECLARE @u2 BIGINT = (SELECT user_id FROM Users WHERE user_email='ducphat02012004@gmail.com');
DECLARE @u3 BIGINT = (SELECT user_id FROM Users WHERE user_email='Cuongtran.dbp.140264@gmail.com');
DECLARE @u4 BIGINT = (SELECT user_id FROM Users WHERE user_email='ThoVL@gmail.com');
DECLARE @u5 BIGINT = (SELECT user_id FROM Users WHERE user_email='sangngao990@gmail.com');

-- brand_id: 1=Giant,2=Merida,3=Pinarello,4=Specialized,5=Trek,6=Others
-- category_id: 1=Road,2=Mountain,3=Gravel,4=City,5=E-Bike,6=Others

PRINT '=== SEED 50 BICYCLE POSTS ===';

-- Posts 1-10: seller01 (Mountain Bikes)
INSERT INTO BicyclePosts (seller_id, brand_id, category_id, bicycle_name, bicycle_color, price, bicycle_description, groupset, frame_material, brake_type, size, model_year, post_status)
VALUES
(@u1, 6, 2, N'Xe Đạp Địa Hình RAPTOR Rally 1B', N'Đen', 4990000, N'Xe đạp địa hình MTB RAPTOR Rally 1B phanh đĩa, bánh 24 inch, phù hợp cho người mới bắt đầu.', 'Shimano Tourney', 'Aluminum', 'Disc', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING'),
(@u1, 6, 2, N'Xe Đạp Địa Hình RAPTOR Hunter 2B', N'Xanh lá', 5990000, N'Xe đạp địa hình MTB RAPTOR Hunter 2B phanh đĩa, bánh 26 inch, khung nhôm chắc chắn.', 'Shimano Tourney', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u1, 6, 2, N'Xe Đạp Địa Hình RAPTOR Hunter 4', N'Xanh đen', 8990000, N'Xe đạp địa hình MTB RAPTOR Hunter 4 phanh đĩa, bánh 29 inch, groupset Shimano Altus.', 'Shimano Altus', 'Aluminum', 'Disc', 'L (56 - 58) / 175 - 183 cm', 2025, 'PENDING'),
(@u1, 6, 2, N'Xe Đạp Địa Hình RAPTOR Rally 2B', N'Đỏ đen', 5490000, N'Xe đạp địa hình MTB RAPTOR Rally 2B bánh 26 inch, phanh đĩa, thiết kế mạnh mẽ.', 'Shimano Tourney', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u1, 6, 2, N'Xe Đạp Địa Hình RAPTOR Rally 3B', N'Đen trắng', 6490000, N'Xe đạp địa hình MTB RAPTOR Rally 3B bánh 27.5 inch, phanh đĩa, 21 tốc độ.', 'Shimano Tourney', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u1, 1, 2, N'Xe Đạp Địa Hình GIANT Talon 29 4', N'Cam rực', 12500000, N'Xe đạp địa hình MTB Giant Talon 29 4 chính hãng 2025, phanh đĩa, bánh 29 inches.', 'Shimano Altus', 'Aluminum', 'Disc', 'L (56 - 58) / 175 - 183 cm', 2025, 'PENDING'),
(@u1, 6, 2, N'Xe Đạp Địa Hình MEREC Honour 300', N'Đen', 7500000, N'Xe đạp địa hình MTB MEREC Honour 300, phanh đĩa, bánh 26 inches, khung nhôm.', 'Shimano Tourney', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u1, 6, 2, N'Xe Đạp Địa Hình MEREC Challenger', N'Đen đỏ', 9800000, N'Xe đạp địa hình MTB MEREC Challenger, phanh đĩa, bánh 27.5 inches, giảm xóc trước.', 'Shimano Altus', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u1, 6, 2, N'Xe Đạp Địa Hình RAPTOR Marlin 2', N'Cam xám', 7990000, N'Xe đạp địa hình MTB RAPTOR Marlin 2, phanh đĩa, bánh 27.5 inch.', 'Shimano Altus', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u1, 1, 2, N'Xe Đạp Địa Hình GIANT Talon 29 3', N'Bạc', 15900000, N'Xe đạp địa hình MTB Giant Talon 29 3 - 2025, groupset Shimano Deore, phanh đĩa thủy lực.', 'Shimano Deore', 'Aluminum', 'Disc', 'L (56 - 58) / 175 - 183 cm', 2025, 'PENDING');

-- Posts 11-20: seller02 (Mountain + Road)
INSERT INTO BicyclePosts (seller_id, brand_id, category_id, bicycle_name, bicycle_color, price, bicycle_description, groupset, frame_material, brake_type, size, model_year, post_status)
VALUES
(@u2, 1, 2, N'Xe Đạp Địa Hình GIANT Talon 3', N'Bạc xám', 13500000, N'Xe đạp địa hình MTB Giant Talon 3 - 2025, phanh đĩa, bánh 27.5 inches.', 'Shimano Deore', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u2, 6, 2, N'Xe Đạp Địa Hình RAPTOR Evo', N'Xanh dương', 11500000, N'Xe đạp địa hình MTB RAPTOR Evo, phanh đĩa, bánh 27.5 inch, giảm xóc khí.', 'Shimano Altus', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u2, 6, 2, N'Xe Đạp Địa Hình HYPER Rider 3', N'Xanh', 8500000, N'Xe đạp địa hình MTB HYPER Rider 3, phanh đĩa, bánh 27.5 inches.', 'Shimano Altus', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u2, 6, 2, N'Xe Đạp Địa Hình HYPER Rider 2', N'Vàng gold', 6990000, N'Xe đạp địa hình MTB HYPER Rider 2, khung nhôm, 21 tốc độ.', 'Shimano Tourney', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u2, 1, 2, N'Xe Đạp Địa Hình GIANT ATX 830', N'Xám mờ', 18500000, N'Xe đạp địa hình MTB Giant ATX 830 - 2025, khung ALUXX-Grade nhôm, groupset Shimano Deore.', 'Shimano Deore', 'Aluminum', 'Disc', 'L (56 - 58) / 175 - 183 cm', 2025, 'PENDING'),
(@u2, 1, 2, N'Xe Đạp Địa Hình GIANT ATX 610', N'Kem latte', 11500000, N'Xe đạp địa hình MTB Giant ATX 610 - 2025, phanh đĩa, phù hợp đô thị và đường mòn.', 'Shimano Altus', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u2, 1, 1, N'Xe Đạp Đua GIANT TCR Advanced 1 PC', N'Xanh mơ', 75000000, N'Xe đạp đua Giant TCR Advanced 1 Pro Compact 2026, full carbon, Shimano Ultegra.', 'Shimano Ultegra', 'Carbon', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2026, 'PENDING'),
(@u2, 1, 1, N'Xe Đạp Đua GIANT TCR Advanced 0 PC', N'Xanh alpine', 120000000, N'Xe đạp đua Giant TCR Advanced 0 Pro Compact 2026, full carbon, Shimano Dura-Ace.', 'Shimano Dura-Ace', 'Carbon', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2026, 'PENDING'),
(@u2, 6, 1, N'Xe Đạp Đua JAVA Veloce 16S', N'Đen', 15900000, N'Xe đạp đường trường JAVA Veloce-16S, khung nhôm, groupset Shimano Claris 16 tốc độ.', 'Shimano Claris', 'Aluminum', 'Rim', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u2, 6, 1, N'Xe Đạp Đua JAVA Wahoo 7S', N'Trắng', 9900000, N'Xe đạp đường trường JAVA Wahoo-7S, khung nhôm, 7 tốc độ, phanh caliper.', 'Shimano Tourney', 'Aluminum', 'Rim', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING');

-- Posts 21-30: seller03 (Road + City)
INSERT INTO BicyclePosts (seller_id, brand_id, category_id, bicycle_name, bicycle_color, price, bicycle_description, groupset, frame_material, brake_type, size, model_year, post_status)
VALUES
(@u3, 6, 1, N'Xe Đạp Đua JAVA Siluro 6 RX', N'Đen', 25000000, N'Xe đạp đua JAVA Siluro 6 RX, khung carbon, groupset Shimano 105 RX.', 'Shimano 105', 'Carbon', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u3, 6, 1, N'Xe Đạp Đua JAVA Siluro 6 105', N'Champagne', 22000000, N'Xe đạp đua JAVA Siluro 6 105, khung carbon, groupset Shimano 105.', 'Shimano 105', 'Carbon', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u3, 6, 1, N'Xe Đạp Đua RAPTOR Taka 1', N'Đỏ', 7990000, N'Xe đạp đua RAPTOR Taka 1, khung nhôm, groupset Shimano Claris, phanh caliper.', 'Shimano Claris', 'Aluminum', 'Rim', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u3, 1, 1, N'Xe Đạp Đua GIANT TCR Advanced 3', N'Supernova', 45000000, N'Xe đạp đua Giant TCR Advanced 3 - 2026, phanh đĩa, khung Advanced-Grade carbon.', 'Shimano 105', 'Carbon', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2026, 'PENDING'),
(@u3, 6, 4, N'Xe Đạp Đường Phố RAPTOR Napa', N'Đỏ', 6990000, N'Xe đạp đường phố touring RAPTOR Napa, phanh đĩa, bánh 700C, thiết kế thể thao.', 'Shimano Tourney', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u3, 1, 4, N'Xe Đạp Touring LIV Alight 2 Disc', N'Xanh mineral', 14500000, N'Xe đạp đường phố touring LIV Alight 2 Disc 2025, phanh đĩa, khung nhôm ALUXX.', 'Shimano Altus', 'Aluminum', 'Disc', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING'),
(@u3, 6, 4, N'Xe Đạp Đường Phố RAPTOR Eva 4', N'Xanh nhạt', 4990000, N'Xe đạp đường phố RAPTOR Eva 4, thiết kế nữ tính, nhẹ nhàng, phù hợp dạo phố.', 'Shimano Tourney', 'Aluminum', 'Rim', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING'),
(@u3, 6, 4, N'Xe Đạp Đường Phố RAPTOR Eva 3', N'Cam pastel', 4590000, N'Xe đạp đường phố RAPTOR Eva 3, phong cách vintage, phù hợp nữ.', 'Shimano Tourney', 'Aluminum', 'Rim', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING'),
(@u3, 1, 4, N'Xe Đạp Touring GIANT Fastroad AR Advanced 1', N'Trắng', 55000000, N'Xe đạp đường phố Giant Fastroad AR Advanced 1-Asia 2026, full carbon, Shimano 105 Di2.', 'Shimano 105 Di2', 'Carbon', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2026, 'PENDING'),
(@u3, 1, 4, N'Xe Đạp Touring GIANT Roam 4', N'Chrome xám', 12800000, N'Xe đạp đường phố Giant Roam 4 - 2026, khung ALUXX nhôm, phanh đĩa, đa năng.', 'Shimano Altus', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2026, 'PENDING');

-- Posts 31-40: seller04 (City + Folding)
INSERT INTO BicyclePosts (seller_id, brand_id, category_id, bicycle_name, bicycle_color, price, bicycle_description, groupset, frame_material, brake_type, size, model_year, post_status)
VALUES
(@u4, 6, 4, N'Xe Đạp Touring JAVA Sequoia 7S', N'Xám', 8900000, N'Xe đạp đường phố JAVA Sequoia-7S-City, thiết kế thanh lịch, 7 tốc độ.', 'Shimano Tourney', 'Aluminum', 'Rim', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u4, 6, 4, N'Xe Đạp Đường Phố RAPTOR Lily 4', N'Be', 4290000, N'Xe đạp đường phố RAPTOR Lily 4, thiết kế nữ tính, nhẹ nhàng, bánh 26 inch.', 'Single Speed', 'Aluminum', 'Rim', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING'),
(@u4, 6, 4, N'Xe Đạp Đường Phố RAPTOR Lily 3', N'Hồng', 3990000, N'Xe đạp đường phố RAPTOR Lily 3, phong cách vintage dành cho nữ.', 'Single Speed', 'Aluminum', 'Rim', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING'),
(@u4, 6, 4, N'Xe Đạp Touring RAPTOR Feliz 2', N'Xám', 5990000, N'Xe đạp đường phố touring RAPTOR Feliz 2, phanh đĩa, bánh 700C.', 'Shimano Tourney', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u4, 6, 4, N'Xe Đạp Touring RAPTOR City', N'Xanh lá', 6490000, N'Xe đạp đường phố touring RAPTOR City, phanh đĩa, bánh 700C, phong cách năng động.', 'Shimano Tourney', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u4, 1, 4, N'Xe Đạp Touring MOMENTUM Latte 26', N'Xanh lá chanh', 8500000, N'Xe đạp đường phố Momentum iNeed Latte 26 - 2026, bánh 26 inches, phong cách retro.', 'Shimano Tourney', 'Aluminum', 'Rim', 'S (48 - 52) / 155 - 165 cm', 2026, 'PENDING'),
(@u4, 6, 4, N'Xe Đạp Touring RAPTOR Turbo 1B', N'Trắng', 5490000, N'Xe đạp đường phố touring RAPTOR Turbo 1B, bánh 700C, thiết kế thể thao.', 'Shimano Tourney', 'Aluminum', 'Rim', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u4, 6, 4, N'Xe Đạp Touring RAPTOR Mocha 1', N'Xanh dương', 3990000, N'Xe đạp đường phố touring RAPTOR Mocha 1, phanh đĩa, bánh 24 inch, phù hợp nữ.', 'Single Speed', 'Aluminum', 'Disc', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING'),
(@u4, 6, 6, N'Xe Đạp Gấp JAVA Volta 7S', N'Trắng', 12500000, N'Xe đạp gấp JAVA Volta 7S, bánh 20 inch, 7 tốc độ, nhẹ gọn tiện lợi.', 'Shimano Tourney', 'Aluminum', 'Rim', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u4, 6, 6, N'Xe Đạp Gấp JAVA X2 16', N'Trắng', 9800000, N'Xe đạp gấp JAVA X2 16, phanh đĩa, bánh 16 inches, siêu gọn nhẹ.', 'Shimano Tourney', 'Aluminum', 'Disc', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING');

-- Posts 41-50: seller05 (Folding + Mixed)
INSERT INTO BicyclePosts (seller_id, brand_id, category_id, bicycle_name, bicycle_color, price, bicycle_description, groupset, frame_material, brake_type, size, model_year, post_status)
VALUES
(@u5, 6, 6, N'Xe Đạp Gấp JAVA Neo 9S', N'Titanium', 18500000, N'Xe đạp gấp JAVA Neo 9S, 9 tốc độ, khung hợp kim nhôm siêu nhẹ.', 'Shimano Sora', 'Aluminum', 'Rim', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u5, 6, 6, N'Xe Đạp Gấp JAVA Neo 9 SE', N'Xanh dương', 16500000, N'Xe đạp gấp JAVA Neo 9 SE, 9 tốc độ, thiết kế cao cấp, siêu nhẹ.', 'Shimano Sora', 'Aluminum', 'Rim', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u5, 6, 2, N'Xe Đạp Địa Hình RAPTOR Hunter 3', N'Đen cam', 7490000, N'Xe đạp địa hình MTB RAPTOR Hunter 3, phanh đĩa, bánh 27.5 inch.', 'Shimano Altus', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u5, 6, 1, N'Xe Đạp Đua RAPTOR Taka 2', N'Xanh đen', 9990000, N'Xe đạp đua RAPTOR Taka 2, khung nhôm, groupset Shimano Sora, phanh đĩa.', 'Shimano Sora', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u5, 6, 4, N'Xe Đạp Đường Phố RAPTOR Mocha 2', N'Hồng', 4490000, N'Xe đạp đường phố RAPTOR Mocha 2, phanh đĩa, bánh 26 inch, thiết kế nữ tính.', 'Single Speed', 'Aluminum', 'Disc', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING'),
(@u5, 6, 4, N'Xe Đạp Đường Phố RAPTOR Eva 2', N'Trắng', 4290000, N'Xe đạp đường phố RAPTOR Eva 2, thiết kế thanh lịch cho nữ, bánh 26 inch.', 'Single Speed', 'Aluminum', 'Rim', 'S (48 - 52) / 155 - 165 cm', 2025, 'PENDING'),
(@u5, 1, 2, N'Xe Đạp Địa Hình GIANT Talon 4', N'Đen xanh', 10900000, N'Xe đạp địa hình Giant Talon 4 - 2025, khung ALUXX nhôm, phanh đĩa.', 'Shimano Altus', 'Aluminum', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u5, 6, 1, N'Xe Đạp Đua JAVA Feroce R3', N'Đỏ đen', 18500000, N'Xe đạp đua JAVA Feroce R3, khung carbon, groupset Shimano Sora, phanh đĩa.', 'Shimano Sora', 'Carbon', 'Disc', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u5, 6, 4, N'Xe Đạp Touring RAPTOR Feliz 1', N'Đen', 5490000, N'Xe đạp đường phố touring RAPTOR Feliz 1, bánh 700C, phong cách năng động.', 'Shimano Tourney', 'Aluminum', 'Rim', 'M (53 - 55) / 165 - 175 cm', 2025, 'PENDING'),
(@u5, 6, 2, N'Xe Đạp Địa Hình RAPTOR Marlin 3', N'Đen đỏ', 9490000, N'Xe đạp địa hình MTB RAPTOR Marlin 3, phanh đĩa thủy lực, bánh 29 inch.', 'Shimano Altus', 'Aluminum', 'Disc', 'L (56 - 58) / 175 - 183 cm', 2025, 'PENDING');

PRINT '-> 50 Posts created.';
GO
