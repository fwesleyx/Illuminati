  
CREATE PROCEDURE [dbo].[prc_idet_tmpl_preview]                          
(@save_typ  VARCHAR(30) = NULL                          
,@mat_type  VARCHAR(8) = NULL                          
,@type_class VARCHAR(8) = NULL                          
,@bus_unit_idn VARCHAR(2) = NULL                          
,@idsid   VARCHAR(8) = NULL                          
,@debug   CHAR(1)  = 'N'                          
,@XmlDoc  XML   = NULL                          
,@dtl_tmpl_idn  INT  = NULL OUTPUT                          
,@dtl_tmpl_ct  INT  = NULL OUTPUT                          
,@sap_tmpl_idn  INT  = NULL OUTPUT                          
,@sap_tmpl_ct  INT  = NULL OUTPUT                          
,@plnt_tmpl_idn  INT  = NULL OUTPUT                          
,@plnt_tmpl_ct  INT  = NULL OUTPUT                          
,@sls_tmpl_idn  INT  = NULL OUTPUT                          
,@sls_tmpl_ct  INT  = NULL OUTPUT                          
,@plnt_ext_tmpl_idn INT  = NULL OUTPUT                          
,@plnt_ext_tmpl_ct INT  = NULL OUTPUT                          
,@sls_ext_tmpl_idn INT  = NULL OUTPUT                          
,@sls_ext_tmpl_ct INT  = NULL OUTPUT                          
) AS                          
/******************************************************************************                          
*** Purpose: item create template selection                          
*** History: 02/31/07 JP Created                          
*** smwoodwo 02/26/08 altered to work with Excel Live                          
*** jhoskins 11/25/08 Excel Live Merge  
*** raviarav 14/04/25 Add IAO  
*** wng5     12/11/25 Plant Ext for Sellable HALB - IF UPI  
*** Copyright 2007 - 2008 Intel Corporation, all rights reserved.                          
******************************************************************************/                          
BEGIN                          
 SET NOCOUNT ON                          
 DECLARE @lvl_idn    VARCHAR(1)                          
  , @idoc      INT                          
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
  , sales_ext_tmpl_style VARCHAR(255) DEFAULT 'display:none;'                          )                          
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
                         
 SELECT @IaoActiveInd = ActiveInd FROM PdmFeatureFlag WHERE FeatureNm = 'IAO_ENABLED_FLAG'; /* Get IAO Flag */                        
                   
