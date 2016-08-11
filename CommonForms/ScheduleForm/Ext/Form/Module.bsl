// FORM EVENTS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	DaysOfWeek = GetEmptyDaysOfWeek();
	Months = GetEmptyMonths();
	
	If Parameters.Schedule = "" Then
		Schedule = "Day;1";
	Else
		Schedule = Parameters.Schedule;
	EndIf;
	Source = Parameters.Source;
	ScheduleStructure = GetScheduleStructure();
	FillPropertyValues(ThisForm, ScheduleStructure);
	ScheduleStringPresentation = GetStringPresentationOfSchedule(Schedule);
	SetVisibility();
EndProcedure

// FORM ITEMS EVENTS

&AtClient
Procedure WriteAndClose(Command)
	Structure = New Structure;
	Structure.Insert("Schedule", Schedule);
	Structure.Insert("ScheduleStringPresentation", ScheduleStringPresentation);
	Structure.Insert("Modified", Modified);
	
	Notify(Source, Structure);
	
	ThisForm.Close();
EndProcedure

&AtClient
Procedure ScheduleTypeOnChange(Item)
	SetVisibilityAndSchedule();
EndProcedure

&AtClient
Procedure QtyOfDaysOnChange(Item)
	SetSchedule();
EndProcedure

&AtClient
Procedure DaysOfWeekCheckOnChange(Item)
	SetSchedule();
EndProcedure

&AtClient
Procedure MonthScheduleTypeOnChange(Item)
	SetVisibilityAndSchedule();
EndProcedure

&AtClient
Procedure MonthBeginPeriodOnChange(Item)
	Items.MonthEndPeriod.MinValue = MonthBeginPeriod;
	MonthEndPeriod = Max(MonthBeginPeriod, MonthEndPeriod);
	SetSchedule();
EndProcedure

&AtClient
Procedure MonthEndPeriodOnChange(Item)
	SetSchedule();
EndProcedure

&AtClient
Procedure MonthFirstOnChange(Item)
	SetSchedule();
EndProcedure

&AtClient
Procedure MonthLastOnChange(Item)
	SetSchedule();
EndProcedure

&AtClient
Procedure YearScheduleTypeOnChange(Item)
	SetVisibilityAndSchedule();
EndProcedure

&AtClient
Procedure MonthsCheckOnChange(Item)
	SetSchedule();
EndProcedure

&AtClient
Procedure YearFirstOnChange(Item)
	SetSchedule();
EndProcedure

&AtClient
Procedure YearLastOnChange(Item)
	SetSchedule();
EndProcedure

&AtClient
Procedure YearBeginPeriodDayOnChange(Item)
	If YearBeginPeriodMonth[0].Value = YearEndPeriodMonth[0].Value Then
		Items.YearEndPeriodDay.MinValue = YearBeginPeriodDay;
		YearEndPeriodDay = ?(YearEndPeriodDay >= YearBeginPeriodDay, YearEndPeriodDay, YearBeginPeriodDay);
	Else
		Items.YearEndPeriodDay.MinValue = 1;
	EndIf;
	SetSchedule();
EndProcedure

&AtClient
Procedure YearEndPeriodDayOnChange(Item)
	SetSchedule();
EndProcedure

&AtClient
Procedure YearBeginPeriodMonthStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	MonthsList = GetEmptyMonths();
	
	ShowChooseFromList(New NotifyDescription("YearBeginPeriodMonthProcessing", ThisForm), 
					   MonthsList,
					   Item,
					   YearBeginPeriodMonth[0].Value - 1);

EndProcedure

&AtClient
Procedure YearBeginPeriodMonthProcessing(Result, Parameters) Export
	
	If Not Result = Undefined Then
		
		MList = New ValueList;
		MList.Add(Result.Value, Result.Presentation);
		
		YearBeginPeriodMonth = MList;
		
		YearEndPeriodMonth = ?(YearEndPeriodMonth[0].Value < YearBeginPeriodMonth[0].Value, YearBeginPeriodMonth, YearEndPeriodMonth);
		
		If YearBeginPeriodMonth[0].Value = YearEndPeriodMonth[0].Value Then
			
			Items.YearEndPeriodDay.MinValue = YearBeginPeriodDay;
			YearEndPeriodDay = ?(YearEndPeriodDay >= YearBeginPeriodDay, YearEndPeriodDay, YearBeginPeriodDay);
			
		Else
			
			Items.YearEndPeriodDay.MinValue = 1;
			
		EndIf;
		
	EndIf;

	SetSchedule();

