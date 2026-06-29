/* FULLY INTERNAL PKG-IPIF
	sathish
*/

use workdb

-- =====================================================================================
-- SCRIPT PURPOSE: BOM HIERARCHY ANALYSIS WITH SITE LOCATION VALIDATION
-- 
-- This script performs a comprehensive analysis of Bill of Materials (BOM) for 
-- 'UPI_TEST','UPI_ASSEMBLY' items to determine optimal sourcing strategies based on manufacturing
-- site locations (internal vs external). It generates complete BOM hierarchies and
-- classifies items for make-vs-buy decisions.
-- =====================================================================================

-- =====================================================================================
-- SECTION 1: CLEANUP AND TABLE CREATION
-- Drop existing temporary tables to ensure clean execution
-- =====================================================================================

-- CREATE A TABLE TO STORE STARTING STAGE ITEM CODES
IF OBJECT_ID('tempdb..#starting_stage_item_codes') IS NOT NULL
    DROP TABLE #starting_stage_item_codes;

IF OBJECT_ID('tempdb..#bom_temp') IS NOT NULL
    DROP TABLE #bom_temp

IF OBJECT_ID('tempdb..#item_child_parent_codes') IS NOT NULL
    DROP TABLE #item_child_parent_codes

IF OBJECT_ID('tempdb..#item_site') IS NOT NULL
    DROP TABLE #item_site

-- =====================================================================================
-- Create temporary table to store starting point items (leaf nodes for recursion)
-- These are the 'UPI_TEST','UPI_ASSEMBLY' items that will be analyzed
-- =====================================================================================
CREATE TABLE #starting_stage_item_codes 
(
    row_nbr INT IDENTITY(1,1),          -- Sequential row number
    item_cde VARCHAR(25),               -- Item code identifier
    item_rev CHAR(2),                   -- Item revision
    item_type VARCHAR(30),              -- Item type description
    item_typ_cde CHAR(4),               -- Item type code
    item_status VARCHAR(30),            -- Item status (PRODN_APPROVED, etc.)
    item_dsc VARCHAR(40),               -- Item description
    item_bu_idn VARCHAR(10),            -- Business unit identifier
    item_bu_short_nme VARCHAR(30),      -- Business unit short name
    item_project_cde VARCHAR(30)       -- Project code
);

-- =====================================================================================
-- Create temporary table to store complete BOM hierarchy with site indicators
-- This will hold the final analyzed BOM structure
-- =====================================================================================
CREATE TABLE #bom_temp (
    master_parent_cde VARCHAR(30),      -- Top-level parent item code
    item_cde VARCHAR(30),               -- Current item code
    item_rev VARCHAR(3),                -- Item revision
    item_status VARCHAR(30),            -- Item status
    item_type VARCHAR(30),              -- Item type description
    item_dsc VARCHAR(40),               -- Item description
    bom_level INT,                      -- Hierarchy level (0=parent, 1=child, etc.)
	mm_code_nme VARCHAR(40) DEFAULT NULL,   -- MM code name attribute
	site_indicator CHAR(1) DEFAULT NULL,    -- Site classification (I/E/M)
	order_point CHAR(3) DEFAULT NULL,       -- Order point recommendation (B/S/TBD)
	remark VARCHAR(MAX) DEFAULT NULL        -- Additional remarks
);



INSERT INTO #starting_stage_item_codes (
    item_cde,
    item_rev,
    item_type,
    item_typ_cde,
    item_status,
    item_dsc,
    item_bu_idn,
    item_bu_short_nme,
    item_project_cde
)
SELECT 
    i.item_cde,                         -- Item code
    i.mfg_rev,                          -- Manufacturing revision
    it.item_typ_dsc,                    -- Item type description
    it.item_typ_cde,                    -- Item type code
    ilvl.nme,                           -- Item release level name
    i.dsc,                              -- Item description
    budg.bus_unit_idn,                  -- Business unit ID
    budg.short_nme,                     -- Business unit short name
    ir.proj_cde                         -- Project code
