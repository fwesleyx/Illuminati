-- =====================================================================================
-- Script Name: UDA Validation Test Suite
-- Purpose: Validates User Defined Attributes (UDA) and their associations with item types
-- Author: [Francis]
-- Date: [26-11-2025]
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
        assert                 CHAR(4) DEFAULT 'FAIL'  -- Test status (PASS/FAIL)
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
        assert                 CHAR(4) DEFAULT 'FAIL'  -- Test status (PASS/FAIL)
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
        assert                 CHAR(4) DEFAULT 'FAIL'  -- Test status (PASS/FAIL)
    );
    -- =====================================================================================
    -- TEST 1: ATTRIBUTE NAME AND DESCRIPTION VALIDATION
    -- Purpose: Validates that specific attributes exist with correct names and descriptions
    -- Focus: Packaging-related attributes for folding cartons and rigid containers
    -- =====================================================================================
    
   
    -- Insert test data: Expected attribute name and description pairs
    INSERT INTO #Updated (itm_class, att_nme,expected_att_nme,expected_att_dsc)
     SELECT 'BAGS','BAG_PRINTED_PLAIN','BAG_PRINTED_PLAIN','Bag Printed/Plain'
UNION SELECT 'BAGS','BAG_MATERIAL_ATTRIBUTES','BAG_MATERIAL_ATTRIBUTES','Bag Material Attributes'


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

    -- Alternative approach (commented out): Direct lookup by attribute name and description
    --UPDATE tgt
    --SET tgt.itm_class = ui.item_typ_dsc
    --FROM #Updated tgt
    --LEFT JOIN uda_item_type ui 
    --ON ui.att_nme = tgt.expected_att_nme AND ui.att_dsc = tgt.att_dsc

    -- Step 4: Mark records as PASS when attribute exists and matches expected name
    UPDATE tgt
    SET tgt.assert = 'PASS',
        tgt.result = 'Match Found'
    FROM #Updated tgt
    JOIN dbo.uda_definition src 
    ON src.att_nme = tgt.expected_att_nme
    AND src.att_idn = tgt.att_idn;

    -- Step 5: Mark records as FAIL when attribute doesn't match or doesn't exist
    UPDATE tgt
    SET tgt.assert = 'FAIL',
        tgt.result = 'Match not Found'
    FROM #Updated tgt
    JOIN dbo.uda_definition src 
    ON src.att_nme <> tgt.expected_att_nme
    AND tgt.att_idn IS NULL;

    -- =====================================================================================
    -- TEST 2: ATTRIBUTE-TO-ITEM-TYPE ASSOCIATION VALIDATION
    -- Purpose: Validates that specific attributes are properly associated with item types
    -- Focus: Diverse item classes and their required attributes
    -- =====================================================================================
    

    -- Insert test data: Item class and attribute name combinations to validate
    INSERT INTO #Inserted (itm_class, att_nme,expected_att_nme,expected_att_dsc)
      SELECT 'FOLDING_CARTON','PRODUCT_LEVEL_ID_CU','PRODUCT_LEVEL_ID_CU','PRODUCT LEVEL IDENTIFICATION CONSUMER UNIT'
UNION SELECT 'RIGID_CNTR','PRODUCT_LEVEL_ID_CU','PRODUCT_LEVEL_ID_CU','PRODUCT LEVEL IDENTIFICATION CU'
UNION SELECT 'RIGID_CNTR','RIGID_CNTR_DEPTH_EXTRNL','RIGID_CNTR_DEPTH_EXTRNL','Rigid Container Depth External'
UNION SELECT 'RIGID_CNTR','RIGID_CNTR_LENGTH_EXTRNL','RIGID_CNTR_LENGTH_EXTRNL','Rigid Container Length External'
UNION SELECT 'RIGID_CNTR','RIGID_CNTR_WIDTH_EXTRNL','RIGID_CNTR_WIDTH_EXTRNL','Rigid Container Width External'
UNION SELECT 'RIGID_CNTR','RIGID_CONTAINER_MATERIAL','RIGID_CONTAINER_MATERIAL','Rigid Container Material';


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
        result = 'Match not Found';

    -- Step 4: Mark as PASS only when the attribute-item type combination exists
    UPDATE tgt
    SET tgt.assert = 'PASS', 
        tgt.result = 'Match Found'
    FROM #Inserted tgt
    INNER JOIN dbo.uda_item_type uit 
    ON uit.att_idn = tgt.att_idn 
       AND uit.item_typ_cde = tgt.item_typ_cde;

   
    -- =====================================================================================
    -- TEST 3: EXTENDED RIGID CONTAINER ATTRIBUTE VALIDATION
    -- Purpose: Validates extended attributes specifically for rigid containers
    -- Focus: Additional rigid container attributes including printing and art specifications
    -- =====================================================================================
    


    -- Insert test data: Extended rigid container attributes to validate
    INSERT INTO #Deleted (itm_class, att_nme, expected_att_nme,expected_att_dsc)
           SELECT 'BAGS','RE-USED','RE-USED','Re-Used Material'
