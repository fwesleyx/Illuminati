USE [Pdm]; 
GO 
 
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [PdmApi].[AttributeValidate]
(
	@AppName VARCHAR(127) = NULL,
	@debug CHAR(1) = 'N' 
)
/******************************************************************************      
*** Purpose: Procedure to validate the given SAP values against the SAP rules for:
			 required validation, data type validation, value length validation 
			 & update the default values if not provided, add the items that are not
			 provided and has default values, into the list
*** Details: To be called by procedure [PdmApi].[ItemCRUD]
	Prerequisite: Temp table #ItemUdt, #SAPCharacteristics and #templateInfo 
			 already have the details to validate
*** History: psaxen2x, 11/30/2017
***          wng5      4/7/2020    DE74018 - Skip SAP Attribute Validation for PLM Item with DRAFT status  
			 neeneeli  4/28/2020   Add multi value validation for SAP characteristics
			 wng5	   10/12/2020  CHG001856679 Remove validation for status Draft to Inactive
			 wng5      03/09/2022  CHG10347359 Remove validation for PLM
			 navishnx 12/07/2023 CHG11063941 Incase of NULL, converting sap.ValueTxt to empty
			 hnarang 02/24/2025 - IAO Feature flag and Product Hierachy removal changes for IAO R3
			 settupax 06/01/2026 - Required and Locking attributes for IAO R3
             francisx 29/06/2026 - ItemCRUD:Defect Fix increase the column size Attribute Temp table
*** Copyright 2017 Intel Corporation, all rights reserved.      
******************************************************************************/ 
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SapTemplateID INT = 0
	DECLARE @ClassCd CHAR(4)
	DECLARE @MaterialType CHAR(4)
	DECLARE @DesignGroup CHAR(2)
	DECLARE @Attributes VARCHAR(8000) = '' 

	DECLARE @MaxRowId INT
	DECLARE @CurrRowId INT
	
	DECLARE @fcst_pkg_dvc NVARCHAR(255) 
	DECLARE @fg_fcst_pkg VARCHAR(255) 
	DECLARE @vldt_rslt NVARCHAR(MAX) 
	DECLARE @url VARCHAR(255)
	DECLARE @ProductLineIdn INT
	DECLARE @usr_acct   VARCHAR(8) 
	DECLARE @StatusCd CHAR(1)
 	DECLARE @IaoActiveInd varchar(1) -- hnarang 02/24/2025 - IAO Feature flag

	/* Validation Begin */
	-- temp table does not exists.
	IF OBJECT_ID('tempdb..#ItemUdt') IS NULL OR OBJECT_ID('tempdb..#SAPCharacteristics') IS NULL OR OBJECT_ID('tempdb..#templateInfo') IS NULL
	BEGIN
		IF @debug = 'Y'
		BEGIN
			PRINT '[PdmApi].[AttributeValidate] - Temp table does not exists'
		END

		RETURN;
	END

	-- No item exists in the table
	IF NOT EXISTS(SELECT 1 FROM #ItemUdt) 
	BEGIN
		IF @debug = 'Y'
		BEGIN
			PRINT '[PdmApi].[AttributeValidate] - No item in #ItemUdt'
		END

		RETURN;
	END

	-- if no valid item exists, dont validate further
	IF NOT EXISTS(SELECT 1 FROM #ItemUdt WHERE ResultStatus <> 'Invalid')
	BEGIN
		RETURN;
	END

	SET @CurrRowId = (SELECT MIN(SessionId) FROM #ItemUdt WHERE ISNULL(ResultStatus,'') <> 'Invalid')
	SET @MaxRowId = (SELECT MAX(SessionId) FROM #ItemUdt WHERE ISNULL(ResultStatus,'') <> 'Invalid')
 	SET @IaoActiveInd =(SELECT ActiveInd FROM Pdm.Framework.PdmFeatureFlag WHERE FeatureNm= 'IAO_ENABLED_FLAG')  --hnarang 02/24/2025 - IAO Feature flag
	
	---- temp table to get the SAP Characteristics of each item
   	CREATE TABLE #Attributes (
		AttributeId INT,
		AttributeName VARCHAR(50),
		IsRequired BIT, -- if true: it is a must have value
		DataType VARCHAR(10), -- acceptable datatype of the value
		DataLen INT NULL, -- acceptable length of the value
		DefaultValue VARCHAR(255), -- assign this default value to the attribute if not passed
		IsEditable BIT, -- if false: attribute cannot be updated
		HasValidList BIT, -- if true: validate the attribute value against the list only.	
		RestrictToValidList BIT, -- if false: value of the attribute can be selected from the list or entered as well
		mask VARCHAR(255),
		TableNm VARCHAR(32)
		);

	-- table to be used when the item is begin updated. 
	-- to match the SAP Characteristics: Current vs New
	CREATE TABLE #MatchAtt (
		RowId INT,
		ItemCd [varchar](21) NULL,
		AttributeId INT,
		AttributeNm VARCHAR(30) ,
		CurrentValue [varchar](255) NULL,
		NewValue [varchar](255) NULL,
		IsEditable BIT )
	
	IF @debug = 'Y'
	BEGIN
		PRINT '[PdmApi].[AttributeValidate] - Validating SAP Characteristics.'
	END

	 IF @IaoActiveInd <>'Y'	 --hnarang 02/24/2025 - IAO Feature flag and Product Hierachy removal changes for IAO R3
	-- #Validation: validate Forecast Package - common for all FERT 
    UPDATE I
	SET I.ResultStatus = 'Invalid',
		I.ResultMessage = CONCAT(I.ResultMessage, 'Invalid Forecast Package value: ', I.ForcastPackage, ', ')
	FROM    #ItemUdt AS I
            LEFT JOIN ItemBom.ItemAttributeValidValue AS vld ON vld.ValueTxt = I.ForcastPackage AND vld.ActiveInd = 1
            LEFT JOIN ItemBom.ItemAttribute AS def ON def.AttributeId = vld.AttributeId AND def.ActiveCd='Y'
    WHERE  I.MaterialTypeCd = 'FERT'
            AND I.ForcastPackage IS NOT NULL
            AND vld.ValueTxt IS NULL
			AND def.AttributeNm = 'MM-PACKAGE-MKT-DESIGNATOR'
			
	-- loop through each item to get its set of SAP Attribute and validate its characteristics against these Attribute.
	WHILE(@CurrRowId <= @MaxRowId)
	BEGIN
		-- validate SAP attributes only for valid items. 
		IF EXISTS(SELECT 1 FROM #ItemUdt WHERE ResultStatus <> 'Invalid' AND RowId = @CurrRowId)
		BEGIN
			-- collect the item details required to get the list of characteristics
			SELECT 
				@ClassCd = ClassCd,
				@MaterialType = MaterialTypeCd,
				@DesignGroup = BusinessUnitCd,
				@usr_acct = ResponsibleEngineer
			FROM #ItemUdt
			WHERE RowId = @CurrRowId

			-------- Get Responsible Eng User Account, Some User have different WWID and USer Acct	
					
			SET @usr_acct = ( Select UsrAcctCd from Security.Users where Wwid = @usr_acct)

			-- Get the SAP template name for this item. Templates are not necessary for each material type. In such case it will be NULL
			SET @SapTemplateID = (
				SELECT t.tmpl_idn 
				FROM #templateInfo ti 
					JOIN [speed].[dbo].[template] t ON t.title = ti.TemplateSAPCharTitle 
				WHERE ti.RowId = @CurrRowId
					AND t.bus_unit_idn = @DesignGroup
					AND t.parent_ent_idn = 42 -- SAP Characteristics
					AND t.actv_ind = 'Y')

			IF @debug = 'Y'
			BEGIN
				PRINT CONCAT('[PdmApi].[AttributeValidate] - EXEC [PdmApi].[ItemAttributesPatternGet] @SapTemplateID = ' , @SapTemplateID, ', @ClassCd = ', 
						@ClassCd, ', @MaterialType = ' , @MaterialType, ', @DesignGroup = ', @DesignGroup)
			END

			-- Get the attribute details for this item based on SAP template, class code, material type & design group
			-- Proc [PdmApi].[ItemAttributesPatternGet] is populating the temp table #Attributes
			-- NOTE: Moved the inserting logic due to error 'An INSERT EXEC statement cannot be nested.'
			EXEC [PdmApi].[ItemAttributesPatternGet]
				@SapTemplateID = @SapTemplateID,
				@ClassCd  = @ClassCd,
				@MaterialType = @MaterialType,
				@DesignGroup = @DesignGroup, 
				@usr_acct = @usr_acct ,
				@debug = @debug,
				@CurrRowId = @CurrRowId

			IF @debug = 'Y'
			BEGIN
				SELECT 'Attributes' as 'Attributes', * FROM #Attributes
			END
			
			-- Validation: validate if temp table #Attributes has any data.
			IF NOT EXISTS(SELECT 1 FROM #Attributes)
			BEGIN
				UPDATE #ItemUdt
				SET ResultMessage = CONCAT(ResultMessage, 'Item Detail errors found: Skipping SAP validation, '),
					ResultStatus = 'Invalid'
				WHERE RowId = @CurrRowId

				CONTINUE;
			END

			/* special chars with no val list */
            UPDATE  #Attributes
            SET     HasValidList = 0
            WHERE   AttributeName = 'MM-ITEM-MARKET-NAME' 

			/* spec sequential is not required because is calculated */
			UPDATE  #Attributes
            SET     IsRequired = 'false'
            WHERE AttributeName = 'MM-SPEC-NUMBER' 

			IF @AppName = 'PSG'
			BEGIN
				/* device code for PSG is generated by us just before making request for item creation. 
					bypass validation for that. */
				IF EXISTS(SELECT 1 FROM #ItemUdt WHERE 
						RowId = @CurrRowId 
					AND CrudType ='CREATE'
					AND ClassDsc IN ('UPI_ASSEMBLY', 'UPI_BUMP', 'UPI_FAB', 'UPI_SORT', 'UPI_TEST'))
				BEGIN
					UPDATE  #Attributes
					SET     IsRequired = 'false'
					WHERE AttributeName = 'PS-MFG-DEVICE' 
				END				
			END
			
			-- delete those records which does not have value			
			DELETE FROM #SAPCharacteristics
			WHERE RowId = @CurrRowId
			AND ValueTxt is null

			-- #Upper Text Conversion
			UPDATE  sap SET sap.ValueTxt = upper(sap.ValueTxt)
			FROM #SAPCharacteristics sap JOIN #Attributes s ON sap.AttributeId = s.AttributeId
			WHERE ((s.mask like ('%!%') AND sap.RowId = @CurrRowId) or s.TableNm like 'uda') 		

			IF @AppName = 'PLM'  
			BEGIN  			
    ---- Convert numeric value to float      
    UPDATE  sap SET sap.ValueTxt = CONVERT(float, NULLIF(sap.ValueTxt,'')) -- navishnx 12/07/2023 CHG11063941 Incase of NULL, converting sap.ValueTxt to empty      
    FROM #SAPCharacteristics sap JOIN #Attributes s ON sap.AttributeId = s.AttributeId      
    WHERE s.DataType = 'int' and s.mask like '%#.#%'      
				--Validate SeqNo for multi value row				
				SELECT @Attributes=COALESCE( @Attributes + ', ', '') + sap.AttributeNm   
				FROM #SAPCharacteristics sap    
				JOIN ItemBom.ItemAttribute ia ON ia.AttributeId = sap.AttributeId
				WHERE sap.RowId = @CurrRowId
				AND ia.ActiveCd = 'Y' AND ia.MultipleValuesInd = 'Y'
				AND (sap.SeqNo = 0 OR sap.SeqNo = '')   

				IF @Attributes IS NOT NULL AND LEN(LTRIM(@Attributes)) > 0   
				BEGIN 
					UPDATE I
					SET I.ResultStatus = 'Invalid',
						I.ResultMessage = CONCAT(I.ResultMessage, 'SAP Attributes SeqNo should be numeric and greater than 0 : [' +  SUBSTRING(@Attributes, 3, LEN(@Attributes)) + '], ')
					FROM #ItemUdt AS I
					WHERE RowId = @CurrRowId  

					SET @Attributes = ''
				END				
				
				--SeqNo cannot have duplicate value
				SELECT @Attributes=COALESCE( @Attributes + ', ', '') + sap.AttributeNm  
				FROM #SAPCharacteristics sap   
				JOIN ItemBom.ItemAttribute ia ON ia.AttributeId = sap.AttributeId
				WHERE sap.RowId = @CurrRowId
				AND ia.ActiveCd = 'Y' AND ia.MultipleValuesInd = 'Y'
				AND sap.SeqNo <> ''
				GROUP BY sap.SeqNo, sap.AttributeId, sap.AttributeNm   
				HAVING COUNT(sap.SeqNo) > 1
				
				IF @Attributes IS NOT NULL AND LEN(LTRIM(@Attributes)) > 0   
				BEGIN  
					UPDATE I
					SET I.ResultStatus = 'Invalid',
						I.ResultMessage = CONCAT(I.ResultMessage, 'SAP Attributes SeqNo is duplicate : [' +  SUBSTRING(@Attributes, 3, LEN(@Attributes)) + '], ')
					FROM #ItemUdt AS I
					WHERE RowId = @CurrRowId  

					SET @Attributes = ''
				END  

				--Multi value cannot have duplicate value
				SELECT @Attributes=COALESCE( @Attributes + ', ', '') + sap.AttributeNm
				FROM #SAPCharacteristics sap
				JOIN ItemBom.ItemAttribute ia ON ia.AttributeId = sap.AttributeId
				WHERE sap.RowId = @CurrRowId
				AND ia.ActiveCd = 'Y' AND ia.MultipleValuesInd = 'Y'
				AND sap.ValueTxt <> ''
				GROUP BY sap.ValueTxt, sap.AttributeId, sap.AttributeNm
				HAVING COUNT(sap.ValueTxt) > 1
				
				IF @Attributes IS NOT NULL AND LEN(LTRIM(@Attributes)) > 0   
				BEGIN  
  					UPDATE I
					SET I.ResultStatus = 'Invalid',
						I.ResultMessage = CONCAT(I.ResultMessage, 'SAP Attributes Multi Value is duplicate : [' +  SUBSTRING(@Attributes, 3, LEN(@Attributes)) + '], ')
					FROM #ItemUdt AS I
					WHERE RowId = @CurrRowId  

					SET @Attributes = ''
				END  

				-- Validate required field for multi value						
				SELECT @Attributes=COALESCE( @Attributes + ', ', '') + 'SeqNo ' + CAST(sap.SeqNo AS NVARCHAR) + ':' + sap.AttributeNm   
				FROM #Attributes a  
				JOIN #SAPCharacteristics sap ON sap.AttributeId = a.AttributeId   
				JOIN ItemBom.ItemAttribute ia ON sap.AttributeId = ia.AttributeId AND ia.MultipleValuesInd = 'Y'
				WHERE a.IsRequired = 1   
				AND (sap.ValueTxt IS NULL OR (RTRIM(sap.ValueTxt) = ''))  
				ORDER BY sap.AttributeNm  
		
				-- SeqNo and attributes name is required for multi value
				IF @Attributes IS NOT NULL AND LEN(LTRIM(@Attributes)) > 0   
				BEGIN  
					UPDATE #ItemUdt  
					SET ResultMessage = CONCAT(ResultMessage, 'Required SAP Attributes Multi Value missing: [' + SUBSTRING(@Attributes, 3, LEN(@Attributes)) + '], '),  
					ResultStatus = 'Invalid'  
					WHERE RowId = @CurrRowId  
				END  
				SET @Attributes = ''
				
				-- Get Existing/Previous Rev StatusCd
				SELECT @StatusCd = Isnull(ir.StatusCd,'') 
				FROM #ItemUdt u
				JOIN ItemBom.Item i ON u.ItemCd = i.ItemCd 
				JOIN ItemBom.ItemRevision ir ON i.ItemCd = ir.ItemCd and i.ManufacturingRevision = ir.Revision
				WHERE u.RowId = @CurrRowId

				IF EXISTS(SELECT 1 FROM #ItemUdt WHERE RowId = @CurrRowId AND [CrudType] = 'CREATE' AND [StatusNm] <> 'k') 
					AND NOT (@StatusCd = 'k' AND EXISTS(SELECT 1 FROM #ItemUdt WHERE RowId = @CurrRowId AND [CrudType] = 'CREATE' AND [StatusNm] = '8'))			
				BEGIN       
					EXEC [PdmApi].[AttributeCreateValidate] @CurrRowId = @CurrRowId, @debug = @debug  
				END  
				ELSE IF EXISTS(SELECT 1 FROM #ItemUdt WHERE RowId = @CurrRowId AND [CrudType] = 'UPDATE' AND [StatusNm] <> 'k') 
					AND NOT (@StatusCd = 'k' AND EXISTS(SELECT 1 FROM #ItemUdt WHERE RowId = @CurrRowId AND [CrudType] = 'UPDATE' AND [StatusNm] = '8'))				
				BEGIN  
					EXEC [PdmApi].[AttributeCreateValidate] @CurrRowId = @CurrRowId, @debug = @debug  
					EXEC [PdmApi].[AttributeUpdateValidate] @CurrRowId = @CurrRowId, @debug = @debug  
				END  
			END  
			ELSE 
			BEGIN
				--#Validation: On the basis of Crud Type of the item
				IF EXISTS(SELECT 1 FROM #ItemUdt WHERE RowId = @CurrRowId AND [CrudType] = 'CREATE')
				BEGIN
					---------------- VALIDATE SAP CHARACTRISTICS FOR ITEM CREATE BEGIN ---------------
					EXEC [PdmApi].[AttributeCreateValidate] @CurrRowId = @CurrRowId, @debug = @debug
					---------------- VALIDATE SAP CHARACTRISTICS FOR ITEM CREATE END ---------------
				END
				ELSE IF EXISTS(SELECT 1 FROM #ItemUdt WHERE RowId = @CurrRowId AND [CrudType] = 'UPDATE')
				BEGIN
					---------------- VALIDATE SAP CHARACTRISTICS FOR ITEM UPDATE BEGIN ---------------
					EXEC [PdmApi].[AttributeUpdateValidate] @CurrRowId = @CurrRowId, @debug = @debug
					---------------- VALIDATE SAP CHARACTRISTICS FOR ITEM UPDATE END ---------------
				END
			END
			
			-- No validation for PLM
			IF(UPPER(@AppName) <> 'PLM')
			BEGIN
				-- #Validation: check if all the given attribute names are valid for this item. 
				SELECT @Attributes = COALESCE( @Attributes + ', ', '') + AttributeNm
				FROM #SAPCharacteristics 
				WHERE RowId = @CurrRowId 
					AND AttributeId IS NULL
			
				-- have the name of the attributes that are not in the list
				IF @Attributes IS NOT NULL AND LEN(LTRIM(@Attributes)) > 0 
				BEGIN
					UPDATE #ItemUdt
					SET ResultMessage = CONCAT(ResultMessage, 'Invalid SAP Attributes: [' + SUBSTRING(@Attributes, 3, LEN(@Attributes)) + '], '),
						ResultStatus = 'Invalid'
					WHERE RowId = @CurrRowId

					SET @Attributes = ''
				END
			END

			-- #Validation: for INT Data Type - validate the given values as per required data types. 
			-- Get the name of the attributes that are expected to be int data type but value is not int
			SELECT @Attributes = COALESCE( @Attributes + ', ', '') + s.AttributeName 
			FROM #Attributes s
				FULL JOIN #SAPCharacteristics p ON p.AttributeId = s.AttributeId
			WHERE s.DataType = 'int'
				AND ISNUMERIC(ISNULL(p.ValueTxt, 0) ) = 0 
				AND  p.ValueTxt <>''
				AND p.RowId = @CurrRowId

			-- have the name of the attributes that are required but not passed
			IF @Attributes IS NOT NULL AND LEN(LTRIM(@Attributes)) > 0 
			BEGIN
				UPDATE #ItemUdt
				SET ResultMessage = CONCAT(ResultMessage, 'Invalid numeric SAP Value for Attributes: [' + SUBSTRING(@Attributes, 3, LEN(@Attributes)) + '], '),
					ResultStatus = 'Invalid'
				WHERE RowId = @CurrRowId

				SET @Attributes = ''
			END


			-- #Validation: for INT Range - validate the given values which are expected numeric and within given range
			SELECT @Attributes = COALESCE( @Attributes + ', ', '') + s.AttributeName 
			FROM #Attributes s
				FULL JOIN #SAPCharacteristics sap ON sap.AttributeId = s.AttributeId
				JOIN ItemBom.ItemAttributeValidRange vv ON vv.AttributeId = sap.AttributeId
			WHERE s.DataType = 'int'
				AND ISNUMERIC(ISNULL(sap.ValueTxt, 0) ) = 1
				AND sap.RowId = @CurrRowId
				AND ( CAST(sap.ValueTxt AS FLOAT) < vv.MinValueNbr
						  OR CAST(sap.ValueTxt AS FLOAT) > vv.MaxValueNbr	)

			-- if there are any attributes which has numeric values but values are out of range
			IF @Attributes IS NOT NULL AND LEN(LTRIM(@Attributes)) > 0 
			BEGIN
				UPDATE #ItemUdt
				SET ResultMessage = CONCAT(ResultMessage, 'Numeric SAP Value for Attributes are out of range: [', SUBSTRING(@Attributes, 3, LEN(@Attributes)), '], '),
					ResultStatus = 'Invalid'
				WHERE RowId = @CurrRowId

				SET @Attributes = ''
			END
			

			-- #Validation: for DATETIME data type - validate the given values as per required data types. 
			-- Get the name of the attributes that are expected to be DATETIME data type but value is not DATETIME
			SELECT @Attributes = COALESCE( @Attributes + ', ', '') + s.AttributeName 
			FROM #Attributes s
				FULL JOIN #SAPCharacteristics p ON p.AttributeId = s.AttributeId
			WHERE s.DataType = 'datetime'
				AND ISDATE(ISNULL(p.ValueTxt, getdate()) ) = 0
				AND p.RowId = @CurrRowId

			-- have the name of the attributes that are required but not passed
			IF @Attributes IS NOT NULL AND LEN(LTRIM(@Attributes)) > 0 
			BEGIN
				UPDATE #ItemUdt
				SET ResultMessage = CONCAT(ResultMessage, 'Invalid datetime SAP Value for Attributes: [', SUBSTRING(@Attributes, 3, LEN(@Attributes)), '], '),
					ResultStatus = 'Invalid'
				WHERE RowId = @CurrRowId

				SET @Attributes = ''
			END
				

			-- #Validation: for valid list values - validate attribute values against the list of valid values		
   IF @AppName = 'PLM'      
   BEGIN     
      CREATE TABLE #temp (AttributeId INT, ValueTxt VARCHAR(255))      
      
      INSERT INTO #temp      
      SELECT v.AttributeId, v.ValueTxt       
      FROM ItemBom.ItemAttributeValidValue v       
      JOIN #Attributes s1 ON s1.AttributeId = v.AttributeId      
      WHERE ActiveInd = 1      
      
      -- Convert LOV to float value when fulfill the criteria    
      UPDATE t      
      SET  ValueTxt = CONVERT(float, t.ValueTxt)      
      FROM #temp t    
      JOIN #Attributes s1 ON s1.AttributeId = t.AttributeId      
      WHERE s1.DataType = 'int' and s1.mask like '%#.#%'      
      
      IF @debug = 'Y'      
      BEGIN    
       SELECT t.ValueTxt, CONVERT(float, t.ValueTxt)      
       FROM #temp t      
       JOIN #Attributes s1 ON s1.AttributeId = t.AttributeId      
       WHERE s1.DataType = 'int' and s1.mask like '%#.#%'      
      END      
         
      SELECT @Attributes = CASE WHEN CHARINDEX(AttributeNm, @Attributes) > 0 THEN @Attributes ELSE COALESCE( @Attributes + ', ', '') + A.AttributeNm END      
      FROM    #SAPCharacteristics A       
      JOIN #Attributes s ON s.AttributeId = A.AttributeId            
      LEFT JOIN  (      
       SELECT *           
       FROM #temp      
      ) vv ON A.AttributeId = vv.AttributeId AND UPPER(RTRIM(A.ValueTxt)) = UPPER(RTRIM(vv.ValueTxt))      
      WHERE   s.HasValidList = 1           
     AND s.RestrictToValidList = 1      
     AND (A.ValueTxt is NOT NULL AND (LTRIM(RTRIM(A.ValueTxt)) != '' or s.IsRequired =1))          
     AND vv.ValueTxt is NULL      
   END    
   ELSE    
   BEGIN    
			SELECT @Attributes = CASE WHEN CHARINDEX(AttributeNm, @Attributes) > 0 THEN @Attributes ELSE COALESCE( @Attributes + ', ', '') + A.AttributeNm END
			FROM    #SAPCharacteristics A	
						JOIN #Attributes s ON s.AttributeId = A.AttributeId 					
						LEFT JOIN  (SELECT * FROM ItemBom.ItemAttributeValidValue WHERE ActiveInd = 1) vv ON A.AttributeId = vv.AttributeId AND A.ValueTxt =vv.ValueTxt						
						  AND RTRIM(A.ValueTxt) = RTRIM(vv.ValueTxt)
			WHERE   s.HasValidList = 1					
					AND s.RestrictToValidList = 1
					AND (A.ValueTxt is NOT NULL AND (LTRIM(RTRIM(A.ValueTxt)) != '' or s.IsRequired =1))				
					AND vv.ValueTxt is NULL	
   END      
           
			-- have the name of the attributes that are not in validation list
			IF @Attributes IS NOT NULL AND LEN(LTRIM(@Attributes)) > 0 
			BEGIN
				UPDATE #ItemUdt
				SET ResultMessage = CONCAT(ResultMessage, 'Invalid value for: [', SUBSTRING(@Attributes, 3, LEN(@Attributes)) + '], '),
					ResultStatus = 'Invalid'
				WHERE RowId = @CurrRowId

				SET @Attributes = ''	
			END


			-- #Validation: for Product Line RAPP - Validate product line for RAPP Material Type
			IF EXISTS(SELECT 1 FROM #ItemUdt WHERE MaterialTypeCd ='RAPP' AND RowId = @CurrRowId)
			BEGIN
				DECLARE @val_txt NVARCHAR(255) 
				DECLARE	@att_idn INT 

				SET @ProductLineIdn = (SELECT AttributeId FROM ItemBom.ItemAttribute WHERE AttributeNm='PRODUCT_LINE')

				SET @vldt_rslt = 'TRUE' 
				-- get the attribute If for attribute PRODUCT_LINE
				SET @att_idn = @ProductLineIdn

				SELECT  @val_txt = ValueTxt
				FROM    #SAPCharacteristics
				WHERE   ISNULL(ValueTxt, '') <> ''
					AND AttributeId = @att_idn 
					AND RowId = @CurrRowId

				-- while updating, it is not nessaracy we have that.
				IF ISNULL(@val_txt,'') <> ''
				BEGIN
					-- get the base url
					EXEC speed.[dbo].[prc_cnctbx_get_base_url] @url OUTPUT;
	  
					EXEC speed.dbo.prc_mrpm_clr_ValidateProductLine 
						@svc_url_base = @url,
						@val_txt = @val_txt,
						@vldt_rslt = @vldt_rslt OUTPUT;

					IF @vldt_rslt = 'FALSE'
					BEGIN
						UPDATE #ItemUdt
						SET ResultMessage = CONCAT(ResultMessage, 'Invalid Product Line: ', @val_txt, ', '),
							ResultStatus = 'Invalid'
						WHERE RowId = @CurrRowId
					END
				END
			END

		END

		DELETE FROM #Attributes
		SET @CurrRowId = @CurrRowId + 1
	END

	-- drop temp table before exit
	DROP TABLE #Attributes
	DROP TABLE #MatchAtt

	IF @debug = 'Y'
	BEGIN
		SELECT '[PdmApi].[AttributeValidate] (Validated SAP Attribute Item UDT)' AS 'Proc Name', * FROM #ItemUdt

		SELECT '[PdmApi].[AttributeValidate] (Validated SAP Attribute SAP Char UDT)' AS 'Proc Name', * FROM #SAPCharacteristics
	END
	
	SET NOCOUNT OFF;
END
GO