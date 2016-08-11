
&AtClient
Var TypesMap;

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.SettingsComposerUserSettingsTableValue.SetAction("StartChoice", "SettingsComposerUserSettingsTableValueStartChoice");
	Items.SettingsComposerUserSettingsTableValue.ChoiceButton = True;
	
	ReportObject			= FormDataToValue(Report, Type("ReportObject"));
	DataCompositionSchema	= ReportObject.DataCompositionSchema;
	DataSets				= DataCompositionSchema.DataSets;
	DataSet					= DataSets[0];
	
	For Each DataSetField In DataSet.Fields Do 
		
		ParameterValue = DataSetField.EditParameters.Items.Find("ChoiceParameters").Value;
		
		For Each ChoiceParameter In ParameterValue Do
			
			Ins				= FieldsTable.Add();
			Ins.Field		= DataSetField.Field;
			Ins.ParamName	= ChoiceParameter.Name;
			Ins.ParamValue	= ChoiceParameter.Value;
			Ins.Type		= DataSetField.ValueType;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ResultSelection(Item, Area, StandardProcessing)
	// Вставить содержимое обработчика.
EndProcedure

&AtServer
Procedure SetCoordinatesFromMapServer(ResultCoord, AdditionalParameter)
	      	
	TempOutlet=NameOutlet.GetObject();
	
	If Not ResultCoord = Undefined And ResultCoord.Property("Latitude") And ResultCoord.Property("Longitude") Then
		TempOutlet.Lattitude=ResultCoord.Latitude;
		TempOutlet.Longitude = ResultCoord.Longitude;
		TempOutlet.Write();		
	EndIf;
	
	
EndProcedure

&AtServer
Function GetOutlet(Det)
	DetDat = GetFromTempStorage(DetailsData);
	Strukture = New Structure();
	OutletRef=DetDat.Items[Det].ПолучитьПоля()[0].Value;
	Strukture.Insert("Outl",OutletRef);
	Strukture.Insert("OutletAddress",OutletRef.Address);
	Return Strukture;
EndFunction
	
&AtClient
Procedure SetCoordinats(Command)
	     //Items.Result.CurrentArea.GetA
	Area = Result.CurrentArea;
	If Area.Left = 1 Then
	//try
		Outlet=GetOutlet(Result.CurrentArea.Details);
		NameOutlet=Outlet.Outl;
		FormParameters = New Structure;
		FormParameters.Insert("Longitude", 0);
		FormParameters.Insert("Latitude", 0);
		FormParameters.Insert("AddresOutl",Outlet.OutletAddress);
		OpenForm("Catalog.Outlet.Form.SetCoordinatesForm",FormParameters,ThisForm , , , , New NotifyDescription("SetCoordinatesFromMap", ThisForm));
	//Except
	//	Message(NStr("en = 'You must set coordinats from name outlet'; ru = 'Чтобы установить координаты, встаньте на поле наименования этой торговой точки'"));		
	//EndTry;		
	Else
		Message(NStr("en = 'You must set coordinats from name outlet'; ru = 'Чтобы установить координаты, встаньте на поле наименования этой торговой точки'"));		
	EndIf;

EndProcedure

&AtClient
Procedure SetCoordinatesFromMap(ResultCoord, AdditionalParameter) Export
	
	SetCoordinatesFromMapServer(ResultCoord, AdditionalParameter);
	
EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)

EndProcedure


