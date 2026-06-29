------------------------------------------------------------------------------------
--	CLEAR WATER FOREST PAPER MODEL DATA LOAD SCRIPT
--	Flow: IP FLOW
--
--
--
------------------------------------------------------------------------------------

USE Pdm
GO

CREATE OR ALTER PROCEDURE #LoadMappingTable AS 
BEGIN
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-099', '2001-005-046', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-101', '2001-005-005', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-102', '2001-005-047', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-104', '2001-005-048', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-308-374', '2001-005-016', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-954', '2001-005-024', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-956', '2001-005-050', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-137', '2001-005-026', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-138', '2001-005-022', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-955', '2001-005-001', 'P_TEST'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-416', '2001-005-002', 'P_TEST'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-331-544', '2001-005-003', 'P_ASSEMBLY'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-331-538', '2001-005-004', 'P_ASSEMBLY'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-168', '2001-005-010', 'P_STACK_COMBO'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-165', '2001-005-011', 'P_STACK_COMBO'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-164', '2001-005-012', 'P_STACK_COMBO'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-170', '2001-005-013', 'P_STACK_COMBO'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-139', '2001-005-025', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-160', '2001-005-020', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-161', '2001-005-018', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-162', '2001-005-019', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-163', '2001-005-021', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-174', '2001-005-008', 'P_STACK_SILICON'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-175', '2001-005-009', 'P_STACK_SILICON'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-318-181', '99Z101', 'CPU'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-252', '2001-005-049', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-255', '2001-005-027', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-326-741', '2001-005-051', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-309-093', '2001-005-023', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-326-742', '2001-005-052', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-417', '2001-005-017', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-253', '2001-005-014', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-256', '2001-005-015', 'P_DIE_PREP'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-100', '2001-005-006', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-308-373', '2001-005-028', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-415', '2001-005-029', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-309-095', '2001-005-030', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-953', '2001-005-031', 'P_SORT'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-323-251', '2001-005-032', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-308-372', '2001-005-033', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-328-416', '2001-005-034', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-309-094', '2001-005-035', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-317-955', '2001-005-036', 'P_FAB'
	INSERT INTO #ItemMapping(OldItemCd, NewItemCd, NewItemClassDsc) SELECT '2000-307-103', '2001-005-007', 'P_FAB'






