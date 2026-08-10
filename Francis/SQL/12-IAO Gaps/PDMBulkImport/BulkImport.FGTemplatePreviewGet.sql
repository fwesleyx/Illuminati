  
CREATE PROCEDURE [BulkImport].[FGTemplatePreviewGet]  
    (  
      @Wwid INT = 10689746 ,  
      @BusinessUnitCd CHAR(2) ='3R' ,  
      @MaterialTypeCd CHAR(4) ='FERT',  
      @ClassCd CHAR(4) ='0004',  
      @StatusCd CHAR(1) = 'Z' ,  
   @debug CHAR(1) ='N'  
    )  
/************************************************************/  
-- Returns idet templates for specific user  
-- @Wwid = user id,   
-- @BusinessUnitCd = Design Group  
-- @MaterialTypeCd = Material Type  
-- @ClassCd = Item Class  
/************************************************************/  
AS  
    BEGIN  
        DECLARE @idsid VARCHAR(10) ,  
            @XmlDoc VARCHAR(MAX)  
  
        SELECT  @idsid = Idsid  
        FROM    Security.Users  
        WHERE   Wwid = @Wwid  
  
        SET @XmlDoc = '<ROOT><save_typ>tmpl_selector</save_typ><divdetail><bus_unit_idn>'  
            + @BusinessUnitCd + '</bus_unit_idn><mat_typ>' + @MaterialTypeCd  
            + '</mat_typ><type_class>' + @ClassCd + '</type_class><lvl_idn>'  
            + @StatusCd + '</lvl_idn></divdetail><idsid>' + @idsid  
            + '</idsid></ROOT>'  
    
  IF @debug='Y'  
   SELECT @XmlDoc AS xmldoc  
  
-- call IDET template procs based on user , bu and class selected  
        EXEC speed.dbo.prc_idet_tmpl_preview @XmlDoc = @XmlDoc  
  
    END  
  
   
/*   
EXEC BulkImport.FGTemplatePreviewGet @Wwid=10689746  
 ,@BusinessUnitCd='6I'  
 ,@MaterialTypeCd='FERT'  
 ,@ClassCd='0004'  
  
*/  