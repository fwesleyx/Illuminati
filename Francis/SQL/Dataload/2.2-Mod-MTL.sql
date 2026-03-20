use speed_2max
go

-- =====================================================================================
-- SCRIPT 1: BOM MIGRATION AND ITEM RECLASSIFICATION FOR 99CDJZ
-- MTL MODEL
-- Purpose: Migrate and reclassify items from UPI (Unpackaged Integrated) to P (Packaged) types
-- Author: PLM Migration Team
-- Date: [Current Date]
-- =====================================================================================

-- Set application context for PLM system tracking
EXEC sp_set_session_context 'AppName', 'PLM'; 

-- =====================================================================================
-- SECTION 1: CREATE BOM EXPLOSION TABLE
-- Purpose: Create working table to store hierarchical BOM structure
-- =====================================================================================

-- Drop existing table if it exists to ensure clean start
--drop table if exists workdb.dbo.dm_bom_99CDJZ

-- Create table to store BOM hierarchy with all necessary fields
create table workdb.dbo.dm_bom_99CDJZ (
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

-- Initialize table with root item 99CDJZ at depth 0
-- This serves as the starting point for recursive BOM explosion
insert into workdb.dbo.dm_bom_99CDJZ
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
from item i 
JOIN item_type ct on i.item_typ_cde = ct.item_typ_cde	
WHERE i.item_cde = '99CDJZ'             -- Target root item for migration

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
	FROM workdb.dbo.dm_bom_99CDJZ t      -- Start from our working table
	JOIN design_bom b on t.child_item_cde = b.parent_item_cde and t.child_item_rev = b.parent_item_rev
	JOIN item p on p.item_cde = b.parent_item_cde  -- Validate parent item exists
	JOIN item c on c.item_cde = b.child_item_cde   -- Validate child item exists
	JOIN item_type ct on c.item_typ_cde = ct.item_typ_cde  -- Get item type description
			
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
	join design_bom b on b.parent_item_cde = cte.child_item_cde AND b.parent_item_rev = cte.child_item_rev
	join item p on p.item_cde = b.parent_item_cde and p.sap_mat_typ in ('FERT','RAPP')  -- Filter for finished goods and semi-finished
	JOIN item c on c.item_cde = b.child_item_cde   -- Validate child item exists
	JOIN item_type ct on c.item_typ_cde = ct.item_typ_cde  -- Get item type description
	WHERE cte.depth < 12                 -- Limit recursion to 12 levels to prevent infinite loops
)    

-- Insert all BOM explosion results into working table
-- DISTINCT ensures no duplicate records are inserted
INSERT INTO workdb.dbo.dm_bom_99CDJZ (depth, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc)
SELECT distinct depth, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc
FROM bomCTE 

-- =====================================================================================
-- SECTION 3: CREATE ITEM CLASSIFICATION TABLE
-- Purpose: Create table to manage item type transformations and new item assignments
-- =====================================================================================

-- Drop existing items table if it exists
drop table if exists workdb.dbo.dm_items_99CDJZ

-- Create table to store item classification mapping
create table workdb.dbo.dm_items_99CDJZ (
	id int identity,                    -- Unique identifier for each item record
	item_cde varchar(21),               -- Original item code
	item_rev char(2),                   -- Item revision
	item_typ_dsc varchar(18),           -- Current item type description
	to_item_typ_dsc varchar(18),        -- Target item type description after migration
	new_item_cde varchar(21)            -- New item code to be assigned
)

-- =====================================================================================
-- SECTION 4: APPLY INITIAL CLASSIFICATION RULES
-- Purpose: Apply business rules to determine target item types for migration
-- =====================================================================================

-- Rule 1: All FERT (Finished Goods) items become UPI_FINISH
-- FERT items are final products that need to be classified as finished UPI items
insert into workdb.dbo.dm_items_99CDJZ (item_cde, item_rev, item_typ_dsc, to_item_typ_dsc)
select distinct child_item_cde,         -- Item code from BOM explosion
       child_item_rev,                  -- Item revision
       item_typ_dsc,                    -- Current item type description
       'UPI_FINISH'                     -- Target classification for all FERT items
