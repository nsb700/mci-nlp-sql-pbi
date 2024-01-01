# Deliver NLP results for strategic decision-making using PowerBI visualizations over a Dimensional Model created using - AWS S3, AWS Glue and AWS RDS (SQL Server).

## Description :-

Data powering this project is created by NLP - code can be found at <a href="https://github.com/nsb700/mci-nlp-aws-webapp">mci-nlp-aws-webapp</a> or <a href="https://github.com/nsb700/mci-nlp-multiprocessing">mci-nlp-multiprocessing</a>. 

This project walks through how NLP results can be delivered to business teams enabling them to make strategic decisions.

## Architecture :

Read along for each numbered step in the below archicture along with detailed screenshots:

![Alt text](screenshots/01-mci-nlp-sql-powerbi.drawio.png)

### (1) NLP Results in AWS S3 Bucket:

![Alt text](screenshots/02-step-01-img-01.png)

### (2) AWS RDS SQL Server:

Since this project uses Microsoft SQL Server, an AWS RDS instance of SQL Server is set up in RDS Console. In the options, one can either create one's own admin password or have AWS create one. This 'admin' user and password is required to connect to it later.

![Alt text](screenshots/03-step-02-img-01.png)

Server created
![Alt text](screenshots/03-step-02-img-02.png)

Click on the DB Identifier. Click on Modify, 

![Alt text](screenshots/03-step-02-img-03.png)

Following steps enable us to connect to the database using MS SQL Server Management Studio.

In Connectivity -> Additional Configuration, make the server publicly accessible so as to be able to connect to it. Then at the bottom, select Continue -> Modify DB Instance

![Alt text](screenshots/03-step-02-img-04.png)

Click on the DB Identifier. Note the Endpoint and Port (required to connect to database). Click on the VPC Security Group,
![Alt text](screenshots/03-step-02-img-05.png)

Select security group and click Edit Inbound rules.
![Alt text](screenshots/03-step-02-img-06.png)

Add Rule for Type MSSQL, Source MyIP. Save Rule. A second rule allowing all traffic is also required. 
![Alt text](screenshots/03-step-02-img-07.png)

Under VPC Console, create Endpoint of Type Gateway.
![Alt text](screenshots/03-step-02-img-08.png)

### (3) SQL Scripts:

Connect to the RDS SQL Server using MS SQL Server Management Studio, using the endpoint and port noted above.

![Alt text](screenshots/04-step-03-img.png)

Create and execute the below scripts (scripts included in this Git repository) - 

