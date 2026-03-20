------------------------------------------------------------------------------------
--	CLEAR WATER FOREST PAPER MODEL DATA LOAD SCRIPT
--	Flow: IP FLOW
--	Purpose: Migrate item and BOM data from legacy system to new PDM system
--	Author: System Migration Team
--	Date: [Current Date]
--	
--	Description: This script performs a complete migration of paper model items
--	from the old numbering system (2000-xxx-xxx) to new system (2001-005-xxx)
--	while preserving all BOM relationships and item attributes.
------------------------------------------------------------------------------------
USE Pdm
GO

-- Set SQL Server session options for consistent behavior
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
SET NOCOUNT ON		-- Suppress row count messages for better performance
GO

------------------------------------------------------------------------------------
-- PROCEDURE: #LoadItemDescription
-- Purpose: Load item codes with their corresponding descriptions
-- Parameters: @debug - 'Y' for debug mode, 'N' for production
------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE #LoadItemDescription (@debug CHAR(1) = 'Y') AS
BEGIN
	-- Insert new item codes with their descriptions
	-- These are the target items in the new numbering system
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-001', '478CMT4VBB0'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-002', '478CMT3VBBZ'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-003', '478CMT4VB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-004', '478CMT3VB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-005', 'S8PD6AVE'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-006', 'S8PD6CVE'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-007', '8PD6CVE'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-008', 'B8PZG4VB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-009', 'B8PZG3VB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-010', 'B8PZGFVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-011', 'B8PZGGVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-012', 'B8PZGDVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-013', 'B8PZGEVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-014', 'S8PZGAVCA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-015', 'S8PZGBVCA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-016', 'S8LF3KVA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-017', 'S8LF7KVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-018', 'S8PYZPVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-019', 'S8PYZGVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-020', 'S8PYZBVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-021', 'S8PYZSVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-022', 'S8PYZSVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-023', 'S8LBLKVA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-024', 'S8PYZAVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-025', 'S8PYZBVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-026', 'S8PYZFVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-027', 'S8PZGCVCA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-028', 'S8LF3CVA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-029', 'S8LF7CVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-030', 'S8LBLCVA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-031', 'S8PYZCVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-032', '8PZGCVCA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-033', '8LF3CVA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-034', '8LF7CVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-035', '8LBLCVA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-036', '8PYZCVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-046', 'S8PD68VE'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-047', 'S8PD6SVE'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-048', 'S8PD61VE'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-049', 'S8PZGRVCA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-050', 'S8LF3RVA'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-051', 'S8PYZ1VB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2001-005-052', 'S8PYZ8VB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '99Z101', 'CWFAPXDCC2PLCHLDRRVCW'  -- Top-level assembly item

END
GO

