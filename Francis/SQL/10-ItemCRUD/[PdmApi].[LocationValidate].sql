USE [Pdm] 
GO 
DROP PROCEDURE IF EXISTS [PdmApi].[LocationValidate]
GO 
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [PdmApi].[LocationValidate]
(
	@AppName VARCHAR(127) = NULL,  
	@debug CHAR(1) = 'N' 
)
/******************************************************************************************************     
*** Purpose: Validate item location before creating the item.
			prerequisites: Temp tables #ItemUdt and #locationInfo
			called from procedure [PdmApi].[ItemCRUD]
			Item Location can only be INSERTED or DELETE; no UPDATE.
*** History: psaxen2x, 01/02/2018
             neeneeli, 08/28/2019 Validate if location exists when create new item revision. 
			 mtan6	08/28/2019 Fix join issue on invalid location combination
			 mtan6  02/24/2020 DE69140 Enhancement to allow delete location when create new rev item
			 wng5   04/23/2020 US613395 Handle PLM Location without use CrudType
			 mtan6	05/29/2020 DE80149 Fix bug for invalid location combination checking
			 mtan6  06/01/2020 DE80357 Fix ResultMessage is not null issue
			 mtan6  06/01/2020 DE80357 Fix bug to support multiple items
			 saurbahx 10/13/2025 TWC5924-1504 serialized location for PDM API
*** Copyright 2017 Intel Corporation, all rights reserved.      
*******************************************************************************************************/ 
AS
BEGIN
	SET NOCOUNT ON;
	--saurbahx start - 10/13/2025 - TWC5924-1504 - serialized location for PDM API, IAO Feature Flag and Cross Site Indicator
	DECLARE @IaoActiveInd VARCHAR(1) = (SELECT ActiveInd FROM Pdm.Framework.PdmFeatureFlag WHERE FeatureNm = 'IAO_ENABLED_FLAG')
	Declare @Cross_Site_Ind varchar(20)
	SET @Cross_Site_Ind =(SELECT UPPER(ValueTxt) FROM #SAPCharacteristics WHERE AttributeNm = 'CROSS_SITE_IND')
	--saurbahx end
	DECLARE @ResultMessage varchar(max) = ''

	-- if no valid item exists, dont validate further
	IF NOT EXISTS(SELECT 1 FROM #ItemUdt WHERE ResultStatus <> 'Invalid')
	BEGIN
		RETURN;
	END

	-- Common check for item create and item update begin --
	-- validate the CRUD TYPE - only Create or Delete
	DELETE li
	FROM #locationInfo li
	WHERE ISNULL(li.PlantCode, '') = '' AND ISNULL(li.SAPPlantCode, '') = ''

	UPDATE P 
	SET P.ResultStatus = 'Invalid',
		P.ResultMessage = CONCAT('Invalid Location CrudType [', li.CrudType, '], ')
	FROM #locationInfo li 
		JOIN #ItemUdt P ON li.RowId = P.RowId
	WHERE li.CrudType NOT IN ('CREATE', 'DELETE')
		AND ResultStatus <> 'Invalid'
		AND ISNULL(PlantCode,'') <> ''

	IF (@AppName <> 'PLM') 
	BEGIN
		-- validate that if the item crud is create then location crud should be create only.
		UPDATE P 
		SET P.ResultStatus = 'Invalid',
			P.ResultMessage = CONCAT('Invalid location CrudType [', li.CrudType ,'] for Item [', P.CrudType,'], ')
		FROM #ItemUdt P 
			JOIN #locationInfo li ON li.RowId = P.RowId
		WHERE P.CrudType = 'CREATE' 
			AND li.CrudType <> 'CREATE'
			AND ResultStatus <> 'Invalid'
	END

	IF (@AppName = 'PLM')
	BEGIN
	--saurbahx start - 10/13/2025 - TWC5924-1504 - serialized location for PDM API
		IF @IaoActiveInd = 'Y' AND @Cross_Site_Ind IN ('Y','YES')
		BEGIN

			-- Validate PlantId is provided and valid (mandatory for IAO)
			UPDATE P 
			SET P.ResultStatus = 'Invalid',
				P.ResultMessage = CONCAT(ISNULL(P.ResultMessage, ''), 'PlantId is required.')
			FROM #ItemUdt P 
				JOIN #locationInfo li ON li.RowId = P.RowId
			WHERE li.CrudType = 'CREATE'
				AND (li.PlantId IS NULL OR li.PlantId <= 0)
				AND P.ResultStatus <> 'Invalid'

			-- Validate PlantId exists in ManufacturingPlant table
			SELECT @ResultMessage = COALESCE(@ResultMessage + ', ', '') + 
								CONCAT('Invalid Location Mapping with Plant Code [', li.PlantCode, '] and Plant Id [', li.PlantId, ']')
			FROM #ItemUdt P 
				JOIN #locationInfo li ON li.RowId = P.RowId
				LEFT JOIN [Framework].[ManufacturingPlant] mp ON mp.PlantCd = li.PlantCode
						AND ISNULL(mp.SapPlantCd, '') = ISNULL(li.SAPPlantCode, '')
			WHERE li.CrudType = 'CREATE'
					AND li.PlantId IS NOT NULL
					AND li.PlantId != mp.SapPlantId

			IF (ISNULL(@ResultMessage,'') <> '')
			BEGIN
				UPDATE P 
				SET P.ResultStatus = 'Invalid',
					P.ResultMessage = CASE WHEN LEFT(@ResultMessage, 2) = ', ' THEN RIGHT(@ResultMessage, LEN(@ResultMessage)-2) ELSE @ResultMessage END
				FROM #ItemUdt P 
					JOIN #locationInfo li ON li.RowId = P.RowId
					LEFT JOIN [Framework].[ManufacturingPlant] mp ON mp.PlantCd = li.PlantCode
							AND ISNULL(mp.SapPlantCd, '') = ISNULL(li.SAPPlantCode, '')
				WHERE li.CrudType = 'CREATE'
					AND li.PlantId IS NOT NULL
					AND li.PlantId != mp.SapPlantId
					AND P.ResultStatus <> 'Invalid'
			END
			
			--Validate the Location Combination of Plant Code and SAP Plant Code
			SELECT @ResultMessage = COALESCE(@ResultMessage + ', ', '') + 
							    CONCAT('Invalid Location Combination of Plant Code [', li.PlantCode, '] and SAP Plant Code [', li.SAPPlantCode, ']')
			FROM #ItemUdt P 
			JOIN #locationInfo li ON li.RowId = P.RowId
			AND NOT EXISTS (
			SELECT 1 FROM Framework.ClassSegment C 
			JOIN [Framework].[ManufacturingPlant] mp ON mp.PlantTypeCd = C.PlantTypeCd 
				AND mp.PlantCd = li.PlantCode AND ISNULL(mp.SapPlantCd, '') = ISNULL(li.SAPPlantCode, '')
				WHERE P.ClassCd = C.ClassCd)			

			IF (ISNULL(@ResultMessage,'') <> '')
			BEGIN
				UPDATE P 
				SET P.ResultStatus = 'Invalid',
				P.ResultMessage = CASE WHEN LEFT(@ResultMessage ,2) =', ' THEN RIGHT(@ResultMessage,LEN(@ResultMessage)-2) ELSE @ResultMessage END
				FROM #ItemUdt P 
					JOIN #locationInfo li ON li.RowId = P.RowId
					AND NOT EXISTS (
				SELECT 1 FROM Framework.ClassSegment C 
					JOIN [Framework].[ManufacturingPlant] mp ON mp.PlantTypeCd = C.PlantTypeCd 
					AND mp.PlantCd = li.PlantCode AND ISNULL(mp.SapPlantCd, '') = ISNULL(li.SAPPlantCode, '')
				WHERE P.ClassCd = C.ClassCd)
			
			END
		END
		ELSE
		BEGIN
		--saurbahx end
		SELECT @ResultMessage = COALESCE(@ResultMessage + ', ', '') + 
							    CONCAT('Invalid Location Combination of Plant Code [', li.PlantCode, '] and SAP Plant Code [', li.SAPPlantCode, ']')
		FROM #ItemUdt P 
			JOIN #locationInfo li ON li.RowId = P.RowId
			AND NOT EXISTS (
			SELECT 1 FROM Framework.ClassSegment C 
			JOIN [Framework].[ManufacturingPlant] mp ON mp.PlantTypeCd = C.PlantTypeCd 
				AND mp.PlantCd = li.PlantCode AND ISNULL(mp.SapPlantCd, '') = ISNULL(li.SAPPlantCode, '')
				WHERE P.ClassCd = C.ClassCd)			

		IF (ISNULL(@ResultMessage,'') <> '')
		BEGIN
			UPDATE P 
			SET P.ResultStatus = 'Invalid',
				P.ResultMessage = CASE WHEN LEFT(@ResultMessage ,2) =', ' THEN RIGHT(@ResultMessage,LEN(@ResultMessage)-2) ELSE @ResultMessage END
			FROM #ItemUdt P 
			JOIN #locationInfo li ON li.RowId = P.RowId
			AND NOT EXISTS (
			SELECT 1 FROM Framework.ClassSegment C 
			JOIN [Framework].[ManufacturingPlant] mp ON mp.PlantTypeCd = C.PlantTypeCd 
				AND mp.PlantCd = li.PlantCode AND ISNULL(mp.SapPlantCd, '') = ISNULL(li.SAPPlantCode, '')
				WHERE P.ClassCd = C.ClassCd)
			
		END
		END
	END
	ELSE
	BEGIN
		-- validate the Plant code
		UPDATE P 
		SET P.ResultStatus = 'Invalid',
			P.ResultMessage = CONCAT('Invalid Location Plant Code [', li.PlantCode, '], ')
		FROM #ItemUdt P 
			JOIN #locationInfo li ON li.RowId = P.RowId
			LEFT JOIN [Framework].[ManufacturingPlant] mp ON mp.PlantCd = li.PlantCode 
		WHERE li.CrudType = 'CREATE'
			AND mp.PlantCd IS NULL
			AND ResultStatus <> 'Invalid'
		
		-- validate plant code and SAP plant code with class code
		SELECT @ResultMessage = COALESCE(@ResultMessage + ', ', '') + 
							    CONCAT('Invalid Location Combination of Plant Code [', li.PlantCode, '] and SAP Plant Code [', li.SAPPlantCode, ']')
		FROM #ItemUdt P 
			JOIN #locationInfo li ON li.RowId = P.RowId
			AND NOT EXISTS (
			SELECT 1 FROM Framework.ClassSegment C 
			JOIN [Framework].[ManufacturingPlant] mp ON mp.PlantTypeCd = C.PlantTypeCd 
				AND mp.PlantCd = li.PlantCode AND ISNULL(mp.SapPlantCd, '') = ISNULL(li.SAPPlantCode, '')
				WHERE P.ClassCd = C.ClassCd)			

		IF (ISNULL(@ResultMessage,'') <> '')
		BEGIN
			UPDATE P 
			SET P.ResultStatus = 'Invalid',
				P.ResultMessage = CASE WHEN LEFT(@ResultMessage ,2) =', ' THEN RIGHT(@ResultMessage,LEN(@ResultMessage)-2) ELSE @ResultMessage END
			FROM #ItemUdt P JOIN #locationInfo li ON li.RowId = P.RowId
			AND NOT EXISTS (
			SELECT 1 FROM Framework.ClassSegment C 
			JOIN [Framework].[ManufacturingPlant] mp ON mp.PlantTypeCd = C.PlantTypeCd 
				AND mp.PlantCd = li.PlantCode AND ISNULL(mp.SapPlantCd, '') = ISNULL(li.SAPPlantCode, '')
				WHERE P.ClassCd = C.ClassCd)	
			WHERE li.CrudType = 'CREATE'
			AND ResultStatus <> 'Invalid'
		END
	END
	
	-- Common check for item create and item update end --
	/*
	IF (@AppName = 'PLM')
	BEGIN
		-- remove such record from the location temp table, which plantId already exists for the item.
		DELETE li
		FROM #locationInfo li
				JOIN #ItemUdt P ON li.RowId = P.RowId
				JOIN Framework.ClassSegment C ON P.ClassCd = C.ClassCd 
				JOIN [Framework].[ManufacturingPlant] mp ON C.PlantTypeCd = mp.PlantTypeCd
				JOIN ItemBom.ItemPlant IP ON IP.PlantId = mp.PlantId AND IP.ItemCd = P.ItemCd
			WHERE li.CrudType = 'CREATE'
				AND P.CrudType = 'CREATE'
				AND P.ResultStatus <> 'Invalid'
				AND P.ItemCd = IP.ItemCd
				AND mp.PlantCd = li.PlantCode
				AND P.ItemCd IS NOT NULL 

		UPDATE P 
		SET P.ResultStatus = 'Invalid',
			P.ResultMessage = CONCAT('Invalid location CrudType [', li.CrudType ,'] for Item [', P.CrudType,'], ')
		FROM #ItemUdt P 
			JOIN #locationInfo li ON li.RowId = P.RowId
		WHERE P.CrudType = 'CREATE' 
			AND li.CrudType <> 'CREATE'
			AND ResultStatus <> 'Invalid'
			AND (ISNULL(P.ItemCd, '') = '') 
	END 
	*/
	-- Check for item update only begin --
	IF (@AppName <> 'PLM')
	BEGIN	
		-- we are not setting it invalid. but we are telling user that it is already existing
		UPDATE P 
		SET 
			P.ResultMessage = CONCAT('Plant Code [', li.PlantCode, '] and SAP Plant Code [', li.SAPPlantCode, '] already exists for Item.')
		FROM #ItemUdt P 
			JOIN #locationInfo li ON li.RowId = P.RowId
			LEFT JOIN Framework.ClassSegment C ON P.ClassCd = C.ClassCd 
			LEFT JOIN [Framework].[ManufacturingPlant] mp ON C.PlantTypeCd = mp.PlantTypeCd
			LEFT JOIN ItemBom.ItemPlant IP ON IP.PlantId = mp.PlantId AND IP.ItemCd = P.ItemCd
		WHERE li.CrudType = 'CREATE'
			AND P.CrudType = 'UPDATE'
			AND P.ResultStatus <> 'Invalid'
			AND ISNULL(P.ItemCd, '') = ISNULL(IP.ItemCd, '')
			AND ISNULL(mp.PlantCd, '') = ISNULL(li.PlantCode, '')

		-- no error check if the plant does not exists; just a message
		UPDATE P 
		SET 
			P.ResultMessage = CONCAT('Plant Code [', li.PlantCode, '] and SAP Plant Code [', li.SAPPlantCode, '] does not exists for Item, ')
		FROM #ItemUdt P 
			JOIN #locationInfo li ON li.RowId = P.RowId
			LEFT JOIN Framework.ClassSegment C ON P.ClassCd = C.ClassCd 
			LEFT JOIN [Framework].[ManufacturingPlant] mp ON C.PlantTypeCd = mp.PlantTypeCd 
				AND mp.SapPlantCd = li.SAPPlantCode
				AND mp.PlantCd = li.PlantCode
			LEFT JOIN ItemBom.ItemPlant IP ON IP.PlantId = mp.PlantId AND IP.ItemCd = P.ItemCd
		WHERE li.CrudType = 'DELETE' -- location CRUD
			AND P.CrudType = 'UPDATE' -- item CRUD
			AND P.ResultStatus <> 'Invalid'
			AND (ISNULL(mp.PlantCd, '') <> ISNULL(li.PlantCode, '') 
			OR ISNULL(mp.SapPlantCd, '') <> ISNULL(li.SAPPlantCode, '')
			OR C.PlantTypeCd <> mp.PlantTypeCd 
			OR ISNULL(P.ItemCd, '') <> ISNULL(IP.ItemCd, ''))

		-- remove such record from the location temp table, which plantId already exists for the item.
		DELETE li
		FROM #locationInfo li
			JOIN #ItemUdt P ON li.RowId = P.RowId
			LEFT JOIN Framework.ClassSegment C ON P.ClassCd = C.ClassCd 
			LEFT JOIN [Framework].[ManufacturingPlant] mp ON C.PlantTypeCd = mp.PlantTypeCd
			LEFT JOIN ItemBom.ItemPlant IP ON IP.PlantId = mp.PlantId AND IP.ItemCd = P.ItemCd
		WHERE li.CrudType = 'CREATE'
			AND P.CrudType = 'UPDATE'
			AND P.ResultStatus <> 'Invalid'
			AND ISNULL(P.ItemCd, '') = ISNULL(IP.ItemCd, '')
			AND ISNULL(mp.PlantCd, '') = ISNULL(li.PlantCode, '')
	END

	-- Check for item update only end --
	-- No Validation for PLM, allow to save. 
	if @AppName = 'PLM'
	BEGIN
		UPDATE #ItemUdt
		SET ResultStatus = 'Success'		
		WHERE ResultStatus = 'Invalid'
	END
	
	IF @debug = 'Y'
	BEGIN
		SELECT '[PdmApi].[LocationValidate]' AS 'Proc Name', * FROM #ItemUdt WHERE ResultStatus = 'Invalid'
	END

	SET NOCOUNT OFF;
END                        


GO