END

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
SET NOCOUNT ON
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
				  Idn				INT IDENTITY
				, OldItemCd			VARCHAR(21)
				, OldItemClassCd	VARCHAR(4)
				, OldItemClassDsc	VARCHAR(18)
				, NewItemCd			VARCHAR(21)
				, NewItemClassCd	VARCHAR(4)
				, NewItemClassDsc	VARCHAR(18)
				)

		DROP TABLE IF EXISTS #Item
		CREATE TABLE #Item(
			  ItemCd				VARCHAR(21)
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
		)
		
		DROP TABLE IF EXISTS #ItemRevision
		CREATE TABLE #ItemRevision(
			  ItemCd				VARCHAR(21)
			, Revision				CHAR(2)
			, DataAdministratorCd	CHAR(8)
			, ProjectCd				VARCHAR(15)
			, StatusCd				CHAR(1)
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
		)
		
		drop table if exists #dm_bom_99Z101
		-- Create table to store BOM hierarchy with all necessary fields
		create table #dm_bom_99Z101 (
			id int identity,                    -- Unique identifier for each BOM record
			depth int,                          -- Level depth in BOM hierarchy (0=root, 1=first level, etc.)
			parent_item_cde varchar(21),        -- Parent item code in BOM relationship
			parent_item_rev char(2),            -- Parent item revision
			bom_find_nbr smallint,              -- BOM find number for ordering components
			child_item_cde varchar(21),         -- Child item code in BOM relationship
			child_item_rev char(2),             -- Child item revision
			child_qty_req numeric(12, 5),       -- Quantity of child item required
			bom_typ_cde char(1),                -- BOM type code (A=Assembly, etc.)
			no_expl_ind char(1),                -- No explosion indicator (Y/N)
			item_typ_dsc varchar(18)            -- Item type description for classification
		)

		-- Load the Mapping table with Old and New Items
		EXEC #LoadMappingTable

		UPDATE tgt
			SET tgt.OldItemClassCd = src.ClassCd
				, tgt.OldItemClassDsc = ic.ClassDsc
		FROM
			#ItemMapping tgt
			JOIN ItemBom.Item src ON tgt.OldItemCd = src.ItemCd
			JOIN ItemBom.ItemClass ic ON src.ClassCd = ic.ClassCd

		UPDATE tgt
			SET tgt.NewItemClassCd = ic.ClassCd
				
		FROM
			#ItemMapping tgt
			JOIN ItemBom.ItemClass ic ON tgt.NewItemClassDsc = ic.ClassDsc
		
		SELECT * FROM #ItemMapping

		
		-- Initialize table with root item 99Z101 at depth 0
		-- This serves as the starting point for recursive BOM explosion
		insert into #dm_bom_99Z101
		select 0,                               -- Depth 0 for root item
			   '',                              -- No parent for root item
			   '',                              -- No parent revision for root item
			   0,                               -- No BOM find number for root item
			   i.item_cde,                      -- Root item code
			   i.mfg_rev,                       -- Current manufacturing revision
			   0,                               -- No quantity for root item
			   '',                              -- No BOM type for root item
			   '',                              -- No explosion indicator for root item
			   ct.item_typ_dsc                  -- Item type description for classification
		from SPDBETA.speed_2max.dbo.item i 
		JOIN SPDBETA.speed_2max.dbo.item_type ct on i.item_typ_cde = ct.item_typ_cde	
		WHERE i.item_cde = '2000-318-181'             -- Target root item for migration

		-- =====================================================================================
		-- SECTION 2: RECURSIVE BOM EXPLOSION
		-- Purpose: Traverse BOM structure recursively to capture all child items up to 12 levels
		-- =====================================================================================

		-- Recursive Common Table Expression (CTE) to explode BOM structure
		;WITH bomCTE (depth, bom_idn, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc) AS    
		(   
			-- ANCHOR: First level of recursion - get immediate children of root item
			SELECT t.depth + 1,                 -- Increment depth for first level
				   b.bom_idn,                   -- BOM identifier from design_bom table
				   b.parent_item_cde,           -- Parent item from BOM
				   b.parent_item_rev,           -- Parent revision from BOM
				   b.bom_find_nbr,              -- BOM find number for ordering
				   b.child_item_cde,            -- Child item from BOM
				   c.mfg_rev as child_item_rev, -- Current manufacturing revision of child
				   b.child_qty_req,             -- Required quantity of child
				   b.bom_typ_cde,               -- BOM type code
				   b.no_expl_ind,               -- No explosion indicator
				   ct.item_typ_dsc              -- Item type description for classification
			FROM #dm_bom_99Z101 t      -- Start from our working table
			JOIN SPDBETA.speed_2max.dbo.design_bom b on t.child_item_cde = b.parent_item_cde and t.child_item_rev = b.parent_item_rev
			JOIN SPDBETA.speed_2max.dbo.item p on p.item_cde = b.parent_item_cde  -- Validate parent item exists
			JOIN SPDBETA.speed_2max.dbo.item c on c.item_cde = b.child_item_cde   -- Validate child item exists
			JOIN SPDBETA.speed_2max.dbo.item_type ct on c.item_typ_cde = ct.item_typ_cde  -- Get item type description
			
			UNION ALL 
	
			-- RECURSIVE: Continue traversing deeper levels of BOM
			SELECT cte.depth + 1 as depth,      -- Increment depth for each level
				   b.bom_idn,                   -- BOM identifier
				   b.parent_item_cde,           -- Parent item code
				   b.parent_item_rev,           -- Parent item revision
				   b.bom_find_nbr,              -- BOM find number
				   b.child_item_cde,            -- Child item code
				   c.mfg_rev as child_item_rev, -- Child item revision
				   b.child_qty_req,             -- Required quantity
				   b.bom_typ_cde,               -- BOM type code
				   b.no_expl_ind,               -- No explosion indicator
				   ct.item_typ_dsc              -- Item type description
			FROM bomCTE cte                      -- Reference previous level results
			join SPDBETA.speed_2max.dbo.design_bom b on b.parent_item_cde = cte.child_item_cde AND b.parent_item_rev = cte.child_item_rev
			join SPDBETA.speed_2max.dbo.item p on p.item_cde = b.parent_item_cde and p.sap_mat_typ in ('FERT','RAPP')  -- Filter for finished goods and semi-finished
			JOIN SPDBETA.speed_2max.dbo.item c on c.item_cde = b.child_item_cde   -- Validate child item exists
			JOIN SPDBETA.speed_2max.dbo.item_type ct on c.item_typ_cde = ct.item_typ_cde  -- Get item type description
			WHERE cte.depth < 12                 -- Limit recursion to 12 levels to prevent infinite loops
		)    

		-- Insert all BOM explosion results into working table
		-- DISTINCT ensures no duplicate records are inserted
		INSERT INTO #dm_bom_99Z101 (depth, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc)
		SELECT distinct depth, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc
		FROM bomCTE 
		select * from #dm_bom_99Z101

		
		-- =====================================================================================
		-- SECTION 2: RECURSIVE BOM EXPLOSION
		-- Purpose: Traverse BOM structure recursively to capture all child items up to 12 levels
		-- =====================================================================================

		-- Recursive Common Table Expression (CTE) to explode BOM structure
		;WITH bomCTE (depth, bom_idn, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc) AS    
		(   
			-- ANCHOR: First level of recursion - get immediate children of root item
			SELECT t.depth + 1,                 -- Increment depth for first level
				   b.bom_idn,                   -- BOM identifier from design_bom table
				   b.parent_item_cde,           -- Parent item from BOM
				   b.parent_item_rev,           -- Parent revision from BOM
				   b.bom_find_nbr,              -- BOM find number for ordering
				   b.child_item_cde,            -- Child item from BOM
				   c.mfg_rev as child_item_rev, -- Current manufacturing revision of child
				   b.child_qty_req,             -- Required quantity of child
				   b.bom_typ_cde,               -- BOM type code
				   b.no_expl_ind,               -- No explosion indicator
				   ct.item_typ_dsc              -- Item type description for classification
			FROM #dm_bom_99Z101 t      -- Start from our working table
			JOIN SPDBETA.speed_2max.dbo.design_bom b on t.child_item_cde = b.parent_item_cde and t.child_item_rev = b.parent_item_rev
			JOIN SPDBETA.speed_2max.dbo.item p on p.item_cde = b.parent_item_cde  -- Validate parent item exists
			JOIN SPDBETA.speed_2max.dbo.item c on c.item_cde = b.child_item_cde   -- Validate child item exists
			JOIN SPDBETA.speed_2max.dbo.item_type ct on c.item_typ_cde = ct.item_typ_cde  -- Get item type description
			
			UNION ALL 
	
			-- RECURSIVE: Continue traversing deeper levels of BOM
			SELECT cte.depth + 1 as depth,      -- Increment depth for each level
				   b.bom_idn,                   -- BOM identifier
				   b.parent_item_cde,           -- Parent item code
				   b.parent_item_rev,           -- Parent item revision
				   b.bom_find_nbr,              -- BOM find number
				   b.child_item_cde,            -- Child item code
				   c.mfg_rev as child_item_rev, -- Child item revision
				   b.child_qty_req,             -- Required quantity
				   b.bom_typ_cde,               -- BOM type code
				   b.no_expl_ind,               -- No explosion indicator
				   ct.item_typ_dsc              -- Item type description
			FROM bomCTE cte                      -- Reference previous level results
			join SPDBETA.speed_2max.dbo.design_bom b on b.parent_item_cde = cte.child_item_cde AND b.parent_item_rev = cte.child_item_rev
			join SPDBETA.speed_2max.dbo.item p on p.item_cde = b.parent_item_cde and p.sap_mat_typ in ('FERT','RAPP')  -- Filter for finished goods and semi-finished
			JOIN SPDBETA.speed_2max.dbo.item c on c.item_cde = b.child_item_cde   -- Validate child item exists
			JOIN SPDBETA.speed_2max.dbo.item_type ct on c.item_typ_cde = ct.item_typ_cde  -- Get item type description
			WHERE cte.depth < 12                 -- Limit recursion to 12 levels to prevent infinite loops
		)    

		-- Insert all BOM explosion results into working table
		-- DISTINCT ensures no duplicate records are inserted
		INSERT INTO #dm_bom_99Z101 (depth, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc)
		SELECT distinct depth, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc
		FROM bomCTE 
		 
		 select * from #dm_bom_99Z101
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