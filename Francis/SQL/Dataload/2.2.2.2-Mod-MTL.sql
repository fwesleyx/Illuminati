use speed_2max
go
begin tran
-- =====================================================================================
-- BOM MIGRATION AND ITEM RECLASSIFICATION FOR 99CDJZ
-- Transforms UPI (Unpackaged Integrated) items to P (Packaged) classification
-- =====================================================================================

EXEC sp_set_session_context 'AppName', 'PLM'; 

-- =====================================================================================
-- CREATE ALL TEMPORARY TABLES
-- =====================================================================================

-- Create item type temporary table
create table #item_type (
    item_typ_cde char(4) not null,
    item_typ_dsc varchar(18) not null,
    DivisionId int
)

-- Create item temporary table
create table #item (
    item_cde varchar(21) not null,
    item_typ_cde char(4),
    comdt_cde varchar(10),
    uom varchar(3),
    ryl_cde varchar(10),
    rcmd_cde varchar(10),
    make_buy_cde char(1),
    six_mo_pln_qty numeric(12,5),
    std_cst numeric(12,5),
    act_cst numeric(12,5),
    act_cst_src varchar(10),
    future_cst numeric(12,5),
    future_cst_eff_dte datetime,
    sap_mat_typ varchar(4),
    owning_sys varchar(10),
    unit_of_wgt varchar(3),
    net_wgt numeric(12,5),
    gross_wgt numeric(12,5),
    sap_dup_reas_idn int,
    sap_lst_mod_dte datetime,
    dsc varchar(40),
    eng_rev char(2),
    mfg_rev char(2),
    aml_cnt int,
    md0_fd_dte datetime,
    lst_cls_chg_dte datetime,
    item_recommend_idn int,
    gtin varchar(14),
    scrty_cls_idn int,
    tst_vhcl_ind char(1),
    bin_splt_ind char(1),
    sls_sts_cde varchar(2),
    cust_pos varchar(18),
    dsc_full varchar(255),
    MigrationStatusNm varchar(20),
    DivisionId int
)

-- Create item revision temporary table
create table #item_revision (
    item_cde varchar(21) not null,
    item_rev char(2) not null,
    data_administrator varchar(8),
    proj_cde varchar(8),
    lvl_idn char(1),
    bus_unit_idn int,
    add_dsc varchar(255),
    cre_dte datetime,
    lst_mod_dte datetime,
    file_cnt int,
    bom_cnt int,
    responsible_eng varchar(8),
    cm1_evnt_idn int,
    eol_dte datetime
)

-- Create item plant temporary table
create table #item_plant (
    item_cde varchar(21) not null,
    plnt_idn int not null,
    prod_strt_dte datetime,
    prod_end_dte datetime,
    mrp_bom_ext_dte datetime,
    mpor_ctrl_ind char(1),
    mpor_asof_dte datetime,
    start_site_ind char(1)
)

-- Create UDA item temporary table
create table #uda_item (
    item_cde varchar(21) not null,
    att_idn int not null,
    seq_nbr int not null,
    val_txt varchar(255),
    val_flt float,
    val_dte datetime,
    mdul_idn int,
    lst_mod_usr varchar(8),
    lst_mod_dte datetime
)

-- Create design BOM temporary table
create table #design_bom (
    bom_idn int not null,
    parent_item_cde varchar(21) not null,
    parent_item_rev char(2) not null,
    bom_find_nbr smallint not null,
    child_item_cde varchar(21) not null,
    child_qty_req numeric(12,5),
    bom_typ_cde char(1),
    no_expl_ind char(1)
)

-- Create SAP material item bank temporary table
create table #sap_mat_item_bank (
    item_cde varchar(21) not null,
    sap_mat_typ varchar(4),
    used_ind char(1),
    used_dte datetime,
    cre_item_id int identity
)

-- Create codes and values temporary table
create table #codes_and_values (
    idn varchar(20) not null,
    value_1 int,
    value_2 varchar(50),
    description varchar(100)
)

-- Create IBC class mapping temporary table
create table #IBC_class_mapping (
    as_is_item_typ_dsc varchar(18),
    to_be_item_typ_dsc varchar(18),
    att_idn int,
    to_be_att_nme varchar(50)
)

-- =====================================================================================
-- CREATE BOM EXPLOSION TABLE
-- =====================================================================================

