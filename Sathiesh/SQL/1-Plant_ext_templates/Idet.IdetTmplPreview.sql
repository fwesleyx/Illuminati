USE [Pdm]
GO
/****** Object:  StoredProcedure [Idet].[IdetTmplPreview]    Script Date: 8/10/2026 10:10:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  
ALTER PROCEDURE  [Idet].[IdetTmplPreview]                             
(@save_typ  VARCHAR(30) = 'tmpl_selector'                             
,@mat_type  VARCHAR(8) = NULL                                
,@type_class VARCHAR(8) = NULL                                
,@bus_unit_idn VARCHAR(2) = NULL                                
--,@idsid   VARCHAR(8) = NULL       
,@usr_acct  CHAR(8) = NULL      
,@debug   CHAR(1)  = 'N'                                
,@XmlDoc  XML   = NULL            
,@lvl_idn VARCHAR(10)=null       
      
) AS         
      
/******************************************************************************                                
*** Purpose: item create template selection                                
*** History: 02/31/07 JP Created                                
*** smwoodwo 02/26/08 altered to work with Excel Live                                
*** jhoskins 11/25/08 Excel Live Merge        
*** raviarav 14/04/25 Add IAO        
*** Copyright 2007 - 2008 Intel Corporation, all rights reserved.                                
******************************************************************************/       
      
BEGIN                                
 SET NOCOUNT ON                                
 DECLARE  @idoc      INT                                
  , @run_wiz     CHAR(1)                                
  , @tgt_flg     CHAR(1)                                
  , @tgt_mat_typ    VARCHAR(4)                                
  , @tgt_lvl_idn    CHAR(1)                                
  , @tgt_type_class   VARCHAR(8)                                
  , @tgt_bus_unit_idn   VARCHAR(8)                                
  , @tgt_dtl_tmpl_idn   INT                                
  , @tgt_sap_tmpl_idn   INT                                
  , @tgt_plnt_tmpl_idn  INT                                
  , @tgt_sls_tmpl_idn   INT                                
  , @tgt_plnt_ext_tmpl_idn INT                                
  , @tgt_sls_ext_tmpl_idn  INT                                  
  , @max_tmpl_ct    INT                                
  ,@IaoActiveInd VARCHAR(1) -- For IAO ActiveInd                              
    DECLARE       
 @dtl_tmpl_idn  INT                                   
