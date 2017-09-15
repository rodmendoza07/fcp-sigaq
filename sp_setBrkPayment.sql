USE CATALOGOS
GO

ALTER PROCEDURE [dbo].[sp_setBrkPayment](
	@empNumber INT
	, @paymentAmount DECIMAL(18,4)
	, @paymentDate VARCHAR(20)
	, @cUser VARCHAR(15)
)
AS
BEGIN
	DECLARE
		@empId INT
		, @empUser VARCHAR(15)
		, @msg VARCHAR(300) = ''
		, @amountAcum DECIMAL(18,4)
		, @amountTotal DECIMAL(18,4)
		, @wAmount DECIMAL(18,4)
		, @codeSva VARCHAR(20)
		, @wId INT
		, @lastpay INT
		, @paycDate DATETIME

	BEGIN TRY
		SELECT
			@empId = emp.id_empleados
			, @empUser = emp.usuario
		FROM CATALOGOS.dbo.tc_empleados emp
		WHERE emp.noemp = @empNumber

		SELECT @empId, @empUser

		SELECT
			@amountAcum = ISNULL(SUM(pay.brkp_amount),0)
		FROM CATALOGOS.dbo.tp_brkPayments pay
		WHERE pay.brkp_Eid = @empId
			AND pay.brkp_paymentApp = 1

		SELECT
			@amountTotal = @amountAcum + @paymentAmount

		SELECT @amountTotal

		WHILE @amountTotal > 0
		BEGIN
			SELECT
				@wId = wp.brkwp_id
				, @codeSva = wp.brkwp_codeSva
				, @wAmount = wp.brkwp_amount
			FROM CATALOGOS.dbo.tp_brkWarrantyToPay wp
			WHERE wp.brkwp_brkUser = @empUser
				AND wp.brkwp_codeSva NOT IN (SELECT
												pay.brkp_codeSvaApp
											 FROM CATALOGOS.dbo.tp_brkPayments pay
											 WHERE pay.brkp_payUser = @empUser 
												AND pay.brkp_cDate = )
			ORDER BY wp.brkwp_brkDate DESC

			SELECT @wId, @codeSva

			--select @amountTotal = @amountTotal - 10
			INSERT INTO CATALOGOS.dbo.tp_brkPayments (
				brkp_Eid
				, brkp_nemp
				, brkp_payUser
				, brkp_cUser
				, brkp_amount
				, brkp_cDate
			) VALUES (
				@empId
				, @empNumber
				, @empUser
				, @cUser
				, @paymentAmount
				, @paymentDate
			)

			SELECT @lastpay = @@IDENTITY

			IF @wAmount <= @amountTotal BEGIN
				UPDATE CATALOGOS.dbo.tp_brkPayments SET
					brkp_paymentApp = 0
					, brkp_codeSvaApp = @codeSva
			END

		END

		select 
		'sale'
		, @amountTotal

		SELECT
			@wId = wp.brkwp_id
			, @codeSva = wp.brkwp_codeSva
			, @wAmount = wp.brkwp_amount
		FROM CATALOGOS.dbo.tp_brkWarrantyToPay wp
		WHERE wp.brkwp_brkUser = @empUser
			AND wp.brkwp_codeSva NOT IN (SELECT
											pay.brkp_codeSvaApp
										 FROM CATALOGOS.dbo.tp_brkPayments pay)
		ORDER BY wp.brkwp_brkDate DESC

		SELECT @wId, @codeSva

		--BEGIN TRAN
		--INSERT INTO 


		--IF @@TRANCOUNT > 0 
		--	COMMIT TRAN

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = (SELECT SUBSTRING(ERROR_MESSAGE(), 1, 300))
		RAISERROR(@msg, 16, 1)
	END CATCH
END

-- EXEC CATALOGOS.dbo.sp_setBrkPayment 972, 65, '20170913', 'luismer'