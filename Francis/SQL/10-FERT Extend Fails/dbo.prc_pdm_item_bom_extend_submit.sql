  
CREATE PROCEDURE [dbo].[prc_pdm_item_bom_extend_submit]   
(@XmlDoc   XML    = NULL  
,@usr_acct   VARCHAR(8)  = NULL  
,@ecc_plnt_cde  CHAR(4)  
,@PlantId           CHAR(4)  
,@mrp_area   VARCHAR(10)  = NULL  
,@parent_item_cde VARCHAR(21)   
,@parent_item_rev CHAR(2)  
,@eco_nbr   CHAR(10)  = NULL  
,@eco_rev   CHAR(2)   = NULL  
,@ext_typ   CHAR(1)   = 'I'  
,@internal_flg  CHAR(1)   = 'Y'  
,@spd_tran_id  VARCHAR(50)  OUTPUT  
,@debug    CHAR(1)   = 'N'  
) AS  
/******************************************************************************  
** Purpose: Applies business logic and filters data. Then calls the crud proc  
** History: cbhingar 08/14/09 created   
**   vgrave  03/16/10 UI performance  
**          bheinaue 10/12/10 use bom_idn to get additional bom data rather than parent/child id  
**          omcisner 12/17/13 ibdm mods (#8069313)  
**          wng5     02/13/26 IAO Add PlantId  
** Copyright 2008-2009 Intel Corporation, all rights reserved.  
******************************************************************************/  
BEGIN  
 DECLARE @rtn   INT  
  ,@cre_tbl  CHAR(1)  
   
 SET @rtn = 0  
  
 if @debug = 'Y' print 'prc_pdm_item_bom_extend_submit, creating #bomDetails table.'  
   
 CREATE TABLE #bomDetails(  
  id [int] IDENTITY NOT NULL,  
  spd_tran_id [varchar](50) NULL,  
  parent_item_cde [varchar](21) NULL,  
  parent_item_rev [char](2) NULL,  
  child_item_cde [varchar](21) NULL,  
  child_item_rev [char](2) NULL,   
  bom_lvl_nbr [int] NULL,  
  bom_find_nbr [int] NULL,  
  bom_typ_cde [char](1) NULL,  
  lvl_idn [char](1) NULL,  
  uom [char](3) NULL,  
  mat_typ [char](4) NULL,  
  cmdt_cde [char](10) NULL,  
  proc_typ_idn [int] NULL,    
  ref_material [varchar](21) NULL,    
  bom_qty [varchar](40) NULL,  
  std_cost [varchar](40) NULL,  
  cmdt_mgr_cde [char](2) NULL,  
  child_id [int] NULL,  
  parent_id [int] NULL,  
  ver_ctl_ent [char](3) NULL,   
  spd_sts [varchar](16) NULL,  
  alt_idn [char](2) NULL,  
  make_buy_cde [char](1) NULL,  
  child_dsc [varchar](40) NULL,  
  bom_idn [int] NULL,  
  ignore_row_extended bit DEFAULT 0,   
  ignore_row_fParent bit DEFAULT 0  
  ,alt_item_group char(2) NULL  
  ,cost_rel [char](1) NULL  
  )  
  
