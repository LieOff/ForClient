////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ 

Процедура ОбработкаЗаполнения(ДанныеЗаполнения, СтандартнаяОбработка)

	Если НЕ ЗначениеЗаполнено(DateFrom)  Тогда
		DateFrom = BegOfWeek(ТекущаяДатаСеанса());
		DateTo   = EndOfWeek(DateFrom);
	КонецЕсли;
	Если НЕ ЗначениеЗаполнено(Year)  Тогда
		Year     = GetYear(CurrentDate());
	КонецЕсли;
	Если НЕ ЗначениеЗаполнено(WeekNumber)  Тогда
		WeekNumber = GetWeekOfYear(CurrentDate());
	КонецЕсли;
	
	Owner = SessionParameters.CurrentUser;
	
КонецПроцедуры


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

Function BeginOfFirstWeek(Year) Export
	
	If GetWeekOfYear(Date(Year(Year), 01, 01)) = 1 Then
		
		Return BegOfWeek(Year);
		
	Else
		
		Return BegOfWeek(Date(Year(Year), 01, 04));
		
	EndIf;
	
EndFunction

Procedure Posting(Cancel, PostingMode)
	
	if Cancel  Then
		Return;
	EndIf;

EndProcedure