create table #dm_bom_99CDJZ (
	id int identity,
	depth int,
	parent_item_cde varchar(21),
	parent_item_rev char(2),
	bom_find_nbr smallint,
	child_item_cde varchar(21),
	child_item_rev char(2),
	child_qty_req numeric(12, 5),
	bom_typ_cde char(1),
	no_expl_ind char(1),
	item_typ_dsc varchar(18)
)

-- Initialize with root item 99CDJZ
insert into #dm_bom_99CDJZ
select 0, '', '', 0, i.item_cde, i.mfg_rev, 0, '', '', ct.item_typ_dsc
from item i 
JOIN item_type ct on i.item_typ_cde = ct.item_typ_cde	
WHERE i.item_cde = '99CDJZ'

-- =====================================================================================
-- RECURSIVE BOM EXPLOSION
-- =====================================================================================

;WITH bomCTE (depth, bom_idn, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc) AS    
(   
	-- First level children
	SELECT t.depth + 1, b.bom_idn, b.parent_item_cde, b.parent_item_rev, b.bom_find_nbr, b.child_item_cde, c.mfg_rev as child_item_rev, b.child_qty_req, b.bom_typ_cde, b.no_expl_ind, ct.item_typ_dsc
	FROM #dm_bom_99CDJZ t
	JOIN design_bom b on t.child_item_cde = b.parent_item_cde and t.child_item_rev = b.parent_item_rev
	JOIN item p on p.item_cde = b.parent_item_cde
	JOIN item c on c.item_cde = b.child_item_cde
	JOIN item_type ct on c.item_typ_cde = ct.item_typ_cde
			
	UNION ALL 
	
	-- Recursive traversal
	SELECT cte.depth + 1 as depth, b.bom_idn, b.parent_item_cde, b.parent_item_rev, b.bom_find_nbr, b.child_item_cde, c.mfg_rev as child_item_rev, b.child_qty_req, b.bom_typ_cde, b.no_expl_ind, ct.item_typ_dsc
	FROM bomCTE cte
	join design_bom b on b.parent_item_cde = cte.child_item_cde AND b.parent_item_rev = cte.child_item_rev
	join item p on p.item_cde = b.parent_item_cde and p.sap_mat_typ in ('FERT','RAPP')
	JOIN item c on c.item_cde = b.child_item_cde
	JOIN item_type ct on c.item_typ_cde = ct.item_typ_cde
	WHERE cte.depth < 12
)    

INSERT INTO #dm_bom_99CDJZ (depth, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc)
SELECT distinct depth, parent_item_cde, parent_item_rev, bom_find_nbr, child_item_cde, child_item_rev, child_qty_req, bom_typ_cde, no_expl_ind, item_typ_dsc
FROM bomCTE 

-- =====================================================================================
-- CREATE ITEM CLASSIFICATION TABLE
-- =====================================================================================

create table #dm_items_99CDJZ (
	id int identity,
	item_cde varchar(21),
	item_rev char(2),
	item_typ_dsc varchar(18),
	to_item_typ_dsc varchar(18),
	new_item_cde varchar(21)
)

-- =====================================================================================
-- APPLY CLASSIFICATION RULES
-- =====================================================================================

-- FERT items become UPI_FINISH
insert into #dm_items_99CDJZ (item_cde, item_rev, item_typ_dsc, to_item_typ_dsc)
select distinct child_item_cde, child_item_rev, item_typ_dsc, 'UPI_FINISH'
from #dm_bom_99CDJZ b 
join item i on b.child_item_cde = i.item_cde
where i.sap_mat_typ = 'FERT'

-- RAPP items get P_ prefix instead of UPI_
insert into #dm_items_99CDJZ (item_cde, item_rev, item_typ_dsc, to_item_typ_dsc)
select distinct child_item_cde, child_item_rev, item_typ_dsc, replace(item_typ_dsc, 'UPI_', 'P_')
from #dm_bom_99CDJZ b 
join item i on b.child_item_cde = i.item_cde
where i.sap_mat_typ = 'RAPP'

-- =====================================================================================
-- APPLY STACK LOGIC
-- =====================================================================================

