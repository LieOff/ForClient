
#Region CommonProceduresAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Query = New Query(
	"SELECT ALLOWED
	|	OutletsPrimaryParametersSettings.Ref,
	|	OutletsPrimaryParametersSettings.Description,
	|	OutletsPrimaryParametersSettings.EditableInMA
	|FROM
	|	Catalog.OutletsPrimaryParametersSettings AS OutletsPrimaryParametersSettings");
	
	QueryResult = Query.Execute().Unload();
	
	For Each Row In QueryResult Do
		
		Row.Description = NStr(Row.Description);
		
	EndDo;
	
	ValueToFormAttribute(QueryResult, "OutletsPrimaryParameters");
	
EndProcedure

&AtServer
Procedure ChangeParameter(ParameterRef)
	
	ParameterObject = ParameterRef.GetObject();
	ParameterObject.EditableInMA = Not ParameterObject.EditableInMA;
	ParameterObject.Write();
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure OutletPrimaryParametersEditableInMAOnChange(Item)
	
	Try
	
		CurrentData = Items.OutletPrimaryParameters.CurrentData;
		ParameterRef = CurrentData.Ref;
		ChangeParameter(ParameterRef);
	
	Except 
		
		Items.OutletPrimaryParameters.CurrentData.EditableInMA = Not Items.OutletPrimaryParameters.CurrentData.EditableInMA;
		
	EndTry;
	
EndProcedure

#EndRegion



