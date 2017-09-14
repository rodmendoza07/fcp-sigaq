USE CATALOGOS
GO

CREATE TABLE tp_brkWarrantyToPay (
	brkwp_id INT NOT NULL IDENTITY(1,1)
	, brkwp_origin VARCHAR(50) NOT NULL CONSTRAINT DEF_brkwp_origin DEFAULT('')
	, brkwp_codeSva VARCHAR(20) NOT NULL CONSTRAINT DEF_brkwp_codeSva DEFAULT('')
	, brkwp_branchOffice INT NOT NULL CONSTRAINT DEF_brkwp_branchOffice DEFAULT('')
	, brkwp_amount DECIMAL(18,4) NOT NULL CONSTRAINT DEF_brkwp_amount DEFAULT(0)
	, brkwp_brkUser VARCHAR(20) NOT NULL CONSTRAINT DEF_brkwp_brkUser DEFAULT('')
	, brkwp_brkDate DATETIME NOT NULL CONSTRAINT DEF_brkwp_brkDate DEFAULT(GETDATE())
	, brkwp_paymentAppId INT NOT NULL CONSTRAINT DEF_brkwp_paymentAppId DEFAULT(0)
	, brkwp_paymentAppDate DATETIME NOT NULL CONSTRAINT DEF_brkwp_paymentAppDate DEFAULT(GETDATE())
)