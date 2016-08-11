
&AtClient
Var OldPartner;

&AtClient
Var OldTerritories;

#Region CommonProceduresAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PredefinedItems = New Map;
	PredefinedItems.Insert("Catalog.OutletType", "Type");
	PredefinedItems.Insert("Catalog.OutletClass", "Class");
	//PredefinedItems.Insert("Catalog.Distributor", "Distributor");
	PredefinedItems.Insert("Document.PriceList", "Prices");
	
	ItemsCollection = CommonProcessors.GetPredefinedItems(PredefinedItems);
	
	For Each Item In ItemsCollection Do
		
		If TypeOf(Object[Item.Key]) = Type("FormDataCollection") Then
			
			If Object[Item.Key].Count() = 0 Then
				
				NewRow = Object[Item.Key].Add();
				
				For Each Attribute In Metadata.Catalogs.Outlet.TabularSections[Item.Key].Attributes Do
					
					If TypeOf(NewRow[Attribute.Name]) = TypeOf(Item.Value) Then
						
						NewRow[Attribute.Name] = Item.Value;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		Else 
			
			Object[Item.Key] = Item.Value;
			
		EndIf;
		
	EndDo;
	
	// Проверить возможность редактирования параметров торговой точки
	If Not Users.HaveAdditionalRight(GetParametersRight()) Then 
		
		HaveEditParametersRight = False;
		
		Items.Snapshots.ReadOnly = True;
		Items.ClearValue.Enabled = False;
		Items.Parameters.ReadOnly = True;
		
	Else 
		
		HaveEditParametersRight = True;
		
	EndIf;
	
	ThisForm.Items.ContactPersonsNotActual.ReadOnly = Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditOutletContacts);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		Object.OutletStatus = Enums.OutletStatus.Potential;
		
	EndIf;
	
	Items.GroupParameters.Visible = HasRightToReadOutletParameters();
	
	// Запомнить ранее введенные проверяемые данные
	TempEmail		= Object.Email;
	TempPhoneNumber	= Object.PhoneNumber;
	
	FillContractors();
	
	HandleContactsAdditionalAccessRights();
	
	ChangeDistributorChoiceParameters();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ThumbnailSize = Constants.SizeOfThumbnailPhotos.Get();
	
	Connection = CommonProcessors.GetConnectionToServer();
	
	Path = CommonProcessors.GetWebDAVPathOnServer();
	
	FileTable = GetFileTable();
	
	FillTerritories();
	
	FillSnapshots(Connection, Path, FileTable);
	
	FillParameters(Connection, Path, FileTable);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If NOT ValueIsFilled(ThisForm.Object.Distributor) Then
		
		CurrentObject.ContractorsList.Load(ThisForm.ContractorsList.Unload());
		
	Else
		
		CurrentObject.ContractorsList.Clear();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not Cancel Then
		
		If HasRightToReadOutletParameters() Then
		
			For Each Row In Object.Parameters Do
				
				If IsPicture(Row.Parameter) Then
					
					If Row.Type = "New" Then
						
						BinaryData = GetFromTempStorage(Row.StorageAddress);
						
						RecordManager							= InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
						RecordManager.Объект					= CurrentObject.Ref;
						RecordManager.НаправлениеСинхронизации	= Enums.bitmobile_НаправленияСинхронизации.Shared;
						RecordManager.Действие					= Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл;
						RecordManager.ИмяФайла					= New UUID(Row.Value);
						RecordManager.Расширение				= Row.Extension;
						RecordManager.Хранилище					= New ValueStorage(BinaryData);
						RecordManager.ПолноеИмяФайла			= "/shared/Catalog.Outlet/" + 
																	CurrentObject.Ref.UUID() + 
																	"/" + 
																	Row.Value + 
																	Lower(Row.Extension);
						
						RecordManager.Write();
						
					ElsIf Row.Type = "Private" Then
						
						RecordSetPrivate = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordSet();
						RecordSetPrivate.Filter.ИмяФайла.Set(New UUID(Row.Value), True);
						RecordSetPrivate.Filter.НаправлениеСинхронизации.Set(Enums.bitmobile_НаправленияСинхронизации.Private, True);
						RecordSetPrivate.Filter.Объект.Set(CurrentObject.Ref, True);
						
						RecordSetPrivate.Read();
						
						If Not RecordSetPrivate.Count() = 0 Then
							
							RecordManagerShared = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
							
							FillPropertyValues(RecordManagerShared, RecordSetPrivate[0]);
							
							BinaryData = GetFromTempStorage(Row.StorageAddress);
							
							RecordManagerShared.НаправлениеСинхронизации	= Enums.bitmobile_НаправленияСинхронизации.Shared;
							RecordManagerShared.Действие					= Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл;
							RecordManagerShared.Хранилище					= New ValueStorage(BinaryData);
							RecordManagerShared.ПолноеИмяФайла				= "/shared/Catalog.Outlet/" + 
																				CurrentObject.Ref.UUID() + 
																				"/" + 
																				Row.Value + 
																				Lower(Row.Extension);
							
							RecordManagerShared.Write();
							
							For Each Record In RecordSetPrivate Do 
								
								Record.Действие = Enums.bitmobile_ДействияПриСинхронизации.УдалитьФайл;
								
							EndDo;
							
							RecordSetPrivate.Write();
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
			EndDo;
		
		EndIf;
		
		For Each Row In Object.Snapshots Do
			
			If Row.Type = "New" Then
				
				BinaryData = GetFromTempStorage(Row.StorageAddress);
				
				RecordManager							= InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
				RecordManager.Объект					= CurrentObject.Ref;
				RecordManager.НаправлениеСинхронизации	= Enums.bitmobile_НаправленияСинхронизации.Shared;
				RecordManager.Действие					= Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл;
				RecordManager.ИмяФайла					= New UUID(Row.FileName);
				RecordManager.Расширение				= Row.Extension;
				RecordManager.Хранилище					= New ValueStorage(BinaryData);
				RecordManager.ПолноеИмяФайла			= "/shared/Catalog.Outlet/" + 
															CurrentObject.Ref.UUID() + 
															"/" + 
															String(Row.FileName) + 
															Lower(Row.Extension);
				
				RecordManager.Write();
				
			ElsIf Row.Type = "Private" Then
				
				RecordSetPrivate = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordSet();
				RecordSetPrivate.Filter.ИмяФайла.Set(New UUID(Row.FileName), True);
				RecordSetPrivate.Filter.НаправлениеСинхронизации.Set(Enums.bitmobile_НаправленияСинхронизации.Private, True);
				RecordSetPrivate.Filter.Объект.Set(CurrentObject.Ref, True);
				
				RecordSetPrivate.Read();
				
				If Not RecordSetPrivate.Count() = 0 Then
					
					RecordManagerShared = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
					
					FillPropertyValues(RecordManagerShared, RecordSetPrivate[0]);
					
					BinaryData = GetFromTempStorage(Row.StorageAddress);
					
					RecordManagerShared.НаправлениеСинхронизации	= Enums.bitmobile_НаправленияСинхронизации.Shared;
					RecordManagerShared.Действие					= Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл;
					RecordManagerShared.Хранилище					= New ValueStorage(BinaryData);
					RecordManagerShared.ПолноеИмяФайла				= "/shared/Catalog.Outlet/" + 
																		CurrentObject.Ref.UUID() + 
																		"/" + 
																		Row.FileName + 
																		Lower(Row.Extension);
					
					RecordManagerShared.Write();
					
					For Each Record In RecordSetPrivate Do 
						
						Record.Действие = Enums.bitmobile_ДействияПриСинхронизации.УдалитьФайл;
						
					EndDo;
					
					RecordSetPrivate.Write();
					
				EndIf;
				
			EndIf;
		
		EndDo;
		
		SetPrivilegedMode(True);
		
		WriteTerritory(CurrentObject);
		
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Connection = CommonProcessors.GetConnectionToServer();
	
	Path = CommonProcessors.GetWebDAVPathOnServer();
	
	FileTable = GetFileTable();
	
	FillParametersAdditionalInformation(Connection, Path, FileTable);
	
	FillSnapshots(Connection, Path, FileTable);
	
	ChangeDistributorChoiceParameters();
	
