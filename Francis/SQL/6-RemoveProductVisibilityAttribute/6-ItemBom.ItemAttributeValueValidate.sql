USE [Pdm]; 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [ItemBom].[ItemAttributeValueValidate] @ModelNm varchar(63) = '[ItemBom].[ItemAttributeValueValidate]' as
/******************************************************************************
** table [ItemBom].[ItemAttributeValue] candidate record validation
** smwoodwo 09/06/15 created
** Copyright 2015 Intel Corporation, all rights reserved
** 
** Dependencies ***************************************************************
** The following working tables must be present and filled-in 
** prior to calling this sproc:
**		#Item
**		#ItemAttributeValue
**		#ErrorLog

** mirzahax 11/03/2017 user story -45954 Create new material type: ZSUB in PDM UI
** Added duplicate prev_ref_id changes
** ajeevapx : 09/06/2026 : IAO changes for required based on the item_attribute_lifecycle table
******************************************************************************/
begin
	DECLARE @IaoActiveInd VARCHAR(1);
	SELECT @IaoActiveInd = ActiveInd FROM Pdm.Framework.PdmFeatureFlag WHERE FeatureNm= 'IAO_ENABLED_FLAG'
/** setup **/
	create table #dupl (ItemCd varchar(21), AttributeId smallint, SequenceNbr smallint, qty int)
	declare @AttributeId int
		,@ItemRw				 int
		,@ItemCd				 varchar(21)
		,@OriginalOwningSystemCd char(3)
		,@OPSD_ESG_BD			 int -- AttributeNm = 'OPSD-ESG-BD'
		,@FAB_VERS				 int -- AttributeNm = 'FAB-VERS'
		,@ECO_MAJOR_CHNG		 int -- AttributeNm = 'ECO-MAJOR-CHNG'    
		,@REV_MINOR_CHNG		 int -- AttributeNm = 'REV-MINOR-CHNG'    

/** synchronize against #Item **/
	update atr 
	set atr.ItemCd = itm.ItemCd
	from #ItemAttributeValue atr
	join #Item itm on itm.ItemGuid = atr.ItemGuid and itm.ItemRw = atr.ItemRw

	update atr 
	set atr.IsValid = 0
	from #ItemAttributeValue atr
	join #Item itm on itm.ItemGuid = atr.ItemGuid and itm.ItemRw = atr.ItemRw and itm.IsValid = 0
	where atr.IsValid = 1

