
Procedure OnWrite(Cancel)
	
	If Not ThisObject.Value = Catalogs.MobileAppSettings.MultistockEnabled.LogicValue Then 
		
		MultistockEnabledObject				= Catalogs.MobileAppSettings.MultistockEnabled.GetObject();
		MultistockEnabledObject.LogicValue	= ThisObject.Value;
		
		MultistockEnabledObject.Write();
		
	EndIf;
	
EndProcedure
