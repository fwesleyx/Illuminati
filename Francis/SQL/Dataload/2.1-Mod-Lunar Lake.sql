use speed_2max
go

-- =====================================================================================
-- SCRIPT 2: BOM MIGRATION AND ITEM RECLASSIFICATION FOR 99CL4D
-- Lunar Lake
-- Purpose: Advanced migration with BETADATA synchronization and special item handling
-- Author: PLM Migration Team
-- Date: [Current Date]
-- Dependencies: Requires BETADATA environment access and completed Script 1 (99CDJZ)
-- =====================================================================================

-- Set application context for PLM system tracking and audit trail
EXEC sp_set_session_context 'AppName', 'PLM'; 

-- =====================================================================================
-- SECTION 1: DATA SYNCHRONIZATION FROM BETADATA
-- Purpose: Import processed BOM and item data from BETADATA test environment
-- Note: This section copies pre-processed data rather than regenerating it
-- =====================================================================================

/*
-- Import BOM explosion data from BETADATA environment
-- This table contains the hierarchical BOM structure already processed in BETADATA
select * 
into workdb.dbo.dm_bom_99CL4D
from BETADATA.workdb.dbo.dm_bom_99CL4D

-- Import item classification mapping from BETADATA environment  
-- This table contains the item type transformations already determined in BETADATA
select * 
into workdb.dbo.dm_items_99CL4D
from BETADATA.workdb.dbo.dm_items_99CL4D
*/

-- =====================================================================================
-- SECTION 2: ITEM MASTER DATA SYNCHRONIZATION
-- Purpose: Synchronize item master data between BETADATA and current environment
-- =====================================================================================

/*
-- Update item master data from BETADATA source to ensure consistency
-- This comprehensive update synchronizes all item attributes
begin tran

update a
set item_typ_cde=b.item_typ_cde,              -- Update item type code
comdt_cde=b.comdt_cde,                        -- Update commodity code
uom=b.uom,                                    -- Update unit of measure
ryl_cde=b.ryl_cde,                            -- Update royalty code
rcmd_cde=b.rcmd_cde,                          -- Update recommendation code
make_buy_cde=b.make_buy_cde,                  -- Update make/buy indicator
six_mo_pln_qty=b.six_mo_pln_qty,              -- Update 6-month plan quantity
std_cst=b.std_cst,                            -- Update standard cost
act_cst=b.act_cst,                            -- Update actual cost
act_cst_src=b.act_cst_src,                    -- Update actual cost source
future_cst=b.future_cst,                      -- Update future cost
future_cst_eff_dte=b.future_cst_eff_dte,      -- Update future cost effective date
sap_mat_typ=b.sap_mat_typ,                    -- Update SAP material type
owning_sys=b.owning_sys,                      -- Update owning system
unit_of_wgt=b.unit_of_wgt,                    -- Update unit of weight
net_wgt=b.net_wgt,                            -- Update net weight
gross_wgt=b.gross_wgt,                        -- Update gross weight
sap_dup_reas_idn=b.sap_dup_reas_idn,          -- Update SAP duplicate reason ID
sap_lst_mod_dte=b.sap_lst_mod_dte,            -- Update SAP last modified date
dsc=b.dsc,                                    -- Update description
eng_rev=b.eng_rev,                            -- Update engineering revision
mfg_rev=b.mfg_rev,                            -- Update manufacturing revision
aml_cnt=b.aml_cnt,                            -- Update AML count
md0_fd_dte=b.md0_fd_dte,                      -- Update MD0 freeze date
lst_cls_chg_dte=b.lst_cls_chg_dte,            -- Update last class change date
item_recommend_idn=b.item_recommend_idn,      -- Update item recommendation ID
gtin=b.gtin,                                  -- Update GTIN
scrty_cls_idn=b.scrty_cls_idn,                -- Update security class ID
tst_vhcl_ind=b.tst_vhcl_ind,                  -- Update test vehicle indicator
bin_splt_ind=b.bin_splt_ind,                  -- Update bin split indicator
sls_sts_cde=b.sls_sts_cde,                    -- Update sales status code
cust_pos=b.cust_pos,                          -- Update customer position
dsc_full=b.dsc_full,                          -- Update full description
MigrationStatusNm=b.MigrationStatusNm         -- Update migration status
from BETADATA.speed_2max.dbo.item b 
join speed_2max.dbo.item a on a.item_cde = b.item_cde
where a.item_cde = '99CL4D'                   -- Only update the root item

commit tran
*/

