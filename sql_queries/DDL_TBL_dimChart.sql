USE [nlp]
GO

IF EXISTS(
	SELECT *
	FROM INFORMATION_SCHEMA.TABLES
	WHERE	TABLE_SCHEMA = N'dbo'
	AND		TABLE_NAME = N'dimChart'
)
	DROP TABLE [dbo].[dimChart]
GO

CREATE TABLE [dbo].[dimChart](
	[dimChartId] INT IDENTITY(1, 1),
	[chartname] [varchar](50),
	[pagenumber] INT,
	[pdftext] [varchar](500)
) ON [PRIMARY]
GO
