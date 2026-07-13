use env_cmply
go
SELECT
ec.item_cde,
ec.item_rev,
rl1.usr_def_attr AS Compliance_Type,
rl2.usr_def_attr AS Compliance_Status,
ec.*
FROM dbo.cmap_item_rev_comply ec
JOIN dbo.ref_lookup rl1
ON ec.cmply_typ_lkup_idn = rl1.lkup_idn
JOIN dbo.ref_lookup rl2
ON ec.cmply_val_lkup_idn = rl2.lkup_idn
WHERE ec.item_cde = '99DMK3'
AND ec.item_rev = '01';
