
Procedure CreateAdmin() Export 
	
	UsersCallServer.CreateFirstAdmin();
	
	Raise "Обнаружен запуск с пустым списком пользователей. Создан пользователь ""Admin"" с пустым паролем. Повторите запуск системы.";
	
EndProcedure

 
