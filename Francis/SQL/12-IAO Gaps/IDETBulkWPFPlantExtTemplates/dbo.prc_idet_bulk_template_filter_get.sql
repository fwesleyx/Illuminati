USE [speed]
GO
/****** Object:  StoredProcedure [dbo].[prc_idet_bulk_template_filter_get]    Script Date: 04-08-2026 12:34:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




  
ALTER PROCEDURE [dbo].[prc_idet_bulk_template_filter_get] (@usr_acct CHAR(8)) AS  
/******************************************************************************  
** Purpose: Load WPF Excel Launcher data  
** History: smwoodwo 05/20/09 created  
** neeneli 07/25/19 filter new FG class from OCPLM   
** francisx 05/08/26 - PLANT EXT TEMPLATE DOES NOT HAVE PLANTID, DIVISIONID
** Copyright 2008 Intel Corporation, all rights reserved.  
******************************************************************************/  
BEGIN  
 CREATE TABLE #sap_mat_types (row_idn INT IDENTITY, sap_mat_typ VARCHAR(4))  
 CREATE TABLE #auth   (sap_mat_typ VARCHAR(4), bus_unit_idn VARCHAR(2), lvl_idn VARCHAR(1))  
 CREATE TABLE #classes  (item_typ_cde VARCHAR(4), item_typ_dsc VARCHAR(18))  
 CREATE TABLE #bus_units  (bus_unit_idn VARCHAR(2))  
 CREATE TABLE #idet_lookup     
  (row_idn  INT IDENTITY  
  ,lkup_idn  VARCHAR(40)  DEFAULT ''  
  ,dsc   VARCHAR(255) DEFAULT ''  
  ,fltr   VARCHAR(255) DEFAULT 'false'  
  ,sap_mat_typ VARCHAR(40)  DEFAULT ''  
  ,item_typ_cde VARCHAR(40)  DEFAULT ''  
  ,bus_unit_idn VARCHAR(40)  DEFAULT ''  
  ,opn_lvl_idn VARCHAR(40)  DEFAULT ''  
  ,bulk_type  VARCHAR(40)  DEFAULT ''  
  )  
/******************************************************************************  
*** fill authorization table with  
** Material Type, Item Class, and Business Groups  
** available to the currently logged-on user  
*******************************************************************************/    
 INSERT #sap_mat_types (sap_mat_typ) SELECT 'RAPP'  
 INSERT #sap_mat_types (sap_mat_typ) SELECT 'FERT'  
 INSERT #sap_mat_types (sap_mat_typ) SELECT 'DIEN'  
 INSERT #sap_mat_types (sap_mat_typ) SELECT 'INTG'  

 --VAMSIk--
 --Changes for Adding UNBW --
     -- Check the user has exactly 2 roles via the validation SP
    DECLARE @UserRoleCount     TINYINT,
            @AssignedDivisionId TINYINT;      

    EXEC Pdm.Security.ValidateIaoRole
         @Wwid       =@usr_acct,
         @RoleCount  = @UserRoleCount OUTPUT,       
         @DivisionId = @AssignedDivisionId OUTPUT; 

    IF ( @AssignedDivisionId !=10 or (@AssignedDivisionId Is Null and @UserRoleCount=2))
    BEGIN
        INSERT #sap_mat_types (sap_mat_typ) SELECT 'UNBW'
    END

