
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PredefinedItems = New Map;
	PredefinedItems.Insert("Catalog.User", "SRs");
	PredefinedItems.Insert("Catalog.Region", "Owner");
	
	ItemsCollection = CommonProcessors.GetPredefinedItems(PredefinedItems);
	
	For Each Item In ItemsCollection Do
		
		If TypeOf(Object[Item.Key]) = Type("FormDataCollection") Then
			
			If Object[Item.Key].Count() = 0 Then
			
				NewRow = Object[Item.Key].Add();
				
				For Each Attribute In Metadata.Catalogs.Territory.TabularSections[Item.Key].Attributes Do
					
					If TypeOf(NewRow[Attribute.Name]) = TypeOf(Item.Value) Then
						
						NewRow[Attribute.Name] = Item.Value;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		Else
			
			Object[Item.Key] = Item.Value;
				
		EndIf;
		
	EndDo;
	
	FillSKUGroups();
	
	ChangeOutletsSelectQuery();
	
	FillOutletsSelectFilters();
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Записать территорию в группы номенклатуры
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	SKUGroupTerritories.Ref AS SKUGroup
		|FROM
		|	Catalog.SKUGroup.Territories AS SKUGroupTerritories
		|WHERE
		|	SKUGroupTerritories.Territory = &Ref
		|	AND NOT SKUGroupTerritories.Ref IN (&SGArray)";
	
	Query.SetParameter("Ref", CurrentObject.Ref);
	Query.SetParameter("SGArray", SKUGroups.Unload().UnloadColumn("SKUGroup"));
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		GroupObject = Selection.SKUGroup.GetObject();
		
		FoundString = GroupObject.Territories.Find(CurrentObject.Ref);
		
		If Not FoundString = Undefined Then 
			
			GroupObject.Territories.Delete(FoundString);			
			
		EndIf;
		
		GroupObject.Write();
		
	EndDo;
		
	For Each Row In SKUGroups Do 
		
		GroupObject = Row.SKUGroup.GetObject();
		
		FoundString = GroupObject.Territories.Find(CurrentObject.Ref);
		
		If FoundString = Undefined Then 
			
			NewRow							= GroupObject.Territories.Add();
			NewRow.Territory				= CurrentObject.Ref;
			NewRow.LineNumberInTerritory	= Row.LineNumber;
			
		Else 
			
			FoundString = Row.LineNumber;
			
		EndIf;
		
		GroupObject.Write();
			
	EndDo;
	
EndProcedure

&AtServer
Procedure FillSKUGroups()
	
	// Заполнить группы SKU
	SKUGroups.Clear();
	
	If ValueIsFilled(Object.Ref) Then 
	
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED DISTINCT
			|	SKUGroupTerritories.Ref AS SKUGroup,
			|	SKUGroupTerritories.LineNumberInTerritory
			|FROM
			|	Catalog.SKUGroup.Territories AS SKUGroupTerritories
			|WHERE
			|	SKUGroupTerritories.Territory = &Ref
			|
			|ORDER BY
			|	SKUGroupTerritories.LineNumberInTerritory";
		
		Query.SetParameter("Ref", Object.Ref);
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			NewRow = SKUGroups.Add();
			NewRow.SKUGroup = Selection.SKUGroup;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function ItsFolder(Value)
	
	If Value.IsFolder Then 
		
		Return True;
		
	Else 
		
		Return False;
		
	EndIf;
		
EndFunction

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure

&AtServer
Procedure ChangeOutletsSelectQuery()
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(OutletsSelect.QueryText);
	
	QuerySchema.QueryBatch[0].Columns[3].Alias = NStr("en='Territory';ru='Территория';cz='Ъzemн'");
	QuerySchema.QueryBatch[0].Columns[4].Alias = NStr("en='Region';ru='Регион';cz='Region'");
	
	OutletsSelect.QueryText = QuerySchema.GetQueryText();
	
EndProcedure

