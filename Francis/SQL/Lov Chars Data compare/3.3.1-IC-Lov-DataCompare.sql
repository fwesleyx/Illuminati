/*
Author:Francis
Environment:SMTF
Type:IC
Description:To compare the data extract on csv with data on SMTF
*/
USE speed_2max;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET NOCOUNT ON;
GO

BEGIN
BEGIN TRY
    -- =====================================================
    -- CLEANUP: Drop temporary tables if they exist
    -- =====================================================
    DROP TABLE IF EXISTS #Updated;
    DROP TABLE IF EXISTS #Inserted;
    DROP TABLE IF EXISTS #Deleted;

    -- =====================================================
    -- TEST 1: VALUE AND DESCRIPTION VALIDATION
    -- Purpose: Validate both attribute values and descriptions
    -- =====================================================
    
    -- Create temp table for value and description validation
    CREATE TABLE #Updated (
        att_idn    int,                    -- Attribute ID/Characteristic Id
        att_nme    VARCHAR(80),            -- Attribute Name/Speed Characteristic Name
        expected_val_txt VARCHAR(80),      -- Expected Value Text
        val_txt   VARCHAR(80),             -- Actual Value Text from DB
        expected_val_dsc VARCHAR(80),      -- Expected Description
        val_dsc   VARCHAR(80),             -- Actual Description from DB
        result    VARCHAR(70),             -- Validation Result Message
        assert    CHAR(4) DEFAULT 'FAIL'   -- Pass/Fail Status
    );

     
    -- Create temp table for value-only validation
    CREATE TABLE #Inserted (
        att_idn    int,                    -- Attribute ID (populated from lookup)
        att_nme   VARCHAR(70),             -- Attribute Name
        expected_val_txt VARCHAR(80),      -- Expected Value Text
        val_txt   VARCHAR(80),             -- Actual Value Text from DB
        expected_val_dsc VARCHAR(80),      -- Expected Description
        val_dsc   VARCHAR(80),             -- Actual Description from DB
        result    VARCHAR(70),             -- Validation Result Message
        assert    CHAR(4) DEFAULT 'FAIL'   -- Pass/Fail Status
    );
       
    -- Create temp table for deletion status validation
    CREATE TABLE #Deleted (
        att_idn    int,                              -- Attribute ID
        att_nme   VARCHAR(70),                       -- Attribute Name
        expected_val_txt VARCHAR(80),                -- Expected Value Text
        val_txt   VARCHAR(80),                       -- Actual Value Text from DB
        expected_val_dsc VARCHAR(80),      -- Expected Description
        val_dsc   VARCHAR(80),             -- Actual Description from DB
        result    VARCHAR(70) DEFAULT 'Value not Deleted', -- Default: assume not deleted
        assert    CHAR(4) DEFAULT 'FAIL'             -- Pass/Fail Status
    );

    -- Insert test data: expected attribute values and descriptions
    INSERT INTO #Updated (att_idn,expected_val_txt,expected_val_dsc)
           SELECT '13258','No-Brand','Handling & recycling symbols'
    UNION SELECT '13258','No-Brand','Handling & recycling symbols'
    UNION SELECT '10454','DTT','Direct Thermal Transfer'
    UNION SELECT '10953','AAA.AA','aaa.aa (UOM for diameter)'
    UNION SELECT '10953','AAA.AAXBBB.BB','aaa.aaXbbb.bb(UOM for dimension)'
    UNION SELECT '10953','AAA.AA','aaa.aa (UOM for diameter)'
    UNION SELECT '10953','AAA.AAXBBB.BB','aaa.aaXbbb.bb(UOM for dimension)'
    UNION SELECT '11215','CONVOL','Convoluted'
    UNION SELECT '13258','No-Brand','Handling & recycling symbols'
    UNION SELECT '13258','NONE','No art - BMC/PN only';

    PRINT '#Updated Table Loaded Successfully'

    -- Populate attribute names from definition table
    UPDATE tgt
    SET tgt.att_nme = d.att_nme
    FROM #Updated tgt
    LEFT JOIN dbo.uda_definition d ON d.att_idn = tgt.att_idn 
    WHERE tgt.att_idn IS NOT NULL;

    -- Populate actual values and descriptions from validation list
    -- Only matches on value text (description matching commented out)
    UPDATE tgt
    SET tgt.val_txt = src.val_txt, tgt.val_dsc = src.dsc
    FROM #Updated tgt
    LEFT JOIN dbo.uda_validation_list src ON src.att_idn = tgt.att_idn 
    AND LTRIM(RTRIM(tgt.expected_val_txt)) = src.val_txt
    --AND LTRIM(RTRIM(tgt.expected_val_dsc)) = src.dsc 
    WHERE tgt.att_idn IS NOT NULL;

    -- =====================================================
    -- VALIDATION LOGIC: Check various mismatch scenarios
    -- =====================================================
    
    -- Case 1: Both value and description are missing from database
    UPDATE tgt
    SET tgt.result = 'Value Missing, Description Missing'
    FROM #Updated tgt
    WHERE tgt.val_txt IS NULL AND tgt.val_dsc IS NULL;

    -- Case 2: Only value is missing (description exists)
    UPDATE tgt
    SET tgt.result = 'Value Missing'
    FROM #Updated tgt
    WHERE tgt.val_txt IS NULL AND tgt.val_dsc IS NOT NULL;

    -- Case 3: Only description is missing (value exists)
    UPDATE tgt
    SET tgt.result = 'Description Missing'
    FROM #Updated tgt
    WHERE tgt.val_txt IS NOT NULL AND tgt.val_dsc IS NULL;

    -- Case 4: Both value and description exist but don't match expected
    UPDATE tgt
    SET tgt.result = 'Value Mismatch, Description Mismatch',
    tgt.val_dsc = src.dsc
    FROM #Updated tgt
    JOIN dbo.uda_validation_list src 
    ON  LTRIM(RTRIM(tgt.expected_val_txt)) <> src.val_txt
    AND LTRIM(RTRIM(tgt.expected_val_dsc)) <> src.dsc
    WHERE tgt.val_txt IS NOT NULL AND tgt.val_dsc IS NOT NULL;

    -- Case 5: Value doesn't match but description does
    UPDATE tgt
    SET tgt.result = 'Value Mismatch'
    FROM #Updated tgt
    JOIN dbo.uda_validation_list src 
    ON  LTRIM(RTRIM(tgt.expected_val_txt)) <> src.val_txt
    AND LTRIM(RTRIM(tgt.expected_val_dsc)) = src.dsc
    WHERE tgt.val_txt IS NOT NULL 
      AND tgt.val_dsc IS NOT NULL;

    -- Case 6: Value matches but description doesn't
    UPDATE tgt
    SET tgt.result = 'Description Mismatch'
    FROM #Updated tgt
    JOIN dbo.uda_validation_list src 
    ON  LTRIM(RTRIM(tgt.expected_val_txt)) = src.val_txt
    AND LTRIM(RTRIM(tgt.expected_val_dsc)) <> src.dsc
    WHERE tgt.val_txt IS NOT NULL 
      AND tgt.val_dsc IS NOT NULL;

    -- Case 7: Perfect match - both value and description match expected
    UPDATE tgt
    SET tgt.assert = 'PASS', tgt.result = 'Match Found'
    FROM #Updated tgt
     JOIN dbo.uda_validation_list src 
    ON  LTRIM(RTRIM(tgt.expected_val_txt)) = src.val_txt
    AND LTRIM(RTRIM(tgt.expected_val_dsc)) = src.dsc;

    -- =====================================================
    -- TEST 2: VALUE-ONLY VALIDATION
    -- Purpose: Validate attribute values without description checking
    -- =====================================================
   
    
    -- Insert test data: expected values only (no descriptions)
    INSERT INTO #Inserted (expected_val_txt,expected_val_dsc)
          SELECT 'CNSMR_UNIT_TRADE_ITEM','Consumer Unit & Trade Item Box'
    UNION SELECT 'CONSUMER_UNIT_BOX','Consumer Unit Box'
    UNION SELECT 'DO_NOT_DSPLY','Do not display dimensions'
    UNION SELECT 'CFB','Corrugated-Fiberboard'
    UNION SELECT 'CNSMR_UNIT_TRADE_ITEM','Consumer Unit & Trade Item Box'
    UNION SELECT 'CONSUMER_UNIT_BOX','Consumer Unit Box'
    UNION SELECT 'DO_NOT_DSPLY','Do not display dimensions'
    UNION SELECT 'Glass','Glass'
    UNION SELECT 'HDPE Code 2','HDPE Code 2'
    UNION SELECT 'LDPE Code 4','LDPE Code 4'
    UNION SELECT 'MLDFBR','Molded Fiber'
    UNION SELECT 'Metal','Metal'
    UNION SELECT 'OT Code  7','OT Code  7'
    UNION SELECT 'PP Code 5','PP Code 5'
    UNION SELECT 'PS Code 6','PS Code 6'
    UNION SELECT 'RIGID','Rigid Paperboard'
    UNION SELECT 'Wood','Wood'
    UNION SELECT 'OT','Other'
    UNION SELECT 'PETE','PETE Code 1';

    -- Populate attribute ID and actual value from validation list
    UPDATE tgt
    SET tgt.att_idn = src.att_idn , tgt.val_txt = src.val_txt
    FROM #Inserted tgt
    LEFT JOIN dbo.uda_validation_list src 
    ON src.val_txt = tgt.expected_val_txt;

    -- Populate attribute names from definition table
    UPDATE tgt
    SET tgt.att_nme = d.att_nme
    FROM #Inserted tgt
    LEFT JOIN dbo.uda_definition d ON d.att_idn = tgt.att_idn 
    WHERE tgt.att_idn IS NOT NULL;

    -- Mark as PASS if exact match found in validation list
    UPDATE tgt
    SET tgt.assert = 'PASS',tgt.result = 'Match Found',tgt.val_dsc = src.dsc
    FROM #Inserted tgt
    JOIN dbo.uda_validation_list src 
    ON src.val_txt = tgt.expected_val_txt
    AND src.att_idn = tgt.att_idn ;

    -- Mark as FAIL if no match found (attribute ID is NULL)
    UPDATE tgt
    SET tgt.result = 'Match not Found' 
    FROM #Inserted tgt
    WHERE tgt.att_idn IS NULL AND tgt.result IS NULL;

    -- =====================================================
    -- TEST 3: DELETION STATUS VALIDATION
    -- Purpose: Check if specific attribute values are marked as deleted
    -- =====================================================
 
    
    -- Insert test data: specific attribute IDs and values to check for deletion
    INSERT INTO #Deleted (att_idn,expected_val_txt,expected_val_dsc)
          SELECT '10398','NULL','NULL'
    UNION SELECT '10398','NULL','NULL'
    UNION SELECT '10399','NULL','NULL'
    UNION SELECT '10399','NULL','NULL'
    UNION SELECT '10399','NULL','NULL'
    UNION SELECT '10399','NULL','NULL'
    UNION SELECT '10399','NULL','NULL'
    UNION SELECT '10399','NULL','NULL'
    UNION SELECT '10399','NULL','NULL'
    UNION SELECT '13261','NULL','NULL'
    UNION SELECT '13261','NULL','NULL'
    UNION SELECT '13262','NULL','NULL'
    UNION SELECT '10454','NULL','NULL'
    UNION SELECT '10454','NULL','NULL'
    UNION SELECT '10454','NULL','NULL'
    UNION SELECT '10454','NULL','NULL'
    UNION SELECT '10944','NULL','NULL'
    UNION SELECT '10944','NULL','NULL'
    UNION SELECT '10944','NULL','NULL'
    UNION SELECT '10944','NULL','NULL'
    UNION SELECT '10946','NULL','NULL'
    UNION SELECT '10944','NULL','NULL'
    UNION SELECT '10944','NULL','NULL'
    UNION SELECT '10944','NULL','NULL'
    UNION SELECT '10944','NULL','NULL'
    UNION SELECT '10947','NULL','NULL'
    UNION SELECT '10947','NULL','NULL'
    UNION SELECT '10947','NULL','NULL'
    UNION SELECT '10947','NULL','NULL'
    UNION SELECT '10947','NULL','NULL'
    UNION SELECT '10947','NULL','NULL'
    UNION SELECT '10947','NULL','NULL'
    UNION SELECT '10947','NULL','NULL'
    UNION SELECT '10950','NULL','NULL'
    UNION SELECT '10950','NULL','NULL'
    UNION SELECT '10950','NULL','NULL'
    UNION SELECT '10950','NULL','NULL'
    UNION SELECT '10951','NULL','NULL'
    UNION SELECT '10951','NULL','NULL'
    UNION SELECT '11159','ASSY','Assembly'
    UNION SELECT '11159','N/A','Blank'
    UNION SELECT '11160','MU','Multiple Use'
    UNION SELECT '11160','ST','Single Trip'
    UNION SELECT '11163','NULL','NULL'
    UNION SELECT '11163','NULL','NULL'
    UNION SELECT '11163','NULL','NULL'
    UNION SELECT '11163','NULL','NULL'
    UNION SELECT '11163','NULL','NULL'
    UNION SELECT '11163','NULL','NULL'
    UNION SELECT '11163','NULL','NULL'
    UNION SELECT '11213','NULL','NULL'
    UNION SELECT '11213','NULL','NULL'
    UNION SELECT '11213','NULL','NULL'
    UNION SELECT '11213','NULL','NULL'
    UNION SELECT '11213','PLSTC','DO NOT USE Plastic'
    UNION SELECT '11213','NULL','NULL'
    UNION SELECT '11213','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11214','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11216','NULL','NULL'
    UNION SELECT '11217','NULL','NULL'
    UNION SELECT '11217','NULL','NULL'
    UNION SELECT '11217','NULL','NULL'
    UNION SELECT '11217','NULL','NULL';

    -- Populate attribute names from definition table
    UPDATE tgt
    SET tgt.att_nme = d.att_nme
    FROM #Deleted tgt
    LEFT JOIN dbo.uda_definition d ON d.att_idn = tgt.att_idn 
    WHERE tgt.att_idn IS NOT NULL;

    -- Populate actual values from validation list
    UPDATE tgt
    SET tgt.val_txt = src.val_txt,tgt.val_dsc = src.dsc
    FROM #Deleted tgt
    LEFT JOIN dbo.uda_validation_list src ON src.att_idn = tgt.att_idn AND src.val_txt = tgt.expected_val_txt
    WHERE tgt.att_idn IS NOT NULL;

    -- Mark as PASS if value exists and is marked as deleted (curr_actv_ind = 'N')
    UPDATE tgt
    SET tgt.assert = 'PASS',tgt.result = 'Marked as Deleted'
    FROM #Deleted tgt
    JOIN dbo.uda_validation_list src 
    ON src.val_txt = tgt.expected_val_txt
    AND src.att_idn = tgt.att_idn  
    AND src.curr_actv_ind = 'N';  -- 'N' indicates deleted/inactive

    -- =====================================================
    -- OUTPUT RESULTS: Display all validation test results
    -- =====================================================
    
    -- Test 1 Results: Value and Description Validation
    SELECT att_idn, att_nme, expected_val_txt, val_txt, expected_val_dsc, val_dsc, assert, result
    FROM #Updated;
    
    -- Test 2 Results: Value-Only Validation
    SELECT att_idn, att_nme, expected_val_txt, val_txt, expected_val_dsc, val_dsc, assert, result
    FROM #Inserted;
    
    -- Test 3 Results: Deletion Status Validation
    SELECT att_idn, att_nme, expected_val_txt, val_txt, expected_val_dsc, val_dsc, assert, result
    FROM #Deleted;

END TRY
BEGIN CATCH
    -- =====================================================
    -- ERROR HANDLING: Display error information if any issues occur
    -- =====================================================
    PRINT 'Error occurred during execution.';
    PRINT 'Message     : ' + ERROR_MESSAGE();
    PRINT 'Line        : ' + CAST(ERROR_LINE() AS VARCHAR);
END CATCH
END