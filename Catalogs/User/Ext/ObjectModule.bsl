
Procedure BeforeWrite(Cancel)
	
	If Not Cancel Then 
		
		If Lower(UserName) = "demo" Then
			
			Password = "demo";
			
		EndIf;
		
		If Lower(UserName) = "demoaccess" Then
			
			Password = "password";
			
		EndIf;
		
		If Not ValueIsFilled(RoleOfUser) Then 
			
			Role = "Admin";
			
		EndIf;
		
		If Not Role = "Admin" Then 
			
			Role = "SR";
			
			If RoleOfUser.Role = "Unknown" Then 
				
				Role = "Unknown";
				
			ElsIf RoleOfUser.Role = "SRM" Then
				
				Role = "SRM";
				
			EndIf;
			
			// Создать пользователя и установить UserID
			ParametersStructure = New Structure();
			ParametersStructure.Insert("FullName", Description);
			ParametersStructure.Insert("UserName", UserName);
			ParametersStructure.Insert("UserID", UserID);
			ParametersStructure.Insert("Role", Role);
			SetPrivilegedMode(True);
			If Not(InfoBaseUsers.FindByUUID(Новый УникальныйИдентификатор(UserID))=Undefined) Then
				If InfoBaseUsers.FindByUUID(Новый УникальныйИдентификатор(UserID)).CannotChangePassword=False Then
					ParametersStructure.Insert("Password", Password);
				EndIf;
				ParametersStructure.Insert("CanNotChangePass", InfoBaseUsers.FindByUUID(Новый УникальныйИдентификатор(UserID)).CannotChangePassword);
			Else
				ParametersStructure.Insert("Password", Password);
			EndIf;
			ParametersStructure.Insert("InterfaceLanguage", InterfaceLanguage);
			UserID = Users.CreateUser(ParametersStructure);
			SetPrivilegedMode(False);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure SendMessage() Export
	
	If TrimAll(EMail) = "" Then
		
		Return;
		
	EndIf;
		
	Recepients = New Array;
	Recepients.Add(EMail);
	
	Theme = NStr("ru = 'Данные для доступа в мобильное приложение БИТ.СуперАгент'");
	
	Body = "Имя пользователя: " + UserName + Chars.CR + "Пароль: " + Password;
	
	Message = DataProcessors.bitmobile_СинхронизацияИНастройки.ПолучитьПочтовоеСообщение(Recepients, Theme, Body);
	
	DataProcessors.bitmobile_СинхронизацияИНастройки.ОтправитьСообщение(Message);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	a=1;
EndProcedure
