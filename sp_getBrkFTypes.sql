USE CATALOGOS
GO

ALTER PROCEDURE [dbo].[sp_getBrkFTypes]
AS
BEGIN
	SELECT *
	FROM CATALOGOS.dbo.tc_brkFinanceType

	SELECT 
		dep.id_departamento
		, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS branchOffice
	FROM CATALOGOS.dbo.tc_departamento dep
END

--EXEC CATALOGOS.dbo.sp_getBrkFTypes