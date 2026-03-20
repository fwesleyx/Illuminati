-- Set the database context to 'speed'
USE speed
GO

-- =====================================================
-- CLEANUP: Remove temporary tables if they exist from previous runs
-- =====================================================
DROP TABLE IF EXISTS #ItemHierarchy;
DROP TABLE IF EXISTS #fg_parent_item;

-- =====================================================
-- TABLE CREATION: Define the main hierarchy structure
-- =====================================================
-- This table will store a 3-level item hierarchy:
-- Level 1: FG (Finished Goods) - the final sellable products
-- Level 2: TEST (Test Items) - intermediate test components  
-- Level 3: ASSY (Assembly Items) - the actual manufactured assemblies
CREATE TABLE #ItemHierarchy 
(
  -- FINISHED GOODS LEVEL (Level 1 - Top of hierarchy)
  fg_item_cde VARCHAR(25),           -- FG item code (primary identifier)
  fg_item_rev CHAR(2),               -- FG item revision
  fg_item_dsc VARCHAR(200),          -- FG item description
  fg_item_typ_cde VARCHAR(25),       -- FG item type code
  fg_item_sap_mat_typ VARCHAR(40),   -- SAP material type for FG
  fg_item_typ_dsc VARCHAR(100),      -- FG item type description
  
  -- TEST ITEM LEVEL (Level 2 - Middle of hierarchy)
  test_item_cde VARCHAR(25),         -- Test item code
  test_item_dsc VARCHAR(200),        -- Test item description
  test_item_typ_cde VARCHAR(25),     -- Test item type code
  test_item_sap_mat_typ VARCHAR(40), -- SAP material type for test item
  test_item_typ_dsc VARCHAR(100),    -- Test item type description
  
  -- ASSEMBLY LEVEL (Level 3 - Bottom of hierarchy)
  assy_item_cde VARCHAR(25),         -- Assembly item code
  assy_item_rev CHAR(2),             -- Assembly item revision
  assy_item_dsc VARCHAR(200),        -- Assembly item description
  assy_item_typ_cde VARCHAR(25),     -- Assembly item type code
  assy_item_sap_mat_typ VARCHAR(40), -- SAP material type for assembly
  assy_item_typ_dsc VARCHAR(100)     -- Assembly item type description
);

-- =====================================================
-- EXPLORATORY QUERY: Preview the data we'll be inserting
-- =====================================================
-- This SELECT shows what finished goods items exist that have the required hierarchy
-- It's essentially a preview of what will be inserted (but only shows FG level data)
-- SELECT 
--  DISTINCT
--    b.parent_item_cde  as fg_item_cde      -- The finished goods item code
--  , b.parent_item_rev  as fg_item_rev      -- The finished goods revision
--  , p.dsc_full   as fg_item_dsc            -- Full description of FG item
--  , p.item_typ_cde  as fg_item_typ_cde     -- FG item type code
--  , p.sap_mat_typ   as fg_item_sap_mat_typ -- SAP material type (should be 'FERT')
--  , pit.item_typ_dsc  as fg_item_typ_dsc   -- Description of the item type
-- FROM
--  dbo.design_bom b                         -- Bill of Materials table
--  JOIN dbo.item p ON b.parent_item_cde = p.item_cde    -- Join to get parent (FG) item details
--   AND b.parent_item_rev = p.mfg_rev
--  JOIN item_type pit ON pit.item_typ_cde = p.item_typ_cde  -- Get FG item type description
--  JOIN dbo.item c ON b.child_item_cde = c.item_cde         -- Join to get child (test) item details
--  JOIN dbo.item_type cit ON c.item_typ_cde = cit.item_typ_cde  -- Verify child is a test item
--   AND cit.item_typ_dsc = 'UPI_TEST'       -- Filter: child must be a test item
 
--  -- Second level BOM join: Test item -> Assembly item
--  JOIN dbo.design_bom b1 ON b.child_item_cde = b1.parent_item_cde  -- Test item is parent in next BOM level
--   AND c.mfg_rev = b1.parent_item_rev
--  JOIN dbo.item c1 ON b1.child_item_cde = c1.item_cde             -- Get assembly item details
--  JOIN dbo.item_type c1it ON c1.item_typ_cde = c1it.item_typ_cde  -- Verify it's an assembly
--   AND c1it.item_typ_dsc = 'UPI_ASSEMBLY'  -- Filter: must be an assembly item
-- WHERE
--  p.sap_mat_typ = 'FERT';                  -- Filter: only finished goods (FERT = Finished Product in SAP)
 
