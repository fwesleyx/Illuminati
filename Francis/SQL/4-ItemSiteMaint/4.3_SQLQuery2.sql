exec [ItemSiteMaint].[ItemSiteMaintItemClassGet] @wwid='12320760'
use Pdm
go
DECLARE @wwid varchar
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
        AND up.Wwid='12320760' AND up.RefPrefTypeKey='NGS_HOME_ACTIVE_IAO_ROLE'
    GROUP BY
        ic.ClassCd,
        ic.ClassDsc
    ORDER BY
        ic.ClassDsc ASC

DECLARE @usr_acct varchar(30) = '12320760'  
DECLARE @DivisionId tinyint
DECLARE @DescriptorId INT        

			 DECLARE @BusinessUnitId INT 

			 DECLARE @RoleCount  TINYINT = 0--aaugus2x - CHG11399939  

			 DECLARE @IAOBusinessUnitNm   VARCHAR(16)  = 'IAO'        

             DECLARE @NgsPreferencesIaoKey  VARCHAR(40) = 'NGS_HOME_ACTIVE_IAO_ROLE'

				 -- Retrieve NGS Business Unit Id for Business Unit = IAO        

				SELECT @BusinessUnitId = BusinessUnitId        

				FROM [Framework].[Core_BusinessUnit]        

				WHERE BusinessUnitNm = @IAOBusinessUnitNm        

				-- Retrieve NGS Security Descriptor Id for BusinessUnitId        

				SELECT @DescriptorId = DescriptorId        

				FROM [Security].[Descriptor]        

				WHERE DescriptorNm = 'BusinessUnitId'        

				-- Retrieve IAO Role Count based on user's wwid       

				SELECT @RoleCount = COUNT(*)        

				FROM [Security].[Core_UserRole] scur        

				JOIN [Security].[UserRoleDescriptor] surd ON scur.Wwid = surd.Wwid AND scur.RoleId = surd.RoleId AND surd.DescriptorId = @DescriptorId AND surd.DescriptorValue = @BusinessUnitId        

				WHERE scur.Wwid = @usr_acct        

				-- Identify active IAO role from NGS Workspace Preferences if @Wwid has 2 IAO roles        

				IF(@RoleCount = 2)        

				BEGIN        

					SELECT @DivisionId = sref.DivisionId        

					FROM [Security].[UserPreference] sup      

					JOIN [Security].[RefIaoDivisionRole] sref ON sref.RoleNme = sup.SettingValue COLLATE SQL_Latin1_General_CP1_CI_AS -- added to resolve collation conflict      

					WHERE Wwid = @usr_acct AND RefPrefTypeKey = @NgsPreferencesIaoKey        

				END        

				ELSE        

				-- Retrieve from NGS Role Assignment if @Wwid has only 1 IAO role        

				IF(@RoleCount = 1)        

				BEGIN        

					SELECT @DivisionId = sref.DivisionId        

					FROM [Security].[Core_UserRole] scur        

					JOIN [Security].[UserRoleDescriptor] surd ON scur.Wwid = surd.Wwid AND scur.RoleId = surd.RoleId AND surd.DescriptorId = @DescriptorId AND surd.DescriptorValue = @BusinessUnitId        

					JOIN [Security].[Core_Role] scr ON scur.RoleId = scr.RoleId      

					JOIN [Security].[RefIaoDivisionRole] sref ON sref.RoleNme = scr.RoleCd COLLATE SQL_Latin1_General_CP1_CI_AS -- added to resolve collation conflict      

					WHERE scur.Wwid = @usr_acct        

				END        

			
			select @DivisionId
		  
 