from workdb.dbo.dm_bom_99CDJZ b 
join item i on b.child_item_cde = i.item_cde
where i.sap_mat_typ = 'FERT'           -- Filter for finished goods only

-- Rule 2: All RAPP (Semi-finished) items get P_ prefix instead of UPI_
-- RAPP items are intermediate products that need to be converted from UPI to P classification
insert into workdb.dbo.dm_items_99CDJZ (item_cde, item_rev, item_typ_dsc, to_item_typ_dsc)
select distinct child_item_cde,         -- Item code from BOM explosion
       child_item_rev,                  -- Item revision
       item_typ_dsc,                    -- Current item type description
       replace(item_typ_dsc, 'UPI_', 'P_')  -- Replace UPI_ prefix with P_
from workdb.dbo.dm_bom_99CDJZ b 
join item i on b.child_item_cde = i.item_cde
where i.sap_mat_typ = 'RAPP'           -- Filter for semi-finished goods only

-- =====================================================================================
-- SECTION 5: APPLY SPECIAL STACK LOGIC
-- Purpose: Apply complex business rules for stack-type items based on BOM relationships
-- =====================================================================================

-- Special Rule 1: UPI_BUMP items become P_STACK_COMBO under specific conditions
-- Condition: UPI_BUMP item has UPI_DIE_PREP as both parent and child in BOM structure
-- This indicates a stacking relationship that requires combo classification
update i 
set i.to_item_typ_dsc = 'P_STACK_COMBO'
from workdb.dbo.dm_items_99CDJZ i
join workdb.dbo.dm_bom_99CDJZ b1 on i.item_cde = b1.child_item_cde   -- Item is child in BOM
join workdb.dbo.dm_items_99CDJZ p on b1.parent_item_cde = p.item_cde and p.item_typ_dsc = 'UPI_DIE_PREP'  -- Parent is UPI_DIE_PREP
join workdb.dbo.dm_bom_99CDJZ b2 on i.item_cde = b2.parent_item_cde  -- Same item is parent in another BOM
join workdb.dbo.dm_items_99CDJZ c on b2.child_item_cde = c.item_cde and c.item_typ_dsc = 'UPI_DIE_PREP'   -- Child is UPI_DIE_PREP
where i.item_typ_dsc = 'UPI_BUMP'      -- Only apply to UPI_BUMP items

-- Special Rule 2: UPI_DIE_PREP items become P_STACK_SILICON under specific conditions
-- Condition: UPI_DIE_PREP item has UPI_ASSEMBLY as parent and UPI_BUMP as child
-- This indicates a silicon stacking relationship
update i 
set i.to_item_typ_dsc = 'P_STACK_SILICON'
from workdb.dbo.dm_items_99CDJZ i
join workdb.dbo.dm_bom_99CDJZ b1 on i.item_cde = b1.child_item_cde   -- Item is child in BOM
join workdb.dbo.dm_items_99CDJZ p on b1.parent_item_cde = p.item_cde and p.item_typ_dsc = 'UPI_ASSEMBLY'  -- Parent is UPI_ASSEMBLY
join workdb.dbo.dm_bom_99CDJZ b2 on i.item_cde = b2.parent_item_cde  -- Same item is parent in another BOM
join workdb.dbo.dm_items_99CDJZ c on b2.child_item_cde = c.item_cde and c.item_typ_dsc = 'UPI_BUMP'       -- Child is UPI_BUMP
where i.item_typ_dsc = 'UPI_DIE_PREP'  -- Only apply to UPI_DIE_PREP items

-- =====================================================================================
-- SECTION 6: ITEM CREATION LOOP
-- Purpose: Create new items with updated classifications using item bank codes
-- =====================================================================================