EndProcedure	
	
&AtClient
Procedure YearEndPeriodMonthStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	MonthsList = GetEmptyMonths(YearBeginPeriodMonth[0].Value);
	
	ShowChooseFromList(New NotifyDescription("YearEndPeriodMonthProcessing", ThisForm), 
					   MonthsList,
					   Item,
					   YearEndPeriodMonth[0].Value - YearBeginPeriodMonth[0].Value);

EndProcedure

&AtClient
Procedure YearEndPeriodMonthProcessing(Result, Parameters) Export
	
	If Not Result = Undefined Then
		
		MList = New ValueList;
		MList.Add(Result.Value, Result.Presentation); 
		
		YearEndPeriodMonth = MList;
		
		If YearBeginPeriodMonth[0].Value = YearEndPeriodMonth[0].Value Then
			
			Items.YearEndPeriodDay.MinValue = YearBeginPeriodDay;
			YearEndPeriodDay = ?(YearEndPeriodDay >= YearBeginPeriodDay, YearEndPeriodDay, YearBeginPeriodDay);
			
		Else
			
			Items.YearEndPeriodDay.MinValue = 1;
			
		EndIf;
		
	EndIf;

	SetSchedule();

EndProcedure


// HELPER PROCEDURES

&AtServer
Procedure SetVisibility()
	Items.GroupDays.Visible = ScheduleType = Enums.ScheduleTypes.Day;
	Items.GroupWeeks.Visible = ScheduleType = Enums.ScheduleTypes.Week;	
	Items.GroupMonths.Visible = ScheduleType = Enums.ScheduleTypes.Month;
	Items.GroupYears.Visible = ScheduleType = Enums.ScheduleTypes.Year;
	
	SetDefaults();
	
	Items.GroupMonthPeriod.Visible = MonthScheduleType = Enums.MonthScheduleTypes.Period;
	If Items.GroupMonthPeriod.Visible Then
		Items.MonthEndPeriod.MinValue = MonthBeginPeriod;
	EndIf;
	
 	Items.GroupMonthFirst.Visible = MonthScheduleType = Enums.MonthScheduleTypes.First;
	Items.GroupMonthLast.Visible = MonthScheduleType = Enums.MonthScheduleTypes.Last;
	
	Items.GroupYearPeriod.Visible = YearScheduleType = Enums.YearScheduleTypes.Period;
	If Items.GroupYearPeriod.Visible Then
		Items.YearEndPeriodDay.MinValue = YearBeginPeriodDay;
	EndIf;
	
	Items.GroupYearMonths.Visible = YearScheduleType = Enums.YearScheduleTypes.Months;
	Items.GroupYearFirst.Visible = YearScheduleType = Enums.YearScheduleTypes.First;
	Items.GroupYearLast.Visible = YearScheduleType = Enums.YearScheduleTypes.Last;
EndProcedure

