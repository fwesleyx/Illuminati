ALTER procedure [AmlSearch].[ClassSelectorSearch] @text varchar(64) = null, @ParentClassCd char(4) = null  as   
/******************************************************************************  
** Class Selector Search  
** mtan6 02/08/2023 created
** fwesleyx  18/05/2026 TWC5924-3019:Inactive Classes showing in class selector       
** !! IMPORTANT !! This stored procedure iS for AML Advanced Search use only, DO NOT MODIFY  
** Copyright 2023 Intel Corporation, all right reserved.  
******************************************************************************/  
begin  
 set nocount on  
 declare @text_shrt varchar(18)  
 create table #rslts (ClassCd char(4) not null, HasChildren bit default 0, primary key (ClassCd))  
  
 set @text = [Framework_2_0].[Search].[GetSelectorFieldPattern](@text)  
  
 if (@ParentClassCd is not null)  
 begin  
  insert #rslts (ClassCd)  
   select top 1001 ClassCd from [Search].[Class] 
   where ParentClassCd = @ParentClassCd 
   and ActiveInd=1
   order by ClassDsc  
 end else if (@text is null) begin  
  insert #rslts (ClassCd)  
   select top 1001 ClassCd from [Search].[Class] 
   where ActiveInd=1
   order by ClassDsc  
 end else if (len(isnull(@text, '')) <= 18) begin  
  set @text_shrt  = @text  
  
  insert #rslts (ClassCd)  
   select top 1001 ClassCd from [Search].[Class] 
   where ClassDsc like @text_shrt 
   and ActiveInd=1 order by ClassDsc  
 end else begin  
  insert #rslts (ClassCd)  
   select top 1001 ClassCd from [Search].[Class] where ClassDsc like @text 
   and ActiveInd=1
   order by ClassDsc  
 end  
  
 update #rslts set HasChildren = 1  
 from #rslts  
 join [Search].[Class] on Class.ParentClassCd = #rslts.ClassCd  
  
  
 select null [SearchResults]  
  ,rtrim(#rslts.ClassCd) [value]  
  ,Class.ClassDsc [text]  
  ,#rslts.HasChildren  
 from #rslts  
 join [Search].[Class] on Class.ClassCd = #rslts.ClassCd  
 order by Class.ClassDsc  
end  