FROM [speed_2max].[dbo].[item] i 
JOIN [speed_2max].[dbo].item_revision ir ON i.item_cde = ir.item_cde AND i.mfg_rev = ir.item_rev
JOIN [speed_2max].[dbo].item_type it ON i.item_typ_cde = it.item_typ_cde
JOIN [speed_2max].[dbo].item_rls_lvl ilvl ON ir.lvl_idn = ilvl.lvl_idn 
JOIN [speed_2max].[dbo].bus_unit_dsgn_grp budg ON budg.bus_unit_idn = ir.bus_unit_idn
JOIN [speed_2max].[dbo].uda_item udaItem ON udaItem.item_cde = ir.item_cde
JOIN [speed_2max].[dbo].uda_definition def ON def.att_idn = udaItem.att_idn
WHERE it.item_typ_dsc IN ('UPI_TEST','UPI_ASSEMBLY')              -- Focus on UPI_TEST,UPI_ASSEMBLY items only
    AND ilvl.nme NOT IN ('INACTIVE','DRAFT','OBSOLETE') -- Exclude inactive items
    AND budg.short_nme IN ('IA','CIG')                   -- Specific business units
    AND ilvl.nme = 'PRODN_APPROVED'                     -- Only production approved items
    AND def.att_nme = 'SUBASSY_PROD_ENGNR_CD'
    AND udaItem.val_txt in ('ENG LOCKED', 'ENG UNLOCKED','PRODUCTION');

-- Uncomment to verify starting items loaded correctly
 SELECT * FROM #starting_stage_item_codes;

-- =====================================================================================
-- SECTION 3: RECURSIVE BOM GENERATION
-- Generate complete BOM hierarchy for all starting items using recursive CTE
-- This creates a tree structure showing all parent-child relationships
-- =====================================================================================

-- STEP 2: GENERATE A BOM RECURSIVELY FOR ALL ITEMS in #starting_items

WITH bom_hier_cte AS (
    -- =====================================================================================
    -- ANCHOR MEMBER: Starting with Root Level Items (Level 1)
    -- Initialize the recursion with our starting 'UPI_TEST','UPI_ASSEMBLY' items
    -- =====================================================================================
    SELECT 
        CAST(ssic.item_cde AS VARCHAR(25)) as master_parent_cde,    -- Track original parent
        CAST(ssic.item_rev AS CHAR(2)) as master_parent_rev,
        CAST(ssic.item_type AS VARCHAR(30)) as master_parent_type,
        CAST(ssic.item_cde AS VARCHAR(25)) as parent_item_cde,      -- Current parent
        CAST(ssic.item_rev AS CHAR(2)) as parent_item_rev,
        CAST(ssic.item_type AS VARCHAR(30)) as parent_item_type,
        CAST(ssic.item_status AS VARCHAR(30)) as parent_status,
        CAST(ssic.item_cde AS VARCHAR(25)) as child_item_cde,       -- Current child (same as parent for level 1)
        CAST(ssic.item_rev AS CHAR(2)) as child_item_rev,
        CAST(ssic.item_type AS VARCHAR(30)) as child_item_type,
        CAST(ssic.item_status AS VARCHAR(30)) as child_item_status,
        CAST(ssic.item_dsc AS VARCHAR(40)) as child_item_dsc,
        
        CAST(NULL AS VARCHAR(16)) as bom_type,                      -- No BOM type for root level
        CAST(1 AS INT) as bom_level,                                -- Start at level 1
        CAST(' / ' + ssic.item_cde AS VARCHAR(1000)) as hierarchy_path  -- Track path for cycle detection
		
    FROM #starting_stage_item_codes ssic

    UNION ALL

    -- =====================================================================================
    -- RECURSIVE MEMBER: Child becomes parent for subsequent recursion calls
    -- This expands the BOM tree by finding children of current items
    -- =====================================================================================
    SELECT 
        CAST(bh.master_parent_cde AS VARCHAR(25)) as master_parent_cde,     -- Keep original parent
        CAST(bh.master_parent_rev AS CHAR(2)) as master_parent_rev,
        CAST(bh.master_parent_type AS VARCHAR(30)) as master_parent_type,
        CAST(bh.child_item_cde AS VARCHAR(25)) as parent_item_cde,          -- Previous child becomes parent
        CAST(bh.child_item_rev AS CHAR(2)) as parent_item_rev,
        CAST(bh.child_item_type AS VARCHAR(30)) as parent_item_type,
        CAST(bh.child_item_status AS VARCHAR(30)) as parent_status,
        CAST(db.child_item_cde AS VARCHAR(25)) as child_item_cde,           -- New child from design_bom
        CAST(ci.mfg_rev AS CHAR(2)) as child_item_rev,
        CAST(cit.item_typ_dsc AS VARCHAR(30)) as child_item_type,
        CAST(cilvl.nme AS VARCHAR(30)) as child_item_status,
        CAST(ci.dsc AS VARCHAR(40)) as child_item_dsc,
       
        CAST(db.bom_typ_cde AS VARCHAR(16)) as bom_type,                    -- BOM type from design_bom
        CAST(bh.bom_level + 1 AS INT) as bom_level,                         -- Increment level
        CAST(bh.hierarchy_path + ' / ' + db.child_item_cde AS VARCHAR(1000)) as hierarchy_path  -- Extend path

    FROM bom_hier_cte bh
    -- Join with design BOM to find children of current item
    JOIN [speed_2max].[dbo].design_bom db ON db.parent_item_cde = bh.child_item_cde AND db.parent_item_rev = bh.child_item_rev
    -- Get child item details
    JOIN [speed_2max].[dbo].[item] ci ON ci.item_cde = db.child_item_cde
    JOIN [speed_2max].[dbo].item_revision cir ON ci.item_cde = cir.item_cde AND ci.mfg_rev = cir.item_rev
    JOIN [speed_2max].[dbo].item_type cit ON ci.item_typ_cde = cit.item_typ_cde
    JOIN [speed_2max].[dbo].item_rls_lvl cilvl ON cir.lvl_idn = cilvl.lvl_idn
    WHERE bh.bom_level < 10                                                 -- Prevent infinite recursion
       
        -- Optional filters for cycle prevention (commented out)
        --AND db.child_item_cde <> '000000'
        --AND bh.hierarchy_path NOT LIKE '%/' + db.child_item_cde + '/%'

		-- Filter child items to only include relevant manufacturing stages
		-- This excludes documents and other non-manufacturing item types
		AND cit.item_typ_dsc IN ('UPI_TEST','UPI_ASSEMBLY')
        AND ci.sap_mat_typ = 'FERT'                  -- Only process finished goods
)