UNION SELECT 'BAGS','RETAIL_PKG_INDICATOR','RETAIL_PKG_INDICATOR','Retail Package Indicator'
UNION SELECT 'CFB_CNTR','OUTERMOST_SHIPPING_CNTR','OUTERMOST_SHIPPING_CNTR','OUTERMOST SHIPPING CNTR'
UNION SELECT 'FOLDING_CARTON','PRODUCT_LEVEL_IDENTIFICATION','PRODUCT_LEVEL_IDENTIFICATION','PRODUCT LEVEL IDENTIFICATION'
UNION SELECT 'LABEL-PREPRINTED','LBL-GRAPHICS','LBL-GRAPHICS','Label Graphics'
UNION SELECT 'LABEL-PREPRINTED','LBL-OVERLAMINATE','LBL-OVERLAMINATE','Label Overlaminate'
UNION SELECT 'LABEL-PREPRINTED','LBL-PRE-PRINT-TYPE','LBL-PRE-PRINT-TYPE','Pre-Print Type'
UNION SELECT 'PALLET','PALLET-ASSY-TYPE','PALLET-ASSY-TYPE','Pallet Assembly Type'
UNION SELECT 'PALLET','PALLET-ATTRIBUTES','PALLET-ATTRIBUTES','Pallet Attributes'
UNION SELECT 'PALLET','PALLET-STYLE','PALLET-STYLE','Pallet Style'
UNION SELECT 'PALLET','PALLET-TYPE','PALLET-TYPE','Pallet Type'
UNION SELECT 'PALLET','RE-USED','RE-USED','Re-Used Material'
UNION SELECT 'PALLET','RETAIL_PKG_INDICATOR','RETAIL_PKG_INDICATOR','Retail Package Indicator'
UNION SELECT 'PKG-COMPONENTS','PKG-COMP-MATERIAL-2','PKG-COMP-MATERIAL-2','Pkg Component Material 2'
UNION SELECT 'PKG-COMPONENTS','PKG-COMP-STYLE-2','PKG-COMP-STYLE-2','Pkg Component Style 2'
UNION SELECT 'PKG-COMPONENTS','RE-USED','RE-USED','Re-Used Material'
UNION SELECT 'PKG-COMPONENTS','RETAIL_PKG_INDICATOR','RETAIL_PKG_INDICATOR','Retail Package Indicator'
UNION SELECT 'SILICON_WAFER','CUSTOMER_PART_NUM','CUSTOMER_PART_NUM','CUSTOMER PART NUMBER'



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
        result = 'Match not Found';

    -- Alternative error handling (commented out): Specific error messages for NULL cases
    -- Handle NULL cases with specific messages
    --UPDATE #Deleted 
    --SET result = 'Attribute not found in uda_definition'
    --WHERE att_idn IS NULL;

    --UPDATE #Deleted 
    --SET result = 'Item type not found'
    --WHERE item_typ_cde IS NULL AND att_idn IS NOT NULL;

    -- Step 4: Mark as PASS only when the attribute-item type combination exists
    UPDATE tgt
    SET tgt.assert = 'PASS', 
        tgt.result = 'Match Found'
    FROM #Deleted tgt
    INNER JOIN dbo.uda_item_type uit 
    ON uit.att_idn = tgt.att_idn 
       AND uit.item_typ_cde = tgt.item_typ_cde;

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
    FROM #Updated;

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
    FROM #Inserted;

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
    FROM #Deleted;

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

