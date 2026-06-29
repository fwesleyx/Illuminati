ALTER procedure [Search].[ClassSearch]   
(@searchValue varchar(127)   
,@IdnValues [Search].[IdnValuePairUDT] readonly  
,@filter varchar(63) = 'ClassCd'  
) as  
/******************************************************************************  
** Item Type/Class Progressive Search  
** smwoodwo 07/21/15 created  
** fwesleyx  18/05/2026 TWC5924-3019:Inactive Classes showing in class selector     
** Copyright 2014-2015 Intel Corporation, all right reserved.  
******************************************************************************/  
begin  
    set nocount on  
 declare @stringLength int, @like varchar(18), @like_long varchar(127), @AdditionalData varchar(127)  
 create table #options  ([value] char(4) not null, primary key ([value]))  
  
    set @searchValue = ISNULL(@searchValue, '')  
 set @stringLength = LEN(@searchValue)  
  
 while (@stringLength > 0 and not exists(select * from #options))  
 begin  
  set @AdditionalData = SUBSTRING(@searchValue, 1, @stringLength);  
  set @like_long = [Framework_2_0].[Search].[GetConditionedPattern](@AdditionalData, 'Contains', 0)  
  SELECT @AdditionalData,@like_long -- Debug
  if (LEN(@like_long) <= 18)  
  begin  
   set @like = @like_long  
  
   insert #options ([value])  
    select distinct top 20 ClassCd  
    from [Search].[Class]   
    where ClassDsc like @like  and ActiveInd = 1  
  end else begin  
  
   insert #options ([value])  
    select distinct top 20 ClassCd  
    from [Search].[Class]   
    where ClassDsc like @like_long  and ActiveInd = 1  
  end  
  
  set @stringLength -= 1  
 end  
   
 if not exists(select * from #options)  
 begin  
  set @AdditionalData = @searchValue  
  insert #options ([value])  
   select distinct top 20 ClassCd  
   from [Search].[Class]   
   where ActiveInd = 1  
 end  
  
 insert #options ([value])  
  select distinct Value   
  from @IdnValues  
  where Value not in (select [value] from #options)  
         
    select null [FormOptions]  
  ,@filter [filter]  
  ,#options.[value]  
  ,dsc.ClassDsc [text]  
  ,@AdditionalData [AdditionalData]  
 from #options  
 join [ItemBom].[ItemClass] dsc on dsc.ClassCd = #options.[value]  
 where dsc.ActiveCd = 'Y'  
 order by #options.[value]  
  
 drop table #options  
end  