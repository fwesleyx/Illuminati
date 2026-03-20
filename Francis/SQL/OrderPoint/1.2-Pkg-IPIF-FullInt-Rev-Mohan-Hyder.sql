USE speed
GO

-- Drop temp tables if they exist
DROP TABLE IF EXISTS #ItemHierarchy;
DROP TABLE IF EXISTS #ItemHierarchyFiltered;
DROP TABLE IF EXISTS #fg_parent_item;
DROP TABLE IF EXISTS #bom_temp;
DROP TABLE IF EXISTS #item_site;

-- Create the hierarchy table with larger column sizes
CREATE TABLE #ItemHierarchy 
(
  fg_item_cde VARCHAR(25),
  fg_item_rev CHAR(2),
  fg_item_dsc VARCHAR(200),        
  fg_item_typ_cde VARCHAR(25),
  fg_item_sap_mat_typ VARCHAR(40),
  fg_item_typ_dsc VARCHAR(100),    
  
  test_item_cde VARCHAR(25),
  test_item_dsc VARCHAR(200),     
  test_item_typ_cde VARCHAR(25),
  test_item_sap_mat_typ VARCHAR(40),
  test_item_typ_dsc VARCHAR(100),  
  
  assy_item_cde VARCHAR(25),
  assy_item_rev CHAR(2),
  assy_item_dsc VARCHAR(200),     
  assy_item_typ_cde VARCHAR(25),
  assy_item_sap_mat_typ VARCHAR(40),
  assy_item_typ_dsc VARCHAR(100),
  item_status VARCHAR(30),            -- Item status (PRODN_APPROVED, etc.) 
  assy_upi_test VARCHAR(40) DEFAULT NULL,
  assy_upi_assembly VARCHAR(100) DEFAULT NULL
);


-- CREATE TEMP TABLE TO STORE BOM AND SITE IND
CREATE TABLE #bom_temp (
    master_parent_cde VARCHAR(30),      -- Top-level parent item code
    item_cde VARCHAR(30),               -- Current item code
    item_rev VARCHAR(3),                -- Item revision
    item_status VARCHAR(30),            -- Item status
    item_type VARCHAR(30),              -- Item type description
    item_dsc VARCHAR(500),               -- Item description
    bom_level INT,                      -- Hierarchy level (0=parent, 1=child, etc.)
	mm_code_nme VARCHAR(40) DEFAULT NULL,   -- MM code name attribute
	site_indicator CHAR(1) DEFAULT NULL,    -- Site classification (I/E/M)
	order_point CHAR(3) DEFAULT NULL,       -- Order point recommendation (B/S/TBD)
	remark VARCHAR(MAX) DEFAULT NULL        -- Additional remarks
);

-- GET ITEM LOCATIONS AND SUBCONTRACTOR DETAILS
-- Create table to store site information for each item
CREATE TABLE #item_site ( 
    item_cde VARCHAR(30),               -- Item code
    ext_site_ind CHAR(1),               -- External site indicator (Y/N)
    --siteIdn VARCHAR(10)                 -- Site identifier
);
INSERT INTO #ItemHierarchy (
	fg_item_cde, fg_item_rev, fg_item_dsc, fg_item_typ_cde, fg_item_sap_mat_typ, fg_item_typ_dsc,
	test_item_cde, test_item_dsc, test_item_typ_cde, test_item_sap_mat_typ, test_item_typ_dsc,
	assy_item_cde, assy_item_rev, assy_item_dsc, assy_item_typ_cde, item_status, assy_item_sap_mat_typ, assy_item_typ_dsc
)
SELECT 
	  b.parent_item_cde		as fg_item_cde
	, b.parent_item_rev		as fg_item_rev
	, p.dsc_full			as fg_item_dsc
	, p.item_typ_cde		as fg_item_typ_cde
	, p.sap_mat_typ			as fg_item_sap_mat_typ
	, pit.item_typ_dsc		as fg_item_typ_dsc
	, b.child_item_cde		as test_item_cde
	, c.dsc_full			as test_item_dsc
	, c.item_typ_cde		as test_item_typ_cde
	, c.sap_mat_typ			as test_item_sap_mat_typ
	, cit.item_typ_dsc		as test_item_typ_dsc
 
	, b1.child_item_cde		as assy_item_cde
	, b1.parent_item_rev	as assy_item_rev
	, c1.dsc_full			as assy_item_dsc
	, c1.item_typ_cde		as assy_item_typ_cde
	, c1.sap_mat_typ		as assy_item_sap_mat_typ
	, c1it.item_typ_dsc		as assy_item_typ_dsc
    , ilvl1.nme             as item_status