,@dtl_tmpl_ct  INT                                   
,@sap_tmpl_idn  INT                                   
,@sap_tmpl_ct  INT                                   
,@plnt_tmpl_idn  INT                                   
,@plnt_tmpl_ct  INT                                   
,@sls_tmpl_idn  INT                                   
,@sls_tmpl_ct  INT                                   
,@plnt_ext_tmpl_idn INT                                   
,@plnt_ext_tmpl_ct INT                                   
,@sls_ext_tmpl_idn INT                                   
,@sls_ext_tmpl_ct INT             
 DECLARE @TmplSummary TABLE                                 
  ( max_tmpl_ct   INT DEFAULT 0                                
  , dtl_tmpl_idn   INT DEFAULT 0                                
  , detail_tmpl_idn  INT                                
  , sap_tmpl_idn   INT DEFAULT 0                                
  , plant_tmpl_idn  INT DEFAULT 0                                
  , sales_tmpl_idn  INT DEFAULT 0                                
  , plant_ext_tmpl_idn INT DEFAULT 0                                
  , sales_ext_tmpl_idn INT DEFAULT 0                                  
  , dtl_tmpl_ct   INT DEFAULT 0                                
  , sap_tmpl_ct   INT DEFAULT 0                                
  , plant_tmpl_ct   INT DEFAULT 0                                
  , sales_tmpl_ct   INT DEFAULT 0                                
  , plant_ext_tmpl_ct  INT DEFAULT 0                                
  , sales_ext_tmpl_ct  INT DEFAULT 0                                  
  , dtl_tmpl_style  VARCHAR(255) DEFAULT 'display:none;'                                
  , sap_tmpl_style  VARCHAR(255) DEFAULT 'display:none;'                                
  , plant_tmpl_style  VARCHAR(255) DEFAULT 'display:none;'                                
  , sales_tmpl_style  VARCHAR(255) DEFAULT 'display:none;'                                
 , plant_ext_tmpl_style VARCHAR(255) DEFAULT 'display:none;'                                
  , sales_ext_tmpl_style VARCHAR(255) DEFAULT 'display:none;'                       )                                
 DECLARE @tmpl_dtl TABLE                                
  ( src_idn  INT                                
  , par_ent_nme VARCHAR(255)                               
  , title   VARCHAR(255)                                
  , tmpl_idn  INT                                
  )                                
 DECLARE @tmpl_sap TABLE                                
  ( src_idn  INT                                
  , par_ent_nme VARCHAR(255)                                
  , title   VARCHAR(255)                                
  , tmpl_idn  INT                                
  , item_typ_cde VARCHAR(4)                                
  , sap_mat_typ VARCHAR(4)                                
  )                                 
 DECLARE @tmpl_plnt TABLE                                
  ( src_idn  INT                                
  , par_ent_nme VARCHAR(255)                                
  , title   VARCHAR(255)                                
  , tmpl_idn  INT                                
  , item_typ_cde VARCHAR(4)                                
  , sap_mat_typ VARCHAR(4)                                
  )                                 
 DECLARE @tmpl_sls TABLE                                
  ( src_idn  INT                                
  , par_ent_nme VARCHAR(255)                              
  , title   VARCHAR(255)                                
  , tmpl_idn  INT                                
  , item_typ_cde VARCHAR(4)                                
  , sap_mat_typ VARCHAR(4)                                
  )                                 
 DECLARE @tmpl_plnt_ext TABLE                               
  ( src_idn  INT                                
  , par_ent_nme VARCHAR(255)                                
  , title   VARCHAR(255)                                
  , tmpl_idn  INT                                
  , item_typ_cde VARCHAR(4)                                
  , sap_mat_typ VARCHAR(4)                                
  )                               
 DECLARE @tmpl_sls_ext TABLE                                
  ( src_idn  INT                                
  , par_ent_nme VARCHAR(255)                                
  , title   VARCHAR(255)                                
  , tmpl_idn  INT                                
  , item_typ_cde VARCHAR(4)                                
  , sap_mat_typ VARCHAR(4)                                
  )                                
                                  
 CREATE TABLE #tmpl_scty (bus_unit_idn VARCHAR(2))                               
                           
                         
/******************************************************************************                                
*** load control values from common XML Document **/                                
 IF @XmlDoc IS NOT NULL                                
 BEGIN                                                              
                                
  IF @tgt_flg = 'Y' OR @run_wiz = 'Y'                                 
  BEGIN                                
   SELECT @lvl_idn   = @tgt_lvl_idn                                
    , @mat_type   = @tgt_mat_typ                                
    , @type_class  = @tgt_type_class                                
    , @lvl_idn   = @tgt_lvl_idn                                
    , @bus_unit_idn  = @tgt_bus_unit_idn                                
    , @dtl_tmpl_idn  = @tgt_dtl_tmpl_idn                                
    , @sap_tmpl_idn  = @tgt_sap_tmpl_idn                                
    , @plnt_tmpl_idn = @tgt_plnt_tmpl_idn                                
    , @sls_tmpl_idn  = @tgt_sls_tmpl_idn           
    , @plnt_ext_tmpl_idn= @tgt_plnt_ext_tmpl_idn                                
    , @sls_ext_tmpl_idn = @tgt_sls_ext_tmpl_idn                                
  END                                
 END                                
                                
