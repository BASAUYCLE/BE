USE BikeShopDB;
GO

PRINT '=== INSERT CLOUDINARY IMAGES ===';

IF OBJECT_ID('tempdb..#Ins6C') IS NOT NULL DROP PROCEDURE #Ins6C;
GO

CREATE PROCEDURE #Ins6C
  @name NVARCHAR(200),
  @url1 VARCHAR(500), @url2 VARCHAR(500), @url3 VARCHAR(500),
  @url4 VARCHAR(500), @url5 VARCHAR(500), @url6 VARCHAR(500)
AS
BEGIN
    DECLARE @pid BIGINT = (SELECT TOP 1 post_id FROM BicyclePosts WHERE bicycle_name = @name);
    IF @pid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM BicycleImages WHERE post_id = @pid)
    BEGIN
        INSERT INTO BicycleImages (post_id, image_url, image_type, is_thumbnail) VALUES
            (@pid, @url1, 'OVERALL_DRIVE_SIDE', 1),
            (@pid, @url2, 'OVERALL_NON_DRIVE_SIDE', 0),
            (@pid, @url3, 'COCKPIT_AREA', 0),
            (@pid, @url4, 'DRIVETRAIN_CLOSEUP', 0),
            (@pid, @url5, 'FRONT_BRAKE', 0),
            (@pid, @url6, 'REAR_BRAKE', 0);
    END
END
GO

