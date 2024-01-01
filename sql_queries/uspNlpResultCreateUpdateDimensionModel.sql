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