use speed
go
select uda.att_nme, uda.att_idn,uda.curr_actv_ind,it.item_typ_dsc,uvl.dsc,uvl.val_txt
from uda_definition uda 
join uda_item_type uit on uit.att_idn = uda.att_idn
join item_type it on it.item_typ_cde = uit.item_typ_cde 
join uda_validation_list uvl on uvl.att_idn = uda.att_idn
where uda.att_dsc ='Product Visibility Code' OR uda.att_nme='Product Visibility Code'

select uda.att_nme, uda.att_idn,uda.curr_actv_ind,uvl.dsc,uvl.val_txt,ui.item_cde,ui.val_txt,i.owning_sys
from
uda_item ui 
join uda_definition uda on uda.att_idn=ui.att_idn
join uda_validation_list uvl on uvl.att_idn = uda.att_idn AND ui.val_txt=uvl.val_txt
join item i on i.item_cde = ui.item_cde
where uda.att_nme='MM-PROD-VISIBILITY'
and ui.val_txt != 'H'


select i.owning_sys,COUNT(*)
from
uda_item ui 
join uda_definition uda on uda.att_idn=ui.att_idn 
join uda_validation_list uvl on uvl.att_idn = uda.att_idn AND ui.val_txt=uvl.val_txt
join item i on i.item_cde = ui.item_cde
where uda.att_nme='MM-PROD-VISIBILITY'
and ui.val_txt != 'H'
Group by i.owning_sys

--OWNING_SYS		COUNT
--J96	*speed		55695
--APS	*speed		2
--PLM	*speed		27
--SPD				3418

select ilvl.nme,COUNT(*) COUNT
from
uda_item ui 
join uda_definition uda on uda.att_idn=ui.att_idn 
join uda_validation_list uvl on uvl.att_idn = uda.att_idn AND ui.val_txt=uvl.val_txt
join item i on i.item_cde = ui.item_cde
join item_revision ir on ir.item_cde = i.item_cde and ir.item_rev = i.mfg_rev
join item_rls_lvl ilvl on ilvl.lvl_idn = ir.lvl_idn and ilvl.eco_item_ind='I'
where uda.att_nme='MM-PROD-VISIBILITY'
and ui.val_txt != 'H'
Group by ilvl.nme
/*
OBSOLETE		9665
INACTIVE		18399
DRAFT			834
REVIEW			1
PRODN_APPROVED	5848
PROTO			5
MODEL			195
ECC				7
UN QUAL			7
CONDITIONAL		8398
PRELIMINARY		5759
EOL				4
DESIGN			9721
ACQUISITION		9
*/

select bus.short_nme,COUNT(*) COUNT
from
uda_item ui 
join uda_definition uda on uda.att_idn=ui.att_idn 
join uda_validation_list uvl on uvl.att_idn = uda.att_idn AND ui.val_txt=uvl.val_txt
join item i on i.item_cde = ui.item_cde
join item_revision ir on ir.item_cde = i.item_cde and ir.item_rev = i.mfg_rev
join item_rls_lvl ilvl on ilvl.lvl_idn = ir.lvl_idn and ilvl.eco_item_ind='I'
join bus_unit_dsgn_grp bus on bus.bus_unit_idn = ir.bus_unit_idn
where uda.att_nme='MM-PROD-VISIBILITY'
and ui.val_txt != 'H'
Group by bus.short_nme