/** apply business rules **/
	if exists (select top 1 1 from [Framework].[CodesAndValues] where Idn = 'CIM PRCD CLASSIFICATION ACTIVE' and Value1 = 1)
	begin
		select @AttributeId = AttributeId from [ItemBom].[ItemAttribute] where AttributeNm = 'MANUFACTURED_WITH_INTEL_SN'          

		insert #ItemAttributeValue	(CrudType, ItemRw, ItemCd, AttributeId, ValueTxt)
			select CrudType, ItemRw, ItemCd, @AttributeId, 'N'
			from #Item itm
			where itm.OwningSystemCd != 'SO'
			  and itm.MaterialTypeCd  = 'PRCD'
			  and not exists (select top 1 1 from #ItemAttributeValue val where val.ItemRw = itm.ItemRw)
	end

/** special Copy Dash handling **/
	select @ItemRw = min(itm.ItemRw) 
	from #Item itm
	join [ItemBom].[Item] original on original.ItemCd = itm.OriginalItemCd and original.OwningSystemCd != 'SO'
	where itm.OriginalItemCd is not null 
	  and itm.IsValid = 1 
	  and itm.CrudType = 'Copy Dash'
	  and itm.OwningSystemCd = 'SO'
	  and itm.MaterialTypeCd in ('HALB', 'ROH')

	while (@ItemRw is not null)
	begin
		if (@OPSD_ESG_BD is null)
		begin
			select @OPSD_ESG_BD		= AttributeId from [ItemBom].[ItemAttribute] where AttributeNm = 'OPSD-ESG-BD'
			select @FAB_VERS		= AttributeId from [ItemBom].[ItemAttribute] where AttributeNm = 'FAB-VERS'
			select @ECO_MAJOR_CHNG	= AttributeId from [ItemBom].[ItemAttribute] where AttributeNm = 'ECO-MAJOR-CHNG'
			select @REV_MINOR_CHNG	= AttributeId from [ItemBom].[ItemAttribute] where AttributeNm = 'REV-MINOR-CHNG'    
		end

		select @ItemCd = ItemCd from #Item where ItemRw = @ItemRw

		if substring(@ItemCd, 7, 1) = '-' and DATALENGTH(RTRIM(@ItemCd)) = 10 
		and exists (select top 1 1 from #ItemAttributeValue where ValueTxt = 'Y' and AttributeId = @OPSD_ESG_BD)
		begin    
			if exists (select top 1 1 from #ItemAttributeValue where ItemRw = @ItemRw and AttributeId = @FAB_VERS)
				update #ItemAttributeValue set ValueTxt = SUBSTRING(@ItemCd, 8, 1) where ItemRw = @ItemRw and AttributeId = @FAB_VERS
			else
				insert #ItemAttributeValue (CrudType  ,  ItemRw,  ItemCd, AttributeId, AttributeNm, SequenceNbr, ValueTxt)
									select 'Copy Dash', @ItemRw, @ItemCd, @FAB_VERS  , 'FAB-VERS' , 1          , SUBSTRING(@ItemCd, 8, 1)


			if exists (select top 1 1 from #ItemAttributeValue where ItemRw = @ItemRw and AttributeId = @ECO_MAJOR_CHNG)    
				update #ItemAttributeValue set ValueTxt = SUBSTRING(@ItemCd, 9, 1) where ItemRw = @ItemRw and AttributeId = @ECO_MAJOR_CHNG
			else
				insert #ItemAttributeValue (CrudType  , ItemRw , ItemCd    ,   AttributeId    , AttributeNm     , SequenceNbr, ValueTxt)
										select 'Copy Dash', @ItemRw, @ItemCd, @ECO_MAJOR_CHNG, 'ECO-MAJOR-CHNG', 1          , SUBSTRING(@ItemCd, 9, 1)

			if exists (select top 1 1 from #ItemAttributeValue where ItemRw = @ItemRw and AttributeId = @REV_MINOR_CHNG)    
				update #ItemAttributeValue set ValueTxt = SUBSTRING(@ItemCd, 10, 1) where ItemRw = @ItemRw and AttributeId = @REV_MINOR_CHNG
			else
				insert #ItemAttributeValue (CrudType  , ItemRw , ItemCd    , AttributeId    , AttributeNm     , SequenceNbr, ValueTxt)
									select 'Copy Dash', @ItemRw, @ItemCd, @REV_MINOR_CHNG, 'REV-MINOR-CHNG', 1          , SUBSTRING(@ItemCd, 10, 1)
		end

		select @ItemRw = min(itm.ItemRw) 
		from #Item itm
		join [ItemBom].[Item] original on original.ItemCd = itm.OriginalItemCd and original.OwningSystemCd != 'SO'
		where itm.OriginalItemCd is not null 
		  and itm.IsValid = 1 
		  and itm.CrudType = 'Copy Dash'
		  and itm.OwningSystemCd = 'SO'
		  and itm.MaterialTypeCd in ('HALB', 'ROH')
		  and itm.ItemRw > @ItemRw
	end

/** load definition values **/
	update val set val.DataTypeCd = def.DataTypeCd, val.AttributeId = def.AttributeId, val.FormatMask = def.FormatMask
	from #ItemAttributeValue val
	join [ItemBom].[ItemAttribute] def on def.AttributeNm = val.AttributeNm
	where (val.DataTypeCd is null or val.AttributeId is null or val.FormatMask is null)
	  and  val.AttributeNm is not null

	update val set val.DataTypeCd = def.DataTypeCd, val.AttributeNm = def.AttributeNm
	from #ItemAttributeValue val
	join [ItemBom].[ItemAttribute] def on def.AttributeId = val.AttributeId
	where (val.DataTypeCd is null or val.AttributeNm is null or val.FormatMask is null)
	  and  val.AttributeId is not null

/** apply Formatting Mask to value **/
	update #ItemAttributeValue 
	set ValueTxt = [ItemBom].[ApplyItemAttributeMask] (ValueTxt, DataTypeCd, FormatMask)
	where IsValid = 1
	  and ValueTxt is not null
	  and DataTypeCd is not null
	  and nullif(rtrim(FormatMask), '') is not null

	insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
		select t.ItemRw, rw, @ModelNm, 'ValueTxt', 'Error encountered applying format mask "' + isnull(ia.AttributeDsc,'') + '": ' + replace(ValueTxt, '|MASK ERROR|', '')
		from #ItemAttributeValue t
		join ItemBom.ItemAttribute ia on ia.AttributeId = t.AttributeId
		where IsValid = 1
		  and ValueTxt is not null 
		  and ValueTxt like '|MASK ERROR|%'

	update #ItemAttributeValue set IsValid = 0, ValueTxt = replace(ValueTxt, '|MASK ERROR|', '')
	from #ItemAttributeValue val
	where IsValid = 1
	  and ValueTxt is not null 
	  and ValueTxt like '|MASK ERROR|%'

/** null handlig **/
	update src set ValueTxt = NULL 
	from #ItemAttributeValue AS src
	where ValueTxt is not null
	and rtrim(ValueTxt) = '' 
	and not exists	
		(select top 1 1 from [ItemBom].[ItemAttributeValidValue] as vld
		 where vld.AttributeId = src.AttributeId and vld.ValueTxt = '')

	update #ItemAttributeValue SET ValueTxt = '' WHERE ValueTxt = '~|~'

/** convert text to numeric or date value **/
	begin try
		UPDATE #ItemAttributeValue SET ValueDt = ValueTxt, ValueTxt = NULL, ValueNbr = NULL 
		WHERE IsValid = 1
		  and ValueTxt is not null 
		  and DataTypeCd = 'D'
	end try
	begin catch
		insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
			SELECT ItemRw, rw, @ModelNm, 'ValueDt', 'Error encountered converting to Date; ' + ERROR_MESSAGE()
			from #ItemAttributeValue
			where IsValid = 1
			  and ValueTxt is not null 
			  and DataTypeCd = 'D'
	end catch

	begin try
	    UPDATE #ItemAttributeValue SET ValueNbr = CONVERT(FLOAT, ValueTxt), ValueTxt = NULL 
		WHERE IsValid = 1
		  and ValueTxt is not null 
		  and DataTypeCd = 'N'
	end try
	begin catch
		insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
			select ItemRw, rw, @ModelNm, 'ValueNbr', 'Error encountered converting to Float; ' + ERROR_MESSAGE()
			from #ItemAttributeValue
			where IsValid = 1
			  and ValueTxt is not null 
			  and DataTypeCd = 'N'
	end catch

	update val set val.IsValid = 0
	from #ItemAttributeValue val
	join #ErrorLog err 
	  on err.ModelNm = @ModelNm 
	 and err.rw = val.rw

/** validation **/
	insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
		select ItemRw, rw, @ModelNm, 'ItemCd', 'Item Code is a required value.'
		from #ItemAttributeValue
		where IsValid = 1
		  and ItemCd is null
		  and CrudType in ('Copy Rev', 'Update', 'Delete')

	--required validation for item_attribute_lifecycle table            
    IF(@IaoActiveInd = 'Y')
    BEGIN

        IF EXISTS (
            SELECT 1 
            FROM #Item 
            WHERE MaterialTypeCd IN ('FERT','DIEN','KITS','INTG','RAPP')
        )
        BEGIN  
            INSERT INTO #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
			SELECT 
				i.ItemRw,
				iav.rw,
				@ModelNm,
				'ItemCd',
				CASE 
					WHEN il.RequiredInd = 'Y' 
						THEN 'Attribute ' + ia.AttributeDsc + ' requires a value.'
					ELSE 
						'Attribute ' + ia.AttributeDsc + ' requires a value.'
				END
			FROM #ItemAttributeValue iav
			JOIN #Item i 
				ON i.ItemGuid = iav.ItemGuid 
			AND i.ItemRw   = iav.ItemRw
			JOIN ItemBom.ItemAttribute ia 
				ON ia.AttributeId = iav.AttributeId
			JOIN ItemBom.ItemClassAttribute ica 
				ON ica.AttributeId = ia.AttributeId 
			AND ica.ClassCd     = i.ClassCd
			LEFT JOIN ItemBom.ItemAttributeLifecycle il
				ON il.AttributeId = ia.AttributeId 
			AND il.ClassCd = i.ClassCd
			AND il.StatusCd = 'A'
			WHERE 
				i.IsValid = 1
				AND NULLIF(iav.ValueTxt, '') IS NULL
				AND iav.ValueNbr IS NULL
				AND iav.ValueDt IS NULL
				AND (
					ica.RequiredInd = 'Y'     -- class-level required
					OR il.RequiredInd = 'Y'       -- lifecycle-level required
				);
        END 
        ELSE
        BEGIN
          insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)            
          select i.ItemRw, iav.rw, @ModelNm, 'ItemCd', 'Attribute ' + ia.AttributeDsc + ' requires a value.'            
          from #ItemAttributeValue iav            
          join #Item i on i.ItemGuid = iav.ItemGuid and i.ItemRw = iav.ItemRw             
          join ItemBom.ItemAttribute ia on ia.AttributeId = iav.AttributeId             
          join ItemBom.ItemClassAttribute ica on ica.AttributeId = ia.AttributeId and ica.ClassCd = i.ClassCd            
          where i.IsValid = 1            
            and nullif(iav.ValueTxt,'') is null and (iav.ValueNbr is null)  and nullif(iav.ValueDt,'') is null            
            and ica.RequiredInd = 'Y'   
        END        
    END
    ELSE
    BEGIN
      insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)            
      select i.ItemRw, iav.rw, @ModelNm, 'ItemCd', 'Attribute ' + ia.AttributeDsc + ' requires a value.'            
      from #ItemAttributeValue iav            
      join #Item i on i.ItemGuid = iav.ItemGuid and i.ItemRw = iav.ItemRw             
      join ItemBom.ItemAttribute ia on ia.AttributeId = iav.AttributeId             
      join ItemBom.ItemClassAttribute ica on ica.AttributeId = ia.AttributeId and ica.ClassCd = i.ClassCd            
      where i.IsValid = 1            
        and nullif(iav.ValueTxt,'') is null and (iav.ValueNbr is null)  and nullif(iav.ValueDt,'') is null            
        and ica.RequiredInd = 'Y'      

    END


	insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
		select ItemRw, rw, @ModelNm, 'AttributeId', 'Attribute IDN not supplied.'
		from #ItemAttributeValue
		where IsValid = 1
		  and AttributeId is null

	insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
		select ItemRw, rw, @ModelNm, 'ValueTxt', 'Invalid character ";" found in SAP Characteristic "' + isnull(AttributeNm, '') + '".'
		from #ItemAttributeValue
		where IsValid = 1
		  and ValueTxt is not null
		  and ValueTxt like '%;%'




	/*determine the permissible attributes for the class */		  
	declare @ClassAttributes table (ItemGuid varchar(40), ItemRw int, MaterialTypeCd char(4), ClassCd varchar(4), AttributeId int)

	insert into @ClassAttributes (ItemGuid, ItemRw, MaterialTypeCd, ClassCd, AttributeId) 
	select i.ItemGuid, i.ItemRw, i.MaterialTypeCd, i.ClassCd, ica.AttributeId
	from ItemBom.ItemClassAttribute ica 
	join #Item i on i.ClassCd = ica.ClassCd

	insert into @ClassAttributes (ItemGuid, ItemRw, MaterialTypeCd, ClassCd, AttributeId) 
	select i.ItemGuid, i.ItemRw, i.MaterialTypeCd, x.ClassCd, x.AttributeId
	from #Item i 
	cross join (select ica.ClassCd, ica.AttributeId from Pdm.ItemBom.ItemClassAttribute ica join Pdm.ItemBom.ItemClass c on c.ClassCd = ica.ClassCd and c.ClassDsc='OT') x
	where i.MaterialTypeCd IN ('FERT','INTG','KITS','DIEN') 

	insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
	select iav.ItemRw, iav.rw, @ModelNm, 'ValueTxt', 'Invalid attribute "' + isnull(ia.AttributeNm, '') + '" for the ' + ic.ClassDsc + ' class.' 
	from #ItemAttributeValue iav
	join ItemBom.ItemAttribute ia on ia.AttributeId = iav.AttributeId and ia.TableNm = 'item' and ia.AttributeNm not in ('ALT_IDENTIFER', 'OTHER_RPL_REASON', 'OLD_MATERIAL_NBR')
	join #Item i On i.ItemGuid = iav.ItemGuid and i.ItemRw = iav.ItemRw  
	join [ItemBom].[ItemClassAttribute] ica on ica.ClassCd = i.ClassCd and ica.AttributeId = ia.AttributeId
	join ItemBom.ItemClass ic on ic.ClassCd = i.ClassCd
	where iav.IsValid = 1 
		and not exists(select * from @ClassAttributes ica where iav.AttributeId = ica.AttributeId)
	



	update val set val.IsValid = 0
	from #ItemAttributeValue val
	join #ErrorLog err on err.ModelNm = @ModelNm and err.rw = val.rw

/** duplicate PREV_REF_ID check **/
    DECLARE @ExtId INT;
	SELECT  @ExtId = AttributeId FROM ItemBom.ItemAttribute WHERE AttributeNm = 'PREV_REF_ID';

	insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
	select iav.ItemRw, iav.rw, @ModelNm, 'PREVIOUS REFERENCE ID', 'Previous Reference ID already assigned to Item ID: ' +  uda.ItemCd 
	from #ItemAttributeValue iav
	join ItemBom.ItemAttributeValue uda ON uda.AttributeId = iav.AttributeId AND iav.ValueTxt = uda.ValueTxt 
	join #Item i On i.ItemGuid = iav.ItemGuid and i.ItemRw = iav.ItemRw
	WHERE iav.AttributeId = @ExtId and uda.ItemCd != isNull(iav.ItemCd, '')

	update val set val.IsValid = 0
	from #ItemAttributeValue val
	join #ErrorLog err on err.ModelNm = @ModelNm and err.rw = val.rw

/** duplicate check **/
	insert #dupl (ItemCd, AttributeId, SequenceNbr, qty)
		select ItemCd, AttributeId, SequenceNbr, count(*)
		from #ItemAttributeValue
		where IsValid = 1
		  and CrudType != 'Delete'
		group by ItemCd, AttributeId, SequenceNbr

	insert #ErrorLog (RowIndex, rw, ModelNm, PropertyNm, ErrorMessage)
		select tmp.ItemRw, tmp.rw, @ModelNm, 'ValueTxt', 'Duplicate SAP Characteristic "' + isnull(def.AttributeNm, '') + '" with sequence number ' + convert(varchar, tmp.SequenceNbr) + '.'
		from #ItemAttributeValue tmp
		join #dupl
		  on #dupl.ItemCd      = tmp.ItemCd
		 and #dupl.AttributeId = tmp.AttributeId
		 and #dupl.SequenceNbr = tmp.SequenceNbr
		 and #dupl.qty > 1
		join [ItemBom].[ItemAttribute] def on def.AttributeId = tmp.AttributeId

	update val set val.IsValid = 0
	from #ItemAttributeValue val
	join #ErrorLog err on err.ModelNm = @ModelNm and err.rw = val.rw

/** synchronize against #Item **/
	update itm set itm.IsValid = 0
	from #Item itm
	join #ItemAttributeValue atr on atr.ItemRw = itm.ItemRw and atr.IsValid = 0
	where itm.IsValid = 1


	
/** cleanup **/
	drop table #dupl
end
GO