/*
Author:Francis/Mohan
Date:24 Mar 2026
Description:To Test Range comparison
*/
---------NEW Range Values only--------
select rep.[Item Class Division],rep.[Speed Item Class],rep.[Characteristic Division],rep.[New Range],
rep.[Characteristic Id],rep.[Speed Characteristic Name],[Speed Range],[S4 Range]
, CONVERT(VARCHAR(MAX), uvr.min_flt) + '-' + CONVERT(VARCHAR(MAX), uvr.max_flt) as uvr_range
,'Requires Insertion'
FROM workdb.dbo.range_analysis_report_march20 rep 
	JOIN speed.dbo.uda_validation_range uvr ON rep.[Characteristic Id] = uvr.att_idn
where [New Range] ='Y'
	AND [S4 Range] != CONVERT(VARCHAR(MAX), uvr.min_flt) + '-' + CONVERT(VARCHAR(MAX), uvr.max_flt)
---------REMOVE Range Values only--------
select rep.[Item Class Division],rep.[Speed Item Class],rep.[Characteristic Division],rep.[Remove Range],
rep.[Characteristic Id],rep.[Speed Characteristic Name],[Speed Range],[S4 Range]
, CONVERT(VARCHAR(MAX), uvr.min_flt) + '-' + CONVERT(VARCHAR(MAX), uvr.max_flt) as uvr_range
,'To be Removed'
FROM workdb.dbo.range_analysis_report_march20 rep 
	JOIN speed.dbo.uda_validation_range uvr ON rep.[Characteristic Id] = uvr.att_idn
where [Remove Range] ='Y'
	AND [S4 Range] != CONVERT(VARCHAR(MAX), uvr.min_flt) + '-' + CONVERT(VARCHAR(MAX), uvr.max_flt)    
---------UPDATE Range Values only--------
select rep.[Item Class Division],rep.[Speed Item Class],rep.[Characteristic Division],rep.[Update Range],
rep.[Characteristic Id],rep.[Speed Characteristic Name],[Speed Range],[S4 Range]
, CONVERT(VARCHAR(MAX), uvr.min_flt) + '-' + CONVERT(VARCHAR(MAX), uvr.max_flt) as uvr_range
,'To be Updated'
FROM workdb.dbo.range_analysis_report_march20 rep 
	JOIN speed.dbo.uda_validation_range uvr ON rep.[Characteristic Id] = uvr.att_idn
where [Update Range] ='Y'
	AND [S4 Range] != CONVERT(VARCHAR(MAX), uvr.min_flt) + '-' + CONVERT(VARCHAR(MAX), uvr.max_flt)