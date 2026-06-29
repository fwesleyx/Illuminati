  
  
ALTER PROCEDURE [dbo].[prc_uda_sap_rpt_thin]            
(@actn   VARCHAR(10)  = 'edit'            
,@mdul_dsc  VARCHAR(40)  = 'IDET'            
,@item_cde  VARCHAR(21)  = NULL            
,@tmpl_idn  INT    = NULL            
,@item_typ_cde VARCHAR(8)  = NULL            
,@sap_mat_typ VARCHAR(8)  = NULL            
,@bus_unit_idn VARCHAR(2)  = NULL            
,@rqst_id  VARCHAR(50)  = ''            
,@usr_acct CHAR(8) = NULL          
,@table_join CHAR(1)   = 'N'            
,@debug  CHAR(1)    = 'N'            
) AS            
/******************************************************************************            
** Purpose: Pull the SAP characteristic data related to a given material/class. Does not create layout html.            
** History: 01/08/07 JP Created            
** cbhingar 10/03/07 Added multiple value for SAP Characteristics functionality            
** smwoodwo 06/12/08 Added req_rsn column for Excel Live            
** mmmcginx 10/08/08 Added bus_unit_idn to sub query            
** cbhingar 11/04/08 EIRP changes            
** 11/12/08 jp CTE recursive bug fix            
** jhoskins 11/25/08 Excel Live Merge            
** jhoskins 12/23/08 Change to sort order            
** smwoodwo 01/16/09 START 7149470, added alpha-numeric mask.            
** smwoodwo 10/16/09 moved temp table schema common to prc_uda_sap_rpt_thin into shared stored procedure            
** jprendiv 10/01/10 START defaults the slctr_idn and casts the min and max range as decimal before varchar.             
** wparndt  10/22/10 Added IPST UDA values, only if coming from IDET              
** waprndt  7/8/11  Changed IDET hard coded values to template_uda table.          
** wparndt  9/18/11  Set it up so if there is no template, it still shows IDET UDAs          
** mtan6 8/26/19  Skip calling to getting idet template when AppName is PLM  
** raviarav 9/30/25 Hide item order point when material type is 'UNBW'   
** wng5     10/6/25 Attribute Lock by item class and lifecycle      
** mtan6     10/7/25 Attribute Required by item class and lifecycle           
** settupax  01/22/26 Attribute Required & Locked by item class and lifecycle  
** fwesleyx  06/05/2026 TWC5924-2920 Remove Product Visibility attribute    
** Copyright 2007-2009 Intel Corporation, all rights reserved.            
*******************************************************************************            
*Class used can be an incoming parameter, derived from an item_cde or derived from a template            
*Provides both default values and meta data (e.g., the required nature of a characteristic.)            
*Meta Data comes from SAP UDA defaults. Template meta data will override SAP defaults.            
*Default values are obtained in this order            
 1. SAP default values            
 2. Overridden by Template default values            
 3. Overridden by Item values            
 4. In the COPY operation, overridden by blank if a template characteristic             
  is set to not copy            
                
IDET MODULE                
*NEW opertion will use a template to define default value and meta data (tmpl_idn)            
*EDIT AND BULK_EDIT will use an item_cde to define default value,             
 and a template to define meta data (item_cde)            
*COPY, BULK_COPY will use an item_cde to define default values and a template to             
 define meta data. BULK_COPY will use the copied item's template. COPY will use a new             
 user-selected template. (tmpl_idn, item_cde)            
             
TEMPLATE MODULE            
*TEMPLATE  module uses this proc to:             
 1. generate an existing template. The template idn is passed in. (tmpl_idn)            
 2. generate a new template. The Material and Class are passed in. No item_cde or             
  template id exists at this point (item_cde)            
******************************************************************************/            
BEGIN            
 SET NOCOUNT ON            
 DECLARE @max_ord INT, @et datetime, @AppName varchar(10)          
 SET @item_cde = NULLIF(@item_cde,'')            
 SET @tmpl_idn = NULLIF(@tmpl_idn,0)            
 SET @item_typ_cde = NULLIF(@item_typ_cde,'')            
   
 DECLARE @IaoActiveInd CHAR(1) = 'N'    
 SELECT @IaoActiveInd = ActiveInd FROM PdmFeatureFlag WHERE FeatureNm = 'IAO_ENABLED_FLAG'  
  
 DECLARE @dependency_relationships TABLE(reltn_idn INT,  
    src_idn INT,  
    bus_unit_idn CHAR(2),  
    sap_mat_typ VARCHAR(4),  
    item_typ_cde VARCHAR(4),  
    parent_idn VARCHAR(10),  
    parent_value_txt VARCHAR(255),  
    child_idn VARCHAR(10),  
    req_ind VARCHAR(1))  
  
 INSERT INTO @dependency_relationships (reltn_idn,src_idn,bus_unit_idn,sap_mat_typ,item_typ_cde,parent_idn,parent_value_txt,child_idn,req_ind)  
 SELECT reltn_idn,src_idn,bus_unit_idn,sap_mat_typ,item_typ_cde,parent_idn,parent_value_txt,child_idn,req_ind  
 FROM dependency_relationships dr WHERE dr.item_typ_cde = @item_typ_cde  
  
 IF(SELECT COUNT(ud.[att_idn]) FROM uda_definition ud  
  JOIN uda_item_type uit ON ud.[att_idn] = uit.[att_idn]  
  WHERE [item_typ_cde] = @item_typ_cde AND  
 [att_nme] IN('MM-SPEC-CODE', 'PRODUCT_MODEL_CODE'))>=2  
 BEGIN  
 INSERT INTO @dependency_relationships (reltn_idn,src_idn,bus_unit_idn,sap_mat_typ,item_typ_cde,parent_idn,parent_value_txt,child_idn,req_ind)  
 VALUES (0, 2, @bus_unit_idn, @sap_mat_typ, @item_typ_cde,  
 (SELECT [att_idn] FROM uda_definition WHERE [att_nme] = 'MM-SPEC-CODE'),  
 'S',  
 (SELECT [att_idn] FROM uda_definition WHERE [att_nme] = 'PRODUCT_MODEL_CODE'),  
 'Y')  
 END    
  
