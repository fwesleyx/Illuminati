-- =====================================================
-- Characteristic Analysis Report for Division Management
-- Purpose: Identify data discrepancies between Speed and S4 systems
-- =====================================================

DECLARE @DivisionID INT = 20;

-- Validate Division ID
IF @DivisionID IS NULL
BEGIN
    RAISERROR('Division ID cannot be NULL', 16, 1);
    RETURN;
END;

-- =====================================================
-- 1. ITEMS MARKED FOR DELETION (Still Exist)
-- =====================================================
WITH ItemsToDelete AS (
    SELECT DISTINCT 
        uda.att_nme AS CharacteristicName,
        uda.att_idn AS CharacteristicID,
        rep.[Speed Item Class] AS ItemClass,
        rep.[Class Division] AS Division,
        rep.[Remove From Class] AS RemoveFlag,
        'DELETION_REQUIRED' AS ActionType,
        'Item exists but marked for removal' AS Description
    FROM workdb..char_analysis_report rep
        INNER JOIN uda_definition uda ON uda.att_nme = rep.[Speed Characteristic Name]
        INNER JOIN uda_item_type uit ON uit.att_idn = uda.att_idn
        INNER JOIN item_type it ON it.item_typ_cde = uit.item_typ_cde 
                                AND it.item_typ_dsc = rep.[Speed Item Class]
    WHERE rep.[Class Division] = @DivisionID
        AND rep.[Remove From Class] = 'Y'
)
SELECT * FROM ItemsToDelete;

-- =====================================================
-- 2. ITEMS REQUIRING DESCRIPTION UPDATES
-- =====================================================
WITH DescriptionUpdates AS (
    SELECT DISTINCT 
        uda.att_nme AS CharacteristicName,
        rep.[S4 Characteristic Description] AS S4Description,
        rep.[Speed Characteristic Description] AS SpeedDescription,
        uda.att_dsc AS CurrentDescription,
        rep.[Class Division] AS Division,
        rep.[Update Characteristic Description] AS UpdateFlag,
        'DESCRIPTION_UPDATE' AS ActionType,
        'Description mismatch - update required' AS Description
    FROM workdb..char_analysis_report rep
        INNER JOIN uda_definition uda ON uda.att_nme = rep.[Speed Characteristic Name]
        INNER JOIN uda_item_type uit ON uit.att_idn = uda.att_idn
        INNER JOIN item_type it ON it.item_typ_cde = uit.item_typ_cde 
                                AND it.item_typ_dsc = rep.[Speed Item Class]
    WHERE rep.[Class Division] = @DivisionID
        AND rep.[Update Characteristic Description] = 'Y'
        AND ISNULL(rep.[S4 Characteristic Description], '') != ISNULL(uda.att_dsc, '')
)
SELECT * FROM DescriptionUpdates;

-- =====================================================
-- 3. MISSING CHARACTERISTICS (Combined Insert Cases)
-- =====================================================
WITH MissingCharacteristics AS (
    -- New Characteristics
    SELECT DISTINCT 
        rep.[S4 Characteristic Name] AS CharacteristicName,
        rep.[Speed Item Class] AS ItemClass,
        rep.[Class Division] AS Division,
        rep.[S4 Characteristic Description] AS Description,
        rep.[S4 Data Type] AS DataType,
        rep.[S4 Number Of Character] AS MaxLength,
        rep.[New Characteristic] AS NewCharFlag,
        rep.[Add To Class] AS AddToClassFlag,
        'NEW_CHARACTERISTIC' AS ActionType,
        'New characteristic needs to be created' AS ActionDescription
    FROM workdb..char_analysis_report rep
    WHERE rep.[Class Division] = @DivisionID
        AND rep.[New Characteristic] = 'Y'
        AND rep.[S4 Characteristic Name] IS NOT NULL
        AND rep.[S4 Characteristic Name] NOT IN (
            SELECT att_nme FROM uda_definition WHERE att_nme IS NOT NULL
        )
    
    UNION ALL
    
    -- Add to Class
    SELECT DISTINCT 
        rep.[S4 Characteristic Name] AS CharacteristicName,
        rep.[Speed Item Class] AS ItemClass,
        rep.[Class Division] AS Division,
        rep.[S4 Characteristic Description] AS Description,
        rep.[S4 Data Type] AS DataType,
        rep.[S4 Number Of Character] AS MaxLength,
        rep.[New Characteristic] AS NewCharFlag,
        rep.[Add To Class] AS AddToClassFlag,
        'ADD_TO_CLASS' AS ActionType,
        'Characteristic needs to be added to class' AS ActionDescription
    FROM workdb..char_analysis_report rep
    WHERE rep.[Class Division] = @DivisionID
        AND rep.[Add To Class] = 'Y'
        AND rep.[New Characteristic] != 'Y'  -- Avoid duplicates with above query
        AND rep.[S4 Characteristic Name] IS NOT NULL
        AND rep.[S4 Characteristic Name] NOT IN (
            SELECT att_nme FROM uda_definition WHERE att_nme IS NOT NULL
        )
)
SELECT * FROM MissingCharacteristics;

