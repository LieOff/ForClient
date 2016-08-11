
#Region CommonProcessors

Function CheckEntity(Source, SourceRef) Export 
	
	Source.AdditionalProperties.Insert("FillDefaultValues", True);
	
	If TypeOf(Source) = Type("DocumentObject.Order") Then
		
		Source = SetStatus(Source);
		
	EndIf;
	
	If TypeOf(Source) = Type("CatalogObject.Outlet") Then
		
		Source = ClearEmptyRows(Source);
		
	EndIf;
	
	If TypeOf(Source) = Type("DocumentObject.Visit") Then
	
		// Очистить результаты анкетирования
		If ValueIsFilled(Source.Ref) Then 
		
			Query = New Query;
			Query.Text = 
				"SELECT ALLOWED
				|	QuestioningResults.Questionnaire,
				|	QuestioningResults.Visit,
				|	QuestioningResults.Outlet,
				|	QuestioningResults.SR,
				|	QuestioningResults.Date
				|FROM
				|	InformationRegister.QuestioningResults AS QuestioningResults
				|WHERE
				|	QuestioningResults.Visit = &Visit";
			
			Query.SetParameter("Visit", Source.Ref);
			
			QueryResult = Query.Execute();
			
			Selection = QueryResult.Select();
			
			RecordManager = InformationRegisters.QuestioningResults.CreateRecordManager();
			
			While Selection.Next() Do
				
				FillPropertyValues(RecordManager, Selection);
				
				RecordManager.Read();
				
				RecordManager.Delete();
				
			EndDo;
			
		EndIf;
		
		QuestionnaireTable = New ValueTable;
		QuestionnaireTable.Columns.Add("Questionnaire");
		
		For Each Str In Source.Questions Do 
			
			If ValueIsFilled(Str.Questionnaire) And ValueIsFilled(Str.AnswerDate) Then 
				
				Ins 				= QuestionnaireTable.Add();
				Ins.Questionnaire 	= Str.Questionnaire;
				
				If Str.Questionnaire.Single Then
					
					RecordManager 				= InformationRegisters.AnsweredQuestions.CreateRecordManager();
					RecordManager.Visit 		= SourceRef;
					RecordManager.Questionaire 	= Str.Questionnaire;
					RecordManager.Outlet 		= Source.Outlet;
					RecordManager.Question 		= Str.Question;
					RecordManager.Answer 		= Str.Answer;
					RecordManager.AnswerDate 	= Str.AnswerDate;
					
					If Str.Question.AnswerType = Enums.DataType.Snapshot And ValueIsFilled(Str.Answer) Then
						
						RecordManager.UploadSnapshot	= True;
						RecordManager.Snapshot			= New UUID(Str.Answer);
						
					EndIf;
					
					RecordManager.Write();
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		For Each Str In Source.SKUs Do 
			
			If ValueIsFilled(Str.Questionnaire) And ValueIsFilled(Str.AnswerDate) Then 
				
				Ins 				= QuestionnaireTable.Add();
				Ins.Questionnaire 	= Str.Questionnaire;
				
				If Str.Questionnaire.Single Then
					
					RecordManager 				= InformationRegisters.AnsweredQuestions.CreateRecordManager();
					RecordManager.Visit 		= SourceRef;
					RecordManager.Questionaire 	= Str.Questionnaire;
					RecordManager.Outlet 		= Source.Outlet;
					RecordManager.Question 		= Str.Question;
					RecordManager.SKU			= Str.SKU;
					RecordManager.Answer 		= Str.Answer;
					RecordManager.AnswerDate 	= Str.AnswerDate;
					
					If Str.Question.AnswerType = Enums.DataType.Snapshot And ValueIsFilled(Str.Answer) Then
						
						RecordManager.UploadSnapshot	= True;
						RecordManager.Snapshot			= New UUID(Str.Answer);
						
					EndIf;
					
					RecordManager.Write();
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		QuestionnaireTable.GroupBy("Questionnaire");
		
		For Each QuestionnaireElement In QuestionnaireTable Do 
			
			RecordManager 				= InformationRegisters.QuestioningResults.CreateRecordManager();		
			RecordManager.Questionnaire = QuestionnaireElement.Questionnaire;
			RecordManager.Visit 		= SourceRef;
			RecordManager.Outlet 		= Source.Outlet;
			RecordManager.SR 			= Source.SR;
			RecordManager.Date 			= Source.Date;
			
			RecordManager.Write();
			
		EndDo;
		
	EndIf;
	
	Return Source;
	