&AtServer
Procedure FillOutletsSelectFilters()

	PartnerFilter = OutletsSelect.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	PartnerFilter.LeftValue = New DataCompositionField("Distributor");
	PartnerFilter.Use = False;

	ClassFilter = OutletsSelect.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ClassFilter.LeftValue = New DataCompositionField("Class");
	ClassFilter.Use = False;

	TypeFilter = OutletsSelect.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	TypeFilter.LeftValue = New DataCompositionField("Type");
	TypeFilter.Use = False;

	TerritoryFilter = OutletsSelect.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	TerritoryFilter.LeftValue = New DataCompositionField(NStr("en='Territory';ru='Территория';cz='Ъzemн'"));
	TerritoryFilter.Use = False;

	RegionFilter = OutletsSelect.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	RegionFilter.LeftValue = New DataCompositionField(NStr("en='Region';ru='Регион';cz='Region'"));
	RegionFilter.Use = False;

EndProcedure

&AtServer
Function GetOutletsArrayFromDynamicList()
	
	DCS = New DataCompositionSchema;
	
	DataSource = DCS.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "Local";
	DataSource.ConnectionString = "";
	
	DataSet = DCS.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSet1";
	
	DataSet.Query = OutletsSelect.QueryText;
	DataSet.DataSource = "DataSource1";
	DataSet.AutoFillAvailableFields = True;
	
	DCG = DCS.DefaultSettings.Structure.Add(Type("DataCompositionGroup"));
	DCG.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	DCG.Use = True;
	
	FieldsArray = New Array;
	FieldsArray.Add("Outlet");
	
	For Each FieldName In FieldsArray Do
		
		NewField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = FieldName;
		NewField.DataPath = FieldName;
		NewField.Title = FieldName;
		
		ChoiceField = DCS.DefaultSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		ChoiceField.Field = New DataCompositionField(FieldName);
		ChoiceField.Use = True;
		
	EndDo;
	
	FillDataCompositionSchemeFilters(DCS, OutletsSelect.Filter.Items);
	
	DCTC = New DataCompositionTemplateComposer;
	Template = DCTC.Execute(DCS, 
							DCS.DefaultSettings,
							,
							,
							Type("DataCompositionValueCollectionTemplateGenerator"));
	
	
	DCP = New DataCompositionProcessor;
	DCP.Initialize(Template);
	
	OutletsVT = New ValueTable;
	
	DCRVCOP = New DataCompositionResultValueCollectionOutputProcessor;
	DCRVCOP.SetObject(OutletsVT);
	DCRVCOP.Output(DCP);
	
	Return OutletsVT.UnloadColumn("Outlet");
	
EndFunction

&AtServerNoContext
Procedure FillDataCompositionSchemeFilters(DCS, Elements, Parent = Undefined)
	
	For Each Element In Elements Do
		
		If Parent = Undefined Then
			
			FilterElement = DCS.DefaultSettings.Filter.Items.Add(Type(Element));
			
		Else
			
			FilterElement = Parent.Items.Add(Type(Element));
			
		EndIf;
		
		FillPropertyValues(FilterElement, Element);
		
		If TypeOf(Element) = Type("DataCompositionFilterItemGroup") Then
			
			FillDataCompositionSchemeFilters(DCS, Element.Items, FilterElement);
			
		EndIf;
		
	EndDo;
	
EndProcedure
#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
	SKUGroupsOnChange(Items.SKUGroups);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	SKUGroupsOnChange(Items.SKUGroups);
	
EndProcedure

&AtClient
Procedure OutletsOutletOnChange(Item)
    
    RequestMap = New Map;
    RequestMap.Insert("pName", "Outlet");
    RequestMap.Insert("checkingItem", Items.Outlets.CurrentData);
    RequestMap.Insert("tabularSection", Object.Outlets);
    
    ClientProcessors.UniqueRows(RequestMap);

EndProcedure

