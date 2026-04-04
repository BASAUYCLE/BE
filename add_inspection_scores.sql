USE BikeShopDB;
GO

-- Thêm 6 cột điểm chấm kiểm định + phần trăm tình trạng vào bảng InspectionReports
ALTER TABLE InspectionReports ADD color_score INT NOT NULL DEFAULT 0;
ALTER TABLE InspectionReports ADD frame_score INT NOT NULL DEFAULT 0;
ALTER TABLE InspectionReports ADD groupset_score INT NOT NULL DEFAULT 0;
ALTER TABLE InspectionReports ADD brake_score INT NOT NULL DEFAULT 0;
ALTER TABLE InspectionReports ADD control_score INT NOT NULL DEFAULT 0;
ALTER TABLE InspectionReports ADD wheel_score INT NOT NULL DEFAULT 0;
ALTER TABLE InspectionReports ADD condition_percent FLOAT NOT NULL DEFAULT 0;

PRINT 'Added 6 score columns + condition_percent to InspectionReports.';
GO
