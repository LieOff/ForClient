
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PredefinedItems = New Map;
	PredefinedItems.Insert("Catalog.Brands", "Brand");
	PredefinedItems.Insert("Catalog.UnitsOfMeasure", "BaseUnit");
	PredefinedItems.Insert("Catalog.SKUGroup", "Owner");
	
	ItemsCollection = CommonProcessors.GetPredefinedItems(PredefinedItems);
	
	For Each Item In ItemsCollection Do
		
		Object[Item.Key] = Item.Value;

	EndDo;
	
	CheckBaseUnitAndMultiplier();
	
	If ValueIsFilled(Object.DefaultPicture) Then 	
		
		ThumbnailSize = Constants.SizeOfThumbnailPhotos.Get();
		
		Connection = CommonProcessors.GetConnectionToServer();
		
		Path = CommonProcessors.GetWebDAVPathOnServer();
		
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED TOP 1
			|	bitmobile_ХранилищеФайлов.Объект,
			|	bitmobile_ХранилищеФайлов.НаправлениеСинхронизации,
			|	bitmobile_ХранилищеФайлов.Действие,
			|	bitmobile_ХранилищеФайлов.ИмяФайла,
			|	bitmobile_ХранилищеФайлов.ПолноеИмяФайла,
			|	bitmobile_ХранилищеФайлов.Расширение,
			|	bitmobile_ХранилищеФайлов.Хранилище
			|FROM
			|	InformationRegister.bitmobile_ХранилищеФайлов AS bitmobile_ХранилищеФайлов
			|WHERE
			|	bitmobile_ХранилищеФайлов.Объект = &ObjectRef
			|	AND bitmobile_ХранилищеФайлов.Действие <> &DeleteAction
			|	AND bitmobile_ХранилищеФайлов.ИмяФайла = &FileName
			|	AND bitmobile_ХранилищеФайлов.НаправлениеСинхронизации = &SyncDirection";
			
		Query.SetParameter("DeleteAction", Enums.bitmobile_ДействияПриСинхронизации.УдалитьФайл);
		Query.SetParameter("SyncDirection", Enums.bitmobile_НаправленияСинхронизации.Shared);
		Query.SetParameter("ObjectRef", Object.Ref);
		Query.SetParameter("FileName", Object.DefaultPicture);
		
		Result = Query.Execute();
		
		Records = Result.Select();
		
		If Records.Next() Then 
			
			// Забираем бинарные данные из таблицы файлов
			BinaryDataOfFile = Records.Хранилище.Get();
			
			// Если бинарные данные есть
			If ValueIsFilled(BinaryDataOfFile) Then
				
				PictureAddress = PutToTempStorage(BinaryDataOfFile, ThisForm.UUID);
				
			// Если нет бинарных данных
			Else
				
				// Если соединение было создано успешно
				If Not Connection = Undefined Then
					
					// Пробуем забрать файл
					Try
						
						WebDAVFile = GetTempFileName(Records.Расширение);
						
						If ThumbnailSize > 0 Then 
							
							Connection.Get(Path + Lower(Records.ПолноеИмяФайла) + "?size=" + Format(ThumbnailSize, "NG=0"), WebDAVFile);
							
						Else 
							
							Connection.Get(Path + Lower(Records.ПолноеИмяФайла), WebDAVFile);
							
						EndIf;
						
						BinaryDataOfFile = New BinaryData(WebDAVFile);
						
						PictureAddress 	= PutToTempStorage(BinaryDataOfFile, ThisForm.UUID);
						
					// Не получилось забрать файл
					Except
						
					EndTry;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	DefaultPictureName = Object.DefaultPicture;
	DefaultPictureExtension = Object.DefaultPictureExtension;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not ValueIsFilled(Object.DefaultPicture) Then
		
		If ValueIsFilled(NewPictureName) Then
			
			CurrentObject.DefaultPicture = NewPictureName;
			CurrentObject.DefaultPictureExtension = NewPictureExtension;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not Cancel Then 
	
		If CurrentObject.DefaultPicture = NewPictureName And ValueIsFilled(NewPictureName) Then 
			
			If NewPictureType = "New" Then 
				
				BinaryData	= GetFromTempStorage(PictureAddress);
				
				RecordManager							= InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
				RecordManager.Объект					= CurrentObject.Ref;
				RecordManager.НаправлениеСинхронизации	= Enums.bitmobile_НаправленияСинхронизации.Shared;
				RecordManager.Действие					= Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл;
				RecordManager.ИмяФайла					= NewPictureName;
				RecordManager.Расширение				= Lower(NewPictureExtension);
				RecordManager.Хранилище					= New ValueStorage(BinaryData);
				RecordManager.ПолноеИмяФайла			= "/shared/Catalog.SKU/" + 
															CurrentObject.Ref.UUID() + 
															"/" + 
															NewPictureName + 
															Lower(NewPictureExtension);
				
				RecordManager.Write();
				
			ElsIf NewPictureType = "Private" Then 
				
				RecordSetPrivate = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordSet();
				RecordSetPrivate.Filter.ИмяФайла.Set(NewPictureName, True);
				RecordSetPrivate.Filter.НаправлениеСинхронизации.Set(Enums.bitmobile_НаправленияСинхронизации.Private, True);
				RecordSetPrivate.Filter.Объект.Set(CurrentObject.Ref, True);
				
				RecordSetPrivate.Read();
				
				If Not RecordSetPrivate.Count() = 0 Then
					
					RecordManagerShared = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
					
					FillPropertyValues(RecordManagerShared, RecordSetPrivate[0]);
					
					BinaryData = GetFromTempStorage(PictureAddress);
					
					RecordManagerShared.НаправлениеСинхронизации	= Enums.bitmobile_НаправленияСинхронизации.Shared;
					RecordManagerShared.Действие					= Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл;
					RecordManagerShared.Хранилище					= New ValueStorage(BinaryData);
					RecordManagerShared.ПолноеИмяФайла				= "/shared/Catalog.SKU/" + 
																		CurrentObject.Ref.UUID() + 
																		"/" + 
																		NewPictureName + 
																		Lower(NewPictureExtension);
					
					RecordManagerShared.Write();
					
					For Each Record In RecordSetPrivate Do 
						
						Record.Действие = Enums.bitmobile_ДействияПриСинхронизации.УдалитьФайл;
						
					EndDo;
					
					RecordSetPrivate.Write();
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckBaseUnitAndMultiplier()
	
	If ValueIsFilled(Object.BaseUnit) Then 
	
		ParameterFilter = new Structure;
		ParameterFilter.Insert("Pack", Object.BaseUnit);
		
		FoundRow = Object.Packing.FindRows(ParameterFilter);
		
		If FoundRow.Count() = 0 Then
			
			NewRow				= Object.Packing.Add();
			NewRow.Pack			= Object.BaseUnit;
			NewRow.Multiplier	= 1;
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en='Warning, new base unit has multiplier 1. Check multipliers corectness, please.';ru='Внимание, новая базовая единица имеет коэффициент 1. Проверьте, пожалуйста, коэффициенты на правильность.';cz='Warning, new base unit has multiplier 1. Check multipliers corectness, please.'");
			
			UserMessage.Message();
			
		Else
			
			If Not FoundRow[0].Multiplier = 1 Then 
				
				FoundRow[0].Multiplier = 1;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en='Warning, new base unit has multiplier 1. Check multipliers corectness, please.';ru='Внимание, новая базовая единица имеет коэффициент 1. Проверьте, пожалуйста, коэффициенты на правильность.';cz='Warning, new base unit has multiplier 1. Check multipliers corectness, please.'");
				
				UserMessage.Message();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function GetConstant()
	Return Constants.SKUFeaturesRegistration.Get();
