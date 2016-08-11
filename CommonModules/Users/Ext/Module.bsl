
Procedure SetSessionParameters() Export 
	
	If Not ValueIsFilled(InfoBaseUsers.CurrentUser().Name) Then 
		
		Return;
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		
		UserNotFound	= False;
		CreateUser		= False;
		CurrentUser		= Undefined;
		
		CurrentInfoBaseUser = InfoBaseUsers.CurrentUser();
		
		If CurrentInfoBaseUser.Language = Undefined Then
			
			CurrentInfoBaseUser.Language = Metadata.Languages.Русский;
			
			CurrentInfoBaseUser.Write();
			
		EndIf;
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED TOP 1
		|	User.Ref AS User
		|FROM
		|	Catalog.User AS User
		|WHERE
		|	User.UserID = &UserID";
		
		Query.SetParameter("UserID", CurrentInfoBaseUser.UUID);
		
		Result = Query.Execute();
		
		If Result.IsEmpty() Then 
			
			If IsInRole("Admin") Then 
				
				CreateUser = True;
				
			Else 
				
				UserNotFound = True;
				
			EndIf;
			
		Else 
			
			Selection = Result.Select();
			
			Selection.Next();
			
			CurrentUser = Selection.User;
			
		EndIf;
		
		If CreateUser Then 
			
			CurrentUser = Catalogs.User.GetRef();
			
			NewAdmin = Catalogs.User.CreateItem();
			
			NewAdmin.Description	= CurrentInfoBaseUser.FullName;
			
			NewAdmin.SetNewObjectRef(CurrentUser);
			
			NewAdmin.Role				= "Admin";
			NewAdmin.UserName			= CurrentInfoBaseUser.Name;
			NewAdmin.UserID				= CurrentInfoBaseUser.UUID;
			NewAdmin.InterfaceLanguage	= CurrentInfoBaseUser.Language.Name;
			
			Try
				
				NewAdmin.Write();
				
			Except
				
				ErrorText = НСтр("en='Authorization failed. System operation is completed."
"User:%1 is not found in catalog ""Users""."
""
"When trying to add a user occurred error:"
"""%2""."
""
"Contact your administrator.';ru='Авторизация не выполнена. Работа системы будет завершена."
"Пользователь: %1 не найден в справочнике ""Пользователи""."
""
"При попытке добавления пользователя возникла ошибка:"
"""%2""."
""
"Обратитесь к администратору.';cz='Autorizace selhala. Systémové operace nebyly ukončeny."
"Uživatel:%1 nebyl nalezen."
""
"Během přidávání uživatele došlo k chybě: ""%2"""
""
"Obraťte se na správce systému.'");
								
				ErrorText = StrReplace(ErrorText, "%1", CurrentInfoBaseUser.Name);
				ErrorText = StrReplace(ErrorText, "%2", BriefErrorDescription(ErrorDescription()));
				
				Raise ErrorText;
				
			EndTry;
			
		ElsIf UserNotFound Then 
			
			ErrorText = НСтр("en='Authorization failed. System operation is completed."
"User:%1 is not found in catalog ""Users""."
""
"Contact your administrator.';ru='Авторизация не выполнена. Работа системы будет завершена."
"Пользователь: %1 не найден в справочнике ""Пользователи""."
""
"Обратитесь к администратору.';cz='Autorizace selhala. Systémové operace nebyly ukončeny."
"Uživatel:%1 nebyl nalezen."
""
"Obraťte se na správce systému.'");
							
			ErrorText = StrReplace(ErrorText, "%1", CurrentInfoBaseUser.Name);
			
			Raise ErrorText;
			
		Else 
			
			If Not CurrentUser.InterfaceLanguage = CurrentInfoBaseUser.Language.Name Then 
				
				CurrentUserObject = CurrentUser.GetObject();
				
				CurrentUserObject.InterfaceLanguage	= CurrentInfoBaseUser.Language.Name;
				
				CurrentUserObject.Write();
				
			EndIf;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Raise;
		
	EndTry;
	
	If CurrentUser = Undefined Then 
		
		ErrorText = НСтр("en='Authorization failed. System operation is completed."
"User:%1 is not found in catalog ""Users""."
""
"Internal error occurred when searching user"
""
"Contact your administrator.';ru='Авторизация не выполнена. Работа системы будет завершена."
"Пользователь: %1 не найден в справочнике ""Пользователи""."
""
"Возникла внутренняя ошибка при поиске пользователя"
""
"Обратитесь к администратору.';cz='Autorizace selhala. Systémové operace nebyly ukončeny."
"Uživatel:%1 nebyl nalezen."
""
"Během vyhledávání uživatele došlo k chybě."
""
"Obraťte se na správce systému.'");
		
		ErrorText = StrReplace(ErrorText, "%1", CurrentInfoBaseUser.Name);
		
		Raise ErrorText;
		
	КонецЕсли;
	
	SessionParameters.CurrentUser = CurrentUser;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure SetRolesOfUsers(RoleOfUsers) Export
	
	RoleToSet = "SR";
	
	If RoleOfUsers.Role = "Unknown" Then 
		
		RoleToSet = "Unknown";
		
	ElsIf RoleOfUsers.Role = "SRM" Then
		
		RoleToSet = "SRM";
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	User.Ref AS User
		|FROM
		|	Catalog.User AS User
		|WHERE
		|	User.RoleOfUser = &RoleOfUsers";
	
	Query.SetParameter("RoleOfUsers", RoleOfUsers);
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		UserObject = Selection.User.GetObject();
		
		If Not Selection.User.Role = RoleToSet And Not Selection.User.Role = "Admin" Then 
			
			UserObject.Role	= RoleToSet;
			
		EndIf;
		
		UserObject.Write();
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