-- =====================================================================================
-- SECTION 3: ITEM REVISION SYNCHRONIZATION
-- Purpose: Import missing item revisions from BETADATA environment
-- =====================================================================================

/*
-- Import item revisions that don't exist in current environment
-- Disable trigger to prevent cascading effects during bulk insert
ALTER TABLE item_revision DISABLE TRIGGER item_revision_i;

insert into speed_2max.dbo.item_revision
select item_cde,item_rev,data_administrator,proj_cde,lvl_idn,bus_unit_idn,add_dsc,cre_dte,lst_mod_dte,file_cnt,bom_cnt,responsible_eng,cm1_evnt_idn,eol_dte
from BETADATA.speed_2max.dbo.item_revision 
where item_cde = '99CL4D' and item_rev <> '00'  -- Import all revisions except base revision

-- Re-enable trigger after bulk operation
ALTER TABLE item_revision ENABLE TRIGGER item_revision_i;
 
-- Create item revision key mappings for imported revisions
insert into item_revision_key_map (item_cde, item_rev)
select item_cde, item_rev
from item_revision 
where item_cde = '99CL4D' and item_rev <> '00'
*/

-- =====================================================================================
-- SECTION 4: MISSING ITEM CREATION
-- Purpose: Create items that exist in BOM but not in current environment
-- =====================================================================================

/*
-- Create missing items that are referenced in BOM but don't exist locally
insert into item 
(item_cde,item_typ_cde,comdt_cde,uom,ryl_cde,rcmd_cde,make_buy_cde,six_mo_pln_qty,std_cst,act_cst,act_cst_src,future_cst,
future_cst_eff_dte,sap_mat_typ,owning_sys,unit_of_wgt,net_wgt,gross_wgt,sap_dup_reas_idn,sap_lst_mod_dte,dsc,eng_rev,mfg_rev,aml_cnt,
md0_fd_dte,lst_cls_chg_dte,item_recommend_idn,gtin,scrty_cls_idn,tst_vhcl_ind,bin_splt_ind,sls_sts_cde,cust_pos,dsc_full,MigrationStatusNm)
select * from BETADATA.speed_2max.dbo.item where item_cde in ('2000-311-262','2000-328-525','2000-328-527')

-- Create corresponding item revisions for missing items
insert into item_revision
select * from BETADATA.speed_2max.dbo.item_revision where item_cde in ('2000-311-262','2000-328-525','2000-328-527')

-- Create item plant records for missing items
insert into item_plant
select *,'N' from BETADATA.speed_2max.dbo.item_plant where item_cde in ('2000-311-262','2000-328-525','2000-328-527')
*/

-- =====================================================================================
-- SECTION 5: BOM STRUCTURE IMPORT
-- Purpose: Import BOM relationships from BETADATA environment
-- =====================================================================================

/*
-- Get next available BOM ID from system counter
declare @bom_idn int
select @bom_idn = value_1 -1 from codes_and_values where idn = 'NEXT BOM IDN'

-- Import BOM structure from working table
-- Assign sequential BOM IDs to all BOM relationships
insert into design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select @bom_idn + id - 1,                     -- Sequential BOM ID assignment
       parent_item_cde,                        -- Parent item code
       parent_item_rev,                        -- Parent item revision
       bom_find_nbr,                           -- BOM find number for ordering
       child_item_cde,                         -- Child item code
       child_qty_req,                          -- Required quantity
       bom_typ_cde,                            -- BOM type code
       no_expl_ind                             -- No explosion indicator
from workdb.dbo.dm_bom_99CL4D
where id > 1                                  -- Skip root item (ID 1)

-- Update system counter with next available BOM ID
select @bom_idn = max(bom_idn) from design_bom 
update codes_and_values set value_1 = @bom_idn + 1 where idn = 'NEXT BOM IDN'
*/

-- =====================================================================================
-- SECTION 6: ITEM CREATION AND MIGRATION PROCESS
-- Purpose: Create new items with updated classifications using same logic as Script 1
-- =====================================================================================