-- Declare variables for item creation loop
declare @item_cde varchar(21)          -- Current item code being processed
declare @item_rev char(2)              -- Current item revision
declare @new_item_cde varchar(21)      -- New item code from item bank
declare @new_item_typ_cde char(4)      -- New item type code
declare @new_item_typ_dsc varchar(18)  -- New item type description
declare @DivisionId int                -- Division ID for organizational assignment
declare @id int = 1                    -- Loop counter starting at 1

-- Disable triggers during bulk operations to improve performance and avoid cascading effects
ALTER TABLE item DISABLE TRIGGER plm_item_i;           -- Disable item insert trigger
ALTER TABLE item DISABLE TRIGGER plm_item_u;           -- Disable item update trigger
ALTER TABLE item_revision DISABLE TRIGGER plm_item_revision_i;  -- Disable item revision insert trigger
ALTER TABLE item_revision DISABLE TRIGGER plm_item_revision_u;  -- Disable item revision update trigger
ALTER TABLE uda_item DISABLE TRIGGER plm_uda_item_i;   -- Disable UDA insert trigger
ALTER TABLE uda_item DISABLE TRIGGER plm_uda_item_u;   -- Disable UDA update trigger

-- Main processing loop - iterate through each item in classification table
while exists (select top 1 1 from workdb.dbo.dm_items_99CDJZ where id = @id )
begin 
	print @id  -- Print current iteration for monitoring progress
	
	-- Initialize variables for each iteration
	select @new_item_cde = null
	select @new_item_typ_cde = null
	
	-- Get next available item code from SAP material item bank
	-- Item bank contains pre-allocated item codes for new items
	select @new_item_cde = item_cde
	from sap_mat_item_bank 
	where sap_mat_typ = 'RAPP'          -- Filter for semi-finished material type
	  and used_ind = 'N'                -- Only unused item codes
	order by cre_item_id                -- Use oldest available codes first

	-- Get item details and mapping information for current iteration
	select @item_cde = t.item_cde,                    -- Original item code
	       @item_rev = i.mfg_rev,                     -- Current manufacturing revision
		   @new_item_typ_dsc = t.to_item_typ_dsc,     -- Target item type description
	       @new_item_typ_cde = it.item_typ_cde,       -- Target item type code
		   @DivisionId = it.DivisionId                -- Division ID from item type
	from workdb.dbo.dm_items_99CDJZ t
	join item i on t.item_cde = i.item_cde            -- Get current item details
	join (select distinct as_is_item_typ_dsc, to_be_item_typ_dsc 
	      from workdb..IBC_class_mapping 
	      where as_is_item_typ_dsc <> to_be_item_typ_dsc) m  -- Get classification mapping
	     on t.item_typ_dsc = as_is_item_typ_dsc and to_be_item_typ_dsc = t.to_item_typ_dsc
	join item_type it on it.item_typ_dsc = m.to_be_item_typ_dsc  -- Get target item type details
	where t.id = @id 
			
	-- Only proceed if we have both a new item code and valid item type
	if (@new_item_cde is not null and @new_item_typ_cde is not null)
	begin
		-- Create new item record by copying from original item
		insert into item
		select @new_item_cde,                         -- New item code from item bank
		       @new_item_typ_cde,                     -- New item type code
		       comdt_cde,                             -- Copy commodity code
		       uom,                                   -- Copy unit of measure
		       ryl_cde,                               -- Copy royalty code
		       rcmd_cde,                              -- Copy recommendation code
		       make_buy_cde,                          -- Copy make/buy indicator
		       six_mo_pln_qty,                        -- Copy 6-month plan quantity
		       std_cst,                               -- Copy standard cost
		       act_cst,                               -- Copy actual cost
			   act_cst_src,                           -- Copy actual cost source
			   future_cst,                            -- Copy future cost
			   null as future_cst_eff_dte,            -- Clear future cost effective date
			   sap_mat_typ,                           -- Copy SAP material type
			   owning_sys,                            -- Copy owning system
			   unit_of_wgt,                           -- Copy unit of weight
			   net_wgt,                               -- Copy net weight
			   gross_wgt,                             -- Copy gross weight
			   sap_dup_reas_idn,                      -- Copy SAP duplicate reason
			   null as sap_lst_mod_dte,               -- Clear SAP last modified date
			   dsc,                                   -- Copy description
			   '01' as eng_rev,                       -- Set engineering revision to 01
			   '01' as mfg_rev,                       -- Set manufacturing revision to 01
			   0 as aml_cnt,                          -- Reset AML count to 0
			   null as md0_fd_dte,                    -- Clear MD0 freeze date
			   null as lst_cls_chg_dte,               -- Clear last class change date
			   item_recommend_idn,                    -- Copy item recommendation ID
			   gtin,                                  -- Copy GTIN
			   scrty_cls_idn,                         -- Copy security class ID
			   tst_vhcl_ind,                          -- Copy test vehicle indicator
			   bin_splt_ind,                          -- Copy bin split indicator
			   sls_sts_cde,                           -- Copy sales status code
			   cust_pos,                              -- Copy customer position
			   dsc_full,                              -- Copy full description
			   'Not Migrated' as MigrationStatusNm,   -- Set migration status
			   @DivisionId                            -- Set division ID
		from item 
		where item_cde = @item_cde                    -- Copy from original item
		
		-- Create new item revision record
		insert into item_revision
		select @new_item_cde,                         -- New item code
		       '01' as item_rev,                      -- Set revision to 01
		       data_administrator,                    -- Copy data administrator
		       proj_cde,                              -- Copy project code
		       'k' as lvl_idn,                        -- Set level ID to 'k' (active)
		       bus_unit_idn,                          -- Copy business unit ID
		       add_dsc,                               -- Copy additional description
			   getdate() as cre_dte,                  -- Set creation date to now
			   getdate() as lst_mod_dte,              -- Set last modified date to now
			   file_cnt,                              -- Copy file count
			   bom_cnt,                               -- Copy BOM count
			   responsible_eng,                       -- Copy responsible engineer
			   cm1_evnt_idn,                          -- Copy CM1 event ID
			   null as eol_dte                        -- Clear end of life date
		from item_revision ir 
		where item_cde = @item_cde and item_rev = @item_rev	-- Copy from original revision
	
		-- Create item plant records for all plants where original item exists
		insert into item_plant
		select @new_item_cde,                         -- New item code
		       plnt_idn,                              -- Copy plant ID
		       prod_strt_dte,                         -- Copy production start date
		       prod_end_dte,                          -- Copy production end date
		       mrp_bom_ext_dte,                       -- Copy MRP BOM extract date
		       mpor_ctrl_ind,                         -- Copy MPOR control indicator
		       mpor_asof_dte,                         -- Copy MPOR as-of date
		       '' as start_site_ind                   -- Clear start site indicator
		from item_plant 
		where item_cde = @item_cde                    -- Copy from original item

		-- Create UDA (User Defined Attributes) records with mapping
		-- Only copy UDAs that have valid mappings in the classification system
		insert into uda_item	
		select @new_item_cde,                         -- New item code
		       ui.att_idn,                            -- Attribute ID
		       ui.seq_nbr,                            -- Sequence number
		       ui.val_txt,                            -- Text value
		       ui.val_flt,                            -- Float value
		       ui.val_dte,                            -- Date value
		       ui.mdul_idn,                           -- Module ID
		       '' as lst_mod_usr,                     -- Clear last modified user
		       getdate() as lst_mod_dte               -- Set last modified date to now
		from item i 
		join uda_item ui on i.item_cde = ui.item_cde  -- Get UDA records for original item
		join item_type it on i.item_typ_cde = it.item_typ_cde  -- Get item type
		left join workdb..IBC_class_mapping m on m.as_is_item_typ_dsc = it.item_typ_dsc and ui.att_idn = m.att_idn	-- Check for UDA mapping
		where i.item_cde = @item_cde	              -- Filter for current item
		and to_be_item_typ_dsc = @new_item_typ_dsc    -- Match target item type
		and to_be_att_nme is not null                 -- Only copy mapped attributes

		-- Update working table with assigned new item code
		update workdb.dbo.dm_items_99CDJZ 
		set new_item_cde = @new_item_cde
		where id = @id

		-- Mark item code as used in item bank to prevent reuse
		update sap_mat_item_bank 
		set used_ind = 'Y',                           -- Mark as used
		    used_dte = getdate()                      -- Set used date
		where item_cde = @new_item_cde 
		  and sap_mat_typ = 'RAPP' 
		  and used_ind = 'N'                          -- Only update if currently unused
	end

	-- Move to next item in the list
	select @id = @id + 1 
