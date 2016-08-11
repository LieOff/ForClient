
Procedure BeforeWrite(Cancel)
	
	// Сохраняем в дополнительные свойства предыдущие значения брэнда и группы 
	// номенклатуры для последующей работы с ними во время записи объекта.
	ThisObject.AdditionalProperties.Insert("OldBrand", ThisObject.Ref.Brand);
	ThisObject.AdditionalProperties.Insert("OldSKUGroup", ThisObject.Ref.Owner);
	
	// Проверить наличие упаковки
	ParameterFilter = new Structure;
	ParameterFilter.Insert("Pack", BaseUnit);
	
	FoundRow = Packing.FindRows(ParameterFilter);
	
	If FoundRow.Count() = 0 Then
		
		NewRow 				= Packing.Add();
		NewRow.Pack 		= BaseUnit;
		NewRow.Multiplier 	= 1;
		
	EndIf;
	
	// Перезаполнить остатки
	If Constants.SKUFeaturesRegistration.Get() Then
		
		If Stocks.Count() = 0 Then
			
			NewRow 				= Stocks.Add();
			NewRow.Feature 		= Catalogs.SKUFeatures.FindByCode("000000001");
			NewRow.StockValue 	= CommonStock;
			
		EndIf;
		
	Else
		
		If Stocks.Count() = 0 Then 
			
			NewRow				= Stocks.Add();
			NewRow.StockValue	= CommonStock; 
			
		EndIf;
		
		For Each Row In Stocks Do
			
			Row.Feature = Catalogs.SKUFeatures.FindByCode("000000001");
			
		EndDo;
		
	EndIf;
	
	TS = Stocks.Unload();
	
	CommonStock = 0;
	
	For Each Row In TS Do
		
		CommonStock = CommonStock + Row.StockValue;
		
	EndDo;
	
	For Each Row In Stocks Do
		
		If Row.Stock = Catalogs.Stock.EmptyRef() Then
			
			Row.Stock = Catalogs.Stock.FindByCode("000000001");
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	// Переменные для предыдущих значений бренда и группы номенклатуры.
	Var OldBrand;
	Var OldSKUGroup;
	
	// В случае если установлена пометка на удаление мы не делаем ничего.
	If Not ThisObject.DeletionMark Then
		
		// Достаём из дополнительных свойств предыдущие значения брэнда и группы
		// номенклатуры и пишем их в вышеобъявленные переменные.
		ThisObject.AdditionalProperties.Property("OldBrand", OldBrand);
		ThisObject.AdditionalProperties.Property("OldSKUGroup", OldSKUGroup);
		
		// Массивы для хранения предыдущих и текущих значений брэнда и группы 
		// номенклатуры текущего элемента справочника "Номенклатура".
		OldSources = New Array;
		NewSources = New Array;
		
		// Если значение реквизита "Брэнд" изменилось,
		If Not OldBrand = ThisObject.Brand Then
			
			// Добавляем в массив новых значений новый брэнд.
			NewSources.Add(ThisObject.Brand);
			
			// Если предыдущее значение не пустая ссылка (а значит объект еще ни разу
			// не был записан),
			If Not OldBrand = Catalogs.Brands.EmptyRef() Then
				
				// Тогда добавляем старый брэнд данного объекта в массив предыдущих 
				// значений.
				OldSources.Add(OldBrand);
				
			EndIf;
			
		EndIf;
		
		// Если значение реквизита "Группа номенклатуры" (Owner) изменилось,
		If Not OldSKUGroup = ThisObject.Owner Then
			
			// Добавляем в массив новых значений новую группу номенклатуры.
			NewSources.Add(ThisObject.Owner);
			
			// Если предыдущее значение не пустая ссылка (а значит объект еще ни разу не
			// был записан),
			If Not OldSKUGroup = Catalogs.SKUGroup.EmptyRef() Then
				
				// Тогда добавляем старую группу номенклатуры в массив предыдущих 
				// значений.
				OldSources.Add(OldSKUGroup);
				
			EndIf;
			
		EndIf;
		
		// Данным запросом формируются строки со статусом "Deleted" и строки со 
		// статусом "Added". То есть из всех анкет убирается номенклатура, которая
		// попала туда из старых источников (предыдущие значения реквизитов "Группа
		// номенклатуры" и "Брэнд" и во все анкеты где присутствуют новые значения
		// реквизитов "Группа номенклатуры" и "Брэнд" добавляется эта же номенклатура
		Query = New Query(
		"SELECT ALLOWED
		|	&CurrentDate AS Period,
		|	SKUsInQuestionnairesSliceLast.Questionnaire,
		|	SKUsInQuestionnairesSliceLast.SKU,
		|	SKUsInQuestionnairesSliceLast.Source,
		|	VALUE(Enum.ValueTableRowStatuses.Deleted) AS Status
		|FROM
		|	InformationRegister.SKUsInQuestionnaires.SliceLast(
		|			,
		|			SKU = &SKU
		|				AND Source IN (&OldSources)
		|				AND Status <> VALUE(Enum.ValueTableRowStatuses.Deleted)) AS SKUsInQuestionnairesSliceLast
		|
		|UNION ALL
		|
		|SELECT 
		|	DATEADD(&CurrentDate, SECOND, 1),
		|	SKUsInQuestionnairesSliceLast.Questionnaire,
		|	&SKU,
		|	SKUsInQuestionnairesSliceLast.Source,
		|	VALUE(Enum.ValueTableRowStatuses.Added)
		|FROM
		|	InformationRegister.SKUsInQuestionnaires.SliceLast(
		|			,
		|			Source IN (&NewSources)
		|				AND Status <> VALUE(Enum.ValueTableRowStatuses.Deleted)) AS SKUsInQuestionnairesSliceLast
		|
		|GROUP BY
		|	SKUsInQuestionnairesSliceLast.Questionnaire,
		|	SKUsInQuestionnairesSliceLast.Source");
		
		// Установка параметров запроса.
		Query.SetParameter("CurrentDate", CurrentDate());
		Query.SetParameter("SKU", ThisObject.Ref);
		Query.SetParameter("OldSources", OldSources);
		Query.SetParameter("NewSources", NewSources);
		
		// Получение результата запроса.
		QueryResult = Query.Execute().Unload();
		
		// Цикл по каждой строке результата запроса.
		For Each Line In QueryResult Do
			
			// Создание, заполнение и запись менеджера записи.
			RecordManager = InformationRegisters.SKUsInQuestionnaires.CreateRecordManager();
			FillPropertyValues(RecordManager, Line);
			RecordManager.Write();
			
		EndDo;
		
	EndIf;
	
EndProcedure