FROM
	dbo.design_bom b
	JOIN dbo.item p ON b.parent_item_cde = p.item_cde
		AND b.parent_item_rev = p.mfg_rev
	JOIN item_type pit ON pit.item_typ_cde = p.item_typ_cde
	JOIN dbo.item c ON b.child_item_cde = c.item_cde
	JOIN dbo.item_type cit ON c.item_typ_cde = cit.item_typ_cde
    JOIN [dbo].item_revision ir ON p.item_cde = ir.item_cde AND p.mfg_rev = ir.item_rev
    JOIN [dbo].bus_unit_dsgn_grp budg ON budg.bus_unit_idn = ir.bus_unit_idn
    JOIN [speed_2max].[dbo].item_rls_lvl ilvl ON ir.lvl_idn = ilvl.lvl_idn 

	JOIN dbo.design_bom b1 ON b.child_item_cde = b1.parent_item_cde
		AND c.mfg_rev = b1.parent_item_rev
	JOIN dbo.item c1 ON b1.child_item_cde = c1.item_cde
	JOIN dbo.item_type c1it ON c1.item_typ_cde = c1it.item_typ_cde
    JOIN [dbo].item_revision ir1 ON p.item_cde = ir1.item_cde AND p.mfg_rev = ir1.item_rev
	JOIN [speed_2max].[dbo].item_rls_lvl ilvl1 ON ir1.lvl_idn = ilvl1.lvl_idn 

WHERE
	p.sap_mat_typ = 'FERT' AND
    c1it.item_typ_dsc IN ('UPI_TEST','UPI_ASSEMBLY') 
      AND budg.short_nme IN ('IA','CIG')
    AND ilvl.nme NOT IN ('INACTIVE','DRAFT','OBSOLETE')  
    AND ilvl.nme = 'PRODN_APPROVED'

    update tgt 
    set tgt.assy_upi_assembly= src.val_txt
    from #ItemHierarchy tgt 
    join [speed_2max].[dbo].uda_item src on src.item_cde= tgt.assy_item_cde
    join [speed_2max].[dbo].uda_definition def on def.att_idn = src.att_idn and def.att_nme='SUBASSY_PROD_ENGNR_CD'

    update tgt 
    set tgt.assy_upi_test= src.val_txt
    from #ItemHierarchy tgt 
    join [speed_2max].[dbo].uda_item src on src.item_cde= tgt.test_item_cde
    join [speed_2max].[dbo].uda_definition def on def.att_idn = src.att_idn and def.att_nme='SUBASSY_PROD_ENGNR_CD'

    DELETE from #ItemHierarchy  
    where  assy_upi_test != 'PRODUCTION' or assy_upi_assembly!= 'PRODUCTION';
    --select * from #ItemHierarchy order by fg_item_cde
-- POPULATE BOM_TEMP with hierarchy data
INSERT INTO #bom_temp (
    master_parent_cde,
    item_cde,
    item_rev,
    item_status,
    item_type,
    item_dsc,
    bom_level,
    site_indicator,
    order_point,
    remark
)
SELECT 
    fg_item_cde as master_parent_cde,
    fg_item_cde as item_cde,
    fg_item_rev as item_rev, 
    item_status as item_status,
    fg_item_typ_dsc as item_type,
    fg_item_dsc as item_dsc,
    0 as bom_level,
    NULL as site_indicator,
    NULL as order_point,
    NULL as remark 
FROM #ItemHierarchy

-- =====================================================================================
-- SECTION 6: SITE LOCATION ANALYSIS
-- Determine manufacturing site classifications for each item
-- =====================================================================================


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
--UPDATE #bom_temp
--SET #bom_temp.order_point = 'B'
--WHERE master_parent_cde IN (
--	SELECT master_parent_cde
--	FROM #bom_temp
--	GROUP BY master_parent_cde
--	HAVING COUNT(*) = SUM(CASE WHEN site_indicator = 'I' THEN 1 ELSE 0 END)  -- All stages internal
--) 
--AND item_type IN ('UPI_TEST','UPI_ASSEMBLY');         -- Only update the die prep items

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
AND item_type IN ('FERT');

UPDATE #bom_temp
SET #bom_temp.order_point = 'S'
WHERE master_parent_cde IN (
	SELECT master_parent_cde
	FROM #bom_temp
	WHERE bom_level = 0                 -- Parent level only
	GROUP BY master_parent_cde
	HAVING SUM(CASE WHEN site_indicator = 'E' THEN 1 ELSE 0 END) > 0  -- Has external sites
) 
AND item_type IN ('UPI');

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
AND item_type IN ('FERT');

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