/******************************************************************************                          
*** load control values from common XML Document **/                          
 IF @XmlDoc IS NOT NULL                          
 BEGIN                          
  EXEC sp_xml_preparedocument @idoc OUTPUT, @XmlDoc                          
                          
  SELECT @mat_type = NULLIF(mat_typ  , '')                          
   ,@type_class = NULLIF(type_class  , '')                          
   ,@bus_unit_idn = NULLIF(bus_unit_idn , '')                          
   ,@lvl_idn  = NULLIF(lvl_idn  , '')                          
   ,@tgt_lvl_idn = NULLIF(tgt_lvl_idn , '')                          
  FROM OPENXML(@idoc, 'ROOT/divdetail', 2) WITH                           
   (mat_typ  VARCHAR(8)                          
   ,type_class  VARCHAR(8)                          
   ,bus_unit_idn VARCHAR(4)                          
   ,lvl_idn  CHAR(1)                          
   ,tgt_lvl_idn CHAR(1)                          
   )                          
                          
  SELECT @dtl_tmpl_idn  = NULLIF(dtl_tmpl_idn   ,  0)                          
   ,@sap_tmpl_idn   = NULLIF(sap_tmpl_idn   ,  0)                                                                            
   ,@plnt_tmpl_idn   = NULLIF(plant_tmpl_idn   ,  0)                                                                         
   ,@sls_tmpl_idn   = NULLIF(sales_tmpl_idn   ,  0)                            
   ,@plnt_ext_tmpl_idn  = NULLIF(plant_ext_tmpl_idn  ,  0)                                                                            
   ,@sls_ext_tmpl_idn  = NULLIF(sales_ext_tmpl_idn  ,  0)                  
   ,@run_wiz    = NULLIF(run_wiz    , '')                            
   ,@tgt_flg    = NULLIF(tgt_flg    , '')                            
   ,@tgt_mat_typ   = NULLIF(tgt_mat_typ   , '')                           
   ,@tgt_type_class  = NULLIF(tgt_type_class  , '')                          
   ,@tgt_bus_unit_idn  = NULLIF(tgt_bus_unit_idn  , '')                          
   ,@tgt_dtl_tmpl_idn  = NULLIF(tgt_dtl_tmpl_idn  ,  0)                          
   ,@tgt_sap_tmpl_idn  = NULLIF(tgt_sap_tmpl_idn  ,  0)                          
   ,@tgt_plnt_tmpl_idn  = NULLIF(tgt_plant_tmpl_idn  ,  0)                          
   ,@tgt_sls_tmpl_idn  = NULLIF(tgt_sales_tmpl_idn  ,  0)                          
   ,@tgt_plnt_ext_tmpl_idn = NULLIF(tgt_plant_ext_tmpl_idn ,  0)                          
   ,@tgt_sls_ext_tmpl_idn = NULLIF(tgt_sales_ext_tmpl_idn ,  0)                            
  FROM OPENXML(@idoc, 'ROOT/divMisc', 2) WITH                           
   ( dtl_tmpl_idn    INT                          
    ,sap_tmpl_idn    INT                          
    ,plant_tmpl_idn   INT                          
    ,sales_tmpl_idn   INT                          
    ,plant_ext_tmpl_idn  INT                          
    ,sales_ext_tmpl_idn  INT                             
    ,run_wiz     VARCHAR(1)                        
    ,tgt_flg     VARCHAR(1)                          
    ,tgt_mat_typ    VARCHAR(4)                          
    ,tgt_type_class   VARCHAR(8)                          
    ,tgt_bus_unit_idn   VARCHAR(4)                          
    ,tgt_dtl_tmpl_idn   INT                          
    ,tgt_sap_tmpl_idn   INT                          
    ,tgt_plant_tmpl_idn  INT                          
    ,tgt_sales_tmpl_idn  INT                          
    ,tgt_plant_ext_tmpl_idn INT                          
    ,tgt_sales_ext_tmpl_idn INT                             
   )                          
                          
  SELECT @idsid = NULLIF(idsid   , '')                          
   ,@save_typ = NULLIF(save_typ, '')                          
  FROM OPENXML(@idoc, 'ROOT', 2) WITH                           
   ( idsid  VARCHAR(8)                          
   , save_typ VARCHAR(30)                            
   )                          
                          
  EXEC sp_xml_removedocument @idoc                          
                          
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
  ,@lvl_idn = ISNULL(@lvl_idn    , '')                          
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
 EXEC prc_idet_tmpl_scty                          
   @save_typ = @save_typ                          
  ,@mdul_idn = NULL                          
  ,@mat_type = @mat_type                   
  ,@lvl_idn = @lvl_idn                          
  ,@idsid  = @idsid                          
  ,@debug  = @debug                          
                          
 DELETE FROM #tmpl_scty WHERE bus_unit_idn != @bus_unit_idn                          
                          
