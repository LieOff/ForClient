
Procedure UpdateDatabase() Export  

	UpdateResult = UpdateDatabase.StartUpdate();
	
	If UpdateResult.NeedRestart Then 
		
		Terminate(True);
		
	Else 
		
		If UpdateResult.NeedUpdate Then 
			
			If UpdateResult.UpdateComplete Then
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en='Database update completed successfully';ru='Обновление базы данных выполнено успешно';cz='Aktualizace databáze byla ukončena úspěšně'");
				
				UserMessage.Message();
				
			Else
				
				ShowMessageBox(New NotifyDescription("ExitSystem", CommonProcessorsClient), UpdateResult.Error); 
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckAccessToDataBase() Export  

	ErrorText = Users.CheckAccessToDataBase();
	
	If ValueIsFilled(ErrorText) Then 
		
		ShowMessageBox(New NotifyDescription("ExitSystem", CommonProcessorsClient), ErrorText); 
		
	EndIf;
	
EndProcedure

Procedure ExitSystem(AdditionalParameter) Export 
	
	Terminate();
	
EndProcedure

Function ExecuteJSFunction(FunctionName, ParamArray) Export 
	
	StartPage = Undefined;
	
	AppWindows = GetWindows();
	
	For Each AppWindow in AppWindows Do 
		
		If AppWindow.StartPage Then 
			
			StartPage = AppWindow.Content[0];
			
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not StartPage = Undefined Then 
		
		If FunctionName = "checkRegExp" Then 
			
			Pattern	= ParamArray[0];
			Str		= ParamArray[1];
			
			Str = StrReplace(Str, "'", "\'");
			
			StartPage.Items.Logo.document.getElementById("WebClientOperation").value = FunctionName + "(" + Pattern + ",'" + Str + "')";
			StartPage.Items.Logo.document.getElementById("WebClient").click();
			
			Result = StartPage.Items.Logo.document.getElementById("Result").value;
			
			If Result = "true" Then 
				
				Return True;
				
			Else 
				
				Return False;
				
			EndIf;
			
		EndIf;
		
	EndIf;
		
EndFunction