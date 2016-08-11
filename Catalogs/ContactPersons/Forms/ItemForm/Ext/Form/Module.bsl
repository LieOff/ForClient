
#Region UserInterface

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not Cancel Then
		
		// Выполнить валидацию телефонного номера
		If ValueIsFilled(Object.PhoneNumber) Then 
			
			ParamArray = New Array;
			ParamArray.Add("/^((8|\+7)[\- ]?)?(\(?\d{3,4}\)?[\- ]?)?[\d\- ]{5,10}$/");
			ParamArray.Add(Object.PhoneNumber);
			
			If Not CommonProcessorsClient.ExecuteJSFunction("checkRegExp", ParamArray) Then 
				
				Cancel = True;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en='Incorrect value in the ""Phone number""';ru='Неверное значение в поле ""Телефонный номер""';cz='Incorrect value in the ""Phone number""'");
				
				UserMessage.Message();
				
			EndIf;
			
		EndIf;
		
		// Выполнить валидацию почты
		If ValueIsFilled(Object.Email) Then
			
			ParamArray = New Array;
			ParamArray.Add("/^([а-яА-ЯёЁa-zA-Z0-9_-]+\.)*[а-яА-ЯёЁa-zA-Z0-9_-]+@[а-яА-ЯёЁa-zA-Z0-9_-]+(\.[а-яА-ЯёЁa-zA-Z0-9_-]+)*\.[а-яА-ЯёЁa-zA-Z]{2,6}$/");
			ParamArray.Add(Object.Email);
			
			If Not CommonProcessorsClient.ExecuteJSFunction("checkRegExp", ParamArray) Then 
				
				Cancel = True;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en='Incorrect value in the field ""E-mail""';ru='Неверное значение в поле ""E-mail""';cz='Incorrect value in the field ""E-mail""'");
				
				UserMessage.Message();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Update");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
EndProcedure

#EndRegion