EXEC #Ins6C N'Xe Đạp Địa Hình RAPTOR Rally 1B',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713582/bike_seed/RAPTOR_rally-1-bn-black_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714012/bike_seed/RAPTOR_rally-1-bn-black_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714013/bike_seed/RAPTOR_rally-1-bn-black_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714014/bike_seed/RAPTOR_rally-1-bn-black_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714015/bike_seed/RAPTOR_rally-1-bn-black_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714016/bike_seed/RAPTOR_rally-1-bn-black_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình RAPTOR Hunter 2B',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713586/bike_seed/RAPTOR_hunter-2-bn-red_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713587/bike_seed/RAPTOR_hunter-2-bn-red_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713588/bike_seed/RAPTOR_hunter-2-bn-red_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713589/bike_seed/RAPTOR_hunter-2-bn-red_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713590/bike_seed/RAPTOR_hunter-2-bn-red_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713591/bike_seed/RAPTOR_hunter-2-bn-red_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình RAPTOR Hunter 4',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713592/bike_seed/RAPTOR_hunter-4-n-blue_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713594/bike_seed/RAPTOR_hunter-4-n-blue_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713595/bike_seed/RAPTOR_hunter-4-n-blue_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713596/bike_seed/RAPTOR_hunter-4-n-blue_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713598/bike_seed/RAPTOR_hunter-4-n-blue_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713600/bike_seed/RAPTOR_hunter-4-n-blue_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình RAPTOR Rally 2B',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713602/bike_seed/RAPTOR_rally-2-bn-red_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714018/bike_seed/RAPTOR_rally-2-bn-red_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714019/bike_seed/RAPTOR_rally-2-bn-red_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714021/bike_seed/RAPTOR_rally-2-bn-red_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714022/bike_seed/RAPTOR_rally-2-bn-red_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714023/bike_seed/RAPTOR_rally-2-bn-red_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình RAPTOR Rally 3B',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713605/bike_seed/RAPTOR_rally-3-bn-blackwhite_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714024/bike_seed/RAPTOR_rally-3-bn-blackwhite_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714025/bike_seed/RAPTOR_rally-3-bn-blackwhite_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714027/bike_seed/RAPTOR_rally-3-bn-blackwhite_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714028/bike_seed/RAPTOR_rally-3-bn-blackwhite_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714029/bike_seed/RAPTOR_rally-3-bn-blackwhite_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình GIANT Talon 29 4',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713608/bike_seed/GIANT_2025-talon-294-radiantorange_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713610/bike_seed/GIANT_2025-talon-294-radiantorange_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713611/bike_seed/GIANT_2025-talon-294-radiantorange_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713612/bike_seed/GIANT_2025-talon-294-radiantorange_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713614/bike_seed/GIANT_2025-talon-294-radiantorange_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713615/bike_seed/GIANT_2025-talon-294-radiantorange_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình MEREC Honour 300',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713616/bike_seed/MEREC_honour-300-black_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714030/bike_seed/MEREC_honour-300-black_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714032/bike_seed/MEREC_honour-300-black_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714033/bike_seed/MEREC_honour-300-black_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714034/bike_seed/MEREC_honour-300-black_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714035/bike_seed/MEREC_honour-300-black_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình MEREC Challenger',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713619/bike_seed/MEREC_challenger-blackred_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714038/bike_seed/MEREC_challenger-blackred_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714039/bike_seed/MEREC_challenger-blackred_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714040/bike_seed/MEREC_challenger-blackred_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714041/bike_seed/MEREC_challenger-blackred_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714042/bike_seed/MEREC_challenger-blackred_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình RAPTOR Marlin 2',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713622/bike_seed/RAPTOR_marlin-2-orangegrey_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713623/bike_seed/RAPTOR_marlin-2-orangegrey_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713624/bike_seed/RAPTOR_marlin-2-orangegrey_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713625/bike_seed/RAPTOR_marlin-2-orangegrey_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713627/bike_seed/RAPTOR_marlin-2-orangegrey_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713628/bike_seed/RAPTOR_marlin-2-orangegrey_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình GIANT Talon 29 3',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713629/bike_seed/GIANT_2025-talon-293-frostsilver_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714043/bike_seed/GIANT_2025-talon-293-frostsilver_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714044/bike_seed/GIANT_2025-talon-293-frostsilver_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714045/bike_seed/GIANT_2025-talon-293-frostsilver_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714046/bike_seed/GIANT_2025-talon-293-frostsilver_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714048/bike_seed/GIANT_2025-talon-293-frostsilver_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình GIANT Talon 3',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713632/bike_seed/GIANT_2025-talon-3-frostsilver_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714049/bike_seed/GIANT_2025-talon-3-frostsilver_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714051/bike_seed/GIANT_2025-talon-3-frostsilver_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714052/bike_seed/GIANT_2025-talon-3-frostsilver_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714053/bike_seed/GIANT_2025-talon-3-frostsilver_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714054/bike_seed/GIANT_2025-talon-3-frostsilver_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình RAPTOR Evo',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713636/bike_seed/RAPTOR_evo-blue_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713637/bike_seed/RAPTOR_evo-blue_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714055/bike_seed/RAPTOR_evo-blue_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714056/bike_seed/RAPTOR_evo-blue_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714057/bike_seed/RAPTOR_evo-blue_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714058/bike_seed/RAPTOR_evo-blue_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình HYPER Rider 3',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713640/bike_seed/HYPER_rider-3-blue_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713642/bike_seed/HYPER_rider-3-blue_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714059/bike_seed/HYPER_rider-3-blue_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714061/bike_seed/HYPER_rider-3-blue_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714062/bike_seed/HYPER_rider-3-blue_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714063/bike_seed/HYPER_rider-3-blue_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình HYPER Rider 2',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713645/bike_seed/HYPER_rider-2-gold_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713645/bike_seed/HYPER_rider-2-gold_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714064/bike_seed/HYPER_rider-2-gold_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714065/bike_seed/HYPER_rider-2-gold_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714067/bike_seed/HYPER_rider-2-gold_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714068/bike_seed/HYPER_rider-2-gold_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình GIANT ATX 830',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713648/bike_seed/GIANT_2025-atx-830-mattgray_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713649/bike_seed/GIANT_2025-atx-830-mattgray_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714069/bike_seed/GIANT_2025-atx-830-mattgray_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714070/bike_seed/GIANT_2025-atx-830-mattgray_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714071/bike_seed/GIANT_2025-atx-830-mattgray_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714072/bike_seed/GIANT_2025-atx-830-mattgray_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình GIANT ATX 610',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713651/bike_seed/GIANT_2025-atx-610-latte_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713652/bike_seed/GIANT_2025-atx-610-latte_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714073/bike_seed/GIANT_2025-atx-610-latte_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714074/bike_seed/GIANT_2025-atx-610-latte_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714075/bike_seed/GIANT_2025-atx-610-latte_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714076/bike_seed/GIANT_2025-atx-610-latte_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đua GIANT TCR Advanced 1 PC',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713660/bike_seed/GIANT_2026-tcradv-1-pc-dreamyblue_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714077/bike_seed/GIANT_2026-tcradv-1-pc-dreamyblue_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714078/bike_seed/GIANT_2026-tcradv-1-pc-dreamyblue_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714079/bike_seed/GIANT_2026-tcradv-1-pc-dreamyblue_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714080/bike_seed/GIANT_2026-tcradv-1-pc-dreamyblue_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714081/bike_seed/GIANT_2026-tcradv-1-pc-dreamyblue_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đua GIANT TCR Advanced 0 PC',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713663/bike_seed/GIANT_2026-tcradv-0-pc-alpinegreen_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713664/bike_seed/GIANT_2026-tcradv-0-pc-alpinegreen_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713665/bike_seed/GIANT_2026-tcradv-0-pc-alpinegreen_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713667/bike_seed/GIANT_2026-tcradv-0-pc-alpinegreen_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714082/bike_seed/GIANT_2026-tcradv-0-pc-alpinegreen_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714084/bike_seed/GIANT_2026-tcradv-0-pc-alpinegreen_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đua JAVA Veloce 16S',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713669/bike_seed/JAVA_veloce-16-black_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713670/bike_seed/JAVA_veloce-16-black_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713671/bike_seed/JAVA_veloce-16-black_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713673/bike_seed/JAVA_veloce-16-black_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713674/bike_seed/JAVA_veloce-16-black_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713675/bike_seed/JAVA_veloce-16-black_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đua JAVA Wahoo 7S',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713677/bike_seed/JAVA_wahoo-7-white_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713678/bike_seed/JAVA_wahoo-7-white_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713679/bike_seed/JAVA_wahoo-7-white_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713680/bike_seed/JAVA_wahoo-7-white_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713682/bike_seed/JAVA_wahoo-7-white_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713683/bike_seed/JAVA_wahoo-7-white_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đua JAVA Siluro 6 RX',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713684/bike_seed/JAVA_siluro-6-rx-black_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713685/bike_seed/JAVA_siluro-6-rx-black_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713686/bike_seed/JAVA_siluro-6-rx-black_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713688/bike_seed/JAVA_siluro-6-rx-black_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713689/bike_seed/JAVA_siluro-6-rx-black_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713690/bike_seed/JAVA_siluro-6-rx-black_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đua JAVA Siluro 6 105',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713691/bike_seed/JAVA_siluro-6-105-champagne_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713692/bike_seed/JAVA_siluro-6-105-champagne_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713693/bike_seed/JAVA_siluro-6-105-champagne_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713694/bike_seed/JAVA_siluro-6-105-champagne_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713695/bike_seed/JAVA_siluro-6-105-champagne_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713697/bike_seed/JAVA_siluro-6-105-champagne_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đua RAPTOR Taka 1',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713699/bike_seed/RAPTOR_taka-1-red_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714085/bike_seed/RAPTOR_taka-1-red_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714087/bike_seed/RAPTOR_taka-1-red_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714088/bike_seed/RAPTOR_taka-1-red_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714089/bike_seed/RAPTOR_taka-1-red_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714090/bike_seed/RAPTOR_taka-1-red_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đua GIANT TCR Advanced 3',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713702/bike_seed/GIANT_2026-tcradv-3-supernova_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714091/bike_seed/GIANT_2026-tcradv-3-supernova_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714092/bike_seed/GIANT_2026-tcradv-3-supernova_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714093/bike_seed/GIANT_2026-tcradv-3-supernova_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714094/bike_seed/GIANT_2026-tcradv-3-supernova_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714095/bike_seed/GIANT_2026-tcradv-3-supernova_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đường Phố RAPTOR Napa',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713706/bike_seed/RAPTOR_raptor-napa-red_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713707/bike_seed/RAPTOR_raptor-napa-red_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714096/bike_seed/RAPTOR_raptor-napa-red_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714098/bike_seed/RAPTOR_raptor-napa-red_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714100/bike_seed/RAPTOR_raptor-napa-red_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714100/bike_seed/RAPTOR_raptor-napa-red_6.jpg';  
EXEC #Ins6C N'Xe Đạp Touring LIV Alight 2 Disc',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713710/bike_seed/GIANT_2025-alight-2-disc-mineralgreen_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713711/bike_seed/GIANT_2025-alight-2-disc-mineralgreen_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713712/bike_seed/GIANT_2025-alight-2-disc-mineralgreen_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713714/bike_seed/GIANT_2025-alight-2-disc-mineralgreen_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713715/bike_seed/GIANT_2025-alight-2-disc-mineralgreen_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713717/bike_seed/GIANT_2025-alight-2-disc-mineralgreen_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đường Phố RAPTOR Eva 4',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713718/bike_seed/RAPTOR_eva-4-lightblue_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714101/bike_seed/RAPTOR_eva-4-lightblue_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714103/bike_seed/RAPTOR_eva-4-lightblue_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714104/bike_seed/RAPTOR_eva-4-lightblue_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714105/bike_seed/RAPTOR_eva-4-lightblue_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714107/bike_seed/RAPTOR_eva-4-lightblue_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đường Phố RAPTOR Eva 3',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713721/bike_seed/RAPTOR_eva-3-pastelorange_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713722/bike_seed/RAPTOR_eva-3-pastelorange_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713723/bike_seed/RAPTOR_eva-3-pastelorange_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713725/bike_seed/RAPTOR_eva-3-pastelorange_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713726/bike_seed/RAPTOR_eva-3-pastelorange_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713727/bike_seed/RAPTOR_eva-3-pastelorange_6.jpg';  
EXEC #Ins6C N'Xe Đạp Touring GIANT Fastroad AR Advanced 1',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713729/bike_seed/GIANT_2026-fastroadadvar-1-a-white_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713730/bike_seed/GIANT_2026-fastroadadvar-1-a-white_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713731/bike_seed/GIANT_2026-fastroadadvar-1-a-white_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713732/bike_seed/GIANT_2026-fastroadadvar-1-a-white_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713733/bike_seed/GIANT_2026-fastroadadvar-1-a-white_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713734/bike_seed/GIANT_2026-fastroadadvar-1-a-white_6.jpg';  
EXEC #Ins6C N'Xe Đạp Touring GIANT Roam 4',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713736/bike_seed/GIANT_2026-roam-4-stealthchrome_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713737/bike_seed/GIANT_2026-roam-4-stealthchrome_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713739/bike_seed/GIANT_2026-roam-4-stealthchrome_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713740/bike_seed/GIANT_2026-roam-4-stealthchrome_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713741/bike_seed/GIANT_2026-roam-4-stealthchrome_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713743/bike_seed/GIANT_2026-roam-4-stealthchrome_6.jpg';  
EXEC #Ins6C N'Xe Đạp Touring JAVA Sequoia 7S',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713744/bike_seed/JAVA_sequoia-7-grey_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713746/bike_seed/JAVA_sequoia-7-grey_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713748/bike_seed/JAVA_sequoia-7-grey_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713749/bike_seed/JAVA_sequoia-7-grey_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713751/bike_seed/JAVA_sequoia-7-grey_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713753/bike_seed/JAVA_sequoia-7-grey_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đường Phố RAPTOR Lily 4',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713754/bike_seed/RAPTOR_lily-4-beige_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714108/bike_seed/RAPTOR_lily-4-beige_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714110/bike_seed/RAPTOR_lily-4-beige_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714111/bike_seed/RAPTOR_lily-4-beige_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714112/bike_seed/RAPTOR_lily-4-beige_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714113/bike_seed/RAPTOR_lily-4-beige_6.jpg';  
EXEC #Ins6C N'Xe Đạp Đường Phố RAPTOR Lily 3',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713757/bike_seed/RAPTOR_lily-3-pink_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713759/bike_seed/RAPTOR_lily-3-pink_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713760/bike_seed/RAPTOR_lily-3-pink_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713761/bike_seed/RAPTOR_lily-3-pink_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713762/bike_seed/RAPTOR_lily-3-pink_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713763/bike_seed/RAPTOR_lily-3-pink_6.jpg';  
EXEC #Ins6C N'Xe Đạp Touring RAPTOR Feliz 2',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713765/bike_seed/RAPTOR_feliz-2-b-grey_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714115/bike_seed/RAPTOR_feliz-2-b-grey_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714116/bike_seed/RAPTOR_feliz-2-b-grey_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714118/bike_seed/RAPTOR_feliz-2-b-grey_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714120/bike_seed/RAPTOR_feliz-2-b-grey_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714121/bike_seed/RAPTOR_feliz-2-b-grey_6.jpg';  
EXEC #Ins6C N'Xe Đạp Touring RAPTOR City',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713768/bike_seed/RAPTOR_city-green_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713770/bike_seed/RAPTOR_city-green_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713771/bike_seed/RAPTOR_city-green_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713772/bike_seed/RAPTOR_city-green_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713773/bike_seed/RAPTOR_city-green_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713774/bike_seed/RAPTOR_city-green_6.jpg';  
EXEC #Ins6C N'Xe Đạp Touring MOMENTUM Latte 26',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713776/bike_seed/GIANT_2025-latte-26-limegreen_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713777/bike_seed/GIANT_2025-latte-26-limegreen_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713778/bike_seed/GIANT_2025-latte-26-limegreen_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713780/bike_seed/GIANT_2025-latte-26-limegreen_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713781/bike_seed/GIANT_2025-latte-26-limegreen_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713782/bike_seed/GIANT_2025-latte-26-limegreen_6.jpg';  
EXEC #Ins6C N'Xe Đạp Touring RAPTOR Turbo 1B',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713785/bike_seed/RAPTOR_turbo-1-b-white_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714122/bike_seed/RAPTOR_turbo-1-b-white_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714123/bike_seed/RAPTOR_turbo-1-b-white_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714124/bike_seed/RAPTOR_turbo-1-b-white_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714125/bike_seed/RAPTOR_turbo-1-b-white_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714128/bike_seed/RAPTOR_turbo-1-b-white_6.jpg';  
EXEC #Ins6C N'Xe Đạp Touring RAPTOR Mocha 1',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713787/bike_seed/RAPTOR_mocha-1-blue_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713788/bike_seed/RAPTOR_mocha-1-blue_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713789/bike_seed/RAPTOR_mocha-1-blue_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713791/bike_seed/RAPTOR_mocha-1-blue_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713792/bike_seed/RAPTOR_mocha-1-blue_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713793/bike_seed/RAPTOR_mocha-1-blue_6.jpg';  
EXEC #Ins6C N'Xe Đạp Gấp JAVA Volta 7S',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713795/bike_seed/JAVA_volta-white_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714129/bike_seed/JAVA_volta-white_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714130/bike_seed/JAVA_volta-white_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714131/bike_seed/JAVA_volta-white_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714132/bike_seed/JAVA_volta-white_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714133/bike_seed/JAVA_volta-white_6.jpg';  
EXEC #Ins6C N'Xe Đạp Gấp JAVA X2 16',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713797/bike_seed/JAVA_x-216-white_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714135/bike_seed/JAVA_x-216-white_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714136/bike_seed/JAVA_x-216-white_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714137/bike_seed/JAVA_x-216-white_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714138/bike_seed/JAVA_x-216-white_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714139/bike_seed/JAVA_x-216-white_6.jpg';  
EXEC #Ins6C N'Xe Đạp Gấp JAVA Neo 9S',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713801/bike_seed/JAVA_neo-9-s-titanium_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713802/bike_seed/JAVA_neo-9-s-titanium_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713803/bike_seed/JAVA_neo-9-s-titanium_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713804/bike_seed/JAVA_neo-9-s-titanium_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713805/bike_seed/JAVA_neo-9-s-titanium_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713807/bike_seed/JAVA_neo-9-s-titanium_6.jpg';  
EXEC #Ins6C N'Xe Đạp Gấp JAVA Neo 9 SE',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713808/bike_seed/JAVA_neo-9-se-blue_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713811/bike_seed/JAVA_neo-9-se-blue_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713812/bike_seed/JAVA_neo-9-se-blue_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713813/bike_seed/JAVA_neo-9-se-blue_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713814/bike_seed/JAVA_neo-9-se-blue_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713817/bike_seed/JAVA_neo-9-se-blue_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình RAPTOR Hunter 3',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING';  
EXEC #Ins6C N'Xe Đạp Đua RAPTOR Taka 2',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING';  
EXEC #Ins6C N'Xe Đạp Đường Phố RAPTOR Mocha 2',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING';  
EXEC #Ins6C N'Xe Đạp Đường Phố RAPTOR Eva 2',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING';  
EXEC #Ins6C N'Xe Đạp Địa Hình GIANT Talon 4',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING';  
EXEC #Ins6C N'Xe Đạp Đua JAVA Feroce R3',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING',
  'MISSING';  
EXEC #Ins6C N'Xe Đạp Touring RAPTOR Feliz 1',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713832/bike_seed/RAPTOR_feliz-1-black_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714154/bike_seed/RAPTOR_feliz-1-black_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714155/bike_seed/RAPTOR_feliz-1-black_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714156/bike_seed/RAPTOR_feliz-1-black_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714158/bike_seed/RAPTOR_feliz-1-black_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772714159/bike_seed/RAPTOR_feliz-1-black_6.jpg';  
EXEC #Ins6C N'Xe Đạp Địa Hình RAPTOR Marlin 3',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713835/bike_seed/RAPTOR_marlin-3-blackred_1.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713837/bike_seed/RAPTOR_marlin-3-blackred_2.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713838/bike_seed/RAPTOR_marlin-3-blackred_3.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713839/bike_seed/RAPTOR_marlin-3-blackred_4.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713841/bike_seed/RAPTOR_marlin-3-blackred_5.jpg',
  'https://res.cloudinary.com/dod2rhslh/image/upload/v1772713842/bike_seed/RAPTOR_marlin-3-blackred_6.jpg';  

DROP PROCEDURE #Ins6C;
PRINT '-> 300 Images ALL on Cloudinary.';
PRINT '=== COMPLETE ===';
GO
