  
  
/******************************************************************************    
** Attribute.AttributeGetByClass    
**    
******************************************************************************/    
ALTER proc [ItemBom].[ItemAttributeGetByClass] (    
    @ItemClassCd char(4),    
 @BaseOnly bit = false,    
 @IncludeHelpTxt bit = false    
)    
/* any changes to the # of columns returned will impact BulkImport.ItemAttributesPatternGet  */    
AS 
/*******************************************************************************      
* Name: [ItemBom].[ItemAttributeGetByClass] - Get Item Attribute Class/Type 
* Author:     
* Modification History      
* Date       Person              Description      
* ---------- ------------------- -----------------------------------------        
* 06/05/2026  fwesleyx          TWC5924-2920 Remove Product Visibility attribute    
*******************************************************************************/

begin    
    
create table #AttributeValidValues (    
 AttributeId int not null,    
 ValidValueCount int default 0    
)    
    
insert #AttributeValidValues(AttributeId, ValidValueCount)    
 select  a.AttributeId,     
    (select COUNT(*)          
    FROM UdaValidationList          
    WHERE UdaValidationList.AttributeId = a.AttributeId          
    AND CurrentActiveInd = 'Y'           
    AND NOT EXISTS(SELECT UdaValidationRange.AttributeId          
    FROM UdaValidationRange          
    WHERE UdaValidationList.AttributeId = UdaValidationRange.AttributeId ) )    
  from ItemBom.ItemAttribute a    
  join ItemBom.ItemClassAttribute ca on a.AttributeId = ca.AttributeId    
  join ItemBom.RefItemAttributeStatus s on a.StatusCd = s.StatusCd    
  where ca.ClassCd = @ItemClassCd    
  and a.TableNm = 'item'    
  and a.ActiveInd = 1    
  and a.AttributeNm<>'MM-PROD-VISIBILITY'
    
    --this implementation supports the use of an abbreviated base class for dropdowns & control bindings    
if (@BaseOnly = 'True')    
 begin      
  select null as ItemAttributeList,        
  ca.ClassCd as ItemClassCd,    
  a.AttributeId,     
  a.AttributeNm,     
  a.AttributeDsc,     
  a.StatusCd,     
  s.StatusDsc,    
  a.MultipleValuesInd,     
  ca.RequiredInd AS RequiredValueInd,     
  a.DataTypeCd,     
  a.FormatMask,     
  case when @IncludeHelpTxt = 1 then ItemBom.GetHelpText(a.AttributeId) else null end as HelpTxt,    
  ca.RestrictToValidValuesInd,    
  CASE avv.ValidValueCount WHEN 0 THEN 'N' ELSE 'Y' END as HasValidationList    
  ,avv.ValidValueCount as ValidValueCount    
  , uvr.MinNbr, uvr.MaxNbr    
  ,ca.SortOrder    
  from ItemBom.ItemAttribute a    
  join #AttributeValidValues avv on a.AttributeId = avv.AttributeId    
  join ItemBom.ItemClassAttribute ca on a.AttributeId = ca.AttributeId    
  join ItemBom.RefItemAttributeStatus s on a.StatusCd = s.StatusCd    
  left join ItemBom.UdaValidationRange uvr on a.AttributeId = uvr.AttributeId    
  where ca.ClassCd = @ItemClassCd    
  and a.TableNm = 'item'    
  and a.ActiveInd = 1    
  order by ca.SortOrder    
 end    
else    
 begin       
  select null as ItemAttributeList,     
  ca.ClassCd as ItemClassCd,    
  a.AttributeId,     
  a.AttributeNm,     
  a.AttributeDsc,     
  a.StatusCd,     
  s.StatusDsc,    
  case when ca.ClassCd = '121' and a.AttributeId in (12581,12621) then 1 else a.MultipleValuesInd end as MultipleValuesInd,     
  ca.RequiredInd AS RequiredValueInd,     
  a.DataTypeCd,     
  a.FormatMask,     
  case when @IncludeHelpTxt = 1 then ItemBom.GetHelpText(a.AttributeId) else null end as HelpTxt,    
  a.InactiveDt,    
  a.CreateDt,    
  cu.Wwid as CreateWwid,    
  a.UpdateDt,    
  uu.Wwid as UpdateWwid,    
  a.ActiveInd,    
  ca.RestrictToValidValuesInd,    
  a.TableNm,    
  a.SapNbr,    
  CASE avv.ValidValueCount WHEN 0 THEN 'N' ELSE 'Y' END as HasValidationList    
  ,avv.ValidValueCount as ValidValueCount    
  , uvr.MinNbr, uvr.MaxNbr    
  ,ca.SortOrder    
  from ItemBom.ItemAttribute a    
  join #AttributeValidValues avv on a.AttributeId = avv.AttributeId    
  join ItemBom.ItemClassAttribute ca on a.AttributeId = ca.AttributeId    
  join ItemBom.RefItemAttributeStatus s on a.StatusCd = s.StatusCd    
  left join [Security].Users cu on cu.UsrAcctCd = a.CreateAccountCd    
  left join [Security].Users uu on uu.UsrAcctCd = a.UpdateAccountCd    
  left join ItemBom.UdaValidationRange uvr on a.AttributeId = uvr.AttributeId    
  where ca.ClassCd = @ItemClassCd    
  and a.TableNm = 'item'    
  order by ca.SortOrder    
end    
    
--Cleanup    
drop table #AttributeValidValues    
    
end    