&AtClient
Procedure StocksStockOnChange(Item)
	
	RequestMap = New Map;
    RequestMap.Insert("pName", "Stock");
    RequestMap.Insert("checkingItem", Items.Stocks.CurrentData);
    RequestMap.Insert("tabularSection", Object.Stocks);
    
    ClientProcessors.UniqueRows(RequestMap);
	
EndProcedure

&AtClient
Procedure SKUGroupsSKUGroupChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If ValueIsFilled(SelectedValue) Then 
		
		If ItsFolder(SelectedValue) Then 
			
			StandardProcessing = False;
			
		EndIf;	
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure SKUGroupsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If Not CancelEdit Then 
		
		If Not ValueIsFilled(Items.SKUGroups.CurrentData.SKUGroup) Then 
			
			Message(NStr("en='Value is not selected';ru='Значение не выбрано';cz='Nebyla zvolena žádná hodnota'"));
			
			Cancel = True;
			
		EndIf;
				
	EndIf;
	
EndProcedure

&AtClient
Procedure SKUGroupsBeforeEditEnd1(Item, NewRow, CancelEdit, Cancel)
	
	If Not CancelEdit Then 
		
		If Not ValueIsFilled(Items.SKUGroups1.CurrentData.SKUGroup) Then 
			
			Message(NStr("en='Value is not selected';ru='Значение не выбрано';cz='Nebyla zvolena žádná hodnota'"));
			
			Cancel = True;
			
		EndIf;
				
	EndIf;
	
EndProcedure