end

-- Re-enable triggers after bulk operations complete
ALTER TABLE item ENABLE TRIGGER plm_item_i;
ALTER TABLE item ENABLE TRIGGER plm_item_u;
ALTER TABLE item_revision ENABLE TRIGGER plm_item_revision_i;
ALTER TABLE item_revision ENABLE TRIGGER plm_item_revision_u;
ALTER TABLE uda_item ENABLE TRIGGER plm_uda_item_i;
ALTER TABLE uda_item ENABLE TRIGGER plm_uda_item_u;

-- =====================================================================================
-- SECTION 7: UP-REVISION IP FINISHED GOODS ITEM
-- Purpose: Create new revision for the root IP finished goods item
-- =====================================================================================

-- Declare variables for revision management
declare @item_cde varchar(21)          -- Root item code
declare @item_rev char(2)              -- Current revision
declare @new_item_rev char(2)          -- New revision to be created

-- Get root item details from BOM explosion table
select @item_cde = child_item_cde,      -- Root item code (99CDJZ)
       @item_rev = child_item_rev       -- Current revision
from workdb.dbo.dm_bom_99CDJZ where id = 1  -- ID 1 is always the root item

-- Calculate next revision number by incrementing highest existing revision
select @new_item_rev = max(item_rev) + 1 from item_revision where item_cde = @item_cde
-- Pad with leading zero if needed (e.g., 9 becomes '09')
select @new_item_rev = replicate('0', 2 -len(@new_item_rev)) + @new_item_rev 

