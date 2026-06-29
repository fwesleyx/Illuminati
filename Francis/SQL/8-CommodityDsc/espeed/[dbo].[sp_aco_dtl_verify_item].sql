USE [espeed]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects where id = object_id(N'[dbo].[sp_aco_dtl_verify_item]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[sp_aco_dtl_verify_item]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_aco_dtl_verify_item] (    
 @item_cde varchar(21)    
 ,@item_rev VARCHAR(2) = NULL    
 ,@usage CHAR(1) = NULL --'B' for ACO item bundle   
 ,@aco_nbr VARCHAR(15) = NULL --aaugus2x - for RBAC
 )    
AS    
/*************************************************************************************************************     
 Purpose:  to verify item is a valid  item and return desc, project, and commodity group.    
     If used by the Item Bundle, tem must be a valid Non-Make item.    
     IF used by the Promotion page, at ACCEPTED level, the only restriction is it be a valid item.    
 History:      
   03/26/03 jp created    
   03/22/12 wparndt - added design group for START 7697801    
   04/25/12 wparndt - Changed commodity code from char(4) to char(10)    
   07/23/12 vgrave item data integrity - add full description    
   10/24/12 krisakse  START# 7836115 - Send back dsc if dsc_full is null or blank    
   04/16/13 msrinivx  START# 7919359 - Design Group and Related ACOs columns are added to keep the    
          Item bundle section consistent.    
   08/29/24 skalai1x  CHG12155128 - fetch the count of existing resteicted Mfr & parts count
   12/14/2025 aaugus2x - CHG11399939 - IAO RBAC 
   06/25/2025 fwesleyx - Change commodity desc char size 
************************************************************************************************************/    
    BEGIN    
 SET NOCOUNT ON    
 DECLARE @msg VARCHAR(255), @sql VARCHAR(2000), @where VARCHAR(1000), @total_ct INT, @filtered_ct int, @restaml_ct int, @IaoActiveInd CHAR(1), @DivisionId INT --aaugus2x - CHG11399939  
 SET @msg = ''    
 
 SELECT @DivisionId = DivisionId FROM eco WHERE eco_nbr = @aco_nbr;--aaugus2x - RBAC
 SELECT @IaoActiveInd = ActiveInd FROM PdmFeatureFlag WHERE FeatureNm = 'IAO_ENABLED_FLAG'--aaugus2x - RBAC
    
 IF @item_rev IS NULL     
  SELECT @item_rev = max(item_rev) FROM item_revision WHERE item_cde = @item_cde    
      
 SELECT @total_ct = count(*) FROM item_revision WHERE item_cde = @item_cde AND item_rev = @item_rev    
    
     
 CREATE TABLE #temp    
 (item_cde varchar(21),item_rev char(2),dsc nvarchar(256), cmdt_mgr_cde varchar(2),     
  cmdt_cde_dsc varchar(60), cmdt_cde varchar(10), proj_cde varchar(15),     
  commodity_manager varchar(80), eng_rev varchar(2), de_proj_cde varchar(15),    
  std_cst int, filtered_ct int, total_ct int, related_aco_url VARCHAR(500),  design_group VARCHAR(16), restricted_mfr_ct int) -- MSRINIVX - 04/16/2013 START# 7919359    
    
 INSERT INTO #temp (total_ct) VALUES (@total_ct)    
    
 SET @where  = ' WHERE i.item_cde = ''' + @item_cde + ''' AND ir.item_rev = ''' +  @item_rev   + ''' '    
 IF   @usage = 'B' --item bundle    
  SET @where  = @where + ' AND i.make_buy_cde != ''M''  ' 
 IF @IaoActiveInd = 'Y'
	BEGIN
		SET @where = @where + ' AND (i.DivisionId IN (' + CAST(ISNULL(@DivisionId, 0) AS VARCHAR(10)) + ', 30)) AND i.DivisionId IS NOT NULL' --aaugus2x - RBAC
	END
    
    
 SET @sql =  'UPDATE #temp '    + char(10)    
  + 'SET item_cde = i.item_cde, '   + char(10)    
  + 'item_rev = ir.item_rev, '   + char(10)    
  + 'dsc = ISNULL(NULLIF(i.dsc_full,''''),i.dsc), '   + char(10)    
  + 'cmdt_mgr_cde = cm.cmdt_mgr_cde, '  + char(10)       
  + 'cmdt_cde_dsc = cc.cmdt_cde_dsc, '   + char(10)    
  + 'cmdt_cde = cc.cmdt_cde,   '  + char(10)    
  + 'proj_cde = ir.proj_cde,   '  + char(10)    
  + 'commodity_manager = u.bookname, '   + char(10)    
  + 'eng_rev = i.eng_rev, '    + char(10)    
  + 'de_proj_cde = de.proj_cde, '   + char(10)    
  + 'std_cst = isnull(i.std_cst,0), '  + char(10)    
  + 'design_group = budg.short_nme, '  + CHAR(10) -- MSRINIVX - 04/16/2013 START# 7919359    
  + 'related_aco_url = '''''  + CHAR(10)    
   + ' FROM     item i   '        + CHAR(10)    
   + ' JOIN     item_revision ir  ON (i.item_cde = ir.item_cde)       ' + CHAR(10)    
   + ' JOIN        bus_unit_dsgn_grp budg ON (ir.bus_unit_idn = budg.bus_unit_idn) ' + CHAR(10)    
   + ' LEFT OUTER JOIN item_type it   ON (i.item_typ_cde=it.item_typ_cde)   ' + CHAR(10)    
   + ' LEFT OUTER JOIN commodity_code cc  ON (i.comdt_cde = cc.cmdt_cde)        ' + CHAR(10)    
   + ' LEFT OUTER JOIN  commodity_manager cm  ON (cm.cmdt_mgr_cde = cc.cmdt_mgr_cde)' + CHAR(10)    
   + ' LEFT OUTER JOIN  users u   ON (u.usr_acct = cm.usr_acct)         ' + CHAR(10)    
   + ' LEFT OUTER JOIN  development_effort de  ON (ir.proj_cde = de.proj_cde )       ' + CHAR(10)    
   + @where    
    
 EXEC(@sql)    
    
 SELECT  @filtered_ct = count(item_cde)     
 FROM  #temp    
 WHERE  item_cde IS NOT NULL  

 -- Check if item was blocked by RBAC restrictions --aaugus2x - RBAC
IF @IaoActiveInd = 'Y' AND @filtered_ct = 0 AND @total_ct > 0
BEGIN
     -- Check if item exists but doesn't match division criteria
     DECLARE @item_exists_different_division INT
     SELECT @item_exists_different_division = COUNT(*)
     FROM item i
     JOIN item_revision ir ON i.item_cde = ir.item_cde
     WHERE i.item_cde = @item_cde 
     AND ir.item_rev = @item_rev
     AND (@usage != 'B' OR i.make_buy_cde != 'M') -- Item would be valid if not for RBAC
     AND (i.DivisionId NOT IN (ISNULL(@DivisionId, 0), 30) OR i.DivisionId IS NULL)
     IF @item_exists_different_division > 0
     BEGIN
         -- Set total_ct to -1 to indicate RBAC blocked (permission issue)
         UPDATE #temp SET total_ct = -1
     END
END
  
 --CHG12155128 - Selecting existig associated restricted mfr & parts count to block if ACO itembundled
SELECT @restaml_ct = count(*) FROM approved_mfr_part amp  
 join #temp t on t.item_cde = amp.item_cde  
 Left Join restricted_mfr rm on rm.mfr_nbr = amp.mfr_nbr and rm.curr_actv_ind = 'Y'  
 Left join restricted_mfr_parts rmp on rmp.mfr_part_nbr = amp.mfg_part_nbr and rmp.curr_actv_ind = 'Y'  
 where   
 (rm.mfr_nbr is not null or rmp.mfr_part_nbr is not null)  
  
 UPDATE #temp SET restricted_mfr_ct = @restaml_ct    
    
 UPDATE #temp SET filtered_ct = @filtered_ct    
    
 SET NOCOUNT OFF    
     
 SELECT * FROM #temp    
    
 IF @@error != 0 BEGIN    
  SET @msg = 'Error validating item sp_aco_dtl_verify_item.'    
   GOTO ERR_LINE    
 END    
     
 RETURN    
    
        
ERR_LINE:     
    SELECT -1 AS error, @msg as message    
 RETURN    
    END    
    
GO

GRANT EXECUTE ON [dbo].[sp_aco_dtl_verify_item] TO [ESPEED] AS [dbo]
GO