-- =====================================================
-- MAIN DATA POPULATION: Insert the complete hierarchy
-- =====================================================
-- This INSERT captures all three levels of the hierarchy in one query
INSERT INTO #ItemHierarchy (
 -- Specify all columns to ensure proper data mapping
 fg_item_cde, fg_item_rev, fg_item_dsc, fg_item_typ_cde, fg_item_sap_mat_typ, fg_item_typ_dsc,
 test_item_cde, test_item_dsc, test_item_typ_cde, test_item_sap_mat_typ, test_item_typ_dsc,
 assy_item_cde, assy_item_rev, assy_item_dsc, assy_item_typ_cde, assy_item_sap_mat_typ, assy_item_typ_dsc
)
SELECT 
   -- FINISHED GOODS DATA (Level 1)
   b.parent_item_cde  as fg_item_cde      -- FG item from first BOM level
 , b.parent_item_rev  as fg_item_rev      -- FG revision
 , p.dsc_full   as fg_item_dsc            -- FG description
 , p.item_typ_cde  as fg_item_typ_cde     -- FG type code
 , p.sap_mat_typ   as fg_item_sap_mat_typ -- FG SAP material type
 , pit.item_typ_dsc  as fg_item_typ_dsc   -- FG type description
 
   -- TEST ITEM DATA (Level 2)
 , b.child_item_cde  as test_item_cde     -- Test item from first BOM level (child of FG)
 , c.dsc_full   as test_item_dsc          -- Test item description
 , c.item_typ_cde  as test_item_typ_cde   -- Test item type code
 , c.sap_mat_typ   as test_item_sap_mat_typ -- Test item SAP material type
 , cit.item_typ_dsc  as test_item_typ_dsc -- Test item type description
 
   -- ASSEMBLY DATA (Level 3)
 , b1.child_item_cde  as assy_item_cde    -- Assembly item from second BOM level (child of test)
 , b1.parent_item_rev as assy_item_rev    -- Assembly revision (using parent rev from second BOM)
 , c1.dsc_full   as assy_item_dsc         -- Assembly description
 , c1.item_typ_cde  as assy_item_typ_cde  -- Assembly type code
 , c1.sap_mat_typ  as assy_item_sap_mat_typ -- Assembly SAP material type
 , c1it.item_typ_dsc  as assy_item_typ_dsc  -- Assembly type description
FROM
 -- FIRST BOM LEVEL: FG -> Test Item
 dbo.design_bom b                         -- Primary BOM table
 JOIN dbo.item p ON b.parent_item_cde = p.item_cde    -- Get FG item details
  AND b.parent_item_rev = p.mfg_rev
 JOIN item_type pit ON pit.item_typ_cde = p.item_typ_cde  -- Get FG type description
 JOIN dbo.item c ON b.child_item_cde = c.item_cde         -- Get test item details
 JOIN dbo.item_type cit ON c.item_typ_cde = cit.item_typ_cde  -- Validate test item type
  AND cit.item_typ_dsc = 'UPI_TEST'       -- Must be a test item
 
 -- SECOND BOM LEVEL: Test Item -> Assembly
 JOIN dbo.design_bom b1 ON b.child_item_cde = b1.parent_item_cde  -- Test item becomes parent
  AND c.mfg_rev = b1.parent_item_rev      -- Match revisions
 JOIN dbo.item c1 ON b1.child_item_cde = c1.item_cde             -- Get assembly item details
 JOIN dbo.item_type c1it ON c1.item_typ_cde = c1it.item_typ_cde  -- Validate assembly type
  AND c1it.item_typ_dsc = 'UPI_ASSEMBLY'  -- Must be an assembly item
WHERE
 p.sap_mat_typ = 'FERT';                  -- Only process finished goods
 