-- Declare variables for item creation loop (same as Script 1)
declare @item_cde varchar(21)          -- Current item code being processed
declare @item_rev char(2)              -- Current item revision
declare @new_item_cde varchar(21)      -- New item code from predefined mapping
declare @new_item_typ_cde char(4)      -- New item type code
declare @new_item_typ_dsc varchar(18)  -- New item type description
declare @DivisionId int                -- Division ID for organizational assignment
declare @id int = 1                    -- Loop counter starting at 1

-- Main processing loop - iterate through each item in classification table
while exists (select top 1 1 from workdb.dbo.dm_items_99CL4D where id = @id )
begin 
	print @id  -- Print current iteration for monitoring progress
	
	-- Initialize variables for each iteration
	select @new_item_cde = null
	select @new_item_typ_cde = null
	
	-- Note: Unlike Script 1, this uses predefined item code mappings rather than item bank
	-- Get item details and mapping information for current iteration
	select @item_cde = t.item_cde,                    -- Original item code
	       @item_rev = i.mfg_rev,                     -- Current manufacturing revision
		   @new_item_typ_dsc = t.to_item_typ_dsc,     -- Target item type description
	       @new_item_typ_cde = it.item_typ_cde,       -- Target item type code
		   @new_item_cde = t.new_item_cde,            -- Predefined new item code
		   @DivisionId = it.DivisionId                -- Division ID from item type
	from workdb.dbo.dm_items_99CL4D t
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
		-- Create new item record (same logic as Script 1)
		insert into item
		select @new_item_cde,                         -- Predefined new item code
		       @new_item_typ_cde,                     -- New item type code
		       comdt_cde, uom, ryl_cde, rcmd_cde, make_buy_cde, six_mo_pln_qty,std_cst, act_cst,
			   act_cst_src, future_cst, null as future_cst_eff_dte, sap_mat_typ, owning_sys, unit_of_wgt, net_wgt, gross_wgt,sap_dup_reas_idn,
			   null as sap_lst_mod_dte, dsc, '01' as eng_rev, '01' as mfg_rev, 0 as aml_cnt, null as md0_fd_dte, null as lst_cls_chg_dte, 
			   item_recommend_idn, gtin, scrty_cls_idn, tst_vhcl_ind, bin_splt_ind, sls_sts_cde, cust_pos, dsc_full, 'Not Migrated' as MigrationStatusNm,
			   @DivisionId
		from item 
		where item_cde = @item_cde
		
		-- Create new item revision record
		insert into item_revision
		select @new_item_cde, '01' as item_rev, data_administrator, proj_cde, 'k' as lvl_idn, bus_unit_idn, add_dsc,
			   getdate() as cre_dte, getdate() as lst_mod_dte, file_cnt, bom_cnt, responsible_eng, cm1_evnt_idn, null as eol_dte
		from item_revision ir 
		where item_cde = @item_cde and item_rev = @item_rev	
	
		-- Create item plant records
		insert into item_plant
		select @new_item_cde, plnt_idn, prod_strt_dte, prod_end_dte, mrp_bom_ext_dte, mpor_ctrl_ind, mpor_asof_dte, '' as start_site_ind 
		from item_plant 
		where item_cde = @item_cde

		-- Create UDA records with mapping validation
		insert into uda_item	
		select @new_item_cde, ui.att_idn, ui.seq_nbr, ui.val_txt, ui.val_flt, ui.val_dte, ui.mdul_idn, '' as lst_mod_usr, getdate() as lst_mod_dte	
		from item i 
		join uda_item ui on i.item_cde = ui.item_cde
		join item_type it on i.item_typ_cde = it.item_typ_cde
		left join workdb..IBC_class_mapping m on m.as_is_item_typ_dsc = it.item_typ_dsc and ui.att_idn = m.att_idn	
		where i.item_cde = @item_cde	
		and to_be_item_typ_dsc = @new_item_typ_dsc
		and to_be_att_nme is not null
	end

	-- Move to next item in the list
	select @id = @id + 1 
end

-- =====================================================================================
-- SECTION 7: UP-REVISION IP FINISHED GOODS ITEM
-- Purpose: Create new revision for root IP finished goods item (same as Script 1)
-- =====================================================================================

