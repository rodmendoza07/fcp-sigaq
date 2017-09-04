USE SIGAQ
GO

ALTER PROCEDURE [dbo].[sp_getBrokenessUser](
	@user VARCHAR(20) = ''
	, @startdate VARCHAR(15) = ''
	, @enddate VARCHAR(15) = ''
)
AS
BEGIN
	DECLARE
		--@siveDate VARCHAR(20) = '20170201'
		@msg VARCHAR(300) = ''

	CREATE TABLE #brk_user (
		norows INT
		, codeSva VARCHAR(20)
		, amount DECIMAL(18,4)
		, [description] VARCHAR(300)
		, createDate DATETIME
		, createUser VARCHAR(10)
	)

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
				INNER JOIN INVENTARIO.dbo.td_brokenness chkbd ON (chkb.bkn_id = chkbd.bkn_id AND chkbd.bknd_status = 1)
				INNER JOIN SVA.dbo.T_GARANTIA tgar ON (chk.wlc_codeSVA = tgar.sCODIGOBARRAS)
			WHERE wlc_respStageUser = @user
				AND (chk.sinv_id = 52)
				AND ((CONVERT(varchar, chk.wlc_createDate, 112) BETWEEN @startdate AND @enddate)
					OR (@startdate = '' AND @enddate = ''))
		)
		SELECT 
			*
		INTO #brksive1
		FROM cte_userbrkSive
 
		;WITH cte_userbrkSive1 AS (
			SELECT
				ROW_NUMBER() OVER(ORDER BY brk.lbrokeness_date ASC) AS [norows]
				, * 
			FROM SVA.dbo.td_brokenessLog brk
			WHERE ((CONVERT(varchar, brk.lbrokeness_date, 112) BETWEEN @startdate AND @enddate)
					OR (@startdate = '' AND @enddate = ''))
		)

		SELECT sive.*
		INTO #brksive
		FROM #brksive1 sive
			INNER JOIN cte_userbrkSive1 b on (sive.norows = b.norows)

		;WITH cte_userbrkInventory AS (
			SELECT 
				ROW_NUMBER() OVER(ORDER BY inv.wlc_codeSva) AS [norows]
				, wlc_codeSVA AS codeSva
				, wlc_amount AS amount
				, i.descripcion AS [description]
				, inv.wlc_createDate AS createDate
				, inv.wlc_createUser AS createUser
			FROM INVENTARIO.dbo.tp_checkListWarranty inv
				INNER JOIN INVENTARIO.dbo.tp_inventarios i ON (inv.wlc_codeSVA = i.codigo_garantia)
			WHERE wlc_respStageUser = @user
				AND sinv_id = 51
				AND wlc_codeSVA NOT IN (SELECT DISTINCT codeSVA FROM SVA.dbo.td_brokenessLog)
		)
		SELECT 
			* 
		INTO #inventario1
		FROM cte_userbrkInventory

		INSERT INTO #brk_user(
			norows
			, codeSva
			, amount
			, [description]
			, createDate
			, createUser
		)
		SELECT
			b.*
		FROM #brksive b
		UNION
		SELECT *
		FROM #inventario1

		SELECT *
		FROM #brk_user

		DROP TABLE #brksive1
		DROP TABLE #brksive
		DROP TABLE #inventario1
		DROP TABLE #brk_user

	END TRY
	BEGIN CATCH
		SET @msg = (SELECT SUBSTRING(ERROR_MESSAGE(), 1, 300))
		RAISERROR(@msg, 16, 1)
		RETURN
	END CATCH
END

-- EXEC SIGAQ.dbo.sp_getBrokenessUser 'gvargas', '20170901', '20170902'