/**************************************************************************************************                          
*** get templates valid for the current material type/class/design group/user rights combination**/                            
 INSERT INTO @tmpl_dtl(tmpl_idn, par_ent_nme, title, src_idn)                          
  SELECT tt.tmpl_idn                          
   ,te.ent_nme                          
   ,tt.title                          
   ,te.src_idn as src_idn                          
  FROM entity te                           
  JOIN template tt  ON te.ent_idn  = tt.parent_ent_idn                          
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                          
  JOIN entity_related ter ON ter.child_ent_idn= te.ent_idn                           
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
  FROM entity te                           
  JOIN template tt     ON te.ent_idn  = tt.parent_ent_idn                          
  JOIN #tmpl_scty ts     ON tt.bus_unit_idn = ts.bus_unit_idn                          
  JOIN entity_related ter    ON ter.child_ent_idn= te.ent_idn                           
  JOIN template_material_class tmc ON tmc.tmpl_idn  = tt.tmpl_idn                          
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
  FROM entity te                           
  JOIN template tt  ON te.ent_idn  = tt.parent_ent_idn                          
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                          
  JOIN entity_related ter ON ter.child_ent_idn= te.ent_idn                           
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
FROM entity te                           
  JOIN template tt  ON te.ent_idn  = tt.parent_ent_idn                          
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                          
  JOIN entity_related ter ON ter.child_ent_idn= te.ent_idn                           
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
  FROM entity te                           
  JOIN template tt  ON te.ent_idn  = tt.parent_ent_idn                          
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                          
  JOIN entity_related ter ON ter.child_ent_idn= te.ent_idn                           
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
  FROM entity te                           
  JOIN template tt  ON te.ent_idn  = tt.parent_ent_idn                          
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                          
  JOIN entity_related ter ON ter.child_ent_idn= te.ent_idn                           
  WHERE tt.actv_ind = 'Y'    --a template that is active       
    AND tt.admin_ind = 'N'                          
    AND te.src_idn ='4'                          
    AND UPPER(te.ent_nme)='SALES EXT'                          
  ORDER BY te.src_idn, upper(tt.title)                          
                    
  SELECT @sls_ext_tmpl_ct = @@rowcount                           
  SELECT @max_tmpl_ct = CASE WHEN @sls_ext_tmpl_ct > @max_tmpl_ct THEN @sls_ext_tmpl_ct ELSE @max_tmpl_ct END                          
 END                          
  
 IF (@mat_type = 'RAPP' AND @type_class like 'UPI_%')  
 BEGIN    
  INSERT INTO @tmpl_plnt_ext(tmpl_idn, par_ent_nme, title, src_idn)                              
  SELECT tt.tmpl_idn                              
   ,te.ent_nme                              
   ,tt.title                              
   ,te.src_idn as src_idn                              
  FROM entity te                               
  JOIN template tt  ON te.ent_idn  = tt.parent_ent_idn                              
  JOIN #tmpl_scty ts  ON tt.bus_unit_idn = ts.bus_unit_idn                              
  JOIN entity_related ter ON ter.child_ent_idn= te.ent_idn                               
  WHERE tt.actv_ind = 'Y'      --a template that is active                              
    AND tt.admin_ind = 'N'                              
    AND te.src_idn = '3'                              
    AND UPPER(te.ent_nme)='PLANT EXT'                              
  ORDER BY te.src_idn, upper(tt.title)                              
                                
  SELECT @plnt_ext_tmpl_ct = @@rowcount                                  
  SELECT @max_tmpl_ct = CASE WHEN @plnt_ext_tmpl_ct > @max_tmpl_ct THEN @plnt_ext_tmpl_ct ELSE @max_tmpl_ct END   
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
   WHEN @dtl_tmpl_ct > 1 THEN 'display:inline;'                          
   ELSE 'display:none;'                           
  END                          
 FROM  @tmpl_dtl                         
                           
 UPDATE  @TmplSummary                           
 SET sap_tmpl_idn = @sap_tmpl_idn                          
  , sap_tmpl_ct = @sap_tmpl_ct                           
  , sap_tmpl_style =                           
  CASE                            
   WHEN @sap_tmpl_ct > 1 THEN 'display:inline;'                          
   ELSE 'display:none;'                           
  END                          
 FROM  @tmpl_sap                          
                           
                           
 UPDATE  @TmplSummary                           
 SET plant_tmpl_idn = @plnt_tmpl_idn                          
  , plant_tmpl_ct = @plnt_tmpl_ct                           
  , plant_tmpl_style =                           
  CASE                            
   WHEN @plnt_tmpl_ct > 1 THEN 'display:inline;'                          
   ELSE 'display:none;'                           
  END                          
 FROM  @tmpl_plnt                          
                          
                           
 UPDATE  @TmplSummary                           
 SET sales_tmpl_idn = @sls_tmpl_idn                   
  , sales_tmpl_ct = @sls_tmpl_ct                           
  , sales_tmpl_style =                           
  CASE                            
   WHEN @sls_tmpl_ct > 1 THEN 'display:inline;'                          
   ELSE 'display:none;'                           
  END                          
 FROM  @tmpl_sls                          
                           
  UPDATE  @TmplSummary                           
 SET plant_ext_tmpl_idn = @plnt_ext_tmpl_idn                          
  , plant_ext_tmpl_ct = @plnt_ext_tmpl_ct                           
  , plant_ext_tmpl_style =                           
  CASE                            
   WHEN @plnt_ext_tmpl_ct > 1 THEN 'display:inline;'                
   ELSE 'display:none;'                           
  END                          
 FROM  @tmpl_plnt_ext                          
                          
                           
 UPDATE  @TmplSummary                           
 SET sales_ext_tmpl_idn = @sls_ext_tmpl_idn                          
  , sales_ext_tmpl_ct = @sls_ext_tmpl_ct                           
  , sales_ext_tmpl_style =                           
  CASE                            
   WHEN @sls_ext_tmpl_ct > 1 THEN 'display:inline;'                          
   ELSE 'display:none;'                           
  END                          
 FROM  @tmpl_sls_ext                          
                          