-- Declare variables for revision management
declare @item_cde varchar(21)          -- Root item code
declare @item_rev char(2)              -- Current revision  
declare @new_item_rev char(2)          -- New revision to be created

-- Get root item details from BOM explosion table
select @item_cde = child_item_cde,      -- Root item code (99CL4D)
       @item_rev = child_item_rev       -- Current revision
from workdb.dbo.dm_bom_99CL4D where id = 1  -- ID 1 is always the root item

-- Calculate next revision number by incrementing highest existing revision
select @new_item_rev = max(item_rev) + 1 from item_revision where item_cde = @item_cde
-- Pad with leading zero if needed (e.g., 4 becomes '05')
select @new_item_rev = replicate('0', 2 -len(@new_item_rev)) + @new_item_rev 

-- Create new active revision for IP finished goods item
insert into item_revision 
select @item_cde,                              -- Item code (99CL4D)
       @new_item_rev as item_rev,              -- New revision number (05)
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
-- SECTION 8: BOM STRUCTURE CREATION WITH PREDEFINED MAPPINGS
-- Purpose: Create new BOM relationships using predefined item code mappings
-- =====================================================================================

-- Add columns to track BOM IDs for IP and IF structures
alter table workdb.dbo.dm_bom_99CL4D add bom_idn_ip int;  -- BOM ID for IP structure
alter table workdb.dbo.dm_bom_99CL4D add bom_idn_if int;  -- BOM ID for IF structure

-- Get starting BOM ID from system counter
declare @bom_idn int
select @bom_idn = value_1 -1 from codes_and_values where idn = 'NEXT BOM IDN'

-- Assign BOM IDs for IP structure (all items with new item codes)
update t
set bom_idn_ip = bom_idn 
from (
select b.id, b.bom_idn_ip, @bom_idn + row_number() OVER (ORDER BY b.id) as bom_idn
from workdb.dbo.dm_bom_99CL4D b 
join workdb.dbo.dm_items_99CL4D p on b.parent_item_cde = p.item_cde  -- Parent has new item code
left join workdb.dbo.dm_items_99CL4D c on b.child_item_cde = c.item_cde  -- Child may have new item code
where b.id > 1                                 -- Exclude root item
  and b.parent_item_cde <> '99CL4D'            -- Exclude root as parent
  and b.parent_item_rev <> '04'                -- Exclude old root revision
  and p.new_item_cde is not null               -- Only items with new codes
) t

-- Update counter after BOM ID assignment
select @bom_idn = @bom_idn + @@ROWCOUNT
update codes_and_values set value_1 = @bom_idn + 1 where idn = 'NEXT BOM IDN'

-- =====================================================================================
-- SECTION 9: CREATE IP AND IF BOM STRUCTURES
-- Purpose: Create BOM relationships for both IP and IF item structures
-- =====================================================================================

-- Create BOM entries linking IP finished goods (new revision) with child items
insert into design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select @bom_idn,                               -- Sequential BOM ID
       parent_item_cde,                        -- Parent item code (99CL4D)
       @new_item_rev,                          -- New revision (05)
       bom_find_nbr,                           -- BOM find number
	   isnull(i.new_item_cde, b.child_item_cde) as child_item_cde,  -- Use new item code if available
	   child_qty_req,                          -- Required quantity
	   bom_typ_cde,                            -- BOM type code
	   no_expl_ind                             -- No explosion indicator
from workdb.dbo.dm_bom_99CL4D b 
left join workdb.dbo.dm_items_99CL4D i on b.child_item_cde = i.item_cde
where parent_item_cde = @item_cde and parent_item_rev = @item_rev  -- Root item children

-- Increment BOM ID for next structure
select @bom_idn = @bom_idn + 1

-- Create BOM entries for new IF finished goods items
insert into design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select @bom_idn,                               -- Sequential BOM ID
       i.new_item_cde,                         -- New IF item code as parent
       '01' as parent_item_rev,                -- Revision 01 for new items
       bom_find_nbr,                           -- BOM find number
	   child_item_cde,                         -- Original child item code
	   child_qty_req,                          -- Required quantity
	   bom_typ_cde,                            -- BOM type code
	   no_expl_ind                             -- No explosion indicator
from workdb.dbo.dm_bom_99CL4D b 
join workdb.dbo.dm_items_99CL4D i on b.parent_item_cde = i.item_cde
where parent_item_cde = @item_cde and parent_item_rev = @item_rev