-- UPI_BUMP becomes P_STACK_COMBO when sandwiched between UPI_DIE_PREP items
update i 
set i.to_item_typ_dsc = 'P_STACK_COMBO'
from #dm_items_99CDJZ i
join #dm_bom_99CDJZ b1 on i.item_cde = b1.child_item_cde
join #dm_items_99CDJZ p on b1.parent_item_cde = p.item_cde and p.item_typ_dsc = 'UPI_DIE_PREP'
join #dm_bom_99CDJZ b2 on i.item_cde = b2.parent_item_cde
join #dm_items_99CDJZ c on b2.child_item_cde = c.item_cde and c.item_typ_dsc = 'UPI_DIE_PREP'
where i.item_typ_dsc = 'UPI_BUMP'

-- UPI_DIE_PREP becomes P_STACK_SILICON when between UPI_ASSEMBLY and UPI_BUMP
update i 
set i.to_item_typ_dsc = 'P_STACK_SILICON'
from #dm_items_99CDJZ i
join #dm_bom_99CDJZ b1 on i.item_cde = b1.child_item_cde
join #dm_items_99CDJZ p on b1.parent_item_cde = p.item_cde and p.item_typ_dsc = 'UPI_ASSEMBLY'
join #dm_bom_99CDJZ b2 on i.item_cde = b2.parent_item_cde
join #dm_items_99CDJZ c on b2.child_item_cde = c.item_cde and c.item_typ_dsc = 'UPI_BUMP'
where i.item_typ_dsc = 'UPI_DIE_PREP'

-- =====================================================================================
-- ITEM CREATION LOOP
-- =====================================================================================

declare @item_cde varchar(21)
declare @item_rev char(2)
declare @new_item_cde varchar(21)
declare @new_item_typ_cde char(4)
declare @new_item_typ_dsc varchar(18)
declare @DivisionId int
declare @id int = 1

-- Disable triggers for performance
--ALTER TABLE #item DISABLE TRIGGER plm_item_i;
--ALTER TABLE #item DISABLE TRIGGER plm_item_u;
--ALTER TABLE #item_revision DISABLE TRIGGER plm_item_revision_i;
--ALTER TABLE #item_revision DISABLE TRIGGER plm_item_revision_u;
--ALTER TABLE #uda_item DISABLE TRIGGER plm_uda_item_i;
--ALTER TABLE #uda_item DISABLE TRIGGER plm_uda_item_u;

