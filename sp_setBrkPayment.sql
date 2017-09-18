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
		, @wAmount DECIMAL(18,4) = 0
		, @codeSva VARCHAR(20) = '-1'
		, @wId INT = -1
		, @lastpay INT
		, @paycDate DATETIME = GETDATE()
		, @aux INT = 0
		, @payment DECIMAL(18,4)
		, @paymentAppAux INT = 1

	BEGIN TRY
		BEGIN TRAN
		SELECT
			@empId = emp.id_empleados
			, @empUser = emp.usuario
		FROM CATALOGOS.dbo.tc_empleados emp
		WHERE emp.noemp = @empNumber

		SELECT
			@amountAcum = ISNULL(SUM(pay.brkp_amount),0)
		FROM CATALOGOS.dbo.tp_brkPayments pay
		WHERE pay.brkp_Eid = @empId
			AND pay.brkp_paymentApp = 1

		SET @amountTotal = @amountAcum + @paymentAmount

		WHILE @amountTotal > 0
		BEGIN

			SELECT
				@wId = wp.brkwp_id
				, @codeSva = wp.brkwp_codeSva
				, @wAmount = wp.brkwp_amount
				, @paycDate = wp.brkwp_brkDate
			FROM CATALOGOS.dbo.tp_brkWarrantyToPay wp
			WHERE wp.brkwp_brkUser = @empUser
				AND wp.brkwp_paymentAppId = 0
			ORDER BY wp.brkwp_brkDate DESC

			IF @wAmount <= @amountTotal BEGIN

				IF @amountAcum > 0 BEGIN
					IF @wId = -1  AND @wAmount = 0 BEGIN
						IF @aux > 0 BEGIN
							SET @payment = @amountTotal - @wAmount
						END
						ELSE BEGIN
							SET @payment = @paymentAmount
						END
						SET @codeSva = '-1'
					END
					IF @wAmount < @amountTotal AND @wAmount > 0 BEGIN
						SET @payment = @wAmount - @amountAcum
						select @payment as pay12, @amountAcum , @amountTotal
						--break
					END
					ELSE IF @wAmount <> 0 BEGIN
						SET @payment = @wAmount - @amountAcum
					END
				END
				ELSE BEGIN
					IF @wId = -1 AND @wAmount = 0 BEGIN
						SELECT @amountTotal as singar
						SET @payment = @amountTotal
						SET @codeSva = '-1'
						SET @paymentAppAux = 1
					END
					IF @wAmount < @amountTotal AND @wAmount > 0 BEGIN
						SET @payment = @wAmount
						SET @paymentAppAux = 0
					END
					ELSE IF @wAmount <> 0 BEGIN
						SET @payment = @amountTotal
						SET @paymentAppAux = 0
					END
				END

				INSERT INTO CATALOGOS.dbo.tp_brkPayments (
					brkp_Eid
					, brkp_nemp
					, brkp_payUser
					, brkp_cUser
					, brkp_amount
					, brkp_cDate
					, brkp_brkDate
					, brkp_codeSvaApp
					, brkp_paymentApp
				) VALUES (
					@empId
					, @empNumber
					, @empUser
					, @cUser
					, @payment
					, @paymentDate
					, @paycDate
					, @codeSva
					, @paymentAppAux
				)

				SELECT @lastpay = @@IDENTITY
				
				IF @wId = -1 BEGIN
					SET @amountTotal  = 0
				END
				ELSE BEGIN
					UPDATE CATALOGOS.dbo.tp_brkWarrantyToPay SET
						brkwp_paymentAppId = @lastpay
						, brkwp_paymentAppDate = @paymentDate
					WHERE brkwp_id = @wId

					IF @amountAcum > 0 BEGIN
						UPDATE CATALOGOS.dbo.tp_brkPayments SET
							brkp_paymentApp = 0
						WHERE brkp_payUser = @empUser
							AND brkp_codeSvaApp = @codeSva
							AND brkp_brkDate = @paycDate
					END

					SET @amountTotal = @amountTotal - @wAmount
					SET @aux = @aux + 1
					SET @payment = 0
				END
			END
			ELSE BEGIN
				IF @aux > 0 BEGIN
					SET @payment = @amountTotal
				END
				ELSE BEGIN
					SET @payment = @paymentAmount
				END
				
				INSERT INTO CATALOGOS.dbo.tp_brkPayments (
					brkp_Eid
					, brkp_nemp
					, brkp_payUser
					, brkp_cUser
					, brkp_amount
					, brkp_cDate
					, brkp_brkDate
					, brkp_codeSvaApp
				) VALUES (
					@empId
					, @empNumber
					, @empUser
					, @cUser
					, @payment
					, @paymentDate
					, @paycDate
					, @codeSva
				)

				SET @amountTotal = 0
			END

			SET @wId = -1
			SET @codeSva = ''
			SET @wAmount = 0
		END

		SET @aux = 0
		IF @@TRANCOUNT > 0 
			COMMIT TRAN

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = (SELECT SUBSTRING(ERROR_MESSAGE(), 1, 300))
		RAISERROR(@msg, 16, 1)
	END CATCH
END

-- EXEC CATALOGOS.dbo.sp_setBrkPayment 972, 65, '20170913', 'luismer'