-- =====================================================
-- DATA VERIFICATION: Show what was inserted
-- =====================================================
SELECT * FROM #ItemHierarchy;

-- =====================================================
-- SCHEMA ENHANCEMENT: Add external plant indicators
-- =====================================================
-- These flags will indicate if items are manufactured at external (non-Intel) plants
ALTER TABLE #ItemHierarchy ADD test_has_any_ext_plnt_ind CHAR(1) DEFAULT 'N';  -- Test item external plant flag
ALTER TABLE #ItemHierarchy ADD assy_has_any_ext_plnt_ind CHAR(1) DEFAULT 'N';  -- Assembly external plant flag

-- Initialize all flags to 'N' (No external plants)
UPDATE #ItemHierarchy SET test_has_any_ext_plnt_ind = 'N'
 , assy_has_any_ext_plnt_ind = 'N';

-- =====================================================
-- EXPLORATORY QUERIES: Examine plant relationships
-- =====================================================
-- This query shows all test items and their associated plants
-- Helps understand the plant distribution before updating flags
SELECT *
FROM
 #ItemHierarchy tgt
 JOIN dbo.item_plant p ON tgt.test_item_cde = p.item_cde      -- Link test items to plants
 JOIN dbo.manufacturing_plant m ON p.plnt_idn = m.plnt_idn;   -- Get plant details

-- This query specifically shows assembly items manufactured at external plants
-- Useful for understanding external dependencies
SELECT 
 tgt.assy_item_cde      -- Assembly item code
 , tgt.assy_item_dsc    -- Assembly description
 , p.item_cde           -- Item code from plant table
 , p.plnt_idn           -- Plant identifier
 , m.plnt_cde           -- Plant code
 , m.sap_plnt_cde       -- SAP plant code
 , m.intel_own_ind      -- Intel ownership indicator ('Y'=Intel owned, 'N'=External)
FROM
 #ItemHierarchy tgt
 JOIN dbo.item_plant p ON tgt.assy_item_cde = p.item_cde     -- Link assembly to plants
 JOIN dbo.manufacturing_plant m ON p.plnt_idn = m.plnt_idn   -- Get plant details
WHERE
 m.intel_own_ind = 'N';  -- Filter to show only external plants

-- =====================================================
-- FLAG UPDATES: Mark items with external plant dependencies
-- =====================================================
-- Update test item external plant flag
-- If any plant manufacturing this test item is external, flag it as 'Y'
UPDATE tgt
 SET tgt.test_has_any_ext_plnt_ind = 'Y'
FROM
 #ItemHierarchy tgt
 JOIN dbo.item_plant p ON tgt.test_item_cde = p.item_cde     -- Find plants for test item
 JOIN dbo.manufacturing_plant m ON p.plnt_idn = m.plnt_idn   -- Get plant ownership info
WHERE
 m.intel_own_ind = 'N';  -- External plant (not Intel owned)

-- Update assembly item external plant flag
-- If any plant manufacturing this assembly is external, flag it as 'Y'
UPDATE tgt
 SET tgt.assy_has_any_ext_plnt_ind = 'Y'
FROM
 #ItemHierarchy tgt
 JOIN dbo.item_plant p ON tgt.assy_item_cde = p.item_cde     -- Find plants for assembly
 JOIN dbo.manufacturing_plant m ON p.plnt_idn = m.plnt_idn   -- Get plant ownership info
WHERE
 m.intel_own_ind = 'N';  -- External plant (not Intel owned)

-- =====================================================
-- SUMMARY TABLE CREATION: Create FG parent item summary
-- =====================================================
-- Create a summary table containing unique finished goods items
-- This could be used for further analysis or reporting
SELECT 
 DISTINCT 
  fg_item_cde           -- Unique FG item codes
  , fg_item_rev         -- FG revisions
  , '' order_point_ind  -- Placeholder for order point indicator (empty for now)
 INTO #fg_parent_item   -- Create new temp table
FROM #ItemHierarchy;

-- =====================================================
-- FINAL RESULTS: Display both tables
-- =====================================================
-- Show the complete hierarchy with external plant flags
--SELECT * FROM #ItemHierarchy;

-- Show the FG summary table
--SELECT * FROM #fg_parent_item;