EndFunction // ()

&AtServer
Function OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndFunction // ()

&AtServer
Function ChangePackAvailable(mPack)
	
	If ValueIsFilled(Object.Ref) Then 
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	AssortmentMatrixSKUs.AssortmentMatrix AS AM,
			|	AssortmentMatrixSKUs.AssortmentMatrix.Code AS Code
			|FROM
			|	InformationRegister.AssortmentMatrixSKUs AS AssortmentMatrixSKUs
			|WHERE
			|	AssortmentMatrixSKUs.SKU = &SKU
			|	AND AssortmentMatrixSKUs.Unit = &Pack
			|
			|GROUP BY
			|	AssortmentMatrixSKUs.AssortmentMatrix,
			|	AssortmentMatrixSKUs.AssortmentMatrix.Code";
		
		Query.SetParameter("SKU", Object.Ref);
		Query.SetParameter("Pack", mPack);
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		ReturnResult = True;
		
		While Selection.Next() Do
			
			ReturnResult = False;
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en = 'SKU and Packing used in the assortment matrix " + String(Selection.Code) + " - """ + String(Selection.AM) + """.'; ru = 'Номенклатура и упаковка используются в ассортиментной матрице " + String(Selection.Code) + " - """ + String(Selection.AM) + """.'");
			
			UserMessage.Message();
			
		EndDo;
		
		If Not ReturnResult Then 
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en='Change prohibited.';ru='Изменение запрещено.';cz='Změny jsou zakázány'");
			
			UserMessage.Message();
			
		EndIf;
		
		Return ReturnResult;
		
	Else 
		
		Return True;
		
	EndIf;
	
