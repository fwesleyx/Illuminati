select  * from speed.dbo.sap_item_bom_extend_request_details where parent_item_cde ='N93693-001' order by cmpl_dte desc
select top 10 * from speed.dbo.sap_item_bom_extend_request_master where parent_item_cde ='2001-802-448' order by rspns_dte desc
 
select top 100 * from speed_2max..sap_extend_async_log where request_data like '%2001-802-321%' order by create_dte desc