while exists (select top 1 1 from #dm_items_99CDJZ where id = @id )
begin 
	print @id
	
	select @new_item_cde = null
	select @new_item_typ_cde = null
	
	-- Get next available item code from bank
	select @new_item_cde = item_cde
	from #sap_mat_item_bank 
	where sap_mat_typ = 'RAPP' and used_ind = 'N'
	order by cre_item_id

	-- Get item mapping details
	select @item_cde = t.item_cde, @item_rev = i.mfg_rev, @new_item_typ_dsc = t.to_item_typ_dsc, @new_item_typ_cde = it.item_typ_cde, @DivisionId = it.DivisionId
	from #dm_items_99CDJZ t
	join item i on t.item_cde = i.item_cde
	join (select distinct as_is_item_typ_dsc, to_be_item_typ_dsc 
	      from IBC_class_mapping 
	      where as_is_item_typ_dsc <> to_be_item_typ_dsc) m
	     on t.item_typ_dsc = as_is_item_typ_dsc and to_be_item_typ_dsc = t.to_item_typ_dsc
	join item_type it on it.item_typ_dsc = m.to_be_item_typ_dsc
	where t.id = @id 
			
	if (@new_item_cde is not null and @new_item_typ_cde is not null)
	begin
		-- Create new item
		insert into #item
		select @new_item_cde, @new_item_typ_cde, comdt_cde, uom, ryl_cde, rcmd_cde, make_buy_cde, six_mo_pln_qty, std_cst, act_cst,
			   act_cst_src, future_cst, null as future_cst_eff_dte, sap_mat_typ, owning_sys, unit_of_wgt, net_wgt, gross_wgt, sap_dup_reas_idn,
			   null as sap_lst_mod_dte, dsc, '01' as eng_rev, '01' as mfg_rev, 0 as aml_cnt, null as md0_fd_dte, null as lst_cls_chg_dte,
			   item_recommend_idn, gtin, scrty_cls_idn, tst_vhcl_ind, bin_splt_ind, sls_sts_cde, cust_pos, dsc_full, 'Not Migrated' as MigrationStatusNm, @DivisionId
		from item 
		where item_cde = @item_cde
		
		-- Create item revision
		insert into #item_revision
		select @new_item_cde, '01' as item_rev, data_administrator, proj_cde, 'k' as lvl_idn, bus_unit_idn, add_dsc,
			   getdate() as cre_dte, getdate() as lst_mod_dte, file_cnt, bom_cnt, responsible_eng, cm1_evnt_idn, null as eol_dte
		from item_revision ir 
		where item_cde = @item_cde and item_rev = @item_rev
	
		-- Create item plant records
		insert into #item_plant
		select @new_item_cde, plnt_idn, prod_strt_dte, prod_end_dte, mrp_bom_ext_dte, mpor_ctrl_ind, mpor_asof_dte, '' as start_site_ind
		from item_plant 
		where item_cde = @item_cde

		-- Create UDA records with mapping
		insert into #uda_item	
		select @new_item_cde, ui.att_idn, ui.seq_nbr, ui.val_txt, ui.val_flt, ui.val_dte, ui.mdul_idn, '' as lst_mod_usr, getdate() as lst_mod_dte
		from item i 
		join uda_item ui on i.item_cde = ui.item_cde
		join item_type it on i.item_typ_cde = it.item_typ_cde
		left join IBC_class_mapping m on m.as_is_item_typ_dsc = it.item_typ_dsc and ui.att_idn = m.att_idn
		where i.item_cde = @item_cde
		and to_be_item_typ_dsc = @new_item_typ_dsc
		and to_be_att_nme is not null

		-- Update working table with new item code
		update #dm_items_99CDJZ 
		set new_item_cde = @new_item_cde
		where id = @id

		-- Mark item code as used
		update #sap_mat_item_bank 
		set used_ind = 'Y', used_dte = getdate()
		where item_cde = @new_item_cde and sap_mat_typ = 'RAPP' and used_ind = 'N'
	end

	select @id = @id + 1 
end

-- Re-enable triggers
--ALTER TABLE #item ENABLE TRIGGER plm_item_i;
--ALTER TABLE #item ENABLE TRIGGER plm_item_u;
--ALTER TABLE #item_revision ENABLE TRIGGER plm_item_revision_i;
--ALTER TABLE #item_revision ENABLE TRIGGER plm_item_revision_u;
--ALTER TABLE #uda_item ENABLE TRIGGER plm_uda_item_i;
--ALTER TABLE #uda_item ENABLE TRIGGER plm_uda_item_u;

-- =====================================================================================
-- UP-REVISION IP FINISHED GOODS ITEM
-- =====================================================================================


declare @new_item_rev char(2)

select @item_cde = child_item_cde, @item_rev = child_item_rev
from #dm_bom_99CDJZ where id = 1

-- Calculate next revision
select @new_item_rev = max(item_rev) + 1 from #item_revision where item_cde = @item_cde
select @new_item_rev = replicate('0', 2 -len(@new_item_rev)) + @new_item_rev 

--ALTER TABLE #item DISABLE TRIGGER plm_item_i;
--ALTER TABLE #item DISABLE TRIGGER plm_item_u;
--ALTER TABLE #item_revision DISABLE TRIGGER plm_item_revision_i;
--ALTER TABLE #item_revision DISABLE TRIGGER plm_item_revision_u;

-- Create new revision
insert into #item_revision 
select @item_cde, @new_item_rev as item_rev, data_administrator, proj_cde, lvl_idn, bus_unit_idn, add_dsc,
	   getdate() as cre_dte, getdate() as lst_mod_dte, file_cnt, bom_cnt, responsible_eng, cm1_evnt_idn, null as eol_dte
from item_revision ir 
where item_cde = @item_cde and item_rev = @item_rev

-- Inactivate old revision
update #item_revision 
set lvl_idn = '8', lst_mod_dte = getdate()
where item_cde = @item_cde and item_rev = @item_rev

-- =====================================================================================
-- RECLASSIFY STACK ITEMS
-- =====================================================================================

update i set item_typ_cde = it.item_typ_cde
from #dm_items_99CDJZ t 
join item i on t.item_cde = i.item_cde
join item_type it on replace(t.to_item_typ_dsc,'P_','UPI_') = it.item_typ_dsc
where to_item_typ_dsc like '%STACK%'

--ALTER TABLE #item ENABLE TRIGGER plm_item_i;
--ALTER TABLE #item ENABLE TRIGGER plm_item_u;
--ALTER TABLE #item_revision ENABLE TRIGGER plm_item_revision_i;
--ALTER TABLE #item_revision ENABLE TRIGGER plm_item_revision_u;

-- =====================================================================================
-- BOM STRUCTURE CREATION
-- =====================================================================================

alter table #dm_bom_99CDJZ add bom_idn_ip int;
alter table #dm_bom_99CDJZ add bom_idn_if int;

-- Get starting BOM ID
declare @bom_idn int
select @bom_idn = value_1 -1 from #codes_and_values where idn = 'NEXT BOM IDN'

-- Assign BOM IDs for IF structure
update t
set bom_idn_if = bom_idn
FROM (SELECT id, bom_idn_if, @bom_idn + row_number() OVER (ORDER BY id) as bom_idn 
      from #dm_bom_99CDJZ
      where parent_item_cde = '99CDJZ' and parent_item_rev = '08')t

select @bom_idn = @bom_idn + @@ROWCOUNT

-- Assign BOM IDs for IP structure
update t
set bom_idn_ip = bom_idn
FROM (SELECT id, bom_idn_ip, @bom_idn + row_number() OVER (ORDER BY id) as bom_idn 
      from #dm_bom_99CDJZ where id > 1)t

select @bom_idn = @bom_idn + @@ROWCOUNT

-- Update system counter
update #codes_and_values set value_1 = @bom_idn + 1 where idn = 'NEXT BOM IDN'

set @new_item_rev  = '09'

select @item_cde = child_item_cde, @item_rev = child_item_rev	   
from #dm_bom_99CDJZ where id = 1 

--ALTER TABLE #design_bom DISABLE TRIGGER plm_design_bom_i;
--ALTER TABLE #design_bom DISABLE TRIGGER plm_design_bom_u;
--ALTER TABLE #item_revision DISABLE TRIGGER plm_item_revision_i;
--ALTER TABLE #item_revision DISABLE TRIGGER plm_item_revision_u;

-- =====================================================================================
-- CREATE IP FINISHED GOODS BOM
-- =====================================================================================

insert into #design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select bom_idn_ip, parent_item_cde, @new_item_rev, bom_find_nbr, isnull(i.new_item_cde, b.child_item_cde) as child_item_cde, child_qty_req, bom_typ_cde, no_expl_ind
from #dm_bom_99CDJZ b 
left join #dm_items_99CDJZ i on b.child_item_cde = i.item_cde
where parent_item_cde = @item_cde and parent_item_rev = @item_rev

-- =====================================================================================
-- CREATE IF FINISHED GOODS BOM
-- =====================================================================================

insert into #design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select bom_idn_if, i.new_item_cde, '01' as parent_item_rev, bom_find_nbr, child_item_cde, child_qty_req, bom_typ_cde, no_expl_ind
from #dm_bom_99CDJZ b 
join #dm_items_99CDJZ i on b.parent_item_cde = i.item_cde
where parent_item_cde = @item_cde and parent_item_rev = @item_rev

-- =====================================================================================
-- CREATE IP BOM FOR RAPP ITEMS
-- =====================================================================================

insert into #design_bom (bom_idn,parent_item_cde,parent_item_rev,bom_find_nbr,child_item_cde,child_qty_req,bom_typ_cde,no_expl_ind)
select b.bom_idn_ip, p.new_item_cde, '01', bom_find_nbr, isnull(c.new_item_cde, b.child_item_cde), child_qty_req, bom_typ_cde, no_expl_ind
from #dm_bom_99CDJZ b 
join #dm_items_99CDJZ p on b.parent_item_cde = p.item_cde
left join #dm_items_99CDJZ c on b.child_item_cde = c.item_cde
where b.id > 1 and b.parent_item_cde <> @item_cde and b.parent_item_rev <> @item_rev

--ALTER TABLE #design_bom ENABLE TRIGGER plm_design_bom_i;
--ALTER TABLE #design_bom ENABLE TRIGGER plm_design_bom_u;
--ALTER TABLE #item_revision ENABLE TRIGGER plm_item_revision_i;
--ALTER TABLE #item_revision ENABLE TRIGGER plm_item_revision_u;
rollback tran