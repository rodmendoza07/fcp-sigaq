BEGIN
	DECLARE
		@user VARCHAR(20) = 'n'
		, @startdate VARCHAR(15) = ''
		, @enddate VARCHAR(15) = ''
		, @enumber INT = -1
		, @audit INT = 0
		, @msg VARCHAR(300) = ''
		, @bkrUsr VARCHAR(20) = ''
		, @brkTotalPayment DECIMAL(18,4) = 0
		, @brkTotalCharge DECIMAL(18,4) = 0
		, @brkTotalAmount DECIMAL(18,4) = 0

		
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

	/************************ Quebrantos SIVE *******************************/
		;WITH cte_userbrkSive AS (
			SELECT
				ROW_NUMBER() OVER(ORDER BY chk.wlc_createDate ASC) AS [norows]
				, 'SIVE' AS originSys
				, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
				, CONVERT(varchar, tgar.sCREDITO) AS credit
				, chk.wlc_codeSVA as codeSva
				, 'Quebranto' AS [type]
				, chk.wlc_createUser
				, CASE
					WHEN chk.wlc_respStageUser = 'gvargas' THEN 'GCP'
					ELSE chk.wlc_respStageUser
				END AS responsibleUser
				, chk.wlc_createDate
				, chkbd.bknd_amountCharge
				, gp.tbrokeness_name + ' - ' + p.tbrokeness_name + ' - ' + tbrk.tbrokeness_name AS reason
				, CASE 
					WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN 'VIGENTE'
					WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 1 THEN 'VENCIDO'
					WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 0 THEN 'LIQ. CLIENTE'
					WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 1 THEN 'VENDIDO'
				END AS warrantyStatus
			
			FROM INVENTARIO.dbo.tp_checkListWarranty chk
				INNER JOIN INVENTARIO.dbo.tp_brokenness chkb ON (chk.wlc_id = chkb.wlc_id)
				INNER JOIN INVENTARIO.dbo.td_brokenness chkbd ON (chkb.bkn_id = chkbd.bkn_id AND chkbd.bknd_status = 1)
				INNER JOIN SVA.dbo.tc_brokenessTypes tbrk ON (chkb.bkn_typeBrokenness = tbrk.tbrokeness_id)
				INNER JOIN SVA.dbo.tc_brokenessTypes p ON (p.tbrokeness_id = tbrk.tbrokeness_parent)
				INNER JOIN SVA.dbo.tc_brokenessTypes gp ON (gp.tbrokeness_id = p.tbrokeness_parent)
				INNER JOIN SVA.dbo.T_GARANTIA tgar ON (chk.wlc_codeSVA = tgar.sCODIGOBARRAS)
				INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (tgar.nSUCURSAL = dep.id_departamento)
				INNER JOIN ISILOANSWEB.dbo.T_CRED cred ON (tgar.sCREDITO = cred.NUMERO)
			WHERE chk.sinv_id = 52
				AND ((@startdate = '' AND @enddate = '') OR CONVERT(varchar, chk.wlc_createDate, 112) BETWEEN @startdate AND @enddate)
				--AND chk.wlc_respStageUser = @bkrUsr
		)
		SELECT * 
		INTO #tmpSive
		FROM cte_userbrkSive

		/************************ Quebrantos Inventarios *******************************/
		;WITH cte_inventarios AS (
			SELECT 
				'INVENTARIOS' AS originSys
				, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
				, chkw.wlc_codeSVA AS codeSVA
				, CASE 
					WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN 'Capital en riesgo'
					ELSE 'Quebranto'
				END AS brkType
				, chkw.wlc_createDate AS brkDate
				, tdbrk.bknd_amountCharge AS amount
				, chkw.wlc_createUser AS createUser
				, CASE
					WHEN tdbrk.bknd_userCharge = 'gvargas' THEN 'GCP'
					ELSE tdbrk.bknd_userCharge 
				END AS responsibleUser
				, CONVERT(varchar,inv.credito) AS credit
				, CASE 
					WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN 'VIGENTE'
					WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 1 THEN 'VENCIDO'
					WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 0 THEN 'LIQ. CLIENTE'
					WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 1 THEN 'VENDIDO'
				END AS warrantyStatus
				, chkw.wlc_id
			FROM INVENTARIO.dbo.tp_checkListWarranty chkw
				INNER JOIN INVENTARIO.dbo.tp_inventarios inv ON (chkw.wlc_codeSVA = inv.codigo_garantia)
				INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (inv.cve_suc = dep.id_departamento)
				INNER JOIN ISILOANSWEB.dbo.T_CRED cred ON (inv.credito = cred.NUMERO)
				INNER JOIN INVENTARIO.dbo.tp_brokenness tpbrk ON (chkw.wlc_id = tpbrk.wlc_id)
				INNER JOIN INVENTARIO.dbo.td_brokenness tdbrk ON (tdbrk.bkn_id = tpbrk.bkn_id)
			WHERE chkw.sinv_id = 51
				--AND tdbrk.bknd_userCharge = @bkrUsr
		)
		SELECT 
			a.*
			, chkwd.wlcd_desComments + ' - ' + chkwd.wlcd_wComments + ' - ' + chkwd.wlcd_dComments AS reason
		INTO #tmpInventarios
		FROM cte_inventarios a
			INNER JOIN INVENTARIO.dbo.td_checkListWarranty chkwd ON (a.wlc_id = chkwd.wlc_id AND chkwd.wlcd_id IN (SELECT MAX(wlcd_id) FROM INVENTARIO.dbo.td_checkListWarranty WHERE wlc_id = a.wlc_id))
		where codeSVA not in (SELECT DISTINCT codeSVA FROM SVA.dbo.td_brokenessLog)
		
		/************************ Quebrantos Auditorias *******************************/
		;WITH cte_brokenessAudit AS (
			SELECT
				ROW_NUMBER() over(PARTITION by ad.daud_code_sva order by ab.baud_date_create asc) as conteo
				, 'AUDITORIA' AS originSys
				, ad.daud_code_sva AS codeSva
				, ab.baud_amount_charge
				, ab.baud_user_create
				, ab.baud_user_responsive
				, ab.baud_date_create
				, ab.baud_comment
				, CONVERT(varchar,ad.daud_credit) AS daud_credit
				, CASE 
					WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN 'VIGENTE'
					WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 1 THEN 'VENCIDO'
					WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 0 THEN 'LIQ. CLIENTE'
					WHEN cred.[STATUS] = 1 AND cred.SUBSISTEMA = 1 THEN 'VENDIDO'
				END AS warrantyStatus
				, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
				, CASE 
					WHEN cred.[STATUS] = 0 AND cred.SUBSISTEMA = 0 THEN 'Capital en riesgo'
					ELSE 'Quebranto'
				END AS brkType
			FROM INVENTARIO.dbo.td_audit ad
				INNER JOIN INVENTARIO.dbo.te_audit_bitacora ab ON (ad.daud_id = ab.daud_id)
				INNER JOIN ISILOANSWEB.dbo.T_CRED cred ON (ad.daud_credit = cred.NUMERO)
				INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (cred.SUCURSAL = dep.id_departamento)
			--WHERE ab.baud_user_responsive = @bkrUsr
		)

		SELECT *
		INTO #tpmAudit
		FROM cte_brokenessAudit

		--select * from #tpmAudit
		/************************ Quebrantos Finanzas *******************************/
		;WITH cte_brkFinance AS (
			SELECT
				'FINANZAS' AS originSys
				, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
				, 'N/A' AS credit
				, 'N/A' AS codeSva
				, 'Quebranto' AS [type]
				, brkf.brkemp_cUser
				, brkf.brkemp_userName
				, brkf.brkemp_brkDate
				, brkf.brkemp_amount
				, brkt.brkf_type
				, 'N/A' AS [status]
			FROM CATALOGOS.dbo.tp_brkEmpFAsign brkf
				INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (brkf.brkemp_branchOffice = dep.id_departamento)
				INNER JOIN CATALOGOS.dbo.tc_brkFinanceType brkt ON (brkf.brkemp_type = brkt.brkf_id)
			--WHERE brkf.brkemp_userName = @bkrUsr
		)
		SELECT *
		INTO #brkFinance
		FROM cte_brkFinance

		--select * from #brkFinance
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
			, brk.[type]
			, brk.wlc_createUser
			, brk.responsibleUser
			, brk.wlc_createDate
			, brk.bknd_amountCharge
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
		UNION
		SELECT
			b.originSys
			, b.branchOffice
			, b.credit
			, b.codeSva
			, b.[type]
			, b.brkemp_cUser
			, b.brkemp_userName
			, b.brkemp_brkDate
			, b.brkemp_amount
			, b.brkf_type
			, b.[status]
		FROM #brkFinance b

		SELECT 
			 ROW_NUMBER() OVER(ORDER BY brk_createDate ASC) AS [no]
			 , *
		FROM #tmpbrk
		WHERE (@startdate = '' AND @enddate = '') OR 
		(CONVERT(varchar, brk_createDate, 112) BETWEEN @startdate AND @enddate)
		
		SELECT
			COUNT(brk_codeSva) AS brk_wtotal
		FROM #tmpbrk

		SELECT
			@brkTotalCharge = ISNULL(SUM(brk_amount),0)
		FROM #tmpbrk

		SELECT
			@brkTotalPayment = ISNULL(SUM(brkp_amount),0)
		FROM CATALOGOS.dbo.tp_brkPayments
		--WHERE brkp_payUSer = @bkrUsr
		
		SELECT
			@brkTotalAmount = @brkTotalCharge - @brkTotalPayment

		SELECT @brkTotalAmount  AS brk_atotal

		DROP TABLE #tmpSive
		DROP TABLE #tmpInventarios
		DROP TABLE #tpmAudit
		DROP TABLE #brkFinance
		DROP TABLE #tmpbrk
END