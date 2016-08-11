&AtClient
Procedure OnOpen(Cancel)
    
    OnOpenServer();

EndProcedure

&AtServer
Procedure OnOpenServer()
	
	Items.Number.ReadOnly = Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditDocumentNumbers);
	
	If IsInRole("Admin") = False Then
        ThisForm.ReadOnly = True;
    EndIf;    

EndProcedure