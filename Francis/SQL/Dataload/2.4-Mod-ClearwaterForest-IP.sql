------------------------------------------------------------------------------------
--	CLEAR WATER FOREST PAPER MODEL DATA LOAD SCRIPT
--	Flow: IP FLOW
--
--
--
------------------------------------------------------------------------------------
USE Pdm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
SET NOCOUNT ON
GO

CREATE OR ALTER PROCEDURE #LoadItemDescription (@debug CHAR(1) = 'Y') AS
BEGIN
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
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '99Z101', 'CWFAPXDCC2PLCHLDRRVCW'

END
GO

CREATE OR ALTER PROCEDURE #LoadMappingTable (@debug CHAR(1) = 'Y') AS 
BEGIN
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-181', '99Z101', 'CPU'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-955', '2001-005-001', 'P_TEST'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-416', '2001-005-002', 'P_TEST'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-331-544', '2001-005-003', 'P_ASSEMBLY'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-331-538', '2001-005-004', 'P_ASSEMBLY'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-101', '2001-005-005', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-100', '2001-005-006', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-103', '2001-005-007', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-174', '2001-005-008', 'P_STACK_SILICON'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-175', '2001-005-009', 'P_STACK_SILICON'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-168', '2001-005-010', 'P_STACK_COMBO'
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
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-255', '2001-005-027', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-308-373', '2001-005-028', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-415', '2001-005-029', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-309-095', '2001-005-030', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-953', '2001-005-031', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-251', '2001-005-032', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-308-372', '2001-005-033', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-416', '2001-005-034', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-309-094', '2001-005-035', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-955', '2001-005-036', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-099', '2001-005-046', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-102', '2001-005-047', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-104', '2001-005-048', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-252', '2001-005-049', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-956', '2001-005-050', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-326-741', '2001-005-051', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-326-742', '2001-005-052', 'P_DIE_PREP'

	UPDATE tgt
			SET tgt.OldItemClassCd = src.item_typ_cde
				, tgt.OldItemClassDsc = ic.item_typ_dsc
				, tgt.OldItemExistsInSourceDB = 'Y'
				, tgt.OldItemMaterialTypeCd = src.sap_mat_typ
				, tgt.OldItemMaterialTypeNm = mt.sap_mat_typ_nme
		FROM
			#ItemMapping tgt
			JOIN SPDREAD2.speed_2max.dbo.item src WITH (NOLOCK) ON tgt.OldItemCd = src.item_cde
			JOIN SPDREAD2.speed_2max.dbo.item_type ic WITH (NOLOCK) ON src.item_typ_cde = ic.item_typ_cde
			JOIN SPDREAD2.speed_2max.dbo.sap_material_type mt WITH (NOLOCK) ON src.sap_mat_typ = mt.sap_mat_typ

	UPDATE tgt
		SET tgt.NewItemClassCd = ic.ClassCd
	FROM
		#ItemMapping tgt
		JOIN ItemBom.ItemClass ic ON tgt.NewItemClassDsc = ic.ClassDsc

	UPDATE tgt
		SET tgt.NewItemMaterialTypeCd = m.MaterialTypeCd
			, tgt.NewItemMaterialTypeNm = m.MaterialTypeNm
				
	FROM
		#ItemMapping tgt
		JOIN ItemBom.RefMaterialTypeItemClass cm ON tgt.NewItemClassCd = cm.ClassCd
		JOIN ItemBom.RefMaterialType m ON cm.MaterialTypeCd = m.MaterialTypeCd

	UPDATE tgt
		SET tgt.NewItemExistsInTargetDB = 'Y'
	FROM
		#ItemMapping tgt
		JOIN ItemBom.Item src ON tgt.NewItemCd = src.ItemCd
	SELECT @@ROWCOUNT as NewItemExistsInTargetDBCount
END
GO

