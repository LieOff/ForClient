&НаСервере
// Формирует запрос по таблице "Outlets" документа
//
Функция ПодготовитьПараметрыПроведения(ДокументСсылка,отказ) Экспорт

	ПараметрыПроведения = Новый Structure;
     	//{{QUERY_BUILDER_WITH_RESULT_PROCESSING
	// Данный фрагмент построен конструктором.
	// При повторном использовании конструктора, внесенные вручную изменения будут утеряны!!!
    Query = new Query;
	
	Query.SetParameter("Ref", ДокументСсылка);
	Query.Text = "SELECT ALLOWED
	             |	VisitPlan.Ref,
	             |	VisitPlan.Date,
	             |	VisitPlan.DateFrom,
	             |	VisitPlan.DateTo,
	             |	VisitPlan.SR
	             |FROM
	             |	Document.VisitPlan AS VisitPlan
	             |WHERE
	             |	VisitPlan.Ref = &Ref";
	
	Выборка = Query.Execute().Select();
	Выборка.Next();
	
	Реквизиты = Новый Structure("Ref,Date,SR,DateFrom,DateTo");
	
	ЗаполнитьЗначенияСвойств(Реквизиты, Выборка);

	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	VisitPlanOutlets.Outlet AS Outlet,
		|	VisitPlanOutlets.Date
		|FROM
		|	Document.VisitPlan.Outlets AS VisitPlanOutlets
		|WHERE
		|	VisitPlanOutlets.Ref = &Ref
		|
		|ORDER BY
		|	VisitPlanOutlets.LineNumber
		|TOTALS BY
		|	Outlet";

	Query.SetParameter("Ref", ДокументСсылка.Ref);

	ResultValueTree = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	DateНачалоНедели = ДатаПоНомеруНедели(ДокументСсылка.WeekNumber,Year(ДокументСсылка.Year));
	Реквизиты.Insert("Date",DateНачалоНедели);
	ПараметрыПроведения.Вставить("ValueTree",ResultValueTree);
    ПараметрыПроведения.Вставить("Реквизиты"   ,Реквизиты);
	
Возврат ПараметрыПроведения;
	
КонецФункции

&НаСервере
 //Как из номера, числа недели вернуть первую Дату этой
Функция ДатаПоНомеруНедели(НомерНедели,   Год =Неопределено) 
	 
Возврат НачалоНедели(Дата(?(Год=Неопределено,Год(ТекущаяДата()), Год),1,1)+(НомерНедели-НеделяГода(Дата(?(Год =Неопределено, Год(ТекущаяДата()), Год), 1, 1))) *604800);
 
КонецФункции