------------------------------------------------------------------------------------
-- PROCEDURE: #LoadMappingTable
-- Purpose: Create mapping between old item codes and new item codes with classifications
-- Parameters: @debug - 'Y' for debug mode, 'N' for production
-- 
-- Item Classifications:
-- CPU - Central Processing Unit (top level)
-- P_TEST - Test items
-- P_ASSEMBLY - Assembly items  
-- P_DIE_PREP - Die preparation items
-- P_SORT - Sorting items
-- P_FAB - Fabrication items
-- P_STACK_SILICON - Silicon stacking items
-- P_STACK_COMBO - Combination stacking items
------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE #LoadMappingTable (@debug CHAR(1) = 'Y') AS 
BEGIN
	-- Load the core mapping data from old item codes to new item codes
	-- Each mapping includes the new item classification
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-181', '99Z101', 'CPU'				-- Top level CPU item
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-955', '2001-005-001', 'P_TEST'		-- Test items
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-416', '2001-005-002', 'P_TEST'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-331-544', '2001-005-003', 'P_ASSEMBLY'	-- Assembly items
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-331-538', '2001-005-004', 'P_ASSEMBLY'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-101', '2001-005-005', 'P_DIE_PREP'	-- Die preparation items
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-100', '2001-005-006', 'P_SORT'		-- Sorting items
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-103', '2001-005-007', 'P_FAB'		-- Fabrication items
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-174', '2001-005-008', 'P_STACK_SILICON'	-- Silicon stacking
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-175', '2001-005-009', 'P_STACK_SILICON'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-168', '2001-005-010', 'P_STACK_COMBO'	-- Combination stacking
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-165', '2001-005-011', 'P_STACK_COMBO'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-164', '2001-005-012', 'P_STACK_COMBO'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-170', '2001-005-013', 'P_STACK_COMBO'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-253', '2001-005-014', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-256', '2001-005-015', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-308-374', '2001-005-016', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-417', '2001-005-017', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-161', '2001-005-018', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-162', '2001-005-019', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-160', '2001-005-020', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-163', '2001-005-021', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-138', '2001-005-022', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-309-093', '2001-005-023', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-954', '2001-005-024', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-139', '2001-005-025', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-137', '2001-005-026', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-255', '2001-005-027', 'P_SORT'		-- Sorting items
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-308-373', '2001-005-028', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-415', '2001-005-029', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-309-095', '2001-005-030', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-953', '2001-005-031', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-251', '2001-005-032', 'P_FAB'		-- Fabrication items
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-308-372', '2001-005-033', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-416', '2001-005-034', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-309-094', '2001-005-035', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-955', '2001-005-036', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-099', '2001-005-046', 'P_DIE_PREP'	-- Additional die prep items
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-102', '2001-005-047', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-104', '2001-005-048', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-252', '2001-005-049', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-956', '2001-005-050', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-326-741', '2001-005-051', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-326-742', '2001-005-052', 'P_DIE_PREP'

	-- Enrich mapping data with information from source system
	-- Get old item classification and material type information
	UPDATE tgt
			SET tgt.OldItemClassCd = src.item_typ_cde					-- Item type code from source
				, tgt.OldItemClassDsc = ic.item_typ_dsc					-- Item type description
				, tgt.OldItemExistsInSourceDB = 'Y'						-- Flag that item exists in source
				, tgt.OldItemMaterialTypeCd = src.sap_mat_typ			-- SAP material type code
				, tgt.OldItemMaterialTypeNm = mt.sap_mat_typ_nme		-- SAP material type name
		FROM
			#ItemMapping tgt
			JOIN SPDREAD2.speed_2max.dbo.item src WITH (NOLOCK) ON tgt.OldItemCd = src.item_cde
			JOIN SPDREAD2.speed_2max.dbo.item_type ic WITH (NOLOCK) ON src.item_typ_cde = ic.item_typ_cde
			JOIN SPDREAD2.speed_2max.dbo.sap_material_type mt WITH (NOLOCK) ON src.sap_mat_typ = mt.sap_mat_typ

	-- Map new item class descriptions to class codes in target system
	UPDATE tgt
		SET tgt.NewItemClassCd = ic.ClassCd
	FROM
		#ItemMapping tgt
		JOIN ItemBom.ItemClass ic ON tgt.NewItemClassDsc = ic.ClassDsc

	-- Set material type for new items based on their class
	UPDATE tgt
		SET tgt.NewItemMaterialTypeCd = m.MaterialTypeCd
			, tgt.NewItemMaterialTypeNm = m.MaterialTypeNm
				
	FROM
		#ItemMapping tgt
		JOIN ItemBom.RefMaterialTypeItemClass cm ON tgt.NewItemClassCd = cm.ClassCd
		JOIN ItemBom.RefMaterialType m ON cm.MaterialTypeCd = m.MaterialTypeCd

	-- Check if new items already exist in target database
	UPDATE tgt
		SET tgt.NewItemExistsInTargetDB = 'Y'
	FROM
		#ItemMapping tgt
		JOIN ItemBom.Item src ON tgt.NewItemCd = src.ItemCd
	SELECT @@ROWCOUNT as NewItemExistsInTargetDBCount		-- Return count for logging
END
GO

