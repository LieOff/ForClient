
Function GetStringPresentationOfSchedule(Schedule) Export
	
	Result = NStr("en = 'Questionnaire will be displayed '; ru = 'Анкета будет показываться '");
	SubstringsArray = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";");
	If SubstringsArray[0] = "Day" Then
		EachDay = ?(+Right(SubstringsArray[1], 1) = 1, NStr("en = 'every '; ru = 'каждый '"), NStr("en = 'every '; ru = 'каждые '"));
		Days = СтроковыеФункцииКлиентСервер.ЧислоЦифрамиПредметИсчисленияПрописью(+SubstringsArray[1], NStr("en='day,day,days';ru='день,дня,дней';cz='day,day,days'"));
		If +SubstringsArray[1] = 1 Then
			Days = NStr("en='day';ru='день';cz='day'");
		Else
			Days = СтроковыеФункцииКлиентСервер.ЧислоЦифрамиПредметИсчисленияПрописью(+SubstringsArray[1], NStr("en='day,day,days';ru='день,дня,дней';cz='day,day,days'"));
		EndIf;
		Result = Result + EachDay + Days;
	ElsIf SubstringsArray[0] = "Week" Then
		On = NStr("en = 'in '; ru = 'в '");
		DaysOfWeekArray = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(SubstringsArray[1], ",");
		DaysOfWeekString = "";
		For Day = 1 To 7 Do
			If +DaysOfWeekArray[Day - 1] = 1 Then        // Если отметка у дня недели стоит
				DayOfWeek = GetDayOfWeekFromNumber(Day); // Берем текстовое представление дня недели по номеру дня недели
				If Day = 3 Or Day = 5 Or Day = 6 Then    // Склоняем среду, пятницу и субботу
					DayOfWeek = Left(DayOfWeek, StrLen(DayOfWeek) - 1) + "у";
				Endif;
				DaysOfWeekString = DaysOfWeekString + DayOfWeek + ", ";
			EndIf;
		EndDo;
		DaysOfWeekString = Left(DaysOfWeekString, StrLen(DaysOfWeekString) - 2); // Убираем запятую в конце списка дней недель
		Result = Result + On + DaysOfWeekString;
	ElsIf SubstringsArray[0] = "Month" Then
		If SubstringsArray[1] = "Period" Then
			Result = Result + NStr("en = 'from '; ru = 'c '") + SubstringsArray[2] + NStr("en = ' to '; ru = ' по '") + SubstringsArray[3] + NStr("en = ' day of each month'; ru = ' день каждого месяца'");
		Else			
			If SubstringsArray[1] = "First" Then
				FirstLast = ?(+SubstringsArray[2] = 1, NStr("en = ' first '; ru = ' первый '"), NStr("en = ' first '; ru = ' первые '"));
			ElsIf SubstringsArray[1] = "Last" Then			
				FirstLast = ?(+SubstringsArray[2] = 1, NStr("en = ' last '; ru = ' последний '"), NStr("en = ' last '; ru = ' последние '"));
			EndIf;		
			Days = СтроковыеФункцииКлиентСервер.ЧислоЦифрамиПредметИсчисленияПрописью(+SubstringsArray[2], NStr("en='day,day,days';ru='день,дня,дней';cz='day,day,days'"));
			Month = NStr("en = ' of the month '; ru = ' месяца '");
			Result = Result + FirstLast + Days + Month;
		EndIf;
	ElsIf SubstringsArray[0] = "Year" Then
		If SubstringsArray[1] = "Months" Then
			EachMonth = NStr("en = 'every '; ru = 'каждый '");
			MonthsArray = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(SubstringsArray[2], ",");
			MonthsString = "";
			For Month = 1  To 12 Do
				If +MonthsArray[Month - 1] = 1 Then
					MonthString = Lower(GetMonthFromNumber(Month));
					MonthsString = MonthsString + MonthString + ", ";
				EndIf;
			EndDo;
			MonthsString = Left(MonthsString, StrLen(MonthsString) - 2);
			Result = Result + EachMonth + MonthsString;
		ElsIf SubstringsArray[1] = "Period" Then
			Result = Result + NStr("en = 'from '; ru = 'c '") + GetNumberWithMonth(+SubstringsArray[2], +SubstringsArray[3]) + NStr("en = ' to '; ru = ' по '") + GetNumberWithMonth(+SubstringsArray[4], +SubstringsArray[5]);
		Else
			If SubstringsArray[1] = "First" Then
				FirstLast = ?(+SubstringsArray[2] = 1, NStr("en = ' first '; ru = ' первый '"), NStr("en = ' first '; ru = ' первые '"));
			ElsIf SubstringsArray[1] = "Last" Then
				FirstLast = ?(+SubstringsArray[2] = 1, NStr("en = ' last '; ru = ' последний '"), NStr("en = ' last '; ru = ' последние '"));
			EndIf;
			Days = СтроковыеФункцииКлиентСервер.ЧислоЦифрамиПредметИсчисленияПрописью(+SubstringsArray[2], NStr("en='day,day,days';ru='день,дня,дней';cz='day,day,days'"));
			Year = NStr("en = ' of the year '; ru = ' года '");
			Result = Result + FirstLast + Days + Year;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Function GetDayOfWeekFromNumber(Number) Export
	Return Format(Date(2014, 09, Number), NStr("en='L=en; DF=дддд';ru='L=ru; DF=дддд';cz='L=en; DF=дддд'"));
EndFunction

Function GetMonthFromNumber(Number) Export
	Return Format(Date(2014, Number, 1), NStr("en='L=en; DF=MMMM';ru='L=ru; DF=MMMM';cz='L=en; DF=MMMM'"));         
EndFunction

Function GetNumberWithMonth(Number, Month)
	
	MonthString = GetMonthFromNumber(Month);
	
	If InfoBaseUsers.CurrentUser().Language = Metadata.Languages.Русский Then
	
		If Month = 3 Or Month = 8 Then // Если март или август
			MonthString = Lower(MonthString) + "а";		
		Else
			MonthString = Lower(Left(MonthString, StrLen(MonthString) - 1) + "я");		
		EndIf;
		
	EndIf;
	
	Result = СтроковыеФункцииКлиентСервер.ЧислоЦифрамиПредметИсчисленияПрописью(Number, MonthString + "," + MonthString + "," + MonthString);
	
	Return Result;
	
EndFunction

Function GetEnumValueFromString(Enum, String) Export
	Return Enums[Enum][String];
EndFunction