-- Disable triggers for revision operations
ALTER TABLE item DISABLE TRIGGER plm_item_i;
ALTER TABLE item DISABLE TRIGGER plm_item_u;
ALTER TABLE item_revision DISABLE TRIGGER plm_item_revision_i;
ALTER TABLE item_revision DISABLE TRIGGER plm_item_revision_u;

-- Create new active revision for IP finished goods item
insert into item_revision 
select @item_cde,                              -- Item code
       @new_item_rev as item_rev,              -- New revision number
       data_administrator,                     -- Copy data administrator
       proj_cde,                               -- Copy project code
       lvl_idn,                                -- Copy level ID (should be active)
       bus_unit_idn,                           -- Copy business unit ID
       add_dsc,                                -- Copy additional description
	   getdate() as cre_dte,                   -- Set creation date to now
	   getdate() as lst_mod_dte,               -- Set last modified date to now
	   file_cnt,                               -- Copy file count
	   bom_cnt,                                -- Copy BOM count
	   responsible_eng,                        -- Copy responsible engineer
	   cm1_evnt_idn,                           -- Copy CM1 event ID
	   null as eol_dte                         -- Clear end of life date
from item_revision ir 
where item_cde = @item_cde and item_rev = @item_rev	-- Copy from current revision

-- Inactivate old revision by setting level ID to '8' (inactive)
update item_revision 
set lvl_idn = '8',                             -- Set to inactive status
    lst_mod_dte = getdate()                    -- Update last modified date
where item_cde = @item_cde and item_rev = @item_rev	-- Target old revision

-- =====================================================================================
-- SECTION 8: RECLASSIFY STACK ITEMS
-- Purpose: Update item classifications for stack-type items in the main item table
-- =====================================================================================