/****************************************************************                          
*** Return web results **/                            
 IF @save_typ != 'EXCEL'                         
 IF @IaoActiveInd = 'Y'                        
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
   , 'display:none;' AS [trSalesTmpl<STYLE />]                          
   , plant_ext_tmpl_style AS [trPlantExtTmpl<STYLE />]                          
, 'display:none;' AS [trSalesExtTmpl<STYLE />]                          
  FROM @TmplSummary                        
 END ELSE                         
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
                          
                          
 IF @save_typ IN ('tmpl_selector','rapp_tmpl_get')                           
 BEGIN                          
  SELECT NULL AS  [<TableName>tblDtlTmplOptions</TableName>]                          
  ,tmpl_idn  AS [<ID />]                          
  ,tmpl_idn AS [<VALUE />]                          
  ,title AS [<InnerHTML />]                          
  FROM @tmpl_dtl                          
                            
  SELECT NULL AS  [<TableName>tblSapTmplOptions</TableName>]                          
  ,tmpl_idn  AS [<ID />]                          
  ,tmpl_idn AS [<VALUE />]                          
  ,title AS [<InnerHTML />]                          
  FROM @tmpl_sap                          
                           
                           
  SELECT NULL AS  [<TableName>tblPlantTmplOptions</TableName>]                          
  ,tmpl_idn  AS [<ID />]                          
  ,tmpl_idn AS [<VALUE />]                          
  ,title AS [<InnerHTML />]                
  FROM @tmpl_plnt                          
                          
                            
  SELECT NULL AS  [<TableName>tblSalesTmplOptions</TableName>]                          
  ,tmpl_idn  AS [<ID />]                          
  ,tmpl_idn AS [<VALUE />]                        
  ,title AS [<InnerHTML />]                          
  FROM @tmpl_sls                          
                            
  SELECT NULL AS  [<TableName>tblPlantExtTmplOptions</TableName>]                          
  ,tmpl_idn  AS [<ID />]                          
  ,tmpl_idn AS [<VALUE />]                          
  ,title AS [<InnerHTML />]                          
  FROM @tmpl_plnt_ext                          
                          
                            
  SELECT NULL AS  [<TableName>tblSalesExtTmplOptions</TableName>]                          
  ,tmpl_idn  AS [<ID />]                          
  ,tmpl_idn AS [<VALUE />]                          
  ,title AS [<InnerHTML />]                          
  FROM @tmpl_sls_ext                       
 END                          
                          
