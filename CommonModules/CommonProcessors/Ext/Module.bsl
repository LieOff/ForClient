
Function GetTerritory(Outlet) Export
	
	Query = New Query;
	
	Query.Text = "SELECT ALLOWED TOP 1
				|	TerritoryOutlets.Ref
				|FROM
				|	Catalog.Territory.Outlets AS TerritoryOutlets
				|WHERE
				|	TerritoryOutlets.Outlet = &Outlet";
	
	Query.SetParameter("Outlet", Outlet);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.Ref;	
	
EndFunction

Function GetPredefinedItems(PredefinedItems) Export 
	
	ItemsMap = New Map;
	
	For Each Row In PredefinedItems Do
		
		If Row.Key = "Catalog.User" Then
			
			Query = New Query;
			Query.Text = "SELECT ALLOWED
						|	User.Ref AS Ref
						|FROM
						|	Catalog.User AS User
						|WHERE
						|	User.Role = &Role";
			
			Query.SetParameter("Role", "SR");
			
		Else
			
			Query = New Query;
			Query.Text = "SELECT ALLOWED Ref FROM " + Row.Key;
			
		EndIf;
		
		Result = Query.Execute().Unload();
		
		If Result.Count() = 1 Then
			
			ItemsMap.Insert(Row.Value, Result[0].Ref);
			
		EndIf;
		
	EndDo;
	
	Return ItemsMap;
	
EndFunction

Function GetQuestionGroupType(TypeString = "SKUQuestions") Export
	
	If TypeString = "SKUQuestions" Then 
		
		Return Enums.QuestionGroupTypes.SKUQuestions;
		
	Else 
		
		Return Enums.QuestionGroupTypes.RegularQuestions;
		
	EndIf;
	
EndFunction

Function StringToNumber(String) Export
	
	Try
		
		Result = StrReplace(String, " ", "");
		Result = StrReplace(Result, Chars.NBSp, "");
		
		Result = Number(Result);
		
	Except
		
		Result = 0;
		
	EndTry;
	
	Return Result;
	
EndFunction

Function GetConnectionToServer() Export
	
	// Инициализация подключения
	
	Password = Constants.bitmobile_Пароль.Get();
	Server = StrReplace(Constants.bitmobile_Сервер.Get(), "localhost", "127.0.0.1");
	Port = Constants.bitmobile_Порт.Get();
	
	DefaultPort 		= 	Undefined;
	SecureConnection 	= 	Undefined;
	
	If Constants.bitmobile_ИспользуетсяHTTPS.Get() Then
		DefaultPort 		= 	443;
		SecureConnection 	= 	New OpenSSLSecureConnection(Undefined, Undefined);
	Else
		DefaultPort 		= 	80;
		SecureConnection 	= 	Undefined;
	EndIf;
	
	If Not ValueIsFilled(Port) Then 
		
		Port = DefaultPort;
		
	EndIf;;

	
	Try
		
		Return New HTTPConnection(Server, ?(Port = 0, 80, Port), "admin", Password,,,SecureConnection);
		
	Except
		
		Return Undefined;
		
	EndTry;
	
EndFunction

Function GetWebDAVPathOnServer() Export
	
	Path = Constants.bitmobile_ПутьНаСервере.Get();
	
	Return StrReplace(Path, "admin/", "webdav");
	
EndFunction

