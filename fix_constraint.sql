USE BikeShopDB;
GO

DECLARE @ConstraintName nvarchar(200)
SELECT @ConstraintName = Name 
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('BicyclePosts')
AND definition LIKE '%post_status%';

IF @ConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE BicyclePosts DROP CONSTRAINT ' + @ConstraintName)
    PRINT 'Dropped constraint: ' + @ConstraintName
END
ELSE
BEGIN
    PRINT 'No constraint found on post_status'
END
GO

ALTER TABLE BicyclePosts
ADD CONSTRAINT CK_BicyclePosts_Status 
CHECK (post_status IN ('PENDING', 'ADMIN_APPROVED', 'AVAILABLE', 
                       'DEPOSITED', 'SOLD', 'REJECTED', 'DRAFTED', 'HIDDEN'));
PRINT 'Added new constraint CK_BicyclePosts_Status';
GO
