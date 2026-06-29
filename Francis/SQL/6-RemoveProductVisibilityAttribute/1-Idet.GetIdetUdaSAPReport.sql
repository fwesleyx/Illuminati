    
    
ALTER     PROCEDURE [Idet].[GetIdetUdaSAPReport]        
( @XmlDoc   XML    = NULL    
 ,@type_class  VARCHAR(8)  = NULL        
 ,@bus_unit_idn  VARCHAR(8)  = NULL     
 ,@mat_typ   VARCHAR(8)  = NULL        
 ,@tmpl_idn   INT   = NULL        
 ,@usr_acct   CHAR(8)  = NULL    
 ,@debug   CHAR(1)  = 'N'        
)        
AS    
/*        
Purpose: For the IDET SAP Characteristic page, pull the entire SAPReport related to a given item class        
 History: 26-5-25 wrote documentation - kramuse        
 Copyright  Intel Corporation, all rights reserved.
/*******************************************************************************      
* Name: [[Idet]].[GetIdetUdaSAPReport]
* Author:     
* Modification History      
* Date       Person              Description      
* ---------- ------------------- -----------------------------------------        
* 06/05/2026  fwesleyx          TWC5924-2920 Remove Product Visibility attribute    
*******************************************************************************/ 
*/        
    
BEGIN      
 DECLARE @max_idn INT, @i INT, @idoc INT      
 DECLARE @att_idn   INT      
 DECLARE @atrb_id VARCHAR(20), @tbl_nme VARCHAR(50), @element_type VARCHAR(50), @default_val VARCHAR(1000), @display_val VARCHAR(1000)      
 DECLARE @sql    VARCHAR(1000)      
 DECLARE @att_val_typ char(1), @att_fmt_str varchar(255)      
 DECLARE @element_tbl  VARCHAR(8000)      
 DECLARE @item_cde   VARCHAR(21)  , @item_rev CHAR(2)    
 DECLARE @lvl_idn   CHAR(1)      
 DECLARE @wwid VARCHAR(50)    
 DECLARE @actn VARCHAR(10)          
         
 SET @element_tbl = ''      
    
 EXEC sp_xml_preparedocument @idoc OUTPUT, @XmlDoc      
    
 -- read from from xml, in the deconstructed SP, the wwid is passed into <idsid> element    
 -- eg. <ROOT><actn>edit</actn><item_cde>2000-000-017</item_cde><item_rev>01</item_rev><idsid>12301776</idsid></ROOT>    
 SELECT     
 @lvl_idn  = ISNULL(tgt_lvl_idn, '')      
 --, @rqst_id  = ISNULL(rqst_id, '')      
 , @item_cde = ISNULL(item_cde,'')    
 , @wwid    = ISNULL(idsid, '')    
 , @item_rev =  ISNULL(item_rev,'')    
 ,@actn   =  ISNULL(actn,'')    
 FROM OPENXML(@idoc, 'ROOT', 2) WITH       
 ( tgt_lvl_idn  CHAR(1),     
  rqst_id  VARCHAR(50),    
  item_cde VARCHAR(50),    
  idsid VARCHAR(50),    
   item_rev CHAR(2),    
   actn VARCHAR(10)    
 )      
      
 EXEC sp_xml_removedocument @idoc       
      
 CREATE TABLE #sap (idn INT IDENTITY)    
 EXEC speed.dbo.prc_idet_sap_schema    
     
 CREATE TABLE #sap_vals (idn INT IDENTITY)    
 EXEC speed.dbo.prc_idet_sap_vals_schema    
                             
 CREATE TABLE #options       
 (    
  fld_id  INT IDENTITY,    
  fld_vlu VARCHAR(255),    
  fld_dsc VARCHAR(255),    
  att_idn INT      
 )      
    
     
  CREATE TABLE #temp_idet(                        
    item_cde   VARCHAR(21)  DEFAULT ''                        
  , item_rev   VARCHAR(2)  DEFAULT ''                         
  , mat_typ   VARCHAR(8)  DEFAULT ''                        
  , mat_typ_dsc  VARCHAR(50)  DEFAULT ''                        
  , type_class  VARCHAR(8)  DEFAULT ''                        
  )    
    
       
 SELECT @i = 0, @att_idn = 0      
 SELECT @atrb_id = '', @tbl_nme = '', @sql = ''      
 SELECT @att_val_typ = '', @att_fmt_str = ''      
    
 --👇captured from prc_idet_detail_get_master with debug='Y'    
 -------------------------------------------------------------------------------------------------------------------------------    
 -- prc_idet_uda_edit_get (  @type_class =  0994,@bus_unit_idn =  OF,@mat_typ = RAPP,@tmpl_idn = NULL ,@debug = 'N'    
 -- EXECUTE prc_uda_sap_rpt_thin  @mdul_dsc  = 'IDET'  @actn      = 'edit' ,@item_cde  = '2000-000-017' ,@tmpl_idn  = NULL ,@item_typ_cde = '0994' ,@sap_mat_typ = 'RAPP' ,@table_join = 'Y'    
    
 --just need to pass the item code and user acct for prc_uda_sap_rpt_thin to work correctly    
 -------------------------------------------------------------------------------------------------------------------------------    
 DECLARE @item_typ_cde VARCHAR(50)    
    
 print 'wwid : ' + @wwid    
 print 'wwid : ' + @usr_acct    
 print 'item cde : ' + @item_cde    
    
 IF @item_cde IS NOT NULL AND @tmpl_idn IS NULL     
 BEGIN          
   SELECT @tmpl_idn = it.tmpl_idn          
   FROM speed.dbo.item_template it          
   JOIN speed.dbo.template tt ON tt.tmpl_idn = it.tmpl_idn           
   JOIN speed.dbo.entity e  ON e.ent_idn = tt.parent_ent_idn          
   WHERE it.item_cde = @item_cde AND e.src_idn = 2 --SAP Char--       
       
   UPDATE #templates           
   SET sap_tmpl_idn = @tmpl_idn, sap_tmpl_nme = ISNULL(t.title,'None')          
   FROM speed.dbo.template t          
   WHERE tmpl_idn =  @tmpl_idn         
 END          
    
     
 --IF @item_cde IS NOT NULL BEGIN    
 --EXEC speed.dbo.prc_uda_sap_rpt_thin         
 --@mdul_dsc  = 'IDET',    
 --@actn      = 'edit',        
 --@item_cde  = @item_cde,        
 --@tmpl_idn  = NULL,    
 --@item_typ_cde = NULL,        
 --@sap_mat_typ = NULL,      
 --@bus_unit_idn  = NULL,        
 ----@rqst_id  = NULL,        
 --@usr_acct = @wwid,    
 --@table_join = 'Y'      
 --END ELSE BEGIN    
 --EXEC speed.dbo.prc_uda_sap_rpt_thin    
 --@mdul_dsc  = 'IDET',    
 --@actn      = 'new',        
 --@item_cde  = NULL,        
 --@tmpl_idn  = @tmpl_idn,    
 --@item_typ_cde = @type_class,        
 --@sap_mat_typ = @mat_typ,      
 --@bus_unit_idn  = @bus_unit_idn,        
 ----@rqst_id  = NULL,        
 --@usr_acct = @usr_acct,    
 --@table_join = 'Y'      
 --END    
     
 IF @item_cde IS NOT NULL AND @item_cde <> ''  BEGIN    
   EXEC speed.dbo.prc_uda_sap_rpt_thin    
 @mdul_dsc  = 'IDET',    
 @actn      = @actn,       
 @item_cde  = @item_cde,        
 @tmpl_idn  = @tmpl_idn,    
 @item_typ_cde = @type_class,        
 @sap_mat_typ = @mat_typ,      
 @bus_unit_idn  = @bus_unit_idn,        
 --@rqst_id  = NULL,        
 @usr_acct = @usr_acct,    
 @table_join = 'Y'      
 END ELSE BEGIN    
 EXEC speed.dbo.prc_uda_sap_rpt_thin    
 @mdul_dsc  = 'IDET',    
 @actn      = 'new',        
 @item_cde  = NULL,        
 @tmpl_idn  = @tmpl_idn,    
 @item_typ_cde = @type_class,        
 @sap_mat_typ = @mat_typ,      
 @bus_unit_idn  = @bus_unit_idn,        
 --@rqst_id  = NULL,        
 @usr_acct = @usr_acct,    
 @table_join = 'Y'      
 END    
    
  --Add Width & Attribute ID      
 UPDATE #sap       
  SET width = '200px', atrb_id = 'A' + RTRIM(CAST(ISNULL(att_idn,'') AS VARCHAR))       
  FROM #sap      
       
       
  --Add Element Type      
 UPDATE #sap       
  SET element_type = 'multi_selector'      
  FROM #sap       
  WHERE mult_val_ind = 'Y'      
       
 UPDATE #sap           
  SET element_type = 'input'          
  FROM #sap           
  WHERE list_count = 0       
      
 UPDATE #sap           
  SET element_type = 'select'          
  FROM #sap           
  WHERE list_count BETWEEN 1 AND 20         
  AND ISNULL(mult_val_ind,'N') = 'N'      
      
 UPDATE #sap         
  SET element_type = 'selector'        
  FROM #sap           
  WHERE list_count > 20        
  AND ISNULL(mult_val_ind,'N') = 'N'      
      
 UPDATE #sap      
  SET element_type = 'selector'          
  FROM #sap      
  JOIN speed.dbo.uda_item_type uit ON uit.att_idn = #sap.att_idn AND uit.item_typ_cde = #sap.item_typ_cde      
  join speed.dbo.uda_definition ud on ud.att_idn=uit.att_idn      
  join speed.dbo.uda_validation_list uvl on uvl.att_idn=uit.att_idn      
  where uit.rstr_vld_lst_ind='N' AND #sap.list_count > 0    
  --and ud.mult_val_ind != 'Y'     
    
 UPDATE #sap      
  SET element_type = 'selector'          
  FROM #sap      
  WHERE (ISNULL(parent_idn,'') != '' OR ISNULL(child_idns,'') != '')       
   AND element_type = 'select'      
    
     
  /*START # 9110094 */     
 UPDATE #sap        
  SET element_type = 'date'        
  FROM #sap        
  WHERE data_type = 'datetime'        
    
      
 --hidden      
 UPDATE #sap      
 SET hidden = 'display:none'      
 WHERE hidden='Y'      
       
 UPDATE #sap      
 SET hidden = 'display:inline'      
 WHERE hidden='N'      
       
       
 --Add required icon      
 UPDATE #sap       
 SET dsgn_req_ind = req_ind       
       
 UPDATE #sap       
 SET req_icon = '&#149; '      
 FROM #sap t      
 WHERE req_ind = 'true'      
      
 IF @lvl_idn = 'k' BEGIN      
 UPDATE #sap      
 SET req_ind = 'false'      
 END      
      
 --output the controls' required natures. This retains that info for client manipulation      
 --when status changes from Design to Draft and back.       
       
 --SELECT NULL AS [<TABLENAME>SapDfltReq</TABLENAME>]      
 -- ,idn    AS [<ID />]      
 -- ,atrb_id   AS [<VALUE />]      
 -- ,req_ind   AS [<InnerHTML />]      
 --FROM #sap      
 --ORDER BY sort_grp, ord      
       
       
 --Now that that's been output, if it's a draft, make all controls not required      
 IF @lvl_idn = 'k' BEGIN      
 UPDATE #sap      
 SET req_ind = 'false'      
 END      
     
  
   
 /* ---------MAKE CONTROLS ---------------- */       
 /*  Inputs */      
 UPDATE #sap        
 SET ctrl_nme = '<SPEED:InputText'        
 + ' ID="'     + atrb_id + '"'         
 + ' att_idn="'   + CAST(ISNULL(att_idn,'') AS VARCHAR) + '"'      
 + ' Name="SAP Char: '     + mouseover + '"'           
 + ' MAXLENGTH="'    + CAST(data_length AS VARCHAR) + '"'         
 + ' WIDTH="'    + CAST(width AS VARCHAR) + '"'         
 + ' TableName="tblInput"'        
 + ' DataBindID="val"'        
 + ' TableSelect="att_idn='  + CAST(att_idn AS VARCHAR)  + '"'        
 + ' IsRequired='    + req_ind + ''        
 + ' DsgnRequired='  + dsgn_req_ind + ''             
  + ' parent_idn="' + CAST(ISNULL(parent_idn,'') AS VARCHAR) + '" '      
 + ' child_idns="' + CAST(ISNULL(child_idns,'') AS VARCHAR) + '" '      
 + ' IsUpper=True '      
 + ' Mask="'     + mask + '" '        
 + ' MinRange="'    + low_range + '"'        
 + ' MaxRange="'    + high_range + '"'        
 + ' SaveID=val'        
 + ' SaveType=Save'          
 + ' ONCHANGE="vbscript:Call fnRptRowChange()"'         
 + ' ModCode='    + CAST(mod_cde  AS VARCHAR)          
 + ' runat="server" />'        
 WHERE element_type = 'input' and data_type = 'int'  and ISNULL(high_range,'') != ''      
          
 UPDATE #sap        
 SET ctrl_nme = '<SPEED:InputText'        
 + ' ID="'    + atrb_id + '"'         
 + ' att_idn="'   + CAST(ISNULL(att_idn,'') AS VARCHAR) + '"'      
 + ' Name="SAP Char: '    + mouseover + '"'           
 + ' MAXLENGTH="'   + CAST(data_length AS VARCHAR) + '"'         
 + ' WIDTH="'   + CAST(width AS VARCHAR) + '"'         
 + ' TableName="tblInput"'         
 + ' DataBindID="val"'        
 + ' TableSelect="att_idn=' + CAST(att_idn AS VARCHAR)  + '"'        
 + ' IsRequired='   + req_ind + ''       
 + ' DsgnRequired='  + dsgn_req_ind + ''           
 + ' parent_idn="' + CAST(ISNULL(parent_idn,'') AS VARCHAR) + '" '      
 + ' child_idns="' + CAST(ISNULL(child_idns,'') AS VARCHAR) + '" '      
 + ' IsUpper=True '      
 + ' Mask="'    + mask + '" '        
 + ' SaveID=val'        
 + ' SaveType=Save'           
 + ' ONCHANGE="vbscript:Call fnRptRowChange()"'          
 + ' ModCode='    + CAST(mod_cde  AS VARCHAR)          
 + ' runat="server" />'        
 WHERE element_type = 'input' and (data_type != 'int' or (data_type = 'int'  and ISNULL(high_range,'') = ''))      
      
      
 /* Dropdowns */      
 UPDATE #sap       
 SET ctrl_nme = '<SPEED:Select'       
 + ' ID="'  + atrb_id + '"'      
 + ' att_idn="'    + CAST(ISNULL(att_idn,'') AS VARCHAR) + '"'      
 + ' Name="SAP Char: '  + mouseover + '"'         
 + ' TableName="tblSelect"'      
 + ' DataBindID="val"'      
 + ' TableSelect="att_idn=' + CAST(att_idn AS VARCHAR)  + '"'      
 + ' SIZE="1"'      
 + ' WIDTH="'    + CAST(width AS VARCHAR) + '"'      
 + ' ShowQuickPick="true" '      
 + ' OptionTableName="tblOptions"'      
 + ' OptionTableSelect="att_idn=' + CAST(att_idn AS VARCHAR)  + '"'      
 + ' IsRequired='   + req_ind + ''       
  + ' DsgnRequired='  + dsgn_req_ind + ''          
  + ' parent_idn="' + CAST(ISNULL(parent_idn,'') AS VARCHAR) + '" '      
  + ' child_idns="' + CAST(ISNULL(child_idns,'') AS VARCHAR) + '" '      
 + ' SaveID=val'         
 + ' SaveType=Save'         
 + ' ONCHANGE="vbscript:Call fnRptRowChange()"'       
 + ' ModCode='    + CAST(mod_cde  AS VARCHAR)      
 + ' runat="server" />'       
 WHERE element_type = 'select'      
       
 /* Selectors */      
 UPDATE #sap       
 SET ctrl_nme = '<SPEED:Selector'       
 + ' ID="'     + atrb_id + '"'      
 + ' att_idn="'    + CAST(ISNULL(att_idn,'') AS VARCHAR) + '"'      
 + ' Name="SAP Char: '    + mouseover + '"'         
 + ' TableName="tblSelector"'      
 + ' DataBindID="val"'      
 + ' TableSelect="att_idn=' + CAST(att_idn AS VARCHAR)  + '"'        
 + ' SelectorNbr="'   + CAST(slct_idn AS VARCHAR) + '"'      
 + ' MAXLENGTH="'   + CAST(data_length AS VARCHAR) + '"'        
 + ' IsRequired='   + req_ind + ''       
 + ' DsgnRequired='  + dsgn_req_ind + ''          
 + ' parent_idn="'   + CAST(ISNULL(parent_idn,'') AS VARCHAR) + '" '      
 + ' child_idns="'   + CAST(ISNULL(child_idns,'') AS VARCHAR) + '" '      
 + ' SaveID=val'         
 + ' SaveType=Save'       
 + ' OnSelectorOpen="fnSetAttIdn()"'        
 + ' OnVerify="fnSetAttIdn()"'        
 + ' ONCHANGED="fnRptRowChange()"'        
 + ' ModCode='    + CAST(mod_cde  AS VARCHAR)        
 + ' runat="server" />'       
 WHERE element_type = 'selector'      
      
      
 /* Multi_Selectors */      
 UPDATE #sap       
 SET ctrl_nme = '<SPEED:SelectorMulti'       
 + ' ID="'     + atrb_id + '"'      
 + ' att_idn="'    + CAST(ISNULL(att_idn,'') AS VARCHAR) + '"'      
 + ' Name="SAP Char: '  + mouseover + '"'           
 + ' DataBindID="val"'        
 + ' SelectorNbr="'   + CAST(slct_idn AS VARCHAR) + '"'      
 + ' MAXLENGTH="'   + CAST(data_length AS VARCHAR) + '"'        
 + ' IsRequired="'   + req_ind + '"'       
 + ' DsgnRequired='  + dsgn_req_ind + ''         
 + ' parent_idn="'   + CAST(ISNULL(parent_idn,'') AS VARCHAR) + '" '      
 + ' child_idns="'   + CAST(ISNULL(child_idns,'') AS VARCHAR(1000)) + '" '        
 + ' SaveID="val"'         
 + ' SaveType="Save"'      
 + ' OptionTableSelect="att_idn=' + CAST(att_idn AS VARCHAR) + '"'        
 + ' OptionTableName="tblMultiSelector"'      
 + ' OnSelectorOpen="fnSetAttIdn()"'       
 + ' ONCHANGED="fnRptRowChange()"'       
 + ' ModCode='    + CAST(mod_cde  AS VARCHAR)      
 + ' runat="server" />'       
 WHERE element_type = 'multi_selector'      
    
 /* START # 9110094   Date */        
 UPDATE #sap          
 SET ctrl_nme = '<SPEED:Date'          
 + ' ID="'     + atrb_id + '"'           
 + ' att_idn="'   + CAST(ISNULL(att_idn,'') AS VARCHAR) + '"'        
 + ' Name="SAP Char: '     + mouseover + '"'             
 + ' MAXLENGTH="'    + CAST(data_length AS VARCHAR) + '"'           
 + ' WIDTH="'    + CAST(width AS VARCHAR) + '"'           
 + ' TableName="tblInput"'          
 + ' DataBindID="val"'          
 + ' TableSelect="att_idn='  + CAST(att_idn AS VARCHAR)  + '"'            
 + ' IsRequired='  + req_ind + ''          
  + ' DsgnRequired='  + dsgn_req_ind + ''          
  + ' parent_idn="' + CAST(ISNULL(parent_idn,'') AS VARCHAR) + '" '        
 + ' child_idns="' + CAST(ISNULL(child_idns,'') AS VARCHAR) + '" '        
 + ' IsUpper=True '        
 + ' Mask="'   + mask + '" '          
 + ' MinRange="'  + low_range + '"'          
 + ' MaxRange="'  + high_range + '"'          
 + ' SaveID=val'          
 + ' SaveType=Save'            
 + ' ONCHANGE="vbscript:Call fnRptRowChange()"'           
 + ' ModCode='    + CAST(mod_cde  AS VARCHAR)            
 + ' runat="server" />'          
 WHERE element_type = 'date'        
    
    
 IF @debug= 'Y'     
 BEGIN      
  select * from #sap      
  select * from #sap_vals      
  select 'EXECUTE prc_uda_sap_rpt_thin'       
  + '  @actn   = ''new'''      
  + ' ,@item_typ_cde = ''' + cast(isnull(@type_class,'') as varchar) + ''' '      
  + ' ,@sap_mat_typ = ''' + cast(isnull(@mat_typ,'') as varchar)  + ''' '      
  + ' ,@bus_unit_idn  = ''' + cast(isnull(@bus_unit_idn,'') as varchar) + ''' '      
  + ' ,@table_join = ''Y'''      
  + ' ,@tmpl_idn  = ''' + cast(isnull(@tmpl_idn,'') as varchar) + ''' '      
      
  goto ENDIT      
 END      
      
      
 --Dropdown Option table       
 INSERT INTO #options (fld_vlu, fld_dsc, att_idn)      
 SELECT ''      
 ,''      
 ,t.att_idn      
 FROM  #sap t       
 WHERE t.element_type = 'select'      
         
 INSERT INTO #options (fld_vlu, fld_dsc, att_idn)      
 SELECT LTRIM(RTRIM(u.val_txt))      
 ,u.dsc      
 ,u.att_idn      
 FROM speed.dbo.uda_validation_list u      
 JOIN #sap t ON t.att_idn = u.att_idn      
 WHERE u.curr_actv_ind = 'Y' and t.element_type = 'select'      
      
 UPDATE #options       
 SET fld_vlu = speed.dbo.fn_fmt_sap_chars (o.fld_vlu, att_valid_str, 'N')      
 FROM #options o      
 JOIN speed.dbo.uda_definition u ON u.att_idn = o.att_idn      
 WHERE u.att_val_typ = 'N'      
 AND (o.fld_vlu IS NOT NULL AND RTRIM(o.fld_vlu) <> '')      
      
    
      
 IF @item_cde IS NOT NULL BEGIN    
 SELECT NULL AS [<TABLENAME>SAPReport</TABLENAME>]      
 ,label    AS [label]      
 ,req_icon   AS [req_icon<NO_ESCAPE />]      
 ,ctrl_nme   AS [ctrl_nme<NO_ESCAPE />]      
 ,req_ind   AS [ctrl_nme<isRequired>]      
 ,hidden    AS [ctrl_nme<TRSTYLE>]      
 ,att_idn   AS [att_idn<HIDDEN />]      
 ,data_type   AS [data_type<HIDDEN />]      
 ,sort_grp   AS [sort_grp<HIDDEN />]      
 ,ord    AS [ord<HIDDEN />]      
 ,att_nme   AS [att_nme<HIDDEN />]      
 ,parent_idn   AS [parent_idn<HIDDEN />]      
 ,child_idns   AS [child_idns<HIDDEN />]    
 ,CAST(1 AS BIT) AS IsDisable    
 FROM #sap      
 WHERE att_nme<>'MM-PROD-VISIBILITY'
 ORDER BY sort_grp, label      
 END ELSE BEGIN    
 SELECT NULL AS [<TABLENAME>SAPReport</TABLENAME>]      
 ,label    AS [label]      
 ,req_icon   AS [req_icon<NO_ESCAPE />]      
 ,ctrl_nme   AS [ctrl_nme<NO_ESCAPE />]      
 ,req_ind   AS [ctrl_nme<isRequired>]      
 ,hidden    AS [ctrl_nme<TRSTYLE>]      
 ,att_idn   AS [att_idn<HIDDEN />]      
 ,data_type   AS [data_type<HIDDEN />]      
 ,sort_grp   AS [sort_grp<HIDDEN />]      
 ,ord    AS [ord<HIDDEN />]      
 ,att_nme   AS [att_nme<HIDDEN />]      
 ,parent_idn   AS [parent_idn<HIDDEN />]      
 ,child_idns   AS [child_idns<HIDDEN />]    
 ,CAST(1 AS BIT) AS IsDisable     
 FROM #sap
 WHERE att_nme<>'MM-PROD-VISIBILITY'
 ORDER BY sort_grp, ord    
 END    
      
      
 ENDIT:      
 DROP TABLE #sap, #options, #sap_vals      
    
END       