-- =====================================================
-- 4. COMPREHENSIVE SUMMARY REPORT
-- =====================================================
WITH SummaryStats AS (
    SELECT 
        @DivisionID AS Division,
        COUNT(CASE WHEN rep.[Remove From Class] = 'Y' THEN 1 END) AS ItemsToDelete,
        COUNT(CASE WHEN rep.[Update Characteristic Description] = 'Y' 
                   AND rep.[S4 Characteristic Description] != uda.att_dsc THEN 1 END) AS DescriptionUpdates,
        COUNT(CASE WHEN rep.[New Characteristic] = 'Y' 
                   AND rep.[S4 Characteristic Name] NOT IN (
                       SELECT att_nme FROM uda_definition WHERE att_nme IS NOT NULL
                   ) THEN 1 END) AS NewCharacteristics,
        COUNT(CASE WHEN rep.[Add To Class] = 'Y' 
                   AND rep.[New Characteristic] != 'Y'
                   AND rep.[S4 Characteristic Name] NOT IN (
                       SELECT att_nme FROM uda_definition WHERE att_nme IS NOT NULL
                   ) THEN 1 END) AS AddToClass,
        COUNT(*) AS TotalRecords
    FROM workdb..char_analysis_report rep
        LEFT JOIN uda_definition uda ON uda.att_nme = rep.[Speed Characteristic Name]
    WHERE rep.[Class Division] = @DivisionID
)
SELECT 
    Division,
    ItemsToDelete,
    DescriptionUpdates,
    NewCharacteristics,
    AddToClass,
    TotalRecords,
    (ItemsToDelete + DescriptionUpdates + NewCharacteristics + AddToClass) AS TotalActionsRequired
FROM SummaryStats;

-- =====================================================
-- 5. DATA QUALITY CHECKS
-- =====================================================
SELECT 
    'Data Quality Issues' AS ReportType,
    COUNT(CASE WHEN rep.[S4 Characteristic Name] IS NULL 
               AND rep.[Speed Characteristic Name] IS NULL THEN 1 END) AS BothNamesNull,
    COUNT(CASE WHEN rep.[Speed Item Class] != rep.[S4 Item Class] THEN 1 END) AS ItemClassMismatch,
    COUNT(CASE WHEN rep.[New Characteristic] = 'Y' 
               AND rep.[Remove From Class] = 'Y' THEN 1 END) AS ConflictingFlags,
    COUNT(CASE WHEN rep.[S4 Data Type] IS NULL 
               AND rep.[New Characteristic] = 'Y' THEN 1 END) AS MissingDataType
FROM workdb..char_analysis_report rep
WHERE rep.[Class Division] = @DivisionID;

-- =====================================================
-- 6. EXECUTION SUMMARY
-- =====================================================
PRINT '========================================';
PRINT 'Characteristic Analysis Complete';
PRINT 'Division ID: ' + CAST(@DivisionID AS VARCHAR(10));
PRINT 'Execution Time: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
PRINT '========================================';