/*
Missing Index Details from SQLQuery1.sql - 192.168.1.10.master (procesador1 (69))
The Query Processor estimates that implementing the following index could improve the query cost by 89.1299%.
*/


USE [INVENTARIO]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[tp_checkListWarranty] ([sinv_id],[wlc_respStageUser])
INCLUDE ([wlc_codeSVA],[wlc_amount],[wlc_createUser],[wlc_createDate])
GO