-- =====================================================================================
-- POPULATE BOM TEMP TABLE WITH CTE RESULTS
-- Insert the complete BOM hierarchy into our working table
-- =====================================================================================
INSERT INTO #bom_temp
SELECT master_parent_cde,
       child_item_cde,
       child_item_rev,
       child_item_status,
       child_item_type,
       child_item_dsc,
       bom_level,
	   NULL as mm_code_nme,         -- Will be populated later
	   NULL as site_indicator,      -- Will be populated later
	   NULL as order_point,         -- Will be populated later
	   NULL as remark               -- Will be populated later
FROM bom_hier_cte
ORDER BY master_parent_cde, bom_level ASC
OPTION (MAXRECURSION 0);                -- Allow unlimited recursion depth

-- =====================================================================================
-- SECTION 5: EXPAND BOM TO INCLUDE PARENT STAGES
-- Add the parent items of our 'UPI_TEST','UPI_ASSEMBLY' items to get complete manufacturing flow
-- =====================================================================================

-- PUSH NEXT STAGE INTO BOM TO GET THEIR SITE INDICATOR
-- PUSH THE NEXT STAGE OF 'UPI_TEST','UPI_ASSEMBLY' INSIDE BOM

-- Clean up temporary table if it exists
IF OBJECT_ID('tempdb..#item_child_parent_codes') IS NOT NULL
    DROP TABLE #item_child_parent_codes

-- Create table to store parent-child relationships for 'UPI_TEST','UPI_ASSEMBLY' items
CREATE TABLE #item_child_parent_codes(
	master_parent_cde VARCHAR(30),      -- Original master parent
	item_cde VARCHAR(30),               -- 'UPI_TEST','UPI_ASSEMBLY' item code
	item_rev VARCHAR(2)                 -- Item revision
	);

-- GET PARENT CODES FOR 'UPI_TEST','UPI_ASSEMBLY' ITEMS IN BOM
-- Extract all 'UPI_TEST','UPI_ASSEMBLY' items that need their parents added
INSERT INTO #item_child_parent_codes
SELECT master_parent_cde,item_cde,item_rev
FROM #bom_temp
WHERE item_type  IN ('UPI_TEST','UPI_ASSEMBLY')


-- Add parent items of 'UPI_TEST','UPI_ASSEMBLY' items to complete the manufacturing flow
-- These parents represent the upstream manufacturing stages
INSERT INTO #bom_temp (master_parent_cde, item_cde, item_rev, item_status, item_type, item_dsc, bom_level, site_indicator, order_point)
SELECT
    icp.master_parent_cde,              -- Keep original master parent reference
    db.parent_item_cde,                 -- The parent in design_bom is what we want to add
    pi.mfg_rev,                         -- Parent item revision
    pilvl.nme,                          -- Parent item status
    pit.item_typ_dsc,                   -- Parent item type
    pi.dsc,                             -- Parent item description
    0,                                  -- Set to level 0 since these are parents of the starting items
    NULL,                               -- Site indicator to be determined later
    NULL                                -- Order point to be determined later