1. *DDL_DB_nlp.sql* - Creates the 'nlp' database
```
USE [master]
GO

CREATE DATABASE [nlp]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'nlp', FILENAME = N'D:\rdsdbdata\DATA\nlp.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
 LOG ON 
( NAME = N'nlp_log', FILENAME = N'D:\rdsdbdata\DATA\nlp_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [nlp].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [nlp] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [nlp] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [nlp] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [nlp] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [nlp] SET ARITHABORT OFF 
GO

ALTER DATABASE [nlp] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [nlp] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [nlp] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [nlp] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [nlp] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [nlp] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [nlp] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [nlp] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [nlp] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [nlp] SET  DISABLE_BROKER 
GO

ALTER DATABASE [nlp] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [nlp] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [nlp] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [nlp] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [nlp] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [nlp] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [nlp] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [nlp] SET RECOVERY FULL 
GO

ALTER DATABASE [nlp] SET  MULTI_USER 
GO

ALTER DATABASE [nlp] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [nlp] SET DB_CHAINING OFF 
GO

ALTER DATABASE [nlp] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [nlp] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO

ALTER DATABASE [nlp] SET DELAYED_DURABILITY = DISABLED 
GO

ALTER DATABASE [nlp] SET QUERY_STORE = OFF
GO

ALTER DATABASE [nlp] SET  READ_WRITE 
GO
```
2. *DDL_TBL_nlpresultstg.sql* - Creates staging table for nlp results data coming from AWS S3.
```
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
```
3. *DDL_TBL_dimChart.sql* - Creates dimension table for charts.
```
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
```
4. *DDL_TBL_dimDiag.sql* - Creates dimension table for diagnoses.
```
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
```
5. *DDL_TBL_factnlpresult.sql* - Creates fact table for nlp results.
```
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
```
6. *uspNlpResultCreateUpdateDimensionModel.sql* - Creates stored procedure which creates/updates the dimension model. This will not be run yet. It will be run in Step(10) i.e. after data is ready in staging table.
```
USE [nlp];  
GO  
CREATE PROCEDURE dbo.uspNlpResultCreateUpdateDimensionModel   
AS   

--===================
-- DIMENSION DIMCHART
--===================
INSERT	dbo.dimChart (chartname, pagenumber, pdftext)
SELECT	source_tbl.chartname, 
		CAST(source_tbl.pagenumber AS INT), 
		source_tbl.pdftext
FROM	(
			SELECT DISTINCT chartname, pagenumber, pdftext
			FROM dbo.nlpresultstg
		)	source_tbl 
WHERE	NOT EXISTS (
					  SELECT	target_tbl.chartname, 
								target_tbl.pagenumber, 
								target_tbl.pdftext 
						 FROM	dbo.dimChart	target_tbl 
						WHERE	target_tbl.chartname  = source_tbl.chartname 
						  AND	target_tbl.pagenumber = CAST(source_tbl.pagenumber as int)
						  AND	target_tbl.pdftext    = source_tbl.pdftext
				   );

--===================
-- DIMENSION DIMDIAG
--===================
INSERT	dbo.dimDiag (diagcodeLvl1, diagdescLvl1)
SELECT	source_tbl.diagcodeLvl1, 
		source_tbl.diagdescLvl1
FROM	(
			SELECT DISTINCT diagcodeLvl1, diagdescLvl1
			FROM dbo.nlpresultstg
		)	source_tbl 
WHERE	NOT EXISTS (
					   SELECT	target_tbl.diagcodeLvl1, 
								target_tbl.diagdescLvl1
						 FROM	dbo.dimDiag	target_tbl 
						WHERE	target_tbl.diagcodeLvl1 = source_tbl.diagcodeLvl1 
						  AND	target_tbl.diagdescLvl1 = source_tbl.diagdescLvl1
				   );

--===================
-- FACT FACTNLPRESULT
--===================
INSERT	dbo.factnlpresult (dimChartId, dimDiagId)
SELECT	src_cht.dimChartId, 
		src_diag.dimDiagId
FROM	dbo.nlpresultstg stg_tbl 
JOIN	dbo.dimChart	 src_cht   on stg_tbl.chartname  = src_cht.chartname 
								  and stg_tbl.pagenumber = src_cht.pagenumber 
								  and stg_tbl.pdftext    = src_cht.pdftext 
JOIN	dbo.dimDiag		 src_diag  on stg_tbl.diagcodeLvl1 = src_diag.diagcodeLvl1
								  and stg_tbl.diagdescLvl1 = src_diag.diagdescLvl1
									
WHERE	NOT EXISTS (
					  SELECT	target_tbl.dimChartId, 
								target_tbl.dimDiagId
						 FROM	dbo.factnlpresult	target_tbl 
						WHERE	target_tbl.dimChartId = src_cht.dimChartId 
						  AND	target_tbl.dimDiagId  = src_diag.dimDiagId
				   );

GO  
```

### (4) IAM Role for AWS Glue

In IAM Console, create a role so that -
* AWS Glue can execute itself (AWSGlueServiceRole), 
* Glue can read from S3 (AmazonS3FullAccess - not recommended in production setting), 
* Glue can write to RDS (AmazonRDSFullAccess - not recommended in production setting)

![Alt text](screenshots/05-step-04-img-09.png)

### (5) AWS Glue Crawler for S3 (source)

In Glue console, create a Data Catalog - Database

![Alt text](screenshots/06-step-05-img-10.png)

In crawlers, create a crawler for s3

![Alt text](screenshots/06-step-05-img-11.png)

### (6) AWS Glue Crawler for SQL Server (destination)

Create connection to SQL Server 

![Alt text](screenshots/Screenshot-8.png)

In crawlers, create a crawler for SQL Server

![Alt text](screenshots/07-step-06-img-12.png)

### (7) AWS Glue Data Catalog

* Run both crawlers. They will detect the data structure from the respective location. A table corresponding to each is created in the Glue data catalog. These will be used in the Glue job as reference for source and destination.

* For s3 crawler
![Alt text](screenshots/08-step-07-img-13.png)