&AtServer
Procedure SetDefaults()
	If ScheduleType = Enums.ScheduleTypes.Day Then
		QtyOfDays = ?(ValueIsFilled(QtyOfDays), QtyOfDays, 1);
	ElsIf ScheduleType = Enums.ScheduleTypes.Month Then
		MonthScheduleType = ?(ValueIsFilled(MonthScheduleType), MonthScheduleType, Enums.MonthScheduleTypes.Period);
		MonthBeginPeriod = ?(ValueIsFilled(MonthBeginPeriod), MonthBeginPeriod, 1);
		MonthEndPeriod = ?(ValueIsFilled(MonthEndPeriod), MonthEndPeriod, 1);
		MonthFirst = ?(ValueIsFilled(MonthFirst), MonthFirst, 1);
		MonthLast = ?(ValueIsFilled(MonthLast), MonthLast, 1);
	ElsIf ScheduleType = Enums.ScheduleTypes.Year Then
		YearScheduleType = ?(ValueIsFilled(YearScheduleType), YearScheduleType, Enums.YearScheduleTypes.Period);		
		If YearScheduleType = Enums.YearScheduleTypes.First Then
			YearFirst = ?(ValueIsFilled(YearFirst), YearFirst, 1);
		ElsIf YearScheduleType = Enums.YearScheduleTypes.Last Then
			YearLast = ?(ValueIsFilled(YearLast), YearLast, 1);
		ElsIf YearScheduleType = Enums.YearScheduleTypes.Period Then
			YearBeginPeriodDay = ?(ValueIsFilled(YearBeginPeriodDay), YearBeginPeriodDay, 1);
			YearEndPeriodDay= ?(ValueIsFilled(YearEndPeriodDay), YearEndPeriodDay, 1);
			January = New ValueList;
			January.Add(1, GetMonthFromNumber(1));
			YearBeginPeriodMonth = ?(ValueIsFilled(YearBeginPeriodMonth), YearBeginPeriodMonth, January);
			YearEndPeriodMonth = ?(ValueIsFilled(YearEndPeriodMonth), YearEndPeriodMonth, January);
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure SetSchedule()
    Schedule = GetScheduleString();
    ScheduleStringPresentation = GetStringPresentationOfSchedule(Schedule);
EndProcedure

&AtServer 
Procedure SetVisibilityAndSchedule()
	SetVisibility();
	SetSchedule();
EndProcedure

// HELPER FUNCTIONS

&AtServer
Function GetScheduleStructure()
	SubstringsArray = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";");
	
	Structure = New Structure;
	Structure.Insert("ScheduleType", GetEnumValueFromString("ScheduleTypes", SubstringsArray[0]));
	
	If Structure.ScheduleType = Enums.ScheduleTypes.Day Then
		Structure.Insert("QtyOfDays", Number(SubstringsArray[1]));
	ElsIf Structure.ScheduleType = Enums.ScheduleTypes.Week Then
		Structure.Insert("DaysOfWeek", GetValueListFromString(Items.DaysOfWeek.Name, SubstringsArray[1]));
	ElsIf Structure.ScheduleType = Enums.ScheduleTypes.Month Then
		MST = GetEnumValueFromString("MonthScheduleTypes", SubstringsArray[1]);
		Structure.Insert("MonthScheduleType", MST);
		If MST = Enums.MonthScheduleTypes.Period Then
			Structure.Insert("MonthBeginPeriod", SubstringsArray[2]);
			Structure.Insert("MonthEndPeriod", SubstringsArray[3]);
		ElsIf MST = Enums.MonthScheduleTypes.First Then
			Structure.Insert("MonthFirst", SubstringsArray[2]);
		ElsIf MST = Enums.MonthScheduleTypes.Last Then
			Structure.Insert("MonthLast", SubstringsArray[2]);
		EndIf;
	ElsIf Structure.ScheduleType = Enums.ScheduleTypes.Year Then
		YST = GetEnumValueFromString("YearScheduleTypes", SubstringsArray[1]);
		Structure.Insert("YearScheduleType", YST);
		If YST = Enums.YearScheduleTypes.Months Then
			Structure.Insert("Months", GetValueListFromString(Items.Months.Name, SubstringsArray[2]));
		ElsIf YST = Enums.YearScheduleTypes.Period Then
			Structure.Insert("YearBeginPeriodDay", SubstringsArray[2]);
			Structure.Insert("YearEndPeriodDay", SubstringsArray[4]);
			
			BeginMonth = New ValueList;
			BeginMonth.Add(+SubstringsArray[3], GetMonthFromNumber(SubstringsArray[3]));
			Structure.Insert("YearBeginPeriodMonth", BeginMonth);
			
			EndMonth = New ValueList;
			EndMonth.Add(+SubstringsArray[5], GetMonthFromNumber(SubstringsArray[5]));
			Structure.Insert("YearEndPeriodMonth", EndMonth);
			
		ElsIf YST = Enums.YearScheduleTypes.First Then
			Structure.Insert("YearFirst", SubstringsArray[2]);
		ElsIf YST = Enums.YearScheduleTypes.Last Then
			Structure.Insert("YearLast", SubstringsArray[2]);
		EndIf;
	EndIf;
	
	Return Structure;
