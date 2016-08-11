
Procedure BeforeStart(Cancel)
	
	NoUsers = UsersCallServer.UsersListIsEmpty();
	
	If NoUsers Then 
		
		UsersClient.CreateAdmin();
		
	EndIf;
	
EndProcedure

Procedure OnStart()
	
	// Проверить возможность запуска под текущим пользователем
	CommonProcessorsClient.CheckAccessToDataBase();
	
	РегламентныеЗаданияСлужебныйКлиент.ПриНачалеРаботыСистемы();
	
	// Обновление информационной базы
	CommonProcessorsClient.UpdateDatabase();
	
EndProcedure








