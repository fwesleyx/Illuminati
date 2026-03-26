/* 
  Author : S.Sathieshkumar
  Date   : 26-09-2025
  Desc   : TWC5924-1343 -- Verify MM Class and Characteristics newly added
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
-- Drop temp table if it exists
DROP TABLE IF EXISTS #SourceItem;
-- Create temp table
CREATE TABLE #SourceItem (
            att_idn    int,
            att_nme    VARCHAR(30),
            expected_val_txt VARCHAR(30),
            val_txt   VARCHAR(30),
            result    VARCHAR(70),
            assert    CHAR(4) DEFAULT 'FAIL'
        );
-- Insert expected attribute name and description pairs
INSERT INTO #SourceItem (expected_val_txt)
SELECT 'CNSMR_UNIT_TRADE_ITEM'
UNION SELECT 'CONSUMER_UNIT_BOX'
UNION SELECT 'DO_NOT_DSPLY'
UNION SELECT 'CFB'
UNION SELECT 'CNSMR_UNIT_TRADE_ITEM'
UNION SELECT 'CONSUMER_UNIT_BOX'
UNION SELECT 'DO_NOT_DSPLY'
UNION SELECT 'Glass'
UNION SELECT 'HDPE Code 2'
UNION SELECT 'LDPE Code 4'
UNION SELECT 'MLDFBR'
UNION SELECT 'Metal'
UNION SELECT 'OT Code  7'
UNION SELECT 'PP Code 5'
UNION SELECT 'PS Code 6'
UNION SELECT 'RIGID'
UNION SELECT 'Wood'
UNION SELECT 'OT';

UPDATE tgt
SET tgt.att_idn = src.att_idn , tgt.val_txt = src.val_txt
FROM
#SourceItem tgt
LEFT JOIN dbo.uda_validation_list src 
ON src.val_txt = tgt.expected_val_txt;


UPDATE tgt
SET tgt.att_idn = src.att_idn , tgt.assert = 'PASS',tgt.result = 'Match Found'
FROM
#SourceItem tgt
JOIN dbo.uda_validation_list src 
ON src.val_txt = tgt.expected_val_txt;


-- Attribute Missing
UPDATE tgt
SET tgt.result = 'lov val_txt missing' FROM
#SourceItem tgt
WHERE tgt.att_idn IS NULL AND tgt.result IS NULL;

-- Attribute Description Mismatch
UPDATE tgt
SET tgt.result = 'Value Text Mismatch'
FROM #SourceItem tgt
JOIN dbo.uda_validation_list src 
ON src.val_txt <> tgt.expected_val_txt
WHERE tgt.result IS NULL;

UPDATE tgt
SET tgt.att_nme = d.att_nme
FROM #SourceItem tgt
LEFT JOIN dbo.uda_definition d ON d.att_idn = tgt.att_idn 
WHERE tgt.att_idn IS NOT NULL;


SELECT att_idn ,att_nme ,expected_val_txt ,val_txt, assert,result
FROM #SourceItem
WHERE assert = 'FAIL';
END TRY
BEGIN CATCH
        PRINT 'Error occurred during execution.';
        PRINT 'Message     : ' + ERROR_MESSAGE();
        PRINT 'Line        : ' + CAST(ERROR_LINE() AS VARCHAR);
        
END CATCH
END

BEGIN
BEGIN TRY
-- Drop temp table if it exists
DROP TABLE IF EXISTS #SourceItems;
-- Create temp table
CREATE TABLE #SourceItems (
            att_idn    int,
            att_nme   VARCHAR(50),
            expected_dsc VARCHAR(30),
            dsc   VARCHAR(30),
            result    VARCHAR(70),
            assert    CHAR(4) DEFAULT 'FAIL'
        );
-- Insert expected attribute name and description pairs
INSERT INTO #SourceItems (expected_dsc)
SELECT 'No art or BMC only'
UNION SELECT 'No art or BMC only'
UNION SELECT 'Direct Transfer'
UNION SELECT 'aa.aa (UOM for diameter)'
UNION SELECT 'aa.aaXbb.bb(UOM for dimension)'
UNION SELECT 'aa.aa (UOM for diameter)'
UNION SELECT 'aa.aaXbb.bb(UOM for dimension)'
UNION SELECT 'Produce Code'
UNION SELECT 'Product Bottom Label'
UNION SELECT 'Packout Label'
UNION SELECT 'Die-Cut, Not Joined'
UNION SELECT 'Die-Cut, Joined'
UNION SELECT 'No art or BMC only';

UPDATE tgt
SET tgt.att_idn = src.att_idn , tgt.dsc = src.dsc
FROM
#SourceItems tgt
LEFT JOIN dbo.uda_validation_list src
ON src.dsc = tgt.expected_dsc;


UPDATE tgt
SET tgt.att_idn = src.att_idn , tgt.assert = 'PASS',tgt.result = 'Match Found'
FROM
#SourceItems tgt
JOIN dbo.uda_validation_list src 
ON src.dsc = tgt.expected_dsc;


-- Attribute Missing
UPDATE tgt
SET tgt.result = 'lov dsc missing' FROM
#SourceItems tgt
WHERE tgt.att_idn IS NULL AND tgt.result IS NULL;

-- Attribute Description Mismatch
UPDATE tgt
SET tgt.result = 'Description Text Mismatch'
FROM #SourceItems tgt
JOIN dbo.uda_validation_list src 
ON src.dsc <> tgt.expected_dsc
WHERE tgt.result IS NULL;

UPDATE tgt
SET tgt.att_nme = d.att_nme
FROM #SourceItems tgt
LEFT JOIN dbo.uda_definition d ON d.att_idn = tgt.att_idn 
WHERE tgt.att_idn IS NOT NULL;


SELECT att_idn ,att_nme ,expected_dsc ,dsc, assert,result
FROM #SourceItems
WHERE assert = 'FAIL';
END TRY
BEGIN CATCH
        PRINT 'Error occurred during execution.';
        PRINT 'Message     : ' + ERROR_MESSAGE();
        PRINT 'Line        : ' + CAST(ERROR_LINE() AS VARCHAR);
        
END CATCH
END