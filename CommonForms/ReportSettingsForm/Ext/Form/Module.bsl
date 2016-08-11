
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
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

#EndRegion

#Region UserInterface

&AtClient
Procedure SettingsComposerUserSettingsValueStartChoice(Item, ChoiceData, StandardProcessing)
	
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
	
EndProcedure

#EndRegion