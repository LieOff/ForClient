
Function GetRightsValueTree() Export
	
	Query = New Query(
	"SELECT
	|	SystemObjects.Ref AS SystemObject,
	|	CASE
	|		WHEN SystemObjects.Ref.IsFolder
	|			THEN 1
	|		ELSE 0
	|	END AS Picture,
	|	SystemObjects.Description AS SystemObjectName,
	|	CASE
	|		WHEN SystemObjects.Ref.Parent = VALUE(Catalog.SystemObjects.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItsSection,
	|	CASE
	|		WHEN SystemObjects.Ref.Parent.Description = ""en = 'Reports'; ru = 'Отчеты'""
	|				OR SystemObjects.Ref.Description = ""en = 'Reports'; ru = 'Отчеты'""
	|				OR SystemObjects.Ref.Description = ""en = 'Encashment'; ru = 'Инкассация'""
	|				OR SystemObjects.Ref.Description = ""en = 'Visit'; ru = 'Визит'""
	|				OR SystemObjects.Ref.Description = ""en = 'Roles of users'; ru = 'Роли пользователей'""
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItsReport,
	|	FALSE AS Read,
	|	FALSE AS Edit,
	|	FALSE AS MarkForDeletion
	|FROM
	|	Catalog.SystemObjects AS SystemObjects
	|WHERE
	|	SystemObjects.DeletionMark = FALSE
	|
	|ORDER BY
	|	SystemObject HIERARCHY
	|AUTOORDER");
	
	QueryResult = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	// Перевести дерево значений
	For Each Element in QueryResult.Rows Do
		
		TranslateRightsTree(Element.Rows);
		
		Element.SystemObjectName = NStr(Element.SystemObjectName);
		
	EndDo;
	
	// Возвращаем дерево значений. Оно используется для вывода назначенных прав
	// доступа.
	Return QueryResult;
	
EndFunction

Function GetOtherRightsTable(CatalogName) Export
	
	RightsTable = New ValueTable;
	RightsTable.Columns.Add("AccessRight");
	RightsTable.Columns.Add("AccessRightName");
	RightsTable.Columns.Add("Use");
	
	If CatalogName = "MobileAppAccessRights" Then 
		
		UseReturns		= Constants.UseReturns.Get();
		UseOrders		= Constants.UseOrders.Get();
		UseEncashments	= Constants.UseEncashments.Get();
		
	Else 
		
		UseReturns		= True;
		UseOrders		= True;
		UseEncashments	= True;
		
	EndIf;
	
	If ValueIsFilled(CatalogName) Then 
		
		RightsSelection = Catalogs[CatalogName].Select( , , , "Code Asc");
		
		While RightsSelection.Next() Do 
			
			// Удалить права не соответвующие настройкам
			If RightsSelection.Ref = Catalogs.MobileAppAccessRights.AccessToReturn And Not UseReturns Then 
				
				Continue;
				
			EndIf;
			
			If RightsSelection.Ref = Catalogs.MobileAppAccessRights.AccessToEncashment And Not UseEncashments Then 
				
				Continue;
				
			EndIf;
			
			If RightsSelection.Ref = Catalogs.MobileAppAccessRights.AccessToOrder And Not UseOrders Then 
				
				Continue;
				
			EndIf;
			
			Ins					= RightsTable.Add();
			Ins.AccessRight		= RightsSelection.Ref;
			Ins.AccessRightName	= NStr(RightsSelection.Ref.Description);
			Ins.Use				= False;
			
		EndDo;
		
	EndIf;
	
	Return RightsTable;
	
EndFunction

Procedure TranslateRightsTree(TreeElement)
	
	For Each Element in TreeElement Do
		
		TranslateRightsTree(Element.Rows);
		
		Element.SystemObjectName = NStr(Element.SystemObjectName);
		
	EndDo;	
	
EndProcedure

Function GetSelectedRightsFromValueTree(RightsValueTree) Export
	
	// Получаем из переданного дерева значений таблицу значений прав у которых
	// стоит "Use". Группы отбрасываются. В результате получается таблица значений
	// которую можно загрузить в табличную часть элемента справочника "Роли 
	// пользователей".
	SelectedRights = New ValueTable;
	
	SelectedRights.Columns.Add("SystemObject");
	SelectedRights.Columns.Add("Read");
	SelectedRights.Columns.Add("Edit");
	SelectedRights.Columns.Add("MarkForDeletion");
	
	GetSelectedRights(RightsValueTree.Rows, SelectedRights);
	
	Return SelectedRights;
	
EndFunction

Procedure GetSelectedRights(RightsValueTreeRows, RightsValueTable)
	
	For Each Row In RightsValueTreeRows Do
		
		IsFolder = Row.SystemObject.IsFolder;
		
		If Not IsFolder Then
			
			If Not Row.Read = 1 And Not Row.Edit = 1 And Not Row.MarkForDeletion = 1 Then
				
				Continue;
				
			Else 
				
				NewRow					= RightsValueTable.Add();
				NewRow.SystemObject		= Row.SystemObject;
				NewRow.Read				= Row.Read = 1;
				NewRow.Edit				= Row.Edit = 1;
				NewRow.MarkForDeletion	= Row.MarkForDeletion = 1;
				
			EndIf;
			
		Else
			
			GetSelectedRights(Row.Rows, RightsValueTable);
			
		EndIf;
		
	EndDo;
	
EndProcedure