-- Update system counter
update codes_and_values set value_1 = @bom_idn + 1 where idn = 'NEXT BOM IDN'

-- Create BOM entries for all intermediate items using predefined mappings
insert into design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select b.bom_idn_ip,                           -- Pre-assigned BOM ID
       p.new_item_cde,                         -- New parent item code
       '01',                                   -- Revision 01 for new items
       bom_find_nbr,                           -- BOM find number
       isnull(c.new_item_cde, b.child_item_cde),  -- Use new child code if available
       child_qty_req,                          -- Required quantity
       bom_typ_cde,                            -- BOM type code
       no_expl_ind                             -- No explosion indicator
from workdb.dbo.dm_bom_99CL4D b 
join workdb.dbo.dm_items_99CL4D p on b.parent_item_cde = p.item_cde      -- Parent has new item code
left join workdb.dbo.dm_items_99CL4D c on b.child_item_cde = c.item_cde  -- Child may have new item code
where b.id > 1                                 -- Exclude root item
  and b.parent_item_cde <> '99CL4D'            -- Exclude root as parent
  and b.parent_item_rev <> '04'                -- Exclude old root revision
  and p.new_item_cde is not null               -- Only items with new codes

-- =====================================================================================
-- SECTION 10: RECLASSIFICATION OF EXISTING ITEMS
-- Purpose: Update item classifications for stack-type items in main item table
-- =====================================================================================

-- Update item type codes for stack items (same logic as Script 1)
update i set item_typ_cde = it.item_typ_cde
from workdb.dbo.dm_items_99CL4D t 
join item i on t.item_cde = i.item_cde                -- Join with actual item table
join item_type it on replace(t.to_item_typ_dsc,'P_','UPI_') = it.item_typ_dsc  -- Convert P_ back to UPI_
where to_item_typ_dsc like '%STACK%'                  -- Only stack-type items

-- =====================================================================================
-- SECTION 11: DIVISION ID ASSIGNMENT
-- Purpose: Assign organizational division IDs to items
-- =====================================================================================

-- Update Division IDs for different item categories
-- IP (In-Process) items get Division ID 10
update item set DivisionId= 10  
where item_cde in ('99CL4D','2000-293-666','2000-293-676', '2001-001-001')

-- IF (Intermediate Finished) items get Division ID 20
update i set DivisionId= 20 
from item i 
join workdb.dbo.dm_items_99CL4D a on i.item_cde = a.item_cde 
where DivisionId is null                       -- Only update items without division assignment

-- =====================================================================================
-- SECTION 12: SPECIAL UNBW ITEM CREATION
-- Purpose: Create special UNBW (Unbound Wafer) items with custom logic
-- =====================================================================================

-- Create special UNBW items for specific semiconductor processes
-- These items require custom descriptions and material type changes

-- Create UNBW item 2000-312-437 from 2000-293-666
declare @item_cde varchar(21) = '2000-293-666'
declare @item_rev char(2) = '03'
declare @new_item_cde varchar(21) = '2000-312-437'
declare @new_item_typ_cde char(4) = '0994'     -- UPI_FAB item type
declare @DivisionId int = 20	

insert into item
select @new_item_cde,                          -- New UNBW item code
       @new_item_typ_cde,                      -- UPI_FAB item type
       comdt_cde, uom, ryl_cde, rcmd_cde, make_buy_cde, six_mo_pln_qty,std_cst, act_cst,
	   act_cst_src, future_cst, null as future_cst_eff_dte, 
	   'UNBW' as sap_mat_typ,                  -- Change material type to UNBW
	   owning_sys, unit_of_wgt, net_wgt, gross_wgt,sap_dup_reas_idn,
	   null as sap_lst_mod_dte, dsc, '01' as eng_rev, '01' as mfg_rev, 0 as aml_cnt, null as md0_fd_dte, null as lst_cls_chg_dte, 
	   item_recommend_idn, gtin, scrty_cls_idn, tst_vhcl_ind, bin_splt_ind, sls_sts_cde, cust_pos, dsc_full, 'Not Migrated' as MigrationStatusNm,
	   @DivisionId
from item 
where item_cde = @item_cde