EndFunction

#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();	
	Items.Stock.ReadOnly 	= 	GetConstant();
	
EndProcedure

&AtClient
Procedure BaseUnitOnChange(Item)
	
	CheckBaseUnitAndMultiplier();
	
EndProcedure

&AtClient
Procedure PackingBeforeDeleteRow(Item, Cancel)
	
	If Not Items.Packing.CurrentData = Undefined Then 
		
		Cancel = Not ChangePackAvailable(Items.Packing.CurrentData.Pack);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PackingBeforeRowChange(Item, Cancel)
	
	If Item.CurrentItem = Items.PackingPack Then 
	
		If Not Items.Packing.CurrentData = Undefined Then 
			
			Cancel = Not ChangePackAvailable(Items.Packing.CurrentData.Pack);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#Region Pictures

&AtClient
Procedure DeletePicture(Command)
	
	NewPictureName 		= Undefined;
	NewPictureExtension = Undefined;
	
	Object.DefaultPicture 			= Undefined;
	Object.DefaultPictureExtension 	= Undefined;
	
	PictureAddress = "";
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure OpenPicture(Command)
	
	If ValueIsFilled(Object.DefaultPicture) Then 
		
		SnapshotStructure = CommonProcessors.GetSnapshot(Object.DefaultPicture, ThisForm.UUID, Object.Description);
		
		If Not SnapshotStructure = Undefined Then 
			
			GetFile(SnapshotStructure.SnapshotAddress, SnapshotStructure.SnapshotName, True);
			
		EndIf;
		
		
	ElsIf ValueIsFilled(NewPictureName) Then 
		
		SnapshotStructure = CommonProcessors.GetSnapshot(NewPictureName, ThisForm.UUID, Object.Description);
		
		If Not SnapshotStructure = Undefined Then 
			
			GetFile(SnapshotStructure.SnapshotAddress, SnapshotStructure.SnapshotName, True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PictureAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectPicture();
	
EndProcedure

&AtClient
Procedure SelectPicture()
	
	OpenForm("CommonForm.PickPictureFromForm", , ThisForm, , , , New NotifyDescription("SelectPictureProcessing", ThisForm));
	
EndProcedure

&AtClient
Procedure SelectPictureProcessing(Result, AdditionalParameter) Export 
	
	If Not Result = Undefined Then
		
		ThisForm.PictureAddress			= Result.StorageAddress;
		ThisForm.NewPictureName			= Result.FileName;
		ThisForm.NewPictureExtension	= Result.Extension;
		ThisForm.NewPictureType			= Result.Type;
		
		Object.DefaultPicture			= Undefined;
		Object.DefaultPictureExtension	= Undefined;
		
		Items.PictureAddress.Refresh();
		
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
