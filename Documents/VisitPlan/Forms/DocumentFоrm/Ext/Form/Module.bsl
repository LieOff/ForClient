&AtClient
Var PrevTime;

#Region CommonProceduresAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	 
	PredefinedItems = New Map;
	PredefinedItems.Insert("Catalog.User", "SR");
	 
	ItemsCollection = CommonProcessors.GetPredefinedItems(PredefinedItems);
	
	For Each Item In ItemsCollection Do
		
		Object[Item.Key] = Item.Value;
		
	EndDo;
	
	ObjectWeekNumber = Object.WeekNumber;
	ObjectYear = Object.Year;
	
	FillWeekNumbers();
	
	CurrentWeekNumber = FormAttributeToValue("Object").GetWeekOfYear(CurrentDate());
	
	FillValueTableOutlets();
	
	ThisForm.YearNumber = Format(Year(Object.Year), "NG=");
	
	CDate = CurrentDate();
	
	If CDate > Object.DateTo Then 
		
		// Заблокировать редактирование года, недели и кнопки заполнения/очистки если неделя уже прошла
		Items.SR.Enabled					= False;
		Items.Year.Enabled					= False;
		Items.WeekChooserWeekNumber.Enabled	= False;
		Items.Clear.Enabled					= False;
		Items.FillTableUsing.Enabled		= False;
		
	ElsIf CDate > BegOfDay(Object.DateFrom) And CDate < EndOfDay(Object.DateTo) And ValueIsFilled(Object.Ref) Then 
		
		// Заблокировать редактирование года, недели если неделя текущая
		Items.SR.Enabled					= False;
		Items.Year.Enabled					= False;
		Items.WeekChooserWeekNumber.Enabled	= False;
		
	EndIf;
		
	//Оформление строки для групповой работы с торговой точкой. 
    ЭлементУсловногоОформления 		= УсловноеОформление.Элементы.Добавить();
    ОформляемоеПоле 				= ЭлементУсловногоОформления.Поля.Элементы.Добавить();
    ОформляемоеПоле.Поле    		= Новый ПолеКомпоновкиДанных("ValueTableOutlets");
    ЭлементОтбора 					= ЭлементУсловногоОформления.Отбор.Элементы.Добавить(Тип("ЭлементОтбораКомпоновкиДанных"));
    ЭлементОтбора.ЛевоеЗначение 	= Новый ПолеКомпоновкиДанных("ValueTableOutlets.General");
    ЭлементОтбора.ВидСравнения 		= ВидСравненияКомпоновкиДанных.Равно;
    ЭлементОтбора.ПравоеЗначение 	= Истина;
    ЭлементУсловногоОформления.Оформление.УстановитьЗначениеПараметра("ЦветФона", WebЦвета.БледноЗеленый);
	ЭлементУсловногоОформления.Оформление.УстановитьЗначениеПараметра("Текст", "");

	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Cancel = CheckVisitPlans();
	
	CurrentObject.WeekNumber = ObjectWeekNumber;
	CurrentObject.Year = ObjectYear;
	
EndProcedure

&AtServer
Procedure FillValueTableOutlets()
	
	Query = New Query(
	"SELECT ALLOWED DISTINCT
	|	TerritoryOutlets.Outlet,
	|	TerritorySRs.Ref AS Territory
	|INTO SRsOutlets
	|FROM
	|	Catalog.Territory.Outlets AS TerritoryOutlets
	|		INNER JOIN Catalog.Territory.SRs AS TerritorySRs
	|		ON TerritoryOutlets.Ref = TerritorySRs.Ref
	|WHERE
	|	&SR IN (TerritorySRs.SR)
	|	AND NOT TerritoryOutlets.Outlet = VALUE(Catalog.Outlet.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	VisitPlanOutlets.Outlet,
	|	VisitPlanOutlets.Date
	|INTO VisitPlanOutlets
	|FROM
	|	&VisitPlanOutlets AS VisitPlanOutlets
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SRsOutlets.Outlet AS Outlet,
	|	SRsOutlets.Outlet.Address AS Address,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 1
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS DateBoolean1,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 2
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS DateBoolean2,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 3
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS DateBoolean3,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 4
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS DateBoolean4,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 5
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS DateBoolean5,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 6
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS DateBoolean6,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 7
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS DateBoolean7,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 1
	|				THEN VisitPlanOutlets.Date
	|		END) AS Time1,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 2
	|				THEN VisitPlanOutlets.Date
	|		END) AS Time2,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 3
	|				THEN VisitPlanOutlets.Date
	|		END) AS Time3,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 4
	|				THEN VisitPlanOutlets.Date
	|		END) AS Time4,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 5
	|				THEN VisitPlanOutlets.Date
	|		END) AS Time5,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 6
	|				THEN VisitPlanOutlets.Date
	|		END) AS Time6,
	|	MAX(CASE
	|			WHEN WEEKDAY(VisitPlanOutlets.Date) = 7
	|				THEN VisitPlanOutlets.Date
	|		END) AS Time7,
	|	SRsOutlets.Outlet.Distributor AS Distributor,
	|	SRsOutlets.Outlet.Class AS Class,
	|	SRsOutlets.Outlet.Type AS Type,
	|	SRsOutlets.Outlet.Description AS Description,
	|	SRsOutlets.Territory
	|FROM
	|	SRsOutlets AS SRsOutlets
	|		LEFT JOIN VisitPlanOutlets AS VisitPlanOutlets
	|		ON SRsOutlets.Outlet = VisitPlanOutlets.Outlet
	|
	|GROUP BY
	|	SRsOutlets.Outlet,
	|	SRsOutlets.Outlet.Address,
	|	SRsOutlets.Outlet.Distributor,
	|	SRsOutlets.Outlet.Class,
	|	SRsOutlets.Outlet.Type,
	|	SRsOutlets.Outlet.Description,
	|	SRsOutlets.Territory
	|AUTOORDER");
	
	Query.SetParameter("VisitPlanOutlets", Object.Outlets.Unload());
	Query.SetParameter("SR", Object.SR);
	
	Result = Query.Execute().Unload();
	
	ValueTableOutlets.Load(Result);
	
EndProcedure

