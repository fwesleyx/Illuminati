USE [speed]
GO

/****** Object:  StoredProcedure [dbo].[wsp_idet_excel_sap_meta_sql]    Script Date: 2/10/2026 3:46:28 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[wsp_idet_excel_sap_meta_sql]
GO

/****** Object:  StoredProcedure [dbo].[wsp_idet_excel_sap_meta_sql]    Script Date: 2/10/2026 3:46:29 PM ******/
SET ANSI_NULLS ON
GO

ALTER PROCEDURE dbo.wsp_idet_excel_sap_meta_sql   
(@slct NVARCHAR(max) OUTPUT  
,@in NVARCHAR(max) OUTPUT  
,@debug CHAR(1) = 'N'  
) AS  
/*********************************************************************************  
*** Purpose: IDET Excel Live: Build Dynamic SELECT for SAP Char Worksheet MetaData  
*** History: smwoodwo 09/03/09 created  
*** fwesleyx 06/05/2026 TWC5924-2920 Remove Product Visibility attribute 
*** Copyright 2009 Intel Corporation, all rights reserved.  
*********************************************************************************/  
BEGIN  
 SET NOCOUNT ON  
 DECLARE @sort_ord INT  
  ,@att_idn  INT  
  ,@att_chr  VARCHAR(30)  
  ,@clm_nme  VARCHAR(40)  
  
 CREATE TABLE #clm_sort (sort_ord INT IDENTITY, att_idn INT)  
  
 INSERT #clm_sort (att_idn)  
  SELECT sap.att_idn  
  FROM #idet_sap_meta AS sap  
  LEFT JOIN uda_definition AS ud  
    ON ud.att_idn = sap.att_idn  
   AND ud.curr_actv_ind = 'Y'  
  WHERE ISNULL(sap.att_nme, ISNULL(ud.att_nme, '')) <> 'MM-PROD-VISIBILITY'  
  ORDER BY sap.sort_grp, sap.sort_ord, sap.hdr_nme
  
 SET @slct = ''  
 SET @in   = ''  
   
 SELECT @sort_ord = MIN(sort_ord) FROM #clm_sort  
   
 WHILE @sort_ord IS NOT NULL  
 BEGIN  
  SELECT @att_idn = att_idn FROM #clm_sort WHERE sort_ord = @sort_ord  
  SET @att_chr = CONVERT(VARCHAR, @att_idn)  
  IF (@att_idn > 0   ) SET @clm_nme = 'att_' + @att_chr  
  IF (@att_idn = -667) SET @clm_nme = 'crud_typ'    
  IF (@att_idn = -668) SET @clm_nme = 'item_cde'  
  SET @slct = @slct + ' ,pvt.[' + @att_chr + '] AS [' + @clm_nme + ']'  
  IF @in != '' SET @in = @in + ', '  
  SET @in = @in + '[' + @att_chr + ']'  
  
  SELECT @sort_ord = MIN(sort_ord) FROM #clm_sort WHERE sort_ord > @sort_ord  
 END  
  
 DROP TABLE #clm_sort  
END  