* For sql server crawler
![Alt text](screenshots/08-step-07-img-14.png)

### (8) AWS Glue Job

A Glue job is created which uses the crawled data source and destination.

* Job setting for source (uses the crawled data catalog table)
![Alt text](screenshots/09-step-08-img-15.png)

* Job setting for destination (uses the crawled data catalog table)
![Alt text](screenshots/09-step-08-img-16.png)

Run this job to loads nlp results data into SQL server table.

### (9) SQL Server data in staging table: [nlp].[dbo].[nlpresultstg]

![Alt text](screenshots/10-step-09-img.png)

### (10) Create dimensional model

Run stored procedure *uspNlpResultCreateUpdateDimensionModel.sql* - it will read data from staging table and populate it into respective facts and dimensions. After it runs,

* Dimension table [nlp].[dbo].[dimChart]

![Alt text](screenshots/11-step-10-img-17.png)

* Dimension table [nlp].[dbo].[dimDiag]

![Alt text](screenshots/11-step-10-img-18.png)

* Fact table [nlp].[dbo].[factnlpresult]

![Alt text](screenshots/11-step-10-img-19.png)

### (11) PowerBI Report

In PowerBI Desktop, connect to SQL server
![Alt text](screenshots/pbi/pbiscrn01.png)

Import the dimension and fact tables. PowerBI will automatically detect the relationships.
![Alt text](screenshots/pbi/pbiscrn02.png)

Open relation and set Cross filter direction to 'Both'
![Alt text](screenshots/pbi/pbiscrn03.png)

Open relation and set Cross filter direction to 'Both'
![Alt text](screenshots/pbi/pbiscrn04.png)

DAX measures saved in a folder

![Alt text](screenshots/pbi/pbiscrn05.png)

```
//DAX measure
chartcount = DISTINCTCOUNT(dimChart[chartname]) 
```
```
//DAX measure
chartcount_all = CALCULATE(
                        [chartcount], 
                        ALL(dimDiag[diagcodeLvl1])
                    ) 
```
```
//DAX measure
%_of_charts = DIVIDE([chartcount],[chartcount_all])
```
```
//DAX measure
diagcodeLvl1_countdistinct = DISTINCTCOUNT(dimDiag[diagcodeLvl1])
```
```
//DAX measure
pagecount = DISTINCTCOUNT(dimChart[pagenumber])
```
```
//DAX measure
pagecount_all = CALCULATE(
                        [pagecount], 
                        ALL(dimChart[chartname])
                    )
```
```
//DAX measure
pagecount_by_chart = CALCULATE(
                        [pagecount], 
                        ALLEXCEPT(dimChart,dimChart[chartname])
                    )
```
```
//DAX measure
pagecount_max_of_all_charts = MAXX(
                                VALUES(dimChart[chartname]),
                                [pagecount]
                            )
```
```
//DAX measure
pagecount_min_of_all_charts = MINX(
                                VALUES(dimChart[chartname]),
                                [pagecount]
                            )
```

New columns created

![Alt text](screenshots/pbi/pbiscrn06.png)

```
// New column
diag_category = IF(
                    LEN(dimDiag[diagcodeLvl1])==3, 
                    LEFT(dimDiag[diagcodeLvl1],1), 
                    LEFT(dimDiag[diagcodeLvl1],3)
                ) 
```
```
// New column
diagcode_type = IF(
                    LEN(dimDiag[diagcodeLvl1])==3, 
                    "diag", 
                    "hcc"
                )
```

Report landing page

![Alt text](screenshots/pbi/pbiscrn07.png)

Drill-through capability added for detail view.

![Alt text](screenshots/pbi/pbiscrn08.png)

![Alt text](screenshots/pbi/pbiscrn09.png)

Detail view after drill through on a diagnosis code

![Alt text](screenshots/pbi/pbiscrn10.png)

Detail view after drill through on medical-chart-10

![Alt text](screenshots/pbi/pbiscrn11.png)

Select diag hierarchy item on landing page

![Alt text](screenshots/pbi/pbiscrn12.png)

Tooltip for diag code 'hcc021'

![Alt text](screenshots/pbi/pbiscrn13.png)

Zoom to see medical charts with less pages

![Alt text](screenshots/pbi/pbiscrn14.png)

***
