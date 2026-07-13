USE [Pdm]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [BulkImport].[AttributeValidate]
    (
      @QueueMasterId INT ,
      @Wwid INT = NULL ,
      @debug BIT = 0
    )
/************************************************************/
-- 03 Called by BulkImport.ItemProcess
-- Validates basic data for sap chars
-- marks failed rows 
-- becuase we are importing at draft we won't run require or data validations
-- fix restrict to list check
-- 02/16/2018 change the logic to determine if attribute has validation list based upon ItemBom.ItemClassAttribute column
-- Restricttovalid list and listcount from view [ItemBom].[ItemAttributeValidValue] 
-- rahul15x 03/28/2024 CHG11181968 - PDM Bulk Import Error. 
-- rtatikon	13/12/2025 added IAO_ENABLED_FLAG for PRODUCT_LINE validation
-- raviarav     05/11/2026 added IAO UNBW material type for IAO validation
-- ajeevapx : 04/02/2026 : IAO changes for required an locking indicator based on the item_attribute_lifecycle table
/************************************************************/
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @ClassCd VARCHAR(30) ,
            @MaterialType VARCHAR(4) ,
            @SapTemplateID INT ,
            @DesignGroup VARCHAR(2),
			@IaoActiveInd VARCHAR(1); 

		SELECT @IaoActiveInd = ActiveInd 
				FROM Pdm.Framework.PdmFeatureFlag
				WHERE FeatureNm= 'IAO_ENABLED_FLAG'

        SELECT  @ClassCd = ClassCd ,
                @MaterialType = MaterialTypeCd ,
                @SapTemplateID = TemplateSAPCharId ,
                @DesignGroup = BusinessUnitCd
        FROM    BulkImport.QueueMaster
        WHERE   QueueMasterId = @QueueMasterId;

		/* to process all the chars*/
        CREATE TABLE #valid_chars
            (
              RowId INT ,
			  RefId INT ,---rahul15x 03/28/2024 CHG11181968 - PDM Bulk Import Error
              AttributeId INT ,
              AttributeNm VARCHAR(30) ,
              ExternalItemCd VARCHAR(100) ,
              ItemCd VARCHAR(21) ,
              AttributeDsc VARCHAR(255) ,
              ItemAttributeValue VARCHAR(255) ,
              RequiredInd VARCHAR(10) ,
              DataType VARCHAR(10) ,
			  RestrictToValidValuesInd CHAR(1) ,
              RestrictToValidList CHAR(1) ,
              ErrorMessage VARCHAR(255)
            );
/* FOR FG CHARS */
        CREATE TABLE #sap_req
            (
              ttl VARCHAR(25) ,
              att_idn INT ,
              att_nme VARCHAR(30) ,
              CharLabel VARCHAR(60) ,
              RequiredInd VARCHAR(6) ,
              DataType VARCHAR(10) ,
              list_count INT ,
              sort_grp INT ,
              ord INT ,
              display_val VARCHAR(30)
            );


/* to get the chars for FG from templates */
        IF @MaterialType IN ( 'FERT', 'DIEN', 'KITS', 'INTG', 'RAPP', 'UNBW' )
            BEGIN   
			  INSERT  INTO #sap_req
                        ( ttl ,
                          att_idn ,
                          att_nme ,
                          CharLabel ,
                          RequiredInd ,
                          DataType ,
                          list_count ,
                          sort_grp ,
                          ord ,
                          display_val
		                )
                        EXEC [BulkImport].[ItemAttributesPatternGet] --@Wwid = @Wwid,
                            @SapTemplateID = @SapTemplateID,
                            @ClassCd = @ClassCd, @MaterialType = @MaterialType,
                            @DesignGroup = @DesignGroup;