Function GetSnapshot(FileUUID, FormUUID, NameForFile) Export
	
	If ValueIsFilled(FileUUID) Then
		
		// Убрать запрещенные символы из имени файла
		NameForFile = PrepareFileName(NameForFile);
		
		Try
			
			If TypeOf(FileUUID) = Type("String") Then 
				
				ShapshotUUID = New UUID(FileUUID);
				
			Else 
				
				ShapshotUUID = FileUUID;
				
			EndIf;
			
			// Ищем данные о файле
			FileRow = InformationRegisters.bitmobile_ХранилищеФайлов.Select(New Structure("ИмяФайла", ShapshotUUID));
			
			// Если найден уид в таблице файлов
			If FileRow.Next() Then
				
				Connection = CommonProcessors.GetConnectionToServer();
				
				Path = CommonProcessors.GetWebDAVPathOnServer();
				
				// Забираем бинарные данные из таблицы файлов
				BinaryDataOfFile = FileRow.Хранилище.Get();
				
				// Если бинарные данные есть
				If ValueIsFilled(BinaryDataOfFile) Then
					
					ReturnStructure = New Structure("SnapshotAddress, SnapshotName", PutToTempStorage(BinaryDataOfFile, FormUUID), NameForFile + FileRow.Расширение);
					
					Return ReturnStructure;
					
				// Если нет бинарных данных
				Else
					
					// Если соединение было создано успешно
					If Not Connection = Undefined Then
						
						// Пробуем забрать файл
						Try
							
							WebDAVFile = GetTempFileName(FileRow.Расширение);
							
							Connection.Get(Path + FileRow.ПолноеИмяФайла, WebDAVFile);
							
							BinaryDataOfFile = New BinaryData(WebDAVFile);
							
							ReturnStructure = New Structure("SnapshotAddress, SnapshotName", PutToTempStorage(BinaryDataOfFile, FormUUID), NameForFile + FileRow.Расширение);
							
							Return ReturnStructure;
							
						Except
						EndTry;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		Except
		EndTry;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Function PrepareFileName(FileName)
	
	FileName = StrReplace(FileName, "/", "");
	FileName = StrReplace(FileName, "\", "");
	FileName = StrReplace(FileName, "|", "");
	FileName = StrReplace(FileName, ":", "");
	FileName = StrReplace(FileName, "*", "");
	FileName = StrReplace(FileName, """", "");
	FileName = StrReplace(FileName, "<", "");
	FileName = StrReplace(FileName, ">", "");
	FileName = StrReplace(FileName, "?", "");
	
	Return FileName;
	
EndFunction

Procedure FillDefaultValues_DocumentBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Or Source.AdditionalProperties.Property("FillDefaultValues") Then 
		
		FillDefaultValues(Source, Source.AdditionalProperties.Property("ЗагрузкаBitmobile"));
		
	EndIf;
	
EndProcedure

Procedure FillDefaultValues_CatalogBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Or Source.AdditionalProperties.Property("FillDefaultValues") Then 
		
		FillDefaultValues(Source, Source.AdditionalProperties.Property("ЗагрузкаBitmobile"));
		
	EndIf;
	
EndProcedure

Procedure FillDefaultValues(Source, IsBMLoad)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DefaultValues.Object AS Object,
		|	DefaultValues.TabularSection AS TabularSection,
		|	DefaultValues.Attribute AS Attribute,
		|	DefaultValues.Value,
		|	DefaultValues.TypeName
		|FROM
		|	InformationRegister.DefaultValues AS DefaultValues
		|WHERE
		|	DefaultValues.Object = &ObjectName
		|
		|ORDER BY
		|	Object,
		|	TabularSection,
		|	Attribute";
	
	Query.SetParameter("ObjectName", Source.Metadata().Name);
	
	DefaultValuesTable = Query.Execute().Unload();
	
	TabularSectionsTable = DefaultValuesTable.Copy();
	
	TabularSectionsTable.GroupBy("TabularSection");
	
	For Each TabularSectionsRow In TabularSectionsTable Do 
		
		ProcessedData = DefaultValuesTable.FindRows(New Structure("TabularSection", TabularSectionsRow.TabularSection));
		
		If ValueIsFilled(TabularSectionsRow.TabularSection) Then // TS attributes 
			
			For Each TSItem In Source[TabularSectionsRow.TabularSection] Do 
				
				For Each ProcessedValue In ProcessedData Do  
				
					If ValueIsFilled(ProcessedValue.Value) And Not ValueIsFilled(TSItem[ProcessedValue.Attribute]) Then 
						
						Try
							
							TSItem[ProcessedValue.Attribute] = ProcessedValue.Value;
							
						Except
						
						EndTry;
						
						If IsBMLoad Then 
							
							Source.AdditionalProperties.Delete("ЗагрузкаBitmobile");
							
							IsBMLoad = False;
							
						EndIf;
						
					EndIf;
					
				EndDo;
				
			EndDo;
			
		Else // Object attributes
			
			For Each ProcessedValue In ProcessedData Do  
				
				If ValueIsFilled(ProcessedValue.Value) And Not ValueIsFilled(Source[ProcessedValue.Attribute]) Then 
					
					Try
						
						Source[ProcessedValue.Attribute] = ProcessedValue.Value;
						
					Except
					
					EndTry;
					
					If IsBMLoad Then 
						
						Source.AdditionalProperties.Delete("ЗагрузкаBitmobile");
						
						IsBMLoad = False;
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillDefaultValuesInformationRegister() Export
	
	// Save old data
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DefaultValues.Object,
		|	DefaultValues.TabularSection,
		|	DefaultValues.Attribute,
		|	DefaultValues.TypeName,
		|	DefaultValues.Value
		|FROM
		|	InformationRegister.DefaultValues AS DefaultValues";
	
	OldValues = Query.Execute().Unload();
	
	// Clear register
	RecordSet = InformationRegisters.DefaultValues.CreateRecordSet();
	RecordSet.Write();
	
	// Fill catalogs
	ReadMetadataCollection(Metadata.Catalogs, OldValues);
	
	// Fill documents
	ReadMetadataCollection(Metadata.Documents, OldValues);
	
EndProcedure

Procedure ReadMetadataCollection(Collection, OldValues) 
	
	For Each ItemMetadata In Collection Do 
		
		If ItemMetadata.Name = "MobileAppSettings"
			Or ItemMetadata.Name = "bitmobile_НастройкиСинхронизации"
			Or ItemMetadata.Name = "OutletsPrimaryParametersSettings"
			Or ItemMetadata.Name = "SystemObjects"
			Or ItemMetadata.Name = "RolesOfUsers"
			Or ItemMetadata.Name = "MobileAppAccessRights"
			Or ItemMetadata.Name = "AdditionalAccessRights" 
			Or ItemMetadata.Name = "Guestbook"
			Or ItemMetadata.Name = "VisitPlan" 
			Or ItemMetadata.Name = "Questionnaire" Then 
			
			Continue;
			
		EndIf;
		
		For Each AttrItem In ItemMetadata.StandardAttributes Do 
			
			If AttrItem.FillChecking = FillChecking.ShowError Then 
				
				NewRecord					= InformationRegisters.DefaultValues.CreateRecordManager();
				NewRecord.Object			= ItemMetadata.Name;
				NewRecord.TabularSection	= "";
				NewRecord.Attribute			= AttrItem.Name;
				
				For Each TypeItem In AttrItem.Type.Types() Do 
					
					NewRecord.TypeName		=  NewRecord.TypeName + GetTypeName(TypeItem) + ",";
					
				EndDo;
				
				NewRecord.TypeName			= Left(NewRecord.TypeName, StrLen(NewRecord.TypeName) - 1);				
				NewRecord.Value				= GetValue(NewRecord, OldValues);
				
				NewRecord.Write();
				
			EndIf;
			
		EndDo;
		
		For Each AttrItem In ItemMetadata.Attributes Do 
			
			If ItemMetadata.Name = "User" And AttrItem.Name = "UserName" Then 
				
				Continue;
				
			EndIf;
			
			If AttrItem.FillChecking = FillChecking.ShowError Then 
				
				NewRecord					= InformationRegisters.DefaultValues.CreateRecordManager();
				NewRecord.Object			= ItemMetadata.Name;
				NewRecord.TabularSection	= "";
				NewRecord.Attribute			= AttrItem.Name;
				
				For Each TypeItem In AttrItem.Type.Types() Do 
					
					NewRecord.TypeName		=  NewRecord.TypeName + GetTypeName(TypeItem) + ",";
					
				EndDo;
				
				NewRecord.TypeName			= Left(NewRecord.TypeName, StrLen(NewRecord.TypeName) - 1);
				NewRecord.Value				= GetValue(NewRecord, OldValues);
				
				NewRecord.Write();
				
			EndIf;
			
		EndDo;
		
		For Each TSItem In ItemMetadata.TabularSections Do 
			
			If ItemMetadata.Name = "VisitPlan" And TSItem.Name = "Outlets" Then 
			
				Continue;
				
			EndIf;
			
			For Each AttrItem In TSItem.Attributes Do
			
				If AttrItem.FillChecking = FillChecking.ShowError Then 
					
					NewRecord					= InformationRegisters.DefaultValues.CreateRecordManager();
					NewRecord.Object			= ItemMetadata.Name;
					NewRecord.TabularSection	= TSItem.Name;
					NewRecord.Attribute			= AttrItem.Name;
					
					For Each TypeItem In AttrItem.Type.Types() Do 
						
						NewRecord.TypeName		=  NewRecord.TypeName + GetTypeName(TypeItem) + ",";
						
					EndDo;
					
					NewRecord.TypeName			= Left(NewRecord.TypeName, StrLen(NewRecord.TypeName) - 1);
					NewRecord.Value				= GetValue(NewRecord, OldValues);
					
					NewRecord.Write();
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function GetValue(NewRecord, OldValues)
	
	FoundStructure = New Structure("Object, TabularSection, Attribute, TypeName", NewRecord.Object, NewRecord.TabularSection, NewRecord.Attribute, NewRecord.TypeName);
	
	FoundedRows = OldValues.FindRows(FoundStructure);
	
	If FoundedRows.Count() = 0 Then 
		
		Return Undefined;
		
	Else 
		
		Return FoundedRows[0].Value;
		
	EndIf;
	
EndFunction

Function GetTypeName(mType)
	
	MetadataOfType = Metadata.FindByType(mType);
	
	If MetadataOfType = Undefined Then  
		
		Return mType;
		
	Else 
		
		FullTypeName = MetadataOfType.FullName();
		
		DotPosition = Find(FullTypeName, ".");
		
		LeftPart = Left(FullTypeName, DotPosition - 1);
		
		FullTypeName = StrReplace(FullTypeName, LeftPart, LeftPart + "Ref"); 
		
		Return FullTypeName;
		
	EndIf;
	
EndFunction

Procedure CheckSnapshots(Source, Cancel) Export
	
	If TypeOf(Source) = Type("CatalogObject.Outlet") Then 
		
		FilesArray = New Array;
		
		// Получить массив актуальных файлов для ТТ
		For Each StrParameter In Source.Parameters Do 
			
			If StrParameter.Parameter.DataType = Enums.DataType.Snapshot And ValueIsFilled(StrParameter.Value) Then 
				
				Try
					
					SnapshotUUID = New UUID(StrParameter.Value);
					
					FilesArray.Add(SnapshotUUID);
					
				Except
					
				EndTry;
				
			EndIf;
			
		EndDo;
		
		For Each StrSnapshot In Source.Snapshots Do 
			
			If ValueIsFilled(StrSnapshot.FileName) Then 
				
				Try
					
					SnapshotUUID = New UUID(StrSnapshot.FileName);
					
					FilesArray.Add(SnapshotUUID);
					
				Except
					
				EndTry;
				
			EndIf;
			
		EndDo;
		
		DeleteIncorrectFiles(Source.Ref, FilesArray);
		
	ElsIf TypeOf(Source) = Type("CatalogObject.SKU") Then
		
		FilesArray = New Array;
		
		If ValueIsFilled(Source.DefaultPicture) Then 
			
			FilesArray.Add(Source.DefaultPicture);
			
		EndIf;
		
		DeleteIncorrectFiles(Source.Ref, FilesArray); 
		
	EndIf;
	
EndProcedure

Procedure DeleteIncorrectFiles(Ref, CorrectFilesArray)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	bitmobile_ХранилищеФайлов.Объект,
		|	bitmobile_ХранилищеФайлов.НаправлениеСинхронизации,
		|	bitmobile_ХранилищеФайлов.Действие,
		|	bitmobile_ХранилищеФайлов.ИмяФайла,
		|	bitmobile_ХранилищеФайлов.ПолноеИмяФайла,
		|	bitmobile_ХранилищеФайлов.Расширение,
		|	bitmobile_ХранилищеФайлов.Хранилище,
		|	bitmobile_ХранилищеФайлов.ФайлЗаблокирован
		|FROM
		|	InformationRegister.bitmobile_ХранилищеФайлов AS bitmobile_ХранилищеФайлов
		|WHERE
		|	bitmobile_ХранилищеФайлов.ФайлЗаблокирован = FALSE
		|	AND bitmobile_ХранилищеФайлов.Объект = &Ref
		|	AND NOT bitmobile_ХранилищеФайлов.ИмяФайла IN (&CorrectFilesArray)";
	
	Query.SetParameter("CorrectFilesArray", CorrectFilesArray);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		If Selection.Действие = Enums.bitmobile_ДействияПриСинхронизации.EmptyRef() Then 
			
			RecordManager = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
			
			FillPropertyValues(RecordManager, Selection);
			
			RecordManager.Read();
		
			If RecordManager.Selected() Then
				
				RecordManager.Действие = Enums.bitmobile_ДействияПриСинхронизации.УдалитьФайл;
				
				RecordManager.Write();
				
			EndIf;
			
		ElsIf Selection.Действие = Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл Then
			
			RecordManager = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
			
			FillPropertyValues(RecordManager, Selection);
			
			RecordManager.Read();
			
			If RecordManager.Selected() Then
				
				RecordManager.Delete();
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

