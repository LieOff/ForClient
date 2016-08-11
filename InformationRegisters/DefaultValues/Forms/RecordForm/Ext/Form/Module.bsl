
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Record.TabularSection) Then 
		
		Description = Record.Object + "." + Record.TabularSection + "." + Record.Attribute;
		
	Else 
		
		Description = Record.Object + "." + Record.Attribute;
		
	EndIf;
	
	Items.Value.TypeRestriction = New TypeDescription(Record.TypeName);
	
EndProcedure

#EndRegion