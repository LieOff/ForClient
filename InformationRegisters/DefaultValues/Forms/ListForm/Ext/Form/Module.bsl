
#Region CommonProcedureAndFunctions

&AtServer
Procedure FillRegisterAtServer()
	
	CommonProcessors.FillDefaultValuesInformationRegister();
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure FillRegister(Command)
	
	FillRegisterAtServer();
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion