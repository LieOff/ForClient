&AtClient
Var OldBeginDate;

&AtClient
Var OldEndDate;

#Region CommonProceduresAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Если создается новый элемент справочника
	If Not ValueIsFilled(Object.Ref) Then
		
		// Статус нового элемента - неактивен
		Object.Status = Enums.AssortmentMatrixStatus.Inactive;
		
		// Ответственный за новый элемент - текущий пользователь
		UserID = InfoBaseUsers.CurrentUser().UUID;
		
		CurrentUserElement = Catalogs.User.FindByAttribute("UserID", UserID);
		
		If ValueIsFilled(CurrentUserElement) Then
		
			Object.Responsible = CurrentUserElement;
			
		EndIf;
		
	// Если открывается существующий элемент справочника
	Else
		
		FillOutlets();
		
		FillSKUs();
		
	EndIf;
	
	ChangeOutletsSelectQuery();
	
	FillOutletsSelectFilters();
	
EndProcedure

Function CheckUnit(CurrentObject)
	
FormSKUs = ThisForm.SKUs.Unload();
	
	For Each Elem In FormSKUs Do 
		
		If Elem.Unit = Catalogs.UnitsOfMeasure.EmptyRef() Then 
			Message(NStr("ru='Заполните единицу измерения';en='Fill unit'"));
			Return True;
		EndIf;
		
	EndDo;
	Return False;	
EndFunction
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Cancel = CheckUnit(CurrentObject);
	
	WriteOutlets(CurrentObject);
	
	WriteSKUs(CurrentObject);
	
EndProcedure

#Region Outlets

