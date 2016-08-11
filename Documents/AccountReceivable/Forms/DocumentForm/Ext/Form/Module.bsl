&AtServer
Procedure OnOpenServer()
	
	Items.Number.ReadOnly = Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditDocumentNumbers);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenServer();

EndProcedure
