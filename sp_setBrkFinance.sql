USE CATALOGOS
GO

ALTER PROCEDURE [dbo].[sp_setBrkFinance](
	@brkType INT
	, @brkBo INT
	, @brkAmount DECIMAL(18,4)
	, @brkEnumber INT
	, @brkUserName VARCHAR(15)
	, @brkEId INT
	, @cUser VARCHAR(15)
	, @brkDate VARCHAR(20)
)
AS
BEGIN
	BEGIN TRY
		INSERT INTO CATALOGOS.dbo.tp_brkEmpFAsign(
			brkemp_type
			, brkemp_branchOffice
			, brkemp_amount
			, brkemp_empNumber
			, brkemp_userName
			, brkemp_empId
			, brkemp_cUser
		) VALUES (
			@brkType
			, @brkBo
			, @brkAmount
			, @brkEnumber
			, @brkUserName
			, @brkEId
			, @cUser
		)
	END TRY
	BEGIN CATCH
	END CATCH
END