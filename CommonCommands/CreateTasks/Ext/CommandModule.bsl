
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters) Export  
	
	Если CommandExecuteParameters.Source.FormName  = "Catalog.Outlet.Form.ListForm" Тогда
		Outlet = CommandExecuteParameters.Source.CurrentItem.CurrentRow;
		Territory = GetTerritory_(Outlet);
		FormParameters = New Structure("Outlet,Territory",CommandExecuteParameters.Source.CurrentItem.CurrentRow,Territory);
	Иначе
		Outlet = CommandExecuteParameters.Source.Object.Ref;
		Territory = GetTerritory_(Outlet);
		FormParameters = New Structure("Outlet,Territory", CommandExecuteParameters.Source.Object.Ref,Territory);
	КонецЕсли;
	OpenForm("Document.Task.ObjectForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

&AtServer
Function GetTerritory_(Outlet)
	Возврат CommonProcessors.GetTerritory(Outlet)	
EndFunction





