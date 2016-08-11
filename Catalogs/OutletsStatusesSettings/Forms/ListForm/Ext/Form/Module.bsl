
#Region CommonProceduresAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Query = New Query(
	"SELECT ALLOWED
	|	OutletsStatusesSettings.Description,
	|	OutletsStatusesSettings.ShowOutletInMA,
	|	OutletsStatusesSettings.DoVisitInMA,
	|	OutletsStatusesSettings.CreateOrderInMA,
	|	OutletsStatusesSettings.FillQuestionnaireInMA,
	|	OutletsStatusesSettings.DoEncashmentInMA,
	|	OutletsStatusesSettings.CreateReturnInMA,
	|	OutletsStatusesSettings.Ref
	|FROM
	|	Catalog.OutletsStatusesSettings AS OutletsStatusesSettings");
	
	QueryResult = Query.Execute().Unload();
	
	For Each Row In QueryResult Do
		
		Row.Description = NStr(Row.Description);
		
	EndDo;
	
	OutletStatuses.Load(QueryResult);
	
EndProcedure

&AtServer
Procedure ChangeStatus(SettingRef, AttributeName, ClearAll, SetVisible)
	
	SettingObject = SettingRef.GetObject();
	
	If AttributeName = "ShowOutletInMA" Then 
		
		If SettingObject.ShowOutletInMA Then 
			
			SettingObject.DoVisitInMA			= False;
			SettingObject.CreateOrderInMA		= False;
			SettingObject.FillQuestionnaireInMA	= False;
			SettingObject.DoEncashmentInMA		= False;
			SettingObject.CreateReturnInMA		= False;
			
			ClearAll = True;
			
		EndIf;
		
	Else 
		
		If Not SettingObject[AttributeName] And Not SettingObject.ShowOutletInMA Then 
			
			SettingObject.ShowOutletInMA = True;
			
			SetVisible = True;
			
		EndIf;
		
	EndIf;
	
	SettingObject[AttributeName] = NOT SettingObject[AttributeName];
	
	SettingObject.Write();
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure OutletStatusesAttributeOnChange(Item)
	
	Try
		
		CurrentData		= Items.OutletStatuses.CurrentData;
		SettingRef		= CurrentData.Ref;
		AttributeName	= Item.Name;
		ClearAll		= False;
		SetVisible		= False;
		
		ChangeStatus(SettingRef, AttributeName, ClearAll, SetVisible);
		
		If SetVisible Then 
			
			CurrentData.ShowOutletInMA = True;
			
		EndIf;
		
		If ClearAll Then 
			
			CurrentData.DoVisitInMA				= False;
			CurrentData.CreateOrderInMA			= False;
			CurrentData.FillQuestionnaireInMA	= False;
			CurrentData.DoEncashmentInMA		= False;
			CurrentData.CreateReturnInMA		= False;
			
		EndIf;
		
	Except
		
		Items.OutletStatuses.CurrentData[Item.Name] = Not Items.OutletStatuses.CurrentData[Item.Name];
		
	EndTry;
	
EndProcedure

#EndRegion