&AtServer
Procedure FillOutlets()
	
	Query = New Query(
	"SELECT ALLOWED
	|	AssortmentMatrixOutletsSliceLast.Outlet,
	|	AssortmentMatrixOutletsSliceLast.UUID
	|FROM
	|	InformationRegister.AssortmentMatrixOutlets.SliceLast(, AssortmentMatrix = &AssortmentMatrix) AS AssortmentMatrixOutletsSliceLast
	|WHERE
	|	AssortmentMatrixOutletsSliceLast.OutletStatus = VALUE(Enum.ValueTableRowStatuses.Added)");
	
	Query.SetParameter("AssortmentMatrix", Object.Ref);
	
	QueryResult = Query.Execute().Unload();
	
	UUIDColumn = QueryResult.UnloadColumn("UUID");
	
	For Counter = 0 To UUIDColumn.Count() - 1 Do
		
		UUIDColumn[Counter] = String(UUIDColumn[Counter]);
		
	EndDo;
	
	QueryResult.Columns.Delete(1);
	QueryResult.Columns.Add("UUID", New TypeDescription(,,,, New StringQualifiers(36, AllowedLength.Variable)));
	QueryResult.LoadColumn(UUIDColumn, "UUID");
	
	ValueToFormAttribute(QueryResult, "Outlets");
	
EndProcedure

&AtServer
Procedure WriteOutlets(CurrentObject)
	
	FormOutlets = ThisForm.Outlets.Unload();
	
	Query = New Query(
	"SELECT ALLOWED
	|	AssortmentMatrixOutletsSliceLast.Outlet,
	|	AssortmentMatrixOutletsSliceLast.UUID
	|FROM
	|	InformationRegister.AssortmentMatrixOutlets.SliceLast(, AssortmentMatrix = &AssortmentMatrix) AS AssortmentMatrixOutletsSliceLast
	|WHERE
	|	AssortmentMatrixOutletsSliceLast.OutletStatus = VALUE(Enum.ValueTableRowstatuses.Added)");
	Query.SetParameter("AssortmentMatrix", CurrentObject.Ref);
	RegisterOutlets = Query.Execute().Unload();
	
	UUIDColumn = RegisterOutlets.UnloadColumn("UUID");
	
	For Counter = 0 To UUIDColumn.Count() - 1 Do
		
		UUIDColumn[Counter] = String(UUIDColumn[Counter]);
		
	EndDo;
	
	RegisterOutlets.Columns.Delete(1);
	RegisterOutlets.Columns.Add("UUID", FormOutlets.Columns.Get(1).ValueType);
	RegisterOutlets.LoadColumn(UUIDColumn, "UUID");
	
	Query = New Query(
	"SELECT ALLOWED
	|	FormOutlets.Outlet,
	|	FormOutlets.UUID
	|INTO FormOutlets
	|FROM
	|	&FormOutlets AS FormOutlets
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	RegisterOutlets.Outlet,
	|	RegisterOutlets.UUID
	|INTO RegisterOutlets
	|FROM
	|	&RegisterOutlets AS RegisterOutlets
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	FormOutlets.Outlet AS FormOutlet,
	|	FormOutlets.UUID AS FormUUID,
	|	RegisterOutlets.Outlet AS RegisterOutlet,
	|	RegisterOutlets.UUID AS RegisterUUID
	|INTO Difference
	|FROM
	|	FormOutlets AS FormOutlets
	|		FULL JOIN RegisterOutlets AS RegisterOutlets
	|		ON FormOutlets.UUID = RegisterOutlets.UUID
	|			AND FormOutlets.Outlet = RegisterOutlets.Outlet
	|WHERE
	|	(FormOutlets.Outlet IS NULL 
	|				AND FormOutlets.UUID IS NULL 
	|			OR RegisterOutlets.Outlet IS NULL 
	|				AND RegisterOutlets.UUID IS NULL )
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	&CurrentDate AS Period,
	|	&AssortmentMatrix AS AssortmentMatrix,
	|	ISNULL(Difference.FormOutlet, Difference.RegisterOutlet) AS Outlet,
	|	ISNULL(Difference.FormUUID, Difference.RegisterUUID) AS UUID,
	|	CASE
	|		WHEN Difference.FormOutlet IS NULL 
	|				AND Difference.FormUUID IS NULL 
	|			THEN VALUE(Enum.ValueTableRowStatuses.Deleted)
	|		WHEN Difference.RegisterOutlet IS NULL 
	|				AND Difference.RegisterUUID IS NULL 
	|			THEN VALUE(Enum.ValueTableRowStatuses.Added)
	|	END AS OutletStatus
	|FROM
	|	Difference AS Difference");
	Query.SetParameter("CurrentDate", CurrentDate());
	Query.SetParameter("AssortmentMatrix", CurrentObject.Ref);
	Query.SetParameter("FormOutlets", ThisForm.Outlets.Unload());
	Query.SetParameter("RegisterOutlets", RegisterOutlets);
	
	QueryResult = Query.Execute().Unload();
	
	UUIDColumn = QueryResult.UnloadColumn(3);
	For Counter = 0 To UUIDColumn.Count() - 1 Do
		
		UUIDColumn[Counter] = New UUID(UUIDColumn[Counter]);
		
	EndDo;
	
	QueryResult.Columns.Delete(3);
	QueryResult.Columns.Insert(3, "UUID", New TypeDescription("UUID"));
	QueryResult.LoadColumn(UUIDColumn, 3);
	CurrentObject.AdditionalProperties.Insert("NewOutletsRows", QueryResult);
	
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

#Region SKUs

&AtServer
Procedure FillSKUs()
	
	Query = New Query(
	"SELECT ALLOWED
	|	AssortmentMatrixSKUsSliceLast.SKU,
	|	AssortmentMatrixSKUsSliceLast.Qty,
	|	AssortmentMatrixSKUsSliceLast.Unit,
	|	AssortmentMatrixSKUsSliceLast.UUID,
	|	AssortmentMatrixSKUsSliceLast.Qty * SKUPacking.Multiplier AS BaseUnitQty
	|FROM
	|	InformationRegister.AssortmentMatrixSKUs.SliceLast(, AssortmentMatrix = &AssortmentMatrix) AS AssortmentMatrixSKUsSliceLast
	|		LEFT JOIN Catalog.SKU.Packing AS SKUPacking
	|		ON AssortmentMatrixSKUsSliceLast.SKU = SKUPacking.Ref
	|			AND AssortmentMatrixSKUsSliceLast.Unit = SKUPacking.Pack
	|WHERE
	|	NOT AssortmentMatrixSKUsSliceLast.SKUStatus = VALUE(Enum.ValueTableRowStatuses.Deleted)");
	
	Query.SetParameter("AssortmentMatrix", Object.Ref);
	
	QueryResult = Query.Execute().Unload();
	
	UUIDColumn = QueryResult.UnloadColumn("UUID");
	
	For Counter = 0 To UUIDColumn.Count() - 1 Do
		
		UUIDColumn[Counter] = String(UUIDColumn[Counter]);
		
	EndDo;
	
	QueryResult.Columns.Delete(3);
	QueryResult.Columns.Add("UUID", New TypeDescription(,,,, New StringQualifiers(36, AllowedLength.Variable)));
	QueryResult.LoadColumn(UUIDColumn, "UUID");
	
	ValueToFormAttribute(QueryResult, "SKUs");
	
EndProcedure

&AtServer
Procedure WriteSKUs(CurrentObject)
	
	FormSKUs = ThisForm.SKUs.Unload();
	
	Query = New Query(
	"SELECT ALLOWED
	|	AssortmentMatrixSKUsSliceLast.SKU,
	|	AssortmentMatrixSKUsSliceLast.UUID,
	|	AssortmentMatrixSKUsSliceLast.Qty,
	|	AssortmentMatrixSKUsSliceLast.Unit,
	|	AssortmentMatrixSKUsSliceLast.BaseUnitQty
	|FROM
	|	InformationRegister.AssortmentMatrixSKUs.SliceLast(, AssortmentMatrix = &AssortmentMatrix) AS AssortmentMatrixSKUsSliceLast
	|WHERE
	|	NOT AssortmentMatrixSKUsSliceLast.SKUStatus = VALUE(Enum.ValueTableRowStatuses.Deleted)");
	
	Query.SetParameter("AssortmentMatrix", CurrentObject.Ref);
	
	RegisterSKUs = Query.Execute().Unload();
	
	UUIDColumn = RegisterSKUs.UnloadColumn("UUID");
	
	For Counter = 0 To UUIDColumn.Count() - 1 Do
		
		UUIDColumn[Counter] = String(UUIDColumn[Counter]);
		
	EndDo;
	
	RegisterSKUs.Columns.Delete(1);
	RegisterSKUs.Columns.Add("UUID", FormSKUs.Columns.Get(3).ValueType);
	RegisterSKUs.LoadColumn(UUIDColumn, "UUID");
	
	Query = New Query(
	"SELECT ALLOWED
	|	FormSKUs.SKU,
	|	FormSKUs.Qty,
	|	FormSKUs.Unit,
	|	FormSKUs.UUID,
	|	FormSKUs.BaseUnitQty
	|INTO FormSKUs
	|FROM
	|	&FormSKUs AS FormSKUs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	RegisterSKUs.SKU,
	|	RegisterSKUs.Qty,
	|	RegisterSKUs.Unit,
	|	RegisterSKUs.UUID,
	|	RegisterSKUs.BaseUnitQty
	|INTO RegisterSKUs
	|FROM
	|	&RegisterSKUs AS RegisterSKUs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	FormSKUs.SKU AS FormSKU,
	|	FormSKUs.Qty AS FormQty,
	|	FormSKUs.Unit AS FormUnit,
	|	FormSKUs.UUID AS FormUUID,
	|	FormSKUs.BaseUnitQty AS FormBaseUnitQty,
	|	RegisterSKUs.SKU AS RegisterSKU,
	|	RegisterSKUs.Qty AS RegisterQty,
	|	RegisterSKUs.Unit AS RegisterUnit,
	|	RegisterSKUs.UUID AS RegisterUUID,
	|	RegisterSKUs.BaseUnitQty AS RegisterBaseUnitQty
	|INTO Difference
	|FROM
	|	FormSKUs AS FormSKUs
	|		FULL JOIN RegisterSKUs AS RegisterSKUs
	|		ON FormSKUs.UUID = RegisterSKUs.UUID
	|			AND FormSKUs.SKU = RegisterSKUs.SKU
	|WHERE
	|	(FormSKUs.SKU IS NULL 
	|				AND FormSKUs.Qty IS NULL 
	|				AND FormSKUs.Unit IS NULL 
	|				AND FormSKUs.BaseUnitQty IS NULL 
	|			OR RegisterSKUs.SKU IS NULL 
	|				AND RegisterSKUs.Qty IS NULL 
	|				AND RegisterSKUs.Unit IS NULL 
	|				AND RegisterSKUs.BaseUnitQty IS NULL 
	|			OR NOT FormSKUs.Qty = RegisterSKUs.Qty
	|			OR NOT FormSKUs.Unit = RegisterSKUs.Unit
	|			OR NOT FormSKUs.BaseUnitQty = RegisterSKUs.BaseUnitQty)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	&CurrentDate AS Period,
	|	&AssortmentMatrix AS AssortmentMatrix,
	|	ISNULL(Difference.FormSKU, Difference.RegisterSKU) AS SKU,
	|	ISNULL(Difference.FormUUID, Difference.RegisterUUID) AS UUID,
	|	ISNULL(Difference.FormQty, Difference.RegisterQty) AS Qty,
	|	ISNULL(Difference.FormUnit, Difference.RegisterUnit) AS Unit,
	|	ISNULL(Difference.FormBaseUnitQty, Difference.RegisterBaseUnitQty) AS BaseUnitQty,
	|	CASE
	|		WHEN Difference.FormSKU IS NULL 
	|				AND Difference.FormQty IS NULL 
	|				AND Difference.FormUnit IS NULL 
	|				AND Difference.FormUUID IS NULL 
	|			THEN VALUE(Enum.ValueTableRowStatuses.Deleted)
	|		WHEN Difference.RegisterSKU IS NULL 
	|				AND Difference.RegisterQty IS NULL 
	|				AND Difference.RegisterUnit IS NULL 
	|				AND Difference.RegisterUUID IS NULL 
	|			THEN VALUE(Enum.ValueTableRowStatuses.Added)
	|		WHEN NOT Difference.FormQty = Difference.RegisterSKU
	|				OR NOT Difference.FormUnit = Difference.RegisterUnit
	|			THEN VALUE(Enum.ValueTableRowStatuses.Modified)
	|	END AS SKUStatus
	|FROM
	|	Difference AS Difference");
	
	Query.SetParameter("CurrentDate", CurrentDate());
	Query.SetParameter("FormSKUs", ThisForm.SKUs.Unload());
	Query.SetParameter("RegisterSKUs", RegisterSKUs);
	Query.SetParameter("AssortmentMatrix", Object.Ref);
	
	QueryResult = Query.Execute().Unload();
	
	UUIDColumn = QueryResult.UnloadColumn(3);
	For Counter = 0 To UUIDColumn.Count() - 1 Do
		
		UUIDColumn[Counter] = New UUID(UUIDColumn[Counter]);
		
	EndDo;
	
	QueryResult.Columns.Delete(3);
	QueryResult.Columns.Insert(3, "UUID", New TypeDescription("UUID"));
	QueryResult.LoadColumn(UUIDColumn, 3);
	CurrentObject.AdditionalProperties.Insert("NewSKUsRows", QueryResult);
	
EndProcedure

#EndRegion

&AtClientAtServerNoContext
Function NextDay(Date = Undefined)
	
	Date = ?(Date = Undefined, CurrentDate(), Date);
	Return EndOfDay(Date) + 1;
	
EndFunction

&AtClientAtServerNoContext
Function PrevDay(Date = Undefined)
	
	Date = ?(Date = Undefined, CurrentDate(), Date);
	Return BegOfDay(Date) - 1;
	
EndFunction

&AtServer
Function OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndFunction // ()

#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
	For Each Period In Object.Periods Do
		
		If Period.BeginDate <= BegOfDay(CurrentDate()) Then
			
			If Not ValueIsFilled(Period.EndDate) Or (Period.EndDate >= CurrentDate()) Then
				
				Items.Periods.CurrentRow = Period.GetID();
				
				SetFilter(Items.Periods);
				
			EndIf;
			
		EndIf;
			
	EndDo;
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	HavePeriods = CurrentPage = Items.GroupOutletsPage Or CurrentPage = Items.GroupSKUsPage;
	
	If HavePeriods Then
		
		IsOutletsPage = CurrentPage = Items.GroupOutletsPage;
		
		CurrentItem = ?(IsOutletsPage, Items.Periods, Items.Periods1);
		PreviousItem = ?(IsOutletsPage, Items.Periods1, Items.Periods);
		
		If Not PreviousItem.CurrentData = Undefined Then
			
			CurrentItem.CurrentRow = PreviousItem.CurrentData.GetID();
			
		EndIf;
		
		SetCurrentPeriod(CurrentItem);
		
	EndIf;
	
EndProcedure

#Region Periods

&AtClient
Procedure PeriodsOnStartEdit(Item, NewRow, Clone)
	
	CurrentData = Item.CurrentData;
	
	CurrentDataIndex = Object.Periods.IndexOf(CurrentData);
	
	PreviousData = GetPreviousData(CurrentDataIndex);
	
	If NewRow Then
		
		CurrentData.UUID = New UUID();
		
		If Not PreviousData = Undefined Then
			
			PreviousData.EndDate = ?(ValueIsFilled(PreviousData.EndDate), 
				PreviousData.EndDate, 
				Max(PreviousData.BeginDate, CurrentDate()));
				
			CurrentData.BeginDate = NextDay(PreviousData.EndDate);
			
			PreviousDataOutlets = Outlets.FindRows(New Structure("UUID", String(PreviousData.UUID)));
			
			For Each PreviousDataOutletsRow In PreviousDataOutlets Do
				
				CurrentDataOutletsRow = Outlets.Add();
				FillPropertyValues(CurrentDataOutletsRow, PreviousDataOutletsRow, , "UUID");
				CurrentDataOutletsRow.UUID = CurrentData.UUID;
				
			EndDo;
			
			PreviousDataSKUs = SKUs.FindRows(New Structure("UUID", String(PreviousData.UUID)));
			
			For Each PreviousDataSKUsRow In PreviousDataSKUs Do
				
				CurrentDataSKUsRow = SKUs.Add();
				FillPropertyValues(CurrentDataSKUsRow, PreviousDataSKUsRow, , "UUID");
				CurrentDataSKUsRow.UUID = CurrentData.UUID;
				
			EndDo;
			
			SetFilter(Item);
			
		Else
			
			CurrentData.BeginDate = NextDay();
			
		EndIf;
		
	EndIf;
	
	If Item.CurrentItem = Items.PeriodsBeginDate Then
		
		OldBeginDate = CurrentData.BeginDate;
		
	ElsIf Item.CurrentItem = Items.PeriodsEndDate Then
		
		OldEndDate = CurrentData.EndDate;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodsOnActivateRow(Item)
	
	SetFilter(Item);
	
	If Not Item.CurrentData = Undefined Then
		
		IsPastPeriod = ValueIsFilled(Item.CurrentData.EndDate) And Item.CurrentData.EndDate < BegOfDay(CurrentDate());
		
		Items.SKUsUnit.ReadOnly = IsPastPeriod;
		Items.SKUsQty.ReadOnly = IsPastPeriod;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodsBeforeDeleteRow(Item, Cancel)
	
	If Item.CurrentData.BeginDate < CurrentDate() Then 
		
		Cancel = True;
		
		UserMessage = New UserMessage;
		UserMessage.Text = NStr("en='Past and current periods deletion is not allowed';ru='Нельзя удалять прошедшие и текущий периоды.';cz='Past and current periods deletion is not allowed'");
		
		UserMessage.Message();
		
	Else
		
		Cancel = True;
		
		Params = New Structure;
		Params.Insert("Index", Object.Periods.IndexOf(Item.CurrentData));
		
		ShowQueryBox(New NotifyDescription("DeletePeriodProcessing", ThisForm, Params),
			NStr("en='All linked with this period data will be lost when this period will be deleted. Continue?';ru='При удалении периода все связанные с ним данные в данной ассоритментной матрице будут утеряны. Продолжить?';cz='All linked with this period data will be lost when this period will be deleted. Continue?'"),
			QuestionDialogMode.YesNo,
			0,
			DialogReturnCode.No,
			NStr("en='Delete period?';ru='Удалить период?';cz='Odstranit obdobн?'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodsBeginDateOnChange(Item)
	
	CurrentData = Item.Parent.CurrentData;
	
	CurrentDataIndex = Object.Periods.IndexOf(CurrentData);
	
	PreviousData = GetPreviousData(CurrentDataIndex);
	
	NextData = GetNextData(CurrentDataIndex);
	
	Buttons = New ValueList;
	Buttons.Add("OldValue", NStr("en='Old value';ru='Старое значение';cz='Old value'"));
	
	Params = New Structure;
	Params.Insert("FieldName", "BeginDate");
	Params.Insert("CurrentData", Object.Periods.FindByID(CurrentData.GetId()));
	Params.Insert("PreviousData", PreviousData);
	Params.Insert("OldValue", OldBeginDate);
	
	QueryText = "";
	
	If CurrentData.BeginDate < NextDay() Then
		
		Buttons.Add("Earliest", NStr("en='Earlist';ru='Самую раннюю возможную';cz='Nejbližší'"));
		
		If PreviousData = Undefined Then
			
			Params.Insert("Earliest", NextDay());
			
		Else
			
			Params.Insert("Earliest", Max(NextDay(), NextDay(PreviousData.BeginDate)));
			
		EndIf;
		
		QueryText = NStr("en='Current row begin date cannot be earlier than tomorrow.';ru='Начало периода текущей строки не может быть раньше чем завтра.';cz='Current row begin date cannot be earlier than tomorrow.'");
	
	ElsIf Not PreviousData = Undefined Then
		
		If CurrentData.BeginDate <= PreviousData.BeginDate Then
			
			Buttons.Add("Earliest", NStr("en='Earlist';ru='Самую раннюю возможную';cz='Nejbližší'"));
			
			Params.Insert("Earliest", NextDay(PreviousData.BeginDate));
			
			QueryText = NStr("en='Current period begin date cannot be earlier or equal to previous row begin period.';ru='Начало периода текущей строки не может быть раньше или таким же как начало периода предыдущей строки.';cz='Začátek období na tomto řádku musí předcházet začátek období na předchozím řádku.'");
			
		ElsIf CurrentData.EndDate < CurrentData.BeginDate Then
			
			//Buttons.Add("Latest", NStr("en='Latest';ru='Самую позднюю возможную';cz='Latest'"));
			//Buttons.Add("Earliest", NStr("en = 'Earliest'; ru = 'Самую раннюю возможную'"));
			//
			//Params.Insert("Latest", CurrentData.EndDate);
			//Params.Insert("Earliest", NextDay(PreviousData.EndDate));
			
			QueryText = "ReturnPrevDate";
			
		//ElsIf PreviousData.EndDate >= CurrentData.BeginDate Then
		//	
		//	Buttons.Add("Earliest", NStr("en='Earlist';ru='Самую раннюю возможную';cz='Nejbližší'"));
		//	
		//	Params.Insert("Earliest", NextDay(PreviousData.EndDate));
		//	
		//	QueryText = NStr("en = 'Current row begin date cannot be earlier than previous row end date'; 
		//		|ru = 'Начало периода текущей строки не может быть раньше чем конец периода предыдущей строки.'");
		//	
		EndIf;
	
	ElsIf Not NextData = Undefined Then
		
		If CurrentData.BeginDate >= NextData.BeginDate Then
			
			Buttons.Add("Latest", NStr("en='Latest';ru='Самую позднюю возможную';cz='Latest'"));
			
			Params.Insert("Latest", CurrentData.EndDate);
			
			QueryText = NStr("en='Current row begin period cannot be later than begin period of next row.';ru='Начало периода текущей строки не может быть позже чем начало периода следующей строки.';cz='Začátek období na tomto řádku musí předcházet začátek období na předchozím řádku.'");
			
		EndIf;
		
	ElsIf NextData = Undefined Then
		
		If ValueIsFilled(CurrentData.EndDate) AND CurrentData.EndDate < CurrentData.BeginDate Then
			
			Buttons.Add("Latest", NStr("en='Latest';ru='Самую позднюю возможную';cz='Latest'"));
			
			Params.Insert("Latest", CurrentData.EndDate);
			
			QueryText = NStr("en='Current row end period cannot be earlier than current period begin period';ru='Конец периода текущей строки не может быть раньше чем начало периода текущей строки';cz='Current row end period cannot be earlier than current period begin period'");
			
		EndIf;
		
	EndIf;
	
	If QueryText = "ReturnPrevDate" Then
		
		CurrentData.BeginDate = OldBeginDate;
		Message(NStr("en = 'Current period begin date can''t be later than current period end date.'; ru = 'Дата начала текущего периода не может быть позже чем дата конца текущего периода.'"));
		
	ElsIf Not QueryText = "" Then
		
		Question = NStr("en = ' What date set as current row begin period?'; ru = ' Какую дату установить началом периода?'");
		
		ShowQueryBox(New NotifyDescription("PeriodsIncorrectInputProcessing", ThisForm, Params),
			QueryText + Question,
			Buttons,
			0,
			,
			NStr("en='Incorrect begin date';ru='Неправильная дата начала';cz='Incorrect begin date'"));
		
	Else
		
		If Not PreviousData = Undefined Then
			
			If PreviousData.EndDate > CurrentDate() Then
				
				PreviousData.EndDate = PrevDay(CurrentData.BeginDate);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Item.Parent.EndEditRow(False);
	
EndProcedure

&AtClient
Procedure PeriodsEndDateOnChange(Item)
	
	CurrentData = Item.Parent.CurrentData;
	
	CurrentDataIndex = Object.Periods.IndexOf(CurrentData);
	
	NextData = GetNextData(CurrentDataIndex);
	
	Buttons = New ValueList;
	Buttons.Add("OldValue", NStr("en='Old value';ru='Старое значение';cz='Old value'"));
	
	Params = New Structure;
	Params.Insert("CurrentData", Object.Periods.FindByID(CurrentData.GetId()));
	Params.Insert("OldValue", OldEndDate);
	Params.Insert("FieldName", "EndDate");
	
	QueryText = "";
	
	If Not NextData = Undefined Then
		
		If CurrentData.EndDate = '00010101' Then
			
			Buttons.Add("Earliest", NStr("en='Earlist';ru='Самую раннюю возможную';cz='Nejbližší'"));
			Buttons.Add("Latest", NStr("en='Latest';ru='Самую позднюю возможную';cz='Latest'"));
			
			Params.Insert("Earliest", CurrentData.BeginDate);
			Params.Insert("Latest", PrevDay(NextData.BeginDate));
			
			QueryText = NStr("en='Current row end period cannot be empty.';ru='Конец периода текущей строки не может быть пустым.';cz='Current row end period cannot be empty.'");
		
		ElsIf CurrentData.EndDate < BegOfDay(CurrentDate()) Then
			
			Buttons.Add("Earliest", NStr("en='Earlist';ru='Самую раннюю возможную';cz='Nejbližší'"));
			Buttons.Add("Latest", NStr("en='Latest';ru='Самую позднюю возможную';cz='Latest'"));
			
			Earliest = ?(CurrentData.BeginDate >= CurrentDate(), CurrentData.BeginDate, CurrentDate());
			
			Params.Insert("Earliest", Earliest);
			Params.Insert("Latest", PrevDay(NextData.BeginDate));
			
			QueryText = NStr("en='Current row end date cannot be empty.';ru='Конец периода текущей строки не может быть меньше чем текущая дата.';cz='Konec období na tomto řádku nesmí být prázdný.'");
		
		ElsIf CurrentData.EndDate < CurrentData.BeginDate Then
			
			Buttons.Add("Earliest", NStr("en='Earlist';ru='Самую раннюю возможную';cz='Nejbližší'"));
			
			Params.Insert("Earliest", CurrentData.BeginDate);
			
			QueryText = NStr("en='Current row end period cannot be earlier than current row begin period.';ru='Конец периода текущей строки не может быть раньше чем начало периода текущей строки.';cz='Current row end period cannot be earlier than current row begin period.'");
		
		ElsIf CurrentData.EndDate >= NextData.BeginDate Then
			
			Buttons.Add("Latest", NStr("en='Latest';ru='Самую позднюю возможную';cz='Latest'"));
			
			Params.Insert("Latest", PrevDay(NextData.BeginDate));
			
			QueryText = NStr("en='Current row end date cannot be later or equal than next row begin date.';ru='Конец периода текущей строки не может быть позже или равным началу периода следующей строки.';cz='Konec období na tomto řádku nesmí předcházet začátek období na dalším řádku.'");
			
		EndIf;
		
	Else
		
		If ValueIsFilled(CurrentData.EndDate) And CurrentData.EndDate < CurrentData.BeginDate Then
			
			Buttons.Add("Earliest", NStr("en='Earlist';ru='Самую раннюю возможную';cz='Nejbližší'"));
			
			Params.Insert("Earliest", CurrentData.BeginDate);
			
			QueryText = NStr("en='Current row end date cannot be earlier than current row end period.';ru='Конец периода текущей строки не может быть раньше чем начало периода текущей строки.';cz='Začátek období na tomto řádku musí předcházet konec období.'");
			
		EndIf;
		
	EndIf;
	
	If Not QueryText = "" Then
		
		Question = NStr("en = ' What date set as current row end period?'; ru = ' Какую дату установить концом периода?'");
		
		ShowQueryBox(New NotifyDescription("PeriodsIncorrectInputProcessing", ThisForm, Params),
			QueryText + Question,
			Buttons,
			0,
			,
			NStr("en='Incorrect end date';ru='Неправильная дата окончания';cz='Nespravnй koncovй datum'"));
		
	EndIf;
	
	Item.Parent.EndEditRow(False);
	
EndProcedure

&AtClient
Procedure SetCurrentPeriod(CurrentItem)
	
	If CurrentItem.CurrentData = Undefined Then
		
		For Each Period In Object.Periods Do
			
			If Period.BeginDate <= BegOfDay(CurrentDate()) Then
				
				If Not ValueIsFilled(Period.EndDate) Or (Period.EndDate >= CurrentDate()) Then
					
					CurrentItem.CurrentRow = Period.GetID();
					
					SetFilter(CurrentItem);
					
					Break;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeletePeriodProcessing(Result, AdditionalParameter) Export
	
	If Result = DialogReturnCode.Yes Then
		
		Object.Periods.Delete(AdditionalParameter.Index);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodsIncorrectInputProcessing(Result, AdditionalParameter) Export
	
	CurrentData = AdditionalParameter.CurrentData;
	FieldName = AdditionalParameter.FieldName;
	NewDate = AdditionalParameter[Result];
	
	CurrentData[FieldName] = NewDate;
	
	If AdditionalParameter.Property("PreviousData") Then
	
		PreviousData = AdditionalParameter.PreviousData;
		
		If Not PreviousData = Undefined Then
			
			If PreviousData.EndDate > CurrentDate() Then
				
				PreviousData.EndDate = PrevDay(CurrentData.BeginDate);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Outlets

&AtClient
Procedure AddOutlet(Command)
	
	CurrentItem = ?(Items.GroupOutletsPages.CurrentPage = Items.GroupOutletsNoSelect, Items.Outlets, Items.Outlets1);
	
	If Not Items.Periods.CurrentData = Undefined Then
		
		If Not ValueIsFilled(Items.Periods.CurrentData.EndDate) OR Items.Periods.CurrentData.EndDate > CurrentDate() Then
			
			ChoiceForm = GetForm("Catalog.Outlet.ChoiceForm", , CurrentItem);
			
			ChoiceForm.CloseOnChoice = False;
			
			OpenForm(ChoiceForm);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowHideOutletsSelect(Command)
	
	IsSelectHidden = Items.GroupOutletsPages.CurrentPage = Items.GroupOutletsNoSelect;
	
	CurrentFormTable = ?(IsSelectHidden, "Outlets", "Outlets1");
	NextFormTable = ?(IsSelectHidden, "Outlets1", "Outlets");
	
	Items[NextFormTable].CurrentRow = Items[CurrentFormTable].CurrentRow;
		
	Items.GroupOutletsPages.CurrentPage = ?(IsSelectHidden,
											Items.GroupOutletsWithSelect,
											Items.GroupOutletsNoSelect);
	
	ThisForm.CurrentItem = Items[NextFormTable];
	
EndProcedure

&AtClient
Procedure OutletsBeforeDeleteRow(Item, Cancel)
	
	If Items.Periods.CurrentData = Undefined Then
		
		Cancel = True;
		
	Else
		
		If ValueIsFilled(Items.Periods.CurrentData.EndDate) AND Items.Periods.CurrentData.EndDate < NextDay() Then
			
			Cancel = True;
			
			UserMessage = New UserMessage;
			UserMessage.Text = NStr("en='Cannot delete outlets from past periods.';ru='Нельзя удалять торговые точки из прошедшего периода.';cz='Nelze odstraňovat prodejní místa nebo zboží z minulého období.'");
			
			UserMessage.Message();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OutletsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	StandardProcessing = False;
	
	Array = New Array;
	Array.Add(SelectedValue);
	
	AddToOutletsVT(Array);
	
EndProcedure

&AtClient
Procedure AddToOutletsVT(OutletsArray)
	
	If Not Items.Periods.CurrentData = Undefined Then
		
		If Not ValueIsFilled(Items.Periods.CurrentData.EndDate) OR Items.Periods.CurrentData.EndDate > CurrentDate() Then
			
			For Each Outlet In OutletsArray Do
			
				FilterParameters = New Structure;
				FilterParameters.Insert("Outlet", Outlet);
				FilterParameters.Insert("UUID", String(Items.Periods.CurrentData.UUID));
				
				If ThisForm.Outlets.FindRows(FilterParameters).Count() = 0 Then
					
					NewOutletRow = ThisForm.Outlets.Add();
					NewOutletRow.UUID = Items.Periods.CurrentData.UUID;
					NewOutletRow.Outlet = Outlet;
					
					Modified = True;
					
				EndIf;
				
			EndDo;
			
		Else
			
			UserMessage = New UserMessage;
			UserMessage.Text = NStr("en='Cannot add outlets to past periods.';ru='Нельзя добавлять торговые точки в прошедшие периоды.';cz='Nelze přidávat prodejní místa do minulého období.'");
			
			UserMessage.Message();

			
		EndIf;
		
	Else
		
		UserMessage = New UserMessage;
		UserMessage.Text = NStr("en='Choose period';ru='Выберите период';cz='Zvolte obdobн'");
		
		UserMessage.Message();
		
	EndIf;
	
	SetFilter(Items.Periods);
	
EndProcedure

#EndRegion

#Region OutletsSelect

&AtClient
Procedure AddOutletFromSelect(Command)
	
	AddToOutletsVT(ThisForm.Items.OutletsSelect.SelectedRows);
	
EndProcedure

&AtClient
Procedure AddAllOutletsFromSelect(Command)
	
	OutletsArray = GetOutletsArrayFromDynamicList();
	
	AddToOutletsVT(OutletsArray);
	
EndProcedure

&AtClient
Procedure RemoveOutlet(Command)
	
	CurrentItem = ?(Items.GroupOutletsPages.CurrentPage = Items.GroupOutletsNoSelect, Items.Outlets, Items.Outlets1);
	
	If Not CurrentItem.CurrentData = Undefined Then
		
		If Not ValueIsFilled(Items.Periods.CurrentData.EndDate) OR Items.Periods.CurrentData.EndDate > CurrentDate() Then
			
			Index = ThisForm.Outlets.IndexOf(CurrentItem.CurrentData);
			ThisForm.Outlets.Delete(Index);
			
			Modified = True;
			
		Else
			
			UserMessage = New UserMessage;
			UserMessage.Text = NStr("en='Cannot delete outlets from past and current periods.';ru='Нельзя удалять торговые точки из прошедших периодов.';cz='Nelze odstraňovat prodejní místa nebo zboží z minulého nebo aktuálního období.'");
			
			UserMessage.Message();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RemoveAllOutlets(Command)
	
	CurrentItem = ?(Items.GroupOutletsPages.CurrentPage = Items.GroupOutletsNoSelect, Items.Outlets, Items.Outlets1);
	
	If Not Items.Periods.CurrentData = Undefined Then
		
		If Not ValueIsFilled(Items.Periods.CurrentData.EndDate) OR Items.Periods.CurrentData.EndDate > CurrentDate() Then
	
			If Not CurrentItem.RowFilter = New FixedStructure("UUID", New UUID("00000000-0000-0000-0000-000000000000")) Then
				
				Rows = ThisForm.Outlets.FindRows(New Structure(CurrentItem.RowFilter));
				
				For Each Row In Rows Do
					
					Index = ThisForm.Outlets.IndexOf(Row);
					ThisForm.Outlets.Delete(Index);
					
					Modified = True;
					
				EndDo;
				
			EndIf;
			
		Else
			
			UserMessage = New UserMessage;
			UserMessage.Text = NStr("en='Cannot delete outlets from past and current periods.';ru='Нельзя удалять торговые точки из прошедших периодов.';cz='Nelze odstraňovat prodejní místa nebo zboží z minulého nebo aktuálního období.'");
			
			UserMessage.Message();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OutletsSelectSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not Item.CurrentData = Undefined Then
	
		CurrentOutlet = Item.CurrentData.Outlet;
		
		OutletsArray = New Array;
		OutletsArray.Add(CurrentOutlet);
		
		AddToOutletsVT(OutletsArray);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region SKUs

&AtClient
Procedure AddSKU(Command)
	
	If Not Items.Periods1.CurrentData = Undefined Then
		
		If Not ValueIsFilled(Items.Periods1.CurrentData.EndDate) OR Items.Periods1.CurrentData.EndDate > CurrentDate() Then
			
			ChoiceForm = GetForm("Catalog.SKU.ChoiceForm", , Items.SKUs);
			
			ChoiceForm.CloseOnChoice = False;
			
			OpenForm(ChoiceForm);
			
		Else
			
			UserMessage = New UserMessage;
			UserMessage.Text = NStr("en='Cannot add SKUs to past periods.';ru='Нельзя добавлять номенклатуру в прошедшие периоды.';cz='Nelze přidávat zboží do minulého období.'");
			
			UserMessage.Message();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SKUsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not Items.Periods1.CurrentData = Undefined Then
		
		If Not ValueIsFilled(Items.Periods1.CurrentData.EndDate) OR Items.Periods1.CurrentData.EndDate > CurrentDate() Then
			
			FilterParameters = New Structure;
			FilterParameters.Insert("SKU", SelectedValue);
			FilterParameters.Insert("UUID", String(Items.Periods1.CurrentData.UUID));
			
			If ThisForm.SKUs.FindRows(FilterParameters).Count() = 0 Then
				
				NewRow = ThisForm.SKUs.Add();
				NewRow.SKU = SelectedValue;
				NewRow.Unit = GetBaseUnit(SelectedValue);
				NewRow.UUID = Items.Periods1.CurrentData.UUID;
				
				Modified = True;
				
			EndIf;
			
		Else
			
			UserMessage = New UserMessage;
			UserMessage.Text = NStr("en='Cannot add SKUs to past periods.';ru='Нельзя добавлять номенклатуру в прошедшие периоды.';cz='Nelze přidávat zboží do minulého období.'");
			
			UserMessage.Message();
			
		EndIf;
		
	EndIf;
	
	SetFilter(Items.Periods1);
	
EndProcedure

&AtClient
Procedure SKUsBeforeDeleteRow(Item, Cancel)
	
	If Items.Periods1.CurrentData = Undefined Then
		
		Calcel = True;
		
	Else
		
		If ValueIsFilled(Items.Periods1.CurrentData.EndDate) AND Items.Periods1.CurrentData.EndDate < NextDay() Then
			
			Cancel = True;
			
			UserMessage = New UserMessage;
			UserMessage.Text = NStr("en='Cannot delete SKUs to past periods.';ru='Нельзя удалять номенклатуру из прошедших периодов.';cz='Nelze odstraňovat zboží z minulého období.'");
			
			UserMessage.Message();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SKUsUnitStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = GetAvailableUnits(Item.Parent.CurrentData.SKU);
	
EndProcedure

&AtClient
Procedure SKUsUnitAutoComplete(Item, Text, ChoiceData, Parameters, Wait, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = GetAvailableUnits(Item.Parent.CurrentData.SKU);
	
EndProcedure

&AtClient
Procedure SKUsUnitOnChange(Item)
	
	ThisForm.Modified = True;
	If CheckQty(Item.Parent.CurrentData.Unit) Then
		Message(NStr("ru='Заполните единицу измерения';en='Fill unit'"));
		//ThisForm.CurrentItem = Item;
		//Cancel = True;
	Else
		RecountBaseUnitQty(Item);
	EndIf;
	
EndProcedure
&AtServer
Function CheckQty(Item)
	
Return Item = Catalogs.UnitsOfMeasure.EmptyRef();	
	
EndFunction
&AtClient
Procedure SKUsQtyOnChange(Item)
	
	RecountBaseUnitQty(Item);
	
EndProcedure

&AtClient
Procedure RecountBaseUnitQty(Item)
	
	CurrentData = Item.Parent.CurrentData;
	
	Unit = CurrentData.Unit;
	SKU = CurrentData.SKU;
	
	Multiplier = GetCurrentSKUUnitMultiplier(SKU, Unit);
	
	CurrentData.BaseUnitQty = CurrentData.Qty * Multiplier;

EndProcedure

&AtServerNoContext
Function GetCurrentSKUUnitMultiplier(SKU, Unit)
	
	Query = New Query(
	"SELECT ALLOWED
	|	SKUPacking.Multiplier
	|FROM
	|	Catalog.SKU.Packing AS SKUPacking
	|WHERE
	|	SKUPacking.Ref = &SKU
	|	AND SKUPacking.Pack = &Pack");
	
	Query.SetParameter("SKU", SKU);
	Query.SetParameter("Pack", Unit);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		Return Selection.Multiplier;
		
	EndIf;
	
EndFunction

&AtServerNoContext
Function GetAvailableUnits(SKU)
	
	Query = New Query(
	"SELECT ALLOWED
	|	SKUPacking.Pack
	|FROM
	|	Catalog.SKU.Packing AS SKUPacking
	|WHERE
	|	SKUPacking.Ref = &SKU");
	Query.SetParameter("SKU", SKU);
	
	QueryResult = Query.Execute().Unload();
	
	ChoiceData = New ValueList;
	
	For Each Row In QueryResult Do
		
		ChoiceData.Add(Row.Pack);
		
	EndDo;
	
	Return ChoiceData;
	
EndFunction

&AtServerNoContext
Function GetBaseUnit(SKU)
	
	Return SKU.BaseUnit;
	
EndFunction

#EndRegion

&AtClient
Procedure SetFilter(Item)
	
	If Item.CurrentData = Undefined Then
		
		EmptyFilter = New FixedStructure("UUID", "00000000-0000-0000-0000-000000000000");
		
		Items.Outlets.RowFilter = EmptyFilter;
		Items.Outlets1.RowFilter = EmptyFilter;
		Items.SKUs.RowFilter = EmptyFilter;
		
	Else
		
		Filter = New FixedStructure("UUID", String(Item.CurrentData.UUID));
		
		Items.Outlets.RowFilter = Filter;
		Items.Outlets1.RowFilter = Filter;
		Items.SKUs.RowFilter = Filter;
		
	EndIf;
	
EndProcedure

&AtClient
Function GetNextData(CurrentDataIndex)
	
	Return ?(CurrentDataIndex = Object.Periods.Count() - 1,
		Undefined,
		Object.Periods.Get(CurrentDataIndex + 1));
	
EndFunction

&AtClient
Function GetPreviousData(CurrentDataIndex)
	
	Return ?(CurrentDataIndex = 0,
		Undefined,
		Object.Periods.Get(CurrentDataIndex - 1));
	
EndFunction

&AtClient
Procedure SKUsUnitClearing(Item, StandardProcessing)
	a=1;
EndProcedure

#EndRegion