SELECT @AppName = IsNULL(CONVERT(varchar(10), SESSION_CONTEXT(N'AppName')), '')             
  
 --If the template was not passed, and the item_cde was not passed, use the             
 --material and class that was passed as incoming parameters (template create)            
             
 --If the item_cde was passed and not the template id, retrieve the             
 --template idn currently associated with the item (bulk copy, bulk edit)            
            
 IF @item_cde IS NOT NULL AND @tmpl_idn IS NULL AND @item_typ_cde IS NULL AND @rqst_id = ''            
 BEGIN            
  SELECT @tmpl_idn = it.tmpl_idn            
  FROM item_template it            
  JOIN template tt ON tt.tmpl_idn = it.tmpl_idn             
  JOIN entity e  ON e.ent_idn = tt.parent_ent_idn            
  WHERE it.item_cde = @item_cde AND e.src_idn = 2 --SAP Char--            
 END            
             
 --If template was found in the previous step, or the tmpl_idn was passed in,             
 --get material and class related to the tmpl_idn (bulk_copy, bulk_edit, edit, new, template edit)            
 IF @tmpl_idn IS NOT NULL AND @item_typ_cde IS NULL AND @rqst_id = '' BEGIN            
  SELECT @item_typ_cde = item_typ_cde, @sap_mat_typ = sap_mat_typ            
  FROM template_material_class            
  WHERE tmpl_idn = @tmpl_idn            
 END            
             
 --If no template was passed or found,              
 --get the item_cde's material and class (no template associated to existing item)            
 IF @item_cde IS NOT NULL AND @tmpl_idn IS NULL AND @item_typ_cde IS NULL AND @rqst_id = '' BEGIN             
  SELECT @item_typ_cde = item_typ_cde, @sap_mat_typ = sap_mat_typ            
  FROM item             
  WHERE item_cde = @item_cde            
 END            
             
 IF @bus_unit_idn IS NULL AND @item_cde IS NOT NULL AND @rqst_id = '' BEGIN            
  SELECT @bus_unit_idn = bus_unit_idn            
  FROM item            
  JOIN item_revision ON item.item_cde = item_revision.item_cde AND item_revision.item_rev=item.eng_rev            
  WHERE item.item_cde = @item_cde             
 END            
 IF @bus_unit_idn IS NULL AND @tmpl_idn IS NOT NULL AND @rqst_id = '' BEGIN            
  SELECT @bus_unit_idn = bus_unit_idn            
  FROM template            
  WHERE tmpl_idn = @tmpl_idn            
 END            
             
 -- Get item_typ_cde, sap_mat_typ, bus_unit_idn from the request            
 IF (@rqst_id <> '')            
 BEGIN            
  SELECT DISTINCT @item_typ_cde = type_class            
  , @sap_mat_typ = mat_typ            
  , @bus_unit_idn = bus_unit_idn            
  FROM sap_mat_request_basics            
  WHERE item_id = @rqst_id              
 END            
             
 IF @debug='Y' BEGIN            
  select '@item_typ_cde',@item_typ_cde            
  select '@sap_mat_typ',@sap_mat_typ            
  select '@bus_unit_idn',@bus_unit_idn            
  select '@mdul_dsc' ,@mdul_dsc            
  select '@actn',@actn            
 END            
              
 IF @table_join = 'N' BEGIN            
  CREATE TABLE #sap (idn INT IDENTITY)            
  EXEC prc_idet_sap_schema            
            
  CREATE TABLE #sap_vals (idn INT IDENTITY)            
  EXEC prc_idet_sap_vals_schema            
 END            
                
 INSERT INTO #sap (            
    item_typ_cde            
  , item_typ_dsc             
  , att_idn            
  , att_nme            
  , list_count            
  , label              
  , data_type             
  , mask             
  , data_length            
  , mouseover            
  , mult_val_ind            
  , slct_idn            
  , mod_cde            
  , ord            
  , sort_grp            
  , req_ind            
  , req_rsn            
 )            
 SELECT            
    ISNULL(it.item_typ_cde,'')  AS item_typ_cde            
  , ISNULL(it.item_typ_dsc,'') AS item_typ_dsc            
  , ISNULL(ud.att_idn,'')   AS att_idn            
  , ISNULL(ud.att_nme,'')   AS att_nme            
  , (SELECT COUNT(*)            
   FROM uda_validation_list uvl            
   WHERE uvl.att_idn = ud.att_idn            
   AND ud.curr_actv_ind = 'Y'  AND uvl.curr_actv_ind='Y')            
  , ISNULL(ud.att_dsc,'') + ': '    AS label            
  , CASE ud.att_val_typ            
     WHEN 'T' THEN 'varchar'            
     WHEN 'N' THEN 'int'            
     WHEN 'D' THEN 'datetime'            
    END         AS data_type            
  , ISNULL(ud.att_valid_str, '')   AS mask            
  , dbo.fnGetMaskLen(ud.att_valid_str) AS data_length            
  , ISNULL(ud.att_dsc,'')     AS mouseover            
  , NULLIF(ud.mult_val_ind,'')            
  , case isnull(ud.mult_val_ind,'N')            
   when 'N' then 603            
   when 'Y' then 653            
    end            
  , uit.mod_cde            
  , ISNULL(uit.sort_ord, 0) AS ord            
  ,CASE uit.att_req_ind WHEN 'Y' THEN 1  ELSE 4       END AS sort_grp            
  ,CASE uit.att_req_ind WHEN 'Y' THEN 'true' ELSE 'false' END AS req_ind            
  ,CASE uit.att_req_ind WHEN 'Y' THEN 'SAP' ELSE ''      END AS req_rsn            
 FROM uda_definition ud             
 JOIN uda_item_type uit  ON uit.att_idn = ud.att_idn            
 JOIN item_type it    ON it.item_typ_cde = uit.item_typ_cde            
 WHERE ud.table_nme = 'item' and uit.item_typ_cde = @item_typ_cde AND ud.curr_actv_ind = 'Y' 
 and ud.att_nme<>'MM-PROD-VISIBILITY'
          
 IF @mdul_dsc = 'template'       
  INSERT INTO #sap (item_typ_cde, item_typ_dsc , att_idn, att_nme, list_count, label  , data_type , mask , data_length, mouseover, mult_val_ind, slct_idn            
        , mod_cde, ord, sort_grp, req_ind, req_rsn)            
  SELECT            
     ISNULL(it.item_typ_cde,'')  AS item_typ_cde            
   , ISNULL(it.item_typ_dsc,'') AS item_typ_dsc            
   , ISNULL(ud.att_idn,'')   AS att_idn            
   , ISNULL(ud.att_nme,'')   AS att_nme            
   , (SELECT COUNT(*)            
    FROM uda_validation_list uvl            
    WHERE uvl.att_idn = ud.att_idn            
    AND ud.curr_actv_ind = 'Y'  AND uvl.curr_actv_ind='Y')            
   , ISNULL(ud.att_dsc,'') + ': '    AS label            
   , CASE ud.att_val_typ            
      WHEN 'T' THEN 'varchar'            
      WHEN 'N' THEN 'int'            
      WHEN 'D' THEN 'datetime'            
     END         AS data_type            
   , ISNULL(ud.att_valid_str, '')   AS mask            
   , dbo.fnGetMaskLen(ud.att_valid_str) AS data_length            
   , ISNULL(ud.att_dsc,'')     AS mouseover            
   , NULLIF(ud.mult_val_ind,'')            
   , case isnull(ud.mult_val_ind,'N')            
    when 'N' then 603            
    when 'Y' then 653            
     end            
   , uit.mod_cde            
   , ISNULL(uit.sort_ord, 0) AS ord            
   ,CASE uit.att_req_ind WHEN 'Y' THEN 1  ELSE 4       END AS sort_grp            
   ,CASE uit.att_req_ind WHEN 'Y' THEN 'true' ELSE 'false' END AS req_ind            
   ,CASE uit.att_req_ind WHEN 'Y' THEN 'SAP' ELSE ''      END AS req_rsn            
  FROM uda_definition ud             
  JOIN uda_item_type uit  ON uit.att_idn = ud.att_idn and uit.item_typ_cde = @item_typ_cde            
  JOIN item_type it    ON it.item_typ_cde = uit.item_typ_cde             
  WHERE uit.item_typ_cde = @item_typ_cde AND ud.curr_actv_ind = 'Y'            
    AND ud.att_idn in (SELECT att_idn FROM template_uda)            
 ELSE           
 BEGIN     
  IF @tmpl_idn IS NOT NULL    
     INSERT INTO #sap (item_typ_cde, item_typ_dsc , att_idn, att_nme, list_count, label  , data_type , mask , data_length, mouseover, mult_val_ind, slct_idn            
     , mod_cde, ord, sort_grp, req_ind, req_rsn)            
     SELECT            
     ISNULL(it.item_typ_cde,'')  AS item_typ_cde            
      , ISNULL(it.item_typ_dsc,'') AS item_typ_dsc            
      , ISNULL(ud.att_idn,'')   AS att_idn            
      , ISNULL(ud.att_nme,'')   AS att_nme            
      , (SELECT COUNT(*)            
    FROM uda_validation_list uvl            
    WHERE uvl.att_idn = ud.att_idn            
    AND ud.curr_actv_ind = 'Y'  AND uvl.curr_actv_ind='Y')            
      , ISNULL(ud.att_dsc,'') + ': '    AS label            
      , CASE ud.att_val_typ            
      WHEN 'T' THEN 'varchar'            
      WHEN 'N' THEN 'int'            
      WHEN 'D' THEN 'datetime'            
     END         AS data_type            
      , ISNULL(ud.att_valid_str, '')   AS mask            
      , dbo.fnGetMaskLen(ud.att_valid_str) AS data_length            
      , ISNULL(ud.att_dsc,'')     AS mouseover            
      , NULLIF(ud.mult_val_ind,'')            
      , case isnull(ud.mult_val_ind,'N')            
    when 'N' then 603            
    when 'Y' then 653            
     end            
      , uit.mod_cde            
      , ISNULL(uit.sort_ord, 0) AS ord            
      ,CASE uit.att_req_ind WHEN 'Y' THEN 1  ELSE 4       END AS sort_grp            
      ,CASE uit.att_req_ind WHEN 'Y' THEN 'true' ELSE 'false' END AS req_ind            
      ,CASE uit.att_req_ind WHEN 'Y' THEN 'SAP' ELSE ''      END AS req_rsn            
     FROM uda_definition ud             
     JOIN uda_item_type uit  ON uit.att_idn = ud.att_idn            
     JOIN item_type it    ON it.item_typ_cde = uit.item_typ_cde            
     WHERE (ud.table_nme = 'uda') AND EXISTS(select * FROM template_value tv WHERE tv.tmpl_idn = @tmpl_idn AND tv.src_idn = 2 AND tv.ent_idn = ud.att_idn)            
    and uit.item_typ_cde = @item_typ_cde AND ud.curr_actv_ind = 'Y'            
  ELSE    
  begin     
  -- For RAPP    
     INSERT INTO #sap (item_typ_cde, item_typ_dsc , att_idn, att_nme, list_count, label  , data_type , mask , data_length, mouseover, mult_val_ind, slct_idn            
     , mod_cde, ord, sort_grp, req_ind, req_rsn)            
     SELECT            
     ISNULL(it.item_typ_cde,'')  AS item_typ_cde            
      , ISNULL(it.item_typ_dsc,'') AS item_typ_dsc            
      , ISNULL(ud.att_idn,'')   AS att_idn            
      , ISNULL(ud.att_nme,'')   AS att_nme            
      , (SELECT COUNT(*)            
    FROM uda_validation_list uvl            
    WHERE uvl.att_idn = ud.att_idn            
    AND ud.curr_actv_ind = 'Y'  AND uvl.curr_actv_ind='Y')            
      , ISNULL(ud.att_dsc,'') + ': '    AS label            
      , CASE ud.att_val_typ            
      WHEN 'T' THEN 'varchar'            
      WHEN 'N' THEN 'int'            
      WHEN 'D' THEN 'datetime'            
     END         AS data_type            
      , ISNULL(ud.att_valid_str, '')   AS mask      
      , dbo.fnGetMaskLen(ud.att_valid_str) AS data_length            
      , ISNULL(ud.att_dsc,'')     AS mouseover            
      , NULLIF(ud.mult_val_ind,'')            
      , case isnull(ud.mult_val_ind,'N')            
    when 'N' then 603            
    when 'Y' then 653            
     end            
      , uit.mod_cde            
      , ISNULL(uit.sort_ord, 0) AS ord            
      ,CASE uit.att_req_ind WHEN 'Y' THEN 1  ELSE 4       END AS sort_grp            
      ,CASE uit.att_req_ind WHEN 'Y' THEN 'true' ELSE 'false' END AS req_ind            
      ,CASE uit.att_req_ind WHEN 'Y' THEN 'SAP' ELSE ''      END AS req_rsn            
     FROM uda_definition ud             
     JOIN uda_item_type uit  ON uit.att_idn = ud.att_idn            
     JOIN item_type it    ON it.item_typ_cde = uit.item_typ_cde            
     WHERE (ud.table_nme = 'uda') AND EXISTS(select * FROM template_uda tu WHERE tu.att_idn = ud.att_idn) and uit.item_typ_cde = @item_typ_cde AND ud.curr_actv_ind = 'Y'    
  end    
 END          
 -- Update list_count for EPM (External Product ID) characteristic            
