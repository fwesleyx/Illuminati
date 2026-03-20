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
  assy_upi_test VARCHAR(40) DEFAULT NULL,
  assy_upi_assembly VARCHAR(100) DEFAULT NULL
  --test_has_any_ext_plnt_ind CHAR(1),
  --assy_has_any_ext_plnt_ind CHAR(1) 
);
CREATE TABLE #ItemHierarchyFiltered 
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

  --test_has_any_ext_plnt_ind CHAR(1),
  --assy_has_any_ext_plnt_ind CHAR(1) 
);

-- CREATE TEMP TABLE TO STORE BOM AND SITE IND
CREATE TABLE #bom_temp (
    master_parent_cde VARCHAR(30),
    item_cde VARCHAR(30),
    item_rev VARCHAR(3),
    item_type VARCHAR(30),
    item_dsc VARCHAR(200),
    bom_level INT,
    mm_code_nme VARCHAR(40) DEFAULT NULL,
    site_indicator CHAR(1) DEFAULT NULL,
    order_point CHAR(3) DEFAULT NULL,
    remark VARCHAR(MAX) DEFAULT NULL
);

-- CREATE ITEM SITE TABLE
CREATE TABLE #item_site ( 
    item_cde VARCHAR(30), 
    ext_site_ind CHAR(1), 
    siteIdn VARCHAR(10)
);


INSERT INTO #ItemHierarchy (
	fg_item_cde, fg_item_rev, fg_item_dsc, fg_item_typ_cde, fg_item_sap_mat_typ, fg_item_typ_dsc,
	test_item_cde, test_item_dsc, test_item_typ_cde, test_item_sap_mat_typ, test_item_typ_dsc,
	assy_item_cde, assy_item_rev, assy_item_dsc, assy_item_typ_cde, assy_item_sap_mat_typ, assy_item_typ_dsc
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


WHERE
	p.sap_mat_typ = 'FERT' AND
    c1it.item_typ_dsc IN ('UPI_TEST','UPI_ASSEMBLY') 
      AND budg.short_nme IN ('IA','CIG')
    AND ilvl.nme NOT IN ('INACTIVE','DRAFT','OBSOLETE')  
    AND ilvl.nme = 'PRODN_APPROVED'
    --AND def.att_nme = 'SUBASSY_PROD_ENGNR_CD'
    --AND udaItem.val_txt in ('PRODUCTION')
    select top 100 * from #ItemHierarchy

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
     --select top 100 * from #ItemHierarchy

-- POPULATE BOM_TEMP with hierarchy data
INSERT INTO #bom_temp (
    master_parent_cde,
    item_cde,
    item_rev,
    item_type,
    item_dsc,
    bom_level,
    site_indicator,
    order_point
)
SELECT 
    fg_item_cde as master_parent_cde,
    fg_item_cde as item_cde,
    fg_item_rev as item_rev, 
    fg_item_typ_dsc as item_type,
    fg_item_dsc as item_dsc,
    0 as bom_level,
    NULL as site_indicator,
    NULL as order_point
FROM #ItemHierarchy

select * from #bom_temp

-- GET ITEM LOCATIONS AND SUBCONTRACTOR DETAILS
INSERT INTO #item_site (item_cde, ext_site_ind, siteIdn)
SELECT DISTINCT 
    bom_temp.item_cde,
    CASE WHEN mp.intel_own_ind = 'N' THEN 'Y' ELSE 'N' END as external_ind, 
    mp.plnt_cde as siteId
FROM #bom_temp as bom_temp
JOIN dbo.item_plant ip ON bom_temp.item_cde = ip.item_cde
JOIN dbo.manufacturing_plant mp ON mp.plnt_idn = ip.plnt_idn;

-- UPDATE BOM BASED ON SUBCONTRACTOR IND
-- Initially considering all sites are Internal unless found otherwise