&AtServer
Procedure FillOutletsUsing(VisitPlan)
	
	DeleteOutletsRows();
	
	Query = New Query(
	"SELECT ALLOWED
	|	VisitPlanOutlets.Outlet,
	|	DATEADD(&DateFrom, SECOND, (WEEKDAY(VisitPlanOutlets.Date) - 1) * 60 * 60 * 24 + SECOND(VisitPlanOutlets.Date) + 60 * MINUTE(VisitPlanOutlets.Date) + 60 * 60 * HOUR(VisitPlanOutlets.Date)) AS Date
	|INTO TempTable
	|FROM
	|	Document.VisitPlan.Outlets AS VisitPlanOutlets
	|WHERE
	|	VisitPlanOutlets.Ref = &VisitPlan
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempTable.Outlet,
	|	TempTable.Date
	|FROM
	|	TempTable AS TempTable
	|WHERE
	|	TempTable.Date >= &CurrentDate");
	
	Query.SetParameter("VisitPlan", VisitPlan);
	Query.SetParameter("DateFrom", Object.DateFrom);
	Query.SetParameter("CurrentDate", BegOfDay(CurrentDate()));
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		FillPropertyValues(Object.Outlets.Add(), Selection);
		
	EndDo;
	
	FillValueTableOutlets();
	
EndProcedure

&AtServer
Procedure FillWeekNumbers()
	
	FirstWeekNumber = 1; //GetWeekOfYear(BegOfYear(Object.Year));
	LastWeekNumber = FormAttributeToValue("Object").GetWeekOfYear(EndOfYear(Object.Year));
	
	    
	ThisForm.WeekChooser.Clear();
	
	For WeekNumber = FirstWeekNumber To LastWeekNumber Do
		
		NewRow = ThisForm.WeekChooser.Add();
		NewRow.WeekNumber = WeekNumber;
		NewRow.WeekBeginDate = BeginOfWeekInYear(WeekNumber, Object.Year);
		NewRow.WeekEndDate = EndOfWeek(NewRow.WeekBeginDate);
		
	EndDo;
	
	Query = New Query(
	"SELECT
	|	FormTable.WeekNumber,
	|	FormTable.WeekBeginDate,
	|	FormTable.WeekEndDate
	|INTO FormTable
	|FROM
	|	&FormTable AS FormTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MAX(VisitPlan.Ref) AS VisitPlan,
	|	VisitPlan.WeekNumber AS WeekNumber
	|INTO VisitPlans
	|FROM
	|	Document.VisitPlan AS VisitPlan
	|WHERE
	|	VisitPlan.SR = &SR
	|	AND BEGINOFPERIOD(VisitPlan.Year, YEAR) = BEGINOFPERIOD(&Year, YEAR)
	|	AND NOT VisitPlan.Ref = &ThisVisitPlan
	|
	|GROUP BY
	|	VisitPlan.WeekNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FormTable.WeekNumber,
	|	FormTable.WeekBeginDate,
	|	FormTable.WeekEndDate,
	|	VisitPlans.VisitPlan AS VisitPlan
	|FROM
	|	FormTable AS FormTable
	|		LEFT JOIN VisitPlans AS VisitPlans
	|		ON FormTable.WeekNumber = VisitPlans.WeekNumber
	|WHERE
	|	VisitPlans.VisitPlan IS NULL 
	|	AND CASE
	|			WHEN YEAR(&Year) = YEAR(&ThisYear)
	|				THEN FormTable.WeekNumber >= &MinWeekNumber
	|						OR FormTable.WeekNumber = &ThisWeekNumber
	|			ELSE TRUE
	|		END");
	
	Query.SetParameter("FormTable", FormAttributeToValue("WeekChooser"));
	Query.SetParameter("SR", Object.SR);
	Query.SetParameter("Year", BegOfYear(Object.Year));
	Query.SetParameter("ThisYear", BegOfYear(CurrentDate()));
	Query.SetParameter("ThisVisitPlan", Object.Ref);
	Query.SetParameter("MinWeekNumber", FormAttributeToValue("Object").GetWeekOfYear(CurrentDate()));
	Query.SetParameter("ThisWeekNumber", Object.WeekNumber);
	
	SetPrivilegedMode(True);
	
	Result = Query.Execute().Unload();
	
	SetPrivilegedMode(False);
	
	ThisForm.WeekChooser.Load(Result);
	
	FilterParameters = New Structure;
	FilterParameters.Insert("WeekNumber", Object.WeekNumber);
	FilterParameters.Insert("VisitPlan", False);
	WeekRows = ThisForm.WeekChooser.FindRows(FilterParameters);
	
	If WeekRows.Count() Then
		
		ThisForm.Items.WeekChooser.CurrentRow = WeekRows[0].GetId();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteOutletsRows()
	
	CDate = BegOfDay(CurrentDate());
	
	ClearArray = New Array;
	
	For Each OutletStr In Object.Outlets Do 
		
		If OutletStr.Date >= CDate Then 
			
			ClearArray.Add(OutletStr);
			
		EndIf;
		
	EndDo;
	
	For Each ClearStr In ClearArray Do 
		
		Object.Outlets.Delete(ClearStr);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearOutlets()
	
	DeleteOutletsRows();
	
	FillValueTableOutlets();
	
EndProcedure

&AtServer
Function CheckVisitPlans()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	VisitPlan.SR,
	|	VisitPlan.Year,
	|	VisitPlan.WeekNumber
	|FROM
	|	Document.VisitPlan AS VisitPlan
	|WHERE
	|	VisitPlan.SR = &SR
	|	AND YEAR(VisitPlan.Year) = &Year
	|	AND VisitPlan.WeekNumber = &WeekNumber
	|	AND VisitPlan.Ref <> &Ref";
	
	Query.SetParameter("SR",Object.SR);
	Query.SetParameter("Year",Year(Object.Year));
	Query.SetParameter("WeekNumber",ObjectWeekNumber);
	Query.SetParameter("Ref",Object.Ref);
	
	Result = Query.Execute().Select();
	
	if Result.Next() then
		Message(NStr("en='This SR is already have visit plan for this week';ru='Для выбранного SR уже имеется план на выбранную неделю';cz='This SR is already have visit plan for this week'"));	
		Return True;
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return False;
	
EndFunction // CheckVisitPlans()

// Функция возвращает дату первого дня недели по переданному в функцию номеру 
// недели в переданном в функцию году
&AtServerNoContext
Function BeginOfWeekInYear(WeekNumber, YearDate)
	
	YearFirstDay = BeginOfFirstWeek(YearDate);
	DateInGivenWeek = YearFirstDay + 60 * 60 * 24 * 7 * (WeekNumber - 1);
	BeginOfGivenWeek = BegOfWeek(DateInGivenWeek);
	Return BeginOfGivenWeek;
	
EndFunction

&AtServerNoContext
Function BeginOfFirstWeek(Year) Export
	
	If GetWeekOfYear(Date(Year(Year), 01, 01)) = 1 Then
		
		Return BegOfWeek(Year);
		
	Else
		
		Return BegOfWeek(Date(Year(Year), 01, 04));
		
	EndIf;
	
EndFunction

&AtServerNoContext
Function GetWeekOfYear(Date) Export
	
	CalendarYearStart = GetYear(Date);
	
	If WeekDay(CalendarYearStart) >= 1 And WeekDay(CalendarYearStart) <= 4 Then
		
		GostYearStart = BegOfWeek(CalendarYearStart);
		
	Else
		
		GostYearStart = BegOfWeek(Date(Year(CalendarYearStart), 01, 04));
		
	EndIf;
	
	WeekNumber = Int((Date - GostYearStart) / (60 * 60 * 24 * 7));
	
	Return WeekNumber + 1;
	
EndFunction

// В связи с тем, что мы считаем номера недель по стандарту ГОСТ ИСО 8601-2001 
// числа с 29 декабря по 3 января могут попадать либо в неделю относящуюся к 
// текущему году, либо в неделю относящуюся к предыдущему году. Данная функция
// принимает дату и возвращает год к которому относится эта дата.
&AtServerNoContext
Function GetYear(Date) Export
	
	CurrentYear = Date(Year(Date), 01, 01);
	
	If Date >= Date(Year(Date), 12, 29) And Date <= EndOfYear(Date) Then
		
		NextYear = Date(Year(CurrentYear) + 1, 01, 01);
		
		FourthJanuary = Date(Year(NextYear), 01, 04);
		
		If BegOfWeek(Date) < BegOfWeek(FourthJanuary) Then
			
			Return CurrentYear;
			
		Else
			
			Return NextYear;
			
		EndIf;
		
	ElsIf Date >= BegOfYear(Date) And Date <= Date(Year(Date), 01, 04) Then
		
		PrevYear = Date(Year(CurrentYear) - 1, 01, 01);
		
		If BegOfWeek(Date) < BegOfWeek(Date(Year(Date), 01, 04)) Then
			
			Return PrevYear;
			
		Else
			
			Return CurrentYear;
			
		EndIf;
		
	Else
		
		Return CurrentYear;
		
	EndIf;
	
EndFunction

&AtServer
Procedure OnOpenAtServer()
	
	Items.Number.ReadOnly = Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditDocumentNumbers);
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
	SetColumnsAvailability();
	
	PredefinedString("General", True);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.VisitPlan.Form.ChoiceForm" Then
		
		FillOutletsUsing(SelectedValue);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecountOutlets()
	
	For Each Row In Object.Outlets Do
		
		OldDate = Row.Date;
		Row.Date = Object.DateFrom + (WeekDay(OldDate) - 1) * 60 * 60 * 24 + Hour(OldDate) * 60 * 60 + Minute(OldDate) * 60 + Second(OldDate);
		
	EndDo;
	
EndProcedure

#Region Header

&AtClient
Procedure YearTuning(Item, Direction, StandardProcessing)
	
	Object.Year = ?(Direction = 1, BegOfYear(AddMonth(Object.Year, 12)), BegOfYear(Object.Year - 1));
	
	// Планируемый год не может быть меньше чем текущий год
	If BegOfYear(Object.Year) < BegOfYear(CurrentDate()) Then
		
		Object.Year = BegOfYear(CurrentDate());
		
	EndIf;
	
	ThisForm.YearNumber = Format(Object.Year, "DF=yyyy");
	
	ProcessWeekNumberAndYearChange();
	
	FillWeekNumbers();
	
EndProcedure

&AtClient
Procedure WeekNumberOnChange(Item)
	
	ProcessWeekNumberAndYearChange();
	
EndProcedure

&AtClient
Procedure SROnChange(Item)
	
	FillValueTableOutlets();	
	FillWeekNumbers();
	ClearOutlets();
	PredefinedString("General", True);
	WeekChooserOnActivateCell(Items.WeekChooser);
	
EndProcedure

#EndRegion

#Region ValueTables

&AtClient
Procedure ValueTableOnChange(Item)
	
	CurrentData = Items.ValueTableOutlets.CurrentData;
	
	If CurrentData.General Then	
		ValueTableOutletsOnChange(CurrentData, Item.Name);
	EndIf;
		
	DayOfWeek = Right(Item.Name, 1);
	
	CurrentDate = BegOfDay(Object.DateFrom) + 60 * 60 * 24 * (DayOfWeek - 1);
	
	PrevTime = ?(PrevTime = Undefined, Date(1, 1, 1), PrevTime);
	PrevDateTime = CurrentDate + Second(PrevTime) + Minute(PrevTime) * 60 + Hour(PrevTime) * 3600;
	
	CurrentTime = CurrentData["Time" + DayOfWeek];
	CurrentDateTime = CurrentDate + Second(CurrentTime) + Minute(CurrentTime) * 60 + Hour(CurrentTime) * 3600;
	
	If CurrentData.General Then
		
		For each String In ValueTableOutlets Do
		FilterParameters = New Structure;
		FilterParameters.Insert("Outlet", String.Outlet);
		FilterParameters.Insert("Date", PrevDateTime);
		
		Rows = Object.Outlets.FindRows(FilterParameters);
		
			If Rows.Count() Then
				
				For Each Row In Rows Do
					
					Object.Outlets.Delete(Object.Outlets.IndexOf(Row));
					
				EndDo;				
			EndIf;
		EndDo;
	Else
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Outlet", CurrentData.Outlet);
		FilterParameters.Insert("Date", PrevDateTime);
		
		Rows = Object.Outlets.FindRows(FilterParameters);
		
		If Rows.Count() Then
			
			For Each Row In Rows Do
				
				Object.Outlets.Delete(Object.Outlets.IndexOf(Row));
				
			EndDo;
		EndIf;
	EndIf;
	
	Checked = CurrentData["DateBoolean" + DayOfWeek];
	
	
	If Checked Then
		If CurrentData.General = False Then
		
			NewRow = Object.Outlets.Add();
			NewRow.Outlet = CurrentData.Outlet;
			NewRow.Date = CurrentDateTime;
			
		Else
			
			For each String In ValueTableOutlets Do
				
				If String.General = False AND String["DateBoolean" + DayOfWeek] = True Then
					
					NewRow = Object.Outlets.Add();
					NewRow.Outlet = String.Outlet;
					NewRow.Date = CurrentDateTime;
					
				EndIf;			
			EndDo;			
		EndIf;		
	Else
		
		CurrentData["Time" + DayOfWeek] = Date(1, 1, 1);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueTableOutletsOnStartEdit(Item, NewRow, Clone)
	
 	If Find(Item.CurrentItem.Name, "Date") OR Find(Item.CurrentItem.Name, "Time") Then
		
		DayOfWeek = Right(Item.CurrentItem.Name, 1);
		CurrentData = Items.ValueTableOutlets.CurrentData;
		
		PrevTime = CurrentData["Time" + DayOfWeek];
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueTableOutletsOnActivateCell(Item)
	
 	ItemName = Item.CurrentItem.Name;
	If Item.CurrentData = Undefined Then
		Items.CreateTask.Enabled = False;
	ElsIf Item.CurrentData.General Then
		Items.CreateTask.Enabled = False;
	Else
		Items.CreateTask.Enabled = ?(ItemName = "ValueTableOutlet" OR ItemName = "ValueTableOutletsAddress", False, Not ThisForm["Attribute" + Right(Item.CurrentItem.Name, 1)]);
	EndIf
		
EndProcedure

&AtClient
Procedure WeekChooserOnActivateCell(Item)
	
	If Not Item.CurrentData = Undefined Then
		
		Modified = ?(Modified, True, NOT Item.CurrentData.WeekNumber = ObjectWeekNumber);
		ObjectWeekNumber = Item.CurrentData.WeekNumber;
		
		ProcessWeekNumberAndYearChange();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DistributorFilterOnChange(Item)
	
	SetRowFilter("Distributor");
	
EndProcedure

&AtClient
Procedure ClassFilterOnChange(Item)
	
	SetRowFilter("Class");
	
EndProcedure

&AtClient
Procedure TypeFilterOnChange(Item)
	
	SetRowFilter("Type");
	
EndProcedure

&AtClient
Procedure TerritoryFilterOnChange(Item)
	
	SetRowFilter("Territory");
	
EndProcedure

&AtClient
Procedure DescriptionFilterEditTextChange(Item, Text, StandardProcessing)
	
	SetRowFilter("Description", Text);
		
EndProcedure

&AtClient
Процедура AddresFilterEditTextChange(Item, Text, StandardProcessing)
	
	SetRowFilter("Address", Text);
		
КонецПроцедуры

#EndRegion

#Region Commands

&AtClient
Procedure Clear(Command)
	
	ClearOutlets();
	PredefinedString("General", True);
	
EndProcedure

&AtClient
Procedure FillTableUsing(Command)
	
	FilterValue = New Structure("SR", ThisForm.Object.SR);
	ChoiceParameters = New Structure("Filter", FilterValue);
	
	ChoiceForm = GetForm("Document.VisitPlan.ChoiceForm", ChoiceParameters);
	ChoiceForm.FormOwner = ThisForm;
	ChoiceForm.Open();
	
EndProcedure

&AtClient
Procedure CreateTask(Command)
	
	Modified = True;
	
	CurrentTableItem = Items.ValueTableOutlets.CurrentItem;
	CurrentData = Items.ValueTableOutlets.CurrentData;
	
	If Find(CurrentTableItem.Name, "Date") OR Find(CurrentTableItem.Name, "Time") Then
		
		If Not CurrentData = Undefined Then
			
			If Object.Ref.IsEmpty() Then
				
				Message(NStr("en='Document must be saved before creating task';ru='Документ должен быть записан перед созданием задачи';cz='Před vytvořením úkolu musíte dokument uložit'"));
				
			Else
			
				DayOfWeek = Right(CurrentTableItem.Name, 1);
				
				PlanDate = BegOfDay(Object.DateFrom) + 60 * 60 * 24 * (DayOfWeek - 1);
				Outlet = CurrentData.Outlet;
				TerritoryFilter = CommonProcessors.GetTerritory(Outlet);
				
				FormParameters = New Structure;
				FormParameters.Insert("Outlet", Outlet);
				FormParameters.Insert("PlanExecutor", Object.SR);
				FormParameters.Insert("StartPlanDate", PlanDate);
				
				FillingValues = New Structure("FillingValues", FormParameters);
				
				OpenForm("Document.Task.ObjectForm", FillingValues);
				
			EndIf;
			
		EndIf;
		
	Else
		
		Message(NStr("en='Choose particlular date';ru='Выберите конкретную дату';cz='Zvolte datum'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearFilters(Command)
	
	ThisForm.DescriptionFilter = Undefined;
	ThisForm.DistributorFilter = Undefined;
	ThisForm.ClassFilter = Undefined;
	ThisForm.TypeFilter = Undefined;
	ThisForm.AddressFilter = Undefined;
	ThisForm.TerritoryFilter = Undefined;
	
	ThisForm.Items.ValueTableOutlets.RowFilter = Undefined;
	
EndProcedure

#EndRegion

#Region Helpers

&AtClient
Procedure ProcessWeekNumberAndYearChange()
	
	Object.DateFrom = BeginOfWeekInYear(ObjectWeekNumber, Object.Year);
	Object.DateTo = EndOfWeek(Object.DateFrom);
	
	SetColumnsAvailability();
	RecountOutlets();
	
EndProcedure

&AtClient
Procedure SetColumnsAvailability()
	
	ColumnDate = Object.DateFrom;
	For WeekDay = 1 To 7 Do
		
		Value = BegOfDay(ColumnDate) < BegOfDay(CurrentDate());
		ThisForm["Attribute" + WeekDay] = Value;
		ColumnDate = ColumnDate + 60 * 60 * 24;
		
	EndDo;
		
EndProcedure

&AtClient
Procedure SetRowFilter(AttributeName, SearchText = Undefined)
	
	StructureHuiure = New Structure;
	StructureHuiure.Вставить("General", True);
	ПерваяСтрока =  ValueTableOutlets.НайтиСтроки(StructureHuiure)[0];
	
	If ThisForm.Items.ValueTableOutlets.RowFilter = Undefined Then
		
		FilterStructure = New Structure;
		
	Else
		
		FilterStructure = New Structure(ThisForm.Items.ValueTableOutlets.RowFilter);
		
	EndIf;
		
		
	ProcessFilterStructure(ПерваяСтрока, FilterStructure, AttributeName, ?(AttributeName = "Description" OR AttributeName = "Address", SearchText, ThisForm[AttributeName + "Filter"]));
	 
	Filter = ?(FilterStructure.Count() > 0, New FixedStructure(FilterStructure), Undefined);
		
	ThisForm.Items.ValueTableOutlets.RowFilter = Filter;

EndProcedure

&AtClient
Procedure ProcessFilterStructure(ПерваяСтрока, Structure, AttributeName, Value)
	
	If ValueIsFilled(Value) Then
		
		Structure.Insert(AttributeName, Value);
		ПерваяСтрока[AttributeName] = Value;
		
	Else
				
		Structure.Delete(AttributeName);
		
	EndIf;

EndProcedure

&AtClient
Procedure ShowOnMap(Command)
	
	CurrentDate = Object.DateFrom;
	
	CurrentData = Items.ValueTableOutlets.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		If Left(Items.ValueTableOutlets.CurrentItem.Name, 21) = "ValueTableDateBoolean" Or
			Left(Items.ValueTableOutlets.CurrentItem.Name, 21) = "ValueTableOutletsTime" Then
			
			DayOfWeek = Right(Items.ValueTableOutlets.CurrentItem.Name, 1);
			
			CurrentDate = BegOfDay(Object.DateFrom) + 60 * 60 * 24 * (DayOfWeek - 1);
			
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Date", CurrentDate);
	
	OpenForm("Document.VisitPlan.Form.VisitPlanOnMapForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure TerritoryFilterStartChoice(Item, ChoiceData, StandardProcessing)
	
		StandardProcessing = False;
		Structure = New Structure;
		Structure.Insert("SR", Object.SR);
		ChoiceForm = OpenForm("Catalog.Territory.ChoiceForm", Structure, Item);		
		
EndProcedure

&AtClient
Procedure PredefinedString(Key, Value)
	
	Structure = New Structure;
	Structure.Insert(Key, Value);
	
	If ValueTableOutlets.FindRows(Structure).Count() = 0 Then 
		
		String = ValueTableOutlets.Insert(0);
		String.General = True;
		
		If NOT ThisForm.Items.ValueTableOutlets.RowFilter = Undefined Then
			StructureFilter = ThisForm.Items.ValueTableOutlets.RowFilter; 
			For each Key In StructureFilter Do
				String[Key.Key] = Key.Value;		
			EndDo	
		EndIf
	EndIf		

EndProcedure

&AtClient
Procedure ValueTableOutletsOnChange(CurrentString, ItemName)
	
	ArrayFilter = New Array;
	
	If NOT ThisForm.Items.ValueTableOutlets.RowFilter = Undefined Then
		
		For each StringStructure In ThisForm.Items.ValueTableOutlets.RowFilter Do
			
			ArrayFilter.Add(StringStructure); 
			
		EndDo;
	EndIf;	
		
		Value = CurrentString[Right(ItemName, 12)];
		For each String In ValueTableOutlets Do
		
			TimeString = String[СтрЗаменить(Right(ItemName, 12), "DateBoolean", "Time")];
			If ?(ArrayFilter.Count() > 0, ПроверитьСтрокуНаЗначенияФильтов(ArrayFilter, String), True) Then 
			    
				String[Right(ItemName, 12)] = Value;				
				String[СтрЗаменить(Right(ItemName, 12), "DateBoolean", "Time")] = ?(Value = False, Date("00010101"), TimeString);
				
			EndIf;	
		EndDo;
	
	    
EndProcedure

&AtClient
Function ПроверитьСтрокуНаЗначенияФильтов(Array, String)
	
	For each StringArray In Array Do
		
		If NOT 		?(StringArray.Key = "Address" OR StringArray.Key = "Description", 
					Find(Upper(String[StringArray.Key]), Upper(StringArray.Value)) > 0, 
					String[StringArray.Key] = StringArray.Value) Then
			
			Возврат False;
			
		EndIf;   
	EndDo;
	
	Возврат True		
EndFunction;

#EndRegion

#EndRegion
