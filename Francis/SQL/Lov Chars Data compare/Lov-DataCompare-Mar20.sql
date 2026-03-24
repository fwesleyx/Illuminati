/*
Author:Francis/Mohan
Date:24 Mar 2026
Description:To Test LOV comparison
*/
USE workdb
GO
--====================================================================================
-- TO Find Newly Inserted LOVs 
--====================================================================================
SELECT DISTINCT
	  [Characteristic Id]
	, [Speed Characteristic Name]
	, [S4 Characteristic Name]
	, [Characteristic Division]
	, [Speed Value Text]
	, [S4 Value Text]
	, [Speed Value Description]
	, [S4 Value Description]
	, [New List Of Value]
	, 'To be Inserted'
FROM
	workdb..lov_analysis_report_march20 rep 
	LEFT OUTER JOIN speed.dbo.uda_validation_list uvl ON 
		uvl.att_idn = rep.[Characteristic Id]
		AND uvl.val_txt = [S4 Value Text]
		AND uvl.dsc = [S4 Value Description] 
WHERE 
	--rep.[Class Division] = 20 -- IC
	--AND 
	rep.[New List Of Value] = 'Y'
	AND rep.[Characteristic Id] IS NOT NULL
	AND [S4 Value Text] IS NOT NULL
	AND [S4 Value Description] IS NOT NULL
	AND (uvl.val_txt IS NULL AND uvl.dsc IS NULL)
ORDER BY rep.[S4 Characteristic Name], rep.[S4 Value Text]
 
-- For Validation Only
--SELECT * FROM #NewLOV src
--WHERE
--	EXISTS (SELECT * FROM speed.dbo.uda_validation_list srcx
--			WHERE
--				src.[Characteristic Id] = srcx.att_idn
--				AND src.[S4 Value Text] = srcx.val_txt
--				AND src.[S4 Value Description] = srcx.dsc
--			)
--SELECT 
--	DISTINCT
--	  [Characteristic Id]
--	, [Speed Characteristic Name]
--	, [S4 Characteristic Name]
--	, [Characteristic Division]
--	, [Speed Value Text]
--	, [S4 Value Text]
--	, [Speed Value Description]
--	, [S4 Value Description]
--	, [New List Of Value]
-- FROM
--	workdb..lov_analysis_report_new rep 
--WHERE 
--	NOT EXISTS (
--		SELECT *
--		FROM
--			speed.dbo.uda_validation_list uvl 
--		WHERE
--			rep.[Characteristic Id] = uvl.att_idn
--			AND uvl.val_txt = rep.[S4 Value Text]
--			AND uvl.dsc		= rep.[S4 Value Description] 
--		)
--AND 
--	rep.[Characteristic Id] IS NOT NULL
--	--AND rep.[Class Division] = 20 -- IC
--	AND rep.[New List Of Value] = 'Y'
--ORDER BY rep.[S4 Characteristic Name], rep.[S4 Value Text]
--------------------=======
--====================================================================================
--2. For Removal -- Find the LOVs marked for deletion but still active.
--====================================================================================
 
-- total marked for deletion = 603
-- curr_actv_ind = 'N' = 11
-- curr_actv_ind = 'Y' = 592
SELECT 
	  uvl.curr_actv_ind
	, [Characteristic Id]
	, [Speed Characteristic Name]
	, [S4 Characteristic Name]
	, [Characteristic Division]
	, [Speed Value Text]
	, [S4 Value Text]
	, [Speed Value Description]
	, [S4 Value Description]
	, [Remove List Of Value]
    , 'Need To be Removed'
FROM
	workdb..lov_analysis_report_march20 rep 
	JOIN speed.dbo.uda_validation_list uvl ON 
		uvl.att_idn = rep.[Characteristic Id]
		AND uvl.val_txt = [S4 Value Text]
		AND uvl.dsc = [S4 Value Description] 
WHERE 
	--rep.[Class Division] = 10 -- IC
	--AND 
	rep.[Remove List Of Value] = 'Y'
	AND rep.[Characteristic Id] IS NOT NULL
	AND [S4 Value Text] IS NOT NULL
	AND [S4 Value Description] IS NOT NULL
	--AND uvl.curr_actv_ind = 'N'
ORDER BY rep.[S4 Characteristic Name], rep.[S4 Value Text]
 
 
--====================================================================================
--3. Update LOV = Y
--====================================================================================
SELECT DISTINCT
	  [Characteristic Id]
	, [Speed Characteristic Name]
	, [S4 Characteristic Name]
	, [Characteristic Division]
	, [Speed Value Text]
	, [S4 Value Text]
	, [Speed Value Description]
	, [S4 Value Description]
	, rep.[Update List Of Value Text]
	, uvl.val_txt
    , 'List Of Value To be Updated'
 
FROM
	workdb..lov_analysis_report_march20 rep 
	JOIN speed.dbo.uda_validation_list uvl ON
				uvl.att_idn = rep.[Characteristic Id]
				AND uvl.val_txt = [Speed Value Text]
WHERE
	rep.[Update List Of Value Text] = 'Y'
	AND rep.[Speed Value Text] != rep.[S4 Value Text]
--====================================================================================
SELECT DISTINCT
	  [Characteristic Id]
	, [Speed Characteristic Name]
	, [S4 Characteristic Name]
	, [Characteristic Division]
	, [Speed Value Text]
	, [S4 Value Text]
	, [Speed Value Description]
	, [S4 Value Description]
	, [Update List Of Value Description]
	, uvl.dsc
    , 'Need List Of Value Description Updated'
FROM
	workdb..lov_analysis_report_march20 rep 
	JOIN speed.dbo.uda_validation_list uvl ON
				uvl.att_idn = rep.[Characteristic Id]
				AND uvl.val_txt = rep.[S4 Value Text]
				AND uvl.dsc = [Speed Value Description]
WHERE
	rep.[Update List Of Value Description] = 'Y'
	AND rep.[Speed Value Description] != rep.[S4 Value Description]