EndFunction

&AtServer
Function GetScheduleString()
	Array = New Array;
	Array.Add(GetStringFromEnumValue("ScheduleTypes", ScheduleType));
	
	If ScheduleType = Enums.ScheduleTypes.Day Then
		Array.Add(QtyOfDays);
	ElsIf ScheduleType = Enums.ScheduleTypes.Week Then
		Array.Add(GetStringFromValueList(DaysOfWeek));
	ElsIf ScheduleType = Enums.ScheduleTypes.Month Then
		Array.Add(GetStringFromEnumValue("MonthScheduleTypes", MonthScheduleType));
		If MonthScheduleType = Enums.MonthScheduleTypes.Period Then
			Array.Add(MonthBeginPeriod);
			Array.Add(MonthEndPeriod);
		ElsIf MonthScheduleType = Enums.MonthScheduleTypes.First Then
			Array.Add(MonthFirst);
		ElsIf MonthScheduleType = Enums.MonthScheduleTypes.Last Then
			Array.Add(MonthLast);
		EndIf;
	ElsIf ScheduleType = Enums.ScheduleTypes.Year Then
		Array.Add(GetStringFromEnumValue("YearScheduleTypes", YearScheduleType));
		If YearScheduleType = Enums.YearScheduleTypes.Months Then
			Array.Add(GetStringFromValueList(Months));
		ElsIf YearScheduleType = Enums.YearScheduleTypes.Period Then
			Array.Add(YearBeginPeriodDay);
			Array.Add(YearBeginPeriodMonth[0].Value);
			Array.Add(YearEndPeriodDay);
			Array.Add(YearEndPeriodMonth[0].Value);
		ElsIf YearScheduleType = Enums.YearScheduleTypes.First Then
			Array.Add(YearFirst);
		ElsIf YearScheduleType = Enums.YearScheduleTypes.Last Then
			Array.Add(YearLast);
		EndIf;
	EndIf;
	
	ScheduleString = СтроковыеФункцииКлиентСервер.ПолучитьСтрокуИзМассиваПодстрок(Array, ";");
	
	Return ScheduleString;
EndFunction

&AtServerNoContext
Function GetStringFromEnumValue(Enum, Value)
	IndexOfValue = Enums[Enum].IndexOf(Value);
	Return Metadata.Enums[Enum].EnumValues[IndexOfValue].Name;
EndFunction

&AtServerNoContext
Function GetValueListFromString(ValueListName, String)
	SubstringsArray = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(String, ",");
	
	If ValueListName = "DaysOfWeek" Then
		ValueList = GetEmptyDaysOfWeek();
	ElsIf ValueListName = "Months" Then
		ValueList = GetEmptyMonths();
	EndIf;

	For Each Line In ValueList Do
		Index = ValueList.IndexOf(Line);
		Line.Check = Boolean(Number(SubstringsArray[Index]));
	EndDo;
	Return ValueList;
EndFunction

&AtServerNoContext
Function GetStringFromValueList(ValueList)
	Array = New Array;
	For Each Line In ValueList Do
		Array.Add(?(Line.Check, "1", "0"));
	EndDo;
	ValueListString = СтроковыеФункцииКлиентСервер.ПолучитьСтрокуИзМассиваПодстрок(Array, ",");
	Return ValueListString;
EndFunction

&AtServerNoContext
Function GetEmptyDaysOfWeek()
	ValueList = New ValueList;
	For Day = 1 To 7 Do
		ValueList.Add(Title(GetDayOfWeekFromNumber(Day)));
	EndDo;
	Return ValueList
EndFunction

&AtServerNoContext
Function GetEmptyMonths(StartMonth = 1)
	ValueList = New ValueList;
	For Month = StartMonth To 12 Do
		ValueList.Add(Month, GetMonthFromNumber(Month), False);
	EndDo;
	Return ValueList;
EndFunction