Function CreateUser(Parameters) Export 
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Parameters.UserID) Then 
		
		ProcessedUser = InfoBaseUsers.CreateUser();
		
	Else 
		
		ProcessedUser = InfoBaseUsers.FindByUUID(Parameters.UserID);
		
	EndIf;
	
	If ProcessedUser = Undefined Or Not ValueIsFilled(ProcessedUser.Name) Then 
		
		ProcessedUser = InfoBaseUsers.CreateUser();
		
	EndIf;
	
	If Parameters.Property("CanNotChangePass") Then	
		ProcessedUser.CannotChangePassword	= Parameters.CanNotChangePass;
	Else
		ProcessedUser.CannotChangePassword	= False;
	EndIf;
	ProcessedUser.ShowInList				= False;
	ProcessedUser.RunMode					= ClientRunMode.ManagedApplication;
	ProcessedUser.StandardAuthentication	= True;
	
	ProcessedUser.Name						= Parameters.UserName;
	ProcessedUser.FullName					= Parameters.FullName;
	ProcessedUser.Language					= Metadata.Languages.Find(Parameters.InterfaceLanguage);
	
	Try
		ProcessedUser.Password					= Parameters.Password;
	Except
	EndTry;
	
	ProcessedUser.Roles.Clear();
	ProcessedUser.Roles.Add(Metadata.Roles.User);
	
	ProcessedUser.Write();
	
	SetPrivilegedMode(False);
	
	Return ProcessedUser.UUID;
	
EndFunction

Function HaveRightToRead(SystemObject) Export 
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	User.Ref AS User
		|FROM
		|	Catalog.User AS User
		|		INNER JOIN Catalog.RolesOfUsers.AccessRightsToSystemObjects AS RolesOfUsersAccessRightsToSystemObjects
		|		ON User.RoleOfUser = RolesOfUsersAccessRightsToSystemObjects.Ref
		|WHERE
		|	RolesOfUsersAccessRightsToSystemObjects.SystemObject = &SystemObject
		|	AND RolesOfUsersAccessRightsToSystemObjects.Read = TRUE
		|	AND User.Ref = &CurrentUser";
	
	Query.SetParameter("CurrentUser", SessionParameters.CurrentUser);
	Query.SetParameter("SystemObject", SystemObject);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then 
		
		Return False;
		
	Else 
		
		Return True;
		
	EndIf;
	
EndFunction

Function HaveAdditionalRight(Right) Export 
	
	CurrentPrivilegedMode = PrivilegedMode();
	SetPrivilegedMode(True);
	
	If SessionParameters.CurrentUser.Role = "Admin" Then 
		
		SetPrivilegedMode(CurrentPrivilegedMode);
		Return True;
		
	Else 
		
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	User.Ref AS User
			|FROM
			|	Catalog.User AS User
			|		INNER JOIN Catalog.RolesOfUsers.AdditionalAccessRights AS RolesOfUsersAdditionalAccessRights
			|		ON User.RoleOfUser = RolesOfUsersAdditionalAccessRights.Ref
			|WHERE
			|	User.Ref = &CurrentUser
			|	AND RolesOfUsersAdditionalAccessRights.AccessRight = &Right";
		
		Query.SetParameter("CurrentUser", SessionParameters.CurrentUser);
		Query.SetParameter("Right", Right);
		
		QueryResult = Query.Execute();
		
		SetPrivilegedMode(CurrentPrivilegedMode);
		
		If QueryResult.IsEmpty() Then 
			
			Return False;
			
		Else 
			
			Return True;
			
		EndIf;
		
	EndIf;
	
EndFunction

Function IsFullRightUser(CheckPrivilegedMode = True) Export 
	
	If CheckPrivilegedMode And PrivilegedMode() Then 
		
		Return True;
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	IBUser = InfoBaseUsers.CurrentUser();
	
	If Not ValueIsFilled(IBUser.Name) And Metadata.DefaultRole = Undefined Then 
		
		Return True;
		
	EndIf;
	
	If Not IsInRole(Metadata.Roles.Admin) Then 
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

Function CheckAccessToDatabase() Export
	
	SetPrivilegedMode(True);
	
	CurrUser = SessionParameters.CurrentUser;
	
	If CurrUser.RoleOfUser.Role = "SRM_SR" Or CurrUser.RoleOfUser.Role = "SRM" Or CurrUser.Role = "Admin" Then 
		
		SetPrivilegedMode(False);
		
		Return "";
		
	Else 
		
		ErrorText = НСтр("en = 'User ""%1"" is denied access to information base.
                          |
                          |System operation is completed.
                          |'; ru = 'Пользователю ""%1"" запрещен доступ в информационную базу.
                          |
                          |Работа системы будет завершена.'");
		
		ErrorText = StrReplace(ErrorText, "%1", InfoBaseUsers.CurrentUser().Name);
		
		SetPrivilegedMode(False);
		
		Return ErrorText;
		
	EndIf;
	
EndFunction