/******************************************************                                
*** set control value defaults **/                                  
 SELECT @mat_type   = ISNULL(@mat_type    , '')                                
  ,@type_class   = ISNULL(@type_class   , '')                                
  ,@bus_unit_idn   = ISNULL(@bus_unit_idn   , '')                                
  ,@lvl_idn    = ISNULL(@lvl_idn    , '')                                
  ,@dtl_tmpl_idn   = ISNULL(@dtl_tmpl_idn   ,  0)                                
  ,@sap_tmpl_idn   = ISNULL(@sap_tmpl_idn   ,  0)                                                                                
  ,@plnt_tmpl_idn   = ISNULL(@plnt_tmpl_idn   ,  0)                                                                                  
  ,@sls_tmpl_idn   = ISNULL(@sls_tmpl_idn   ,  0)                                  
  ,@plnt_ext_tmpl_idn = ISNULL(@plnt_ext_tmpl_idn  ,  0)                                                                                  
  ,@sls_ext_tmpl_idn  = ISNULL(@sls_ext_tmpl_idn  ,  0)                                    
  ,@run_wiz    = ISNULL(@run_wiz    ,'N')                                  
  ,@tgt_flg    = ISNULL(@tgt_flg    ,'N')                                  
  ,@tgt_mat_typ   = ISNULL(@tgt_mat_typ   , '')                                 
  ,@tgt_type_class  = ISNULL(@tgt_type_class  , '')                                
  ,@tgt_bus_unit_idn  = ISNULL(@tgt_bus_unit_idn  , '')                                
  ,@tgt_dtl_tmpl_idn  = ISNULL(@tgt_dtl_tmpl_idn  ,  0)                                
  ,@tgt_sap_tmpl_idn  = ISNULL(@tgt_sap_tmpl_idn  ,  0)                                
  ,@tgt_plnt_tmpl_idn  = ISNULL(@tgt_plnt_tmpl_idn  ,  0)                                
  ,@tgt_sls_tmpl_idn  = ISNULL(@tgt_sls_tmpl_idn  ,  0)                        
  ,@tgt_plnt_ext_tmpl_idn = ISNULL(@tgt_plnt_ext_tmpl_idn ,  0)                                
  ,@tgt_sls_ext_tmpl_idn = ISNULL(@tgt_sls_ext_tmpl_idn ,  0)                                  
  ,@dtl_tmpl_idn   = ISNULL(@tgt_dtl_tmpl_idn  ,  0)                                  
  ,@sap_tmpl_idn   = ISNULL(@tgt_sap_tmpl_idn  ,  0)                                
  ,@plnt_tmpl_idn   = ISNULL(@tgt_plnt_tmpl_idn  ,  0)                                
  ,@sls_tmpl_idn   = ISNULL(@tgt_sls_tmpl_idn  ,  0)                            
  ,@plnt_ext_tmpl_idn  = ISNULL(@tgt_plnt_ext_tmpl_idn ,  0)                                
  ,@sls_ext_tmpl_idn  = ISNULL(@tgt_sls_ext_tmpl_idn ,  0)                                   
                                
/******************************************************                                
*** setup template role security **/                                  
 EXEC [Idet].[Idettmplscty]                                
   @save_typ = @save_typ                                
  ,@mdul_idn = NULL                                
  ,@mat_type = @mat_type                         
  ,@lvl_idn = @lvl_idn                                
  --,@idsid  = @idsid                                
  ,@debug  = @debug       
 ,@usr_acct=@usr_acct                     
 DELETE FROM #tmpl_scty WHERE bus_unit_idn != @bus_unit_idn                                
                                
