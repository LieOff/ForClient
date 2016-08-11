
&AtClient
Var OldTerritories;

#Region CommonProceduresAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillRegions();
	
	FillTerritories();
	
	HandleContactsAdditionalAccessRights();
	
	SetConditionalAppearence();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(CurrentObject.Ref) Then
	
		Query = New Query(
		"SELECT
		|	ObjectTerritories.Territory
		|INTO ObjectTerritories
		|FROM
		|	&ObjectTerritories AS ObjectTerritories
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TerritoryOutlets.Ref AS Territory,
		|	OutletCatalog.Ref AS Outlet
		|INTO OutletTerritories
		|FROM
		|	Catalog.Territory.Outlets AS TerritoryOutlets
		|		LEFT JOIN Catalog.Outlet AS OutletCatalog
		|		ON TerritoryOutlets.Outlet = OutletCatalog.Ref
		|WHERE
		|	OutletCatalog.Distributor = &Distributor
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OutletTerritories.Outlet,
		|	COUNT(DISTINCT OutletTerritories.Territory) AS OutletTerritory,
		|	COUNT(DISTINCT ObjectTerritories.Territory) AS PartnerTerritory
		|FROM
		|	OutletTerritories AS OutletTerritories
		|		LEFT JOIN ObjectTerritories AS ObjectTerritories
		|		ON OutletTerritories.Territory = ObjectTerritories.Territory
		|
		|GROUP BY
		|	OutletTerritories.Outlet
		|
		|HAVING
		|	COUNT(ObjectTerritories.Territory) = 0");
		
		Query.SetParameter("ObjectTerritories", CurrentObject.Territories.Unload());
		Query.SetParameter("Distributor", CurrentObject.Ref);
		Result = Query.Execute().Unload();
		
		Cancel = Result.Count() > 0;
		
		If Cancel Then
			
			Message(NStr("ru = 'Нельзя записывать партнера пока есть хотя бы одна торговая точка в которой присутствует этот партнер и список территорий этой торговой точки не соответствует ни одной территории из нового списка территорий этого партнера.'"));
			
		EndIf;
		
	EndIf;
	
EndProcedure


#Region Contractors

&AtServer
Function GetFilters()
	
	FiltersArray = New Array;
	
	FiltersArray.Add(GetFilter("Ref.Regions.Region", GetRegions()));
	FiltersArray.Add(GetFilter("Ref.Territories.Territory", GetTerritories()));
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
	
	Query.SetParameter("FormContractors", ThisForm.Object.Contractors.Unload(, "Contractor"));
	Result = Query.Execute().Unload();
	
	AvailableContractors = New Array;
	
	For Each Row In Result Do
		
		AvailableContractors.Add(Row.Contractor);
		
	EndDo;
	
	Return AvailableContractors;
	
EndFunction

&AtServer
Function GetNewContractorsList()
	
	Query = New Query(
	"SELECT ALLOWED DISTINCT
	|	FormContractors.Contractor,
	|	FormContractors.Default
	|INTO FormContractors
	|FROM
	|	&FormContractors AS FormContractors
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContractorsTerritories.Ref AS Contractor,
	|	FormContractors.Default
	|FROM
	|	FormContractors AS FormContractors
	|		LEFT JOIN Catalog.Contractors.Territories AS ContractorsTerritories
	|		ON FormContractors.Contractor = ContractorsTerritories.Ref
	|WHERE
	|	ContractorsTerritories.Ref IN (FormContractors.Contractor)
	|	AND ContractorsTerritories.Territory IN(&Territories)");
	Query.SetParameter("FormContractors", ThisForm.Object.Contractors.Unload());
	Query.SetParameter("Territories", GetTerritoriesArray());
	Result = Query.Execute().Unload();
	
	Contractors = New Array;
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

&AtServer
Function GetTerritoriesArray()
	
	TerritoriesArray = New Array;
	
	For Each Row In ThisForm.Object.Territories Do
		
		TerritoriesArray.Add(Row.Territory);
		
	EndDo;
	
	Return TerritoriesArray;
	
EndFunction

#EndRegion

#Region ContactList

&AtServer
Procedure HandleContactsAdditionalAccessRights()
	
	CurrentUser = SessionParameters.CurrentUser;
	EditContactsAccessRight = Catalogs.AdditionalAccessRights.EditPartnerContacts;
	IsAdmin = Not ValueIsFilled(CurrentUser.RoleOfUser);
	HasRightToEditContacts = Not CurrentUser.RoleOfUser.AdditionalAccessRights.Find(EditContactsAccessRight) = Undefined;
	EnableContactEdit = IsAdmin OR HasRightToEditContacts;
	Items.ContactListAddContact.Enabled = EnableContactEdit;
	Items.ContactListDeleteContact.Enabled = EnableContactEdit;
	Items.ContactListNotActual.ReadOnly = Not EnableContactEdit;
	
EndProcedure

#EndRegion

#Region Regions

&AtServer
Procedure FillRegions()
	
	Query = New Query(
	"SELECT ALLOWED
	|	DistributorRegions.Region
	|INTO SavedRegions
	|FROM
	|	Catalog.Distributor.Regions AS DistributorRegions
	|WHERE
	|	DistributorRegions.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	RegionCatalog.Ref AS Region,
	|	CASE
	|		WHEN SavedRegions.Region IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS USE
	|FROM
	|	Catalog.Region AS RegionCatalog
	|		LEFT JOIN SavedRegions AS SavedRegions
	|		ON RegionCatalog.Ref = SavedRegions.Region
	|
	|ORDER BY
	|	Region HIERARCHY
	|AUTOORDER");
	Query.SetParameter("Ref", ThisForm.Object.Ref);
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	ValueToFormAttribute(Result, "Regions");
	
EndProcedure

#EndRegion

#Region Territories

&AtServer
Procedure FillTerritories()
	
	Query = New Query(
	"SELECT ALLOWED
	|	DistributorTerritories.Territory
	|INTO SavedTerritories
	|FROM
	|	Catalog.Distributor.Territories AS DistributorTerritories
	|WHERE
	|	DistributorTerritories.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TerritoryCatalog.Owner AS Region,
	|	TerritoryCatalog.Ref AS Territory,
	|	CASE
	|		WHEN SavedTerritories.Territory IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Use
	|FROM
	|	Catalog.Territory AS TerritoryCatalog
	|		LEFT JOIN SavedTerritories AS SavedTerritories
	|		ON TerritoryCatalog.Ref = SavedTerritories.Territory
	|
	|ORDER BY
	|	Region
	|AUTOORDER");
	
	Query.SetParameter("Ref", ThisForm.Object.Ref);
	
	Result = Query.Execute().Unload();
	
	ThisForm.Territories.Load(Result);
	
EndProcedure

#EndRegion

&AtServer
Procedure SetConditionalAppearence()
	
	// Green color for territories with current selected region
	CA = ThisForm.ConditionalAppearance;
	CAItem = CA.Items.Add();
	
	Field = CAItem.Fields.Items.Add();
	Field.Field = New DataCompositionField("TerritoriesRegion");
	Field.Use = True;
	
	Field = CAItem.Fields.Items.Add();
	Field.Field = New DataCompositionField("TerritoriesTerritory");
	Field.Use = True;
	
	Field = CAItem.Fields.Items.Add();
	Field.Field = New DataCompositionField("TerritoriesUse");
	Field.Use = True;
	
	RegionsFilterItem = CAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	RegionsFilterItem.LeftValue = New DataCompositionField("Territories.Region");
	RegionsFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	RegionsFilterItem.RightValue = New DataCompositionField("CurrentRegion");
	
	CAItem.Appearance.SetParameterValue("BackColor", WebColors.PaleGreen);
	
	// Block use of territories that are not in current selected region
	CAItem = CA.Items.Add();
	
	Field = CAItem.Fields.Items.Add();
	Field.Field = New DataCompositionField("TerritoriesUse");
	Field.Use = True;
	
	RegionsFilterItem = CAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	RegionsFilterItem.LeftValue = New DataCompositionField("Territories.Region");
	RegionsFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	RegionsFilterItem.RightValue = New DataCompositionField("CurrentRegion");
	
	CAItem.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Update" Then
		
		ThisForm.Items.ContactList.Refresh();
		
	EndIf;
	
EndProcedure

#Region Contractors

&AtClient
Procedure ContractorsDefaultOnChange(Item)
	
	CurrentData = Items.Contractors.CurrentData;
	IsNotDefaultAfterChange = CurrentData.Default;
	ThisRowIndex = ThisForm.Object.Contractors.IndexOf(CurrentData);
	ThisRow = ThisForm.Object.Contractors.Get(ThisRowIndex);
	
	If IsNotDefaultAfterChange Then
		
		For Each Row In ThisForm.Object.Contractors Do
			
			Row.Default = ThisForm.Object.Contractors.IndexOf(Row) = ThisRowIndex;
			
		EndDo;
		
	Else
		
		ThisRow.Default = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractorsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	FilterParameters = New Structure("Contractor", SelectedValue);
	ContractorExists = ThisForm.Object.Contractors.FindRows(FilterParameters).Count();
	
	If NOT ContractorExists Then
		
		FirstItem = ThisForm.Object.Contractors.Count() = 0;
		NewContractorRow = ThisForm.Object.Contractors.Add();
		NewContractorRow.Contractor = SelectedValue;
		NewContractorRow.Default = FirstItem;
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ContactList

&AtClient
Procedure ContactListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentData = Items.ContactList.CurrentData;
	
	If NOT CurrentData = Undefined Then
		
		OpenForm("Catalog.ContactPersons.ObjectForm", New Structure("Key", CurrentData.Contact), ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactListChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	FilterParameters = New Structure("Contact", SelectedValue);
	ContactExists = ThisForm.Object.Contacts.FindRows(FilterParameters).Count();
	
	If Not ContactExists Then
		
		NewContactRow = ThisForm.Object.Contacts.Add();
		NewContactRow.Contact = SelectedValue;
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Regions

&AtClient
Procedure RegionsBeforeCollapse(Item, Row, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure RegionsOnActivateRow(Item)
	
	CurrentData = ThisForm.Items.Regions.CurrentData;
	
	CurrentRegion = ?(CurrentData = Undefined, Undefined, CurrentData.Region);
	
	Filter = New FixedStructure("Region", CurrentRegion);
	ThisForm.Items.Territories.RowFilter = ?(ThisForm.Items.ShowAllTerritories.Check, Undefined, Filter);
	
	ThisForm.CurrentRegion = CurrentRegion;
	
	ThisForm.Items.Territories.Refresh();
	
EndProcedure

&AtClient
Procedure RegionsUseOnChange(Item)
	
	CurrentData = ThisForm.Items.Regions.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		If Not CurrentData.Use Then
			
			Filter = New Structure;
			Filter.Insert("Region", CurrentData.Region);
			
			OldTerritories = New Array;
			For Each TerritoryRow In ThisForm.Object.Territories Do
				
				OldTerritories.Add(TerritoryRow.Territory);
				
			EndDo;
			
			TerritoriesRows = ThisForm.Territories.FindRows(Filter);
			
			For Each Row In TerritoriesRows Do
				
				Row.Use = False;
				Filter = New Structure("Territory", Row.Territory);
				TerritoryRows = ThisForm.Object.Territories.FindRows(Filter);
				For Each TerritoryRow In TerritoryRows Do
					
					ThisForm.Object.Territories.Delete(TerritoryRow);
					
				EndDo;
				
			EndDo;
			
			Filter = New Structure("Region", CurrentData.Region);
			RowsToDelete = ThisForm.Object.Regions.FindRows(Filter);
			For Each Row In RowsToDelete Do
				
				ThisForm.Object.Regions.Delete(Row);
				
			EndDo;
			
			ProcessTerritoriesChange("Regions");
			
		Else
			
			NewRow = ThisForm.Object.Regions.Add();
			NewRow.Region = CurrentData.Region;
			
		EndIf;
		
	EndIf;
	
	ThisForm.RefreshDataRepresentation();
	
EndProcedure

#EndRegion

#Region Territories

&AtClient
Procedure CheckTerritories(Value)
	
	CurrentData = ThisForm.Items.Regions.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		If CurrentData.Use Then
		
			Filter = New Structure;
			Filter.Insert("Region", CurrentData.Region);
			
			Rows = ThisForm.Territories.FindRows(Filter);
			
			For Each Row In Rows Do
				
				Row.Use = Value;
				Modified = True;
				
				Filter = New Structure("Territory", Row.Territory);
				
				If Value = True Then
				
					If ThisForm.Object.Territories.FindRows(Filter).Count() = 0 Then
						
						NewRow = ThisForm.Object.Territories.Add();
						NewRow.Territory = Row.Territory;
						
					EndIf;
					
				Else
					
					RowsToDelete = ThisForm.Object.Territories.FindRows(Filter);
					
					For Each RowToDelete In RowsToDelete Do
						
						ThisForm.Object.Territories.Delete(RowToDelete);
						
					EndDo;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TerritoriesUseOnChange(Item)
	
	CurrentData = ThisForm.Items.Territories.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		If CurrentData.Use Then
			
			NewRow = ThisForm.Object.Territories.Add();
			NewRow.Territory = CurrentData.Territory;
			
		Else
			
			Filter = New Structure("Territory", CurrentData.Territory);
			RowsToDelete = ThisForm.Object.Territories.FindRows(Filter);
			
			For Each Row In RowsToDelete Do
				
				ThisForm.Object.Territories.Delete(Row);
				
			EndDo;
			
			ProcessTerritoriesChange();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessTerritoriesChange(Regions = Undefined)
	
	NewContractors = GetNewContractorsList();
	
	If Not Regions = Undefined Then
		
		NewContractors.Insert("Regions", True);
		
	EndIf;
	
	If NewContractors.Contractors.Count() < ThisForm.Object.Contractors.Count() Then
		
		ShowQueryBox(New NotifyDescription("ProcessContractorsOnTerritoriesChange", ThisForm, NewContractors),
					 NStr("en = 'Contractors list will be changed. Continue?'; ru = 'Список контрагентов будет изменен. Продолжить?'"),
					 QuestionDialogMode.YesNo,
					 ,
					 ,
					 NStr("en = 'Continue?'; ru = 'Продолжить?'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessContractorsOnTerritoriesChange(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		Contractors = Parameters.Contractors;
		HasDefault = Parameters.HasDefault;
		Default = Parameters.Default;
		
		ThisForm.Object.Contractors.Clear();
		
		If Contractors.Count() > 0 Then
			
			For Each Contractor In Contractors Do
				
				NewRow = ThisForm.Object.Contractors.Add();
				NewRow.Contractor = Contractor;
				
			EndDo;
			
			DefaultRowIndex = ?(HasDefault, Default, 0);
			ThisForm.Object.Contractors[DefaultRowIndex].Default = True;
			
		EndIf;
			
	Else
		
		If Parameters.Property("Regions") Then
			
			ThisForm.Object.Territories.Clear();
			
			For Each Territory In OldTerritories Do
				
				NewTerritoryRow = ThisForm.Object.Territories.Add();
				NewTerritoryRow.Territory = Territory;
				
			EndDo;
			
			FillTerritories();
			
			ThisForm.Items.Regions.CurrentData.Use = True;
			RegionsRow = ThisForm.Object.Regions.Add();
			RegionsRow.Region = ThisForm.Items.Regions.CurrentData.Region;
			
		Else
			
			ThisForm.Items.Territories.CurrentData.Use = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Commands

&AtClient
Procedure AddContractor(Command)
	
	ChoiceForm = GetForm("Catalog.Contractors.ChoiceForm", , Items.Contractors);
	Filter = ChoiceForm.List.Filter;
	
	FilterItems = GetFilters();
	
	For Each FilterItem In FilterItems Do
		
		NewRow = Filter.Items.Add(Type("DataCompositionFilterItem"));
		FillPropertyValues(NewRow, FilterItem);
		
	EndDo;
	
	ChoiceForm.CloseOnChoice = False;
	
	OpenForm(ChoiceForm);
	
EndProcedure

&AtServer
Function GetTerritories()
	
	TerritoriesVT = ThisForm.Object.Territories.Unload(, "Territory");
	TerritoriesArray = New Array;
	
	For Each Row In TerritoriesVT Do
		
		TerritoriesArray.Add(Row.Territory);
		
	EndDo;
	
	Return TerritoriesArray;
	
EndFunction

&AtServer
Function GetRegions()
	
	RegionsVT = ThisForm.Object.Regions.Unload(, "Region");
	RegionsArray = New Array;
	
	For Each Row In RegionsVT Do
		
		RegionsArray.Add(Row.Region);
		
	EndDo;
	
	Return RegionsArray;
	
EndFunction

&AtClient
Procedure RemoveContractor(Command)
	
	CurrentData = Items.Contractors.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		CurrentDataIndex = ThisForm.Object.Contractors.IndexOf(CurrentData);
		ThisForm.Object.Contractors.Delete(CurrentDataIndex);
		Modified = True;
		
	EndIf;
	
	If ThisForm.Object.Contractors.Count() Then
		
		FilterParameters = New Structure("Default", True);
		NoDefault = NOT ThisForm.Object.Contractors.FindRows(FilterParameters).Count();
		
		If NoDefault Then
			
			ThisForm.Object.Contractors[0].Default = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddContact(Command)
	
	ChoiceForm = GetForm("Catalog.ContactPersons.ChoiceForm", , Items.ContactList);
	
	ChoiceForm.CloseOnChoice = False;
	
	OpenForm(ChoiceForm);
	
EndProcedure

&AtClient
Procedure DeleteContact(Command)
	
	CurrentData = Items.ContactList.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		CurrentDataIndex = ThisForm.Object.Contacts.IndexOf(CurrentData);
		ThisForm.Object.Contacts.Delete(CurrentDataIndex);
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckAllTerritories(Command)
	
	CheckTerritories(True);
	
EndProcedure

&AtClient
Procedure UncheckAllTerritories(Command)
	
	CheckTerritories(False);
	
EndProcedure

&AtClient
Procedure ShowAllTerritories(Command)
	
	ThisForm.Items.ShowAllTerritories.Check = Not ThisForm.Items.ShowAllTerritories.Check;
	ShowAll = ThisForm.Items.ShowAllTerritories.Check;
	CurrentData = ThisForm.Items.Regions.CurrentData;
	RegionSelected = Not CurrentData = Undefined;
	ThisForm.Items.Territories.RowFilter = ?(ShowAll AND RegionSelected, Undefined, New FixedStructure("Region", ThisForm.Items.Regions.CurrentData.Region));
	
	CurrentData = ThisForm.Items.Regions.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		CurrentRegion = CurrentData.Region;
		
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

#EndRegion