/* populate working table with template info */			
                INSERT  #valid_chars
                        ( RowId ,
						  RefId ,----rahul15x 03/28/2024 CHG11181968 - PDM Bulk Import Error
                          AttributeId ,
                          AttributeNm ,
                          ExternalItemCd ,
                          ItemCd ,
                          AttributeDsc ,
                          ItemAttributeValue ,
                          RequiredInd ,
                          DataType ,
                          RestrictToValidList 		
			            )
                        SELECT  q.AttributeRowId ,									--	RowId ,
						        q.ReferenceId,										--  RefId , ----rahul15x 03/28/2024 CHG11181968 - PDM Bulk Import Error	
                                s.att_idn ,											--	AttributeId ,
                                s.att_nme ,											--  att name
                                q.ExternalItemCd ,									--	ExternalItemCd ,
                                q.ItemCd ,											--	ItemCd ,
                                q.AttributeDsc ,									--	AttributeDsc ,
                                q.ItemAttributeValue ,								--	ItemAttributeValue ,
                                s.RequiredInd ,										--	RequiredInd ,
                                s.DataType ,									--	DataType ,								
                                CASE WHEN s.list_count > 0 THEN 'Y'					--	RestrictToValidList 	
                                     ELSE 'N'
                                END
                        FROM    BulkImport.QueueItemAttributes q
                                LEFT JOIN BulkImport.QueueItem qi ON qi.ExternalItemCd = q.ExternalItemCd AND qi.QueueMasterId = @QueueMasterId								
                                LEFT JOIN #sap_req s ON s.CharLabel = q.AttributeDsc
                        WHERE   q.QueueMasterId = @QueueMasterId
						        

/** now update RestrictToValidValuesInd column as class like 0013 BD dont have the full attribute list
like Royalty Payable and if we update above those attribute will be ommited */       
 UPDATE  vc
 SET     vc.RestrictToValidValuesInd = ica.RestrictToValidList
 FROM   #valid_chars vc 
 LEFT JOIN [ItemBom].[ItemClassAttribute] ica ON ica.AttributeId = vc.AttributeId 
 WHERE ica.ClassCd = @ClassCd;

/* special chars with no val list */
                UPDATE  #valid_chars
                SET     RestrictToValidList = 'N'
                WHERE   AttributeNm IN ( 'MM-ITEM-MARKET-NAME' );
/* spec sequential is not required becuase is calculated */
 -- commented for this MM-SPEC-NUMBER validation part reason: item attribute lifecycle table attribute is mandatory
		--UPDATE  #valid_chars
                --SET     RequiredInd = 'N'
               --WHERE   AttributeNm IN ( 'MM-SPEC-NUMBER' );

				EXEC [BulkImport].[AttributeDependencyValidate] @sap_mat_typ=@MaterialType,@item_typ_cde=@ClassCd, @bus_unit_idn=@DesignGroup,@sap_tmpl_idn=@SapTemplateID
					
                IF @debug = 1
                    BEGIN
                        SELECT  '#sap' ,
                                *
                        FROM    #sap_req;
                        SELECT  '#valid' ,
                                *
                        FROM    #valid_chars;
                        RETURN;
                    END;

            END;
        ELSE
            BEGIN