-- Create corresponding item revision
insert into item_revision
select @new_item_cde, '01' as item_rev, data_administrator, proj_cde, 'k' as lvl_idn, bus_unit_idn, add_dsc,
	   getdate() as cre_dte, getdate() as lst_mod_dte, file_cnt, bom_cnt, responsible_eng, cm1_evnt_idn, null as eol_dte
from item_revision ir 
where item_cde = @item_cde and item_rev = @item_rev	

-- Create item plant records
insert into item_plant
select @new_item_cde, plnt_idn, prod_strt_dte, prod_end_dte, mrp_bom_ext_dte, mpor_ctrl_ind, mpor_asof_dte, '' as start_site_ind 
from item_plant 
where item_cde = @item_cde

-- Create UDA records
insert into uda_item	
select @new_item_cde, att_idn, seq_nbr, val_txt, val_flt, val_dte, mdul_idn, '' as lst_mod_usr, getdate() as lst_mod_dte	
from uda_item ui 
where item_cde = @item_cde

-- =====================================================================================
-- SECTION 13: SPECIAL STACK ITEM CREATION
-- Purpose: Create special stack items with custom descriptions and properties
-- =====================================================================================

-- Create special stack items 2001-001-003 and 2001-001-002
-- These items have modified descriptions (remove first character) and specific UDA values

-- Create item 2001-001-003 (8PURCV stack item)
insert into item
select '2001-001-003',                        -- New item code
       '1432',                                 -- P_STACK_SILICON item type
       '0116',                                 -- Commodity code
       uom, ryl_cde, rcmd_cde, 
       'M',                                    -- Make indicator
       six_mo_pln_qty,std_cst, act_cst, act_cst_src, future_cst, null as future_cst_eff_dte, 
       'UNBW' as sap_mat_typ,                  -- UNBW material type
       owning_sys, unit_of_wgt, net_wgt, gross_wgt,sap_dup_reas_idn, null as sap_lst_mod_dte, 
       substring(dsc,2,len(dsc)),              -- Remove first character from description
       '01' as eng_rev, '01' as mfg_rev, 0 as aml_cnt, null as md0_fd_dte, null as lst_cls_chg_dte, 
       item_recommend_idn, gtin, scrty_cls_idn, tst_vhcl_ind, bin_splt_ind, sls_sts_cde, cust_pos, 
       substring(dsc_full,2,len(dsc_full)),    -- Remove first character from full description
       'Not Migrated' as MigrationStatusNm, DivisionId
from item where item_cde = '2000-285-610'

union

-- Create item 2001-001-002 (8LF4CV stack item)
select '2001-001-002',                        -- New item code
       '1432',                                 -- P_STACK_SILICON item type
       '0116',                                 -- Commodity code
       uom, ryl_cde, rcmd_cde, 
       'M',                                    -- Make indicator
       six_mo_pln_qty,std_cst, act_cst, act_cst_src, future_cst, null as future_cst_eff_dte, 
       'UNBW' as sap_mat_typ,                  -- UNBW material type
       owning_sys, unit_of_wgt, net_wgt, gross_wgt,sap_dup_reas_idn, null as sap_lst_mod_dte, 
       substring(dsc,2,len(dsc)),              -- Remove first character from description
       '01' as eng_rev, '01' as mfg_rev, 0 as aml_cnt, null as md0_fd_dte, null as lst_cls_chg_dte, 
       item_recommend_idn, gtin, scrty_cls_idn, tst_vhcl_ind, bin_splt_ind, sls_sts_cde, cust_pos, 
       substring(dsc_full,2,len(dsc_full)),    -- Remove first character from full description
       'Not Migrated' as MigrationStatusNm, DivisionId
from item where item_cde = '2000-285-678'

-- Create item revisions for both new stack items
insert into item_revision
select '2001-001-003', '01' as item_rev, data_administrator, proj_cde, 'k' as lvl_idn, bus_unit_idn, add_dsc,
	   getdate() as cre_dte, getdate() as lst_mod_dte, file_cnt, bom_cnt, responsible_eng, cm1_evnt_idn, null as eol_dte
from item_revision ir where item_cde = '2000-285-610' and item_rev = '07'	
union
select '2001-001-002', '01' as item_rev, data_administrator, proj_cde, 'k' as lvl_idn, bus_unit_idn, add_dsc,
	   getdate() as cre_dte, getdate() as lst_mod_dte, file_cnt, bom_cnt, responsible_eng, cm1_evnt_idn, null as eol_dte