/*             
 IF EXISTS(select * from #sap where att_nme = 'EPM_ID')            
 BEGIN            
  UPDATE #sap            
  SET list_count = (select count(*) from vcblry_src_elem where inactv_ind = 'N')            
  WHERE att_nme = 'EPM_ID'            
 END            
*/             
 IF @sap_mat_typ IN ('FERT','DIEN','INTG','KITS') BEGIN            
  SELECT @max_ord = MAX(ord) FROM #sap            
  SET @max_ord = ISNULL(@max_ord, 0)            
            
  INSERT INTO #sap (            
   item_typ_cde            
   , item_typ_dsc             
   , att_idn            
   , att_nme            
   , list_count            
   , label              
   , data_type             
   , mask             
   , data_length            
   , mouseover            
   , mult_val_ind            
   , slct_idn            
   , mod_cde            
   , ord            
   , sort_grp     
   , req_ind            
   , req_rsn            
  )            
  SELECT            
   ISNULL(it.item_typ_cde,'')   AS item_typ_cde            
   , ISNULL(it.item_typ_dsc,'') AS item_typ_dsc            
   , ISNULL(ud.att_idn,'')   AS att_idn            
   , ISNULL(ud.att_nme,'')   AS att_nme            
   , (SELECT COUNT(*)            
    FROM uda_validation_list uvl            
    WHERE uvl.att_idn = ud.att_idn            
    AND ud.curr_actv_ind = 'Y' AND uvl.curr_actv_ind='Y')            
   , ISNULL(ud.att_dsc,'') + ': '    AS label            
   , CASE ud.att_val_typ            
     WHEN 'T' THEN 'varchar'            
     WHEN 'N' THEN 'int'            
     WHEN 'D' THEN 'datetime'          
    END         AS data_type            
   , ISNULL(ud.att_valid_str, '')   AS mask            
   , dbo.fnGetMaskLen(ud.att_valid_str) AS data_length            
   , ISNULL(ud.att_dsc,'')     AS mouseover            
   , NULLIF(ud.mult_val_ind,'')            
   , case isnull(ud.mult_val_ind,'N')            
    when 'N' then 603            
    when 'Y' then 653            
     end            
   , uit.mod_cde            
   , ISNULL(uit.sort_ord, 0) + @max_ord AS ord            
   ,CASE uit.att_req_ind WHEN 'Y' THEN 1  ELSE 4       END AS sort_grp            
   ,CASE uit.att_req_ind WHEN 'Y' THEN 'true' ELSE 'false' END AS req_ind            
   ,CASE uit.att_req_ind WHEN 'Y' THEN 'SAP' ELSE ''      END AS req_rsn            
  FROM uda_definition ud             
  JOIN uda_item_type uit   ON uit.att_idn = ud.att_idn            
  JOIN item_type it    ON it.item_typ_cde = uit.item_typ_cde            
  WHERE ud.table_nme = 'item' and it.item_typ_dsc = 'OT'             
   AND ud.curr_actv_ind = 'Y' AND ud.att_idn NOT IN (            
    SELECT t.att_idn             
    FROM  #sap t             
    )  AND ud.att_nme<>'MM-PROD-VISIBILITY'           
 END            
      
 --Add object dependencies            
             
 UPDATE #sap            
 SET parent_idn = CONVERT(INT, dr.parent_idn)            
 FROM #sap             
 JOIN @dependency_relationships dr ON dr.child_idn = #sap.att_idn             
 WHERE dr.sap_mat_typ = @sap_mat_typ             
  AND dr.item_typ_cde = @item_typ_cde            
  AND dr.bus_unit_idn = '00'            
            
 UPDATE #sap            
 SET parent_idn = CONVERT(INT, dr.parent_idn)            
 FROM #sap             
 JOIN @dependency_relationships dr ON dr.child_idn = #sap.att_idn             
 WHERE dr.sap_mat_typ = @sap_mat_typ             
  AND dr.item_typ_cde = @item_typ_cde            
  AND dr.bus_unit_idn = @bus_unit_idn             
  AND #sap.parent_idn IS NULL            
            
             
  DECLARE @parents TABLE (rw INT IDENTITY, parent_att_idn INT, child_att_idn INT)            
            
 INSERT @parents (parent_att_idn, child_att_idn)            
  SELECT DISTINCT dr.parent_idn AS parent_att_idn, dr.child_idn AS child_att_idn            
  FROM @dependency_relationships dr            
  JOIN #sap AS prn_sap ON prn_sap.att_idn = dr.parent_idn             
  JOIN #sap AS chd_sap ON chd_sap.att_idn = dr.child_idn             
  WHERE dr.sap_mat_typ  = @sap_mat_typ            
    AND dr.item_typ_cde = @item_typ_cde            
    AND dr.bus_unit_idn = '00'            
 UNION            
  SELECT DISTINCT dr.parent_idn AS parent_att_idn, dr.child_idn AS child_att_idn            
  FROM @dependency_relationships dr            
  JOIN #sap AS prn_sap ON prn_sap.att_idn = dr.parent_idn             
  JOIN #sap AS chd_sap ON chd_sap.att_idn = dr.child_idn             
  WHERE  dr.sap_mat_typ = @sap_mat_typ            
    AND dr.item_typ_cde = @item_typ_cde            
    AND dr.bus_unit_idn = @bus_unit_idn            
    AND NOT EXISTS (            
   SELECT *             
   FROM @dependency_relationships AS super_dr            
   WHERE super_dr.parent_idn   = dr.parent_idn            
     AND super_dr.child_idn    = dr.child_idn            
     AND super_dr.sap_mat_typ  = dr.sap_mat_typ            
     AND super_dr.item_typ_cde = dr.item_typ_cde            
     AND super_dr.bus_unit_idn = '00')            
 ORDER BY parent_att_idn, child_att_idn            
             
 ;WITH CTE ( parent_att_idn, children, rw ) AS (             
   SELECT parent_att_idn, CAST(p.child_att_idn AS VARCHAR(8000)), rw            
   FROM @parents AS p            
   WHERE rw IN (SELECT MIN(rw) FROM @parents GROUP BY parent_att_idn)            
  UNION ALL            
     SELECT p.parent_att_idn            
      ,CAST(CTE.children + CHAR(9) + CAST(p.child_att_idn AS VARCHAR) AS VARCHAR(8000))            
      ,p.rw            
   FROM CTE             
   JOIN @parents AS p             
     ON p.parent_att_idn = CTE.parent_att_idn            
    AND p.rw = CTE.rw + 1             
  )            
 UPDATE #sap            
 SET child_idns = CTE.children             
 FROM #sap            
 JOIN CTE            
   ON CTE.parent_att_idn = #sap.att_idn            
  AND CTE.rw IN (SELECT MAX(rw) FROM @parents GROUP BY parent_att_idn);            
            
 UPDATE #sap            
 SET child_idns = CHAR(9) + child_idns + CHAR(9)            
 WHERE child_idns != ''            
             