/****************************************************************                          
*** Return Excel Live results **/                            
 IF @save_typ = 'EXCEL'                          
 BEGIN                          
  SET @bus_unit_idn = NULLIF(RTRIM(@bus_unit_idn), '')                          
                          
  IF @bus_unit_idn IS NULL                          
  BEGIN                          
   INSERT @tmpl_dtl      (tmpl_idn, title) VALUES (-1, '(Select Design Group first.)')                          
   INSERT @tmpl_sap      (tmpl_idn, title) VALUES (-1, '(Select Design Group first.)')                          
   INSERT @tmpl_plnt     (tmpl_idn, title) VALUES (-1, '(Select Design Group first.)')                          
   INSERT @tmpl_sls      (tmpl_idn, title) VALUES (-1, '(Select Design Group first.)')                          
   INSERT @tmpl_plnt_ext (tmpl_idn, title) VALUES (-1, '(Select Design Group first.)')                          
   INSERT @tmpl_sls_ext  (tmpl_idn, title) VALUES (-1, '(Select Design Group first.)')                          
                            
   SELECT @dtl_tmpl_ct    = -1                          
    ,@sap_tmpl_ct      = -1                          
    ,@plnt_tmpl_ct     = -1                          
    ,@sls_tmpl_ct      = -1                          
    ,@plnt_ext_tmpl_ct = -1                          
    ,@sls_ext_tmpl_ct  = -1                          
  END                          
                          
  IF @dtl_tmpl_ct      = 0 INSERT @tmpl_dtl      (tmpl_idn, title) VALUES (0, 'Detail Default')                          
  IF @sap_tmpl_ct      = 0 INSERT @tmpl_sap      (tmpl_idn, title) VALUES (0, 'SAP Char. Default')                      
  IF @plnt_tmpl_ct     = 0 INSERT @tmpl_plnt     (tmpl_idn, title) VALUES (0, 'Plants Default')                          
  IF @sls_tmpl_ct    = 0 INSERT @tmpl_sls      (tmpl_idn, title) VALUES (0, 'Sales Default')                          
  IF @plnt_ext_tmpl_ct = 0 INSERT @tmpl_plnt_ext (tmpl_idn, title) VALUES (0, 'Plants Extentions Default')                          
  IF @sls_ext_tmpl_ct  = 0 INSERT @tmpl_sls_ext  (tmpl_idn, title) VALUES (0, 'Sales Extentions Default')                          
                          
  IF @plnt_tmpl_ct     IS NULL INSERT @tmpl_plnt     (tmpl_idn, title) VALUES (-1, '(N/A Material Type)')                          
 IF @sls_tmpl_ct      IS NULL INSERT @tmpl_sls      (tmpl_idn, title) VALUES (-1, '(N/A Material Type)')                          
  IF @plnt_ext_tmpl_ct IS NULL INSERT @tmpl_plnt_ext (tmpl_idn, title) VALUES (-1, '(N/A Material Type)')                          
  IF @sls_ext_tmpl_ct  IS NULL INSERT @tmpl_sls_ext  (tmpl_idn, title) VALUES (-1, '(N/A Material Type)')                          
                          
  IF @dtl_tmpl_idn < 1 OR NOT EXISTS (SELECT TOP 1 tmpl_idn FROM @tmpl_dtl WHERE @dtl_tmpl_idn = tmpl_idn)                          
   SELECT TOP 1 @dtl_tmpl_idn = tmpl_idn FROM @tmpl_dtl ORDER BY UPPER(title)                          
  IF @sap_tmpl_idn < 1 OR NOT EXISTS (SELECT TOP 1 tmpl_idn FROM @tmpl_sap WHERE @sap_tmpl_idn = tmpl_idn)                          
   SELECT TOP 1 @sap_tmpl_idn = tmpl_idn FROM @tmpl_sap ORDER BY UPPER(title)                          
  IF @plnt_tmpl_idn < 1 OR NOT EXISTS (SELECT TOP 1 tmpl_idn FROM @tmpl_plnt WHERE @plnt_tmpl_idn = tmpl_idn)                          
   SELECT TOP 1 @plnt_tmpl_idn = tmpl_idn FROM @tmpl_plnt ORDER BY UPPER(title)                          
  IF @sls_tmpl_idn < 1 OR NOT EXISTS (SELECT TOP 1 tmpl_idn FROM @tmpl_sls WHERE @sls_tmpl_idn = tmpl_idn)                          
   SELECT TOP 1 @sls_tmpl_idn = tmpl_idn FROM @tmpl_sls ORDER BY UPPER(title)                          
  IF @plnt_ext_tmpl_idn < 1 OR NOT EXISTS (SELECT TOP 1 tmpl_idn FROM @tmpl_plnt_ext WHERE @plnt_ext_tmpl_idn = tmpl_idn)                          
   SELECT TOP 1 @plnt_ext_tmpl_idn = tmpl_idn FROM @tmpl_plnt_ext ORDER BY UPPER(title)                          
  IF @sls_ext_tmpl_idn < 1 OR NOT EXISTS (SELECT TOP 1 tmpl_idn FROM @tmpl_sls_ext WHERE @sls_ext_tmpl_idn = tmpl_idn)                          
   SELECT TOP 1 @sls_ext_tmpl_idn  = tmpl_idn FROM @tmpl_sls_ext ORDER BY UPPER(title)                          
                          
  SELECT NULL AS [<TableName>dtl_tmpl_idn</TableName>]     , tmpl_idn AS [<ValueMember />], title AS [<DisplayMember />] FROM @tmpl_dtl      ORDER BY UPPER(title)                        
  SELECT NULL AS [<TableName>sap_tmpl_idn</TableName>]     , tmpl_idn AS [<ValueMember />], title AS [<DisplayMember />] FROM @tmpl_sap      ORDER BY UPPER(title)                          
  SELECT NULL AS [<TableName>plnt_tmpl_idn</TableName>]    , tmpl_idn AS [<ValueMember />], title AS [<DisplayMember />] FROM @tmpl_plnt     ORDER BY UPPER(title)                          
  SELECT NULL AS [<TableName>sls_tmpl_idn</TableName>]     , tmpl_idn AS [<ValueMember />], title AS [<DisplayMember />] FROM @tmpl_sls      ORDER BY UPPER(title)                          
  SELECT NULL AS [<TableName>plnt_ext_tmpl_idn</TableName>], tmpl_idn AS [<ValueMember />], title AS [<DisplayMember />] FROM @tmpl_plnt_ext ORDER BY UPPER(title)                          
  SELECT NULL AS [<TableName>sls_ext_tmpl_idn</TableName>] , tmpl_idn AS [<ValueMember />], title AS [<DisplayMember />] FROM @tmpl_sls_ext  ORDER BY UPPER(title)                          
 END              
                          
