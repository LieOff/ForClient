
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If HaveRightToRead() Then 
	
		OpenForm("Report.SKUChangeAnalysis.Form", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
		
	Else 
		
		ShowMessageBox( , NStr("en='Are not authorized to view the report.';ru='Нет прав для просмотра отчета.';cz='Nemáte oprávnění k danému typu výkazu.'"), , );
		
	EndIf;
	
EndProcedure

&AtServer
Function HaveRightToRead()
	
	If IsInRole("Admin") Then 
		
		Return True;
		
	Else 
		
		Return Users.HaveRightToRead(Catalogs.SystemObjects.Report_SKUChangeAnalysis);
		
	EndIf;
	
EndFunction