---------------------------------------------------------------------------------------------------------            
             
 --Add Range Validation            
 UPDATE #sap             
 SET high_range = cast(ISNULL(cast(max_flt as decimal(16,3)),'-1.00') as varchar), low_range = cast(ISNULL(cast(min_flt as decimal(16,3)),'1.00') as varchar)            
 FROM #sap t             
 JOIN uda_validation_range uvr ON uvr.att_idn = t.att_idn            
 WHERE data_type = 'int' AND (max_flt IS NOT NULL or min_flt IS NOT NULL)            
             
 -- characteristics that determine description cannot have special characters             
 UPDATE #sap SET mask = mask + ' [AlphaNbr]'            
 FROM #sap            
 JOIN uda_item_type            
   ON uda_item_type.att_idn  = #sap.att_idn            
  AND uda_item_type.item_typ_cde = #sap.item_typ_cde            
  AND uda_item_type.mod_cde  = 84            
 WHERE #sap.mask IS NULL            
    OR #sap.mask NOT LIKE '%#%'            
            
 UPDATE #sap SET mask = '[AlphaNbr]' WHERE mask = ' [AlphaNbr]'            
            
 -- no mask is used when user is suppose to pick value from drop-down or selector             
 UPDATE #sap SET mask = '' WHERE list_count > 0            
            
