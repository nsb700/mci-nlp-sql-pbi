USE [nlp]
GO

IF EXISTS(
	SELECT *
	FROM INFORMATION_SCHEMA.TABLES
	WHERE	TABLE_SCHEMA = N'dbo'
	AND		TABLE_NAME   = N'dimDiag'
)
	DROP TABLE [dbo].[dimDiag]
GO

CREATE TABLE [dbo].[dimDiag](
	[dimDiagId] int identity(1, 1),
	[diagcodeLvl1] [varchar](50),
	[diagdescLvl1] [varchar](500)
) ON [PRIMARY]
GO