-- Update item type codes for stack items that were identified in classification process
-- Convert P_ prefix back to UPI_ for items that need stack classifications
update i set item_typ_cde = it.item_typ_cde
from workdb.dbo.dm_items_99CDJZ t 
join item i on t.item_cde = i.item_cde                -- Join with actual item table
join item_type it on replace(t.to_item_typ_dsc,'P_','UPI_') = it.item_typ_dsc  -- Convert P_ back to UPI_ for lookup
where to_item_typ_dsc like '%STACK%'                  -- Only apply to stack-type items

-- Re-enable triggers after item updates
ALTER TABLE item ENABLE TRIGGER plm_item_i;
ALTER TABLE item ENABLE TRIGGER plm_item_u;
ALTER TABLE item_revision ENABLE TRIGGER plm_item_revision_i;
ALTER TABLE item_revision ENABLE TRIGGER plm_item_revision_u;

-- =====================================================================================
-- SECTION 9: BOM STRUCTURE CREATION
-- Purpose: Create new BOM relationships linking IP and IF items with updated structure
-- =====================================================================================

-- Add columns to track BOM IDs for IP and IF structures
alter table workdb.dbo.dm_bom_99CDJZ add bom_idn_ip int;  -- BOM ID for IP (In-Process) structure
alter table workdb.dbo.dm_bom_99CDJZ add bom_idn_if int;  -- BOM ID for IF (Intermediate Finished) structure

-- Get starting BOM ID from system counter
declare @bom_idn int
select @bom_idn = value_1 -1 from codes_and_values where idn = 'NEXT BOM IDN'

-- Assign BOM IDs for IF structure (root item BOM)
-- This creates the BOM for the new IF finished goods item
update t
set bom_idn_if = bom_idn
FROM (SELECT id, bom_idn_if, @bom_idn + row_number() OVER (ORDER BY id) as bom_idn 
      from workdb.dbo.dm_bom_99CDJZ
      where parent_item_cde = '99CDJZ' and parent_item_rev = '08')t  -- Root item BOM entries

-- Update counter after IF BOM ID assignment
select @bom_idn = @bom_idn + @@ROWCOUNT

-- Assign BOM IDs for IP structure (all other BOM relationships)
-- This creates BOMs for all intermediate items
update t
set bom_idn_ip = bom_idn
FROM (SELECT id, bom_idn_ip, @bom_idn + row_number() OVER (ORDER BY id) as bom_idn 
      from workdb.dbo.dm_bom_99CDJZ where id > 1)t  -- All non-root BOM entries

-- Update counter after IP BOM ID assignment
select @bom_idn = @bom_idn + @@ROWCOUNT

-- Update system counter with next available BOM ID
update codes_and_values set value_1 = @bom_idn + 1 where idn = 'NEXT BOM IDN'

-- Declare variables for BOM creation
declare @item_cde varchar(21)          -- Root item code
declare @item_rev char(2)              -- Current revision
declare @new_item_rev char(2) = '09'   -- New revision number

-- Get root item details
select @item_cde = child_item_cde, 
       @item_rev = child_item_rev	   
from workdb.dbo.dm_bom_99CDJZ where id = 1 

-- Disable triggers for BOM operations
ALTER TABLE design_bom DISABLE TRIGGER plm_design_bom_i;
ALTER TABLE design_bom DISABLE TRIGGER plm_design_bom_u;
ALTER TABLE item_revision DISABLE TRIGGER plm_item_revision_i;
ALTER TABLE item_revision DISABLE TRIGGER plm_item_revision_u;

-- =====================================================================================
-- SECTION 10: CREATE IP FINISHED GOODS BOM
-- Purpose: Link IP finished goods item with new IP child items
-- =====================================================================================