------------------------------------------------------------------------------------
-- PROCEDURE: #LoadBomData
-- Purpose: Load Bill of Materials relationships between items
-- Parameters: @debug - 'Y' for debug mode, 'N' for production
--
-- BOM Association Types:
-- NORMAL - Standard parent-child relationship
-- ALTERNATE - Alternative component that can be substituted
------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE #LoadBomData (@debug CHAR(1) = 'Y') AS
BEGIN
	
	-- Create temporary table for BOM ID generation
	-- This is used to generate unique BOM identifiers
	DROP TABLE IF EXISTS #BomIdGenerator
	CREATE TABLE #BomIdGenerator
	(
		  BomIdGeneratorId	INT IDENTITY		-- Auto-incrementing ID
		, Idn				INT					-- Original BOM record ID
		, NewBomId			BIGINT				-- Generated BOM ID
	)

	-- Variables for BOM ID generation
	DECLARE 
		   @MaxBomIdn	INT						-- Maximum BOM ID from system
		 , @LastIdn		INT						-- Last used ID
		 , @MaxRow		INT = 20				-- Maximum rows to process (unused)
		 , @BomCount	INT						-- Count of BOMs to create

	-- Load BOM relationships - Top level CPU to test items
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '99Z101', '01', '2001-005-001', 'NORMAL', 1		-- CPU -> Test item (normal)
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '99Z101', '01', '2001-005-002', 'ALTERNATE', 1	-- CPU -> Test item (alternate)
	
	-- Test items to assembly items
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-001', '01', '2001-005-003', 'NORMAL', 1	-- Test -> Assembly
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-001', '01', '2001-005-004', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-002', '01', '2001-005-003', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-002', '01', '2001-005-004', 'NORMAL', 1
	
	-- Assembly items to die prep and stacking items
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-003', '01', '2001-005-005', 'NORMAL', 2	-- Assembly -> Die prep (qty 2)
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-003', '01', '2001-005-008', 'NORMAL', 3	-- Assembly -> Stack silicon (qty 3)
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-004', '01', '2001-005-005', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-004', '01', '2001-005-009', 'NORMAL', 3
	
	-- Die prep to sort items
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-005', '01', '2001-005-006', 'NORMAL', 1	-- Die prep -> Sort
	
	-- Sort to fab items
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-006', '01', '2001-005-007', 'NORMAL', 1	-- Sort -> Fab
	
	-- Stack silicon items to stack combo items (with alternates)
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-008', '01', '2001-005-010', 'NORMAL', 1		-- Stack silicon -> Stack combo (normal)
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-008', '01', '2001-005-011', 'ALTERNATE', 1	-- Stack silicon -> Stack combo (alternate)
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-009', '01', '2001-005-012', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-009', '01', '2001-005-013', 'ALTERNATE', 1
	
	-- Stack combo items to various die prep items (complex relationships with multiple quantities)
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-010', '01', '2001-005-015', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-010', '01', '2001-005-016', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-010', '01', '2001-005-017', 'NORMAL', 2		-- Quantity 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-010', '01', '2001-005-018', 'NORMAL', 4		-- Quantity 4
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-011', '01', '2001-005-015', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-011', '01', '2001-005-016', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-011', '01', '2001-005-017', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-011', '01', '2001-005-018', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-011', '01', '2001-005-019', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-012', '01', '2001-005-014', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-012', '01', '2001-005-016', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-012', '01', '2001-005-017', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-012', '01', '2001-005-020', 'NORMAL', 4
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-013', '01', '2001-005-014', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-013', '01', '2001-005-016', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-013', '01', '2001-005-017', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-013', '01', '2001-005-020', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-013', '01', '2001-005-021', 'NORMAL', 2
	
	-- Die prep items to sort items
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-014', '01', '2001-005-027', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-015', '01', '2001-005-027', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-016', '01', '2001-005-028', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-017', '01', '2001-005-029', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-018', '01', '2001-005-022', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-019', '01', '2001-005-024', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-020', '01', '2001-005-025', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-021', '01', '2001-005-026', 'NORMAL', 1
	
	-- Sort items to fab items
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-027', '01', '2001-005-032', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-028', '01', '2001-005-033', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-029', '01', '2001-005-034', 'NORMAL', 1
	
	-- Various items converging to common sort item
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-022', '01', '2001-005-031', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-024', '01', '2001-005-031', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-025', '01', '2001-005-031', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-026', '01', '2001-005-031', 'NORMAL', 1
	
	-- Final sort to fab relationship
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-031', '01', '2001-005-036', 'NORMAL', 1

	-- Map BOM association names to BOM type codes
	UPDATE tgt
		SET tgt.BomTypeCd = src.BomTypeCd
	FROM
		#BillOfMaterial tgt
		JOIN ItemBom.RefBomType src ON tgt.BomAssociationNm = src.BomAssociationNm

	-- Check for existing BOM relationships and mark them as READ operations
	UPDATE tgt
		SET tgt.BomId = src.BomId
			, tgt.CrudType = 'READ'				-- Mark as existing record
	FROM
		#BillOfMaterial tgt
		JOIN ItemBom.BillOfMaterial src ON tgt.ParentItemCd = src.ParentItemCd
			AND tgt.ParentItemRevision = src.ParentItemRevision
			AND tgt.ChildItemCd = src.ChildItemCd
			AND tgt.BomTypeCd = src.BomTypeCd
			AND tgt.BomFindNbr = src.BomFindNbr
	SELECT @@ROWCOUNT as ExistingBomCount

	-- Generate BOM IDs for new records
	IF @debug = 'Y'
	BEGIN
		-- In debug mode, use negative test IDs
		UPDATE #BillOfMaterial SET BomId = Idn * -1000
	END
	ELSE
	BEGIN
		-----------------------------------------------------------
		-------------- GENERATE BOM IDNs	-----------------------
		-----------------------------------------------------------
		-- Get records that need new BOM IDs
		INSERT INTO #BomIdGenerator(Idn)
		SELECT Idn FROM #BillOfMaterial WHERE CrudType = 'CREATE' ORDER BY Idn
		SELECT @BomCount = @@ROWCOUNT 
		
		-- Call system procedure to get next available BOM ID range
		EXEC espeed.dbo.sp_scrty_rtn_next_idn 'BOM', @MaxBomIdn OUTPUT, @LastIdn OUTPUT, @BomCount
		SELECT @MaxBomIdn as [@MaxBomIdn], @LastIdn as [@LastIdn], @BomCount as [@BomCount]
		
		-- Assign sequential BOM IDs starting from the reserved range
		UPDATE #BomIdGenerator SET NewBomId = BomIdGeneratorId + @MaxBomIdn
		
		-- Update the BOM records with their new IDs
		UPDATE tgt
			SET tgt.BomId = src.NewBomId
		FROM
			#BillOfMaterial tgt
			JOIN #BomIdGenerator src ON tgt.Idn = src.Idn
	END
END
GO

