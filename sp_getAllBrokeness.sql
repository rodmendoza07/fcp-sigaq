USE SIGAQ
GO

ALTER PROCEDURE [dbo].[sp_getAllBrokeness] (
	@startdate VARCHAR(30) = ''
	, @enddate VARCHAR(330) = ''
)
AS
BEGIN
	DECLARE
		@begenningDate VARCHAR(20) = '20170201'

	CREATE TABLE #tmpbrk (
		brk_originSys VARCHAR(100)
		, brk_branchOffice VARCHAR(50)
		, brk_credit VARCHAR(20)
		, brk_codeSva VARCHAR(20)
		, brk_type VARCHAR(100)
		, brk_createUser VARCHAR(20)
		, brk_responsibleUser VARCHAR(20)
		, brk_createDate DATETIME
		, brk_amount DECIMAL(18,4)
		, brk_description VARCHAR(500)
		, brk_wstatus VARCHAR(100)
	)
	/************* Quebrantos SIVE ********************/
	;WITH cte_brokenessSIVE AS (
		SELECT 
			ROW_NUMBER() OVER(ORDER BY brk.lbrokeness_date ASC) AS [norows]
			, '<span class="label label-warning">SIVE</span>' AS originSys
			, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
			, brk.codeSVA
			, '<span class="label label-danger">Quebranto</span>' AS brkType 
			, brk.lbrokeness_date
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
			, CASE
				WHEN chk.wlc_respStageUser = 'gvargas' THEN 'GCP'
				ELSE chk.wlc_respStageUser
			END AS responsibleUser
			, gp.tbrokeness_name + ' - ' + p.tbrokeness_name + ' - ' + tbrk.tbrokeness_name AS reason
			
		FROM INVENTARIO.dbo.tp_checkListWarranty chk
			INNER JOIN INVENTARIO.dbo.tp_brokenness chkb ON (chk.wlc_id = chkb.wlc_id)
			INNER JOIN INVENTARIO.dbo.td_brokenness chkbd ON (chkb.bkn_id = chkbd.bkn_id)
			INNER JOIN SVA.dbo.tc_brokenessTypes tbrk ON (chkb.bkn_typeBrokenness = tbrk.tbrokeness_id)
			INNER JOIN SVA.dbo.tc_brokenessTypes p ON (p.tbrokeness_id = tbrk.tbrokeness_parent)
			INNER JOIN SVA.dbo.tc_brokenessTypes gp ON (gp.tbrokeness_id = p.tbrokeness_parent)
			
		WHERE /*chk.sinv_id = 51 OR*/ chk.sinv_id = 52
			AND CONVERT(varchar, chk.wlc_createDate, 112) >= @begenningDate
	)
	
	SELECT 
		a.*
		, b.bknd_amountCharge AS amount
		, b.wlc_createUser AS createUser
		, b.responsibleUser
		, b.reason 
		, inv.credito AS credit
		, CASE 
			WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN '<span class="label label-primary">VIGENTE</span>'
			WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 1 THEN '<span class="label label-danger">VENCIDO</span>'
			WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 0 THEN '<span class="label label-success">LIQ. CLIENTE</span>'
			WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 1 THEN '<span class="label label-info">VENDIDO</span>'
		END AS warrantyStatus
	INTO #tmpSive
	FROM #tmpbrokeness a
		INNER JOIN cte_brokenessInventaio b ON (a.norows = b.norows)
		INNER JOIN INVENTARIO.dbo.tp_inventarios inv ON (a.codeSVA = inv.codigo_garantia)
		INNER JOIN ISILOANSWEB.dbo.T_CRED cred ON (inv.credito = cred.NUMERO)

	/************* Quebrantos Inventarios ********************/
	;WITH cte_brokenessInventarios AS(
		SELECT 
			'<span class="label label-success">INVENTARIOS</span>' AS originSys
			, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
			, chkw.wlc_codeSVA AS codeSVA
			, CASE 
				WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN '<span class="label label-warning">Capital en riesgo</span>'
				ELSE '<span class="label label-danger">Quebranto</span>'
			END AS brkType
			, chkw.wlc_createDate AS brkDate
			, tdbrk.bknd_amountCharge AS amount
			, chkw.wlc_createUser AS createUser
			, CASE
				WHEN chkw.wlc_respStageUser = 'gvargas' THEN 'GCP'
				ELSE chkw.wlc_respStageUser
			END AS responsibleUser
			, inv.credito AS credit
			, CASE 
				WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN '<span class="label label-primary">VIGENTE</span>'
				WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 1 THEN '<span class="label label-danger">VENCIDO</span>'
				WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 0 THEN '<span class="label label-success">LIQ. CLIENTE</span>'
				WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 1 THEN '<span class="label label-info">VENDIDO</span>'
			END AS warrantyStatus
			, chkw.wlc_id
		FROM INVENTARIO.dbo.tp_checkListWarranty chkw
			INNER JOIN INVENTARIO.dbo.tp_inventarios inv ON (chkw.wlc_codeSVA = inv.codigo_garantia)
			INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (inv.cve_suc = dep.id_departamento)
			INNER JOIN ISILOANSWEB.dbo.T_CRED cred ON (inv.credito = cred.NUMERO)
			INNER JOIN INVENTARIO.dbo.tp_brokenness tpbrk ON (chkw.wlc_id = tpbrk.wlc_id)
			INNER JOIN INVENTARIO.dbo.td_brokenness tdbrk ON (tdbrk.bkn_id = tpbrk.bkn_id)
		WHERE chkw.sinv_id = 51	
			AND chkw.wlc_codeSVA NOT IN (SELECT DISTINCT codeSVA FROM #tmpbrokeness)	
	)
	SELECT 
		a.*
		, chkwd.wlcd_desComments + ' - ' + chkwd.wlcd_wComments + ' - ' + chkwd.wlcd_dComments AS reason
	INTO #tmpInventarios
	FROM cte_brokenessInventarios a
		INNER JOIN INVENTARIO.dbo.td_checkListWarranty chkwd ON (a.wlc_id = chkwd.wlc_id AND chkwd.wlcd_id IN (SELECT MAX(wlcd_id) FROM INVENTARIO.dbo.td_checkListWarranty WHERE wlc_id = a.wlc_id))

	/************* Quebrantos Auditoria ********************/
	;WITH cte_brokenessAudit AS (
		SELECT
			'<span class="label label-primary">AUDITORIA</span>' AS originSys
			, ad.daud_code_sva AS codeSva
			, ab.baud_amount_charge
			, ab.baud_user_create
			, ab.baud_user_responsive
			, ab.baud_date_create
			, ab.baud_comment
			, ad.daud_credit
			, CASE 
				WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN '<span class="label label-primary">VIGENTE</span>'
				WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 1 THEN '<span class="label label-danger">VENCIDO</span>'
				WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 0 THEN '<span class="label label-success">LIQ. CLIENTE</span>'
				WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 1 THEN '<span class="label label-info">VENDIDO</span>'
			END AS warrantyStatus
			, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
			, CASE 
				WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN '<span class="label label-warning">Capital en riesgo</span>'
				ELSE '<span class="label label-danger">Quebranto</span>'
			END AS brkType
		FROM INVENTARIO.dbo.td_audit ad
			INNER JOIN INVENTARIO.dbo.te_audit_bitacora ab ON (ad.daud_id = ab.daud_id)
			INNER JOIN ISILOANSWEB.dbo.T_CRED cred ON (ad.daud_credit = cred.NUMERO)
			INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (cred.SUCURSAL = dep.id_departamento)
	)

	SELECT *
	INTO #tpmAudit
	FROM cte_brokenessAudit

	/*************** Muestra datos ****************/	
	INSERT INTO #tmpbrk (
		brk_originSys
		, brk_branchOffice
		, brk_credit
		, brk_codeSva
		, brk_type
		, brk_createUser
		, brk_responsibleUSer
		, brk_createDate
		, brk_amount
		, brk_description
		, brk_wstatus
	)
	SELECT
		brk.originSys
		, brk.branchOffice
		, brk.credit
		, brk.codeSVA
		, brk.brkType
		, brk.createUser
		, brk.responsibleUser
		, brk.lbrokeness_date
		, brk.amount
		, brk.reason
		, brk.warrantyStatus
	FROM #tmpSive brk 
	UNION
	SELECT 
		stk.originSys
		, stk.branchOffice
		, stk.credit
		, stk.codeSVA
		, stk.brkType
		, stk.createUser
		, stk.responsibleUser
		, stk.brkDate
		, stk.amount
		, stk.reason
		, stk.warrantyStatus
	FROM #tmpInventarios stk
	UNION
	SELECT
		a.originSys
		, a.branchOffice
		, a.daud_credit
		, a.codeSva
		, a.brkType
		, a.baud_user_create
		, a.baud_user_responsive
		, a.baud_date_create
		, a.baud_amount_charge
		, a.baud_comment
		, a.warrantyStatus
	FROM #tpmAudit a

	SELECT 
		 ROW_NUMBER() OVER(ORDER BY brk_createDate ASC) AS [no]
		 , *
	FROM #tmpbrk
	WHERE (@startdate = '' AND @enddate = '') OR 
	(CONVERT(varchar, brk_createDate, 112) BETWEEN @startdate AND @enddate)

	DROP TABLE #tmpbrokeness
	DROP TABLE #tmpSive
	DROP TABLE #tmpInventarios
	DROP TABLE #tpmAudit
	DROP TABLE #tmpbrk
END

-- EXEC SIGAQ.dbo.sp_getAllBrokeness