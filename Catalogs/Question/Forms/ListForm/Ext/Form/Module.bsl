
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not IsInRole("Admin") Then 
		
		Cancel = True;
		
	EndIf;
	
EndProcedure
