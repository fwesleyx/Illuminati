/**
Author:Francis
Date:10-11-2025
Description: Dataload to SMTF
Model:Galepeak
**/

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
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-287-984',	'7GAPAVC'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-287-985',	'B7GAPAVC'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-288-777',	'7BNJAVC'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-288-778',	'B7BNJAVC'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-289-233',	'H37GAPBVC'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-289-234',	'H37GAPBVCB1'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-289-324',	'7TT2EVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-289-325',	'B7TT2EVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-294-228',	'New'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-294-229',	'New'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '99CAHZ'	, 'DATA COMM WCSBE200 FC-CSP225 SRMRX COMM>'

	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-312-831',	'B7GAPBVC'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-313-085',	'B7TT2GVB'
	INSERT INTO #ItemDescription(ItemCd, ItemDsc) SELECT '2000-313-089',	'B7BNJBVC'
	
END
GO

CREATE OR ALTER PROCEDURE #LoadMappingTable (@debug CHAR(1) = 'Y') AS 
BEGIN

	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-287-984',	'2000-287-984',	'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-287-985',	'2000-287-985',	'P_BUMP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-288-777',	'2000-288-777',	'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-288-778',	'2000-288-778',	'P_BUMP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-289-233',	'2000-289-233',	'P_ASSEMBLY'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-289-234',	'2000-289-234',	'P_TEST'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-289-324',	'2000-289-324',	'P_TEST'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-289-325',	'2000-289-325',	'P_BUMP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-294-228',	'2000-294-228',	'P_ASSEMBLY'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-294-229',	'2000-294-229',	'P_TEST'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '99CAHZ'	,		'99CAHZ'	,	'CONNECTIVITY'
	
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-312-831','2000-312-831',	'P_BUMP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-313-085','2000-313-085',	'P_BUMP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-313-089','2000-313-089',	'P_BUMP'

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

INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '99CAHZ','01', '2000-289-234' , 'NORMAL', 1
INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-289-234','01','2000-289-233','NORMAL', 1

INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-289-233','01','2000-287-985','NORMAL', 1
INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-287-985','01','2000-287-984','NORMAL', 1

INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-289-233','01','2000-289-325','NORMAL', 1
INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-289-325','01','2000-289-324','NORMAL', 1

INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-289-233','01','2000-288-778','NORMAL', 1
INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-288-778','01','2000-288-777','NORMAL', 1

INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '99CAHZ','01', '2000-294-229' , 'NORMAL', 1
INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-294-229','01','2000-294-228','NORMAL', 1

INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-294-228','01','2000-312-831','NORMAL', 1
INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-312-831','01','2000-287-984','NORMAL', 1

INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-294-228','01','2000-313-085','NORMAL', 1
INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-313-085','01','2000-289-324','NORMAL', 1

INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-294-228','01','2000-313-089','NORMAL', 1
INSERT INTO #BillOfMaterial(ParentItemCd, ParentItemRevision, ChildItemCd, BomAssociationNm, ChildQty)SELECT '2000-313-089','01','2000-288-777','NORMAL', 1

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

		select * from #BillOfMaterial
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

			--	-- Insert item master records
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

			---- Insert user-defined attribute records
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

			---- Insert item extended records
			PRINT 'Inserting item extended records...'
			INSERT INTO speed_2max.dbo.item_extended(item_cde, uda_mod_dte)
			SELECT src.ItemCd, src.ItemUdaLastUpdate
			FROM #ItemExtended src
			WHERE
				src.CrudType = 'CREATE'
				AND NOT EXISTS (SELECT * FROM ItemBom.ItemExtended srcx WHERE src.ItemCd = srcx.ItemCd)
			SELECT @@ROWCOUNT as ItemExtendedInsertCount

			---- Insert item revision extended records
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