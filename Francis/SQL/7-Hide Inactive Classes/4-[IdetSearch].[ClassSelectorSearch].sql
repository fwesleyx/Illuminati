IF EXISTS (SELECT * FROM dbo.sysobjects where id = object_id(N'[IdetSearch].[ClassSelectorSearch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [IdetSearch].[ClassSelectorSearch]
GO
	
SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [IdetSearch].[ClassSelectorSearch] @text VARCHAR(64) = NULL, @ParentClassCd CHAR(4) = NULL 
AS
/*******************************************************************************
* Name: IDET Advanced Search Class Selector Search
* Author: ngcx
* Modification History
* Date       Person              Description
* ---------- ------------------- -----------------------------------------
* 04/18/2025  ngcx	         	 Created 
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
			SELECT TOP 1001 ClassCd FROM [Search].[Class] WHERE ParentClassCd = @ParentClassCd and ActiveInd=1 ORDER BY ClassDsc
	END ELSE IF (@text IS NULL) BEGIN
		INSERT #rslts (ClassCd)
			SELECT TOP 1001 ClassCd FROM [Search].[Class] WHERE ActiveInd=1 ORDER BY ClassDsc
	END ELSE IF (len(isnull(@text, '')) <= 18) BEGIN
		SET @text_shrt  = @text

		INSERT #rslts (ClassCd)
			SELECT TOP 1001 ClassCd FROM [Search].[Class] WHERE ClassDsc LIKE @text_shrt and ActiveInd=1 ORDER BY ClassDsc
	END ELSE BEGIN
		INSERT #rslts (ClassCd)
			SELECT TOP 1001 ClassCd FROM [Search].[Class] WHERE ClassDsc LIKE @text and ActiveInd=1 ORDER BY ClassDsc
	END

	UPDATE #rslts SET HasChildren = 1
	FROM #rslts
	JOIN [Search].[Class] ON Class.ParentClassCd = #rslts.ClassCd


	SELECT NULL [SearchResults]
		,rtrim(#rslts.ClassCd) [value]
		,Class.ClassDsc [text]
		,#rslts.HasChildren
	FROM #rslts
	JOIN [Search].[Class] ON Class.ClassCd = #rslts.ClassCd
	WHERE Class.ActiveInd=1
	ORDER BY Class.ClassDsc
END


GO