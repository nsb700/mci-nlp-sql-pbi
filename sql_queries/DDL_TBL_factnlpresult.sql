USE [nlp]
GO

IF EXISTS(
	SELECT *
	FROM INFORMATION_SCHEMA.TABLES
	WHERE	TABLE_SCHEMA = N'dbo'
	AND		TABLE_NAME   = N'factnlpresult'
)
	DROP TABLE [dbo].[factnlpresult]
GO

CREATE TABLE [dbo].[factnlpresult](
	[factnlpresultId] INT IDENTITY(1, 1),
	[dimChartId] INT,
	[dimDiagId] INT
) ON [PRIMARY]
GO