CREATE OR ALTER PROCEDURE #LoadBomData (@debug CHAR(1) = 'Y') AS
BEGIN
	
	DROP TABLE IF EXISTS #BomIdGenerator
	CREATE TABLE #BomIdGenerator
	(
		  BomIdGeneratorId	INT IDENTITY
		, Idn				INT
		, NewBomId			BIGINT
	)

	DECLARE 
		   @MaxBomIdn	INT
		 , @LastIdn		INT
		 , @MaxRow		INT = 20
		 , @BomCount	INT

	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '99Z101', '01', '2001-005-001', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '99Z101', '01', '2001-005-002', 'ALTERNATE', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-001', '01', '2001-005-003', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-001', '01', '2001-005-004', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-002', '01', '2001-005-003', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-002', '01', '2001-005-004', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-003', '01', '2001-005-005', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-003', '01', '2001-005-008', 'NORMAL', 3
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-004', '01', '2001-005-005', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-004', '01', '2001-005-009', 'NORMAL', 3
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-005', '01', '2001-005-006', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-006', '01', '2001-005-007', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-008', '01', '2001-005-010', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-008', '01', '2001-005-011', 'ALTERNATE', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-009', '01', '2001-005-012', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-009', '01', '2001-005-013', 'ALTERNATE', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-010', '01', '2001-005-015', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-010', '01', '2001-005-016', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-010', '01', '2001-005-017', 'NORMAL', 2
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-010', '01', '2001-005-018', 'NORMAL', 4
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
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-014', '01', '2001-005-027', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-015', '01', '2001-005-027', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-016', '01', '2001-005-028', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-017', '01', '2001-005-029', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-018', '01', '2001-005-022', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-019', '01', '2001-005-024', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-020', '01', '2001-005-025', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-021', '01', '2001-005-026', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-027', '01', '2001-005-032', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-028', '01', '2001-005-033', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-029', '01', '2001-005-034', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-022', '01', '2001-005-031', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-024', '01', '2001-005-031', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-025', '01', '2001-005-031', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-026', '01', '2001-005-031', 'NORMAL', 1
	INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty) SELECT '2001-005-031', '01', '2001-005-036', 'NORMAL', 1

	UPDATE tgt
		SET tgt.BomTypeCd = src.BomTypeCd
	FROM
		#BillOfMaterial tgt
		JOIN ItemBom.RefBomType src ON tgt.BomAssociationNm = src.BomAssociationNm


	UPDATE tgt
		SET tgt.BomId = src.BomId
			, tgt.CrudType = 'READ'
	FROM
		#BillOfMaterial tgt
		JOIN ItemBom.BillOfMaterial src ON tgt.ParentItemCd = src.ParentItemCd
			AND tgt.ParentItemRevision = src.ParentItemRevision
			AND tgt.ChildItemCd = src.ChildItemCd
			AND tgt.BomTypeCd = src.BomTypeCd
			AND tgt.BomFindNbr = src.BomFindNbr
	SELECT @@ROWCOUNT as ExistingBomCount

	IF @debug = 'Y'
	BEGIN
		UPDATE #BillOfMaterial SET BomId = Idn * -1000
	END
	ELSE
	BEGIN
		-----------------------------------------------------------
		-------------- GENERATE BOM IDNs	-----------------------
		-----------------------------------------------------------
		INSERT INTO #BomIdGenerator(Idn)
		SELECT Idn FROM #BillOfMaterial WHERE CrudType = 'CREATE' ORDER BY Idn
		SELECT @BomCount = @@ROWCOUNT 
		EXEC espeed.dbo.sp_scrty_rtn_next_idn 'BOM', @MaxBomIdn OUTPUT, @LastIdn OUTPUT, @BomCount
		SELECT @MaxBomIdn as [@MaxBomIdn], @LastIdn as [@LastIdn], @BomCount as [@BomCount]
		UPDATE #BomIdGenerator SET NewBomId = BomIdGeneratorId + @MaxBomIdn
		
		UPDATE tgt
			SET tgt.BomId = src.NewBomId
		FROM
			#BillOfMaterial tgt
			JOIN #BomIdGenerator src ON tgt.Idn = src.Idn
	END
END
GO