------------------------------------------------------------------------------------
-- MAIN EXECUTION BLOCK
-- This is the primary execution logic that orchestrates the entire migration
------------------------------------------------------------------------------------
BEGIN
	BEGIN TRY
		-- Configuration variables
		DECLARE
			  @debug					CHAR(1)	= 'Y'				-- Set to 'N' for production run
			, @ServerEnvironment		VARCHAR(100)				-- Server environment (unused)
			, @RunDate					DATETIME = GETDATE()		-- Current execution timestamp
			, @UpdateAccountCd			CHAR(8) = 'SYSTEM'			-- Account code for audit trail
			, @BackupDone				CHAR(1) = 'N'				-- Backup status flag (unused)
			, @BackUpCount				INT = 0						-- Backup count (unused)

		------------------------------------------------------------------------------------
		-- CREATE TEMPORARY TABLES FOR DATA STAGING
		------------------------------------------------------------------------------------
		
		-- Table to map old items to new items with metadata
		DROP TABLE IF EXISTS #ItemMapping
		CREATE TABLE #ItemMapping(
				  Idn						INT IDENTITY			-- Unique identifier
				, OldItemCd					VARCHAR(21)				-- Source system item code
				, OldItemClassCd			VARCHAR(4)				-- Source item classification
				, OldItemClassDsc			VARCHAR(18)				-- Source item class description
				, OldItemMaterialTypeCd		VARCHAR(4)				-- Source material type code
				, OldItemMaterialTypeNm		VARCHAR(30)				-- Source material type name
				, OldItemExistsInSourceDB	CHAR(1) DEFAULT 'N'		-- Flag: item exists in source
				, NewItemCd					VARCHAR(21)				-- Target system item code
				, NewItemClassCd			VARCHAR(4)				-- Target item classification
				, NewItemClassDsc			VARCHAR(18)				-- Target item class description
				, NewItemMaterialTypeCd		VARCHAR(4)				-- Target material type code
				, NewItemMaterialTypeNm		VARCHAR(30)				-- Target material type name
				, NewItemExistsInTargetDB	CHAR(1) DEFAULT 'N'		-- Flag: item exists in target
				)

		-- Main item master data table
		DROP TABLE IF EXISTS #Item
		CREATE TABLE #Item(
			  Idn					INT IDENTITY				-- Unique identifier
			, ItemCd				VARCHAR(21)					-- Item code (primary key)
			, ItemDsc				NVARCHAR(255)				-- Full item description
			, ItemDscShort			VARCHAR(40)					-- Short description (40 char limit)
			, ForecastDsc			VARCHAR(255)				-- Forecast description
			, ClassCd				CHAR(4)						-- Item classification code
			, MaterialTypeCd		CHAR(4)						-- Material type code
			, CommodityCd			CHAR(10)					-- Commodity classification
			, EngineeringRevision	CHAR(2)						-- Engineering revision level
			, ManufacturingRevision	CHAR(2)						-- Manufacturing revision level
			, UnitOfMeasureCd		CHAR(3)						-- Unit of measure (EA, LB, etc.)
			, UnitOfWeightCd		CHAR(3)						-- Weight unit of measure
			, NetWeight				NUMERIC(12, 5)				-- Net weight value
			, GrossWeight			NUMERIC(12, 5)				-- Gross weight value
			, OwningSystemCd		CHAR(3)						-- System that owns this item
			, RoyaltyCd				CHAR(2)						-- Royalty classification
			, MakeBuyCd				CHAR(1)						-- Make vs Buy indicator
			, CustomStandardId		INT							-- Custom/Standard classification
			, DuplicateReasonId		SMALLINT					-- Reason for duplicate items
			, RecommendedCd			CHAR(1)						-- Recommended item flag
			, ItemStatusRestriction	CHAR(1)						-- Status restriction code
			, ItemRecommendId		INT							-- Recommended item reference
			, StandardCost			NUMERIC(12, 5)				-- Standard cost value
			, MigrationStatusNm		VARCHAR(40)					-- Migration status description
			, DivisionId			TINYINT						-- Division identifier
			, CrudType				VARCHAR(10) DEFAULT 'CREATE'-- Operation type (CREATE/UPDATE/READ)
		)
		
		-- Item revision information table
		DROP TABLE IF EXISTS #ItemRevision
		CREATE TABLE #ItemRevision(
			  Idn					INT IDENTITY				-- Unique identifier
			, ItemCd				VARCHAR(21)					-- Item code (foreign key)
			, Revision				CHAR(2)			DEFAULT '01'-- Revision number (default 01)
			, DataAdministratorCd	CHAR(8)						-- Data administrator account
			, ProjectCd				VARCHAR(15)					-- Project code
			, StatusCd				CHAR(1)			DEFAULT 'k'	-- Status code (k=active)
			, BusinessUnitCd		CHAR(2)						-- Business unit code
			, AddDescriptionCd		VARCHAR(25)					-- Additional description
			, CreateDt				DATETIME					-- Creation timestamp
			, CreateAcctCd			VARCHAR(8)					-- Creating account
			, UpdateDt				DATETIME					-- Last update timestamp
			, FileQty				SMALLINT					-- File count
			, BomQty				SMALLINT					-- BOM count
			, ResponsibleEngineerCd	CHAR(8)						-- Responsible engineer
			, EolDt					DATETIME					-- End of life date
			, Cm1EventId			INT							-- CM1 event identifier
			, CrudType				VARCHAR(10) DEFAULT 'CREATE'-- Operation type
		)
		
		-- Bill of Materials relationship table
		DROP TABLE IF EXISTS #BillOfMaterial
		CREATE TABLE #BillOfMaterial(
			  Idn					INT IDENTITY(0,1)			-- Unique identifier (starts at 0)
			, BomId					BIGINT						-- BOM unique identifier
			, ParentItemCd			VARCHAR(21)					-- Parent item code
			, ParentItemRevision	CHAR(2)						-- Parent item revision
			, BomFindNbr			SMALLINT		DEFAULT '0100'-- BOM find number (sequence)
			, ChildItemCd			VARCHAR(21)					-- Child item code
			, ChildQty				NUMERIC(12, 5)				-- Quantity of child required
			, BomTypeCd				CHAR(1)						-- BOM type code (N=Normal, A=Alternate)
			, BomAssociationNm		VARCHAR(20)					-- BOM association name
			, NoExplodeCd			CHAR(1)			DEFAULT 'N'	-- No explode flag
			, CrudType				VARCHAR(10)	DEFAULT 'CREATE'-- Operation type
		)

		-- Item revision key mapping table
		DROP TABLE IF EXISTS #ItemRevisionKeyMap
		CREATE TABLE #ItemRevisionKeyMap(
			  ItemCd	VARCHAR(21)							-- Item code
			, Revision	CHAR(2)								-- Revision
			, CrudType	VARCHAR(10) DEFAULT 'CREATE'		-- Operation type
			)
			
		-- Extended item information table
		DROP TABLE IF EXISTS #ItemExtended
		CREATE TABLE #ItemExtended(
			  ItemCd			VARCHAR(21)					-- Item code
			, ItemUdaLastUpdate	DATETIME					-- Last UDA update timestamp
			, CrudType			VARCHAR(10) DEFAULT 'CREATE'-- Operation type
			)

		-- Extended item revision information table
		DROP TABLE IF EXISTS #ItemRevisionExtended
		CREATE TABLE #ItemRevisionExtended(
			  ItemCd			VARCHAR(21)					-- Item code
			, Revision			CHAR(2)						-- Revision
			, OrigAcctCd		VARCHAR(8)					-- Original account code
			, LastUpdateAcctCd	VARCHAR(8)					-- Last update account code
			, CrudType			VARCHAR(10) DEFAULT 'CREATE'-- Operation type
			)

		-- User-defined attributes table
		DROP TABLE IF EXISTS #ItemAttributeValue
		CREATE TABLE #ItemAttributeValue(
			  ItemCd			VARCHAR(21)					-- Item code
			, AttributeId		SMALLINT					-- Attribute identifier
			, AttributeNm		VARCHAR(30)					-- Attribute name
			, DataTypeCd		CHAR(1)						-- Data type (T=Text, N=Number, D=Date)
			, TableNm			VARCHAR(20)					-- Source table name
			, SequenceNbr		SMALLINT					-- Sequence number for multi-value attributes
			, ValueTxt			VARCHAR(255)				-- Text value
			, ValueNbr			FLOAT						-- Numeric value
			, ValueDt			DATETIME					-- Date value
			, ModuleId			INT							-- Module identifier
			, UpdateDt			DATETIME					-- Update timestamp
			, UpdateAccountCd	CHAR(8)						-- Update account code
			, CrudType			VARCHAR(10) DEFAULT 'CREATE'-- Operation type
			)

		-- Item descriptions lookup table
		DROP TABLE IF EXISTS #ItemDescription
		CREATE TABLE #ItemDescription(
			  Idn			INT IDENTITY				-- Unique identifier
			, ItemCd		VARCHAR(21)					-- Item code
			, ItemDsc		NVARCHAR(255)				-- Item description
		)
		
		------------------------------------------------------------------------------------
		-- EXECUTE DATA LOADING PROCEDURES
		------------------------------------------------------------------------------------
		
		-- Load the mapping table with old and new items from business requirements
		PRINT 'Loading item mapping data...'
		EXEC #LoadMappingTable @debug = @debug
		
		-- Load item descriptions for the new items
		PRINT 'Loading item descriptions...'
		EXEC #LoadItemDescription @debug = @debug
		
		-- Load BOM relationships between items
		PRINT 'Loading BOM data...'
		EXEC #LoadBomData @debug = @debug
		
		------------------------------------------------------------------------------------
		-- BUILD ITEM MASTER DATA FROM SOURCE SYSTEM
		------------------------------------------------------------------------------------
		PRINT 'Building item master data...'
		INSERT INTO #Item(
			  ItemCd, ItemDsc, ItemDscShort, ForecastDsc, ClassCd, MaterialTypeCd
			, CommodityCd, EngineeringRevision, ManufacturingRevision, UnitOfMeasureCd
			, UnitOfWeightCd, NetWeight, GrossWeight, OwningSystemCd, RoyaltyCd
			, MakeBuyCd, CustomStandardId, DuplicateReasonId, RecommendedCd
			, ItemStatusRestriction, ItemRecommendId, StandardCost, MigrationStatusNm, DivisionId
		)		
		SELECT 
			  srcx.NewItemCd as ItemCd						-- Use new item code
			, '' as  ItemDsc								-- Will be populated later
			, '' as ItemDscShort							-- Will be populated later
			, '' as ForecastDsc								-- Empty for now
			, srcx.NewItemClassCd as ClassCd				-- New classification
			, srcx.NewItemMaterialTypeCd as MaterialTypeCd	-- New material type
			, src.comdt_cde as CommodityCd					-- Copy from source
			, '01' as EngineeringRevision					-- Default to revision 01
			, '01' as ManufacturingRevision					-- Default to revision 01
			, src.uom as UnitOfMeasureCd					-- Copy unit of measure
			, src.unit_of_wgt as UnitOfWeightCd				-- Copy weight unit
			, src.net_wgt as NetWeight						-- Copy net weight
			, src.gross_wgt as GrossWeight					-- Copy gross weight
			, src.owning_sys as OwningSystemCd				-- Copy owning system
			, src.ryl_cde as RoyaltyCd						-- Copy royalty code
			, src.make_buy_cde as  MakeBuyCd				-- Copy make/buy indicator
			, src.cust_pos as CustomStandardId				-- Copy custom position
			, src.sap_dup_reas_idn as DuplicateReasonId		-- Copy duplicate reason
			, src.rcmd_cde as RecommendedCd					-- Copy recommended flag
			, '' as ItemStatusRestriction					-- Empty for now
			, src.item_recommend_idn as ItemRecommendId		-- Copy recommendation ID
			, src.std_cst as  StandardCost					-- Copy standard cost
			, src.MigrationStatusNm as MigrationStatusNm	-- Copy migration status
			, 0 as DivisionId								-- Default division
		FROM
			SPDREAD2.speed_2max.dbo.item src WITH (NOLOCK)	-- Source item table
			JOIN #ItemMapping srcx ON src.item_cde = srcx.OldItemCd	-- Join with mapping
		WHERE
			srcx.NewItemExistsInTargetDB = 'N'				-- Only process new items

		-- Update item descriptions from the description table
		UPDATE tgt
			SET tgt.ItemDsc = src.ItemDsc					-- Set full description
				, tgt.ItemDscShort = src.ItemDsc			-- Set short description (same for now)
		FROM
			#Item tgt
			JOIN #ItemDescription src ON tgt.ItemCd = src.ItemCd

		------------------------------------------------------------------------------------
		-- BUILD ITEM REVISION DATA
		------------------------------------------------------------------------------------
		PRINT 'Building item revision data...'
		INSERT INTO #ItemRevision(
			  ItemCd, DataAdministratorCd, ProjectCd, BusinessUnitCd, AddDescriptionCd
			, CreateDt, CreateAcctCd, UpdateDt, FileQty, BomQty, ResponsibleEngineerCd
			, EolDt, Cm1EventId
			)
		SELECT
			  m.NewItemCd								-- New item code
			, src.data_administrator					-- Copy data administrator
			, src.proj_cde								-- Copy project code
			, src.bus_unit_idn							-- Copy business unit
			, src.add_dsc as AddDescriptionCd			-- Copy additional description
			, @RunDate as CreateDt						-- Set creation date to now
			, @UpdateAccountCd as CreateAcctCd			-- Set creating account
			, @RunDate as UpdateDt						-- Set update date to now
			, 0 as FileQty								-- Initialize file count
			, 0 as BomQty								-- Initialize BOM count
			, src.responsible_eng						-- Copy responsible engineer
			, NULL as EOLDt								-- No end of life date
			, NULL as Cm1EventId						-- No CM1 event
		FROM	
			#ItemMapping m
			JOIN SPDREAD2.speed_2max.dbo.item_revision src WITH (NOLOCK) ON src.item_cde = m.OldItemCd
				AND src.item_rev = '01'					-- Only revision 01
			JOIN #Item srcx ON m.NewItemCd = srcx.ItemCd	-- Ensure item exists
		
		------------------------------------------------------------------------------------
		-- BUILD SUPPORTING TABLES
		------------------------------------------------------------------------------------
		
		-- Build item revision key map
		INSERT INTO #ItemRevisionKeyMap(ItemCd, Revision)
		SELECT src.ItemCd, src.Revision
		FROM #ItemRevision src

		-- Build item extended table
		INSERT INTO #ItemExtended(ItemCd, ItemUdaLastUpdate)
		SELECT src.ItemCd, src.CreateDt
		FROM #ItemRevision src

		-- Build item revision extended table
		INSERT INTO #ItemRevisionExtended(ItemCd, Revision, OrigAcctCd, LastUpdateAcctCd)
		SELECT src.ItemCd, src.Revision, src.CreateAcctCd, src.CreateAcctCd
		FROM #ItemRevision src

		------------------------------------------------------------------------------------
		-- BUILD USER-DEFINED ATTRIBUTES
		------------------------------------------------------------------------------------
		PRINT 'Building user-defined attributes...'
		INSERT INTO #ItemAttributeValue(
			  ItemCd, AttributeId, AttributeNm, DataTypeCd, TableNm, SequenceNbr
			, ValueTxt, ValueNbr, ValueDt, ModuleId, UpdateDt, UpdateAccountCd
			)
		SELECT
			  src.ItemCd								-- New item code
			, iav.att_idn								-- Attribute ID
			, ia.att_nme								-- Attribute name
			, ia.att_val_typ							-- Data type
			, ia.table_nme								-- Table name
			, iav.seq_nbr								-- Sequence number
			, iav.val_txt								-- Text value
			, iav.val_flt								-- Float value
			, iav.val_dte								-- Date value
			, NULL as ModuleId							-- No module ID
			, @RunDate as UpdateDt						-- Set update date
			, @UpdateAccountCd as UpdateAccountCd		-- Set update account
		FROM
			#Item src
			JOIN #ItemMapping srcx ON src.ItemCd = srcx.NewItemCd
			JOIN SPDREAD2.speed_2max.dbo.uda_item iav ON srcx.OldItemCd = iav.item_cde	-- Source UDA values
			JOIN SPDREAD2.speed_2max.dbo.uda_definition ia ON iav.att_idn = ia.att_idn	-- UDA definitions
	
		---======================================================================================-----
		---------------------------------------- DATA VALIDATION -------------------------------------
		---======================================================================================-----
		PRINT 'Performing data validation...'
		-- TODO: Add specific validation rules here
		-- Examples: Check for required fields, validate data ranges, etc.
		---======================================================================================-----
		
		-- Display data for review in debug mode
		SELECT '#ItemMapping' as debug, * FROM #ItemMapping
		SELECT '#Item' as debug, * FROM #Item ORDER BY ItemCd
		SELECT '#ItemRevision' as debug, * FROM #ItemRevision
		SELECT '#ItemAttributeValue' as debug, * FROM #ItemAttributeValue
		SELECT '#ItemRevisionKeyMap' as debug, * FROM #ItemRevisionKeyMap
		SELECT '#ItemExtended' as debug, * FROM #ItemExtended
		SELECT '#ItemRevisionExtended' as debug, * FROM #ItemRevisionExtended
		SELECT '#BillOfMaterial' as debug, * FROM #BillOfMaterial
		
		---======================================================================================-----
		-- EXECUTE DATA INSERTION (ONLY IN PRODUCTION MODE)
		---======================================================================================-----
		IF @debug != 'Y'
		BEGIN
			BEGIN TRAN
				PRINT 'Transaction Started...!'
				-- Set application context for auditing
				EXEC sp_set_session_context 'AppName', 'PLM';

				-- Insert item master records
				PRINT 'Inserting items...'
				INSERT INTO speed_2max.dbo.item
				(
					  item_cde, item_typ_cde, comdt_cde, uom, ryl_cde, rcmd_cde, make_buy_cde
					, std_cst, sap_mat_typ, owning_sys, unit_of_wgt, net_wgt, gross_wgt
					, dsc, eng_rev, mfg_rev, item_recommend_idn, dsc_full, MigrationStatusNm
					, DivisionId, ForecastDsc					
				)
			SELECT
					  src.ItemCd as item_cde
					, src.ClassCd as item_typ_cde
					, src.CommodityCd as comdt_cde
					, src.UnitOfMeasureCd as uom
					, src.RoyaltyCd as ryl_cde
					, src.RecommendedCd as rcmd_cde
					, src.MakeBuyCd as make_buy_cde
					, src.StandardCost as std_cst
					, src.MaterialTypeCd as sap_mat_typ
					, src.OwningSystemCd as owning_sys
					, src.UnitOfWeightCd as unit_of_wgt
					, src.NetWeight as net_wgt
					, src.GrossWeight as gross_wgt
					, src.ItemDscShort as dsc
					, src.EngineeringRevision as eng_rev
					, src.ManufacturingRevision as mfg_rev
					, src.ItemRecommendId as item_recommend_idn
					, src.ItemDsc as dsc_full
					, src.MigrationStatusNm as MigrationStatusNm
					, src.DivisionId as DivisionId
					, src.ForecastDsc as ForecastDsc		
			FROM
				#Item src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.Item srcx WHERE src.ItemCd = srcx.ItemCd)
			SELECT @@ROWCOUNT as ItemInsertCount

			-- Insert item revision records
			PRINT 'Inserting item revisions...'
			INSERT INTO speed_2max.dbo.item_revision(
				  item_cde, item_rev, data_administrator, proj_cde, lvl_idn, bus_unit_idn
				, cre_dte, lst_mod_dte, file_cnt, bom_cnt, responsible_eng, cm1_evnt_idn, eol_dte
			)
			SELECT
				  src.ItemCd as item_cde
				, src.Revision as item_rev
				, src.DataAdministratorCd as data_administrator
				, src.ProjectCd as proj_cde
				, src.StatusCd as lvl_idn
				, src.BusinessUnitCd as bus_unit_idn
				, src.CreateDt as cre_dte
				, src.UpdateDt as lst_mod_dte
				, src.FileQty as file_cnt
				, src.BomQty as bom_cnt
				, src.ResponsibleEngineerCd as responsible_eng
				, src.Cm1EventId as cm1_evnt_idn
				, src.EolDt as eol_dte
			FROM
				#ItemRevision src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.ItemRevision srcx 
								WHERE src.ItemCd = srcx.ItemCd AND src.Revision = srcx.Revision)
			SELECT @@ROWCOUNT as ItemRevisionInsertCount

			-- Insert item revision key map records
			PRINT 'Inserting item revision key maps...'
			INSERT INTO speed_2max.dbo.item_revision_key_map(item_cde, item_rev)
			SELECT ItemCd, Revision
			FROM #ItemRevisionKeyMap src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.ItemRevisionKeyMap srcx
								WHERE src.ItemCd = srcx.ItemCd AND src.Revision = srcx.Revision)
			SELECT @@ROWCOUNT as ItemRevisionKeyMapInsertCount

			-- Insert user-defined attribute records
			PRINT 'Inserting user-defined attributes...'
			INSERT INTO speed_2max.dbo.uda_item(
				  item_cde, att_idn, seq_nbr, val_txt, val_flt, val_dte
				, mdul_idn, lst_mod_usr, lst_mod_dte
				)
			SELECT
				  src.ItemCd as item_cde
				, src.AttributeId as att_idn
				, src.SequenceNbr as seq_nbr
				, src.ValueTxt as val_txt
				, src.ValueNbr as val_flt
				, src.ValueDt as val_dte
				, src.ModuleId as mdul_idn
				, src.UpdateAccountCd as lst_mod_usr
				, src.UpdateDt as lst_mod_dte
			FROM
				#ItemAttributeValue src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.ItemAttributeValue srcx
								WHERE src.ItemCd = srcx.ItemCd 
								AND src.AttributeId = srcx.AttributeId
								AND src.SequenceNbr = srcx.SequenceNbr)
			SELECT @@ROWCOUNT as ItemAttributeValueInsertCount

			-- Insert item extended records
			PRINT 'Inserting item extended records...'
			INSERT INTO speed_2max.dbo.item_extended(item_cde, uda_mod_dte)
			SELECT src.ItemCd, src.ItemUdaLastUpdate
			FROM #ItemExtended src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.ItemExtended srcx WHERE src.ItemCd = srcx.ItemCd)
			SELECT @@ROWCOUNT as ItemExtendedInsertCount

			-- Insert item revision extended records
			PRINT 'Inserting item revision extended records...'
			INSERT INTO speed_2max.dbo.item_revision_extended(
				   item_cde, item_rev, orig_nme, lst_mod_nme
				)
			SELECT
				  src.ItemCd as  item_cde	
				, src.Revision as item_rev	
				, src.OrigAcctCd as orig_nme	
				, src.LastUpdateAcctCd as lst_mod_nme
			FROM
				#ItemRevisionExtended src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM speed_2max.dbo.item_revision_extended srcx
								WHERE src.ItemCd = srcx.item_cde AND src.Revision = srcx.item_rev)
			SELECT @@ROWCOUNT as ItemRevisionExtendedInsertCount

			-- Insert bill of materials records
			PRINT 'Inserting bill of materials...'
			INSERT INTO speed_2max.dbo.design_bom(
					  bom_idn, parent_item_cde, parent_item_rev, bom_find_nbr
					, child_item_cde, child_qty_req, bom_typ_cde, no_expl_ind
				)
			SELECT
				  src.BomId as  bom_idn	
				, src.ParentItemCd as parent_item_cde	
				, src.ParentItemRevision as parent_item_rev	
				, src.BomFindNbr as bom_find_nbr	
				, src.ChildItemCd as child_item_cde	
				, src.ChildQty as child_qty_req	
				, src.BomTypeCd as bom_typ_cde	
				, src.NoExplodeCd as no_expl_ind
			FROM
				#BillOfMaterial src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.BillOfMaterial srcx
								WHERE src.ParentItemCd = srcx.ParentItemCd
								AND src.ParentItemRevision = srcx.ParentItemRevision
								AND src.ChildItemCd = srcx.ChildItemCd
								AND src.BomFindNbr = srcx.BomFindNbr
								AND src.BomTypeCd = srcx.BomTypeCd)
			SELECT @@ROWCOUNT as BillOfMaterialInsertCount
			
			COMMIT TRAN
			PRINT 'Transaction Committed...!'
		END
	END TRY
	BEGIN CATCH
		-- Error handling
		SELECT ERROR_LINE() as error_line, ERROR_MESSAGE() as error_message
		IF @@TRANCOUNT > 0 
		BEGIN
			ROLLBACK
			PRINT 'Transaction Rolled back..!'
		END
	END CATCH
END
GO