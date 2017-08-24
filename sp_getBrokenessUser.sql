USE SIGAQ
GO

ALTER PROCEDURE [dbo].[sp_getBrokenessUser]
AS
BEGIN
	DECLARE
		@begenningDate VARCHAR(20) = '20170201'

	;WITH cte_brokenessSIVE AS (
		SELECT 
			'SIVE' AS originSys
			, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
			, brk.codeSVA
			, 'Quebranto' AS brkType 
			, brk.lbrokeness_date
			, 'Quebranto' estatus
			, ROW_NUMBER() OVER(ORDER BY brk.lbrokeness_date ASC) AS [norows]
		FROM SVA.dbo.td_brokenessLog brk 
			INNER JOIN SVA.dbo.T_GARANTIA tgar ON (brk.codeSVA = tgar.sCODIGOBARRAS)
			INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (tgar.nSUCURSAL = dep.id_departamento)
			INNER JOIN SVA.dbo.tc_brokenessTypes brkt ON (brk.tbrokeness_id = brkt.tbrokeness_id)
		WHERE CONVERT(varchar,brk.lbrokeness_date,112) >= @begenningDate
	) 
	SELECT *
	INTO #tmpbrokeness
	FROM cte_brokenessSIVE
	
	;WITH cte_brokenessInventaio AS (
		SELECT
			ROW_NUMBER() OVER(ORDER BY chk.wlc_createDate ASC) AS [norows]
			, chk.wlc_codeSVA
			, chkbd.bknd_amountCharge
			, chk.wlc_createUser
			, chk.wlc_respStageUser
			, gp.tbrokeness_name + ' - ' + p.tbrokeness_name + ' - ' + tbrk.tbrokeness_name AS reason
		FROM INVENTARIO.dbo.tp_checkListWarranty chk
			INNER JOIN INVENTARIO.dbo.tp_brokenness chkb ON (chk.wlc_id = chkb.wlc_id)
			INNER JOIN INVENTARIO.dbo.td_brokenness chkbd ON (chkb.bkn_id = chkbd.bkn_id)
			INNER JOIN SVA.dbo.tc_brokenessTypes tbrk ON (chkb.bkn_typeBrokenness = tbrk.tbrokeness_id)
			INNER JOIN SVA.dbo.tc_brokenessTypes p ON (p.tbrokeness_id = tbrk.tbrokeness_parent)
			INNER JOIN SVA.dbo.tc_brokenessTypes gp ON (gp.tbrokeness_id = p.tbrokeness_parent)
		WHERE chk.sinv_id = 51 OR chk.sinv_id = 52
			AND CONVERT(varchar, chk.wlc_createDate, 112) >= @begenningDate
	)
	
	SELECT 
		a.*
		, b.bknd_amountCharge AS amount
		, b.wlc_createUser AS createUser
		, b.wlc_respStageUser AS responsibleUser
		, b.reason
	FROM #tmpbrokeness a
		INNER JOIN cte_brokenessInventaio b ON (a.norows = b.norows)

	;WITH cte_brokenessInventarios AS(
		SELECT inv.*
		FROM INVENTARIO.dbo.tp_checkListWarranty inv
		WHERE inv.sinv_id = 51	
			AND inv.wlc_codeSVA NOT IN (SELECT DISTINCT codeSVA FROM #tmpbrokeness)	
	)
	SELECT *
	FROM cte_brokenessInventarios
	/*
	SELECT 
		DISTINCT codeSVA
	FROM #tmpbrokeness*/
	
	SELECT
		COUNT(DISTINCT codeSVA)
	FROM #tmpbrokeness

	DROP TABLE #tmpbrokeness
END

-- EXEC SIGAQ.dbo.sp_getBrokenessUser