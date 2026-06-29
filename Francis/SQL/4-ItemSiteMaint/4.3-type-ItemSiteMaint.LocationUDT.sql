USE [Pdm]
GO

/****** Object:  UserDefinedTableType [ItemSiteMaint].[LocationUDT]    Script Date: 16-12-2025 20:51:57 ******/
CREATE TYPE [ItemSiteMaint].[LocationUDT] AS TABLE(
	[plant_idn] [int] NULL,
	[begin_date] [smalldatetime] NULL,
	[end_date] [smalldatetime] NULL,
	[starting_site_ind] [CHAR] NULL
)
GO
