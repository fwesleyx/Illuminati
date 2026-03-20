USE [Pdm]
GO

/****** Object:  View [ItemBom].[ItemClass]    Script Date: 03-12-2025 12:53:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************      
* Name: [ItemBom].[ItemClass]
* Author:    
* Modification History      
* Date       Person              Description      
* ---------- ------------------- -----------------------------------------      
* 06/12/2025  Francis          TWC5924-1892:ItemSiteMaint     
*******************************************************************************/


  
 ALTER view [ItemBom].[ItemClass] as    
select item_typ_cde   AS ClassCd    
 ,item_typ_dsc   AS ClassDsc    
 ,parent_item_typ_cde AS ParentClassCd    
 ,curr_actv_ind   AS ActiveCd    
 ,del_dte    AS InactivateDt    
 ,cre_dte    AS CreateDt    
 ,mod_dte    AS UpdateDt    
 ,owning_sys    AS OwningSystemCd    
 ,force_uow    AS ForceUnitOfWeightCd    
 ,plchldr_elig_ind  AS PlaceholderEligibilityCd    
 ,sap_internal_idn  AS SapInternalId   
 ,file_req_ind FileRequiredInd
 ,DivisionId 
from [speed_2max].[dbo].[item_type] 
GO

