USE CATALOGOS
GO

ALTER PROCEDURE [dbo].[sp_setBrkPayment](
	@empNumber INT
	, @paymentAmount DECIMAL(18,4)
	, @paymentDate VARCHAR(20)
	, @cUser INT = 0
	, @opt INT = 0
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
		, @countUser INT = 0
		, @createUser VARCHAR(15) = ''
		, @employees INT = 0
		, @employees1 INT = 0
		, @amountCero INT = 0
		, @rowCounter INT = 1
	
	IF @opt = 0 BEGIN
		SELECT
			usuario
		FROM CATALOGOS.dbo.tc_empleados
		WHERE id_empleados = @cUser
			AND estatus = 1
	END

	IF @opt = 2 BEGIN
		BEGIN TRY
			IF @paymentAmount <= 0 BEGIN
				SET @msg = 'No se pueden abonar cantidades en Cero'
				RAISERROR(@msg, 16, 1)
				RETURN
			END
		END TRY
		BEGIN CATCH
			IF @msg = '' BEGIN
				SET @msg = (SELECT SUBSTRING(ERROR_MESSAGE(), 1, 300))
			END
			RAISERROR(@msg, 16, 1)
		END CATCH
	END

	IF @opt = 3 BEGIN

		CREATE TABLE #tmpFile(
			noemp VARCHAR(15)
			, amount DECIMAL(18,4)
			, paymentDate DATETIME
		)
		
		BULK INSERT #tmpFile
		FROM 'E:\web\repositorios\20170921140045.csv'
		WITH
		(
			FIELDTERMINATOR =',',
			ROWTERMINATOR ='\n'
		) 

		SELECT 
			@employees = COUNT(DISTINCT noemp) 
		FROM #tmpFile

		SELECT
			 emp.id_empleados
			, emp.usuario
		INTO #employees
		FROM CATALOGOS.dbo.tc_empleados emp
		WHERE emp.noemp IN (SELECT noemp FROM #tmpFile)

		SELECT 
			@employees1 = COUNT(*)
		FROM #employees

		IF @employees = @employees1 BEGIN
			SELECT
				*
			FROM #employees
		END
		ELSE BEGIN
			SET @msg = 'Empleados no coinciden'
			RAISERROR(@msg, 16, 1)
			RETURN
		END

		SELECT
			@amountCero = COUNT(amount)
		FROM #tmpFile
		WHERE amount <= 0

		IF @amountCero > 0 BEGIN
			SET @msg = 'No se pueden abonar cantidades en Cero'
			RAISERROR(@msg, 16, 1)
			RETURN
		END

		SELECT
			ROW_NUMBER() OVER(ORDER BY paymentDate ASC) AS [norows]
			, tmp.*
		INTO #tmpFile1
		FROM #tmpFile tmp

		SELECT
			amount
		FROM #tmpFile
		
		BEGIN TRY
			BEGIN TRAN
			WHILE @rowCounter <= (SELECT MAX(norows) FROM #tmpFile1)
			BEGIN
				SELECT
					@createUser = usuario
				FROM CATALOGOS.dbo.tc_empleados
				WHERE id_empleados = @cUser

				select @createUser

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
				SELECT @amountTotal

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
							, @createUser
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
							, @createUser
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
				
				SET @rowCounter = @rowCounter + 1
			END
			SELECT @rowCounter
			IF @@TRANCOUNT > 0 
				COMMIT TRAN
				SELECT 'SUCCESS' AS success
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
			IF @msg = '' BEGIN
				SET @msg = (SELECT SUBSTRING(ERROR_MESSAGE(), 1, 300))
			END
			RAISERROR(@msg, 16, 1)
		END CATCH
			

		DROP TABLE #tmpFile
		DROP TABLE #employees
	END

	IF @opt = 4 BEGIN
		BEGIN TRY
			/*
			IF @paymentAmount <= 0 BEGIN
				SET @msg = 'No se pueden abonar cantidades en Cero'
				RAISERROR(@msg, 16, 1)
				RETURN
			END*/

			SELECT
				@createUser = usuario
			FROM CATALOGOS.dbo.tc_empleados
			WHERE id_empleados = @cUser

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
						, @createUser
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
						, @createUser
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
				SELECT 'SUCCESS' AS success

		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
			IF @msg = '' BEGIN
				SET @msg = (SELECT SUBSTRING(ERROR_MESSAGE(), 1, 300))
			END
			RAISERROR(@msg, 16, 1)
		END CATCH
	END
END

-- EXEC CATALOGOS.dbo.sp_setBrkPayment 972, 65, '20170913', 1024, 3