from item_revision ir where item_cde = '2000-285-678' and item_rev = '07'

-- Create item plant records for both new stack items
insert into item_plant
select '2001-001-003', plnt_idn, prod_strt_dte, prod_end_dte, mrp_bom_ext_dte, mpor_ctrl_ind, mpor_asof_dte, '' as start_site_ind 
from item_plant where item_cde = '2000-293-667'
union
select '2001-001-002', plnt_idn, prod_strt_dte, prod_end_dte, mrp_bom_ext_dte, mpor_ctrl_ind, mpor_asof_dte, '' as start_site_ind 
from item_plant where item_cde = '2000-293-667'

-- Create UDA records for both new stack items
insert into uda_item	
select '2001-001-003', att_idn, seq_nbr, val_txt, val_flt, val_dte, mdul_idn, '' as lst_mod_usr, getdate() as lst_mod_dte	
from uda_item ui where item_cde = '2000-293-667'
union
select '2001-001-002', att_idn, seq_nbr, val_txt, val_flt, val_dte, mdul_idn, '' as lst_mod_usr, getdate() as lst_mod_dte	
from uda_item ui where item_cde = '2000-293-678'

-- =====================================================================================
-- SECTION 14: CUSTOM UDA VALUE UPDATES
-- Purpose: Set specific UDA values for the new stack items
-- =====================================================================================

-- Update UDA values with specific product codes for new stack items
-- These values identify the specific semiconductor product variants

-- Update product code UDAs for 2001-001-002 (8LF4CV variant)
update uda_item set val_txt = '8LF4CVA' 
where item_cde = '2001-001-002' and att_idn = 9998    -- Product code attribute

update uda_item set val_txt = '8LF4CV' 
where item_cde = '2001-001-002' and att_idn = 12058   -- Short product code attribute

-- Update product code UDAs for 2001-001-003 (8PURCV variant)
update uda_item set val_txt = '8PURCVA' 
where item_cde = '2001-001-003' and att_idn = 9998    -- Product code attribute

update uda_item set val_txt = '8PURCV' 
where item_cde = '2001-001-003' and att_idn = 12058   -- Short product code attribute

-- =====================================================================================
-- SECTION 15: BOM RELATIONSHIP UPDATES FOR SPECIAL ITEMS
-- Purpose: Create BOM relationships for the new special items
-- =====================================================================================

-- Create BOM relationships linking parent items to new stack items
insert into design_bom 
select 88628889,                              -- BOM ID
       '2000-285-610',                        -- Parent item code
       '07',                                  -- Parent revision
       '100',                                 -- BOM find number
       '2001-001-003',                        -- Child item code (new stack item)
       1.00000,                               -- Quantity required
       'A',                                   -- BOM type (Assembly)
       'N'                                    -- No explosion indicator
union
select 88628890,                              -- BOM ID
       '2000-285-678',                        -- Parent item code
       '07',                                  -- Parent revision
       '100',                                 -- BOM find number
       '2001-001-002',                        -- Child item code (new stack item)
       1.00000,                               -- Quantity required
       'A',                                   -- BOM type (Assembly)
       'N'                                    -- No explosion indicator

-- Create BOM relationships for new stack items to their children
insert into design_bom 
select 88628891,                              -- BOM ID
       '2001-001-003',                        -- Parent item code (new stack item)
       '01',                                  -- Parent revision
       '100',                                 -- BOM find number
       '2000-285-609',                        -- Child item code
       1.00000,                               -- Quantity required
       'A',                                   -- BOM type (Assembly)
       'N'                                    -- No explosion indicator
union
select 88628892,                              -- BOM ID
       '2001-001-002',                        -- Parent item code (new stack item)
       '01',                                  -- Parent revision
       '100',                                 -- BOM find number
       '2000-285-677',                        -- Child item code
       1.00000,                               -- Quantity required
       'A',                                   -- BOM type (Assembly)
       'N'                                    -- No explosion indicator

-- =====================================================================================
-- SECTION 16: ROH (RAW MATERIAL) ITEM CREATION
-- Purpose: Create new ROH items for raw materials with UNBW material type
-- =====================================================================================