-- Create BOM entries linking IP finished goods (new revision) with child items
-- Use new item codes where available, otherwise use original item codes
insert into design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select bom_idn_ip,                             -- Pre-assigned BOM ID for IP structure
       parent_item_cde,                        -- Parent item code (99CDJZ)
       @new_item_rev,                          -- New revision (09)
       bom_find_nbr,                           -- BOM find number for ordering
	   isnull(i.new_item_cde, b.child_item_cde) as child_item_cde,  -- Use new item code if available, otherwise original
	   child_qty_req,                          -- Required quantity
	   bom_typ_cde,                            -- BOM type code
	   no_expl_ind                             -- No explosion indicator
from workdb.dbo.dm_bom_99CDJZ b 
left join workdb.dbo.dm_items_99CDJZ i on b.child_item_cde = i.item_cde  -- Left join to get new item codes
where parent_item_cde = @item_cde and parent_item_rev = @item_rev  -- Only root item children

-- =====================================================================================
-- SECTION 11: CREATE IF FINISHED GOODS BOM
-- Purpose: Link new IF finished goods items with their child items
-- =====================================================================================

-- Create BOM entries for new IF finished goods items
-- These are the new items created from the original root item's children
insert into design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select bom_idn_if,                             -- Pre-assigned BOM ID for IF structure
       i.new_item_cde,                         -- New IF item code as parent
       '01' as parent_item_rev,                -- Revision 01 for new items
       bom_find_nbr,                           -- BOM find number
	   child_item_cde,                         -- Original child item code
	   child_qty_req,                          -- Required quantity
	   bom_typ_cde,                            -- BOM type code
	   no_expl_ind                             -- No explosion indicator
from workdb.dbo.dm_bom_99CDJZ b 
join workdb.dbo.dm_items_99CDJZ i on b.parent_item_cde = i.item_cde  -- Get new item codes for parents
where parent_item_cde = @item_cde and parent_item_rev = @item_rev     -- Only root item children

-- =====================================================================================
-- SECTION 12: CREATE IP BOM FOR RAPP ITEMS
-- Purpose: Create BOM structures for all intermediate RAPP items
-- =====================================================================================

-- Create BOM entries for all intermediate items (RAPP items)
-- This links new parent items with their children (new or original)
insert into design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select b.bom_idn_ip,                           -- Pre-assigned BOM ID for IP structure
       p.new_item_cde,                         -- New parent item code
       '01',                                   -- Revision 01 for new items
       bom_find_nbr,                           -- BOM find number
       isnull(c.new_item_cde, b.child_item_cde),  -- Use new child item code if available, otherwise original
       child_qty_req,                          -- Required quantity
       bom_typ_cde,                            -- BOM type code
       no_expl_ind                             -- No explosion indicator
from workdb.dbo.dm_bom_99CDJZ b 
join workdb.dbo.dm_items_99CDJZ p on b.parent_item_cde = p.item_cde      -- Get new parent item codes
left join workdb.dbo.dm_items_99CDJZ c on b.child_item_cde = c.item_cde  -- Get new child item codes if available
where b.id > 1                                 -- Exclude root item (ID 1)
  and b.parent_item_cde <> @item_cde           -- Exclude root item as parent
  and b.parent_item_rev <> @item_rev           -- Exclude root item revision

-- Re-enable triggers after BOM operations complete
ALTER TABLE design_bom ENABLE TRIGGER plm_design_bom_i;
ALTER TABLE design_bom ENABLE TRIGGER plm_design_bom_u;
ALTER TABLE item_revision ENABLE TRIGGER plm_item_revision_i;
ALTER TABLE item_revision ENABLE TRIGGER plm_item_revision_u;

-- =====================================================================================
-- SCRIPT 1 COMPLETION
-- Purpose: Script 1 (99CDJZ) migration and reclassification is now complete
-- =====================================================================================

-- At this point, the script has:
-- 1. Exploded the BOM structure for item 99CDJZ
-- 2. Applied classification rules to determine target item types
-- 3. Created new items with updated classifications
-- 4. Created new revision for the root IP item
-- 5. Reclassified stack items in the main item table
-- 6. Created new BOM structures linking IP and IF items
-- 7. Maintained data integrity throughout the process

-- The migration is ready for the next phase (Script 2: 99CL4D)