EndFunction

#EndRegion

#Region AnsweredQuestions 

Function ProcessAnsweredQuestionsSnapshots(Connection, Path) Export 
	
	// Получить снимки которые можно удалить с сервера
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
		|	bitmobile_ХранилищеФайлов.ФайлЗаблокирован,
		|	AnsweredQuestions.Snapshot
		|INTO ProcessedFiles
		|FROM
		|	InformationRegister.bitmobile_ХранилищеФайлов AS bitmobile_ХранилищеФайлов
		|		LEFT JOIN InformationRegister.AnsweredQuestions AS AnsweredQuestions
		|		ON bitmobile_ХранилищеФайлов.Объект = AnsweredQuestions.Outlet
		|			AND bitmobile_ХранилищеФайлов.ИмяФайла = AnsweredQuestions.Snapshot
		|WHERE
		|	bitmobile_ХранилищеФайлов.ФайлЗаблокирован = TRUE
		|	AND VALUETYPE(bitmobile_ХранилищеФайлов.Объект) = TYPE(Catalog.Outlet)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProcessedFiles.Объект,
		|	ProcessedFiles.НаправлениеСинхронизации,
		|	ProcessedFiles.Действие,
		|	ProcessedFiles.ИмяФайла,
		|	ProcessedFiles.ПолноеИмяФайла,
		|	ProcessedFiles.Расширение,
		|	ProcessedFiles.Хранилище,
		|	ProcessedFiles.ФайлЗаблокирован
		|FROM
		|	ProcessedFiles AS ProcessedFiles
		|WHERE
		|	ProcessedFiles.Snapshot IS NULL ";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		RecordManagerDelete = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
		
		FillPropertyValues(RecordManagerDelete, Selection);
		
		RecordManagerDelete.Read();
		
		If RecordManagerDelete.Selected() Then 
			
			RecordManagerDelete.Действие = Enums.bitmobile_ДействияПриСинхронизации.УдалитьФайл;
			
			RecordManagerDelete.Write();
			
		EndIf;
		
	EndDo;
	
	// Получить невыгруженные снимки ответов
	Query = New Query;
	Query.Text = 
		"SELECT
		|	AnsweredQuestions.Questionaire,
		|	AnsweredQuestions.Outlet,
		|	AnsweredQuestions.Question,
		|	AnsweredQuestions.SKU,
		|	AnsweredQuestions.Answer,
		|	AnsweredQuestions.AnswerDate,
		|	AnsweredQuestions.Visit,
		|	AnsweredQuestions.UploadSnapshot,
		|	AnsweredQuestions.Snapshot,
		|	bitmobile_ХранилищеФайлов.Расширение,
		|	bitmobile_ХранилищеФайлов.ПолноеИмяФайла,
		|	bitmobile_ХранилищеФайлов.ИмяФайла
		|FROM
		|	InformationRegister.AnsweredQuestions AS AnsweredQuestions
		|		LEFT JOIN InformationRegister.bitmobile_ХранилищеФайлов AS bitmobile_ХранилищеФайлов
		|		ON AnsweredQuestions.Snapshot = bitmobile_ХранилищеФайлов.ИмяФайла
		|			AND (bitmobile_ХранилищеФайлов.НаправлениеСинхронизации = VALUE(Enum.bitmobile_НаправленияСинхронизации.Private))
		|WHERE
		|	AnsweredQuestions.UploadSnapshot = TRUE";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.ИмяФайла) Then
			
			Try
				
				// Получить тело файла
				TempFile = GetTempFileName(Selection.Расширение);
				
				Connection.Get(Path + Selection.ПолноеИмяФайла, TempFile);
				
				BinaryData = New BinaryData(TempFile);
					
				RecordManagerF							= InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordManager();
				RecordManagerF.Объект					= Selection.Outlet;
				RecordManagerF.НаправлениеСинхронизации	= Enums.bitmobile_НаправленияСинхронизации.Shared;
				RecordManagerF.Действие					= Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл;
				RecordManagerF.ПолноеИмяФайла			= "/shared/Catalog.Outlet/" + Selection.Outlet.UUID() + 
														  "/" + Selection.ИмяФайла + Lower(Selection.Расширение);
				RecordManagerF.ИмяФайла					= Selection.ИмяФайла;
				RecordManagerF.Расширение				= Selection.Расширение;
				RecordManagerF.Хранилище				= New ValueStorage(BinaryData);
				RecordManagerF.ФайлЗаблокирован			= True;
				
				RecordManagerF.Write();
				
				RecordManagerAQ = InformationRegisters.AnsweredQuestions.CreateRecordManager();
				
				FillPropertyValues(RecordManagerAQ, Selection);
				
				RecordManagerAQ.UploadSnapshot = False;
				
				RecordManagerAQ.Write();
				
			Except
				
				
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndFunction

#EndRegion

#Region Document_Order 

Function SetStatus(Source) 

    If Source.Status=Enums.OrderSatus.New or Source.Status=Enums.OrderSatus.EmptyRef() Then
		
		Source.Status=Enums.OrderSatus.Sent;
		
	EndIf;
	
	For Each Row In Source.SKUs Do
		
		Row.Amount = Row.Total*Row.Qty;
		
	EndDo;
        
    Return Source;

EndFunction

#EndRegion

#Region Catalog_Outlet

Function ClearEmptyRows(Source)

	For Each Row In Source.Parameters Do
		
		If Row.Value = Undefined Or Row.Value = "" Then
			
			Source.Parameters.Delete(Row.LineNumber - 1);
			
		EndIf;
		
	EndDo;
	
	Return Source;

EndFunction

#EndRegion

#Region Document_Questionnaire

#Region CalculateStatuses

Procedure SetStatusOfQuestionnaires() Export
	
	// В первом запросе выбираются все анкеты со статусом "Готова" у которых
	// дата начала действия анкеты меньше текущей даты. У этих анкет новый статус
	// будет "Активна".
	Query = New Query(
	"SELECT ALLOWED
	|	Questionnaire.Ref AS Questionnaire,
	|	VALUE(Enum.QuestionnareStatus.Active) AS NewStatus
	|FROM
	|	Document.Questionnaire AS Questionnaire
	|WHERE
	|	Questionnaire.Status = VALUE(Enum.QuestionnareStatus.Ready)
	|	AND Questionnaire.BeginDate <= &CurrentDate");
	
	Query.SetParameter("CurrentDate", BegOfDay(CurrentDate()));
	
	QueryResult = Query.Execute().Unload();
	
	For Each Line In QueryResult Do
		
		QuestionnaireObject = Line.Questionnaire.GetObject();
		QuestionnaireObject.Status = Line.NewStatus;
		QuestionnaireObject.Write();
		
	EndDo;
	
	// Во втором запросе выбираются все анкеты со статусом "Активна" у 
	// которых дата конца действия анкеты меньше текущей даты. У этих анкет новый
	// статус будет "Неактивна".
	Query.Text = 
	"SELECT ALLOWED
	|	Questionnaire.Ref AS Questionnaire,
	|	VALUE(Enum.QuestionnareStatus.Inactive) AS NewStatus
	|FROM
	|	Document.Questionnaire AS Questionnaire
	|WHERE
	|	Questionnaire.Status = VALUE(Enum.QuestionnareStatus.Active)
	|	AND Questionnaire.EndDate < &CurrentDate
	|	AND Questionnaire.EndDate <> DATETIME(1, 1, 1)";
	
		QueryResult = Query.Execute().Unload();
	
	For Each Line In QueryResult Do
		
		QuestionnaireObject = Line.Questionnaire.GetObject();
		QuestionnaireObject.Status = Line.NewStatus;
		QuestionnaireObject.Write();
		
	EndDo;
		
EndProcedure

#EndRegion

#Region CalculateSRs

Procedure CheckSRsInQuestionnaire() Export 
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Questionnaire.Ref AS Questionnaire
		|FROM
		|	Document.Questionnaire AS Questionnaire
		|WHERE
		|	Questionnaire.Status = VALUE(Enum.QuestionnareStatus.Active)";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		CurrentSRs	= Documents.Questionnaire.SelectSRs(Selection.Questionnaire.Selectors.Unload(), Selection.Questionnaire.Selectors.Unload(New Structure("Selector", "Catalog_Positions")));
		DocSRs		= Selection.Questionnaire.SRs.Unload();
		
		If Not CountOfDifference(DocSRs, CurrentSRs) = 0 Then 
			
			QuestObject = Selection.Questionnaire.GetObject();
			
			QuestObject.SRs.Load(CurrentSRs);
			
			QuestObject.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function CountOfDifference(DocSRs, CurrentSRs)
	
	TableAllRecords = DocSRs.Copy();
	
	For Each Str In CurrentSRs Do FillPropertyValues(TableAllRecords.Add(), Str) EndDo;
	
	TableAllRecords.Columns.Add("Count", New TypeDescription("Number"));
	TableAllRecords.FillValues(1, "Count");
	
	TableAllRecords.GroupBy("SR", "Count");
	
	Result = TableAllRecords.Copy(New Structure("Count", 1));
	
	Return Result.Count();
	
EndFunction

#EndRegion 

#Region CalculatePeriodicity

Procedure ActualizePeriodicity() Export

	PeriodicityTable = GetPeriodicityTable();

	BeginOfCurrentDay = BegOfDay(CurrentDate());
	
	For Each Row In PeriodicityTable Do
		
		// Вычисляем начало периода расчета для текущего соответствия анкета-ТТ. 
		// Если начало периода действия анкеты больше текущей даты - тогда начало
		// периода расчета = начало периода действия анкеты, иначе текущая дата
		BeginDate = ?(Row.Questionnaire.BeginDate > BeginOfCurrentDay, BeginDate, BeginOfCurrentDay); 
		
		// Вычисляем конец периода расчета для текущего соответствия анкета-ТТ. 
		Day = 60 * 60 * 24;             
		Week = Day * 7;               
		PlusWeek = BeginOfCurrentDay + Week;  
		
		// В случае когда конец периода действия текущей анкеты не задан считаем 
		// на неделю вперед от текущей даты, иначе если дата конца действия анкеты
		// меньше чем текущая дата плюс неделя, тогда считаем до конца действия 
		// анкеты, иначе до текущей даты плюс неделя.
		EndDate = ?(ValueIsFilled(Row.Questionnaire.EndDate), ?(Row.Questionnaire.EndDate > PlusWeek, PlusWeek, Row.Questionnaire.EndDate), PlusWeek);
		
		// Для недельного и годового расписания по месяцам нам нужно понимать в 
		// какие дни недели и месяцы года нам нужно показывать анкеты. Для этого
		// выдергиваем из расписания те дни недели и месяцы года у которых стоят
		// галки в расписании.
		Schedule = Row.Questionnaire.Schedule;
		
		If Row.Periodicity = Enums.ScheduleTypes.Week Then
			
			DaysOfWeek = GetDaysOfWeek(Schedule);
			
		ElsIf Row.Periodicity = Enums.ScheduleTypes.Year Then
			
			YearScheduleType = GetEnumValueFromString("YearScheduleTypes", GetPeriodicityTypeString(Schedule));
			
			If YearScheduleType = Enums.YearScheduleTypes.Months Then
				
				MonthsOfYear = GetMonthsOfYear(Schedule);
				
			EndIf;
			
		EndIf;
		
		// В цикле проверяем каждый день с начала периода расчета до конца периода 
		// расчета нужно ли нам для данной торговой точки выводить данную анкету
		CurrentDate = BeginDate;
		
		While CurrentDate <= EndDate Do
			
			Write = False;
			
			If Row.Periodicity = Enums.ScheduleTypes.Month Then
				
				MonthScheduleType = GetMonthScheduleType(Schedule);
				
				If MonthScheduleType = Enums.MonthScheduleTypes.Period Then
					
					BeginPeriod = GetMonthBeginPeriod(Schedule);
					EndPeriod = GetMonthEndPeriod(Schedule);
					
				ElsIf MonthScheduleType = Enums.MonthScheduleTypes.First Then
					
					BeginPeriod = 1;
					EndPeriod = GetMonthFirstLastNumber(Schedule);
					
				ElsIf MonthScheduleType = Enums.MonthScheduleTypes.Last Then
					
					EndPeriod = Day(EndOfMonth(CurrentDate));
					BeginPeriod = EndPeriod - GetMonthFirstLastNumber(Schedule) + 1;
					
				EndIf;
				
			ElsIf Row.Periodicity = Enums.ScheduleTypes.Year Then
				
				YearScheduleType = GetEnumValueFromString("YearScheduleTypes", GetPeriodicityTypeString(Schedule));
				
				If YearScheduleType = Enums.YearScheduleTypes.First Then
					
					BeginPeriod = 1;
					EndPeriod = GetYearFirstLastNumber(Schedule);
					
				ElsIf YearScheduleType = Enums.YearScheduleTypes.Last Then
					
					EndPeriod = DayOfYear(EndOfYear(CurrentDate));
					BeginPeriod = EndPeriod - GetYearFirstLastNumber(Schedule) + 1;
					
				ElsIf YearScheduleType = Enums.YearScheduleTypes.Period Then
					
					BeginPeriodDay = GetYearBeginPeriodDay(Schedule);
					BeginPeriodMonth = GetYearBeginPeriodMonth(Schedule);
					
					EndPeriodDay = GetYearEndPeriodDay(Schedule);
					EndPeriodMonth = GetYearEndPeriodMonth(Schedule);
					
					Year = Year(CurrentDate);
					
					BeginPeriod = DayOfYear(Date(Year, BeginPeriodMonth, BeginPeriodDay));
					EndPeriod = DayOfYear(Date(Year, EndPeriodMonth, EndPeriodDay));
					
				EndIf;
				
			EndIf;			
			
			If Row.Periodicity = Enums.ScheduleTypes.Day Then
				
				BeginSchedulePeriod = ?(Row.Questionnaire.Single, CurrentDate, '00010101');
				EndSchedulePeriod = ?(Row.Questionnaire.Single, CurrentDate, '00010101');
				Difference = (BegOfDay(CurrentDate) - BegOfDay(Row.Questionnaire.BeginDate)) / Day;
				RepeatEvery = GetDays(Schedule);
				
				If Difference % RepeatEvery = 0 Then
					
					Write = True;
					
				EndIf;
				
			ElsIf Row.Periodicity = Enums.ScheduleTypes.Week Then
				
				If Row.Questionnaire.Single Then
					
					BeginSchedulePeriod = ?(Row.Questionnaire.FillPeriod = Enums.QuestionsSaveIntervals.ScheduleInterval, BegOfWeek(CurrentDate), Row.Questionnaire.BeginDate);
					EndSchedulePeriod = ?(Row.Questionnaire.FillPeriod = Enums.QuestionsSaveIntervals.ScheduleInterval, EndOfWeek(CurrentDate), Row.Questionnaire.EndDate);
					
				Else
					
					BeginSchedulePeriod = '00010101';
					EndSchedulePeriod = '00010101';
					
				EndIf;
	
				WeekDayNumber = WeekDay(CurrentDate) - 1;
				
				If DaysOfWeek[WeekDayNumber] = "1" Then
					
					Write = True;
					
				EndIf;
				
			ElsIf Row.Periodicity = Enums.ScheduleTypes.Month Then
				
				If Row.Questionnaire.Single Then
					
					BeginSchedulePeriod = ?(Row.Questionnaire.FillPeriod = Enums.QuestionsSaveIntervals.ScheduleInterval, BegOfMonth(CurrentDate), Row.Questionnaire.BeginDate);
					EndSchedulePeriod = ?(Row.Questionnaire.FillPeriod = Enums.QuestionsSaveIntervals.ScheduleInterval, EndOfMonth(CurrentDate), Row.Questionnaire.EndDate);
					
				Else
					
					BeginSchedulePeriod = '00010101';
					EndSchedulePeriod = '00010101';
					
				EndIf;
				MonthDay = Day(CurrentDate);
				
				If MonthDay >= BeginPeriod AND MonthDay <= EndPeriod Then
					
					Write = True;
					
				EndIf;
				
			ElsIf Row.Periodicity = Enums.ScheduleTypes.Year Then
				
				If Row.Questionnaire.Single Then
					
					BeginSchedulePeriod = ?(Row.Questionnaire.FillPeriod = Enums.QuestionsSaveIntervals.ScheduleInterval, BegOfYear(CurrentDate), Row.Questionnaire.BeginDate);
					EndSchedulePeriod = ?(Row.Questionnaire.Single, EndOfYear(CurrentDate), Row.Questionnaire.EndDate);
					
				Else
					
					BeginSchedulePeriod = '00010101';
					EndSchedulePeriod = '00010101';
					
				EndIf;
				
				YearScheduleType = GetEnumValueFromString("YearScheduleTypes", GetPeriodicityTypeString(Schedule));
				
				If YearScheduleType = Enums.YearScheduleTypes.Months Then
					
					MonthNumber = Month(CurrentDate) - 1;
					
					If MonthsOfYear[MonthNumber] = "1" Then
						
						Write = True;
						
					EndIf;
					
				ElsIf YearScheduleType = Enums.YearScheduleTypes.First 
					  OR YearScheduleType = Enums.YearScheduleTypes.Last 
					  OR YearScheduleType = Enums.YearScheduleTypes.Period Then
					  
					YearDay = DayOfYear(CurrentDate);
					
					If YearDay >= BeginPeriod AND YearDay <= EndPeriod Then
						
						Write = True;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If Write = True Then
				
				ResultRow = InformationRegisters.QuestionnairesSchedule.CreateRecordManager();
				ResultRow.Questionnaire = Row.Questionnaire;
				ResultRow.Date = CurrentDate;
				ResultRow.BeginAnswerPeriod = BeginSchedulePeriod;
				ResultRow.EndAnswerPeriod = EndSchedulePeriod;
				
				ResultRow.Read();
				
				If Not ResultRow.Selected() Then 
					
					ResultRow.Questionnaire = Row.Questionnaire;
					ResultRow.Date = CurrentDate;
					ResultRow.BeginAnswerPeriod = BeginSchedulePeriod;
					ResultRow.EndAnswerPeriod = EndSchedulePeriod;
					
					ResultRow.Write();
					
				EndIf;
				
			EndIf;
			
			CurrentDate = CurrentDate + Day;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function GetPeriodicityTable()
	
	Questionnaires 		= GetQuestionnaires();
	PeriodicityTable 	= GetEmptyPeriodicityTable();
		
	For Each Questionnaire In Questionnaires Do
		
		ResultRow = PeriodicityTable.Add();
		ResultRow.Questionnaire = Questionnaire.Ref;
		ResultRow.Periodicity = GetPeriodicity(Questionnaire.Ref.Schedule);
		
	EndDo;
	
	Return PeriodicityTable;
	
EndFunction

Function GetEmptyPeriodicityTable()
    
    ValueTable = New ValueTable;
    ValueTable.Columns.Add("Questionnaire");
	ValueTable.Columns.Add("Periodicity");
	
	Return ValueTable;

EndFunction

Function GetPeriodicity(Schedule)
	
	PeriodicityString = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[0];
	
	Return GetEnumValueFromString("ScheduleTypes", PeriodicityString);
	
EndFunction

Function GetQuestionnaires()
	
	Query = New Query(
	"SELECT ALLOWED
	|	Questionnaire.Ref AS Ref
	|FROM
	|	Document.Questionnaire AS Questionnaire
	|WHERE
	|	Questionnaire.Status = VALUE(Enum.QuestionnareStatus.Active)");
	QueryResult = Query.Execute();
	Questionnaires = QueryResult.Unload();
	
	Return Questionnaires;
	
EndFunction

Function GetPeriodicityTypeString(Schedule)
	
	Return ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[1];
	
EndFunction

Function GetDays(Schedule)
	DaysString = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[1];
	Return Number(DaysString);
EndFunction

Function GetDaysOfWeek(Schedule)
	DaysOfWeekString = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[1];
	DaysOfWeekArray = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(DaysOfWeekString, ",");
	Return DaysOfWeekArray;
EndFunction

Function GetMonthsOfYear(Schedule)
	MonthsOfYearString = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[2];
	MonthsOfYearArray = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(MonthsOfYearString, ",");
	Return MonthsOfYearArray;
EndFunction

Function GetMonthScheduleType(Schedule)
	MonthScheduleTypeString = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[1];
	Return GetEnumValueFromString("MonthScheduleTypes", MonthScheduleTypeString);
EndFunction

Function GetMonthBeginPeriod(Schedule)
	MonthBeginPeriod = Number(ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[2]);
	Return MonthBeginPeriod;
EndFunction

Function GetMonthEndPeriod(Schedule)
	MonthEndPeriod = Number(ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[3]);
	Return MonthEndPeriod;
EndFunction

Function GetMonthFirstLastNumber(Schedule)
	MonthFirstLastNumber = Number(Общегоназначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[2]);
	Return MonthFirstLastNumber;
EndFunction

Function GetYearFirstLastNumber(Schedule)
	YearFirstLastNumber = Number(ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[2]);
	Return YearFirstLastNumber;
EndFunction

Function GetYearBeginPeriodDay(Schedule)
	Return ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[2];
EndFunction

Function GetYearBeginPeriodMonth(Schedule)
	Return ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[3];
EndFunction

Function GetYearEndPeriodDay(Schedule)
	Return ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[4];
EndFunction

Function GetYearEndPeriodMonth(Schedule)
	Return ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(Schedule, ";")[5];
EndFunction

#EndRegion

#EndRegion

#Region Document_AssortmentMatrix

Procedure SetStatusOfAssortmentMatrix(Date) Export
	
	Query = New Query(
	"SELECT ALLOWED
	|	AssortmentMatrix.Ref AS AM,
	|	AssortmentMatrix.PeriodUUID AS AMPeriodUUID,
	|	AssortmentMatrix.Status AS AMStatus,
	|	AssortmentMatrix.BeginDate AS AMBeginDate,
	|	AssortmentMatrix.EndDate AS AMEndDate
	|INTO AMs
	|FROM
	|	Catalog.AssortmentMatrix AS AssortmentMatrix
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AssortmentMatrixPeriods.Ref AS AM,
	|	AssortmentMatrixPeriods.BeginDate AS CurrentPeriodBeginDate,
	|	AssortmentMatrixPeriods.EndDate AS CurrentPeriodEndDate,
	|	AssortmentMatrixPeriods.UUID AS CurrentPeriodUUID
	|INTO CurrentPeriods
	|FROM
	|	Catalog.AssortmentMatrix.Periods AS AssortmentMatrixPeriods
	|WHERE
	|	BEGINOFPERIOD(AssortmentMatrixPeriods.BeginDate, DAY) <= &CurrentDate
	|	AND CASE
	|			WHEN AssortmentMatrixPeriods.EndDate = DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN DATETIME(2999, 12, 31, 23, 59, 59)
	|			ELSE ENDOFPERIOD(AssortmentMatrixPeriods.EndDate, DAY)
	|		END >= &CurrentDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AMs.AM,
	|	AMs.AMPeriodUUID,
	|	AMs.AMStatus,
	|	AMs.AMBeginDate,
	|	AMs.AMEndDate,
	|	ISNULL(CurrentPeriods.CurrentPeriodUUID, AMs.AMPeriodUUID) AS NewPeriodUUID,
	|	ISNULL(CurrentPeriods.CurrentPeriodBeginDate, AMs.AMBeginDate) AS NewPeriodBeginDate,
	|	ISNULL(CurrentPeriods.CurrentPeriodEndDate, AMs.AMEndDate) AS NewPeriodEndDate,
	|	CASE
	|		WHEN AMs.AMStatus = VALUE(Enum.AssortmentMatrixStatus.Inactive)
	|			THEN CASE
	|					WHEN NOT CurrentPeriods.CurrentPeriodUUID IS NULL 
	|						THEN VALUE(Enum.AssortmentMatrixStatus.Active)
	|					ELSE AMs.AMStatus
	|				END
	|		WHEN AMs.AMStatus = VALUE(Enum.AssortmentMatrixStatus.Active)
	|			THEN CASE
	|					WHEN CurrentPeriods.CurrentPeriodUUID IS NULL 
	|						THEN VALUE(Enum.AssortmentMatrixStatus.Inactive)
	|					ELSE AMs.AMStatus
	|				END
	|	END AS NewStatus
	|INTO Map
	|FROM
	|	AMs AS AMs
	|		LEFT JOIN CurrentPeriods AS CurrentPeriods
	|		ON AMs.AM = CurrentPeriods.AM
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Map.AM,
	|	Map.NewPeriodBeginDate AS BeginDate,
	|	Map.NewPeriodEndDate AS EndDate,
	|	Map.NewPeriodUUID AS PeriodUUID,
	|	Map.NewStatus AS Status
	|FROM
	|	Map AS Map
	|WHERE
	|	(NOT Map.NewPeriodUUID = Map.AMPeriodUUID
	|			OR NOT Map.NewPeriodBeginDate = Map.AMBeginDate
	|			OR NOT Map.AMEndDate = Map.NewPeriodEndDate
	|			OR NOT Map.AMStatus = Map.NewStatus)");
	
	Query.SetParameter("CurrentDate", Date);
	
	QueryResult = Query.Execute().Unload();
	
	For Each Line In QueryResult Do
		
		AMObject = Line.AM.GetObject();
		FillPropertyValues(AMObject, Line);
		AMObject.Write();
		
	EndDo;
	
EndProcedure

#EndRegion