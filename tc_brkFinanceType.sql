USE CATALOGOS
GO

CREATE TABLE tc_brkFinanceType(
	brkf_id INT NOT NULL IDENTITY(1,1)
	, brkf_type VARCHAR(50) NOT NULL CONSTRAINT def_brkf_type DEFAULT ('')
)

INSERT INTO tc_brkFinanceType (
	brkf_type
) VALUES
	('Reporte')
	, ('Faltante de efectivo')
	, ('Remanente de Bono')