USE CATALOGOS
GO

CREATE PROCEDURE [dbo].[sp_setBrkWarrantyToPay]
AS
BEGIN
	IF OBJECT_ID('tempdb..#tmpSive') IS NOT NULL
	BEGIN
		DROP TABLE #tmpSive
	END

	IF OBJECT_ID('tempdb..#tmpInventarios') IS NOT NULL
	BEGIN
		DROP TABLE #tmpInventarios
	END
	
	IF OBJECT_ID('tempdb..#tpmAudit') IS NOT NULL
	BEGIN
		DROP TABLE #tpmAudit
	END

	IF OBJECT_ID('tempdb..#brkFinance') IS NOT NULL
	BEGIN
		DROP TABLE #brkFinance
	END

	DECLARE
		@startDate DATETIME = '2017-09-13 00:00:00.000'
		--@startDate DATETIME = GETDATE()
		, @msg VARCHAR(300) = ''

	BEGIN TRY
		/**************** Quebrantos SIVE *************************/
		;WITH cte_brokenessInventaioSIVE AS (
			SELECT
				'SIVE' AS originSys
				, chk.wlc_codeSVA as codeSva
				, dep.id_departamento AS branchOffice
				, chkbd.bknd_amountCharge
				, CASE
					WHEN chk.wlc_respStageUser = 'gvargas' THEN 'GCP'
					ELSE chk.wlc_respStageUser
				END AS responsibleUser
				, chk.wlc_createDate
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
				AND (CONVERT(varchar, chk.wlc_createDate, 112) = CONVERT(varchar, @startdate, 112))
		)
		SELECT *
		INTO #tmpSive
		FROM cte_brokenessInventaioSIVE
		
		/************* Quebrantos Inventarios *******************/
		;WITH cte_brokenessInventarios AS(
			SELECT 
				'INVENTARIOS' AS originSys
				, chkw.wlc_codeSVA AS codeSVA
				, dep.id_departamento AS branchOffice
				, tdbrk.bknd_amountCharge AS amount
				, CASE
					WHEN tdbrk.bknd_userCharge = 'gvargas' THEN 'GCP'
					ELSE tdbrk.bknd_userCharge
				END AS responsibleUser
				, chkw.wlc_createDate AS brkDate
				, chkw.wlc_id
			FROM INVENTARIO.dbo.tp_checkListWarranty chkw
				INNER JOIN INVENTARIO.dbo.tp_inventarios inv ON (chkw.wlc_codeSVA = inv.codigo_garantia)
				INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (inv.cve_suc = dep.id_departamento)
				INNER JOIN ISILOANSWEB.dbo.T_CRED cred ON (inv.credito = cred.NUMERO)
				INNER JOIN INVENTARIO.dbo.tp_brokenness tpbrk ON (chkw.wlc_id = tpbrk.wlc_id)
				INNER JOIN INVENTARIO.dbo.td_brokenness tdbrk ON (tdbrk.bkn_id = tpbrk.bkn_id)
			WHERE chkw.sinv_id = 51	
				AND (CONVERT(varchar, chkw.wlc_createDate, 112) = CONVERT(varchar, @startdate, 112))	
		)
		SELECT 
			a.*
		INTO #tmpInventarios
		FROM cte_brokenessInventarios a
			INNER JOIN INVENTARIO.dbo.td_checkListWarranty chkwd ON (a.wlc_id = chkwd.wlc_id AND chkwd.wlcd_id IN (SELECT MAX(wlcd_id) FROM INVENTARIO.dbo.td_checkListWarranty WHERE wlc_id = a.wlc_id))
		where codeSVA not in (SELECT DISTINCT codeSVA FROM SVA.dbo.td_brokenessLog)

		/************* Quebrantos Auditoria *********************/
		;WITH cte_brokenessAudit AS (
			SELECT
				'AUDITORIA' AS originSys
				, ad.daud_code_sva AS codeSva
				, dep.id_departamento AS branchOffice
				, ab.baud_amount_charge
				, ab.baud_user_responsive
				, ab.baud_date_create
			FROM INVENTARIO.dbo.td_audit ad
				INNER JOIN INVENTARIO.dbo.te_audit_bitacora ab ON (ad.daud_id = ab.daud_id)
				INNER JOIN ISILOANSWEB.dbo.T_CRED cred ON (ad.daud_credit = cred.NUMERO)
				INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (cred.SUCURSAL = dep.id_departamento)
			WHERE CONVERT(varchar, ab.baud_date_create, 112) = CONVERT(varchar, @startDate, 112)
		)
		SELECT *
		INTO #tpmAudit
		FROM cte_brokenessAudit
		
		/****************** Quebrantos Finanzas *****************/
		;WITH cte_brkFinance AS (
			SELECT
				'FINANZAS' AS originSys
				, brkf.brkemp_id
				, dep.id_departamento AS branchOffice
				, brkf.brkemp_amount
				, brkf.brkemp_userName
				, brkf.brkemp_brkDate
			FROM CATALOGOS.dbo.tp_brkEmpFAsign brkf
				INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (brkf.brkemp_branchOffice = dep.id_departamento)
				INNER JOIN CATALOGOS.dbo.tc_brkFinanceType brkt ON (brkf.brkemp_type = brkt.brkf_id)
			WHERE CONVERT(varchar, brkf.brkemp_cDate, 112) = CONVERT(varchar, @startDate, 112)
		)
		SELECT *
		INTO #brkFinance
		FROM cte_brkFinance

		/************* Insercion en tp_brkWarrantyToPay *********/
		BEGIN TRAN
		INSERT INTO tp_brkWarrantyToPay (
			brkwp_origin
			, brkwp_codeSva
			, brkwp_branchOffice
			, brkwp_amount
			, brkwp_brkUser
			, brkwp_brkDate
		)
		SELECT * FROM #tmpSive
		UNION
		SELECT
			inv.originSys
			, inv.codeSVA
			, inv.branchOffice
			, inv.amount
			, inv.responsibleUser
			, inv.brkDate			
		FROM #tmpInventarios inv
		UNION
		SELECT * FROM #tpmAudit
		UNION
		SELECT 
			fi.originSys
			, CONVERT(varchar, fi.brkemp_id)
			, fi.branchOffice
			, fi.brkemp_amount
			, fi.brkemp_userName
			, fi.brkemp_brkDate
		FROM #brkFinance fi

		IF @@TRANCOUNT > 0 
			COMMIT TRAN

		DROP TABLE #tmpSive
		DROP TABLE #tmpInventarios
		DROP TABLE #tpmAudit
		DROP TABLE #brkFinance

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = (SELECT SUBSTRING(ERROR_MESSAGE(), 1, 300))
		RAISERROR(@msg, 16, 1)
	END CATCH
END

-- EXEC CATALOGOS.dbo.sp_setBrkWarrantyToPay