EndProcedure

&AtServer
Procedure ChangeDistributorChoiceParameters()
	
	Array = New Array;
	TerritoriesParameter = New ChoiceParameter("Territories", GetTerritoriesArray());
	Array.Add(TerritoriesParameter);
	NewParameters = New FixedArray(Array);
	ThisForm.Items.Distributor.ChoiceParameters = NewParameters;
	
EndProcedure

&AtServer
Function GetFileTable()
	
	// Выбираем все записи относящиеся к данной торговой точке из регистра 
	// сведений с файлами.
	Query = New Query(
	"SELECT
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
	|	bitmobile_ХранилищеФайлов.Объект = &Outlet");
	
	Query.SetParameter("Outlet", Object.Ref);
	
	// Ложим результат запроса в таблицу файлов
	FileTable = Query.Execute().Unload();
	
	Return FileTable;
	
EndFunction

&AtServer
Procedure FillPictureInformation(Connection, Path, FileTable, Row, FileNameColumnName)
	
	// Если значение параметра заполнено
	If ValueIsFilled(Row[FileNameColumnName]) Then
		
		// Проверяем что значение текущего параметра - УИД
		Try
			
			ShapshotUUID = New UUID(Row[FileNameColumnName]);
			
			// Ищем в таблице файлов уид из текущей строки
			FileTableRow = FileTable.Find(ShapshotUUID, "ИмяФайла");
			
			// Если найден уид в таблице файлов
			If Not FileTableRow = Undefined Then
				
				Row.Type = "Snapshot";
				
				// Забираем бинарные данные из таблицы файлов
				BinaryDataOfFile = FileTableRow.Хранилище.Get();
				
				// Если бинарные данные есть
				If ValueIsFilled(BinaryDataOfFile) Then
					
					Row.StorageAddress = PutToTempStorage(BinaryDataOfFile, ThisForm.UUID);
					Row.Extension = FileTableRow.Расширение;
					
				// Если нет бинарных данных
				Else
					
					// Если соединение было создано успешно
					If Not Connection = Undefined Then
						
						// Пробуем забрать файл
						Try
							
							WebDAVFile = GetTempFileName(FileTableRow.Расширение);
							
							If ThumbnailSize > 0 Then 
								
								Connection.Get(Path + Lower(FileTableRow.ПолноеИмяФайла) + "?size=" + Format(ThumbnailSize, "NG=0"), WebDAVFile);
								
							Else 
								
								Connection.Get(Path + Lower(FileTableRow.ПолноеИмяФайла), WebDAVFile);
								
							EndIf;
							
							BinaryDataOfFile = New BinaryData(WebDAVFile);
							
							Row.StorageAddress 	= PutToTempStorage(BinaryDataOfFile, ThisForm.UUID);
							Row.Extension 		= FileTableRow.Расширение;
							
						// Не получилось забрать файл
						Except
							
							Row.Type = "WebDAVFailed";
							
						EndTry;
						
					EndIf;
					
				EndIf;
				
			// Если уид не найден
			Else
				
				Row.Type = "NotFound";
				
			EndIf;
			
		// Если значение - не УИД, тогда мы не можем получить фотоснимок
		Except
			
			Row.Type = "NotUID";
			
		EndTry;
		
		
	// Если значение параметра не заполнено
	Else
		
		Row.Type = "NoSnapshot";
		
	EndIf;
	
EndProcedure

#Region Status

&AtServerNoContext
Function IsClosed(Status)
	
	If Status = Enums.OutletStatus.Closed Then
		
		Return True;
		
	Else 
		
		Return False;
		
	EndIf;
	
EndFunction

&AtServer
Function ClosingCauseFilledWhenOutletClosed()
	
	If Object.OutletStatus=Enums.OutletStatus.Closed And Object.ClosingCause=Enums.ClosingCause.EmptyRef() Then
		
		Message(NStr("en='""Closing cause"" field couldn''t be empty';ru='Поле ""Причина закрытия"" не может быть пустым';cz='Pole ""Důvod zavření"" nesmí být prazdné'"));
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

&AtServer 
Function NotFilledCorrectly()
	
	Return NOT HasTerritories() OR ClosingCauseFilledWhenOutletClosed();
	
EndFunction

#EndRegion

#Region Parameters

&AtServer
Procedure FillParameters(Val Connection = Undefined, Val Path = Undefined, Val FileTable = Undefined)
	
	If Connection = Undefined Then 
		
		Connection = CommonProcessors.GetConnectionToServer();
		
	EndIf;
	
	If FileTable = Undefined Then 
		
		FileTable = GetFileTable();
		
	EndIf;
	
	If Path = Undefined Then 
		
		Path = CommonProcessors.GetWebDAVPathOnServer();
		
	EndIf;
	
	NewParametersArray = GetNewParameters();
	
	AddNewParameters(NewParametersArray);
	
	FillParametersAdditionalInformation(Connection, Path, FileTable);
	
EndProcedure

&AtServer
Procedure AddNewParameters(ParametersArray)
	
	// Строка добавленных параметров. Нужна для вывода сообщения.
	AddedParameters = New Array;
	
	// Новые параметры добавляются в конец таблицы параметров.
	For Each Parameter In ParametersArray Do
		
		NewRow = Object.Parameters.Add();
		NewRow.Parameter = Parameter;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetParametersRight()
	
	Return Catalogs.AdditionalAccessRights.EditParametersInOutlet;	
	
EndFunction

&AtServer
Function GetNewParameters()
	
	// Первый запрос пакета выбирает те параметры которые уже добавлены в текущую
	// торговую точку.
	//
	// Второй запрос пакета выбирает все существующие параметры в справочнике.
	//
	// Третий запрос пакета выбирает те параметры в справочнике которые не 
	// добавлены в торговую точку.
	//
	// Четвертый запрос пакета выбирает результирующую выборку параметров к 
	// добавлению в данную торговую точку.
	Query = New Query(
	"SELECT
	|	FormParameters.Parameter AS Parameter
	|INTO FormParameters
	|FROM
	|	&FormParameters AS FormParameters
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OutletParameter.Ref AS CatalogParameter
	|INTO CatalogParameters
	|FROM
	|	Catalog.OutletParameter AS OutletParameter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatalogParameters.CatalogParameter
	|INTO Difference
	|FROM
	|	CatalogParameters AS CatalogParameters
	|		LEFT JOIN FormParameters AS FormParameters
	|		ON CatalogParameters.CatalogParameter = FormParameters.Parameter
	|WHERE
	|	FormParameters.Parameter IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Difference.CatalogParameter AS Parameter
	|FROM
	|	Difference AS Difference");
	
	Query.SetParameter("FormParameters", Object.Parameters.Unload());
	
	QueryResult = Query.Execute().Unload();
	
	Return QueryResult.UnloadColumn("Parameter");
	
EndFunction

&AtServer
Procedure FillSnapshots(Connection, Path, FileTable)
	
	For Each Row In Object.Snapshots Do
		
		FillPictureInformation(Connection, Path, FileTable, Row, "FileName");
		
	EndDo;
	
EndProcedure 

#EndRegion

#Region ParametersPictures

&AtServer
Procedure FillParametersAdditionalInformation(Connection, Path, FileTable)
	
	If HasRightToReadOutletParameters() Then
	
		// Для каждой строки из параметров данной торговой точки
		For Each Row In Object.Parameters Do
			
			// Если тип данных параметра текущей строки - фотоснимок
			If IsPicture(Row.Parameter) Then
				
				If Not ValueIsFilled(Row.StorageAddress) And Not Row.IsPicture Then 
				
					FillPictureInformation(Connection, Path, FileTable, Row, "Value");
					Row.IsPicture = True;
					
				EndIf;
				
			// Если тип данных параметра данной строки - не фотоснимок
			Else
				
				Row.Presentation = Row.Value;
				Row.IsPicture = False;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function IsPicture(Parameter)
	
	If HasRightToReadOutletParameters() Then
		
		If Parameter.DataType = Enums.DataType.Snapshot Then 
			
			Return True;
			
		Else 
			
			Return False;
			
		EndIf;
		
	EndIf;
	
EndFunction

&AtServerNoContext
Function HasRightToReadOutletParameters()
	
	Selection = SessionParameters.CurrentUser.RoleOfUser.AccessRightsToSystemObjects.Find(Catalogs.SystemObjects.Catalog_OutletsParameters);
	
	IsAdmin = NOT ValueIsFilled(SessionParameters.CurrentUser.RoleOfUser);
	HasRightToReadParameters = ValueIsFilled(Selection);
	
	Return IsAdmin OR HasRightToReadParameters;
	
EndFunction

#EndRegion

#Region Territories

&AtServer
Procedure FillTerritories()
	
	Territories = GetTerritories();
	
	SelectionDetailRecords = Territories.Choose();
	
	While SelectionDetailRecords.Next() Do
		
		NewRow = TerritoriesList.Add();
		NewRow.Value = SelectionDetailRecords.Ref;
		
	EndDo;
	
EndProcedure

&AtServer
Function GetTerritories()
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	TerritoryOutlets.Ref.Ref
	|FROM
	|	Catalog.Territory.Outlets AS TerritoryOutlets
	|WHERE
	|	TerritoryOutlets.Outlet.Ref = &Ref";
	
	Query.SetParameter("Ref", Object.Ref);
	
	Result = Query.Execute();
	
	Return Result;
	
EndFunction

&AtServer
Function GetTerritoriesArray()
	
	//Query = New Query(
	//"SELECT ALLOWED
	//|	TerritoryOutlets.Ref AS Territory
	//|FROM
	//|	Catalog.Territory.Outlets AS TerritoryOutlets
	//|		FULL JOIN Catalog.Contractors.Territories AS ContractorsTerritories
	//|		ON TerritoryOutlets.Ref = ContractorsTerritories.Territory
	//|WHERE
	//|	TerritoryOutlets.Outlet = &Outlet");
	//
	//Query.SetParameter("Outlet", ThisForm.Object.Ref);
	//TerritoriesVT = Query.Execute().Unload();
	
	TerritoriesVT = ThisForm.TerritoriesList.Unload();
	TerritoriesArray = New Array;
	
	For Each Row In TerritoriesVT Do
		
		TerritoriesArray.Add(Row.Value);
		
	EndDo;
	
	Return TerritoriesArray;
	
EndFunction

&AtServer
Procedure WriteTerritory(CurrObject)
	
	WrittenTerritories = GetTerritories().Unload();
	
	For Each TerritoryRow In TerritoriesList Do
		
		SelectedItem = WrittenTerritories.Find(TerritoryRow.Value.Ref, "Ref");
		
		If SelectedItem = Undefined Then
			
			TerritoryValue = TerritoryRow.Value;
			
			Territory = TerritoryValue.GetObject();
			
			Outlets = Territory.Outlets.Unload();
			
			NewRow 			= Outlets.Add();
			NewRow.Outlet 	= CurrObject.Ref;
			
			Territory.Outlets.Load(Outlets);
			Territory.Write();
			
		EndIf;
		
	EndDo;
	
	DeleteTerritories(CurrObject);
	
EndProcedure

&AtServer
Procedure DeleteTerritories(CurrObject)
	
	Territories 			= GetTerritories();
	RecordedTerritories 	= Territories.Unload();
	TerritoriesValueTable 	= TerritoriesList.Unload();
	
	For Each Territory In RecordedTerritories Do
		
		If TerritoriesValueTable.Find(Territory.Ref, "Value") = Undefined Then
			
			TerritoryObject = Territory.Ref.GetObject();
			
			Outlets = TerritoryObject.Outlets.Unload();
			Outlets.Delete(Outlets.Find(CurrObject.Ref, "Outlet").LineNumber - 1);
			
			TerritoryObject.Outlets.Load(Outlets);
			TerritoryObject.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function HasTerritories() 
	
	If Not IsInRole("Admin") Then
	
		If ThisForm.TerritoriesList.Count() > 0 Then
			
			Return True;
			
		Else
			
			Message(Nstr("en = 'You cannot write outlet without territories'; ru = 'Нельзя записывать торговую точку без территорий'"));
			Return False;
			
		EndIf;
		
	Else
		
		Return True;
		
	EndIf;
	
EndFunction

&AtServer
Function PartnerNotInTerritories()
	
	Query = New Query(
	"SELECT ALLOWED
	|	DistributorTerritories.Territory
	|FROM
	|	Catalog.Distributor.Territories AS DistributorTerritories
	|WHERE
	|	DistributorTerritories.Territory IN(&Territories)");
	Query.SetParameter("Territories", GetTerritoriesArray());
	Result = Query.Execute().Unload();
	
	Return Result.Count() = 0;
	
EndFunction

&AtServer
Function GetNewContractorsList()
	
	Query = New Query(
	"SELECT ALLOWED
	|	Contractors.Contractor,
	|	Contractors.Default
	|INTO FormContractors
	|FROM
	|	&Contractors AS Contractors
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	ContractorsTerritories.Ref AS Contractor,
	|	FormContractors.Default
	|FROM
	|	Catalog.Contractors.Territories AS ContractorsTerritories,
	|	FormContractors AS FormContractors
	|WHERE
	|	ContractorsTerritories.Ref IN (FormContractors.Contractor)
	|	AND ContractorsTerritories.Territory IN(&Territories)");
	Query.SetParameter("Contractors", ThisForm.ContractorsList.Unload());
	Query.SetParameter("Territories", GetTerritoriesArray());
	Result = Query.Execute().Unload();
	
	Contractors= New Array;
	Default = 0;
	Counter = 0;
	
	For Each Row In Result Do
		
		Contractors.Add(Row.Contractor);
		
		If Row.Default Then
			
			Default = Counter;
			
		EndIf;
		
		Counter = Counter + 1;
		
	EndDo;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Default", True);
	DefaultRows = Result.FindRows(FilterParameters);
	
	Structure = New Structure;
	Structure.Insert("Contractors", Contractors);
	Structure.Insert("HasDefault", DefaultRows.Count() > 0);
	Structure.Insert("Default", Default);
	
	Return Structure;
	
EndFunction

#EndRegion

#Region Contractors

&AtServer
Procedure FillContractors()
	
	If ValueIsFilled(ThisForm.Object.Distributor) Then
		
		Query = New Query(
		"SELECT ALLOWED
		|	PartnersContractorsSliceLast.Contractor,
		|	PartnersContractorsSliceLast.Default
		|FROM
		|	Catalog.Distributor.Contractors AS PartnersContractorsSliceLast
		|WHERE
		|	PartnersContractorsSliceLast.Ref = &Partner");
		
		Query.SetParameter("Partner", ThisForm.Object.Distributor);
		
		Result = Query.Execute().Unload();
		
	Else
		
		Query = New Query(
		"SELECT ALLOWED
		|	OutletsContractors.Contractor,
		|	OutletsContractors.Default
		|FROM
		|	Catalog.Outlet.ContractorsList AS OutletsContractors
		|WHERE
		|	OutletsContractors.Ref = &Outlet");
		
		Query.SetParameter("Outlet", ThisForm.Object.Ref);
		
		Result = Query.Execute().Unload();
		
	EndIf;
	
	ThisForm.ContractorsList.Load(Result);
	
EndProcedure

&AtServer
Function GetFilters()
	
	FiltersArray = New Array;
	FiltersArray.Add(GetFilter("Ref.Territories.Territory", GetTerritoriesArray()));
	FiltersArray.Add(GetFilter("Ref", GetAvailableContractors()));
	
	Return FiltersArray;
	
EndFunction

&AtServer
Function GetFilter(FieldName, List)
	
	Filter = New DataCompositionFilter;
	FilterItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField(FieldName);
	FilterItem.Use 				= True;
	FilterItem.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
	FilterItem.ComparisonType	= DataCompositionComparisonType.InList;
	FilterItem.RightValue		= List;
	
	Return FilterItem;
	
EndFunction

&AtServer
Function GetAvailableContractors()
	
	Query = New Query(
	"SELECT ALLOWED
	|	FormContractors.Contractor
	|INTO FormContractors
	|FROM
	|	&FormContractors AS FormContractors
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PartnersContractors.Contractor
	|INTO PartnersContractors
	|FROM
	|	Catalog.Distributor.Contractors AS PartnersContractors
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OutletsContractors.Contractor
	|INTO OutletsContractors
	|FROM
	|	Catalog.Outlet.ContractorsList AS OutletsContractors
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Contractors.Ref AS Contractor
	|FROM
	|	Catalog.Contractors AS Contractors
	|		LEFT JOIN OutletsContractors AS OutletsContractors
	|		ON Contractors.Ref = OutletsContractors.Contractor
	|		LEFT JOIN PartnersContractors AS PartnersContractors
	|		ON Contractors.Ref = PartnersContractors.Contractor
	|		LEFT JOIN FormContractors AS FormContractors
	|		ON Contractors.Ref = FormContractors.Contractor
	|WHERE
	|	OutletsContractors.Contractor IS NULL 
	|	AND PartnersContractors.Contractor IS NULL 
	|	AND FormContractors.Contractor IS NULL ");
	
	Query.SetParameter("FormContractors", ThisForm.ContractorsList.Unload(, "Contractor"));
	Result = Query.Execute().Unload();
	
	AvailableContractors = New Array;
	
	For Each Row In Result Do
		
		AvailableContractors.Add(Row.Contractor);
		
	EndDo;
	
	Return AvailableContractors;
	
EndFunction

#EndRegion

#Region ContactList

&AtServer
Procedure HandleContactsAdditionalAccessRights()
	
	CurrentUser = SessionParameters.CurrentUser;
	EditContactsAccessRight = Catalogs.AdditionalAccessRights.EditOutletContacts;
	IsAdmin = Not ValueIsFilled(CurrentUser.RoleOfUser);
	HasRightToEditContacts = Not CurrentUser.RoleOfUser.AdditionalAccessRights.Find(EditContactsAccessRight) = Undefined;
	EnableContactEdit = IsAdmin OR HasRightToEditContacts;
	Items.ContactListAddContact.Enabled = EnableContactEdit;
	Items.ContactListDeleteContact.Enabled = EnableContactEdit;
	
EndProcedure

#EndRegion

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OutletStatusOnChange(Undefined);
	
	OnOpenAtServer();
	
	IsPartnerFilled = ValueIsFilled(ThisForm.Object.Distributor);
	Items.AddContractor.Enabled = Not IsPartnerFilled;
	Items.DeleteContractor.Enabled = Not IsPartnerFilled;
	
	OldContractor = ThisForm.Object.Distributor;
	
	SetContractorsButtonsAvailability();
	
	NotifyChanged(Type("CatalogRef.ContactPersons"));
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	Cancel = NotFilledCorrectly();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FillParameters();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "OutletParameterCreated" Then
		
		FillParameters();
		
	Elsif EventName = "Update" Then
		
		ThisForm.Items.ContactList.Refresh();
		
	EndIf;
	
EndProcedure

#Region Status

&AtClient
Procedure OutletStatusOnChange(Item)
	
	If IsClosed(Object.OutletStatus) Then
		
		ThisForm.Items.ClosingCause.Visible = True;
		
	Else 
		
		ThisForm.Items.ClosingCause.Visible = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region LattitudeLongtitude

&AtClient
Procedure LattitudeOnChange(Item)
	
	Object.Lattitude = GetRealLatLng(Object.Lattitude, 90);
	
EndProcedure

&AtClient
Procedure LongitudeOnChange(Item)
	
	Object.Longitude = GetRealLatLng(Object.Longitude, 180);
	
EndProcedure

&AtClientAtServerNoContext
Function GetRealLatLng(LatLng, Limit)
	
	Return ?(LatLng > Limit, Limit, ?(LatLng < -Limit, -Limit, LatLng));
	
EndFunction

#EndRegion

#Region Parameters

&AtClient
Procedure UpdateParameters(Command)
	
	FillParameters();
	
EndProcedure

&AtClient
Procedure ParametersOnActivateRow(Item)
	
	IsPicture = Not Item.CurrentData = Undefined And Item.CurrentData.IsPicture;
	
	PictureAddress = ?(IsPicture, Item.CurrentData.StorageAddress, Undefined);
	PictureExtension = ?(IsPicture, Item.CurrentData.Extension, Undefined);
	
	Items.PictureAddress.Hyperlink = IsPicture;
	Items.PictureAddress.NonselectedPictureText = ?(IsPicture, 
		NStr("en='Add snapshot';ru='Добавить фотоснимок';cz='Novй foto'"),
		NStr("en='No snapshot';ru='Нет фотоснимка';cz='No snapshot'"));
	
EndProcedure

&AtClient
Procedure ParametersSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Item.CurrentItem = Items.ParametersPresentation OR Item.CurrentItem = Items.ParametersParameter Then
		
		StandardProcessing = False;
		
		If HaveEditParametersRight Then 
		
			OpenEditParameterValueForm();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ParametersOnStartEdit(Item, NewRow, Clone)
	
	If Item.CurrentItem = Items.ParametersPresentation Then
	
		StandardProcessing = False;
		
		OpenEditParameterValueForm();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenEditParameterValueForm()
	
	If IsPicture(Items.Parameters.CurrentData.Parameter) Then
		
		OpenPickPictureFromForm("Parameters", "PictureAddress", "PictureExtension", GetParametersAliases());
		
	Else
		
		OpenOutletParameterValueInputForm();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenOutletParameterValueInputForm()
	
	CurrentRowId = Items.Parameters.CurrentData.GetID();
	CurrentRowData = Object.Parameters.FindByID(CurrentRowId);
	
	InputFormParameters = GetInputFormParameters(CurrentRowData);
	
	OpenForm("CommonForm.OutletParameterValueInputForm", 
		InputFormParameters,
		ThisForm, 
		, 
		, 
		, 
		New NotifyDescription("OutletParameterValueInputProcessing", ThisForm));

EndProcedure

&AtClient
Procedure OutletParameterValueInputProcessing(Result, AdditionalParameter) Export
	
	If Result = Undefined Then
		
		Items.Parameters.EndEditRow(True);
		
	Else
		
		ObjectRow = Object.Parameters.FindByID(Result.StringNumber);
		
		ObjectRow.Value = Result.Str;
		ObjectRow.Presentation = ObjectRow.Value;
		
		Items.Parameters.EndEditRow(False);
		
		Modified = True;
		
	EndIf;
	
EndProcedure 

&AtClient
Function GetInputFormParameters(CurrentData)
	
	InputFormParameters = New Structure;
	InputFormParameters.Insert("StringNumber", CurrentData.GetID());
	InputFormParameters.Insert("OutletParameter", CurrentData.Parameter);
	InputFormParameters.Insert("PreviousValue", CurrentData.Value);
	
	Return InputFormParameters;
	
EndFunction

#EndRegion

#Region ParametersPictures

&AtClient
Procedure ClearValue(Command)
	
	CurrentData = Items.Parameters.CurrentData;
		
	If Not CurrentData = Undefined Then
			
		CurrentRowId = CurrentData.GetID();
		
		ObjectRow = Object.Parameters.FindByID(CurrentRowId);
		
		If CurrentData.IsPicture Then 
			
			ObjectRow.Value = Undefined;
			ObjectRow.StorageAddress = Undefined;
			ObjectRow.Extension = Undefined;
			ObjectRow.Type = "NoSnapshot";
			
			ThisForm.PictureAddress = "";
			ThisForm.PictureExtension = "";
			
		Else 
			
			ObjectRow.Value = Undefined;
			ObjectRow.Presentation = ObjectRow.Value;
			
		EndIf;
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenParameterSnapshot(Command)
	
	If Not Items.Parameters.CurrentData = Undefined Then
		
		If Items.Parameters.CurrentData.IsPicture Then 
			
			SnapshotStructure = CommonProcessors.GetSnapshot(Items.Parameters.CurrentData.Value, ThisForm.UUID, Object.Description);
			
			If Not SnapshotStructure = Undefined Then 
			 
				GetFile(SnapshotStructure.SnapshotAddress, SnapshotStructure.SnapshotName, True);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PictureAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not Items.Parameters.CurrentData = Undefined Then
		
		If HaveEditParametersRight Then
			
			OpenPickPictureFromForm("Parameters", "PictureAddress", "PictureExtension", GetParametersAliases());
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPickPictureFromForm(FormTableName, PictureAttribute, ExtensionAttribute, Aliases = Undefined)
	
	If Not Items[FormTableName].CurrentData = Undefined Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("FormTableName", FormTableName);
		AdditionalParameters.Insert("PictureAttribute", PictureAttribute);
		AdditionalParameters.Insert("ExtensionAttribute", ExtensionAttribute);
		AdditionalParameters.Insert("Aliases", ?(Aliases = Undefined, New Structure, Aliases));
		AdditionalParameters.Insert("RowId", Items[FormTableName].CurrentData.GetID());
		
		OpenForm("CommonForm.PickPictureFromForm", 
			, 
			ThisForm, 
			, 
			, 
			, 
			New NotifyDescription("SelectPictureProcessing", ThisForm, AdditionalParameters));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectPictureProcessing(Result, AdditionalParameter) Export
	
	If Not Result = Undefined Then
		
		ObjectRow = Object[AdditionalParameter.FormTableName].FindByID(AdditionalParameter.RowId);
		FillPropertyValues(ObjectRow, Result);
		Items[AdditionalParameter.FormTableName].EndEditRow(False);
		
		ThisForm[AdditionalParameter.PictureAttribute] = ObjectRow.StorageAddress;
		ThisForm[AdditionalParameter.ExtensionAttribute] = ObjectRow.Extension;
		
		Modified = True;
		
	Else
		
		Items[AdditionalParameter.FormTableName].EndEditRow(True);
		
		If AdditionalParameter.FormTableName = "Snapshots" Then 
		
			ObjectRow = Object[AdditionalParameter.FormTableName].FindByID(AdditionalParameter.RowId);
			
			If Not ObjectRow = Undefined Then 
				
				If Not ValueIsFilled(ObjectRow.FileName) Then 
					
					Object.Snapshots.Delete(ObjectRow);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function GetParametersAliases()
	
	Aliases = New Structure;
	Aliases.Insert("FileName", "Value");
	
	Return Aliases;
	
EndFunction

#EndRegion

#Region Territories

&AtClient
Procedure TerritoriesListValueOnChange(Item)
	
	OutletValue 		= Items.TerritoriesList.CurrentData.Value;
	
	ParametersFilter 	= New Structure("Value", OutletValue);
	
	FoundRows 			= TerritoriesList.FindRows(ParametersFilter);
	
	If FoundRows.count() > 1 Then
		
		Message(NStr("en='This territory is already listed';ru='Выбранная территория уже есть в списке';cz='This territory is already listed'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TerritoriesListOnChange(Item)
	
	ChangeDistributorChoiceParameters();
	SetContractorsButtonsAvailability();
	
EndProcedure

&AtClient
Procedure TerritoriesListBeforeDeleteRow(Item, Cancel)
	
	OldTerritories = New Array;
	
	For Each Row In ThisForm.TerritoriesList Do
		
		OldTerritories.Add(Row.Value);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure TerritoriesListAfterDeleteRow(Item)
	
	If ValueIsFilled(ThisForm.Object.Distributor) Then
		
		OldPartner = ThisForm.Object.Distributor;
		
		If PartnerNotInTerritories() Then
			
			ShowQueryBox(New NotifyDescription("ProcessDistributorOnTerritoriesChange", ThisForm),
						 NStr("en = 'Partner will be cleared. Continue?'; ru = 'Партнер будет очищен. Продолжить?'"),
						 QuestionDialogMode.YesNo,
						 ,
						 ,
						 NStr("en = 'Continue?'; ru = 'Продолжить?'"));
						 
		EndIf;
		
	Else
		
		NewContractors = GetNewContractorsList();
		
		If NewContractors.Contractors.Count() < ThisForm.ContractorsList.Count() Then
			
			ShowQueryBox(New NotifyDescription("ProcessContractorsOnTerritoriesChange", ThisForm, NewContractors),
						 NStr("en = 'Contractors list will be changed. Continue?'; ru = 'Список контрагентов будет изменен. Продолжить?'"),
						 QuestionDialogMode.YesNo,
						 ,
						 ,
						 NStr("en = 'Continue?'; ru = 'Продолжить?'"));
			
		EndIf;
		
		
		
		
	EndIf;
	
EndProcedure

&AtClient
Function ProcessDistributorOnTerritoriesChange(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		OldPartner = ThisForm.Object.Distributor;
		ThisForm.Object.Distributor = Undefined;
		FillContractors();
		
	Else
		
		RestoreOldTerritories();
		
	EndIf;
	
EndFunction

&AtClient
Procedure RestoreOldTerritories()
	
	ThisForm.TerritoriesList.Clear();
	
	For Each Territory In OldTerritories Do
		
		NewRow = ThisForm.TerritoriesList.Add();
		NewRow.Value = Territory;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessContractorsOnTerritoriesChange(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		Contractors = Parameters.Contractors;
		HasDefault = Parameters.HasDefault;
		Default = Parameters.Default;
		ThisForm.ContractorsList.Clear();
		
		If Contractors.Count() > 0 Then
			
			For Each Contractor In Contractors Do
				
				NewRow = ThisForm.ContractorsList.Add();
				NewRow.Contractor = Contractor;
				
			EndDo;
			
			DefaultRowIndex = ?(HasDefault, Default, 0);
			ThisForm.ContractorsList[DefaultRowIndex].Default = True;
			
		EndIf;
		
	Else
		
		RestoreOldTerritories();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DistributorStartChoice(Item, ChoiceData, StandardProcessing)
	
	If ThisForm.TerritoriesList.Count() = 0 Then
		
		Message(NStr("en = 'Choose territories before choosing partner'; ru = 'Выберите территории перед тем как выбирать партнера.'"));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Prices

&AtClient
Procedure PricesPriceListOnChange(Item)
	
	requestMap = New Map;
	requestMap.Insert("pName", "PriceList");
	requestMap.Insert("checkingItem", Items.Prices.CurrentData);
	requestMap.Insert("tabularSection", Object.Prices);
	
	ClientProcessors.UniqueRows(requestMap);
	
EndProcedure

&AtClient
Procedure PricesPriceListStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("Document.PriceList.ChoiceForm", , Item);
	
EndProcedure

#EndRegion

#Region Snapshots

&AtClient
Procedure SnapshotsOnActivateRow(Item)
	
	If Not Item.CurrentData = Undefined Then
	
		ThisForm.OutletSnapshotAddress = Item.CurrentData.StorageAddress;
		ThisForm.OutletSnapshotExtension = Item.CurrentData.Extension;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SnapshotsAfterDeleteRow(Item)
	
	If Item.CurrentData = Undefined Then
		
		ThisForm.OutletSnapshotAddress = Undefined;
		ThisForm.OutletSnapshotExtension = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SnapshotsOnStartEdit(Item, NewRow, Clone)
	
	If Item.CurrentItem = Items.SnapshotsPresentation Then
		
		OpenPickPictureFromForm("Snapshots","OutletSnapshotAddress", "OutletSnapshotExtension");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SnapshotsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Item.CurrentItem = Items.SnapshotsPresentation Then
		
		StandardProcessing = False;
		
		If HaveEditParametersRight Then
			
			OpenPickPictureFromForm("Snapshots","OutletSnapshotAddress", "OutletSnapshotExtension");
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSnapshot(Command)
	
	If Not Items.Snapshots.CurrentData = Undefined Then 
		
		SnapshotStructure = CommonProcessors.GetSnapshot(Items.Snapshots.CurrentData.FileName, ThisForm.UUID, Object.Description);
		
		If Not SnapshotStructure = Undefined Then 
			 
			GetFile(SnapshotStructure.SnapshotAddress, SnapshotStructure.SnapshotName, True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OutletSnapshotAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not Items.Snapshots.CurrentData = Undefined Then 
		
		If HaveEditParametersRight Then
		
			OpenPickPictureFromForm("Snapshots", "OutletSnapshotAddress", "OutletSnapshotExtension");
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Contractors

&AtClient
Procedure DistributorOnChange(Item)
	
	If NOT ThisForm.Object.ContractorsList.Count() = 0 Then
		
		ShowQueryBox(New NotifyDescription("ProcessDistributorChange", ThisForm),
										   NStr("en = 'Value table ""Contractors"" well be changed. Continue?'; ru = 'Табличная часть ""Контрагенты"" будет изменена. Продолжить?'"),
										   QuestionDialogMode.YesNo,
										   ,
										   DialogReturnCode.Yes,
										   NStr("en = 'Continue?'; ru = 'Продолжить?'"));
										   
	Else
		
		SetContractorsButtonsAvailability();
		FillContractors();
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractorsListChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	FilterParameters = New Structure("Contractor", SelectedValue);
	ContractorExists = ThisForm.ContractorsList.FindRows(FilterParameters).Count();
	
	If NOT ContractorExists Then
		
		FirstItem = ThisForm.ContractorsList.Count() = 0;
		NewContractorRow = ThisForm.ContractorsList.Add();
		NewContractorRow.Contractor = SelectedValue;
		NewContractorRow.Default = FirstItem;
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractorsListDefaultOnChange(Item)
		
	CurrentData = Items.ContractorsList.CurrentData;
	IsNotDefaultAfterChange = CurrentData.Default;
	ThisRowIndex = ThisForm.ContractorsList.IndexOf(CurrentData);
	ThisRow = ThisForm.ContractorsList.Get(ThisRowIndex);
	
	If IsNotDefaultAfterChange Then
		
		For Each Row In ThisForm.ContractorsList Do
			
			Row.Default = ThisForm.ContractorsList.IndexOf(Row) = ThisRowIndex;
			
		EndDo;
		
	Else
		
		ThisRow.Default = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetContractorsButtonsAvailability()
	
	IsPartnerFilled = ValueIsFilled(ThisForm.Object.Distributor);
	Items.AddContractor.Enabled = Not IsPartnerFilled;
	Items.DeleteContractor.Enabled = Not IsPartnerFilled;
	Items.ContractorsListDefault.ReadOnly = IsPartnerFilled;
	
EndProcedure

&AtClient
Procedure DeleteContractor(Command)
	
	CurrentData = Items.ContractorsList.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		CurrentDataIndex = ThisForm.ContractorsList.IndexOf(CurrentData);
		ThisForm.ContractorsList.Delete(CurrentDataIndex);
		Modified = True;
		
	EndIf;
	
	If ThisForm.ContractorsList.Count() Then
		
		FilterParameters = New Structure("Default", True);
		NoDefault = NOT ThisForm.ContractorsList.FindRows(FilterParameters).Count();
		
		If NoDefault Then
			
			ThisForm.ContractorsList[0].Default = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddContractor(Command)
	
	ChoiceForm = GetForm("Catalog.Contractors.ChoiceForm", , Items.ContractorsList);
	Filter = ChoiceForm.List.Filter;
	
	FilterItems = GetFilters();
	
	For Each FilterItem In FilterItems Do
		
		NewRow = Filter.Items.Add(Type("DataCompositionFilterItem"));
		FillPropertyValues(NewRow, FilterItem);
		
	EndDo;
	
	ChoiceForm.CloseOnChoice = False;
	
	OpenForm(ChoiceForm);
	
EndProcedure

&AtClient
Procedure ProcessDistributorChange(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		ThisForm.ContractorsList.Clear();
		
		FillContractors();
		
		OldPartner = ThisForm.Object.Distributor;
		
	ElsIf Result = DialogReturnCode.No Then
		
		ThisForm.Object.Distributor = OldPartner;
		
	EndIf;
	
	SetContractorsButtonsAvailability();
	
EndProcedure

#EndRegion

#Region ContactList

&AtClient
Procedure AddContact(Command)
	
	ChoiceForm = GetForm("Catalog.ContactPersons.ChoiceForm", , Items.ContactList);
	
	ChoiceForm.CloseOnChoice = False;
	
	OpenForm(ChoiceForm);
	
EndProcedure

&AtClient
Procedure ContactListChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	FilterParameters = New Structure("ContactPerson", SelectedValue);
	ContactExists = ThisForm.Object.ContactPersons.FindRows(FilterParameters).Count();
	
	If Not ContactExists Then
		
		NewContactRow = ThisForm.Object.ContactPersons.Add();
		NewContactRow.ContactPerson = SelectedValue;
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteContact(Command)
	
	CurrentData = Items.ContactList.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		CurrentDataIndex = ThisForm.Object.ContactPersons.IndexOf(CurrentData);
		ThisForm.Object.ContactPersons.Delete(CurrentDataIndex);
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentData = Items.ContactList.CurrentData;
	
	If NOT CurrentData = Undefined Then
		
		OpenForm("Catalog.ContactPersons.ObjectForm", New Structure("Key", CurrentData.ContactPerson), ThisForm);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetPartners(Outlet)
	
	Query = New Query(
	"SELECT ALLOWED DISTINCT
	|	DistributorTerritories.Ref AS Partner
	|FROM
	|	Catalog.Territory.Outlets AS TerritoryOutlets
	|		LEFT JOIN Catalog.Distributor.Territories AS DistributorTerritories
	|		ON TerritoryOutlets.Ref = DistributorTerritories.Territory
	|WHERE
	|	TerritoryOutlets.Outlet = &Outlet
	|
	|ORDER BY
	|	Partner
	|AUTOORDER");
	Query.SetParameter("Outlet", Outlet);
	Result = Query.Execute().Unload();
	
	ChoiceData = New ValueList;
	
	For Each Row In Result Do
		
		ChoiceData.Add(Row.Partner);
		
	EndDo;
	
	Return ChoiceData;
	
EndFunction

&AtClient
Procedure SetCoordinates(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Longitude", Object.Longitude);
	FormParameters.Insert("Latitude", Object.Lattitude);
	
	OpenForm("Catalog.Outlet.Form.SetCoordinatesForm", FormParameters, ThisForm, , , , New NotifyDescription("SetCoordinatesFromMap", ThisForm));
	
EndProcedure

&AtClient
Procedure SetCoordinatesFromMap(Result, AdditionalParameter) Export
	
	If Not Result = Undefined And Result.Property("Latitude") And Result.Property("Longitude") Then
		
		Object.Lattitude = Result.Latitude;
		Object.Longitude = Result.Longitude;
		
		Modified = True;
		
	EndIf;
	
EndProcedure
#EndRegion

#EndRegion

