USE [Pdm]
GO
/****** Object:  StoredProcedure [ItemSiteMaint].[ItemSiteMaintItemClassGet]    Script Date: 03-12-2025 12:18:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [ItemSiteMaint].[ItemSiteMaintItemClassGet]
@wwid varchar(30)
AS
/*******************************************************************************      
* Name: Item Site Maintenance - Get Item Class/Type 
* Author: msabudix    
* Modification History      
* Date       Person              Description      
* ---------- ------------------- -----------------------------------------      
* 09/25/2025  msabudix          CHG117157675 - Created    
* 06/12/2025  Francis          TWC5924-1892:ItemSiteMaint     
*******************************************************************************/
BEGIN
	SET NOCOUNT ON

    SELECT
        ic.ClassCd AS Id,
        ic.ClassDsc AS Name
    FROM
        [ItemBom].[ItemClassTemp] ic
        JOIN [ItemBom].[ItemClassMaterialType] icmt ON ic.ClassCd = icmt.ClassCd
        JOIN [Security].[RefIaoDivisionRole] ref on ref.DivisionId=ic.DivisionId
        JOIN SpeedCore.[Security].[UserPreference] up on up.SettingValue=ref.RoleNme collate SQL_Latin1_General_CP850_BIN
    WHERE
        ic.ActiveCd = 'Y'
        AND (
            ic.OwningSystemCd <> 'SO'
            OR ic.OwningSystemCd IS NULL
        )
        AND icmt.MaterialTypeCd IN ('RAPP', 'FERT')
        AND ic.ParentClassCd IS NULL
        AND ic.ClassCd <> '1016'
        AND (
            ic.ClassDsc like 'UPI%'
			OR ic.ClassDsc like 'P%'
            OR ic.ClassDsc = 'PLACEHOLDER_IC'
            OR ic.ClassDsc = 'MOBILE_COMMS_TEST'
			OR ic.ClassDsc IN ('CPU', 'GPU', 'FPGA', 'WAFER', 'CHIPSETS_IC')
        )
        AND up.Wwid=@wwid AND up.RefPrefTypeKey='NGS_HOME_ACTIVE_IAO_ROLE'
    GROUP BY
        ic.ClassCd,
        ic.ClassDsc
    ORDER BY
        ic.ClassDsc ASC

END
