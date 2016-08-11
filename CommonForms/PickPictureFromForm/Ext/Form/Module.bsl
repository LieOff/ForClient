
#Region CommonProceduresAndFunctions

&AtServerNoContext
Function PutPictureToValueStorage(BinaryData, FormOwnerUUID)
	
	Storage = New ValueStorage(BinaryData);
	
	Return PutToTempStorage(Storage.Get(), FormOwnerUUID);
	
EndFunction

&AtServerNoContext
Function GetFilter(Ref ,SyncDirection)
	
	ExtensionList = New ValueList;
	ExtensionList.Add(".jpg");
	ExtensionList.Add(".png");
	
	ActionList = New ValueList;
	ActionList.Add(Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл);
	ActionList.Add(Enums.bitmobile_ДействияПриСинхронизации.EmptyRef());
	
	Filter = Undefined;
		
	Filter = New Structure("Объект, НаправлениеСинхронизации, Действие, Расширение", 
		Ref, 
		GetEnumValueFromString("bitmobile_НаправленияСинхронизации", SyncDirection),
		ActionList,
		ExtensionList);
		
	Return Filter;
	
EndFunction

&AtServerNoContext
Function GetRecordManagerStructure(RecordKey, FormOwnerUUID, Section)
	
	RecordManager = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
	
	FillPropertyValues(RecordManager, RecordKey);
	
	RecordManager.Read();
	
	SnapshotData = CommonProcessors.GetSnapshot(RecordManager.ИмяФайла, FormOwnerUUID, String(RecordManager.ИмяФайла));
	
	RecordManagerStructure = GetFieldsStructure(SnapshotData.SnapshotAddress, RecordManager.ИмяФайла, RecordManager.Расширение, Section);
	
	Return RecordManagerStructure;

EndFunction

&AtServerNoContext
Function GetFieldsStructure(StorageAddress, FileName, Extension, Type)
	
	File = New File(Extension);
	
	FieldsStructure = New Structure;
	FieldsStructure.Insert("StorageAddress", StorageAddress);
	FieldsStructure.Insert("FileName", FileName);
	FieldsStructure.Insert("Extension", File.Extension);
	FieldsStructure.Insert("Type", Type);
	
	Return FieldsStructure;

EndFunction

#EndRegion

#Region UserInterface

#Region PickFromDisk

&AtClient
Procedure PickFromDisk(Command)
	
	#If WebClient Then
		
		BeginPutFile(New NotifyDescription("SelectPictureFromDiskOnWebClientProcessing", ThisForm)
					,
					,
					, True
					, ThisForm.FormOwner.UUID);
			
	#Else
		
		FileDialog = New FileDialog(FileDialogMode.Open);
		FileDialog.Filter = "JPG (*.jpg)|*.jpg|PNG (*.png)|*.png";
		FileDialog.Title = NStr("en='Select file';ru='Выберите файл';cz='Zvolit soubor'");
		FileDialog.Preview = True;
		FileDialog.FilterIndex = 0;
		
		If FileDialog.Choose() Then
			
			BinaryData = New BinaryData(FileDialog.FullFileName);
			
			File = New File(FileDialog.FullFileName);
			
			FieldsStructure = GetFieldsStructure(PutPictureToValueStorage(BinaryData, ThisForm.FormOwner.UUID), New UUID(), File.Extension, "New");
			
			Close(GetCloseParameter(FieldsStructure));
			
		EndIf;
		
	#EndIf
	
EndProcedure

&AtClient
Procedure SelectPictureFromDiskOnWebClientProcessing(Result, TempStorageAddress, FileName, AdditionalParameters) Export
	
	If Not Result Then
		
		Return;
		
	EndIf;
	
	SlashPosition = Find(FileName,"\");
	
	While SlashPosition > 0 Do 
		
		FileName = Mid(FileName, SlashPosition + 1);
		
		SlashPosition = Find(FileName,"\");
		
	КонецЦикла;
	
	FieldsStructure = GetFieldsStructure(TempStorageAddress, New UUID(), FileName, "New");
	
	Close(GetCloseParameter(FieldsStructure));
	
EndProcedure

#EndRegion

#Region PickFromPrivate

&AtClient
Procedure PickFromPrivate(Command)
	
	Filter = GetFilter(ThisForm.FormOwner.Object.Ref, "Private");
	
	Params = New Structure("Filter", Filter);
	
	OpenForm("InformationRegister.bitmobile_ХранилищеФайлов.Form.ФормаВыбора", Params, , , , , New NotifyDescription("SelectPictureFromPrivateProcessing", ThisForm));
	
EndProcedure

&AtClient
Procedure SelectPictureFromPrivateProcessing(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		QueryText = "ru = ""Изображение будет перенесено в раздел 'shared'. Продолжить?""; "
		+ "en = ""Picture will be moved to the section 'shared'. Continue?""";
		
		ShowQueryBox(New NotifyDescription("MovePictureFromPrivateToSharedQueryProcessing", ThisForm, Result), NStr(QueryText), QuestionDialogMode.YesNo, 0, DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MovePictureFromPrivateToSharedQueryProcessing(Result, AdditionalParameter) Export
	
	If Result = DialogReturnCode.Yes Then
		
		FieldsStructure = GetRecordManagerStructure(AdditionalParameter, ThisForm.FormOwner.UUID, "Private");
		
		Close(GetCloseParameter(FieldsStructure));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PickFromShared

&AtClient
Procedure PickFromShared(Command)
	
	Filter = GetFilter(ThisForm.FormOwner.Object.Ref, "Shared");
	
	Params = New Structure("Filter", Filter);
	
	OpenForm("InformationRegister.bitmobile_ХранилищеФайлов.Form.ФормаВыбора", Params, , , , , New NotifyDescription("SelectPictureFromSharedProcessing", ThisForm));
	
EndProcedure

&AtClient
Procedure SelectPictureFromSharedProcessing(Result, AdditionalParameter) Export
	
	If Not Result = Undefined Then
		
		RMS = GetRecordManagerStructure(Result, ThisForm.FormOwner.UUID, "Shared");
		
		Close(GetCloseParameter(RMS));
		
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Function GetCloseParameter(FieldsStructure)
	
	AdditionalParameters = ThisForm.OnCloseNotifyDescription.AdditionalParameters;
	
	Aliases = ?(TypeOf(AdditionalParameters) = Type("Structure"),
		?(AdditionalParameters.Property("Aliases"), 
			AdditionalParameters.Aliases, 
			New Structure),
		New Structure);
	
	ReturnFieldsArray = New Array;
	ReturnFieldsArray.Add("FileName");
	ReturnFieldsArray.Add("StorageAddress");
	ReturnFieldsArray.Add("Extension");
	ReturnFieldsArray.Add("Type");
	
	CloseParameter = New Structure;
	
	For Each Field In ReturnFieldsArray Do
		
		FieldAlias = ?(Aliases.Property(Field), Aliases[Field], Field); 
		CloseParameter.Insert(FieldAlias, FieldsStructure[Field]);
		
	EndDo;
	
	Return CloseParameter;
	
EndFunction

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

