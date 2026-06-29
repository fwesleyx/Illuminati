DECLARE @DivisionID INT=20


 select top 10 * from workdb..lov_analysis_report rep 
 JOIN 
 where rep.[Class Division]=@DivisionID
and [New List Of Value]='Y'
 --To find not inserted '[New Characteristic]'
select top 10 * from workdb..lov_analysis_report rep
join uda_definition uda on uda.att_nme = rep.[S4 Characteristic Name]
join uda_item_type uit on uit.att_idn = uda.att_idn
join item_type it on it.item_typ_cde = uit.item_typ_cde and it.item_typ_dsc =rep.[Speed Item Class]
where rep.[Class Division]=@DivisionID
and [New List Of Value]='Y'
 and rep.[S4 Characteristic Name] not in (
 select att_nme FROM uda_definition uda 
 )

select top 10 * from workdb..lov_analysis_report 
join uda_definition uda on uda.att_nme = rep.[Speed Characteristic Name]
join uda_item_type uit on uit.att_idn = uda.att_idn
join item_type it on it.item_typ_cde = uit.item_typ_cde and it.item_typ_dsc =rep.[Speed Item Class]
where rep.[Class Division]=@DivisionID and [Remove List Of Value]='Y'

select top 10 * from workdb..lov_analysis_report 
join uda_definition uda on uda.att_nme = rep.[Speed Characteristic Name]
join uda_item_type uit on uit.att_idn = uda.att_idn
join item_type it on it.item_typ_cde = uit.item_typ_cde and it.item_typ_dsc =rep.[Speed Item Class]
where rep.[Class Division]=@DivisionID and [Update List Of Value Text]='Y'

select top 10 * from workdb..lov_analysis_report 
join uda_definition uda on uda.att_nme = rep.[Speed Characteristic Name]
join uda_item_type uit on uit.att_idn = uda.att_idn
join item_type it on it.item_typ_cde = uit.item_typ_cde and it.item_typ_dsc =rep.[Speed Item Class]
where rep.[Class Division]=@DivisionID and [Update List Of Value Description] ='Y'