&AtClient
Procedure SKUGroupsOnChange(Item)
	
	Ind = 0;
	
	For Each ItemElement In SKUGroups Do 
		
		Ind = Ind + 1;
		
		ItemElement.LineNumber = Ind;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(CurrentObject.Ref) Then
	
		If Not CurrentObject.Owner =ThisForm.Object.Ref.Owner Then
		
			Query = New Query(
			"SELECT
			|	DistributorTerritories.Ref
			|FROM
			|	Catalog.Distributor.Territories AS DistributorTerritories
			|WHERE
			|	DistributorTerritories.Territory = &Territory
			|
			|UNION ALL
			|
			|SELECT
			|	ContractorsTerritories.Ref
			|FROM
			|	Catalog.Contractors.Territories AS ContractorsTerritories
			|WHERE
			|	ContractorsTerritories.Territory = &Territory");
			
			Query.SetParameter("Territory", CurrentObject.Ref);
			Result = Query.Execute().Unload();
			Cancel = Result.Count();
			
			If Cancel Then
				
				Message(NStr("en = 'You cannot change region of territory that has link with partner or contractor'; ru = 'Нельзя изменять регион территории к которой привязаны партнеры или контрагенты.'"));
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ToogleOutletsSelect(Command)
	
	IsSelectHidden = Items.GroupOutletsPages.CurrentPage = Items.GroupOutletsNoSelect;
	
	CurrentFormTable = ?(IsSelectHidden, "Outlets", "Outlets1");
	NextFormTable = ?(IsSelectHidden, "Outlets1", "Outlets");
	
	Items[NextFormTable].CurrentRow = Items[CurrentFormTable].CurrentRow;
	
	Items.GroupOutletsPages.CurrentPage = ?(IsSelectHidden, Items.GroupOutletsWithSelect, Items.GroupOutletsNoSelect);
	
	ThisForm.CurrentItem = Items[NextFormTable];
	
EndProcedure

&AtClient
Procedure AddOutletFromSelect(Command)
	
	AddToOutletsVT(ThisForm.Items.OutletsSelect2.SelectedRows);
	
EndProcedure

&AtClient
Procedure AddToOutletsVT(OutletsArray)
	
	For Each Outlet In OutletsArray Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Outlet", Outlet);
		
		If ThisForm.Object.Outlets.FindRows(FilterParameters).Count() = 0 Then
			
			NewOutletRow = ThisForm.Object.Outlets.Add();
			NewOutletRow.Outlet = Outlet;
			
			Modified = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure AddAllOutletsFromSelect(Command)
	
	OutletsArray = GetOutletsArrayFromDynamicList();
	
	AddToOutletsVT(OutletsArray);
	
EndProcedure

&AtClient
Procedure RemoveAllOutlets(Command)
	
	CurrentItem = ?(Items.GroupOutletsPages.CurrentPage = Items.GroupOutletsNoSelect, Items.Outlets, Items.Outlets1);
	
	Rows = ThisForm.Object.Outlets.FindRows(New Structure(CurrentItem.RowFilter));
	
	For Each Row In Rows Do
		
		Index = ThisForm.Object.Outlets.IndexOf(Row);
		ThisForm.Object.Outlets.Delete(Index);
		
		Modified = True;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RemoveOutlet(Command)
	
	CurrentItem = ?(Items.GroupOutletsPages.CurrentPage = Items.GroupOutletsNoSelect, Items.Outlets, Items.Outlets1);
	
	If Not CurrentItem.CurrentData = Undefined Then
		
		
		Index = ThisForm.Object.Outlets.IndexOf(CurrentItem.CurrentData);
		ThisForm.Object.Outlets.Delete(Index);
		
		Modified = True;
		
		
	EndIf;
	
EndProcedure


&AtClient
Procedure OutletsSelect2Selection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not Item.CurrentData = Undefined Then
	
		CurrentOutlet = Item.CurrentData.Outlet;
		
		OutletsArray = New Array;
		OutletsArray.Add(CurrentOutlet);
		
		AddToOutletsVT(OutletsArray);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ToogleSkuGroupSelect(Command)
		
	IsSelectHidden = Items.GroupSkuGroup.CurrentPage = Items.GroupSkuWithNoSelect;
	
	CurrentFormTable = ?(IsSelectHidden, "SKUGroups", "SKUGroups1");
	NextFormTable = ?(IsSelectHidden, "SKUGroups1", "SKUGroups");
	
	Items[NextFormTable].CurrentRow = Items[CurrentFormTable].CurrentRow;
	
	Items.GroupSkuGroup.CurrentPage = ?(IsSelectHidden, Items.GroupSkuWithSelect, Items.GroupSkuWithNoSelect);
	
	ThisForm.CurrentItem = Items[NextFormTable];
	

EndProcedure

&AtClient
Procedure AddSkusFromSelect(Command)
	
	AddToSkusVT(ThisForm.Items.SkusSelect.SelectedRows);

EndProcedure

&AtServer
Function GetArraySkusGroupFromFolder(SKU)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SKUGroup.Ref AS Ref
		|FROM
		|	Catalog.SKUGroup AS SKUGroup
		|WHERE
		|	SKUGroup.Parent IN HIERARCHY(&Parent)
		|	AND SKUGroup.IsFolder = FALSE";
	
	Query.SetParameter("Parent", SKU);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Unload().UnloadColumn("Ref");
	
	Return SelectionDetailRecords;
	
EndFunction

&AtClient
Procedure AddToSkusVT(SkusArray)
	
	For Each SKU In SkusArray Do		
		
		If ItsFolder(SKU) Then 
			ArrayInFolder = GetArraySkusGroupFromFolder(SKU);
			For Each ElInFolder In ArrayInFolder Do
				FilterParameters = New Structure;
				FilterParameters.Insert("SKUGroup", ElInFolder);
				
				If SKUGroups.FindRows(FilterParameters).Count() = 0 Then			
					Ind = 1;	
						For Each ItemElement In SKUGroups Do 		
							Ind = Ind + 1;
						EndDo;
					NewSKUGroupsRow = SKUGroups.Add();
					NewSKUGroupsRow.SKUGroup = ElInFolder;
					NewSKUGroupsRow.LineNumber = Ind;
					Modified = True;			
				EndIf;
				
			EndDo;
		Else
			FilterParameters = New Structure;
			FilterParameters.Insert("SKUGroup", SKU);	
			If SKUGroups.FindRows(FilterParameters).Count() = 0 Then			
			Ind = 1;	
			For Each ItemElement In SKUGroups Do 		
				Ind = Ind + 1;
			EndDo;
			NewSKUGroupsRow = SKUGroups.Add();
			NewSKUGroupsRow.SKUGroup = SKU;
			NewSKUGroupsRow.LineNumber = Ind;
			Modified = True;
			
		EndIf;
	
		EndIf;
				
	EndDo;
	
EndProcedure

&AtClient
Procedure AddAllSkusGroupFromSelect(Command)
		
	SkusGroupArray = GetSkusGroupArrayFromDynamicList();
	
	AddToSkusVT(SkusGroupArray);
	

EndProcedure


&AtServer
Function GetSkusGroupArrayFromDynamicList()
	
	DCS = New DataCompositionSchema;
	
	DataSource = DCS.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "Local";
	DataSource.ConnectionString = "";
	
	DataSet = DCS.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSet1";
	
	DataSet.Query = SkusSelect.QueryText;
	DataSet.DataSource = "DataSource1";
	DataSet.AutoFillAvailableFields = True;
	
	DCG = DCS.DefaultSettings.Structure.Add(Type("DataCompositionGroup"));
	DCG.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	DCG.Use = True;
	
	FieldsArray = New Array;
	FieldsArray.Add("SkuGroup");
	
	For Each FieldName In FieldsArray Do
		
		NewField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = FieldName;
		NewField.DataPath = FieldName;
		NewField.Title = FieldName;
		
		ChoiceField = DCS.DefaultSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		ChoiceField.Field = New DataCompositionField(FieldName);
		ChoiceField.Use = True;
		
	EndDo;
	
	FillDataCompositionSchemeFilters(DCS, SkusSelect.Filter.Items);
	
	DCTC = New DataCompositionTemplateComposer;
	Template = DCTC.Execute(DCS, 
							DCS.DefaultSettings,
							,
							,
							Type("DataCompositionValueCollectionTemplateGenerator"));
	
	
	DCP = New DataCompositionProcessor;
	DCP.Initialize(Template);
	
	SkusGroupVT = New ValueTable;
	
	DCRVCOP = New DataCompositionResultValueCollectionOutputProcessor;
	DCRVCOP.SetObject(SkusGroupVT);
	DCRVCOP.Output(DCP);
	
	Return SkusGroupVT.UnloadColumn("SkuGroup");
	
EndFunction

&AtClient
Procedure RemoveSkuGroup(Command)
		
	CurrentItem = ?(Items.GroupSkuGroup.CurrentPage = Items.GroupSkuWithNoSelect, Items.SKUGroups, Items.SKUGroups1);
	
	If Not CurrentItem.CurrentData = Undefined Then
		
		
		Index = SKUGroups.IndexOf(CurrentItem.CurrentData);
		SKUGroups.Delete(Index);
		
		Modified = True;
		
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RemoveAllSkuGroup(Command)
		
	CurrentItem = ?(Items.GroupSkuGroup.CurrentPage = Items.GroupSkuWithNoSelect, Items.SKUGroups, Items.SKUGroups1);
	
	Rows = SKUGroups.FindRows(New Structure(CurrentItem.RowFilter));
	
	For Each Row In Rows Do
		
		Index = SKUGroups.IndexOf(Row);
		SKUGroups.Delete(Index);
		
		Modified = True;
		
	EndDo;
	

EndProcedure

&AtClient
Procedure SkusSelectSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not Item.CurrentData = Undefined Then
	
		SkuGroup = Item.CurrentData.SkuGroup;
		
		SkusArray = New Array;
		SkusArray.Add(SkuGroup);
		
		AddToSkusVT(SkusArray);
	
	EndIf;
	
EndProcedure

#EndRegion