/**************************************************************************************************                                
*** get templates valid for the current material type/class/design group/user rights combination**/                                  
 INSERT INTO @tmpl_dtl(tmpl_idn, par_ent_nme, title, src_idn)                                
  SELECT tt.tmpl_idn                                
   ,te.ent_nme     
   ,tt.title                                
   ,te.src_idn as src_idn                                
  FROM speed.dbo.entity te                                 
  JOIN speed.dbo.template tt  ON te.ent_idn  = tt.parent_ent_idn                                
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                                
  JOIN speed.dbo.entity_related ter ON ter.child_ent_idn= te.ent_idn                                 
  WHERE tt.actv_ind = 'Y'   --a template that is active                                
    AND tt.admin_ind = 'N'                               
    AND (te.src_idn = 1 AND te.ent_nme IN ('Detail'))                                
  ORDER BY te.src_idn, upper(tt.title)                                
                                
 SELECT @dtl_tmpl_ct = @@rowcount                                
 SELECT @max_tmpl_ct = @dtl_tmpl_ct                                
                                
 INSERT INTO @tmpl_sap(tmpl_idn, par_ent_nme, title, src_idn, item_typ_cde, sap_mat_typ)                                
  SELECT tt.tmpl_idn              
   ,te.ent_nme                                
   ,tt.title                                
   ,te.src_idn as src_idn                                
   ,tmc.item_typ_cde                                
   ,tmc.sap_mat_typ                                
  FROM speed.dbo.entity te                                 
  JOIN speed.dbo.template tt     ON te.ent_idn  = tt.parent_ent_idn                                
  JOIN #tmpl_scty ts     ON tt.bus_unit_idn = ts.bus_unit_idn                                
  JOIN speed.dbo.entity_related ter    ON ter.child_ent_idn= te.ent_idn                                 
  JOIN speed.dbo.template_material_class tmc ON tmc.tmpl_idn  = tt.tmpl_idn                                
             AND tmc.sap_mat_typ = @mat_type                                 
             AND tmc.item_typ_cde = @type_class                                
  WHERE tt.actv_ind = 'Y'      --a template that is active                                
    AND tt.admin_ind = 'N'                                
    AND te.src_idn = 2       --and it's an SAP template                                
  ORDER BY te.src_idn, UPPER(tt.title)                                
                                
 SELECT @sap_tmpl_ct = @@rowcount                                 
 SELECT @max_tmpl_ct = CASE WHEN @sap_tmpl_ct > @max_tmpl_ct then @sap_tmpl_ct else @max_tmpl_ct end                                
                                
 IF @mat_type IN('FERT','INTG','KITS','DIEN')                                 
 BEGIN                                
  INSERT INTO @tmpl_plnt(tmpl_idn, par_ent_nme, title, src_idn)                                
  SELECT tt.tmpl_idn                                
   ,te.ent_nme                                
   ,tt.title                                
   ,te.src_idn as src_idn                                
  FROM speed.dbo.entity te                                 
  JOIN speed.dbo.template tt  ON te.ent_idn  = tt.parent_ent_idn                                
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                                
  JOIN speed.dbo.entity_related ter ON ter.child_ent_idn= te.ent_idn                                 
  WHERE tt.actv_ind = 'Y'      --a template that is active                                
    AND tt.admin_ind = 'N'                                
    AND te.src_idn ='1'                                
    AND te.ent_nme ='Plant'                                
  ORDER BY te.src_idn, upper(tt.title)                                
                                  
  SELECT @plnt_tmpl_ct = @@rowcount                                 
  SELECT @max_tmpl_ct = CASE WHEN @plnt_tmpl_ct > @max_tmpl_ct THEN @plnt_tmpl_ct ELSE @max_tmpl_ct END                                
                                  
  INSERT INTO @tmpl_sls(tmpl_idn, par_ent_nme, title, src_idn)                                
  SELECT tt.tmpl_idn                                
   ,te.ent_nme                                
   ,tt.title                                
   ,te.src_idn as src_idn                                