-- Create ROH item N52701-001 from N16151-002
declare @item_cde varchar(21) = 'N16151-002'
declare @item_rev char(2) = '01'
declare @new_item_cde varchar(21) = 'N52701-001'
declare @DivisionId int = null              -- No division assignment for ROH items

insert into item
select @new_item_cde,                          -- New ROH item code
       item_typ_cde,                           -- Keep same item type
       comdt_cde, uom, ryl_cde, rcmd_cde, make_buy_cde, six_mo_pln_qty,std_cst, act_cst,
	   act_cst_src, future_cst, null as future_cst_eff_dte, 
	   'UNBW' as sap_mat_typ,                  -- Change to UNBW material type
	   owning_sys, unit_of_wgt, net_wgt, gross_wgt,sap_dup_reas_idn,
	   null as sap_lst_mod_dte, dsc, '01' as eng_rev, '01' as mfg_rev, 0 as aml_cnt, null as md0_fd_dte, null as lst_cls_chg_dte, 
	   item_recommend_idn, gtin, scrty_cls_idn, tst_vhcl_ind, bin_splt_ind, sls_sts_cde, cust_pos, dsc_full, 'Not Migrated' as MigrationStatusNm,
	   @DivisionId
from item 
where item_cde = @item_cde

-- Create corresponding item revision, plant, and UDA records
insert into item_revision
select @new_item_cde, '01' as item_rev, data_administrator, proj_cde, 'k' as lvl_idn, bus_unit_idn, add_dsc,
	   getdate() as cre_dte, getdate() as lst_mod_dte, file_cnt, bom_cnt, responsible_eng, cm1_evnt_idn, null as eol_dte
from item_revision ir 
where item_cde = @item_cde and item_rev = @item_rev	

insert into item_plant
select @new_item_cde, plnt_idn, prod_strt_dte, prod_end_dte, mrp_bom_ext_dte, mpor_ctrl_ind, mpor_asof_dte, '' as start_site_ind 
from item_plant 
where item_cde = @item_cde

insert into uda_item	
select @new_item_cde, att_idn, seq_nbr, val_txt, val_flt, val_dte, mdul_idn, '' as lst_mod_usr, getdate() as lst_mod_dte	
from uda_item ui 
where item_cde = @item_cde

-- =====================================================================================
-- SECTION 17: BOM UPDATES FOR ROH ITEMS
-- Purpose: Update existing BOM relationships to use new ROH items
-- =====================================================================================

-- Update BOM relationships to use new ROH items instead of old ones
-- This ensures the BOM structure uses the new UNBW material type items

-- Update BOM to use new ROH item N52701-001
update design_bom 
set child_item_cde = 'N52701-001' 
where parent_item_cde = '2000-311-262' 
  and parent_item_rev = '03' 
  and child_item_cde = 'N16151-002'

-- Update BOM to use new ROH item N52702-001  
update design_bom 
set child_item_cde = 'N52702-001' 
where parent_item_cde = 'N26524-001' 
  and parent_item_rev = '01' 
  and child_item_cde = 'N26523-001'

-- =====================================================================================
-- SECTION 18: ITEM REVISION KEY MAP UPDATES
-- Purpose: Fix item revision key mappings for consistency
-- =====================================================================================

-- Update item revision key map to ensure consistency
-- This fixes any mismatches between item revisions and their key mappings
update item_revision_key_map 
set item_rev = '04' 
where item_rev_idn = 6086302                  -- Specific revision ID that needs correction

-- =====================================================================================
-- SCRIPT 2 COMPLETION
-- Purpose: Script 2 (99CL4D) migration and reclassification is now complete
-- =====================================================================================

-- At this point, Script 2 has completed:
-- 1. Synchronized data from BETADATA environment
-- 2. Created missing items and revisions
-- 3. Applied classification rules and created new items
-- 4. Created new revision for root IP item
-- 5. Built new BOM structures with predefined mappings
-- 6. Created special UNBW and stack items with custom properties
-- 7. Created ROH items with UNBW material type
-- 8. Updated BOM relationships to use new items
-- 9. Assigned division IDs and updated item classifications
-- 10. Fixed item revision key mappings

-- The migration is ready for the next phase (Script 3: 99D5JH)