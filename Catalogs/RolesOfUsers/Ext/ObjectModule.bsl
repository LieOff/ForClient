
Procedure BeforeWrite(Cancel)
	
	HasAccessToMobileApp = False;
	
	If Not MobileAppAccessRights.Find(Catalogs.MobileAppAccessRights.AccessToMobileApp) = Undefined Then 
		
		HasAccessToMobileApp = True;
		
	EndIf;
	
	HasAccessTo1C = False;
	
	If Not AccessRightsToSystemObjects.Find(True, "Read") = Undefined Then 
		
		HasAccessTo1C = True;
		
	EndIf;
	
	If HasAccessTo1C And HasAccessToMobileApp Then 
		
		Role = "SRM_SR";
		
	ElsIf HasAccessTo1C And Not HasAccessToMobileApp Then 
		
		Role = "SRM";
		
	ElsIf Not HasAccessTo1C And HasAccessToMobileApp Then 
		
		Role = "SR";
		
	Else 
		
		Role = "Unknown";
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	Users.SetRolesOfUsers(Ref);
	
EndProcedure