FROM speed.dbo.entity te                                 
  JOIN speed.dbo.template tt  ON te.ent_idn  = tt.parent_ent_idn                                
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                                
  JOIN speed.dbo.entity_related ter ON ter.child_ent_idn= te.ent_idn                                 
  WHERE tt.actv_ind = 'Y'     --a template that is active                                
    AND tt.admin_ind = 'N'                                
    AND te.src_idn = '1'                                
    AND te.ent_nme = 'Sales'                                
  ORDER BY te.src_idn, upper(tt.title)                                
       
        
  SELECT @sls_tmpl_ct = @@rowcount                                 
  SELECT @max_tmpl_ct = CASE WHEN @sls_tmpl_ct > @max_tmpl_ct THEN @sls_tmpl_ct ELSE @max_tmpl_ct END                         
      
          
  INSERT INTO @tmpl_plnt_ext(tmpl_idn, par_ent_nme, title, src_idn)                                
  SELECT tt.tmpl_idn                                
   ,te.ent_nme                                
   ,tt.title                                
   ,te.src_idn as src_idn                                
  FROM speed.dbo.entity te                                 
  JOIN speed.dbo.template tt  ON te.ent_idn  = tt.parent_ent_idn                                
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                                
  JOIN speed.dbo.entity_related ter ON ter.child_ent_idn= te.ent_idn                                 
  WHERE tt.actv_ind = 'Y'      --a template that is active                                
    AND tt.admin_ind = 'N'                                
    AND te.src_idn = '3'                                
    AND UPPER(te.ent_nme)='PLANT EXT'                                
  ORDER BY te.src_idn, upper(tt.title)                                
                                  
  SELECT @plnt_ext_tmpl_ct = @@rowcount                                    
  SELECT @max_tmpl_ct = CASE WHEN @plnt_ext_tmpl_ct > @max_tmpl_ct THEN @plnt_ext_tmpl_ct ELSE @max_tmpl_ct END                                
                                 
  INSERT INTO @tmpl_sls_ext(tmpl_idn, par_ent_nme, title, src_idn)                                
  SELECT tt.tmpl_idn                                
   ,te.ent_nme                                
   ,tt.title                                
   ,te.src_idn as src_idn                                
  FROM speed.dbo.entity te                                 
  JOIN speed.dbo.template tt  ON te.ent_idn  = tt.parent_ent_idn                                
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                                
  JOIN speed.dbo.entity_related ter ON ter.child_ent_idn= te.ent_idn                                 
  WHERE tt.actv_ind = 'Y'    --a template that is active             
    AND tt.admin_ind = 'N'                                
    AND te.src_idn ='4'                                
    AND UPPER(te.ent_nme)='SALES EXT'                                
  ORDER BY te.src_idn, upper(tt.title)                                
                          
  SELECT @sls_ext_tmpl_ct = @@rowcount                                 
  SELECT @max_tmpl_ct = CASE WHEN @sls_ext_tmpl_ct > @max_tmpl_ct THEN @sls_ext_tmpl_ct ELSE @max_tmpl_ct END                                
 END                                
                                 
/****************************************************************                                
*** update web styling according to availability of templates **/                                  
 INSERT INTO @TmplSummary (max_tmpl_ct) VALUES(@max_tmpl_ct)                          
                                