/******************************************************************************  
** fill SAP Material session tables */  
 if @debug = 'Y' print 'Item extend, choosing path.'  
   
 SET @spd_tran_id = NULLIF(RTRIM(@spd_tran_id), '')  
  
 IF @XmlDoc IS NOT NULL AND @spd_tran_id IS NULL  
 BEGIN  
  IF @ext_typ = 'I'  
  BEGIN  
  
   if @debug = 'Y' print '@ext_typ = I; Item extend, starting bom #bomDetails build.'  
     
   INSERT INTO #bomDetails (  
    parent_item_cde,  
    parent_item_rev,  
    child_item_cde,  
    child_item_rev,  
    bom_lvl_nbr,     
    proc_typ_idn,    
    ref_material  
   )    
   SELECT DISTINCT dtl.row.value('@parent_item_cde','varchar(21)') as parent_item_cde         
    ,dtl.row.value('@parent_item_rev','char(2)') as parent_item_rev         
    ,dtl.row.value('@child_item_cde','varchar(21)') as child_item_cde         
    ,dtl.row.value('@child_item_rev','char(2)') as child_item_rev  
    ,CONVERT(INT, dtl.row.value('@bom_lvl_nbr','int')) as bom_lvl_nbr            
    ,dtl.row.value('@proc_typ_idn','int') as proc_typ_idn               
    ,dtl.row.value('@ref_material','varchar(21)') as ref_material          
   FROM @XmlDoc.nodes('/ROOT[1]/detailRpt[1]/ROW') as dtl(row)   
     
   -- Set the parent item cde for the 1st row  
   UPDATE #bomDetails  
   SET parent_item_cde = child_item_cde, parent_item_rev = child_item_rev  
   WHERE id = 1  
        
   -- Do not re-submit the items that are IN PROCESS or SUCCESSFULLY  
   -- extended to the plant and mrp_area     
   UPDATE #bomDetails   
   set ignore_row_extended = 1   
   WHERE child_item_cde IN (SELECT item_cde FROM speed.dbo.item_plant_extension  
                            WHERE item_ext_sts IN ('I', 'S') AND   
                ecc_plnt_cde = @ecc_plnt_cde AND   
             mrp_area = ISNULL(@mrp_area, '') AND  
             PlantId = @PlantId -- IAO  
             )  
     
   UPDATE b   
   SET b.cmdt_cde = i.comdt_cde  
    ,b.mat_typ = i.sap_mat_typ  
   FROM #bomDetails b  
   JOIN item i ON b.child_item_cde = i.item_cde     
      
  END  
  ELSE IF @ext_typ = 'B'  
  BEGIN  
   if @debug = 'Y' print '@ext_typ = B; Bom extend, starting bom #bomDetails build.'  
  
   INSERT INTO #bomDetails (  
    parent_item_cde,  
    parent_item_rev,  
    child_item_cde,  
    child_item_rev,   
    bom_qty,    -- omcisner: ibdm mods  
    bom_lvl_nbr,  
    proc_typ_idn,    
    child_id,  
    parent_id,  
    bom_idn  
    ,alt_item_group  
    ,cost_rel    -- ibdm mod: omcisner   
   )  
   SELECT dtl.row.value('@parent_item_cde','varchar(21)' ) as parent_item_cde  
      ,dtl.row.value('@parent_item_rev','char(2)') as parent_item_rev          
      ,dtl.row.value('@child_item_cde','varchar(21)') as child_item_cde         
      ,dtl.row.value('@child_item_rev','char(2)') as child_item_rev  
      ,ISNULL(NULLIF(dtl.row.value('@bom_qty','varchar(40)'),''),'0.000') as bom_qty  
      ,CONVERT(INT, dtl.row.value('@bom_lvl_nbr','int')) as bom_lvl_nbr             
      ,dtl.row.value('@proc_typ_idn','int') as proc_typ_idn                   
      ,CONVERT(INT, dtl.row.value('@id','varchar(50)')) as child_id  
      ,CONVERT(INT, dtl.row.value('@parent_id','varchar(50)' )) as parent_id  
      ,CONVERT(INT, dtl.row.value('@bom_idn','int')) as bom_idn --blh:   
      ,dtl.row.value('@alt_item_group','char(2)') as alt_item_group  
      ,dtl.row.value('@cost_rel','char(1)') as cost_rel          -- ibdm mod: omcisner   
   FROM @XmlDoc.nodes('/ROOT[1]/detailRpt[1]/ROW') as dtl(row)   
     
   SELECT @eco_nbr as [eco_nbr]  
     
   UPDATE #bomDetails  
   SET parent_item_cde = @eco_nbr  
   ,bom_idn = 0  
   WHERE bom_lvl_nbr = 0  
  
   -- update bom fields  
   -- OMCISNER: removed bom_qty to grab info from incoming xml instead (IBDM mods)  
   UPDATE b SET    
    b.bom_find_nbr=d.bom_find_nbr,  
    b.bom_typ_cde=d.bom_typ_cde,  
    --b.bom_qty=d.child_qty_req,  
    b.bom_idn=d.bom_idn  
   FROM #bomDetails b    
   join design_bom d ON d.bom_idn = b.bom_idn and b.bom_idn <> 0--blh: previous join not reliable, 0=no bom idn  
     
   --update detail fields            
   UPDATE b   
   SET b.cmdt_cde = i.comdt_cde  
    ,b.mat_typ = i.sap_mat_typ            
    ,b.uom = i.uom  
    ,b.std_cost = i.std_cst   
    ,b.make_buy_cde = i.make_buy_cde  
    ,b.child_dsc = i.dsc  
    ,b.alt_idn= CASE WHEN bia.cmp_typ_cde = 3 THEN '02' ELSE '01' END   
    ,b.ver_ctl_ent = LEFT(ISNULL(u.val_txt, ''),3)     
    ,b.spd_sts = irl.nme   
    ,b.lvl_idn = ir.lvl_idn  
    ,b.cmdt_mgr_cde = c.cmdt_mgr_cde  
   FROM #bomDetails b  
   JOIN item i ON b.child_item_cde = i.item_cde   
   JOIN item_revision ir on b.child_item_cde = ir.item_cde and ir.item_rev = b.child_item_rev          
   LEFT JOIN bom_item_assoc bia on b.bom_typ_cde =  bia.bom_typ_cde    
   LEFT JOIN item_rls_lvl irl on irl.lvl_idn = ir.lvl_idn  
   LEFT JOIN uda_item_rev u ON u.item_cde = b.child_item_cde AND u.item_rev = b.child_item_rev and u.att_idn = 10194  
   LEFT JOIN commodity_code c on i.comdt_cde = c.cmdt_cde  
     
  END    
    
  /*  
  if (@debug = 'Y')   
  begin  
   select null as [#bomDetails before F delete], ignore_row_fParent, ignore_row_extended, * from #bomDetails  
  
   select null as [Items extended as F Proc Type],  child_item_cde, ptExt.proc_typ, ptExt.proc_typ_idn    
   from  #bomDetails t  
   inner join procurement_type ptExt on ptExt.proc_typ_idn = t.proc_typ_idn  
   where RTRIM(ptExt.proc_typ)  = 'F'   
    and ptExt.ecc_plnt_cde = @ecc_plnt_cde   
    and curr_actv_ind = 'Y'   
  end         
  */  
    
  /*  
  IF @internal_flg = 'Y'  
  BEGIN  
     
   -- walk down the bom tree and mark rows for deletion when the parent row's proc type starts with F   
   declare @maxBomLevel int  
   set @maxBomLevel  = (select max(bom_lvl_nbr) from #bomDetails  )  
   declare @currentBomLevel int  
   set @currentBomLevel = 0   
     
   while (@currentBomLevel <= @maxBomLevel)   
   begin   
    UPDATE #bomDetails   
     set ignore_row_fParent = 1   
     WHERE parent_item_cde in (  
      select child_item_cde   
      from  #bomDetails t  
      inner join procurement_type ptExt on ptExt.proc_typ_idn = t.proc_typ_idn  
      where   
       -- item's parent is marked for deletion  
       ignore_row_fParent = 1   
       or   
       -- or row is a F proc type  
       (ptExt.proc_typ like  'F%'    
       and ptExt.ecc_plnt_cde = @ecc_plnt_cde   
       and curr_actv_ind = 'Y')   
       )  
     AND RTRIM(parent_item_cde) <> RTRIM(child_item_cde)  
     and bom_lvl_nbr = @currentBomLevel  
  
    set @currentBomLevel  = @currentBomLevel +1   
   end   
  
   if (@debug = 'Y')   
   begin  
      select null as [#bomDetails after F delete], ignore_row_fParent, ignore_row_extended, * from #bomDetails  
   end      
  end  
  */  
    
  -- do not item extend the FERT at any level  
  if (@ext_typ = 'I')   
  begin   
   UPDATE #bomDetails   
   set ignore_row_extended = 1   
   WHERE mat_typ = 'FERT'   
  end     
    
  -- don't delete, need for subsequent procs   
   
  if (@debug = 'Y')   
  begin  
     select null as [#bomDetails after delete_row logic], ignore_row_fParent, ignore_row_extended, * from #bomDetails  
  end     
  
  IF @debug = 'Y'  
  BEGIN  
   print 'IN PROC: speed.dbo.prc_pdm_item_bom_extend_submit'  
   SELECT * FROM #bomDetails  
   print 'starting prc_sap_item_bom_extend_crud...'   
  END  
    
  EXEC @rtn = prc_sap_item_bom_extend_crud  @XmlDoc = @XmlDoc, @cre_tbl = @cre_tbl   
   , @spd_tran_id = @spd_tran_id OUTPUT,  @usr_acct = @usr_acct, @debug = @debug    
    
 END  
 ELSE  
 BEGIN  
  -- No XMLDoc/No Data  
  SELECT @rtn = -1  
 END  
  
 DROP TABLE #bomDetails   
 RETURN @rtn  
END  