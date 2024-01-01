USE [nlp]
GO

IF EXISTS(
	SELECT *
	FROM INFORMATION_SCHEMA.TABLES
	WHERE	TABLE_SCHEMA = N'dbo'
	AND		TABLE_NAME = N'nlpresultstg'
)
	DROP TABLE [dbo].[nlpresultstg]
GO

CREATE TABLE [dbo].[nlpresultstg](
	[chartname] [varchar](50) NULL,
	[pagenumber] [varchar](50) NULL,
	[diagcodeLvl1] [varchar](50) NULL,
	[diagdescLvl1] [varchar](500) NULL,
	[pdftext] [varchar](500) NULL
) ON [PRIMARY]
GO