/* if no template idn was passed in, then take the top 1 from those available to pre-select */                                
 SELECT TOP 1 @dtl_tmpl_idn = tmpl_idn                                 
 FROM @tmpl_dtl                                 
 WHERE @dtl_tmpl_idn = 0                                
                                
 SELECT TOP 1 @sap_tmpl_idn = tmpl_idn                                 
 FROM @tmpl_sap                                 
 WHERE @sap_tmpl_idn = 0                                
                                
 SELECT TOP 1 @plnt_tmpl_idn = tmpl_idn                                 
 FROM @tmpl_plnt                                 
 WHERE @plnt_tmpl_idn = 0                                
                                
 SELECT TOP 1 @sls_tmpl_idn = tmpl_idn                                 
 FROM @tmpl_sls                                 
 WHERE @sls_tmpl_idn = 0                           
                                
 SELECT TOP 1 @plnt_ext_tmpl_idn = tmpl_idn                                 
 FROM @tmpl_plnt_ext                                 
 WHERE @plnt_ext_tmpl_idn = 0                                 
                                 
 SELECT TOP 1 @sls_ext_tmpl_idn = tmpl_idn                                 
 FROM @tmpl_sls_ext                                 
 WHERE @sls_ext_tmpl_idn = 0                                    
                                             
 UPDATE  @TmplSummary                                 
 SET dtl_tmpl_idn = @dtl_tmpl_idn                                
  , dtl_tmpl_ct = @dtl_tmpl_ct                                 
  , dtl_tmpl_style =                                 
  CASE                                  
   WHEN @dtl_tmpl_ct > 0 THEN 'display:inline;'                                
   ELSE 'display:none;'                                 
  END                                
 FROM  @tmpl_dtl                                                           
 UPDATE  @TmplSummary                                 
 SET sap_tmpl_idn = @sap_tmpl_idn                                
  , sap_tmpl_ct = @sap_tmpl_ct                                 
  , sap_tmpl_style =                                 
  CASE                                  
   WHEN @sap_tmpl_ct > 0 THEN 'display:inline;'                                
   ELSE 'display:none;'                                 
  END                                
 FROM  @tmpl_sap                                
                                 
                                 
 UPDATE  @TmplSummary                                 
 SET plant_tmpl_idn = @plnt_tmpl_idn                                
  , plant_tmpl_ct = @plnt_tmpl_ct                                 
  , plant_tmpl_style =                                 
  CASE                                  
   WHEN @plnt_tmpl_ct > 0 THEN 'display:inline;'                                
   ELSE 'display:none;'                                 
  END                                
 FROM  @tmpl_plnt                                
                           
                                 
 UPDATE  @TmplSummary                                 
 SET sales_tmpl_idn = @sls_tmpl_idn                         
  , sales_tmpl_ct = @sls_tmpl_ct                                 
  , sales_tmpl_style =                                 
  CASE                                  
   WHEN @sls_tmpl_ct > 0 THEN 'display:inline;'                                
   ELSE 'display:none;'                                 
  END                                
 FROM  @tmpl_sls                                
                                 
  UPDATE  @TmplSummary                                 
 SET plant_ext_tmpl_idn = @plnt_ext_tmpl_idn                                
  , plant_ext_tmpl_ct = @plnt_ext_tmpl_ct                                 
  , plant_ext_tmpl_style =                                 
  CASE                                  
   WHEN @plnt_ext_tmpl_ct > 0 THEN 'display:inline;'                      
   ELSE 'display:none;'                                 
  END    
 FROM  @tmpl_plnt_ext                                
                                
                                 
 UPDATE  @TmplSummary                                 
 SET sales_ext_tmpl_idn = @sls_ext_tmpl_idn                                
  , sales_ext_tmpl_ct = @sls_ext_tmpl_ct                                 
  , sales_ext_tmpl_style =                                 
  CASE                                  
   WHEN @sls_ext_tmpl_ct > 0 THEN 'display:inline;'                                
   ELSE 'display:none;'                                 
  END                                
 FROM  @tmpl_sls_ext                                
  IF( @save_typ  = 'tmpl_preview' )                               
  BEGIN    
 INSERT INTO #TmplSummary   
 (                            
   dtl_tmpl_idn                                                          
  , sap_tmpl_idn                              
  , plant_tmpl_idn     
  , plant_ext_tmpl_idn    
  , sales_tmpl_idn                                                         
  , sales_ext_tmpl_idn                                   
  )             
 SELECT              
  dtl_tmpl_idn                 
 ,sap_tmpl_idn                      
 ,plant_tmpl_idn                         
 ,plant_ext_tmpl_idn    
 ,sales_tmpl_idn    
 ,sales_ext_tmpl_idn         
 FROM @TmplSummary     
  END               
 IF( @save_typ  = 'tmpl_selector' )    
 BEGIN                              
   SELECT NULL AS  [<TableName>tblTmplSummary</TableName>]                                
   , ISNULL(max_tmpl_ct,0) AS max_tmpl_ct                                
   , dtl_tmpl_idn                                 
   , sap_tmpl_idn                                 
   , plant_tmpl_idn                                 
   , sales_tmpl_idn                                 
   , plant_ext_tmpl_idn                                 
   , sales_ext_tmpl_idn                                 
   , dtl_tmpl_ct                                 
   , sap_tmpl_ct                                 
   , plant_tmpl_ct                                 
   , sales_tmpl_ct                                 
   , plant_ext_tmpl_ct                                 
   , sales_ext_tmpl_ct                                   
   , dtl_tmpl_style AS [trDtlTmpl<STYLE />]          
   , sap_tmpl_style AS [trSapTmpl<STYLE />]                                
   , plant_tmpl_style AS [trPlantTmpl<STYLE />]                                
   , sales_tmpl_style AS [trSalesTmpl<STYLE />]                         
   , plant_ext_tmpl_style AS [trPlantExtTmpl<STYLE />]                                
   , sales_ext_tmpl_style AS [trSalesExtTmpl<STYLE />]                                
  FROM @TmplSummary                              
 END                               
                                                 
                                 
 /** clean-up **/                                
 DROP TABLE #tmpl_scty                                
END 