----------------------------------------------------------------------------------------------------------------            
 --Templates and object dependendies can drive the next 2 sort orders            
              
 --TEMPLATE Working Tables               
 CREATE TABLE #sap_tmpl_vals (            
      tmpl_idn INT            
    , tmpl_title VARCHAR(200)            
    , tmpl_lvl INT            
    , ent_idn VARCHAR(100)            
    , val  VARCHAR(255))            
             
 CREATE TABLE #sap_tmpl_req (            
      tmpl_idn INT            
    , tmpl_title VARCHAR(200)            
    , tmpl_lvl INT            
    , ent_idn VARCHAR(100)            
    , required VARCHAR(10))            
                
                
 CREATE TABLE #sap_tmpl_hidden (            
      tmpl_idn INT            
    , tmpl_title VARCHAR(200)            
    , tmpl_lvl INT            
    , ent_idn VARCHAR(100)            
    , hidden  VARCHAR(10))            
                
 CREATE TABLE #sap_tmpl_copy_incl (            
      tmpl_idn INT            
    , tmpl_title VARCHAR(200)            
    , tmpl_lvl INT            
    , ent_idn VARCHAR(100)            
    , copy_incl VARCHAR(10))            
                
 --SAP DEFAULT VALS Working Table               
 CREATE TABLE #sap_dflt_vals (            
     att_idn  VARCHAR(100)            
    ,val   VARCHAR(255)            
    )              
             
 --ITEM RECORD VALS Working Table               
 CREATE TABLE #sap_item_vals (            
      att_idn  VARCHAR(100)            
    , val   VARCHAR(255)            
    )                  
                
                
 CREATE TABLE #sap_union_vals              
  (   att_idn  INT            
   , val   VARCHAR(255)            
   , lvl_idn  INT            
  )               
            
             
 --Get the TEMPLATE VALUES. This includes            
 --design grp template, super user template, and SPEED template            
 --applied in that order. In other words, Speed template values            
 --trump super user template values. Super user template values trump             
 --design group template values              
 --produces #sap_tmpl            
        
 IF @mdul_dsc = 'template' BEGIN            
  EXEC prc_tmpl_element_values_get @tmpl_idn = @tmpl_idn            
 END            
 ELSE IF @mdul_dsc = 'IDET'             
 BEGIN            
  IF @rqst_id = ''              
  BEGIN            
   IF NULLIF(@tmpl_idn,0) IS NULL AND @AppName <> 'PLM' BEGIN            
    EXEC prc_idet_tmpl_sap_get             
      @item_typ_cde = @item_typ_cde            
     ,@sap_mat_typ = @sap_mat_typ            
     ,@bus_unit_idn = @bus_unit_idn            
     ,@actn = @actn            
   END            
   ELSE  BEGIN              
    EXEC prc_idet_tmpl_sap_get             
       @tmpl_idn = @tmpl_idn            
      ,@actn = @actn            
   END            
  END            
 END            
            
