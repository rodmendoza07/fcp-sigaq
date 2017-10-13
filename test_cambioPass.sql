select id_empleados, usuario, clave, cve_depto, cve_puesto, * from CATALOGOS.dbo.tc_empleados 
where (nombre like '%cesiah%' or nombre like 'monica' or nombre like 'renan' or nombre like 'ivan') and estatus = 1

select * from CATALOGOS.dbo.tc_puesto where id_puesto in (4,6)
select * from CATALOGOS.dbo.tc_departamento where id_departamento in (1000, 9100)

select * from CATALOGOS.dbo.te_users_passw_encrypt where peusr_user_id = 52

--Pass Porvenir#24

update CATALOGOS.dbo.te_users_passw_encrypt set
	peusr_passw_encrypt = 'b8b1317c98a8c50f21105c465f4e38bb',
	peusr_passw_encrypt_reset = 0,
	peusr_passw_encrypt_lock = 0
where peusr_user_id = 3

update CATALOGOS.dbo.te_users_passw_encrypt set
	peusr_passw_encrypt = 'e07e5f71ed282fcc038531a9f00fdc9a',
	peusr_passw_encrypt_reset = 0,
	peusr_passw_encrypt_lock = 0
where peusr_user_id = 588

update CATALOGOS.dbo.te_users_passw_encrypt set
	peusr_passw_encrypt = '8b2d4b06f536eeb44da86f9b72257d42',
	peusr_passw_encrypt_reset = 0,
	peusr_passw_encrypt_lock = 0
where peusr_user_id = 1130

update CATALOGOS.dbo.te_users_passw_encrypt set
	peusr_passw_encrypt = 'ea7a7a68ca0553f9adb0d3ebec750920',
	peusr_passw_encrypt_reset = 0,
	peusr_passw_encrypt_lock = 0
where peusr_user_id = 362