-- TO BE STRICTLY INTERNAL ALL PLANTS IN LOCATION NEED TO BE INTERNAL AND NONE EXTERNAL
UPDATE #bom_temp
SET site_indicator = 'I'
WHERE item_cde IN (SELECT item_cde FROM #item_site WHERE ext_site_ind = 'N') 
  AND item_cde NOT IN (SELECT item_cde FROM #item_site WHERE ext_site_ind = 'Y');

-- TO BE STRICTLY EXTERNAL ALL NEED IN EXTERNAL AND NONE IN INTERNAL
UPDATE #bom_temp
SET site_indicator = 'E'
WHERE item_cde IN (SELECT item_cde FROM #item_site WHERE ext_site_ind = 'Y') 
  AND item_cde NOT IN (SELECT item_cde FROM #item_site WHERE ext_site_ind = 'N');


-- At this point BOM contains only Parent Level External Sites 

-- CHECK ALL STAGES INCLUDING PARENT ARE INTERNAL 
-- ALL STAGES ARE INTERNAL ONLY
UPDATE #bom_temp
SET order_point = 'B'
WHERE master_parent_cde IN (
    SELECT master_parent_cde
    FROM #bom_temp
    GROUP BY master_parent_cde
    HAVING COUNT(*) = SUM(CASE WHEN site_indicator = 'I' THEN 1 ELSE 0 END)
) AND item_type = 'UPI_TEST';  

UPDATE #bom_temp
SET order_point = 'S'
WHERE master_parent_cde IN (
    SELECT master_parent_cde
    FROM #bom_temp
    WHERE bom_level = 0
    GROUP BY master_parent_cde
    HAVING SUM(CASE WHEN site_indicator = 'E' THEN 1 ELSE 0 END) > 0
) AND item_type = 'UPI_TEST';

-- LOCATION DOESN'T EXIST IN SOME STAGE
UPDATE #bom_temp
SET order_point = 'TBD'
WHERE master_parent_cde IN (
    SELECT master_parent_cde
    FROM #bom_temp
    GROUP BY master_parent_cde
    HAVING SUM(CASE WHEN site_indicator IS NULL THEN 1 ELSE 0 END) > 0
) AND item_type = 'UPI_TEST';

 ---Your existing hierarchy updates
ALTER TABLE #ItemHierarchy ADD test_has_any_ext_plnt_ind CHAR(1) DEFAULT 'N';
ALTER TABLE #ItemHierarchy ADD assy_has_any_ext_plnt_ind CHAR(1) DEFAULT 'N';

UPDATE #ItemHierarchy SET test_has_any_ext_plnt_ind = 'N', assy_has_any_ext_plnt_ind = 'N';

UPDATE tgt
SET tgt.test_has_any_ext_plnt_ind = 'Y'
FROM #ItemHierarchy tgt
JOIN dbo.item_plant p ON tgt.test_item_cde = p.item_cde
JOIN dbo.manufacturing_plant m ON p.plnt_idn = m.plnt_idn
WHERE m.intel_own_ind = 'N';

UPDATE tgt
SET tgt.assy_has_any_ext_plnt_ind = 'Y'
FROM #ItemHierarchy tgt
JOIN dbo.item_plant p ON tgt.assy_item_cde = p.item_cde
JOIN dbo.manufacturing_plant m ON p.plnt_idn = m.plnt_idn
WHERE m.intel_own_ind = 'N';

------------
---- Update test_has_any_ext_plnt_ind for external plants
--UPDATE #ItemHierarchy 
--SET test_has_any_ext_plnt_ind = 'Y'
--WHERE test_item_cde IN (
--    SELECT DISTINCT p.item_cde
--    FROM dbo.item_plant p
--    JOIN dbo.manufacturing_plant m ON p.plnt_idn = m.plnt_idn
--    WHERE m.intel_own_ind = 'N'
--);

---- Update assy_has_any_ext_plnt_ind for external plants
--UPDATE #ItemHierarchy 
--SET assy_has_any_ext_plnt_ind = 'Y'
--WHERE assy_item_cde IN (
--    SELECT DISTINCT p.item_cde
--    FROM dbo.item_plant p
--    JOIN dbo.manufacturing_plant m ON p.plnt_idn = m.plnt_idn
--    WHERE m.intel_own_ind = 'N'
--);

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

-- ORDER POINT 'S' (SELL): PARENT LEVEL HAS EXTERNAL SITES
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

SELECT 
    DISTINCT 
        fg_item_cde,
        fg_item_rev, 
        '' order_point_ind
    INTO #fg_parent_item
FROM #ItemHierarchy;

-- Final results
SELECT * FROM #ItemHierarchy;
SELECT * FROM #fg_parent_item;
SELECT * FROM #bom_temp ORDER BY master_parent_cde, bom_level ASC, item_cde;