--END

 --VAMSIK END--

 --FRANCISX - AUGUST 2025 - IAO R3 
 --Changes for Removal of KITS and ESUB
 IF NOT EXISTS(SELECT TOP 1 1 FROM Pdm.Framework.PdmFeatureFlag where FeatureNm = 'IAO_ENABLED_FLAG' and ActiveInd='Y')
 BEGIN
   INSERT #sap_mat_types (sap_mat_typ) SELECT 'KITS'  
 END
  
 INSERT #auth (bus_unit_idn, sap_mat_typ, lvl_idn)  
  SELECT DISTINCT grp.bus_unit_idn, 'RAPP', 'k' -- DRAFT status  
  FROM bus_person_security_grp_role AS scty   
  JOIN bus_unit_dsgn_grp AS grp   
    ON grp.scrty_grp_idn = scty.scrty_grp_idn  
   AND grp.bus_unit_idn != '14' -- SPEED TEST  
  WHERE scty.usr_acct = @usr_acct  
    AND scty.role_idn = 299 -- PLANNER_UPI_DRAFT  
  
 INSERT #auth (bus_unit_idn, sap_mat_typ, lvl_idn)  
  SELECT DISTINCT grp.bus_unit_idn, #sap_mat_types.sap_mat_typ, 'k' -- DRAFT status  
  FROM bus_person_security_grp_role AS scty   
  JOIN bus_unit_dsgn_grp AS grp   
    ON grp.scrty_grp_idn = scty.scrty_grp_idn  
   AND grp.bus_unit_idn != '14' -- SPEED TEST  
  CROSS JOIN #sap_mat_types  
  WHERE scty.usr_acct = @usr_acct  
    AND scty.role_idn = 324 -- PLANNER_FG_DRAFT  
    AND #sap_mat_types.sap_mat_typ != 'RAPP'  
  
 INSERT #auth (bus_unit_idn, sap_mat_typ, lvl_idn)  
  SELECT DISTINCT grp.bus_unit_idn, 'RAPP', 'A' -- DESIGN status  
  FROM bus_person_security_grp_role AS scty   
  JOIN bus_unit_dsgn_grp AS grp   
    ON grp.scrty_grp_idn = scty.scrty_grp_idn  
   AND grp.bus_unit_idn != '14' -- SPEED TEST  
  WHERE scty.usr_acct = @usr_acct  
    AND scty.role_idn = 298 -- PLANNER_UPI  
  
 INSERT #auth (bus_unit_idn, sap_mat_typ, lvl_idn)  
  SELECT DISTINCT grp.bus_unit_idn, #sap_mat_types.sap_mat_typ, 'A' -- DESIGN status  
  FROM bus_person_security_grp_role AS scty   
  JOIN bus_unit_dsgn_grp AS grp   
    ON grp.scrty_grp_idn = scty.scrty_grp_idn  
   AND grp.bus_unit_idn != '14' -- SPEED TEST  
  CROSS JOIN #sap_mat_types  
  WHERE scty.usr_acct = @usr_acct  
    AND scty.role_idn = 323 -- PLANNER_FG  
    AND #sap_mat_types.sap_mat_typ != 'RAPP'  
  
 SELECT DISTINCT NULL AS [<TABLENAME>RoleMap</TABLENAME>], sap_mat_typ, lvl_idn, bus_unit_idn  
 FROM #auth ORDER BY sap_mat_typ, lvl_idn, bus_unit_idn  
  
/******************************************************************************  
*** create drop-down option source tables **/  
  
