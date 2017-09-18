USE CATALOGOS
GO

ALTER PROCEDURE [dbo].[sp_setBrkFinance](
	@brkType INT
	, @brkBo INT
	, @brkAmount DECIMAL(18,4)
	, @brkEnumber INT
	, @brkUserName VARCHAR(15)
	, @brkEId INT
	, @cUser INT
	, @brkDate VARCHAR(20)
	, @brkComment VARCHAR(350)
)
AS
BEGIN
	DECLARE
		@userName VARCHAR(15) = ''
		, @msg VARCHAR(300) = ''

	BEGIN TRY
		
		SELECT
			@userName = usuario
		FROM CATALOGOS.dbo.tc_empleados
		WHERE id_empleados = @cUser
		
		BEGIN TRAN 
			INSERT INTO CATALOGOS.dbo.tp_brkEmpFAsign(
				brkemp_type
				, brkemp_branchOffice
				, brkemp_amount
				, brkemp_empNumber
				, brkemp_userName
				, brkemp_empId
				, brkemp_cUser
				, brkemp_brkDate
				, brkemp_comment
			) VALUES (
				@brkType
				, @brkBo
				, @brkAmount
				, @brkEnumber
				, @brkUserName
				, @brkEId
				, @userName
				, @brkDate
				, @brkComment
			)
		COMMIT TRAN
		SELECT 'SUCCESS' AS success
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = (SELECT SUBSTRING(ERROR_MESSAGE(), 1, 300))
		RAISERROR(@msg, 16, 1)
	END CATCH
END