---------------------------------------------------------------------------------------------------------             
 IF @mdul_dsc='IDET' BEGIN            
 --New and Copy needs SAP DEFAULT VALUES and required properties            
  IF @actn IN ('new','copy','bulk_copy')BEGIN            
            
   IF @rqst_id = ''             
   BEGIN            
    INSERT INTO #sap_dflt_vals (att_idn, val)            
    SELECT t.att_idn, REPLACE(RTRIM(ud.def_val_txt),'''','''''')             
    FROM #sap t             
    JOIN uda_definition ud ON ud.att_idn = t.att_idn             
    WHERE NULLIF(ud.def_val_txt,'') IS NOT NULL            
   END            
   ELSE IF @rqst_id <> '' and @actn = 'new'            
   BEGIN            
    INSERT INTO #sap_dflt_vals(att_idn, val)            
    SELECT ui.att_idn, ui.val               
    FROM #sap t            
    JOIN sap_mat_request_chars ui ON ui.att_idn  = t.att_idn            
    JOIN uda_definition ud ON ud.att_idn  = t.att_idn              
    WHERE ui.item_id = @rqst_id              
   END            
  END            
            
----------------------------------------------------------------------------------------------------------------            
 --Edit and Copy needs the ITEM RECORD'S VALUES            
  IF  @actn IN ('edit', 'copy','bulk_copy')             
  BEGIN            
   IF @rqst_id = ''            
   BEGIN            
    INSERT INTO #sap_item_vals(att_idn, val)            
    SELECT ui.att_idn, CAST(ui.val_flt as VARCHAR)               
    FROM #sap t            
    JOIN uda_item ui  ON ui.att_idn  = t.att_idn            
    JOIN uda_definition ud ON ud.att_idn  = t.att_idn              
    WHERE ud.att_val_typ = 'N' AND ui.item_cde = @item_cde            
                 
    INSERT INTO #sap_item_vals(att_idn, val)            
    SELECT ui.att_idn, RTRIM(CONVERT(VARCHAR, ui.val_dte))              
    FROM #sap t            
    JOIN uda_item ui  ON ui.att_idn  = t.att_idn            
    JOIN uda_definition ud ON ud.att_idn  = t.att_idn              
    WHERE ud.att_val_typ = 'D' AND ui.item_cde = @item_cde            
               
    INSERT INTO  #sap_item_vals(att_idn, val)            
    SELECT ui.att_idn, RTRIM(ui.val_txt)             
    FROM #sap t            
    JOIN uda_item ui  ON ui.att_idn  = t.att_idn            
    JOIN uda_definition ud ON ud.att_idn  = t.att_idn              
    WHERE ud.att_val_typ NOT IN ('N', 'D') AND ui.item_cde = @item_cde             
   END            
   ELSE            
   BEGIN            
    INSERT INTO #sap_item_vals(att_idn, val)            
    SELECT ui.att_idn, ui.val               
    FROM #sap t            
    JOIN sap_mat_request_chars ui ON ui.att_idn  = t.att_idn            
    JOIN uda_definition ud ON ud.att_idn  = t.att_idn              
    WHERE ui.item_id = @rqst_id              
   END            
  END            
 END            
             
------------------------------------------------------------------------------------------------------------------             
 /*            
  enter to a union table the weighted values of :            
  1. SAP Defaults (New and Copy)            
  2. trumped by Template Defaults (New and Copy)            
  3. trumped by Item record values (Edit)          
 */            
            
 INSERT INTO #sap_union_vals            
   ( att_idn              
   , val               
   , lvl_idn              
   )            
 SELECT att_idn, val, 1            
 FROM #sap_dflt_vals            
 where ISNULL(val,'') IS NOT NULL             
             
 INSERT INTO #sap_union_vals            
   ( att_idn              
   , val               
   , lvl_idn              
   )            
 SELECT ent_idn, val, 2            
 FROM #sap_tmpl_vals            
               
 INSERT INTO #sap_union_vals            
   ( att_idn              
   , val               
   , lvl_idn              
   )            
 SELECT att_idn, val, 3            
 FROM #sap_item_vals             
            
 IF @actn IN ('copy','bulk_copy')  BEGIN            
  DELETE #sap_union_vals            
  FROM #sap_union_vals suv            
  JOIN #sap_tmpl_copy_incl stc ON stc.ent_idn = suv.att_idn             
            
 END            
            
 --Insert into the MAIN VALUE TABLE the maximum weighted value. This            
 --will insert an SAP Default if one exists (copy or New)            
 --trumped by a template value, if one exists, (Copy or New)            
 --trumped by an item record value (Edit)             
            
 INSERT INTO #sap_vals(sap_idn, att_idn, default_val)            
 SELECT #sap.idn, s.att_idn, s.val            
 FROM #sap_union_vals s            
 JOIN #sap ON #sap.att_idn = s.att_idn            
JOIN (SELECT max(suv.lvl_idn) lvl_idn,  suv.att_idn             
    FROM (SELECT * FROM #sap_union_vals WHERE val IS NOT NULL) suv            
    GROUP BY suv.att_idn            
   ) s1 ON s.lvl_idn = s1.lvl_idn AND s.att_idn = s1.att_idn            
 ORDER BY s.att_idn, s.lvl_idn            
            
----------------------------------------------------------------------------------------------------------------------            
 --Correct for a rare SAP peculiarity wherein SAP provides an option default value of NULL and            
 --a Display value that is not NULL. This forces the selector            
 --object to not assign an IDN value. This fails to clear Is Required validation because             
 --the IDN attribute is missing.             
 --On GET, convert NULL default_val to temporary value "~|~". On SAVE, convert "~|~" back to NULL.            
 UPDATE #sap_vals            
 SET default_val = '~|~'            
 FROM #sap_vals s            
 JOIN uda_validation_list uvl ON uvl.att_idn = s.att_idn AND s.default_val = uvl.val_txt            
 WHERE RTRIM(ISNULL(uvl.dsc,'')) != '' AND RTRIM(s.default_val) = ''            
            
 update #sap_vals          
 set default_val = dbo.fn_fmt_sap_chars (sv.default_val, u.att_valid_str, 'N')           
 from #sap_vals     sv          
 JOIN uda_definition u ON u.att_idn = sv.att_idn              
 WHERE u.att_val_typ = 'N'              
 AND (sv.default_val IS NOT NULL AND RTRIM(sv.default_val) <> '')            
            
 --Add DISPLAY VALUE from the uda_validation_list where applicable            
 UPDATE #sap_vals             
 SET display_val = RTRIM(ISNULL(uvl.dsc,''))                
 FROM #sap_vals t             
 JOIN uda_validation_list uvl ON uvl.att_idn = t.att_idn             
  and uvl.val_txt = REPLACE(t.default_val,'~|~','')             
  and ISNULL(t.default_val,'') != ''            
            
            
  UPDATE #sap               
  SET display_val = t.default_val                 
  FROM #sap t               
  JOIN uda_validation_list uvl ON uvl.att_idn = t.att_idn             
  JOIN uda_item_type uit ON uit.att_idn = uvl.att_idn AND uit.item_typ_cde = t.item_typ_cde            
  WHERE ISNULL(t.display_val,'') = ''             
    and ISNULL(t.default_val,'') != ''             
    and uit.rstr_vld_lst_ind = 'N'             
              
             
 -- Add Display Value for EPM (External Product ID) characteristic as the actual value            
/*            
 IF EXISTS(select * from #sap where att_nme = 'EPM_ID')            
 BEGIN            
  UPDATE #sap_vals            
  SET display_val = t1.default_val            
  FROM #sap_vals t1            
  JOIN #sap t2 ON t2.att_idn = t1.att_idn            
  WHERE t2.att_nme = 'EPM_ID'            
 END           
*/            
            
             
 UPDATE #sap_vals             
 SET display_val = t.default_val            
 FROM #sap_vals t             
 WHERE ISNULL(t.default_val,'') != '' and ISNULL(t.display_val,'') = ''            
             
-------------------------------------------------------------REQUIRED Property            
            
 UPDATE #sap             
 SET req_ind = 'true', req_rsn = 'Template', sort_grp = 1             
 FROM #sap s            
 JOIN #sap_tmpl_req st ON s.att_idn = st.ent_idn            
 WHERE st.required = 'Y' and s.req_ind != 'true'            
             
 --Add 3rd Sort for other Template fields (4th Sort is default)            
 UPDATE #sap             
 SET sort_grp = 3            
 FROM #sap t            
 JOIN template_value tv ON tv.ent_idn = t.att_idn             
 WHERE t.req_ind = 'false' and tv.tmpl_idn = @tmpl_idn            
             
            
 --Master control drives the required nature of a dependent controls (Object Dependency)            
 IF @actn != 'bulk_copy' BEGIN            
  --make require those that are children of required parents whose value had a rule            
  --mmmcginx 10/08/08 Added bus_unit_idn to sub query            
  UPDATE #sap            
  SET req_ind = 'true', req_rsn = 'Dependent Value', sort_grp = 1             
  FROM #sap s             
  WHERE req_ind = 'false' AND             
   att_idn IN (            
   SELECT drp.child_idn              
   FROM #sap s1            
   JOIN #sap_vals sv ON s1.att_idn = sv.att_idn             
   JOIN @dependency_relationships drp ON drp.parent_idn = s1.att_idn             
   WHERE            
      drp.parent_value_txt = sv.default_val             
    AND  drp.src_idn = 2            
    AND  drp.req_ind = 'Y'            
    AND  drp.bus_unit_idn = @bus_unit_idn            
    AND  drp.sap_mat_typ = @sap_mat_typ             
    AND  drp.item_typ_cde = @item_typ_cde            
            
   )            
               
  --make required the children of required parents whose value is ''              
  UPDATE #sap            
  SET req_ind = 'true', req_rsn = 'Dependent Values', sort_grp = 1           
  FROM #sap s             
  WHERE req_ind = 'false' AND             
   att_idn IN (            
   SELECT drp.child_idn              
   FROM #sap s1            
   JOIN #sap_vals sv ON s1.att_idn = sv.att_idn             
   JOIN @dependency_relationships drp ON drp.parent_idn = s1.att_idn             
   WHERE            
      drp.parent_value_txt = ''             
    AND  drp.src_idn = 2            
    AND  drp.req_ind = 'Y'            
    AND  drp.bus_unit_idn = @bus_unit_idn            
    AND  drp.sap_mat_typ = @sap_mat_typ             
    AND  drp.item_typ_cde = @item_typ_cde            
   )            
              
  --AND exists(SELECT * FROM #sap_vals sv WHERE sv.att_idn = dr.parent_idn and sv.default_val !='' )            
 END            
              
--HIDDEN Property            
  
 UPDATE #sap             
 SET hidden = 'Y'             
 FROM #sap s            
 JOIN #sap_tmpl_hidden st ON s.att_idn = st.ent_idn            
 WHERE st.hidden = 'Y' and s.hidden != 'true'  
   
 -- Hide item oder point in UNBW  
  
IF @sap_mat_typ = 'UNBW' AND EXISTS (SELECT 1 FROM #sap WHERE att_idn = 21998)  
BEGIN  
    UPDATE #sap   
    SET hidden = 'Y'   
    WHERE att_idn = 21998;  
END  
            
--HIDDEN to end of list            
            
 UPDATE #sap             
 SET sort_grp = 5            
 WHERE hidden = 'Y'            
            
--------------------------------------------------------------------------------------------------------------            
            
--COPY_INCL Property            
            
 UPDATE #sap             
 SET copy_incl = 'N'             
 FROM #sap s            
 JOIN #sap_tmpl_copy_incl st ON s.att_idn = st.ent_idn            
 WHERE st.copy_incl = 'N' and s.hidden != 'false'            
            
          
          
-- Custom attribute lockdowns           
          
declare @usr_roles table (role_idn int)          
declare @custom_attr table(item_typ_cde varchar(40), att_idn int, role_idn int          
 , min_life int, max_life int, item_life int          
 , is_active int default 0          
 , is_true int default 0          
 , enabled_ind int DEFAULT 0          
 )          
          
declare @item_life_cycle int          
          
 SET @item_life_cycle = 100          
          
 SELECT @item_life_cycle = irl.life_cycle_val          
 FROM item_revision ir           
 JOIN item i on i.item_cde = ir.item_cde          
 JOIN item_rls_lvl irl on irl.lvl_idn = ir.lvl_idn           
 WHERE ir.item_rev = i.mfg_rev and i.item_cde = @item_cde          
          
          
insert into @custom_attr(item_typ_cde, att_idn, role_idn, min_life, max_life, item_life)          
select ias.item_typ_cde, ias.att_idn, ias.role_idn, ias.life_cycle_min_val, ias.life_cycle_max_val, @item_life_cycle          
from #sap s          
join idet_attribute_security ias on ias.item_typ_cde = s.item_typ_cde and ias.att_idn = s.att_idn           
          
--select '@custom_attr 0', * from @custom_attr           
           
delete           
from @custom_attr           
where att_idn not in (          
 select att_idn           
 from @custom_attr          
 where           
(min_life <= @item_life_cycle           
   and max_life >= @item_life_cycle)          
 )          
          
--select '@custom_attr 1', * from @custom_attr           
          
          
update @custom_attr           
set is_active = 1           
from @custom_attr c          
where c.item_life between c.min_life and c.max_life          
          
insert into @usr_roles(role_idn)            
select distinct b.role_idn           
from  bus_person_bu_role b           
join @custom_attr ca on ca.role_idn = b.role_idn          
where b.usr_acct = @usr_acct          
          
update @custom_attr           
set is_true = 1           
from @custom_attr a           
join @usr_roles u on u.role_idn = a.role_idn           
          
update @custom_attr           
set enabled_ind = 1           
from @custom_attr a          
where att_idn in (          
 select att_idn           
 from @custom_attr ca           
 where is_active = 1 and is_true = 1          
)          
          
--select '@custom_attr 2', * from @custom_attr           
          
        
update #sap           
set mod_cde = 84          
from #sap s           
join @custom_attr ca on ca.item_typ_cde = s.item_typ_cde and ca.att_idn = s.att_idn           
where ca.att_idn in (          
 select att_idn           
 from @custom_attr           
 group by att_idn           
 having max(enabled_ind) = 0          
)          
          
--select '#sap last', * from #sap          
          
-- End custom attribute lockdowns           

-- Lock Attribute and Required Attribute By Lifecycle     
IF (@IaoActiveInd = 'Y')  
BEGIN      
    IF @item_cde IS NULL  
    BEGIN  
        UPDATE s        
        SET req_ind = 'true'         
        FROM #sap s          
        JOIN item_attribute_lifecycle ial ON ial.att_idn = s.att_idn                      
        WHERE ial.item_typ_cde = @item_typ_cde  
        AND ial.lvl_idn = 'A'   
        AND ial.req_ind = 'Y'  
    END      
  
    IF @item_cde IS NOT NULL        
    BEGIN        
          
        -- For REVIEW items with multiple promotion targets, derive the target status from the associated multiple ECOs  
        DECLARE @req_lvl_idn CHAR(1)  
        DECLARE @lock_lvl_idn CHAR(1)  
        SELECT @req_lvl_idn = ISNULL(eic.new_lvl_idn, ir.lvl_idn),  
        @lock_lvl_idn = ISNULL(eic.xst_lvl_idn, ir.lvl_idn)  
        FROM item i         
        JOIN item_revision ir ON i.item_cde = ir.item_cde AND i.mfg_rev = ir.item_rev  
        LEFT JOIN (  
            SELECT TOP 1 xst_item_cde, xst_item_rev, new_lvl_idn, xst_lvl_idn  
            FROM eco_item_change eic   
            JOIN eco eco ON eic.eco_nbr = eco.eco_nbr  
            JOIN eco_mod_history emh ON eco.eco_nbr = emh.eco_nbr  
            WHERE xst_item_cde = @item_cde AND eco.lvl_idn = 'Q'  
            AND emh.cmnt LIKE '%ECC_REVIEW%'   
            ORDER BY emh.mod_tms ASC     
        ) eic ON eic.xst_item_cde = ir.item_cde AND eic.xst_item_rev = ir.item_rev  
        WHERE i.item_cde = @item_cde  
  
        -- Get Spec Code attribute value  
        DECLARE @spec_code_val_txt VARCHAR(255)  
        SELECT @spec_code_val_txt = ui.val_txt   
        FROM uda_item ui     
        JOIN uda_definition ud ON ui.att_idn = ud.att_idn  
        WHERE ui.item_cde = @item_cde  
        AND ud.att_nme = 'MM-SPEC-CODE'  
  
        -- Get TEST MERGE IND attribute value  
        DECLARE @test_merge_ind_val_txt VARCHAR(255)  
        SELECT @test_merge_ind_val_txt = ui.val_txt   
        FROM uda_item ui     
        JOIN uda_definition ud ON ui.att_idn = ud.att_idn  
        WHERE ui.item_cde = @item_cde  
        AND ud.att_nme = 'TEST_MERGE_IND'  
  
        IF @req_lvl_idn = 'k'  
            SET @req_lvl_idn = 'A'  
  
        -- req_ind update  
        UPDATE s        
        SET req_ind = 'true'               
        FROM #sap s  
        JOIN uda_definition ud ON ud.att_idn = s.att_idn  
        JOIN item_attribute_lifecycle ial ON ial.att_idn = ud.att_idn AND ial.req_ind = 'Y'  
        JOIN item i ON i.item_typ_cde = ial.item_typ_cde AND i.item_cde = @item_cde  
        JOIN item_revision ir ON ir.item_cde = i.item_cde AND ir.item_rev = i.mfg_rev  
        WHERE @req_lvl_idn = ial.lvl_idn  
        AND (ud.att_nme != 'PRODUCT_MODEL_CODE'   
             OR (ud.att_nme = 'PRODUCT_MODEL_CODE' AND @spec_code_val_txt = 'S'))  
  
        -- mod_cde update  
        UPDATE s        
        SET mod_cde = 84                
        FROM #sap s  
        JOIN uda_definition ud ON ud.att_idn = s.att_idn  
        JOIN item_attribute_lifecycle ial ON ial.att_idn = ud.att_idn AND ial.lock_ind = 'Y'  
        JOIN item i ON i.item_typ_cde = ial.item_typ_cde AND i.item_cde = @item_cde  
        JOIN item_revision ir ON ir.item_cde = i.item_cde AND ir.item_rev = i.mfg_rev  
        LEFT JOIN uda_item ui ON ui.att_idn = ud.att_idn AND ui.item_cde = i.item_cde  
        WHERE @lock_lvl_idn = ial.lvl_idn  
        AND (s.req_ind != 'true'  
            OR ud.att_val_typ = 'T' AND ui.val_txt IS NOT NULL AND LTRIM(RTRIM(ui.val_txt)) != ''  
            OR ud.att_val_typ = 'N' AND ui.val_flt IS NOT NULL  
            OR ud.att_val_typ = 'D' AND ui.val_dte IS NOT NULL)  
        AND (  
            ud.att_nme NOT IN ('PS-REV', 'PS-STEP', 'PS-MFG-DEVICE', 'MFG_PKG_CODE', 'BIN_CATEGORY', 'PROCESSOR_NUMBER')  
            OR (ud.att_nme IN ('PS-REV', 'PS-STEP', 'PS-MFG-DEVICE', 'MFG_PKG_CODE', 'BIN_CATEGORY')  
                AND (ir.lvl_idn NOT IN ('A', 'q') OR @test_merge_ind_val_txt = 'Y'))  
            OR (ud.att_nme = 'PROCESSOR_NUMBER'   
                AND (ir.lvl_idn != 'B' OR @spec_code_val_txt = 'S'))  
        )  
              
    END  
END  
          
--CLEAN UP            
 -- return results             
 IF @table_join = 'N' BEGIN             
  SELECT * FROM #sap ORDER BY sort_grp, ord            
  DROP TABLE #sap            
  DROP TABLE #sap_vals            
 END             
END     