/** Material Type options **/  
 TRUNCATE TABLE #idet_lookup  
   
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ', ''  
  
 INSERT #idet_lookup (lkup_idn, dsc)  
  SELECT sap_mat_types.sap_mat_typ AS lkup_idn  
     ,sap_mat_types.sap_mat_typ AS dsc   
    FROM #sap_mat_types AS sap_mat_types  
  WHERE EXISTS (SELECT * FROM #auth AS auth WHERE auth.sap_mat_typ = sap_mat_types.sap_mat_typ)  
  ORDER BY sap_mat_types.row_idn  
  
 SELECT NULL AS [<TABLENAME>sap_mat_typOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/** item type/class options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ' , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK item_typ_cde', '' 

--kiranksx start
DECLARE 
    @role_count     INT,
    @iao_role       VARCHAR(20),
    @DivisionId     INT,
    @iao_flag       VARCHAR(2);

  
DECLARE @UserRoles TABLE 
(
    table_name      VARCHAR(15),
    total_role      INT,
    pref_role       VARCHAR(20),
    pref_role_id    INT,
    iao_flag        VARCHAR(2)
);


INSERT @UserRoles
EXEC [dbo].[prc_iao_role_validation]      
      @usr_acct       = @usr_acct,      
      @OPResultSet    = '2',      
      @includeIAOFlag = 1;

SELECT   
    @role_count  = total_role, 
    @iao_role    = pref_role, 
    @DivisionId  = pref_role_id,   -- division returned by preferred role
    @iao_flag    = iao_flag 
FROM @UserRoles;
--kiranksx End
INSERT #classes (item_typ_cde, item_typ_dsc)
SELECT DISTINCT 
       item_type.item_typ_cde, 
       item_type.item_typ_dsc
FROM item_type
JOIN item_sap_material_type  
    ON item_sap_material_type.item_typ_cde = item_type.item_typ_cde  
   AND item_sap_material_type.cre_ind = 'Y'  
JOIN #auth   
    ON #auth.sap_mat_typ = item_sap_material_type.sap_mat_typ  
WHERE item_type.curr_actv_ind = 'Y'  
  AND (item_type.owning_sys <> 'SO' OR item_type.owning_sys IS NULL)  
  AND (item_type.owning_sys <> 'PLM' OR item_type.owning_sys IS NULL)
-- kiranksx Start RBAC
  AND ( @iao_flag = 'N' OR ( @iao_flag = 'Y' AND ( item_type.DivisionId = 30 OR (@role_count = 1 AND item_type.DivisionId = @DivisionId) OR (@role_count = 2 AND item_type.DivisionId IN (10,20)) ) ) )
-- kiranksx End

   
 INSERT #idet_lookup (lkup_idn, dsc, sap_mat_typ)   
  SELECT DISTINCT #classes.item_typ_cde, #classes.item_typ_dsc, item_sap_material_type.sap_mat_typ  
  FROM #classes  
  JOIN item_sap_material_type  
    ON item_sap_material_type.item_typ_cde = #classes.item_typ_cde  
   AND item_sap_material_type.cre_ind = 'Y'  
  ORDER BY item_sap_material_type.sap_mat_typ, #classes.item_typ_dsc, #classes.item_typ_cde  
  
 SELECT NULL AS [<TABLENAME>item_typ_cdeOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,sap_mat_typ  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/** Design Group Options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ' , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type'   , '(Select Bulk Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bus_unit_idn', ''  
  
 INSERT #idet_lookup (lkup_idn, dsc, sap_mat_typ, bulk_type)  
  SELECT DISTINCT grp.bus_unit_idn, grp.short_nme, #auth.sap_mat_typ, 'edit' AS bulk_type  
  FROM bus_unit_dsgn_grp AS grp  
  JOIN #auth ON #auth.bus_unit_idn = grp.bus_unit_idn  
  ORDER BY #auth.sap_mat_typ, grp.short_nme, grp.bus_unit_idn  
  
 INSERT #idet_lookup (lkup_idn, dsc, sap_mat_typ, bulk_type)  
  SELECT lkup_idn, dsc, sap_mat_typ, 'create' AS bulk_type  
  FROM #idet_lookup  
  WHERE sap_mat_typ != ''  
    AND lkup_idn != '00' -- ALL  
  
 SELECT NULL AS [<TABLENAME>bus_unit_idnOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,sap_mat_typ  
  ,bulk_type  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/** Bulk Type ListBox options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type' , ''  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'create', 'Bulk Create/Copy'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'edit'  , 'Bulk Edit/Delete'  
  
 SELECT NULL AS [<TABLENAME>bulk_typeOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/* Start Status options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ' , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bus_unit_idn', '(Select Design Group First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type'   , '(Select Bulk Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK opn_lvl_idn' , ''  
  
 INSERT #idet_lookup (lkup_idn, dsc, sap_mat_typ, bus_unit_idn)  
  SELECT DISTINCT lvl_idn  
   ,CASE lvl_idn WHEN 'k' THEN 'DRAFT' WHEN 'A' THEN 'NON-DRAFT' END  
   ,sap_mat_typ  
   ,bus_unit_idn   
  FROM #auth   
  ORDER BY sap_mat_typ, bus_unit_idn, lvl_idn DESC  
  
 SELECT NULL AS [<TABLENAME>opn_lvl_idnOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,sap_mat_typ  
  ,bus_unit_idn  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/* Save Status options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ' , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bus_unit_idn', '(Select Design Group First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type'   , '(Select Bulk Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK opn_lvl_idn' , '(Select Start Status First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK tgt_lvl_idn' , ''  
 INSERT #idet_lookup (lkup_idn, dsc, opn_lvl_idn)  SELECT 'k', 'DRAFT', 'k'  
 INSERT #idet_lookup (lkup_idn, dsc, opn_lvl_idn)  SELECT 'A', 'NON-DRAFT', 'k'  
 INSERT #idet_lookup (lkup_idn, dsc, opn_lvl_idn)  SELECT 'A', 'NON-DRAFT', 'A'  
  
 SELECT NULL AS [<TABLENAME>tgt_lvl_idnOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,opn_lvl_idn  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/** Detail Template Options **/  
 INSERT #bus_units (bus_unit_idn)  
  SELECT DISTINCT bus_unit_idn FROM #auth  
  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ' , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bus_unit_idn', '(Select Design Group First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type'   , '(Select Bulk Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT '0'                 , 'Detail Default'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK dtl_tmpl_idn', ''  
  
 INSERT #idet_lookup (lkup_idn, dsc, bus_unit_idn)  
  SELECT CONVERT(VARCHAR, tmpl.tmpl_idn), tmpl.title, tmpl.bus_unit_idn  
  FROM entity AS prn_ent  
  JOIN template AS tmpl   
    ON tmpl.parent_ent_idn = prn_ent.ent_idn  
   AND tmpl.actv_ind = 'Y'  
   AND tmpl.admin_ind = 'N'  
  JOIN entity_related AS rltd  
    ON rltd.child_ent_idn= prn_ent.ent_idn   
  JOIN #bus_units AS scty   
    ON scty.bus_unit_idn = tmpl.bus_unit_idn  
  WHERE prn_ent.src_idn = 1   
    AND prn_ent.ent_nme = 'Detail'  
  ORDER BY tmpl.bus_unit_idn, UPPER(tmpl.title)  
  
 SELECT NULL AS [<TABLENAME>dtl_tmpl_idnOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,bus_unit_idn  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/** SAP Template Options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ' , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK item_typ_cde', '(Select Class First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bus_unit_idn', '(Select Design Group First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type'   , '(Select Bulk Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT '0'                 , 'SAP Char. Default'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_tmpl_idn', ''  
  
 INSERT #idet_lookup (lkup_idn, dsc, sap_mat_typ, item_typ_cde, bus_unit_idn)  
  SELECT CONVERT(VARCHAR, tmpl.tmpl_idn) AS lkup_idn  
   ,tmpl.title       AS dsc  
   ,tmc.sap_mat_typ     AS sap_mat_typ  
   ,tmc.item_typ_cde     AS item_typ_cde  
   ,tmpl.bus_unit_idn     AS bus_unit_idn  
  FROM entity AS prn_ent   
  JOIN template AS tmpl  
    ON tmpl.parent_ent_idn = prn_ent.ent_idn  
   AND tmpl.actv_ind = 'Y'  
   AND tmpl.admin_ind = 'N'  
  JOIN entity_related rltd      
    ON rltd.child_ent_idn= prn_ent.ent_idn   
  JOIN template_material_class tmc   
    ON tmc.tmpl_idn = tmpl.tmpl_idn  
  JOIN #sap_mat_types ON #sap_mat_types.sap_mat_typ  = tmc.sap_mat_typ  
  JOIN #classes ON #classes.item_typ_cde = tmc.item_typ_cde  
  JOIN #bus_units ON #bus_units.bus_unit_idn    = tmpl.bus_unit_idn  
  WHERE prn_ent.src_idn = 2 -- an SAP template  
  ORDER BY tmc.sap_mat_typ  
   ,tmc.item_typ_cde  
   ,tmpl.bus_unit_idn  
   ,UPPER(tmpl.title)  
  
 SELECT NULL AS [<TABLENAME>sap_tmpl_idnOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,sap_mat_typ  
  ,item_typ_cde  
  ,bus_unit_idn  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/** Plant Template Options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ'  , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bus_unit_idn' , '(Select Design Group First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type'    , '(Select Bulk Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT '0'                  , 'Plant Default'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK plnt_tmpl_idn', ''  
  
 INSERT #idet_lookup (lkup_idn, dsc, bus_unit_idn)  
  SELECT CONVERT(VARCHAR, tmpl.tmpl_idn), tmpl.title, tmpl.bus_unit_idn  
  FROM entity AS prn_ent  
  JOIN template AS tmpl  
    ON tmpl.parent_ent_idn = prn_ent.ent_idn  
   AND tmpl.actv_ind = 'Y'  
   AND tmpl.admin_ind = 'N'  
  JOIN entity_related AS rltd ON rltd.child_ent_idn = prn_ent.ent_idn   
  JOIN #bus_units ON #bus_units.bus_unit_idn = tmpl.bus_unit_idn  
  WHERE prn_ent.src_idn = 1  
    AND prn_ent.ent_nme = 'Plant'  
  ORDER BY tmpl.bus_unit_idn, UPPER(tmpl.title)  
  
 SELECT NULL AS [<TABLENAME>plnt_tmpl_idnOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,bus_unit_idn  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/** Plant Extension Template Options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ'      , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bus_unit_idn'     , '(Select Design Group First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type'        , '(Select Bulk Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT '0'                      , 'Plant Ext. Default'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK plnt_ext_tmpl_idn', ''  
  
 INSERT #idet_lookup (lkup_idn, dsc, bus_unit_idn)  
  SELECT CONVERT(VARCHAR, tmpl.tmpl_idn), tmpl.title, tmpl.bus_unit_idn  
  FROM entity AS prn_ent  
  JOIN template AS tmpl  
    ON tmpl.parent_ent_idn = prn_ent.ent_idn  
   AND tmpl.actv_ind = 'Y'  
   AND tmpl.admin_ind = 'N'  
  JOIN entity_related AS rltd ON rltd.child_ent_idn = prn_ent.ent_idn   
  JOIN #bus_units ON #bus_units.bus_unit_idn = tmpl.bus_unit_idn  
  JOIN Pdm.[Templates].[TemplatePlantValue] tpv 
    ON tpv.tmpl_idn = tmpl.tmpl_idn
  JOIN Pdm.[Manufacturing].[ManufacturingPlant] mp 
    ON mp.plnt_cde = tpv.plant_idn
  WHERE prn_ent.src_idn = 3  
    AND UPPER(prn_ent.ent_nme)='PLANT EXT'  
    AND mp.DivisionId = @DivisionId  
  ORDER BY tmpl.bus_unit_idn, UPPER(tmpl.title)  
  
 SELECT NULL AS [<TABLENAME>plnt_ext_tmpl_idnOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,bus_unit_idn  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/** Sales Template Options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ' , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bus_unit_idn', '(Select Design Group First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type'   , '(Select Bulk Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT '0'                 , 'Sales Default'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sls_tmpl_idn', ''  
  
 INSERT #idet_lookup (lkup_idn, dsc, bus_unit_idn)  
  SELECT CONVERT(VARCHAR, tmpl.tmpl_idn), tmpl.title, tmpl.bus_unit_idn  
  FROM entity AS prn_ent  
  JOIN template AS tmpl  
    ON tmpl.parent_ent_idn = prn_ent.ent_idn  
   AND tmpl.actv_ind = 'Y'  
   AND tmpl.admin_ind = 'N'  
  JOIN entity_related AS rltd ON rltd.child_ent_idn = prn_ent.ent_idn   
  JOIN #bus_units ON #bus_units.bus_unit_idn = tmpl.bus_unit_idn  
  WHERE prn_ent.src_idn = 1  
    AND prn_ent.ent_nme = 'Sales'  
  ORDER BY tmpl.bus_unit_idn, UPPER(tmpl.title)  
  
 SELECT NULL AS [<TABLENAME>sls_tmpl_idnOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,bus_unit_idn  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/** Sales Extension Template Options **/  
 TRUNCATE TABLE #idet_lookup  
  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sap_mat_typ'     , '(Select Material Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bus_unit_idn'    , '(Select Design Group First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK bulk_type'       , '(Select Bulk Type First)'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT '0'                     , 'Sales Ext. Default'  
 INSERT #idet_lookup (lkup_idn, dsc) SELECT 'BLANK sls_ext_tmpl_idn', ''  
  
 INSERT #idet_lookup (lkup_idn, dsc, bus_unit_idn)  
  SELECT CONVERT(VARCHAR, tmpl.tmpl_idn), tmpl.title, tmpl.bus_unit_idn  
  FROM entity AS prn_ent  
  JOIN template AS tmpl  
    ON tmpl.parent_ent_idn = prn_ent.ent_idn  
   AND tmpl.actv_ind = 'Y'  
   AND tmpl.admin_ind = 'N'  
  JOIN entity_related AS rltd ON rltd.child_ent_idn = prn_ent.ent_idn   
  JOIN #bus_units ON #bus_units.bus_unit_idn = tmpl.bus_unit_idn  
  WHERE prn_ent.src_idn = 4  
    AND UPPER(prn_ent.ent_nme)='SALES EXT'  
  ORDER BY tmpl.bus_unit_idn, UPPER(tmpl.title)  
  
 SELECT NULL AS [<TABLENAME>sls_ext_tmpl_idnOpt</TABLENAME>]  
  ,lkup_idn AS [lkup_idn<Value />]  
  ,dsc  AS [dsc<InnerHtml />]  
  ,fltr  
  ,lkup_idn  
  ,bus_unit_idn  
 FROM #idet_lookup  
 ORDER BY row_idn  
  
/* start page state with blanks **/  
 SELECT NULL AS [<TABLENAME>TemplateFilter</TABLENAME>]  
  ,'BLANK sap_mat_typ' AS sap_mat_typ  
  ,'BLANK sap_mat_typ' AS item_typ_cde  
  ,'BLANK sap_mat_typ' AS bus_unit_idn  
  ,'BLANK bulk_type'  AS bulk_type  
  ,'BLANK sap_mat_typ' AS opn_lvl_idn  
  ,'BLANK sap_mat_typ' AS tgt_lvl_idn  
  ,'BLANK sap_mat_typ' AS dtl_tmpl_idn  
  ,'BLANK sap_mat_typ' AS sap_tmpl_idn  
  ,'BLANK sap_mat_typ' AS plnt_tmpl_idn  
  ,'BLANK sap_mat_typ' AS plnt_ext_tmpl_idn  
  ,'BLANK sap_mat_typ' AS sls_tmpl_idn  
  ,'BLANK sap_mat_typ' AS sls_ext_tmpl_idn  
  
/** cleanup **/  
 DROP TABLE #sap_mat_types  
 DROP TABLE #auth  
 DROP TABLE #classes  
 DROP TABLE #bus_units  
 DROP TABLE #idet_lookup     
END  
  
  