FROM [speed_2max].[dbo].design_bom db 
JOIN #item_child_parent_codes icp ON db.child_item_cde = icp.item_cde
JOIN [speed_2max].[dbo].item ci ON db.child_item_cde = ci.item_cde AND ci.mfg_rev = icp.item_rev
JOIN [speed_2max].[dbo].item pi ON db.parent_item_cde = pi.item_cde AND db.parent_item_rev = pi.mfg_rev
JOIN [speed_2max].[dbo].item_type pit ON pit.item_typ_cde = pi.item_typ_cde 
JOIN [speed_2max].[dbo].item_revision pir ON pi.item_cde = pir.item_cde AND pi.mfg_rev = pir.item_rev
JOIN [speed_2max].[dbo].item_rls_lvl pilvl ON pilvl.lvl_idn = pir.lvl_idn
WHERE pilvl.nme NOT IN ('INACTIVE', 'DRAFT', 'OBSOLETE')    -- Only include active items

-- =====================================================================================
-- SECTION 6: SITE LOCATION ANALYSIS
-- Determine manufacturing site classifications for each item
-- =====================================================================================

-- GET ITEM LOCATIONS AND SUBCONTRACTOR DETAILS
-- Create table to store site information for each item
CREATE TABLE #item_site ( 
    item_cde VARCHAR(30),               -- Item code
    ext_site_ind CHAR(1),               -- External site indicator (Y/N)
    --siteIdn VARCHAR(10)                 -- Site identifier
);

-- Populate site information by joining item plants with facility data
INSERT INTO #item_site (item_cde, ext_site_ind
--,siteIdn
)
SELECT DISTINCT 
    bom_temp.item_cde,                  -- Item from our BOM
     mp.intel_own_ind as external_ind   -- External/subcontractor indicator
    --facMlc.extsub as external_ind,      -- External/subcontractor indicator
    --facMlc.siteId                       -- Site ID
FROM #bom_temp as bom_temp
JOIN [speed_2max].[dbo].item_plant ip ON bom_temp.item_cde = ip.item_cde
JOIN [speed_2max].[dbo].manufacturing_plant mp ON mp.plnt_idn = ip.plnt_idn
--JOIN [workdb].[dbo].intFacMlc facMlc ON facMlc.siteId = mp.plnt_cde

-- =====================================================================================
-- SECTION 7: SITE INDICATOR CLASSIFICATION
-- Classify items based on their manufacturing site locations
-- I = Internal only, E = External only, M = Mixed (both internal and external)
-- =====================================================================================

-- UPDATE BOM BASED ON SUBCONTRACTOR IND
-- Initially considering all sites are Internal unless found otherwise
-- 3 Level UPDATE FOR PERFORMANCE

-- CLASSIFICATION 1: STRICTLY INTERNAL
-- TO BE STRICTLY INTERNAL ALL PLANTS IN LOCATION NEED TO BE INTERNAL AND NONE EXTERNAL
UPDATE #bom_temp
SET site_indicator = 'I'
WHERE item_cde IN (
    SELECT item_cde 
    FROM #item_site 
    WHERE ext_site_ind = 'N'            -- Has internal sites
) 
AND item_cde NOT IN (
    SELECT item_cde 
    FROM #item_site 
    WHERE ext_site_ind = 'Y'            -- No external sites
)

-- CLASSIFICATION 2: STRICTLY EXTERNAL
-- TO BE STRICTLY EXTERNAL ALL NEED TO BE EXTERNAL AND NONE INTERNAL
UPDATE #bom_temp
SET site_indicator = 'E'
WHERE item_cde IN (
    SELECT item_cde 
    FROM #item_site 
    WHERE ext_site_ind = 'Y'            -- Has external sites
) 
AND item_cde NOT IN (
    SELECT item_cde 
    FROM #item_site 
    WHERE ext_site_ind = 'N'            -- No internal sites
)

-- CLASSIFICATION 3: MIXED SITES
-- TO BE MIXED NEED AT LEAST ONE INTERNAL AND ONE EXTERNAL
UPDATE bt
SET site_indicator = 'M',               -- Mixed classification
    remark = 'MIXED SITE'               -- Add explanatory remark
FROM #bom_temp bt
WHERE EXISTS (
    SELECT 1 
    FROM #item_site 
    WHERE item_cde = bt.item_cde 
    AND ext_site_ind = 'Y'              -- Has external sites
)
AND EXISTS (
    SELECT 1 
    FROM #item_site 
    WHERE item_cde = bt.item_cde 
    AND ext_site_ind = 'N'              -- Has internal sites
)

-- =====================================================================================
-- SECTION 8: SUPPLY CHAIN FILTERING
-- Remove BOM structures that don't meet our supply chain requirements
-- =====================================================================================

