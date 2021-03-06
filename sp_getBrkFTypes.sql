USE CATALOGOS
GO

CREATE PROCEDURE [dbo].[sp_getBrkFTypes]
AS
BEGIN
	SELECT *
	FROM CATALOGOS.dbo.tc_brkFinanceType

	SELECT 
		dep.id_departamento AS brk_boId
		, REPLICATE('0', 5 - LEN(dep.id_departamento)) + CAST(dep.id_departamento AS varchar) + ' - ' + dep.descripcion AS brk_bo
	FROM CATALOGOS.dbo.tc_departamento dep
	--WHERE dep.id_departamento < 300
END

--EXEC CATALOGOS.dbo.sp_getBrkFTypes