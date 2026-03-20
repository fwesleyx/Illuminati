-- =====================================================================================
-- Script Name: UDA Validation Test Suite
-- Purpose: Validates User Defined Attributes (UDA) and their associations with item types
-- Author: [Francis]
-- Date: [05-01-2026]
-- Description: This script performs three validation tests:
--              1. Attribute name and description validation
--              2. Attribute-to-item-type association validation  
--              3. Extended rigid container attribute validation
-- =====================================================================================
USE speed_2max;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET NOCOUNT ON;
GO

BEGIN
BEGIN TRY
    DECLARE @ClassDivision INT = 10
    -- =====================================================================================
    -- CLEANUP: Drop temporary tables if they exist from previous runs
    -- =====================================================================================
    DROP TABLE IF EXISTS #Updated;
    DROP TABLE IF EXISTS #Inserted;
    DROP TABLE IF EXISTS #Deleted;
     -- Create temporary table for Test 1
    CREATE TABLE #Updated (
        att_idn                 int,            -- Attribute ID from uda_definition
        item_typ_cde           VARCHAR(10),    -- Item type code
        expected_itm_class     VARCHAR(70),    -- Expected item class name
        itm_class              VARCHAR(70),    -- Actual item class name
        expected_att_nme       VARCHAR(70),    -- Expected attribute name
        att_nme                VARCHAR(70),    -- Actual attribute name
        expected_att_dsc       VARCHAR(70),    -- Expected attribute description
        att_dsc                VARCHAR(50),    -- Actual attribute description
        result                 VARCHAR(70),    -- Test result message
        assert                 CHAR(4) DEFAULT 'FAIL',  -- Test status (PASS/FAIL)
        mode                   VARCHAR(70) DEFAULT 'TO BE UPDATED'    -- Mode
    );
        -- Create temporary table for Test 2
    CREATE TABLE #Inserted (
        att_idn                 int,            -- Attribute ID from uda_definition
        item_typ_cde           VARCHAR(10),    -- Item type code
        expected_itm_class     VARCHAR(70),    -- Expected item class name
        itm_class              VARCHAR(70),    -- Actual item class name
        expected_att_nme       VARCHAR(70),    -- Expected attribute name
        att_nme                VARCHAR(70),    -- Actual attribute name
        expected_att_dsc       VARCHAR(70),    -- Expected attribute description
        att_dsc                VARCHAR(50),    -- Actual attribute description
        result                 VARCHAR(70),    -- Test result message
        assert                 CHAR(4) DEFAULT 'FAIL',  -- Test status (PASS/FAIL)
        mode                   VARCHAR(70) DEFAULT 'TO BE INSERTED'    -- Mode
    );
        -- Create temporary table for Test 3
    CREATE TABLE #Deleted (
        att_idn                 int,            -- Attribute ID from uda_definition
        item_typ_cde           VARCHAR(10),    -- Item type code
        expected_itm_class     VARCHAR(70),    -- Expected item class name
        itm_class              VARCHAR(70),    -- Actual item class name
        expected_att_nme       VARCHAR(70),    -- Expected attribute name
        att_nme                VARCHAR(70),    -- Actual attribute name
        expected_att_dsc       VARCHAR(70),    -- Expected attribute description
        att_dsc                VARCHAR(50),    -- Actual attribute description
        result                 VARCHAR(70),    -- Test result message
        assert                 CHAR(4) DEFAULT 'FAIL',  -- Test status (PASS/FAIL)
        mode                   VARCHAR(70) DEFAULT 'TO BE DELETED'    -- Mode
    );
    -- =====================================================================================
    -- TEST 1: ATTRIBUTE NAME AND DESCRIPTION VALIDATION
    -- Purpose: Validates that specific attributes exist with correct names and descriptions
    -- Focus: Packaging-related attributes for folding cartons and rigid containers
    -- =====================================================================================
    
   
    -- Insert test data: Expected attribute name and description pairs
    INSERT INTO #Updated (itm_class, att_nme,expected_att_nme,expected_att_dsc)
    SELECT [Speed Item Class],[Speed Characteristic Name],[Speed Characteristic Name],[Speed Characteristic Description] 
    FROM workdb..char_analysis_report 
    WHERE [Class Division] = @ClassDivision
    AND [Add To Class]='N' 
    AND [New Characteristic]='N' 
    AND [Update Characteristic Description] = 'Y'
    AND [Remove From Class]='N'
    -- Step 1: Populate actual attribute data from uda_definition table
    UPDATE tgt
    SET tgt.att_idn = src.att_idn,      -- Get attribute ID
        tgt.att_nme = src.att_nme,      -- Get actual attribute name
        tgt.att_dsc = src.att_dsc       -- Get actual attribute description
    FROM #Updated tgt
    LEFT JOIN dbo.uda_definition src 
    ON src.att_nme = tgt.expected_att_nme;

    -- Step 2: Get item type code from uda_item_type table
    UPDATE tgt
    SET tgt.item_typ_cde = ui.item_typ_cde
    FROM #Updated tgt
    LEFT JOIN uda_item_type ui 
    ON ui.att_idn = tgt.att_idn;

    -- Step 3: Get actual item class description from item_type table
    UPDATE tgt
    SET tgt.itm_class = ui.item_typ_dsc
    FROM #Updated tgt
    LEFT JOIN item_type ui 
    ON ui.item_typ_cde = tgt.item_typ_cde;

    -- Step 4: Mark records as PASS when attribute exists and matches expected name
    UPDATE tgt
    SET tgt.assert = 'PASS',
        tgt.result = 'Update:Match Found'
    FROM #Updated tgt
    JOIN dbo.uda_definition src 
    ON src.att_nme = tgt.expected_att_nme
    AND src.att_idn = tgt.att_idn;

    -- Step 5: Mark records as FAIL when attribute doesn't match or doesn't exist
    --UPDATE tgt
    --SET tgt.assert = 'FAIL',
    --    tgt.result = 'Update:Match not Found'
    --FROM #Updated tgt
    --JOIN dbo.uda_definition src 
    --ON src.att_nme <> tgt.expected_att_nme
    --AND tgt.att_idn IS NULL;

    UPDATE tgt
    SET tgt.assert = 'FAIL',
        tgt.result = 'Update:Match not Found'
    FROM #Updated tgt
     INNER JOIN dbo.uda_item_type uit  ON uit.item_typ_cde = tgt.item_typ_cde AND uit.att_idn=tgt.att_idn
    JOIN item_type t ON t.item_typ_cde = uit.item_typ_cde 
    JOIN uda_definition d ON d.att_idn = uit.att_idn AND d.att_nme <> tgt.expected_att_nme
    WHERE 
    table_nme = 'item';
   
    -- =====================================================================================
    -- TEST 2: ATTRIBUTE-TO-ITEM-TYPE ASSOCIATION VALIDATION
    -- Purpose: Validates that specific attributes are properly associated with item types
    -- Focus: Diverse item classes and their required attributes
    -- =====================================================================================
    

    -- Insert test data: Item class and attribute name combinations to validate
    INSERT INTO #Inserted (itm_class, att_nme,expected_att_nme,expected_att_dsc)

    SELECT [Speed Item Class],[Speed Characteristic Name],[Speed Characteristic Name],[S4 Characteristic Description]
    FROM workdb..char_analysis_report 
    WHERE [Class Division] = @ClassDivision
    AND [Add To Class]='Y' 
    AND [New Characteristic]='Y' 
    AND [Update Characteristic Description] = 'N'
    AND [Remove From Class]='N';

    -- Step 1: Get attribute ID for each attribute name
    UPDATE tgt
    SET tgt.att_idn = ud.att_idn,tgt.att_dsc = ud.att_dsc
    FROM #Inserted tgt
    LEFT JOIN dbo.uda_definition ud 
    ON ud.att_nme = tgt.att_nme;

    -- Step 2: Get item type code from item class description
    UPDATE tgt
    SET tgt.item_typ_cde = ui.item_typ_cde
    FROM #Inserted tgt
    LEFT JOIN item_type ui 
    ON ui.item_typ_dsc = tgt.itm_class;

    -- Step 3: Initialize all records as FAIL by default
    UPDATE #Inserted 
    SET assert = 'FAIL', 
        result = 'Insert:Match not Found';

    -- Step 4: Mark as PASS only when the attribute-item type combination exists

        UPDATE tgt
    SET tgt.assert = 'PASS', 
        tgt.result = 'Insert:Match Found'
    FROM #Inserted tgt
    INNER JOIN dbo.uda_item_type uit  ON uit.item_typ_cde = tgt.item_typ_cde
    JOIN item_type t ON t.item_typ_cde = uit.item_typ_cde 
    JOIN uda_definition d ON d.att_idn = uit.att_idn
    WHERE 
    table_nme = 'item';

    -- =====================================================================================
    -- TEST 3: EXTENDED RIGID CONTAINER ATTRIBUTE VALIDATION
    -- Purpose: Validates extended attributes specifically for rigid containers
    -- Focus: Additional rigid container attributes including printing and art specifications
    -- =====================================================================================
    


    -- Insert test data: Extended rigid container attributes to validate
    INSERT INTO #Deleted (itm_class, att_nme, expected_att_nme,expected_att_dsc)          
    SELECT [Speed Item Class],[Speed Characteristic Name],[Speed Characteristic Name],[Speed Characteristic Description] 
    FROM workdb..char_analysis_report 
    WHERE [Class Division] = @ClassDivision
    AND [Add To Class]='N' 
    AND [New Characteristic]='N' 
    AND [Update Characteristic Description] = 'N'
    AND [Remove From Class]='Y'

    -- Step 1: Get attribute ID for each attribute name
    UPDATE tgt
    SET tgt.att_idn = ud.att_idn
    FROM #Deleted tgt
    LEFT JOIN dbo.uda_definition ud 
    ON ud.att_nme = tgt.att_nme;

    -- Step 2: Get item type code from item class description
    UPDATE tgt
    SET tgt.item_typ_cde = ui.item_typ_cde
    FROM #Deleted tgt
    LEFT JOIN item_type ui 
    ON ui.item_typ_dsc = tgt.itm_class;

    -- Step 3: Initialize all records as FAIL by default
    UPDATE #Deleted 
    SET assert = 'FAIL', 
        result = 'Delete:Match not Found';

    -- Step 4: Mark as PASS only when the attribute-item type combination exists
       UPDATE tgt
    SET tgt.assert = 'PASS', 
        tgt.result = 'Delete:Match Found'
    FROM #Deleted tgt
    INNER JOIN dbo.uda_item_type uit  ON uit.item_typ_cde = tgt.item_typ_cde
    JOIN item_type t ON t.item_typ_cde = uit.item_typ_cde 
    JOIN uda_definition d ON d.att_idn = uit.att_idn
    WHERE 
    table_nme = 'item';
    -- =====================================================================================
    -- RESULTS: Display validation results for all three tests
    -- =====================================================================================
    
    -- Test 1 Results: Attribute name and description validation
    SELECT 
        att_idn,                -- Attribute ID
        item_typ_cde,          -- Item type code
        itm_class,             -- Item class name
        expected_att_nme,      -- Expected attribute name
        att_nme,               -- Actual attribute name
        expected_att_dsc,      -- Expected attribute description
        att_dsc,               -- Actual attribute description
        assert,                -- Test result (PASS/FAIL)
        result                 -- Result message        
    FROM #Updated
    WHERE assert='FAIL';

    -- Test 2 Results: Attribute-to-item-type association validation
    SELECT 
        att_idn,                -- Attribute ID
        item_typ_cde,          -- Item type code
        itm_class,             -- Item class name
        expected_att_nme,      -- Expected attribute name
        att_nme,               -- Actual attribute name
        expected_att_dsc,      -- Expected attribute description
        att_dsc,               -- Actual attribute description
        assert,                -- Test result (PASS/FAIL)
        result                 -- Result message        
    FROM #Inserted
    WHERE assert='FAIL';

    -- Test 3 Results: Extended rigid container attribute validation
    SELECT 
        att_idn,                -- Attribute ID
        item_typ_cde,          -- Item type code
        itm_class,             -- Item class name
        expected_att_nme,      -- Expected attribute name
        att_nme,               -- Actual attribute name
        expected_att_dsc,      -- Expected attribute description
        att_dsc,               -- Actual attribute description
        assert,                -- Test result (PASS/FAIL)
        result                 -- Result message        
    FROM #Deleted
    WHERE assert='FAIL';

END TRY
BEGIN CATCH
    -- =====================================================================================
    -- ERROR HANDLING: Display error information if any step fails
    -- =====================================================================================
    PRINT 'Error occurred during execution.';
    PRINT 'Message     : ' + ERROR_MESSAGE();
    PRINT 'Line        : ' + CAST(ERROR_LINE() AS VARCHAR);
        
END CATCH
END
