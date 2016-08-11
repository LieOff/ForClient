
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandExecuteParameters.Source.FormName  = "Catalog.Outlet.Form.ListForm" Then
		
		FilterValue = New Structure("Outlet",CommandExecuteParameters.Source.CurrentItem.CurrentRow);
		
	Else
		
		FilterValue = New Structure("Outlet", CommandExecuteParameters.Source.Object.Ref);
		
	EndIf;
	
	FilterParameters = New Structure("Filter", FilterValue);
	OpenForm("Document.Task.ListForm", FilterParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