&AtClient
Procedure SettingsComposerUserSettingsTableValueStartChoice(Item, ChoiceData, StandardProcessing)	
	
	OutletParameterStructure = GetOutletParameterStructure();
	
	CurrentSetting = GetOutletParameterSettings();
	
	If Not CurrentSetting = Undefined And Not OutletParameterStructure = Undefined Then 
		
		StandardProcessing = False;
		
		If CurrentSetting.ComparisonType = DataCompositionComparisonType.InList 
			Or CurrentSetting.ComparisonType = DataCompositionComparisonType.InListByHierarchy
			Or CurrentSetting.ComparisonType = DataCompositionComparisonType.NotInList
			Or CurrentSetting.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then 
			
			OpenForm("Document.Questionnaire.Form.SelectorsListForm", New Structure("StringNumber, Selector, DataType, CurrentValue, OutletParameter, Source", 0, "Catalog_OutletParameter", OutletParameterStructure.DataType, CurrentSetting.RightValue, OutletParameterStructure.OutletParameter, "ValueListOk" + String(ThisForm.UUID)));
			
		Else 
			
			OpenForm("Document.Questionnaire.Form.Input", New Structure("StringNumber, DataType, OutletParameter, Source, CurrentValue", 0, OutletParameterStructure.DataType, OutletParameterStructure.OutletParameter, "QuestionnaireForm" + String(ThisForm.UUID), CurrentSetting.RightValue));
			
		EndIf;
		
	Else
		
		CurrentId = Item.Parent.Parent.CurrentRow;
		CurrentUserSetting = ThisForm.Report.SettingsComposer.UserSettings.GetObjectByID(CurrentId);
		CurrentUserSettingId = CurrentUserSetting.UserSettingID;
		CurrentSetting = Undefined;
		
		For Each Element In ThisForm.Report.SettingsComposer.Settings.Filter.Items Do
			
			If Element.UserSettingID = CurrentUserSettingId Then
				
				CurrentSetting = Element;
				
			EndIf;
			
		EndDo;
		
		If NOT CurrentSetting = Undefined Then
			
			If CurrentUserSetting.ComparisonType = DataCompositionComparisonType.InList OR 
				CurrentUserSetting.ComparisonType = DataCompositionComparisonType.InListByHierarchy OR
				CurrentUserSetting.ComparisonType = DataCompositionComparisonType.NotInList OR
				CurrentUserSetting.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
				
				Try
					
					ValueType = Undefined;
					
					FieldParameters = FieldsTable.FindRows(New Structure("Field", String(CurrentSetting.LeftValue)));
		
					Filter = New Map;
					
					For Each FieldParameter In FieldParameters Do
						
						If ValueType = Undefined And ValueIsFilled(FieldParameter.Type) Then 
							
							ValueType = FieldParameter.Type;
							
						EndIf;
						
						Filter.Insert(FieldParameter.ParamName, FieldParameter.ParamValue);
						
					EndDo;
					
					If ValueType = Undefined Then 
						
						ValueType = CurrentUserSetting.RightValue.ValueType;
						
					EndIf;
					
					FormParameters = New Structure;
					
					If Not ValueIsFilled(ValueType) = Undefined Then
						
						StandardProcessing = False;
						
						FormParameters.Insert("FieldValueType", ValueType);
						
						Form = GetForm("CommonForm.ValueListForm", FormParameters, Item, , WindowOpenVariant.SingleWindow);
						
						For Each Row In Filter Do
							
							NewRow				= Form.Filter.Add();
							NewRow.FilterName	= Row.Key;
							NewRow.Value		= Row.Value;
							
						EndDo;
						
						Form.ValueList.LoadValues(CurrentUserSetting.RightValue.UnloadValues());
						
						Form.Open();
						
					EndIf;
					
				Except
				EndTry;
				
			EndIf;
				
		EndIf;
		
	EndIf;
	If Not CurrentSetting = Undefined Then 
		If (CurrentSetting.LeftValue = new DataCompositionField("SR") OR CurrentSetting.LeftValue = new DataCompositionField("FactExecutor")) And (CurrentUserSetting.ComparisonType = DataCompositionComparisonType.Equal OR CurrentUserSetting.ComparisonType = DataCompositionComparisonType.NotEqual) Then
			StandardProcessing = False;
			FormParameters = New Structure;
			FormParameters.Insert("Role", "SR");
			Form = GetForm("Catalog.User.ChoiceForm", FormParameters, Item);
			Form.Open();
		EndIf;
	EndIf;

	
EndProcedure

&AtClient
Function GetOutletParameterSettings()
	
	CurrentSetting = Report.SettingsComposer.UserSettings.Items.Find(Items.SettingsComposerUserSettingsTable.CurrentRow);
	
	ValueField = New DataCompositionField("Value");
	
	ReturnSettings = Undefined;
	
	For Each ItemElement In Report.SettingsComposer.Settings.Filter.Items Do 
		
		If ItemElement.UserSettingID = CurrentSetting.UserSettingID Then 
			
			If ItemElement.LeftValue = ValueField Then 
				
				ReturnSettings = CurrentSetting;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return ReturnSettings;
	
EndFunction


&AtServerNoContext
Function GetReturnStructure(Value, TypesMap)
	
	Return New Structure("OutletParameter, DataType", Value, TypesMap.Get(String(Value.DataType)));
	
EndFunction



&AtClient
Function GetOutletParameterStructure()
	
	ParameterField = New DataCompositionParameter("Parameter");
	
	ReturnStructure = Undefined;
	
	For Each ItemElement In Report.SettingsComposer.UserSettings.Items Do
		
		If TypeOf(ItemElement) = Type("DataCompositionSettingsParameterValue") Then 
		
			If ItemElement.Parameter = ParameterField Then 
				
				If ValueIsFilled(ItemElement.Value) Then 
					
					ReturnStructure = GetReturnStructure(ItemElement.Value, TypesMap);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return ReturnStructure;
	
EndFunction


&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "QuestionnaireForm" + String(ThisForm.UUID) Then
		
		CurrentSetting = GetOutletParameterSettings();
		
		CurrentSetting.RightValue = Parameter.Str;
		
		Items.SettingsComposerUserSettingsTable.EndEditRow(False);
		
	EndIf;
	
	If EventName = "ValueListOk" + String(ThisForm.UUID) Then
		
		CurrentSetting = GetOutletParameterSettings();
		
		CurrentSetting.RightValue = Parameter.List;
		
		Items.SettingsComposerUserSettingsTable.EndEditRow(False);
		
	EndIf;
	
EndProcedure


&AtClient
Procedure SettingsComposerUserSettingsTableChoiceProcessing(Item, SelectedValue, StandardProcessing)
	//Message("asdfasd");
	// Вставить содержимое обработчика.
EndProcedure


TypesMap = new Map();
TypesMap.Insert("String", "String");
TypesMap.Insert("Строка", "String");
TypesMap.Insert("Integer", "Integer");
TypesMap.Insert("Целое число", "Integer");
TypesMap.Insert("Decimal", "Decimal");
TypesMap.Insert("Десятичная дробь", "Decimal");
TypesMap.Insert("Boolean", "Boolean");
TypesMap.Insert("Логический тип", "Boolean");
TypesMap.Insert("Date time", "Date time");
TypesMap.Insert("Дата и время", "Date time");
TypesMap.Insert("Value list", "Value list");
TypesMap.Insert("Список значений", "Value list");
