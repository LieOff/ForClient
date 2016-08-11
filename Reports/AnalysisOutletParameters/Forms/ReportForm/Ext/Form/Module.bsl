
#Region CommonProceduresAndFunctions

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

&AtServer
Procedure ResultDetailProcessingServer(Details, StandardProcessing)
	
	ThumbnailSize = Constants.SizeOfThumbnailPhotos.Get();
	
	Connection = CommonProcessors.GetConnectionToServer();
	
	Path = CommonProcessors.GetWebDAVPathOnServer();
	
	Fields = GetFields(Details);
	
	For Each Field In Fields Do
		
		If Field.Field = "Value" Then
			
			StandardProcessing = False;
			
			Value = Field.Value;
			
			Try
				
				SnapshotUUID = New UUID(Value);
				
				SetPicture(SnapshotUUID, Connection, Path, ThumbnailSize);
				
			Except
				
				PictureAddress = Undefined;
				PictureExtension = Undefined;
				PictureFilename = Undefined;
				
			EndTry;
			
		Else
			
			PictureAddress = Undefined;
			PictureExtension = Undefined;
			PictureFilename = Undefined;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetPicture(ID, Connection, Path, ThumbnailSize)
	
	Filter = New Structure;
	Filter.Insert("ИмяФайла", ID);
	
	Sel = InformationRegisters.bitmobile_ХранилищеФайлов.Select(Filter);
	
	If Sel.Next() Then
		
		BinaryDataOfFile = Sel.Хранилище.Get();
		
		If ValueIsFilled(BinaryDataOfFile) Then
		
			PictureAddress = PutToTempStorage(BinaryDataOfFile);
			PictureExtension = Sel.Расширение;
			PictureFilename = Sel.ИмяФайла;
			
		Else 
			
			If Not Connection = Undefined Then 
			
				Try
					
					WebDAVFile = GetTempFileName(Sel.Расширение);
					
					If ThumbnailSize > 0 Then 
						
						Connection.Get(Path + Lower(Sel.ПолноеИмяФайла) + "?size=" + Format(ThumbnailSize, "NG=0"), WebDAVFile);
						
					Else 
						
						Connection.Get(Path + Lower(Sel.ПолноеИмяФайла), WebDAVFile);
						
					EndIf;
					
					BinaryDataOfFile = New BinaryData(WebDAVFile);
					
					PictureAddress = PutToTempStorage(BinaryDataOfFile);
					PictureExtension = Sel.Расширение;
					PictureFilename = Sel.ИмяФайла;
					
				Except
					
					PictureAddress = Undefined;
					PictureExtension = Undefined;
					PictureFilename = Undefined;
					
				EndTry;
				
			Else 
				
				PictureAddress = Undefined;
				PictureExtension = Undefined;
				PictureFilename = Undefined;
				
			EndIf;
			
		EndIf;
		
	Else
		
		PictureAddress = Undefined;
		PictureExtension = Undefined;
		PictureFilename = Undefined;
		
	EndIf;
	
EndProcedure

&AtServer
Function GetFields(Details)
	
	Return GetFromTempStorage(DetailsData).Items.Get(Details).GetFields();
	
EndFunction

&AtServer
Procedure ResultOnActivateAreaAtServer(DetailsArray)
	
	For Each Detail In DetailsArray Do
		
		Fields = GetFields(Detail);
		
		If Fields[0].Field = "Value" Then
			ResultDetailProcessingServer(Detail, true);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	ResultDetailProcessingServer(Details, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SettingsComposerUserSettingsTableValueStartChoice(Item, ChoiceData, StandardProcessing)
	
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
Procedure OpenSnapshot(Command)
	
	If ValueIsFilled(PictureFilename) Then 
		
		SnapshotStructure = CommonProcessors.GetSnapshot(PictureFilename, ThisForm.UUID, "Image");
		
		If Not SnapshotStructure = Undefined Then 
			 
			GetFile(SnapshotStructure.SnapshotAddress, SnapshotStructure.SnapshotName, True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ResultOnActivateArea(Item)
	
	If NOT Item.CurrentArea.Left - Item.CurrentArea.Right = 0 OR NOT Item.CurrentArea.Top - Item.CurrentArea.Bottom = 0 Then
		Return;
	EndIf;
	
	ThisForm.PictureAddress = Undefined;
	ThisForm.PictureExtension = Undefined;
	ThisForm.PictureFilename = Undefined;
	
	If NOT Item.CurrentArea.Details = Undefined Then
				
		DetailsArray = New Array;
		
		DetailsArray.Add(Item.CurrentArea.Details);
		
		If DetailsArray.Count() > 0 Then
			ResultOnActivateAreaAtServer(DetailsArray);
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure Compose(Command)
	
	PictureAddress = Undefined;
	PictureExtension 	= Undefined;
	PictureFilename 	= Undefined;
	
	ComposeResult();
	
EndProcedure

#EndRegion