/****************************************************************                          
*** Return debugging results **/                            
 IF @debug='Y'                           
 BEGIN                          
  SELECT 'debug'   [debug]                          
  ,@mat_type    [@mat_type]                              
  ,@type_class   [@type_class]                             
  ,@bus_unit_idn   [@bus_unit_idn]                             
  ,@lvl_idn    [@lvl_idn]                              
  ,@dtl_tmpl_idn   [@dtl_tmpl_idn]                             
  ,@sap_tmpl_idn   [@sap_tmpl_idn]                             
  ,@plnt_tmpl_idn   [@plnt_tmpl_idn]                            
  ,@sls_tmpl_idn   [@sls_tmpl_idn]                            
  ,@plnt_ext_tmpl_idn  [@plnt_ext_tmpl_idn]                           
  ,@sls_ext_tmpl_idn  [@sls_ext_tmpl_idn]                           
  ,@run_wiz    [@run_wiz]                              
  ,@tgt_flg    [@tgt_flg]                              
  ,@tgt_mat_typ   [@tgt_mat_typ]                             
  ,@tgt_type_class  [@tgt_type_class]                            
  ,@tgt_bus_unit_idn  [@tgt_bus_unit_idn]                            
  ,@tgt_dtl_tmpl_idn  [@tgt_dtl_tmpl_idn]                            
  ,@tgt_sap_tmpl_idn  [@tgt_sap_tmpl_idn]                            
  ,@tgt_plnt_tmpl_idn  [@tgt_plnt_tmpl_idn]                           
  ,@tgt_sls_tmpl_idn  [@tgt_sls_tmpl_idn]                           
  ,@tgt_plnt_ext_tmpl_idn [@tgt_plnt_ext_tmpl_idn]                          
  ,@tgt_sls_ext_tmpl_idn [@tgt_sls_ext_tmpl_idn]                          
  ,@dtl_tmpl_idn   [@tgt_dtl_tmpl_idn]                            
  ,@sap_tmpl_idn   [@tgt_sap_tmpl_idn]                            
  ,@plnt_tmpl_idn   [@tgt_plnt_tmpl_idn]                           
  ,@sls_tmpl_idn   [@tgt_sls_tmpl_idn]                           
  ,@plnt_ext_tmpl_idn  [@tgt_plnt_ext_tmpl_idn]                          
  ,@sls_ext_tmpl_idn  [@tgt_sls_ext_tmpl_idn]                          
                          
  SELECT '#tmpl_scty' [#tmpl_scty], * FROM #tmpl_scty                          
  SELECT '@tmpl_dtl'  [@tmpl_dtl] , * FROM @tmpl_dtl                          
  SELECT '@tmpl_sap'  [@tmpl_sap] , * FROM @tmpl_sap                          
 END                          
                           
 /** clean-up **/                          
 DROP TABLE #tmpl_scty                          
END   