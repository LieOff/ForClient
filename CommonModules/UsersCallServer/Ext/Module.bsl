
Function UsersListIsEmpty() Export 
	
	If PrivilegedMode() Then 
		
		// Выполнен запуск в привилегированном режиме
		// (параметр командной строки "/UsePrivilegedMode").
		//
		// В этом режиме пользователь имеет все права,
		// первого администратора не требуется создавать.
		Return False;
		
	EndIf;
	
	CurrentUser = InfoBaseUsers.CurrentUser();
	
	If ValueIsFilled(CurrentUser.Name) Then 
		
		// Список пользователей ИБ не пустой.
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

Procedure CreateFirstAdmin() Export 
	
	SetPrivilegedMode(True);
		
	FirstAdmin							= InfoBaseUsers.CreateUser();
	FirstAdmin.Name						= "Admin";
	FirstAdmin.FullName					= FirstAdmin.Name;
	FirstAdmin.Language					= Metadata.Languages.Русский;
	FirstAdmin.StandardAuthentication	= True;
	FirstAdmin.ShowInList				= True;
	
	FirstAdmin.Roles.Add(Metadata.Roles.Admin);
	
	FirstAdmin.Write();
	
EndProcedure

Function GetRandomNumber(Start, End)
	
	RNG = New RandomNumberGenerator();
	RandomNumber = RNG.RandomNumber(Start, End);
	
	Return RandomNumber;
	
EndFunction

Function GenerateRandomUsername() Export
	
	Return Format(GetRandomNumber(1, 9999), "ND=4; NLZ=; NG=0");
	
EndFunction

Function GenerateRandomPassword() Export
	
	Return Format(GetRandomNumber(1, 999999), "ND=6; NLZ=; NG=0");
	
EndFunction