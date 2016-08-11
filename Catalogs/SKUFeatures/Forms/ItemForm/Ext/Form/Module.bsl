
&AtClient
Procedure FeaturesValueOnChange(Item)
    Name = "";
    For Each FeaturesRow In Object.Features Do
        Name = ? (Name = "", String(FeaturesRow.Value), (Name + ", " + String(FeaturesRow.Value)));
    EndDo;
    Object.Description = Name;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure

