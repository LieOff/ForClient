
Procedure SessionParametersSetting(RequiredParameters)
	
	Users.SetSessionParameters();
		
	// Удалить настройки пользователя для формы ввода значений
	SystemSettingsStorage.Delete("Document.Questionnaire.Form.Input/Taxi/WindowSettings", Undefined, InfoBaseUsers.CurrentUser().Name);
	SystemSettingsStorage.Delete("Document.Questionnaire.Form.Input/WebClientWindowSettings", Undefined, InfoBaseUsers.CurrentUser().Name);
	
EndProcedure


