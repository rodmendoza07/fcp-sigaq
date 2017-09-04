/*USE SIGAQ
GO

ALTER PROCEDURE [dbo].[sp_getBrokenessUser](
	@user VARCHAR(20) = ''
)
AS*/
BEGIN
	DECLARE
		@user VARCHAR(20) = 'franvp'
		, @siveDate VARCHAR(20) = '20170201'
		, @msg VARCHAR(300) = ''

	BEGIN TRY
		SELECT
			emp.nombre AS [name]
			, emp.ap_paterno AS firstname
			, emp.ap_materno AS lastname
			, job.descripcion AS puesto
			, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
		FROM CATALOGOS.dbo.tc_empleados emp
			INNER JOIN CATALOGOS.dbo.tc_puesto job ON (emp.cve_puesto = job.id_puesto)
			INNER JOIN CATALOGOS.dbo.tc_departamento dep ON (emp.cve_depto = dep.id_departamento)
		WHERE usuario = @user

		;WITH cte_userbrkSive AS (
			SELECT 
				ROW_NUMBER() OVER(ORDER BY chk.wlc_createDate ASC) AS [norows]
				, chk.wlc_codeSVA AS codeSva
				, chkbd.bknd_amountCharge AS amount
				, tgar.sDESCGARANTIA AS [description]
				, chk.wlc_createDate AS createDate
				, chk.wlc_createUser AS createUser
			FROM INVENTARIO.dbo.tp_checkListWarranty chk
				INNER JOIN INVENTARIO.dbo.tp_brokenness chkb ON (chk.wlc_id = chkb.wlc_id)
				INNER JOIN INVENTARIO.dbo.td_brokenness chkbd ON (chkb.bkn_id = chkbd.bkn_id AND chkb.bknd_status = 1)
				INNER JOIN SVA.dbo.T_GARANTIA tgar ON (chk.wlc_codeSVA = tgar.sCODIGOBARRAS)
			WHERE wlc_respStageUser = @user
				AND CONVERT(varchar,chk.wlc_createDate,112) >= @siveDate
				AND (chk.sinv_id = 52)
		)
		SELECT 
			*
		INTO #brksive1
		FROM cte_userbrkSive

		SELECT *
		FROM #brksive1
 
		;WITH cte_userbrkSive1 AS (
			SELECT
				ROW_NUMBER() OVER(ORDER BY brk.lbrokeness_date ASC) AS [norows]
				, * 
			FROM SVA.dbo.td_brokenessLog brk
			WHERE CONVERT(varchar,brk.lbrokeness_date,112) >= @siveDate
		)

		SELECT sive.*
		--INTO #brksive
		FROM #brksive1 sive
			INNER JOIN cte_userbrkSive1 b on (sive.norows = b.norows)
		
		--SELECT 
		--	DISTINCT codeSva AS codigo
		--INTO #brksive2
		--FROM #brksive

		--SELECT *
		--FROM #brksive2

		--SELECT 
		--	norows
		--	, codeSva
		--	, amount
		--FROM #brksive
		
		--SELECT 
		--	--DISTINCT codeSva 
		--	 SUM(amount)
		--FROM #brksive 
		--WHERE 
		--	AND codeSva = '20479860001'

		DROP TABLE #brksive1
		--DROP TABLE #brksive
		--DROP TABLE #brksive2

	END TRY
	BEGIN CATCH
		SET @msg = (SELECT SUBSTRING(ERROR_MESSAGE(), 1, 300))
		RAISERROR(@msg, 16, 1)
		RETURN
	END CATCH
END

-- EXEC SIGAQ.dbo.sp_getBrokenessUser 'luismer'