-- DELETE THOSE IN WHICH ANY STAGE EXCEPT PARENT IS EXTERNAL
-- Business Rule: We don't want any child stages to be external (only parent can be external)
-- This ensures internal control over critical manufacturing processes
DELETE #bom_temp
WHERE master_parent_cde IN (
	SELECT master_parent_cde
	FROM #bom_temp
	WHERE bom_level > 0                 -- Child levels only (not parent)
	AND site_indicator = 'E'            -- External sites
	)

-- At this point BOM contains only items where child stages are internal or mixed
-- Parent level external sites are still allowed

-- =====================================================================================
-- SECTION 9: ORDER POINT DETERMINATION
-- Determine sourcing strategy based on site analysis
-- B = Buy (all internal), S = Sell (parent external), TBD = To Be Determined
-- =====================================================================================

-- CHECK ALL STAGES INCLUDING PARENT ARE INTERNAL 
-- ORDER POINT 'B' (BUY): ALL STAGES ARE INTERNAL ONLY
-- This means we can manufacture everything internally
UPDATE #bom_temp
SET #bom_temp.order_point = 'B'
WHERE master_parent_cde IN (
	SELECT master_parent_cde
	FROM #bom_temp
	GROUP BY master_parent_cde
	HAVING COUNT(*) = SUM(CASE WHEN site_indicator = 'I' THEN 1 ELSE 0 END)  -- All stages internal
) 
AND item_type IN ('UPI_TEST','UPI_ASSEMBLY');         -- Only update the die prep items

-- ORDER POINT 'S' (SHIPPABLE): PARENT LEVEL HAS EXTERNAL SITES
-- This means we need to source from external suppliers for parent stage
UPDATE #bom_temp
SET #bom_temp.order_point = 'S'
WHERE master_parent_cde IN (
	SELECT master_parent_cde
	FROM #bom_temp
	WHERE bom_level = 0                 -- Parent level only
	GROUP BY master_parent_cde
	HAVING SUM(CASE WHEN site_indicator = 'E' THEN 1 ELSE 0 END) > 0  -- Has external sites
) 
AND item_type IN ('UPI_TEST','UPI_ASSEMBLY');

-- ORDER POINT 'TBD' (TO BE DETERMINED): LOCATION DOESN'T EXIST IN SOME STAGE
-- This means we have incomplete site information and need further analysis
UPDATE #bom_temp
SET #bom_temp.order_point = 'TBD'
WHERE master_parent_cde IN (
	SELECT master_parent_cde
	FROM #bom_temp
	GROUP BY master_parent_cde
	HAVING SUM(CASE WHEN site_indicator IS NULL THEN 1 ELSE 0 END) > 0  -- Missing site info
) 
AND item_type IN ('UPI_TEST','UPI_ASSEMBLY');

-- =====================================================================================
-- SECTION 10: DATA ENRICHMENT
-- Add additional attributes to enhance the analysis
-- =====================================================================================

-- ATTACH ATTRIBUTES TO IT (MM-CODE-NAME)
-- Add MM code name attribute from user-defined attributes
-- This provides additional item classification information
UPDATE #bom_temp
SET mm_code_nme = uda_i.val_txt
FROM #bom_temp bom
LEFT JOIN [speed_2max].[dbo].uda_item uda_i ON uda_i.item_cde = bom.item_cde
LEFT JOIN [speed_2max].[dbo].uda_definition uda_def ON uda_def.att_idn = uda_i.att_idn
WHERE uda_def.att_nme = 'MM-CODE-NAME';

-- =====================================================================================
-- SECTION 11: FINAL OUTPUT
-- Display the complete analyzed BOM with all classifications and recommendations
-- =====================================================================================

-- Final output showing complete BOM hierarchy with site analysis and sourcing recommendations
SELECT * FROM #bom_temp
ORDER BY master_parent_cde, bom_level ASC, item_cde

-- =====================================================================================
-- OUTPUT COLUMNS EXPLANATION:
-- master_parent_cde: Original top-level item being analyzed
-- item_cde: Current item code in the BOM
-- item_rev: Item revision
-- item_status: Item release status
-- item_type: Manufacturing stage type ('UPI_TEST','UPI_ASSEMBLY')
-- item_dsc: Item description
-- bom_level: Hierarchy level (0=parent, 1=starting item, 2+=children)
-- mm_code_nme: MM code classification
-- site_indicator: I=Internal, E=External, M=Mixed, NULL=Unknown
-- order_point: B=Buy(Internal), S=Sell(External), TBD=To Be Determined
-- remark: Additional notes (e.g., "MIXED SITE")
-- =====================================================================================