-- get att_idn for 6-3
                INSERT  #valid_chars
                        ( RowId ,
                          AttributeId ,
                          ExternalItemCd ,
                          ItemCd ,
                          AttributeDsc ,
                          ItemAttributeValue ,
                          RequiredInd ,
                          DataType ,
						  RestrictToValidValuesInd,
                          RestrictToValidList 
		                )
                        SELECT  q.AttributeRowId ,
                                ica.AttributeId ,
                                q.ExternalItemCd ,
                                q.ItemCd ,
                                q.AttributeDsc ,
                                q.ItemAttributeValue ,
                                ica.RequiredInd ,
                                ia.DataTypeCd ,
                                ica.RestrictToValidList,
								CASE (SELECT COUNT(*)      
                                FROM [ItemBom].[ItemAttributeValidValue] vv      
                                WHERE vv.AttributeId = ia.AttributeId   
                                AND vv.[ActiveInd] = 1       
                                AND NOT EXISTS(SELECT vr.AttributeId      
                                FROM [ItemBom].[ItemAttributeValidRange] vr      
                                WHERE vv.AttributeId = vr.AttributeId ) )      
                                WHEN 0 THEN 'N' ELSE 'Y' 
								END
                        FROM    BulkImport.QueueItemAttributes q
                                LEFT JOIN BulkImport.QueueItem qi ON qi.ExternalItemCd = q.ExternalItemCd
                                LEFT JOIN [ItemBom].[ItemAttribute] ia ON ia.AttributeDsc = q.AttributeDsc
                                LEFT JOIN [ItemBom].[ItemClassAttribute] ica ON ica.AttributeId = ia.AttributeId
                        WHERE   q.QueueMasterId = @QueueMasterId
                               -- AND ( qi.RowStatus = 'SUCCESS'
                               --       OR qi.ExternalItemCd IS NULL
                               --     )
                                AND TableNm IN ( 'item' )
                                AND ClassCd = @ClassCd;
            END;                        


        IF NOT EXISTS ( SELECT  *
                        FROM    #valid_chars )
            BEGIN
                UPDATE  q
                SET     q.RowStatus = 'FAILED' ,
                        q.RowErrors = 'Item Detail errors found: Skipping Chars validation.'
                FROM    BulkImport.QueueItemAttributes q
                WHERE   q.QueueMasterId = @QueueMasterId;

                RETURN;
				
            END;

		-- dont do validation on this
        DELETE  #valid_chars
        WHERE   AttributeDsc IN ( 'CLASS/TEMPLATE');
		
		SELECT * FROM         
        #valid_chars c
        WHERE   c.ExternalItemCd IS NULL;

		UPDATE  c
        SET     c.ErrorMessage = ' Row ID not found.'
        FROM    #valid_chars c
        WHERE   c.ExternalItemCd IS NULL;

/* fail rows with no Att Idn*/
        UPDATE  #valid_chars
        SET     ErrorMessage = AttributeDsc + ' Characteristic not found.'
        FROM    #valid_chars
        WHERE   AttributeId IS NULL; 

/* fail rows with no Item code in details*/			
        UPDATE  c
        SET     c.ErrorMessage = c.ExternalItemCd + ' Row ID not found.'
        FROM    #valid_chars c
        WHERE   c.ExternalItemCd NOT IN (
                SELECT  ExternalItemCd
                FROM    BulkImport.QueueItem
                WHERE   QueueMasterId = @QueueMasterId );


/* move the code to update AttributeId up so that we can use here */
-- save all ATT IDNs
        UPDATE  q
        SET     q.AttributeId = v.AttributeId
        FROM    BulkImport.QueueItemAttributes q
                JOIN #valid_chars v ON v.RowId = q.AttributeRowId
        WHERE   q.QueueMasterId = @QueueMasterId;		

/* duplicate Prev_ref_id found in same file */
	 DECLARE @ExtId INT;
	 SELECT  @ExtId = AttributeId
			FROM    ItemBom.ItemAttribute
			WHERE   AttributeNm = 'PREV_REF_ID';  

	 WITH cteDuplicatePrevRefIDAttr AS
				(SELECT AttributeId,[AttributeDsc], [ItemAttributeValue]
				 FROM [BulkImport].[QueueItemAttributes] 
				 WHERE QueueMasterId=@QueueMasterId AND AttributeId = @ExtId
				 GROUP BY AttributeId,[AttributeDsc], [ItemAttributeValue]
				 HAVING COUNT([ItemAttributeValue]) >1
				 )

		UPDATE  c
        SET     ErrorMessage = 'PREVIOUS REFERENCE ID::' + c.ItemAttributeValue + ' value found multiple times in same file '
        FROM	 #valid_chars c					 
				JOIN cteDuplicatePrevRefIDAttr cte ON cte.AttributeId=c.AttributeId AND cte.[ItemAttributeValue] = c.[ItemAttributeValue]
/* END check Prev_ref_id found in same file */ 



        INSERT  BulkImport.QueueItem
                ( QueueMasterId ,
                  ExternalItemCd ,
                  RowStatus ,
                  RowErrors           
				)
                SELECT DISTINCT
                        @QueueMasterId ,
                        c.ExternalItemCd ,
                        'FAILED' ,
                        'Item detail missing. Only Chars found.'
                FROM    #valid_chars c
                WHERE   ErrorMessage LIKE '%Row ID not found';
				
-- get required values
        UPDATE  #valid_chars
        SET     ErrorMessage = AttributeDsc + ' Value is required.'
		--SELECT * FROM #valid_chars
        WHERE   RequiredInd IN ( 'true', 'Y' )
                AND ISNULL(ItemAttributeValue, '') = '';

-- numeric values f
        UPDATE  #valid_chars
        SET     ErrorMessage = AttributeDsc + ' Numeric value expected.'	
        WHERE   DataType IN ( 'N', 'int' )
                AND ISNUMERIC(ItemAttributeValue) = 0		
                AND ItemAttributeValue IS NOT NULL;
                
-- range
        IF EXISTS ( SELECT  c.ItemAttributeValue
                    FROM    #valid_chars c
                            JOIN ItemBom.ItemAttributeValidRange vv ON vv.AttributeId = c.AttributeId )
		BEGIN TRY
			UPDATE  c
			SET     ErrorMessage = AttributeDsc + ' Value out of range.'
						--SELECT c.*
			FROM    #valid_chars c
					JOIN ItemBom.ItemAttributeValidRange vv ON vv.AttributeId = c.AttributeId
			WHERE   DataType IN ( 'N', 'int' )
					--AND RestrictToValidList = 'Y'
					AND ( CAST(c.ItemAttributeValue AS FLOAT) < vv.MinValueNbr
						  OR CAST(c.ItemAttributeValue AS FLOAT) > vv.MaxValueNbr
						);
		END TRY
		BEGIN CATCH
			UPDATE  c
			SET     ErrorMessage = AttributeDsc + ' Expected numeric values only.'
			FROM    #valid_chars c
					JOIN ItemBom.ItemAttributeValidRange vv ON vv.AttributeId = c.AttributeId
			WHERE   DataType IN ( 'N', 'int' )
					--AND RestrictToValidList = 'Y'
					AND ISNUMERIC(ItemAttributeValue) = 0;	
		END CATCH;

--- add date validation
			--	AND DataType IN ( 'D', 'xxx' )


-- validation list 	  			
        UPDATE  c
        SET     ErrorMessage = AttributeDsc + ' Invalid value.'
		--SELECT * 
        FROM    #valid_chars c
                LEFT JOIN ItemBom.ItemAttributeValidValue vv ON vv.AttributeId = c.AttributeId
                                                              AND UPPER(RTRIM(c.ItemAttributeValue)) = UPPER(RTRIM(vv.ValueDsc))
        WHERE   c.RestrictToValidList = 'Y' AND c.RestrictToValidValuesInd = 'Y'
                AND vv.ValueTxt IS NULL
				AND DataType IN ( 'T', 'N','varchar' )
                AND c.ItemAttributeValue IS NOT NULL;



--- PRODUCT_LINE for RAPP
        IF @MaterialType IN ('RAPP', 'UNBW') and @IaoActiveInd <> 'Y'
            BEGIN
                DECLARE @val_txt NVARCHAR(255) ,
                    @att_idn INT ,
                    @vldt_rslt NVARCHAR(MAX) ,
                    @url VARCHAR(255);

                SELECT  @att_idn = att_idn
                FROM    #sap_req
                WHERE   att_nme = 'PRODUCT_LINE';

                EXEC speed.[dbo].[prc_cnctbx_get_base_url] @url OUTPUT;

                SELECT  @val_txt = MIN(ItemAttributeValue)
                FROM    #valid_chars
                WHERE   ItemAttributeValue IS NOT NULL
                        AND AttributeId = @att_idn;
	  

                SET @vldt_rslt = 'TRUE';
                WHILE @val_txt IS NOT NULL
                    BEGIN
                        EXEC speed.dbo.prc_mrpm_clr_ValidateProductLine @svc_url_base = @url,
                            @val_txt = @val_txt,
                            @vldt_rslt = @vldt_rslt OUTPUT;

                        IF @vldt_rslt != 'TRUE'
                            BEGIN
                                IF @vldt_rslt = 'FALSE'
                                    BEGIN

                                        UPDATE  c
                                        SET     ErrorMessage = @val_txt
                                                + ' Invalid Product Line.'
                                        FROM    #valid_chars c
                                        WHERE   AttributeId = @att_idn
                                                AND ItemAttributeValue = @val_txt;
                                    END;
                                ELSE
                                    BEGIN

                                        UPDATE  c
                                        SET     ErrorMessage = 'SAP call failed for Product Line validation'
                                        FROM    #valid_chars c
                                        WHERE   AttributeId = @att_idn
                                                AND ItemAttributeValue = @val_txt;

                                    END;
                            END;
		
                        IF @vldt_rslt IN ( 'TRUE', 'FALSE' )
                            BEGIN
                                SELECT  @val_txt = MIN(ItemAttributeValue)
                                FROM    #valid_chars
                                WHERE   ItemAttributeValue IS NOT NULL
                                        AND ItemAttributeValue > @val_txt
                                        AND AttributeId = @att_idn
                                        AND ErrorMessage IS NULL;
		
                            END;
                        ELSE
                            BEGIN
                                SELECT  @val_txt = NULL;
                            END;
                    END;
------------ product_line ends

/** EPM_ID validation **/
	
	--     SELECT  @att_idn = att_idn
 --               FROM    #sap_req
 --               WHERE   att_nme = 'EPM_ID';

	--UPDATE sap
	--SET sap.val_txt = CONVERT(VARCHAR, vldt.elem_id)
	--             FROM    #valid_chars AS sap

	--	JOIN speed.dbo.vcblry_src_elem AS vldt
	--  ON CONVERT(VARCHAR, vldt.elem_id) = RTRIM(sap.ItemAttributeValue)
	-- AND vldt.inactv_ind = 'N'
	-- AND vldt.type_cd <> 'PROD-PH'
	--WHERE sap.AttributeId = @att_idn


	

            END;
			------ rapp ENDS





        IF @debug = 1
            SELECT  *
            FROM    #valid_chars;

-- return bad records
        UPDATE  q
        SET     q.RowStatus = 'FAILED' ,
                q.RowErrors = v.ErrorMessage
        FROM    BulkImport.QueueItemAttributes q
                JOIN #valid_chars v ON v.RowId = q.AttributeRowId
        WHERE   q.QueueMasterId = @QueueMasterId
                AND v.ErrorMessage IS NOT NULL;

-- mark good records
        UPDATE  q
        SET     q.RowStatus = 'SUCCESS'
        FROM    BulkImport.QueueItemAttributes q
                JOIN #valid_chars v ON v.RowId = q.AttributeRowId
        WHERE   q.QueueMasterId = @QueueMasterId
                AND q.RowErrors IS NULL
                AND v.ItemAttributeValue IS NOT NULL;

-- fail item record
        UPDATE  i
        SET     i.RowStatus = 'FAILED' ,
                i.RowErrors = ISNULL(i.RowErrors, '')
                + ' SAP Char errors found'
        FROM    BulkImport.QueueItem i
                JOIN BulkImport.QueueItemAttributes att ON i.QueueMasterId = att.QueueMasterId
                                                           AND i.ExternalItemCd = att.ExternalItemCd
        WHERE   i.QueueMasterId = @QueueMasterId
                AND att.RowStatus = 'FAILED';



	
    END;


GO