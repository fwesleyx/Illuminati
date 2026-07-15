USE [speed_2max]
GO

DROP PROCEDURE IF EXISTS [BulkImport].[ItemBomExtensionGet]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [BulkImport].[ItemBomExtensionGet](
	@current_idn INT,  
	@wwid NCHAR(8)= NULL, 
	@ext_typ CHAR(1) = 'I', /*'I/E' (internal or external)*/
	@ItemOrBom CHAR(1) = 'I',  /*'I/B' (Item extend = I, Bom extend = B) */
	@tran_id VARCHAR(50)=0 OUTPUT,
	@debug INT=0
) 
AS	/************************************************************/   
	/* handshake with sap for itembom extension*/  
	-- @QueueMasterId = unique identifier for uploaded file 
	-- @debug = enable/disable debugging
	-- Called by speed_2max.[BulkImport].[ItemBomExtensionProcess]
	-- 2/13/2026   WNG5   IAO Add PlantId
	/************************************************************/
BEGIN
	/**SET NOCOUNT ON added to prevent extra result sets from
	interfering with SELECT statements.****/
	SET NOCOUNT ON;

	--DECLARE @current_idn INT;
	DECLARE @Debug INT;
	DECLARE @internal_flg CHAR(1);
    DECLARE @XmlDocMaster AS VARCHAR(MAX);             
    DECLARE @eco_nbr VARCHAR(12);            
    DECLARE @save_flg AS BIT;
	DECLARE @qty INT = 0;
	DECLARE @parentCd varchar(8);
	DECLARE @tran_status VARCHAR(50);
	DECLARE @tran_Error VARCHAR(50);
	DECLARE @idsid CHAR(8);
	DECLARE @usr_acct CHAR(8); 
	  

	SET @internal_flg= 'Y';
	
	/**table to hold each bom parent item's extend data****/
	CREATE TABLE #bom_extend_data
    (
        [<TABLENAME>BomTree</TABLENAME>] NVARCHAR(1) ,
        child_item VARCHAR(25) ,
        sort_order VARCHAR(53) ,
        [row] INT ,
        parent_row INT ,
        bom_level INT ,
        has_child INT ,
        bom_find_nbr INT ,
        item_cde VARCHAR(300) , -- href added for fert
        item_typ_cde NVARCHAR(4) ,
        item_rev VARCHAR(2) ,
        parent_item_cde VARCHAR(25) ,
        parent_item_rev VARCHAR(2) ,
        item_extend_status CHAR(10) ,
        item_extend_mrp_area VARCHAR(25) ,
        show_item_extend_status VARCHAR(10) ,
        bom_extend_status VARCHAR(10) ,
        show_bom_extend_status VARCHAR(10) ,
        item_desc NVARCHAR(255) ,
        comdt_cde NVARCHAR(15) ,
        quantity INT ,
        uom VARCHAR(6) ,
        bom_typ VARCHAR(30)	,
        item_status VARCHAR(20) ,
        material_typ VARCHAR(12) ,
        speed_mbp VARCHAR(12) ,
        [subQueryItemExtensionByDate.proc_typ_idn] INT ,
        proc_typ_idn INT ,
        proc_typ_desc NVARCHAR(10) ,
        ref_material VARCHAR(25) ,
        ver_ctl_ent NVARCHAR(25) ,
        alt_idn VARCHAR(3) ,
        error VARCHAR(60) ,
        visible BIT ,
        margin INT ,
        showExpansion INT ,
        allowEdit INT ,
        allowProcTypeEdit INT ,
        isparent INT ,
        bom_idn INT ,
        matp_ind NCHAR(1) ,
        ibdm_bom_grouping NVARCHAR(25)
    );
	CREATE TABLE #bom_extend_eco ( eco_nbr VARCHAR(12) );
	
	IF(@debug = 1)
	BEGIN
		SELECT * FROM    #itemtbl 
        WHERE   seq_id = CAST(@current_idn AS int);
	END	

	IF(@wwid IS NOT NULL) 
	BEGIN
			SELECT  @usr_acct = usr_acct, 
					@idsid = idsid  
			FROM users 
			WHERE wwid = @wwid	
	END
	ELSE
	BEGIN
			SELECT  @usr_acct = usr_acct, 
					@idsid = idsid  
			FROM users 
			WHERE usr_acct = 'SYSTEM'
	END
	
	/**  PREPARE FOR THE GET ****/
    SELECT  @XmlDocMaster = '' + '<ROOT>' + '<item_cde>' + parent_item_cde + '</item_cde>' + '<item_rev>' + parent_item_rev + '</item_rev>'                        
		    + CASE WHEN mrp_area IS NULL THEN '<mrp_area />' ELSE '<mrp_area>' + ISNULL(mrp_area, '') + '</mrp_area>' END
		    + CASE WHEN ecc_plnt_cde IS NULL THEN '<ecc_plnt_cde />' ELSE '<ecc_plnt_cde>' + ISNULL(ecc_plnt_cde, '') + '</ecc_plnt_cde>' END
			+ '<PlantId>' + ISNULL(PlantId, '') + '</PlantId>' 
            + '<ext_typ>' + ext_type + '</ext_typ>'
            + '<vendor_idn /><mrp_area_is_optional>Y</mrp_area_is_optional>'    
			+ '<idsid>'+ @idsid +'</idsid>'                                                           
            + '</ROOT>'
    FROM    #itemtbl 
    WHERE   seq_id = CAST(@current_idn AS int);

	/**  populate temp table with rules get results ****/
    EXEC [speed].dbo.prc_pdm_item_bom_extend_master @actn = 'GET', @XmlDoc = @XmlDocMaster , @debug= @debug

	IF(@debug = 1)
		BEGIN		
				SELECT '#bom_extend_data'
				SELECT * FROM #bom_extend_data;	
		END

	PRINT 'GET'
		
	-- only send the ones in Error or not sent
	IF  @ItemOrBom = 'I' 
	BEGIN
		SELECT @qty = COUNT(*) FROM #bom_extend_data
		WHERE (item_extend_status IS NULL) 				
		AND visible = 1
		
		--update temp to track item extension
		UPDATE #itemtbl SET item_ext = 1 
		WHERE seq_id = @current_idn

	END
			
	IF  @ItemOrBom = 'B' 
	BEGIN
		SELECT @qty = COUNT(*) 
		FROM #bom_extend_data
		WHERE (item_extend_status = 'S') 				
		AND visible = 1
		
		--update temp to track item extension
		UPDATE #itemtbl SET bom_ext = 1 
		WHERE seq_id = @current_idn

	END	
	
	/****If *****/
	IF (@qty > 0 AND @ItemOrBom = 'I') or (@qty > 1 AND @ItemOrBom = 'B')
	BEGIN

		/**  PREPARE THE HEADER FOR THE SAVE ****/
		SELECT  @XmlDocMaster = '' + '<ROOT><master><spd_tran_id /><edm_group_id />'                        
            + '<parent_item_cde>' + parent_item_cde + '</parent_item_cde>' 
			+ '<parent_item_rev>' + parent_item_rev + '</parent_item_rev>' 
			+ '<ecc_plnt_cde>' + ISNULL(it.ecc_plnt_cde, '') + '</ecc_plnt_cde>'
			+ '<PlantId>' + PlantId + '</PlantId>'
            + CASE WHEN mrp_area IS NULL THEN '<mrp_area />' ELSE '<mrp_area>' + ISNULL(mrp_area, '') + '</mrp_area>' END 
			+ '<eco_nbr>' + ISNULL(RTRIM(@eco_nbr),'0') + '</eco_nbr>'                        						
			+ CASE WHEN @ItemOrBom = 'I' THEN '<bom_eff_dt/>' ELSE '<bom_eff_dt>' + CONVERT(VARCHAR(10), GETDATE() ,101)+ '</bom_eff_dt><bom_usage_typ>1</bom_usage_typ>' END
            + '<ext_typ>'+ @ItemOrBom + '</ext_typ>' 	
			+ '<qty>' + CAST(@qty AS VARCHAR) + '</qty><internal_flg>' + @internal_flg + '</internal_flg>'				
            + '</master><detailRpt>'                       
		FROM    #itemtbl AS it
		WHERE   it.seq_id = CAST(@current_idn AS int);
    
		/**Item DETAILS extend xml**/
		IF  @ItemOrBom = 'I' BEGIN			
			SELECT  @XmlDocMaster = @XmlDocMaster +                        
					+ '<ROW parent_item_cde="' + ISNULL(parent_item_cde, '') + '" '
					+ 'parent_item_rev="' + ISNULL(parent_item_rev,'') + '" '
					+ 'child_item_cde="' + ISNULL(child_item, '') + '" '
					+ 'child_item_rev="' + ISNULL(item_rev, '') + '" '
					+ 'bom_lvl_nbr="'   + CAST(bom_level AS VARCHAR) + '" ' 
					+ 'ref_material="' + ISNULL(ref_material, '') + '" ' 
					+ 'proc_typ_idn="' + CAST(ISNULL(proc_typ_idn, '')  AS VARCHAR) + '" ' + ' />'                        
			FROM    #bom_extend_data
			WHERE ISNULL(item_extend_status,'') NOT IN ('I','S') AND				
				visible = 1				
			ORDER BY sort_order;
			PRINT 'Preparing for Item Save'
		END
	
		IF(@debug = 1)
			BEGIN		
				SELECT '#bom_extend_data'
				SELECT * FROM #bom_extend_data;
				SELECT @XmlDocMaster AS XmlDocMasterHeader
		END

		SELECT parent_item_cde,parent_item_rev, child_item, item_rev, bom_level, ref_material, proc_typ_idn                      
		FROM    #bom_extend_data
		WHERE ISNULL(item_extend_status,'') NOT IN ('I','S') AND				
			   visible = 1				 
				 
		/**BOM DETAILS extend xml**/
		IF  @ItemOrBom = 'B' BEGIN					
			SELECT  @XmlDocMaster = @XmlDocMaster
				+ ( SELECT  ISNULL(CAST([row]-1 AS VARCHAR), '') AS "@id" ,
							CASE  WHEN [row] = 1 THEN RTRIM(ISNULL(@eco_nbr, 0))
								ELSE ISNULL(parent_item_cde, '') 
							END AS "@parent_item_cde" ,
							ISNULL(parent_item_rev, '') AS "@parent_item_rev" ,
							ISNULL(child_item, '') AS "@child_item_cde" ,
							ISNULL(item_rev, '') AS "@child_item_rev" ,
							ISNULL(CAST(bom_level AS VARCHAR), '') AS "@bom_lvl_nbr" ,                                    
							CASE  WHEN [row] = 1 THEN 0
								ELSE ISNULL(CAST(bom_idn AS VARCHAR), '') 
							END AS "@bom_idn" ,
							ISNULL(CAST(proc_typ_idn AS VARCHAR), '') AS "@proc_typ_idn" ,
							CASE  WHEN [row] = 1 THEN 1
								ELSE ISNULL(CAST(quantity AS VARCHAR), '') 
							END AS "@bom_qty" ,  									
							CASE  WHEN parent_row = 1 THEN parent_row
								ELSE ISNULL(CAST(parent_row-1 AS VARCHAR), '') 
							END AS "@parent_id"
					FROM    #bom_extend_data d
					WHERE   ( ISNULL(item_extend_status,'') = 'S' )
							AND visible = 1
							AND (quantity > 0 OR parent_item_cde IS NULL )
					ORDER BY sort_order
					FOR
					XML PATH('ROW')
					)
			PRINT 'Preparing for BOM Save'
		END

		SELECT  @XmlDocMaster = @XmlDocMaster + '</detailRpt>'
				+ '<misc>' + '<usr_acct>' + @usr_acct+ '</usr_acct>' + '</misc>'    --@usr_acct                 
				+ '<idsid>'+ @idsid+'</idsid></ROOT>'  -- use my idsid becuase need mod_cde 200 to extend

		IF(@debug = 1)
		BEGIN
			SELECT @qty AS qty;
			SELECT @XmlDocMaster AS XmlDocMasterSave

			INSERT speed.dbo.capture_parms ( parms )
			VALUES  ( @XmlDocMaster )

		END
				
		
			
			
		/*Process extension*/
		EXEC [speed].dbo.prc_pdm_item_bom_extend_master @actn = 'SAVE', @XmlDoc = @XmlDocMaster, @tran_id=@tran_id OUTPUT;						
            
			/*Get transaction status and transaction error from master table*/   
		SET @tran_status = (SELECT status FROM dbo.sap_item_bom_extend_request_master WHERE spd_tran_id = ISNULL(@tran_id, 0))
		SET @tran_Error = (SELECT comments FROM dbo.sap_item_bom_extend_request_master WHERE spd_tran_id = @tran_id)

		/*Reset the success msg*/
		IF(@tran_status = 'FAILED' AND @tran_Error IS NULL) AND @ItemOrBom  = 'I'
			SET @tran_Error = 'ITEM EXT FAILED, CHECK EXT QUEUE REPORT.'
		IF(@tran_status = 'FAILED' AND @tran_Error IS NULL) AND @ItemOrBom  = 'B'
			SET @tran_Error = 'BOM EXT FAILED. ITEM EXTEND OK, CHECK EXT QUEUE REPORT.'
		IF(@tran_status = 'SUCCESS' AND @tran_Error IS NULL) AND @ItemOrBom  = 'I'
			SET @tran_Error = 'ITEM EXT SUCCESSFUL.'
		IF(@tran_status = 'SUCCESS' AND @tran_Error IS NULL) AND @ItemOrBom  = 'B'
			SET @tran_Error = 'ITEM/BOM EXTENSION SUCCESSFUL.'

		/*Added to update the queue in Asynchronously*/
		IF(@ItemOrBom = 'I')
			BEGIN
				UPDATE BulkImport.QueueItemBomExtension
				SET RowStatus = @tran_status, 
					RowErrors = @tran_Error,
					spd_tran_id = @tran_id, 
					qty = @qty, 
					IsItemExtensionProcessed = 1
				WHERE   QueueMasterId = (SELECT QueueMasterId FROM #itemtbl WHERE seq_id = @current_idn)
				AND		RowId = (SELECT RowId FROM #itemtbl WHERE seq_id = @current_idn)
			END
		
		IF(@ItemOrBom = 'B')
			BEGIN
				UPDATE BulkImport.QueueItemBomExtension
				SET RowStatus = @tran_status, 
					RowErrors = @tran_Error,
					spd_tran_id = @tran_id, 
					qty = @qty, 
					IsBomExtensionProcessed = 1
				WHERE   QueueMasterId = (SELECT QueueMasterId FROM #itemtbl WHERE seq_id = @current_idn)
				AND		RowId = (SELECT RowId FROM #itemtbl WHERE seq_id = @current_idn)
			END
			
		/** Update status **/
		UPDATE #itemtbl 
		SET IsProcessed = 1, spd_tran_id = @tran_id, tran_status = @tran_status, tran_error =  @tran_Error, qty = @qty  
		WHERE seq_id = @current_idn;

		END
	ELSE
		BEGIN
			
			IF @ItemOrBom = 'I' 
				SET @tran_Error = 'ITEM ALREADY EXTENDED OR NO ITEMS TO EXTEND.'

			IF @ItemOrBom = 'B' 
				SET @tran_Error = 'ITEM EXTENSION SUCCESSFUL,NO BOM TO EXTEND.'
			 
			/** update status as SUCCESS but No extension needed**/
			UPDATE #itemtbl 
			SET IsProcessed = 1, qty = @qty, 
				tran_status = 'NO EXTENSION',
				tran_error =  @tran_Error
			WHERE seq_id = @current_idn
			
			IF(@ItemOrBom = 'I')
			BEGIN
				UPDATE BulkImport.QueueItemBomExtension 
				SET RowStatus = 'SUCCESS',	
				qty = @qty, 
				RowErrors = @tran_Error, 
				IsItemExtensionProcessed = 1
				WHERE   QueueMasterId = (SELECT QueueMasterId FROM #itemtbl WHERE seq_id = @current_idn)
					AND		RowId = (SELECT RowId FROM #itemtbl WHERE seq_id = @current_idn)
			END
			IF(@ItemOrBom = 'B')
			BEGIN
				UPDATE BulkImport.QueueItemBomExtension 
				SET RowStatus = 'SUCCESS',
				qty = @qty,	
				RowErrors = @tran_Error, 
				IsBomExtensionProcessed = 1 
				WHERE   QueueMasterId = (SELECT QueueMasterId FROM #itemtbl WHERE seq_id = @current_idn)
					AND		RowId = (SELECT RowId FROM #itemtbl WHERE seq_id = @current_idn)
			END
		END
 
END
GO

GRANT EXECUTE ON [BulkImport].[ItemBomExtensionGet] TO [AppPool5] AS [dbo]
GO

GRANT EXECUTE ON [BulkImport].[ItemBomExtensionGet] TO [ESPEED] AS [dbo]
GO