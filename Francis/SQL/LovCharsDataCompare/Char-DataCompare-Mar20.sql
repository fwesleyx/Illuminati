/*
Author:Francis/Mohan
Date:24 Mar 2026
Description:To Test Char comparison
*/
--select * FROM workdb..char_analysis_report_march9
--select * FROM workdb..char_analysis_march24
--1.To find its not deleted
select DISTINCT uda.att_nme,uda.att_idn,uda.curr_actv_ind,rep.[Speed Item Class] as Report_Spd_Itm_Class,rep.[Class Division] as Report_Class_Div,
rep.[Remove From Class] as Report_Remove_From_Class,'Item exists. Should be Deleted'
FROM workdb..char_analysis_march24 rep
join uda_definition uda on uda.att_nme = rep.[Speed Characteristic Name]
join uda_item_type uit on uit.att_idn = uda.att_idn
join item_type it on it.item_typ_cde = uit.item_typ_cde and it.item_typ_dsc =rep.[Speed Item Class]
where 
--rep.[Class Division]=@DivisionID and
rep.[Remove From Class]='Y'
 --2.To find the not updated
 select DISTINCT uda.att_nme,rep.[S4 Characteristic Description],rep.[Speed Characteristic Description],uda.att_dsc,rep.[Class Division] as Report_Class_Div,
 rep.[Update Characteristic Description] as Report_Update_Char_Description,'Description needs updation'
 FROM workdb..char_analysis_march24 rep
join uda_definition uda on uda.att_nme = rep.[Speed Characteristic Name]
join uda_item_type uit on uit.att_idn = uda.att_idn
join item_type it on it.item_typ_cde = uit.item_typ_cde and it.item_typ_dsc =rep.[Speed Item Class]
where 
-- rep.[Class Division]=@DivisionID and
  rep.[Update Characteristic Description]='Y'
 and rep.[S4 Characteristic Description] != uda.att_dsc

 --3.To find not inserted '[New Characteristic]'
 select DISTINCT rep.[S4 Characteristic Name],rep.[Speed Item Class] as Report_Spd_Itm_Class,
 rep.[Class Division] as Report_Class_Div,rep.[New Characteristic],'Item Missing.Need to be Inserted' 
 FROM workdb..char_analysis_march24 rep
 where 
 --rep.[Class Division]=@DivisionID and
  rep.[New Characteristic]='Y'
 and rep.[S4 Characteristic Name] not in (
 select att_nme FROM uda_definition uda 
 )

--4.To find not inserted 'Add To Class'
select DISTINCT rep.[Speed Characteristic Name],   rep.[S4 Characteristic Name],rep.[Speed Item Class] as Report_Spd_Itm_Class,
rep.[Class Division] as Report_Class_Div,rep.[Add To Class],'Item Missing.Need to be Inserted' 
FROM workdb..char_analysis_march24 rep
JOIN dbo.uda_definition  uda ON  rep.[Characteristic Id] != 'NULL' AND  uda.att_idn = ISNULL(rep.[Characteristic Id], 0)
where 
--rep.[Class Division]=@DivisionID and
  rep.[Add To Class]='Y'
  AND NOT  EXISTS (SELECT * FROM item_type it
				  JOIN uda_item_type uit ON it.item_typ_cde = uit.item_typ_cde
				  WHERE
					rep.[Characteristic Id] = uit.att_idn
					AND (rep.[Speed Item Class] = it.item_typ_dsc
						OR rep.[S4 Item Class] = it.item_typ_dsc
						)
		)

   --To find not inserted Type 3
 select DISTINCT rep.[S4 Characteristic Name],rep.[Speed Item Class] as Report_Spd_Itm_Class,
 rep.[Class Division] as Report_Class_Div,rep.[New Characteristic],'Item Missing.Need to be Inserted' 
 FROM workdb..char_analysis_march24 rep
 where 
 --rep.[Class Division]=@DivisionID and
  rep.[Add To Class]='Y'
 and rep.[S4 Characteristic Name] not in (
 select att_nme FROM uda_definition uda 
 )
