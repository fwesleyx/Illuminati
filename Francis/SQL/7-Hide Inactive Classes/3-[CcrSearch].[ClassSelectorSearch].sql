USE [Pdm]; 
GO 
IF EXISTS (SELECT * FROM dbo.sysobjects where id = object_id(N'[CcrSearch].[ClassSelectorSearch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [CcrSearch].[ClassSelectorSearch]
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [CcrSearch].[ClassSelectorSearch] @text VARCHAR(64) = NULL, @ParentClassCd CHAR(4) = NULL  AS   
/*******************************************************************************        
* Name:  [CcrSearch].[ClassSelectorSearch]   
* Author: wanx.ahmad.fikry.wan.effendy@intel.com
* !! IMPORTANT !! This stored procedure is for CCR Advanced Search use only, DO NOT MODIFY
* Copyright 2025 Intel Corporation, all rights reserved.
* Modification History        
* Date       Person              Description        
* ---------- ------------------- -----------------------------------------        
* 10/13/2025  wwaneffx          Created      
* 18/05/2026  fwesleyx   TWC5924-3019:Inactive Classes showing in class selector 	
*******************************************************************************/ 
BEGIN  
 SET NOCOUNT ON  
 DECLARE @text_shrt VARCHAR(18)  
 CREATE TABLE #rslts (ClassCd CHAR(4) NOT NULL, HasChildren BIT DEFAULT 0, PRIMARY KEY (ClassCd))  
  
 SET @text = [Framework_2_0].[Search].[GetSelectorFieldPattern](@text)  
  
 IF (@ParentClassCd IS NOT NULL)  
 BEGIN  
  INSERT #rslts (ClassCd)  
   SELECT TOP 1001 ClassCd FROM [CcrSearch].[Class] WHERE ParentClassCd = @ParentClassCd ORDER BY ClassDsc  
 END ELSE IF (@text IS NULL) BEGIN  
  INSERT #rslts (ClassCd)  
   SELECT TOP 1001 ClassCd FROM [Search].[Class] ORDER BY ClassDsc  
 END ELSE IF (len(isnull(@text, '')) <= 18) BEGIN  
  SET @text_shrt  = @text  
  
  INSERT #rslts (ClassCd)  
   SELECT TOP 1001 ClassCd FROM [CcrSearch].[Class] WHERE ClassDsc LIKE @text_shrt ORDER BY ClassDsc  
 END ELSE BEGIN  
  INSERT #rslts (ClassCd)  
   SELECT TOP 1001 ClassCd FROM [CcrSearch].[Class] WHERE ClassDsc LIKE @text ORDER BY ClassDsc  
 END  
  
 UPDATE #rslts SET HasChildren = 1  
 FROM #rslts  
 JOIN [CcrSearch].[Class] ON Class.ParentClassCd = #rslts.ClassCd  
  
  
 SELECT NULL [SearchResults]  
  ,RTRIM(#rslts.ClassCd) [value]  
  ,Class.ClassDsc [text]  
  ,#rslts.HasChildren  
 FROM #rslts  
 JOIN [CcrSearch].[Class] ON Class.ClassCd = #rslts.ClassCd  
 ORDER BY Class.ClassDsc  
END  
GO