USE CATALOGOS
GO

CREATE TABLE tp_brkEmpFAsign (
	brkemp_id INT NOT NULL IDENTITY(1,1)
	, brkemp_type INT NOT NULL CONSTRAINT DEF_brkemp_type DEFAULT(0)
	, brkemp_amount DECIMAL(18,4) NOT NULL CONSTRAINT DEF_brkemp_amount DEFAULT(0)
	, brkemp_empNumber INT NOT NULL CONSTRAINT DEF_brkemp_empNumber DEFAULT(0)
	, brkemp_userName VARCHAR(15) NOT NULL CONSTRAINT DEF_brkemp_userName DEFAULT('')
	, brkemp_empId INT NOT NULL CONSTRAINT DEF_brkemp_empId DEFAULT(-1)
	, brkemp_cUser VARCHAR(15) NOT NULL CONSTRAINT DEF_brkemp_cUser DEFAULT('')
	, brkemp_cDate DATETIME NOT NULL CONSTRAINT DEF_brkemp_cDate DEFAULT(GETDATE())
)