BEGIN
	BEGIN TRY
		DECLARE
			  @debug					CHAR(1)	= 'Y'
			, @ServerEnvironment		VARCHAR(100)
			, @RunDate					DATETIME = GETDATE()
			, @UpdateAccountCd			CHAR(8) = 'SYSTEM'
			, @BackupDone				CHAR(1) = 'N'
			, @BackUpCount				INT = 0

		DROP TABLE IF EXISTS #ItemMapping
		CREATE TABLE #ItemMapping(
				  Idn						INT IDENTITY
				, OldItemCd					VARCHAR(21)
				, OldItemClassCd			VARCHAR(4)
				, OldItemClassDsc			VARCHAR(18)
				, OldItemMaterialTypeCd		VARCHAR(4)
				, OldItemMaterialTypeNm		VARCHAR(30)
				, OldItemExistsInSourceDB	CHAR(1) DEFAULT 'N'
				, NewItemCd					VARCHAR(21)
				, NewItemClassCd			VARCHAR(4)
				, NewItemClassDsc			VARCHAR(18)
				, NewItemMaterialTypeCd		VARCHAR(4)
				, NewItemMaterialTypeNm		VARCHAR(30)
				, NewItemExistsInTargetDB	CHAR(1) DEFAULT 'N'
				)

		DROP TABLE IF EXISTS #Item
		CREATE TABLE #Item(
			  Idn					INT IDENTITY
			, ItemCd				VARCHAR(21)
			, ItemDsc				NVARCHAR(255)
			, ItemDscShort			VARCHAR(40)
			, ForecastDsc			VARCHAR(255)
			, ClassCd				CHAR(4)
			, MaterialTypeCd		CHAR(4)
			, CommodityCd			CHAR(10)
			, EngineeringRevision	CHAR(2)
			, ManufacturingRevision	CHAR(2)
			, UnitOfMeasureCd		CHAR(3)
			, UnitOfWeightCd		CHAR(3)
			, NetWeight				NUMERIC(12, 5)
			, GrossWeight			NUMERIC(12, 5)
			, OwningSystemCd		CHAR(3)
			, RoyaltyCd				CHAR(2)
			, MakeBuyCd				CHAR(1)
			, CustomStandardId		INT
			, DuplicateReasonId		SMALLINT
			, RecommendedCd			CHAR(1)
			, ItemStatusRestriction	CHAR(1)
			, ItemRecommendId		INT
			, StandardCost			NUMERIC(12, 5)
			, MigrationStatusNm		VARCHAR(40)
			, DivisionId			TINYINT
			, CrudType				VARCHAR(10) DEFAULT 'CREATE'
		)
		
		DROP TABLE IF EXISTS #ItemRevision
		CREATE TABLE #ItemRevision(
			  Idn					INT IDENTITY
			, ItemCd				VARCHAR(21)
			, Revision				CHAR(2)			DEFAULT '01'
			, DataAdministratorCd	CHAR(8)
			, ProjectCd				VARCHAR(15)
			, StatusCd				CHAR(1)			DEFAULT 'k'
			, BusinessUnitCd		CHAR(2)
			, AddDescriptionCd		VARCHAR(25)
			, CreateDt				DATETIME
			, CreateAcctCd			VARCHAR(8)
			, UpdateDt				DATETIME
			, FileQty				SMALLINT
			, BomQty				SMALLINT
			, ResponsibleEngineerCd	CHAR(8)
			, EolDt					DATETIME
			, Cm1EventId			INT
			, CrudType				VARCHAR(10) DEFAULT 'CREATE'
		)
		
		DROP TABLE IF EXISTS #BillOfMaterial
		CREATE TABLE #BillOfMaterial(
			  Idn					INT IDENTITY(0,1)
			, BomId					BIGINT
			, ParentItemCd			VARCHAR(21)
			, ParentItemRevision	CHAR(2)
			, BomFindNbr			SMALLINT		DEFAULT '0100'
			, ChildItemCd			VARCHAR(21)
			, ChildQty				NUMERIC(12, 5)
			, BomTypeCd				CHAR(1)
			, BomAssociationNm			VARCHAR(20)
			, NoExplodeCd			CHAR(1)			DEFAULT 'N'
			, CrudType				VARCHAR(10)	DEFAULT 'CREATE'
		)

		DROP TABLE IF EXISTS #ItemRevisionKeyMap
		CREATE TABLE #ItemRevisionKeyMap(
			  ItemCd	VARCHAR(21)
			, Revision	CHAR(2)
			, CrudType	VARCHAR(10) DEFAULT 'CREATE'
			)
		DROP TABLE IF EXISTS #ItemExtended
		CREATE TABLE #ItemExtended(
			  ItemCd			VARCHAR(21)
			, ItemUdaLastUpdate	DATETIME
			, CrudType			VARCHAR(10) DEFAULT 'CREATE'
			)

		DROP TABLE IF EXISTS #ItemRevisionExtended
		CREATE TABLE #ItemRevisionExtended(
			  ItemCd			VARCHAR(21)
			, Revision			CHAR(2)
			, OrigAcctCd		VARCHAR(8)
			, LastUpdateAcctCd	VARCHAR(8)
			, CrudType			VARCHAR(10) DEFAULT 'CREATE'
			)

		DROP TABLE IF EXISTS #ItemAttributeValue
		CREATE TABLE #ItemAttributeValue(
			  ItemCd			VARCHAR(21)
			, AttributeId		SMALLINT
			, AttributeNm		VARCHAR(30)
			, DataTypeCd		CHAR(1)
			, TableNm			VARCHAR(20)
			, SequenceNbr		SMALLINT
			, ValueTxt			VARCHAR(255)
			, ValueNbr			FLOAT
			, ValueDt			DATETIME
			, ModuleId			INT
			, UpdateDt			DATETIME
			, UpdateAccountCd	CHAR(8)
			, CrudType			VARCHAR(10) DEFAULT 'CREATE'
			)

		DROP TABLE IF EXISTS #ItemDescription
		CREATE TABLE #ItemDescription(
			  Idn			INT IDENTITY
			, ItemCd		VARCHAR(21)
			, ItemDsc		NVARCHAR(255)
		)
		--------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------
		-- Load the Mapping table with Old and New Items that we received from the business in excel file.
		--------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------
		EXEC #LoadMappingTable @debug = @debug
		EXEC #LoadItemDescription @debug = @debug
		--------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------
		-- Load the BOM Data on new items that we received from the business in excel file.
		EXEC #LoadBomData @debug = @debug
		--------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------
		INSERT INTO #Item(
			  ItemCd
			, ItemDsc
			, ItemDscShort
			, ForecastDsc
			, ClassCd
			, MaterialTypeCd
			, CommodityCd
			, EngineeringRevision
			, ManufacturingRevision
			, UnitOfMeasureCd
			, UnitOfWeightCd
			, NetWeight
			, GrossWeight
			, OwningSystemCd
			, RoyaltyCd
			, MakeBuyCd
			, CustomStandardId
			, DuplicateReasonId
			, RecommendedCd
			, ItemStatusRestriction
			, ItemRecommendId
			, StandardCost
			, MigrationStatusNm
			, DivisionId
		)		
		SELECT 
			  srcx.NewItemCd as ItemCd
			, '' as  ItemDsc
			, '' as ItemDscShort
			, '' as ForecastDsc
			, srcx.NewItemClassCd as ClassCd
			, srcx.NewItemMaterialTypeCd as MaterialTypeCd
			, src.comdt_cde as CommodityCd
			, '01' as EngineeringRevision
			, '01' as ManufacturingRevision
			, src.uom as UnitOfMeasureCd
			, src.unit_of_wgt as UnitOfWeightCd
			, src.net_wgt as NetWeight
			, src.gross_wgt as GrossWeight
			, src.owning_sys as OwningSystemCd
			, src.ryl_cde as RoyaltyCd
			, src.make_buy_cde as  MakeBuyCd
			, src.cust_pos  CustomStandardId
			, src.sap_dup_reas_idn as DuplicateReasonId
			, src.rcmd_cde as RecommendedCd
			, '' as ItemStatusRestriction
			, src.item_recommend_idn as ItemRecommendId
			, src.std_cst as  StandardCost
			, src.MigrationStatusNm as MigrationStatusNm
			, 0 as DivisionId
		FROM
			SPDREAD2.speed_2max.dbo.item src WITH (NOLOCK)
			JOIN #ItemMapping srcx ON src.item_cde = srcx.OldItemCd
		WHERE
			srcx.NewItemExistsInTargetDB = 'N'

		UPDATE tgt
			SET tgt.ItemDsc = src.ItemDsc
				, tgt.ItemDscShort = src.ItemDsc
		FROM
			#Item tgt
			JOIN #ItemDescription src ON tgt.ItemCd = src.ItemCd
		INSERT INTO #ItemRevision(
			  ItemCd
			, DataAdministratorCd
			, ProjectCd
			, BusinessUnitCd
			, AddDescriptionCd
			, CreateDt
			, CreateAcctCd
			, UpdateDt
			, FileQty
			, BomQty
			, ResponsibleEngineerCd
			, EolDt
			, Cm1EventId
			)
		SELECT
			  m.NewItemCd
			, src.data_administrator
			, src.proj_cde
			, src.bus_unit_idn
			, src.add_dsc as AddDescriptionCd
			, @RunDate as CreateDt
			, @UpdateAccountCd as CreateAcctCd
			, @RunDate as UpdateDt
			, 0 as FileQty
			, 0 as BomQty
			, src.responsible_eng
			, NULL as EOLDt
			, NULL as Cm1EventId
		FROM	
			#ItemMapping m
			JOIN SPDREAD2.speed_2max.dbo.item_revision src WITH (NOLOCK) ON src.item_cde = m.OldItemCd
				AND src.item_rev = '01'
			JOIN #Item srcx ON m.NewItemCd = srcx.ItemCd
		
		INSERT INTO #ItemRevisionKeyMap(ItemCd, Revision)
		SELECT 
			  src.ItemCd	
			, src.Revision
		FROM
			#ItemRevision src

		INSERT INTO #ItemExtended(
			  ItemCd
			, ItemUdaLastUpdate
			)
		SELECT
			src.ItemCd
			,src.CreateDt
		FROM
			#ItemRevision src

		INSERT INTO #ItemRevisionExtended(
			  ItemCd
			, Revision
			, OrigAcctCd
			, LastUpdateAcctCd
			)
		SELECT 
			  src.ItemCd
			, src.Revision
			, src.CreateAcctCd
			, src.CreateAcctCd
		FROM
			#ItemRevision src

		INSERT INTO #ItemAttributeValue(
			  ItemCd
			, AttributeId
			, AttributeNm
			, DataTypeCd
			, TableNm
			, SequenceNbr
			, ValueTxt
			, ValueNbr
			, ValueDt
			, ModuleId
			, UpdateDt
			, UpdateAccountCd
			)
		SELECT
			  src.ItemCd
			, iav.att_idn
			, ia.att_nme
			, ia.att_val_typ
			, ia.table_nme
			, iav.seq_nbr
			, iav.val_txt
			, iav.val_flt
			, iav.val_dte
			, NULL as ModuleId
			, @RunDate as UpdateDt
			, @UpdateAccountCd as UpdateAccountCd
		FROM
			#Item src
			JOIN #ItemMapping srcx ON src.ItemCd = srcx.NewItemCd
			JOIN SPDREAD2.speed_2max.dbo.uda_item iav ON srcx.OldItemCd = iav.item_cde
			JOIN SPDREAD2.speed_2max.dbo.uda_definition ia ON iav.att_idn = ia.att_idn
	
		---======================================================================================-----
		---------------------------------------- DATA VALIDATION -------------------------------------
		---======================================================================================-----
		--- VALIDATIONS TODO
		---======================================================================================-----
		
		SELECT '#ItemMapping' as debug, * FROM #ItemMapping
		SELECT '#Item' as debug, * FROM #Item ORDER BY ItemCd
		SELECT '#ItemRevision' as debug, * FROM #ItemRevision
		SELECT '#ItemAttributeValue' as debug, * FROM #ItemAttributeValue
		SELECT '#ItemRevisionKeyMap' as debug, * FROM #ItemRevisionKeyMap
		SELECT '#ItemExtended' as debug, * FROM #ItemExtended
		SELECT '#ItemRevisionExtended' as debug, * FROM #ItemRevisionExtended
		SELECT '#BillOfMaterial' as debug, * FROM #BillOfMaterial
		---======================================================================================-----
		IF @debug != 'Y'
		BEGIN
			BEGIN TRAN
				PRINT 'Transaction Started...!'
				EXEC sp_set_session_context 'AppName', 'PLM';

				INSERT INTO speed_2max.dbo.item
				(
					  item_cde
					, item_typ_cde
					, comdt_cde
					, uom
					, ryl_cde
					, rcmd_cde
					, make_buy_cde
					--, six_mo_pln_qty
					, std_cst
					--, act_cst
					--, act_cst_src
					--, future_cst
					--, future_cst_eff_dte
					, sap_mat_typ
					, owning_sys
					, unit_of_wgt
					, net_wgt
					, gross_wgt
					--, sap_dup_reas_idn
					--, sap_lst_mod_dte
					, dsc
					, eng_rev
					, mfg_rev
					--, aml_cnt
					--, md0_fd_dte
					--, lst_cls_chg_dte
					, item_recommend_idn
					--, gtin
					-- scrty_cls_idn
					--, tst_vhcl_ind
					--, bin_splt_ind
					--, sls_sts_cde
					--, cust_pos
					, dsc_full
					, MigrationStatusNm
					, DivisionId
					, ForecastDsc					
				)
			SELECT
					  src.ItemCd as item_cde
					, src.ClassCd as item_typ_cde
					, src.CommodityCd as comdt_cde
					, src.UnitOfMeasureCd as uom
					, src.RoyaltyCd as ryl_cde
					, src.RecommendedCd as rcmd_cde
					, src.MakeBuyCd as make_buy_cde
					--, src.six six_mo_pln_qty
					, src.StandardCost as std_cst
					--,  act_cst
					--, act_cst_src
					--, future_cst
					--, future_cst_eff_dte
					, src.MaterialTypeCd as sap_mat_typ
					, src.OwningSystemCd as owning_sys
					, src.UnitOfWeightCd as unit_of_wgt
					, src.NetWeight as net_wgt
					, src.GrossWeight as gross_wgt
					--, sap_dup_reas_idn
					--, src.sap_lst_mod_dte
					, src.ItemDscShort as dsc
					, src.EngineeringRevision as eng_rev
					, src.ManufacturingRevision as mfg_rev
					--, src.aml_cnt
					--, src.md0_fd_dte
					--, src.lst_cls_chg_dte
					, src.ItemRecommendId as item_recommend_idn
					--, src.gtin
					--, src.scrty_cls_idn
					--, src.tst_vhcl_ind
					--, src.bin_splt_ind
					--, src.sls_sts_cde
					--, src.cust_pos
					, src.ItemDsc as dsc_full
					, src.MigrationStatusNm as MigrationStatusNm
					, src.DivisionId as DivisionId
					, src.ForecastDsc as ForecastDsc		
			FROM
				#Item src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.Item srcx
								WHERE src.ItemCd = srcx.ItemCd)
			SELECT @@ROWCOUNT as ItemInsertCount

			INSERT INTO speed_2max.dbo.item_revision(
				  item_cde
				, item_rev
				, data_administrator
				, proj_cde
				, lvl_idn
				, bus_unit_idn
				--, add_dsc
				, cre_dte
				, lst_mod_dte
				, file_cnt
				, bom_cnt
				, responsible_eng
				, cm1_evnt_idn
				, eol_dte
			)
			SELECT
				  src.ItemCd as item_cde
				, src.Revision as item_rev
				, src.DataAdministratorCd as data_administrator
				, src.ProjectCd as proj_cde
				, src.StatusCd as lvl_idn
				, src.BusinessUnitCd as bus_unit_idn
				--, src.add_dsc
				, src.CreateDt as cre_dte
				, src.UpdateDt as lst_mod_dte
				, src.FileQty file_cnt
				, src.BomQty as bom_cnt
				, src.ResponsibleEngineerCd as responsible_eng
				, src.Cm1EventId as cm1_evnt_idn
				, src.EolDt as eol_dte
			FROM
				#ItemRevision src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.ItemRevision srcx 
								WHERE
									src.ItemCd = srcx.ItemCd
									AND src.Revision = srcx.Revision)
			SELECT @@ROWCOUNT as ItemRevisionInsertCount

			INSERT INTO speed_2max.dbo.item_revision_key_map(item_cde, item_rev)
			SELECT 
				ItemCd, Revision
			FROM
				#ItemRevisionKeyMap src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.ItemRevisionKeyMap srcx
								WHERE src.ItemCd = srcx.ItemCd
									AND src.Revision = srcx.Revision)
			SELECT @@ROWCOUNT as ItemRevisionKeyMapInsertCount

			INSERT INTO speed_2max.dbo.uda_item(
				  item_cde
				, att_idn
				, seq_nbr
				, val_txt
				, val_flt
				, val_dte
				, mdul_idn
				, lst_mod_usr
				, lst_mod_dte
				)
			SELECT
				  src.ItemCd as item_cde
				, src.AttributeId as att_idn
				, src.SequenceNbr as seq_nbr
				, src.ValueTxt as val_txt
				, src.ValueNbr as val_flt
				, src.ValueNbr as val_dte
				, src.ModuleId as mdul_idn
				, src.UpdateAccountCd as lst_mod_usr
				, src.UpdateDt as lst_mod_dte
			FROM
				#ItemAttributeValue src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.ItemAttributeValue srcx
								WHERE
									src.ItemCd = srcx.ItemCd
									AND src.AttributeId = srcx.AttributeId
									AND src.SequenceNbr = srcx.SequenceNbr)
			SELECT @@ROWCOUNT as ItemAttributeValueInsertCount

			INSERT INTO speed_2max.dbo.item_extended(item_cde, uda_mod_dte)
			SELECT src.ItemCd, src.ItemUdaLastUpdate
			FROM #ItemExtended src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.ItemExtended srcx
								WHERE src.ItemCd = srcx.ItemCd
								)
			SELECT @@ROWCOUNT as ItemExtendedInsertCount

			INSERT INTO speed_2max.dbo.item_revision_extended(
				   item_cde	
				 , item_rev	
				 , orig_nme	
				 , lst_mod_nme
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
								WHERE
									src.ItemCd = srcx.item_cde
									AND src.Revision = srcx.item_rev)
			SELECT @@ROWCOUNT as ItemRevisionInsertCount

			INSERT INTO speed_2max.dbo.design_bom(
					  bom_idn	
					, parent_item_cde	
					, parent_item_rev	
					, bom_find_nbr	
					, child_item_cde	
					, child_qty_req	
					, bom_typ_cde	
					, no_expl_ind

				)
			SELECT
				  src.BomId as  bom_idn	
				, src.ParentItemCd as parent_item_cde	
				, src.ParentItemRevision as parent_item_rev	
				, src.BomFindNbr as bom_find_nbr	
				, src.ChildItemCd child_item_cde	
				, src.ChildQty as child_qty_req	
				, src.BomTypeCd bom_typ_cde	
				, src.NoExplodeCd as no_expl_ind
			FROM
				#BillOfMaterial src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.BillOfMaterial srcx
								WHERE
									src.ParentItemCd = srcx.ParentItemCd
									AND src.ParentItemRevision = srcx.ParentItemRevision
									AND src.ChildItemCd = srcx.ChildItemCd
									AND src.BomFindNbr = srcx.BomFindNbr
									AND src.BomTypeCd = srcx.BomTypeCd)
			SELECT @@ROWCOUNT as BillOfMaterialInsertCount
			--COMMIT TRAN
			PRINT 'Transaction Committed...!'
		END
	END TRY
	BEGIN CATCH
		SELECT ERROR_LINE() as error_line, ERROR_MESSAGE() as error_message
		IF @@TRANCOUNT > 0 
		BEGIN
			ROLLBACK
			PRINT 'Transaction Rolled back..!'
		END
	END CATCH
END
GO
