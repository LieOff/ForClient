
&AtServer
Var TypesMap;

&AtClient
Var OldSKUSourceType;

&AtClient
Var OldStatus;

&AtClient
Var AvailableStatuses;

#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	////////////////
	//If Object.Ref.IsEmpty() Then
	//	Object.Date = CurrentDate();
	//EndIf;
	////////////////
	PredefinedItems = New Map;
	PredefinedItems.Insert("Catalog.OutletType", "OutletType");
	PredefinedItems.Insert("Catalog.OutletClass", "OutletClass");
	
	ItemsCollection = CommonProcessors.GetPredefinedItems(PredefinedItems);
	
	For Each Item In ItemsCollection Do
		
		Object[Item.Key] = Item.Value;
		
	EndDo;
	
	If Not ValueIsFilled(Object.Ref) Then 
		
		Object.BeginDate = BegOfDay(CurrentDate()) + 60 * 60 * 24;
		Object.Schedule = "Day;1";
		
		// Установить владельца анкеты
		UserID = InfoBaseUsers.CurrentUser().UUID;
		
		CurrentUserElement = Catalogs.User.FindByAttribute("UserID", UserID);	
		
		If ValueIsFilled(CurrentUserElement) Then 
			
			Object.Owner = CurrentUserElement;
			
		EndIf;
		
		Object.Status = Enums.QuestionnareStatus.Planning;
		
		// Новая анкета регулярная. То есть ответы заполняются заново каждый визит.
		Object.Single = False;
		
		// Новая анкета заполняется исходя из 
		Object.FillPeriod = Enums.QuestionsSaveIntervals.ScheduleInterval;
		
		// Группы номенклатуры по умолчанию
		Object.SKUSourceType = Enums.SKUSourceTypes.SKUGroup;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Schedule) Then
		
		Object.Schedule = "Day;1";
		
		Modified = True;
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='For this questionnaire has not been established schedule. The schedule is set by default.';ru='Для данной анкеты не было установлено расписание. Установлено расписание по умолчанию.';cz='For this questionnaire has not been established schedule. The schedule is set by default.'");
		
		UserMessage.Message();
	
	EndIf;
	
	Regularity = ?(Object.Single, "Single", "Regular");
	
	SetScheduleStringPresentation();
	
	// Заполнить списки вопросов
	FillQuestionsTree(Enums.QuestionGroupTypes.RegularQuestions, Parameters.CopyingValue);
	FillQuestionsTree(Enums.QuestionGroupTypes.SKUQuestions, Parameters.CopyingValue);
	
	// Заполнить SKU
	FillSKUs(Parameters.CopyingValue);
	
	// Заполнить параметры отбора
	FillSelectors();
	FillSkuAndSkuGroupSelectFilters();
	
	// Разблокировать/заблокировать элементы в зависимости от статуса
	DisableFormElements();
	             
	// Заполнить значения об отобранных ТТ и торговых представителях
	SetOutletsSRsSelected();
	If Object.SKUSourceType = Enums.SKUSourceTypes.Brand Then
		Items.SelectSkuGroup.Enabled = False;
	EndIf;	
	
EndProcedure

&AtServer
Procedure FillSkuAndSkuGroupSelectFilters()

	NameFilterSkuGroup = SkusGroupSelect.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	NameFilterSkuGroup.ComparisonType = DataCompositionComparisonType.Contains;
	NameFilterSkuGroup.LeftValue = New DataCompositionField("Description");
	NameFilterSkuGroup.Use = False;

	NameFilterSku = SkusSelect.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	NameFilterSku.ComparisonType=DataCompositionComparisonType.Contains;
	NameFilterSku.LeftValue = New DataCompositionField("Description");
	NameFilterSku.Use = False;

	
EndProcedure


&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	For Each SKUElement In SKUsValueTable Do 
		
		If Not ValueIsFilled(SKUElement.SKU) Then 
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en='Found blank rows in a tabular section ""SKUs""';ru='Найдены незаполненные строки в табличной части ""Номенклатура""';cz='Found blank rows in a tabular section ""SKUs""'");
			
			UserMessage.Message();
			
			Cancel = True;
			
			Return;
			
		EndIf;
		
	EndDo;
		
	If Not SKUsValueTable.Count() = 0 And SKUQuestions.GetItems().Count() = 0 Then 
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='The list of SKU questions must be filled';ru='Список вопросов по номенклатуре должен быть заполнен';cz='The list of SKU questions must be filled'");
		
		UserMessage.Message();
		
		Cancel = True;
		
	EndIf;
	
	If SKUsValueTable.Count() = 0 And Not SKUQuestions.GetItems().Count() = 0 Then 
		
		UserMessage 		= New UserMessage;
		UserMessage.Text	= NStr("en='The list of SKUs must be filled';ru='Список номенклатуры должен быть заполнен';cz='The list of SKUs must be filled'");
		
		UserMessage.Message();
		
		Cancel = True;
		
	EndIf;
	
	If Not Cancel Then 	
		
		WriteQuestions(Cancel, RegularQuestions, DeletedRegularQuestions, CurrentObject);
		WriteQuestions(Cancel, SKUQuestions, DeletedSKUQuestions, CurrentObject);
		
		WriteSKUs(CurrentObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillQuestionsTree(Enums.QuestionGroupTypes.RegularQuestions);
	FillQuestionsTree(Enums.QuestionGroupTypes.SKUQuestions);
	
	FillSKUs();
	
	FillSelectors();
	
	// Разблокировать/заблокировать элементы в зависимости от статуса
	DisableFormElements();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	LoadSelectors(Cancel);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FillAvailableStatuses(Object.Status);
	
	CheckSelectorsForSKUs(Items.QuestionsCheckSelectorsForSKUs);
	
EndProcedure

&AtServer
Procedure OpenAtServer()
	
	Items.Number.ReadOnly = Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditDocumentNumbers);
	
EndProcedure

#Region Status

&AtServer
Procedure DisableFormElements()
	
	// Блокировка элементов в зависимости от статуса анкеты
	IsActive = Object.Status = Enums.QuestionnareStatus.Active;
	IsInactive = Object.Status = Enums.QuestionnareStatus.Inactive;
	
	Items.Regularity.Enabled = Not (IsActive Or IsInactive);
	Items.BeginDate.Enabled = Not (IsActive Or IsInactive);
	Items.SelectorsTable.Enabled = Not (IsActive Or IsInactive);
	Items.FillPeriod.Enabled = Not (IsActive Or IsInactive) And Object.Single;
	
	Items.SetSchedule.Enabled = Not (IsActive Or IsInactive);
	
	Items.Status.Enabled = Not IsInactive;
	Items.EndDate.Enabled = Not IsInactive;
	
	Items.RegularQuestions.ReadOnly = IsInactive;
	Items.RegularQuestions.CommandBar.Enabled = Not IsInactive;
	
	Items.SKUQuestions.ReadOnly = IsInactive;
	Items.SKUQuestions.CommandBar.Enabled = Not IsInactive;
	
	Items.SKUSourceType.Enabled = Not IsInactive;
	Items.SKUsValueTable.ReadOnly = IsInactive;
	Items.SKUsValueTable.CommandBar.Enabled = Not IsInactive;

EndProcedure

&AtServer
Procedure SetStatusTo(EnumValueName)
	
	Object.Status = Enums["QuestionnareStatus"][EnumValueName];
	
EndProcedure

&AtServer
Function StatusIs(EnumValueName) 
	
	Return Object.Status = Enums["QuestionnareStatus"][EnumValueName];
	
EndFunction

&AtServer
Function GetAvailableStatuses(Status)
	
	AvailableStatuses = New ValueList;
	
	If Status = Enums.QuestionnareStatus.Planning Then
		
		AvailableStatuses.Add(Enums.QuestionnareStatus.Planning, 
							Metadata.Enums.QuestionnareStatus.EnumValues.Planning.Presentation());
		AvailableStatuses.Add(Enums.QuestionnareStatus.Ready, 
							Metadata.Enums.QuestionnareStatus.EnumValues.Ready.Presentation());
		
	ElsIf Status = Enums.QuestionnareStatus.Ready Then
		
		AvailableStatuses.Add(Enums.QuestionnareStatus.Planning, 
							Metadata.Enums.QuestionnareStatus.EnumValues.Planning.Presentation());
		AvailableStatuses.Add(Enums.QuestionnareStatus.Ready, 
							Metadata.Enums.QuestionnareStatus.EnumValues.Ready.Presentation());
		AvailableStatuses.Add(Enums.QuestionnareStatus.Active, 
							Metadata.Enums.QuestionnareStatus.EnumValues.Active.Presentation());
		
	ElsIf Status = Enums.QuestionnareStatus.Active Then
		
		AvailableStatuses.Add(Enums.QuestionnareStatus.Active, 
							Metadata.Enums.QuestionnareStatus.EnumValues.Active.Presentation());
		AvailableStatuses.Add(Enums.QuestionnareStatus.Inactive, 
							Metadata.Enums.QuestionnareStatus.EnumValues.Inactive.Presentation());
		
	ElsIf Status = Enums.QuestionnareStatus.Inactive Then
		
		AvailableStatuses.Add(Enums.QuestionnareStatus.Inactive, 
							Metadata.Enums.QuestionnareStatus.EnumValues.Inactive.Presentation());
		
	EndIf;
	
	Return AvailableStatuses;
	
EndFunction

#EndRegion

#Region SKUs

&AtServerNoContext
Function GetSKUSourceType(Value)
	
	If Value = "SKUGroup" Then 
		
		Return Enums.SKUSourceTypes.SKUGroup;
		
	Else 
		
		Return Enums.SKUSourceTypes.Brand;
		
	EndIf;
		
EndFunction

&AtServerNoContext
Function CheckSelectorsForSKUsAtServer(ObjectName, Filter, RefArray)
	
	// Объявляем схему
	DCS = New DataCompositionSchema;
	
	DataSource						= DCS.DataSources.Add();
	DataSource.Name					= "DataSource1";
	DataSource.DataSourceType		= "Local";
	DataSource.ConnectionString		= "";
	
	DataSet							= DCS.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name					= "DataSet1";
	DataSet.Query					= "Select ALLOWED Ref AS Ref From " + ObjectName;
	DataSet.DataSource				= "DataSource1";
	DataSet.AutoFillAvailableFields	= True;
	
	RefField			= DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	RefField.Field		= "Ref";
	RefField.DataPath	= "Ref";
	RefField.Title		= "Ref";
	
	DCGroup = DCS.DefaultSettings.Structure.Add(Type("DataCompositionGroup"));
	DCGroup.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	DCGroup.Use = True;
	
	SelectField			= DCS.DefaultSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectField.Field	= New DataCompositionField("Ref");
	SelectField.Use		= True;
	
	For Each FilterItem In Filter.Items Do 
		
		RefField			= DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		RefField.Field		= String(FilterItem.LeftValue);
		RefField.DataPath	= String(FilterItem.LeftValue);
		RefField.Title		= String(FilterItem.LeftValue);
		
		SelectField			= DCS.DefaultSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectField.Field	= FilterItem.LeftValue;
		SelectField.Use		= True;
				
		NewFilterItem = DCS.DefaultSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		
		FillPropertyValues(NewFilterItem, FilterItem);
		
	EndDo;
	
	NewFilterItem					= DCS.DefaultSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	NewFilterItem.LeftValue			= New DataCompositionField("Ref");
	NewFilterItem.Use				= True;
	NewFilterItem.ComparisonType	= DataCompositionComparisonType.InList;
	NewFilterItem.RightValue		= RefArray;
		
	TemplateComposer = New DataCompositionTemplateComposer;
	
	Template = TemplateComposer.Execute(DCS, DCS.DefaultSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));

	Processor = New DataCompositionProcessor;
	Processor.Initialize(Template);

	ResultTable = New ValueTable;
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

	OutputProcessor.SetObject(ResultTable);
	OutputProcessor.Output(Processor);
	
	Return ResultTable.UnloadColumn("Ref");
	
EndFunction

&AtServerNoContext
Function GetDataCompositionFilterConstructor()
	
	Return New DataCompositionFilter;
	
EndFunction

&AtServerNoContext
Procedure CheckBrand(Brand, IsCorrect)
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	SKU.Ref
		|FROM
		|	Catalog.SKU AS SKU
		|WHERE
		|	SKU.Brand = &Brand";
	
	Query.SetParameter("Brand", Brand);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then 
		
		IsCorrect = True;
		
	Else 
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en = 'No nomenclature with brand """ + String(Brand) + """ '; ru = 'Нет номенклатуры с брендом """ + String(Brand) + """ '");
		
		UserMessage.Message();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CheckGroup(Group, IsCorrect)
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	SKU.Ref
		|FROM
		|	Catalog.SKU AS SKU
		|WHERE
		|	SKU.Owner = &Group";
	
	Query.SetParameter("Group", Group);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then 
		
		IsCorrect = True;
		
	Else 
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en = 'No nomenclature with group """ + String(Group) + """ '; ru = 'Нет номенклатуры с группой """ + String(Group) + """ '");
		
		UserMessage.Message();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillSKUs(CopyingValue = Undefined)
	
	SKUsValueTable.Load(GetSKUsInQuestionnaireValueTable(CopyingValue));
		
EndProcedure

&AtServer
Procedure WriteSKUs(CurrentObject)
	
	// Первый запрос пакета получает все источники номенклатуры (номенклатура,  
	// группа номенклатуры, брэнд) с формы.
	//
	// Второй запрос пакета выбирает все элементы справочника "Номенклатура"
	// у которых значения реквизитов соответствуют источникам из группы.
	//
	// Третий запрос пакета выбирает из регистра сведений SKUsInQuestionnaires
	// все записи со статусом "Added" соответствующие данному документу "Анкета".
	//
	// Четвертый запрос пакета формирует соответствие номенклатуры и источников 
	// из регистра сведений и с формы и отбрасывает то что не изменилось.
	//
	// Пятый запрос пакета формирует статусы для каждой строки в зависимости от
	// наличия данных в регистре сведений и на форме. Если данные есть в регистре
	// сведений, но их нет на форме, тогда данной строке ставится статус "Deleted"
	// Если данные есть на форме, но их нет в регистре, тогда статус данной строки
	// "Added".
	
	Query = New Query(
	"SELECT ALLOWED
	|	FormSKUs.SKU AS Source
	|INTO Sources
	|FROM
	|	&FormSKUs AS FormSKUs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SKU.Ref AS SKUOnForm,
	|	Sources.Source AS SourceOnForm
	|INTO SKUsWithSources
	|FROM
	|	Catalog.SKU AS SKU
	|		INNER JOIN Sources AS Sources
	|		ON (SKU.Ref = Sources.Source
	|				OR SKU.Owner = Sources.Source
	|				OR SKU.Brand = Sources.Source)
	|WHERE
	|	(SKU.Ref IN
	|				(SELECT 
	|					Sources.Source
	|				FROM
	|					Sources AS Sources)
	|			OR SKU.Owner IN
	|				(SELECT 
	|					Sources.Source
	|				FROM
	|					Sources AS Sources)
	|			OR SKU.Brand IN
	|				(SELECT 
	|					Sources.Source
	|				FROM
	|					Sources AS Sources))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SKUsInQuestionnairesSliceLast.SKU AS SKUInRegister,
	|	SKUsInQuestionnairesSliceLast.Source AS SourceInRegister
	|INTO SavedSKUs
	|FROM
	|	InformationRegister.SKUsInQuestionnaires.SliceLast(&CurrentDate, Questionnaire = &Questionnaire) AS SKUsInQuestionnairesSliceLast
	|WHERE
	|	SKUsInQuestionnairesSliceLast.Status <> VALUE(Enum.ValueTableRowStatuses.Deleted)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SavedSKUs.SKUInRegister,
	|	SavedSKUs.SourceInRegister,
	|	SKUsWithSources.SKUOnForm,
	|	SKUsWithSources.SourceOnForm
	|INTO Difference
	|FROM
	|	SKUsWithSources AS SKUsWithSources
	|		FULL JOIN SavedSKUs AS SavedSKUs
	|		ON SKUsWithSources.SKUOnForm = SavedSKUs.SKUInRegister
	|			AND SKUsWithSources.SourceOnForm = SavedSKUs.SourceInRegister
	|WHERE
	|	(SavedSKUs.SKUInRegister IS NULL 
	|				AND SavedSKUs.SourceInRegister IS NULL 
	|			OR SKUsWithSources.SKUOnForm IS NULL 
	|				AND SKUsWithSources.SourceOnForm IS NULL )
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	&CurrentDate AS Period,
	|	&Questionnaire,
	|	ISNULL(Difference.SKUInRegister, Difference.SKUOnForm) AS SKU,
	|	ISNULL(Difference.SourceInRegister, Difference.SourceOnForm) AS Source,
	|	CASE
	|		WHEN Difference.SKUInRegister IS NULL 
	|				AND Difference.SourceInRegister IS NULL 
	|			THEN VALUE(Enum.ValueTableRowStatuses.Added)
	|		WHEN Difference.SKUOnForm IS NULL 
	|				AND Difference.SourceOnForm IS NULL 
	|			THEN VALUE(Enum.ValueTableRowStatuses.Deleted)
	|	END AS Status
	|FROM
	|	Difference AS Difference");
	
	// Установка параметров запроса.
	Query.SetParameter("FormSKUs", SKUsValueTable.Unload());
	Query.SetParameter("Questionnaire", CurrentObject.Ref);
	Query.SetParameter("CurrentDate", CurrentDate());
	
	// Получение результата запроса.
	QueryResult = Query.Execute().Unload();
	
	// Цикл по каждой строке результата запроса
	For Each Line In QueryResult Do
		
		// Создание, заполнение и запись менедежра записи.
		RecordManager = InformationRegisters.SKUsInQuestionnaires.CreateRecordManager();
		FillPropertyValues(RecordManager, Line);
		RecordManager.Questionnaire = CurrentObject.Ref;
		
		RecordManager.Write();
		
	EndDo;
	
EndProcedure

&AtServer
Function GetSKUsInQuestionnaireValueTable(CopyingValue)
	
	Var Query, QueryResult;
	
	Query = New Query(
	"SELECT ALLOWED
	|	SKUsInQuestionnairesSliceLast.Source AS SKU,
	|	VALUETYPE(SKUsInQuestionnairesSliceLast.Source) AS SourceType
	|FROM
	|	InformationRegister.SKUsInQuestionnaires.SliceLast AS SKUsInQuestionnairesSliceLast
	|WHERE
	|	SKUsInQuestionnairesSliceLast.Questionnaire = &Questionnaire
	|	AND SKUsInQuestionnairesSliceLast.Status <> VALUE(Enum.ValueTableRowStatuses.Deleted)
	|
	|GROUP BY
	|	SKUsInQuestionnairesSliceLast.Source,
	|	VALUETYPE(SKUsInQuestionnairesSliceLast.Source)");
	
	If ValueIsFilled(CopyingValue) Then 
	
		Query.SetParameter("Questionnaire", CopyingValue);
		
	Else 
		
		Query.SetParameter("Questionnaire", Object.Ref);
		
	EndIf;
	
	QueryResult = Query.Execute().Unload();
	
	Return QueryResult;

EndFunction

&AtClient
Function GetDataCompositionFilter(ResultValue, AdditionalText = "")
	
	FilterOfList = GetDataCompositionFilterConstructor();
	
	For Each Item In Selectors Do
		
		FieldName = Undefined;
		
		If Item.Selector = "Catalog_Region" Then 
			
			If ResultValue = "Catalog.SKU" Then 
				
				FieldName = AdditionalText + "Owner.Territories.Territory.Owner";
				
			Else 
				
				FieldName = AdditionalText + "Territories.Territory.Owner";
				
			EndIf;
			
		ElsIf Item.Selector = "Catalog_Territory" Then
			
			If ResultValue = "Catalog.SKU" Then 
				
				FieldName = AdditionalText + "Owner.Territories.Territory";
				
			Else 
				
				FieldName = AdditionalText + "Territories.Territory";
				
			EndIf;
			
		EndIf;
		
		If Not FieldName = Undefined Then 
			
			If IsList(Item.ComparisonType) Then
			
				For Each ListItem In Item.Value Do
					
					FilterElement					= FilterOfList.Items.Add(Type("DataCompositionFilterItem"));
					FilterElement.LeftValue			= New DataCompositionField(FieldName);
					FilterElement.Use				= True;
					FilterElement.ComparisonType	= DataCompositionComparisonType.InHierarchy;
					FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
					FilterElement.RightValue		= ListItem.Value;	
					
				EndDo;
				
			ElsIf IsEqual(Item.ComparisonType) Then  
				
				FilterElement					= FilterOfList.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.LeftValue			= New DataCompositionField(FieldName);
				FilterElement.Use				= True;
				
				If Item.Selector = "Catalog_Region" Then 
				
					FilterElement.ComparisonType	= DataCompositionComparisonType.InHierarchy;
					
				Else 
					
					FilterElement.ComparisonType	= DataCompositionComparisonType.Equal;
					
				EndIf;
				
				FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
				FilterElement.RightValue		= Item.Value;
				
			ElsIf IsNotEqual(Item.ComparisonType) Then
				
				FilterElement					= FilterOfList.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.LeftValue			= New DataCompositionField(FieldName);
				FilterElement.Use				= True;
				
				If Item.Selector = "Catalog_Region" Then 
				
					FilterElement.ComparisonType	= DataCompositionComparisonType.NotInHierarchy;
					
				Else 
					
					FilterElement.ComparisonType	= DataCompositionComparisonType.NotEqual;
					
				EndIf;
				
				FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
				FilterElement.RightValue		= Item.Value;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return FilterOfList;
	
EndFunction

#EndRegion

#Region Schedule

&AtServer
Procedure SetScheduleStringPresentation()
	
	ScheduleStringPresentation = GetStringPresentationOfSchedule(Object.Schedule);
	
EndProcedure

#EndRegion

#Region Questions

&AtServer
Function IsNotEqual(Value)

	If Value = Enums.ComparisonType.NotEqual Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;

EndFunction

&AtServer
Function IsEqual(Value)

	If Value = Enums.ComparisonType.Equal Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;

EndFunction

&AtServerNoContext
Function GUIDFromEnumValue(Value) 
	
	GUID = Mid(ValueToStringInternal(Value), StrLen(ValueToStringInternal(Value))-32,32);
	GUID = Left(GUID,8) + "-" + Mid(GUID,9,4) + "-" + Mid(GUID,13,4) + "-" + Mid(GUID,17,4) + "-" + Right(GUID,12);
	
	Return GUID;
	
EndFunction

&AtServerNoContext
Function GetStringFromValue(Value) 
	
	TypeOfValue = TypeOf(Value);
	
	If TypeOfValue = Type("Boolean") Then 
		
		If Value Then
			
			Return "True";
			
		Else 
			
			Return "False";
			
		EndIf;
				
	ElsIf TypeOfValue = Type("Number") Then 
		
		Value = String(Value);
		Value = StrReplace(Value, " ", "");
		Value = StrReplace(Value, Chars.NBSp, "");
		
		Return Value;
		
	ElsIf Enums.AllRefsType().ContainsType(TypeOfValue) Then 
		
		Return GUIDFromEnumValue(Value);
		
	ElsIf Catalogs.AllRefsType().ContainsType(TypeOfValue) Or Документы.AllRefsType().ContainsType(TypeOfValue) Then 
		
		Return String(Value.UUID());
		
	Else 
		
		Return String(Value);
		
	EndIf;
	
EndFunction

&AtServerNoContext
Function GetQuestionGroupType(TypeString = "SKUQuestions")
	
	Return CommonProcessors.GetQuestionGroupType(TypeString);
	
EndFunction

&AtServerNoContext
Function IsLogicAnswerType(Question)
	
	If Question.AnswerType = Enums.DataType.Boolean Then 
		
		Return True;
		
	Else 
		
		Return False;
		
	EndIf;
	
EndFunction

&AtServerNoContext
Function GetStatusToRow(StringStatus)
	
	If StringStatus = "Deleted" Then 
		
		Return Enums.ValueTableRowStatuses.Deleted;
		
	ElsIf StringStatus = "Modified" Then 
		
		Return Enums.ValueTableRowStatuses.Modified;
		
	EndIf;
	
EndFunction

&AtServerNoContext
Function GetQuestionsFromGroup(Group)
	
	Selection = Catalogs.Question.Select( , Group);
	
	ArrayOfQuestion = New Array;
	
	While Selection.Next() Do
		
		ArrayOfQuestion.Add(Selection.Ref);
		
	EndDo;
	
	Return ArrayOfQuestion;
	
EndFunction

&AtServer
Procedure WriteQuestions(Cancel, Tree, DeletedTable, CurrentObject)
	
	If Not Cancel Then 
		
		ItemsOfTopLevel = Tree.GetItems();
		
		IndOrder = 0;
		
		For Each DeletedElement In DeletedTable Do 
			
			Manager					= InformationRegisters.QuestionsInQuestionnaires.CreateRecordManager();
			Manager.Period			= DeletedElement.StatusDate; 
			Manager.Questionnaire	= CurrentObject.Ref;
			Manager.ParentQuestion	= DeletedElement.ParentQuestion;
			Manager.ChildQuestion	= DeletedElement.Question;
			Manager.Obligatoriness	= DeletedElement.Obligatoriness;
			Manager.Order			= IndOrder;
			Manager.QuestionType	= DeletedElement.Question.Owner.Type;
			Manager.Status			= Enums.ValueTableRowStatuses.Deleted;
			
			Manager.Write();
			
		EndDo;
		
		DeletedTable.Clear();
		
		For Each ItemOfTopLevel In ItemsOfTopLevel Do 
			
			IndOrder = IndOrder + 1;
			
			Manager					= InformationRegisters.QuestionsInQuestionnaires.CreateRecordManager();
			Manager.Period			= ItemOfTopLevel.StatusDate; 
			Manager.Questionnaire	= CurrentObject.Ref;
			Manager.ChildQuestion	= ItemOfTopLevel.Question;
			Manager.Obligatoriness	= ItemOfTopLevel.Obligatoriness;
			Manager.Order			= IndOrder;
			Manager.QuestionType	= ItemOfTopLevel.Question.Owner.Type;
			Manager.Status			= ItemOfTopLevel.Status;
			
			Manager.Write();
			
			ItemsOfBottomLevel = ItemOfTopLevel.GetItems();
			
			For Each ItemOfBottomLevel In ItemsOfBottomLevel Do 
				
				IndOrder = IndOrder + 1;
				
				Manager					= InformationRegisters.QuestionsInQuestionnaires.CreateRecordManager();
				Manager.Period			= ItemOfBottomLevel.StatusDate; 
				Manager.Questionnaire	= CurrentObject.Ref;
				Manager.ParentQuestion	= ItemOfTopLevel.Question;
				Manager.ChildQuestion	= ItemOfBottomLevel.Question;
				Manager.Obligatoriness	= ItemOfBottomLevel.Obligatoriness;
				Manager.Order			= IndOrder;
				Manager.QuestionType	= ItemOfBottomLevel.Question.Owner.Type;
				Manager.Status			= ItemOfBottomLevel.Status;
				
				Manager.Write();
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure GetAddedStatusAndAnswerTypeToRow(Question, Status, AnswerType)
	
	Status		= Enums.ValueTableRowStatuses.Added;
	AnswerType	= Question.AnswerType;
	
EndProcedure

&AtServer
Procedure FillQuestionsTree(GroupType, CopyingValue = Undefined)
	
	If GroupType = Enums.QuestionGroupTypes.RegularQuestions Then 
		
		Tree = RegularQuestions;
		
	Else 
		
		Tree = SKUQuestions;
		
	EndIf;
	
	Tree.GetItems().Clear();
	
	If ValueIsFilled(Object.Ref) Or ValueIsFilled(CopyingValue) Then 
	
		// Заполнить список вопросов
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	QuestionsInQuestionnairesSliceLast.Period,
			|	QuestionsInQuestionnairesSliceLast.Questionnaire,
			|	QuestionsInQuestionnairesSliceLast.ParentQuestion,
			|	QuestionsInQuestionnairesSliceLast.ChildQuestion,
			|	QuestionsInQuestionnairesSliceLast.QuestionType,
			|	QuestionsInQuestionnairesSliceLast.Obligatoriness,
			|	QuestionsInQuestionnairesSliceLast.Status,
			|	QuestionsInQuestionnairesSliceLast.Order
			|FROM
			|	InformationRegister.QuestionsInQuestionnaires.SliceLast AS QuestionsInQuestionnairesSliceLast
			|WHERE
			|	NOT QuestionsInQuestionnairesSliceLast.Status = VALUE(Enum.ValueTableRowStatuses.Deleted)
			|	AND QuestionsInQuestionnairesSliceLast.Questionnaire = &Questionnaire
			|	AND QuestionsInQuestionnairesSliceLast.QuestionType = &GroupType";

		If ValueIsFilled(CopyingValue) Then 
			
			Query.SetParameter("Questionnaire", CopyingValue);
			
		Else 
			
			Query.SetParameter("Questionnaire", Object.Ref);
			
		EndIf;
		
		Query.SetParameter("GroupType", GroupType);
		
		QuestionsTable = Query.Execute().Unload();

		ParentQuestionsTable = QuestionsTable.Copy(New Structure("ParentQuestion", Catalogs.Question.EmptyRef()));
		
		ParentQuestionsTable.Sort("Order Asc");
		
		For Each ParentQuestionRow In ParentQuestionsTable Do 
			
			ParentRow					= Tree.GetItems().Add();
			ParentRow.Question			= ParentQuestionRow.ChildQuestion;
			ParentRow.Obligatoriness	= ParentQuestionRow.Obligatoriness;
			ParentRow.Status			= ParentQuestionRow.Status;
			ParentRow.StatusDate		= ParentQuestionRow.Period;
			ParentRow.AnswerType		= ParentQuestionRow.ChildQuestion.AnswerType;
			ParentRow.IsOldQuestion		= True;
			
			ChildQuestionsTable = QuestionsTable.Copy(New Structure("ParentQuestion", ParentQuestionRow.ChildQuestion));
			
			ChildQuestionsTable.Sort("Order Asc");
			
			For Each ChildQuestionRow In ChildQuestionsTable Do 
				
				ChildRow				= ParentRow.GetItems().Add();
				ChildRow.Question		= ChildQuestionRow.ChildQuestion;
				ChildRow.Obligatoriness	= ChildQuestionRow.Obligatoriness;
				ChildRow.Status			= ChildQuestionRow.Status;
				ChildRow.StatusDate		= ChildQuestionRow.Period;
				ChildRow.AnswerType		= ChildQuestionRow.ChildQuestion.AnswerType;
				ChildRow.IsOldQuestion	= True;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Function CheckAdding(Tree, CurrentRow)
	
	If TypeOf(CurrentRow) = Type("Number") Then 
		
		Row = Tree.FindByID(CurrentRow);
		
	Else 
		
		Row = CurrentRow;
		
	EndIf;
	
	If Row.Status = GetStatusToRow("Deleted") Then 
		
		Return False;
		
	EndIf;
	
	If TypeOf(Row.Question) = Type("CatalogRef.Question") And IsLogicAnswerType(Row.Question) And Row.GetParent() = Undefined Then 
		
		Return True;
		
	Else 
		
		If Row.GetParent() = Undefined Then 
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en='Dependent questions can only be added to the question having a logical answer type.';ru='Зависимые вопросы могут быть добавлены только к вопросу имеющему логический тип ответа.';cz='Dependent questions can only be added to the question having a logical answer type.'");
			
			UserMessage.Message();
		
		EndIf;
		
		Return False;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Function DragAvailable(Element, Val NewParent)
	
	While Not NewParent = Undefined Do 
		
		If Element = NewParent Then 
			
			Return False;
			
		EndIf;
		
		NewParent = NewParent.GetParent();	
		
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Function CopyRow(Tree, Receiver, Source)
	
	If Not CheckAdding(Tree, Receiver) Then 
		
		Return Undefined;
		
	EndIf;
	
	If Source = Undefined Then 
		
		Return Undefined;
		
	EndIf;
	
	If Source.Status = GetStatusToRow("Deleted") Then 
		
		Return Undefined;
		
	EndIf;
	
	NewRow = Receiver.GetItems().Add();
	
	FillPropertyValues(NewRow, Source);
	
	If Source.IsOldQuestion Then 
		
		NewRow.Status = GetStatusToRow("Modified");
		
	EndIf;
	
	NewRow.StatusDate = CurrentDate();
	
	RowCount = Source.GetItems().Count();
	
	For ReverseIndex = 1 To RowCount Do 
		
		ChildRow = Source.GetItems()[RowCount - ReverseIndex];
		
		CopyRow(Tree, NewRow, ChildRow);
		
	EndDo;
	
	If Source.GetParent() = Undefined Then 
		
		Tree.GetItems().Delete(Source);
		
	Else 
		
		Source.GetParent().GetItems().Delete(Source);
		
	EndIf; 
	
	Return NewRow;
	
EndFunction

&AtClient
Procedure ClearParent(Tree, Source)
	
	If Source = Undefined Then 
		
		Return;
		
	EndIf;
	
	If Source.Status = GetStatusToRow("Deleted") Then 
		
		Return;
		
	EndIf;
	
	NewRow = Tree.GetItems().Add();
	
	FillPropertyValues(NewRow, Source);
	
	If Source.IsOldQuestion Then 
		
		NewRow.Status = GetStatusToRow("Modified");
		
	EndIf;
	
	NewRow.StatusDate = CurrentDate();
	
	Source.GetParent().GetItems().Delete(Source);
	
EndProcedure

&AtClient
Procedure FindValueInTree(TreeElements, Value, ElemenFound)
	
	For Each TreeElelment In TreeElements Do 
		
		If ElemenFound Then
			
			Break;
			
		Else 
			
			If Not TreeElelment.Question = Value Then 
				
				FindValueInTree(TreeElelment.GetItems(), Value, ElemenFound);
				
			Else
				
				If Not TreeElelment.Status = GetStatusToRow("Deleted") Then 
					
					ElemenFound = True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure AddQuestionsToTree(SelectedValue, Tree, ItemsTree, Parent = Undefined, CurrentRow = Undefined)
	
	ValueArray = New Array;
	
	If TypeOf(SelectedValue) = Type("CatalogRef.Question") Then
		
		ValueArray.Add(SelectedValue);
		
	ElsIf TypeOf(SelectedValue) = Type("DynamicalListGroupRow") Then 
		
		If TypeOf(SelectedValue.Key) = Type("CatalogRef.QuestionGroup") Then
		
			ValueArray = GetQuestionsFromGroup(SelectedValue.Key);
			
		EndIf;
		
	EndIf;
	
	For Each Element In ValueArray Do
		
		ElementFound = False;
		
		FindValueInTree(Tree.GetItems(), Element, ElementFound);
		
		If Not ElementFound Then 
			
			If IsChildQuestionAdding Then 
				
				AddRow = Parent.GetItems().Add();
				
			Else 
				
				AddRow = Tree.GetItems().Add();
				
			EndIf;	
			
			AddRow.Question = Element;
			AddRow.StatusDate = CurrentDate();
			
			Status		= Undefined;
			AnswerType 	= Undefined;
			
			GetAddedStatusAndAnswerTypeToRow(Element, Status, AnswerType);
			
			AddRow.Status		= Status;
			AddRow.AnswerType	= AnswerType;
			
			If IsChildQuestionAdding Then
				
				ItemsTree.Expand(CurrentRow);
				
			EndIf;
			
		Else 
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en = 'Question """ + String(Element) + """ has already been added'; ru = 'Вопрос """ + String(Element) + """ уже добавлен'");
			
			UserMessage.Message();
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Selectors

&AtServerNoContext
Function GetEqualComparisonType()
	
	Return Enums.ComparisonType.Equal;
	
EndFunction

&AtServer
Function GetSelectorList()

	List = New ValueList;
	
	For Each Value In Metadata.Enums.QuestionnaireSelectors.EnumValues Do
		
		List.Add(Value.Name, Value.Synonym);
		
	EndDo; 
	
	Return List;

EndFunction

&AtServer
Function GetParameterType(Parameter)

	Return TypesMap.Get(String(Parameter.DataType));

EndFunction

&AtServer
Function GetSnapshotDataType()
	
	Return Enums.DataType.Snapshot;
	
EndFunction

&AtServer
Function IsOutletParameter(Value)

	If Value = "Catalog_OutletParameter" Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf; 

EndFunction

&AtServer
Function IsList(Value)

	If Value = Enums.ComparisonType.InList Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;

EndFunction

&AtServer
Function FillSelectors()
	
	Selectors.Clear();
	
	Source = Object.Selectors.Unload();
	
	SelectorTable = Source.Copy();
	SelectorTable.GroupBy("Selector, ComparisonType, AdditionalParameter");
	
	For Each SelectorElsement In SelectorTable Do 
		
		If SelectorElsement.ComparisonType = Enums.ComparisonType.InList Then 
			
			FoundedStrings = Source.FindRows(New Structure("Selector, ComparisonType, AdditionalParameter", SelectorElsement.Selector, SelectorElsement.ComparisonType, SelectorElsement.AdditionalParameter));
					
			ListOfValues = New ValueList;
			
			For Each FoundedString In FoundedStrings Do 
				
				ListOfValues.Add(FoundedString.Value);
				
			EndDo;
			
			NewRow			= Selectors.Add();	
			NewRow.Value 	= ListOfValues;
			
			WriteSelectorRow(NewRow, FoundedString);
			
		Else 
			
			FoundedStrings = Source.FindRows(New Structure("Selector, ComparisonType, AdditionalParameter", SelectorElsement.Selector, SelectorElsement.ComparisonType, SelectorElsement.AdditionalParameter));
			
			For Each FoundedString In FoundedStrings Do
				
				NewRow			= Selectors.Add();	
				NewRow.Value 	= FoundedString.Value;
				
				WriteSelectorRow(NewRow, FoundedString);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndFunction

&AtServer
Function CreateSelectorsTable(Cancel = Undefined)

	SelectorsTable = New ValueTable();
	SelectorsTable.Columns.Add("Selector");
	SelectorsTable.Columns.Add("ComparisonType");
	SelectorsTable.Columns.Add("Value");
	SelectorsTable.Columns.Add("AdditionalParameter");
	
	For Each Item In Selectors Do
		
		If ValueIsFilled(Item.Selector) And ValueIsFilled(Item.ComparisonType) And ValueIsFilled(Item.Value) Then 
			
			If IsList(Item.ComparisonType) Then
				
				For Each ListItem In Item.Value Do
					
					SelectorsTable = WriteSRow(Item, ListItem.Value, SelectorsTable);
					
				EndDo;
				
			Else
				
				SelectorsTable = WriteSRow(Item, Undefined, SelectorsTable);
				
			EndIf;
			
		Else 
			
			If Not Cancel = Undefined Then 
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en='Found blank rows in a tabular section ""Selectors""';ru='Найдены незаполненные строки в табличной части ""Параметры отбора""';cz='Found blank rows in a tabular section ""Selectors""'");
				
				UserMessage.Message();
				
				Cancel = True;
				
				Break;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return SelectorsTable; 

EndFunction

&AtServer
Function WriteSRow(Item, ListItem, SelectorsTable)
	
	Row					= SelectorsTable.Add();
	Row.Selector		= Item.Selector;
	Row.ComparisonType	= Item.ComparisonType;
	
	If Row.Selector = "Catalog_OutletParameter" Then
		
		Row.AdditionalParameter = Item.SelectorRepresent;
		
	Else
		
		Row.AdditionalParameter = Undefined;
		
	EndIf; 
	
	If Not ListItem = Undefined Then
		
		Row.Value = ListItem;
		
	Else
		
		Row.Value = Item.Value;
		
	EndIf;
	
	Return SelectorsTable;
	
EndFunction

&AtServer
Procedure SetOutletsSRsSelected()
	
	TempSelectorsTable = CreateSelectorsTable();
	
	OutletsSelected = Documents.Questionnaire.SelectOutlets(TempSelectorsTable.Copy()).Count();
	
	SRsSelected = Documents.Questionnaire.SelectSRs(TempSelectorsTable, TempSelectorsTable.Copy(New Structure("Selector", "Catalog_Positions"))).Count();
	
EndProcedure

&AtServer
Procedure WriteSelectorRow(NewRow, Selector)
	
	NewRow.Selector			= Selector.Selector;
	NewRow.ComparisonType	= Selector.ComparisonType;
	
	If Selector.Selector = "Catalog_OutletParameter" Then
		
		NewRow.SelectorRepresent	= Selector.AdditionalParameter;
		NewRow.AdditionalParameter	= TypesMap.Get(String(Selector.AdditionalParameter.DataType));
		
	Else
		
		NewRow.SelectorRepresent	= String(Enums.QuestionnaireSelectors[Selector.Selector]);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadSelectors(Cancel) 
	
	SelectorsValueTable = CreateSelectorsTable(Cancel);
	
	If Not Cancel Then 
	
		Object.Selectors.Clear();
		
		For Each Row In SelectorsValueTable Do
			
			NewRecord						= Object.Selectors.Add();
			NewRecord.AdditionalParameter	= Row.AdditionalParameter;
			NewRecord.ComparisonType		= Row.ComparisonType;
			NewRecord.Selector				= Row.Selector;
			NewRecord.Value					= Row.Value;
			NewRecord.StringValue			= GetStringFromValue(Row.Value);
			
		EndDo;
		
	EndIf;
		
EndProcedure

#EndRegion

#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OpenAtServer();
	
	FillAvailableStatuses(Object.Status);
	
	CheckSelectorsForSKUs(Items.QuestionsCheckSelectorsForSKUs);
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	# If WebClient Then
	
	QuestionsOnActivateRow(CurrentPage);
	
	# EndIf
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)	
	
	If EventName = "QuestionnaireForm" + String(ThisForm.UUID) Then
		
		Selectors[Parameter.StringNumber].Value = Parameter.Str;
		SetOutletsSRsSelected();
		
	EndIf;
	
	If EventName = "ScheduleChanged" + String(ThisForm.UUID) Then
		
		Modified = Parameter.Modified;
		
		If Modified Then
			
			Object.Schedule = Parameter.Schedule;
			SetScheduleStringPresentation();
			
		EndIf;
		
	EndIf;

	If EventName = "ValueListOk" + String(ThisForm.UUID) Then
		
		Selectors[Parameter.StringNumber].Value = Parameter.List;
		SetOutletsSRsSelected();
		
	EndIf;
	
EndProcedure

#Region Status

&AtClient
Procedure StatusStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OldStatus = Object.Status;
	
	ShowChooseFromList(New NotifyDescription("StatusChooseFromListProcessing", ThisForm), 
						AvailableStatuses,
						Item,
						AvailableStatuses.FindByValue(OldStatus));
	
EndProcedure

&AtClient
Procedure StatusChooseFromListProcessing(Result, Parameters) Export
	
	If Not Result = Undefined Then
		
		Object.Status = Result.Value;
		StatusOnChange(Items.Status);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	NewStatus = Object.Status;
	
	// Если статус был изменен
	If Not OldStatus = NewStatus Then
		
		// Если новый статус "Готова к работе"
		If StatusIs("Ready") Then
			
			// Если текущая дата позже чем дата начала периода действия анкеты
			If CurrentDate() >= Object.BeginDate Then
				
				// Спрашиваем пользователя хочет ли он сразу сменить статус на "Активна".
				// Если да, то меняется статус на активна, дата начала действия анкеты
				// устанавливается равной текущей дате и записывается документ, из-за чего
				// блокируется шапка.
				// Если нет, устанавливаем статус обратно в значение "Черновик".
				ShowQueryBox(New NotifyDescription("StatusChangeFromPlanningToActiveProcessing", ThisForm),
							NStr("en = 'Current date is after begin date of questionnaire. 
								|Questionnaire status will be automatically set to ""Active"", 
								|begin date of period will be set to current date, document 
								|will be written and header (periodicity, period and 
								|schedule, selectors) will be blocked. Continue?'; 
								|ru = 'Текущая дата больше даты начала действия анкеты. Анкета будет 
								|автоматически переведена в статус ""Активна"", дата начала действия 
								|анкеты будет установлена равной текущей дате, документ будет 
								|записан и шапка (регулярность, период и расписание, селекторы) 
								|будет заблокирована. Продолжить?'"), 
							QuestionDialogMode.YesNo,
							0,
							DialogReturnCode.No,
							NStr("en='Change status to ""Active""?';ru='Изменить статус на ""Активна""?';cz='Změnit stav za ""Aktivní""?'"));
				
			EndIf;
			
		// Если новый статус "Активна"	
		ElsIf StatusIs("Active") Then
			
			// Спрашиваем пользователя хочет ли он сменить дату начала действия анкеты
			// на текущую и записать документ.
			// Если да, меняем статус, меняем дату, записываем документ.
			// Если нет, устанавливаем статус обратно в значение "Готова к работе".
			ShowQueryBox(New NotifyDescription("StatusChangeFromReadyToActiveProcessing", ThisForm),
						NStr("en='Begin date of this questionnaire will be changed to current "
"date. This document will be written and uploaded to server on next "
"synchronization. Document header (periodicity, period and schedule, "
"selectors) will be blocked for changing. Continue?';ru='Дата начала действия данной анкеты будет изменена на текущую "
"дату. Документ будет записан и выгружен на сервер при следующей "
"синхронизации. Шапка документа (регулярность, период и расписание, "
"селекторы) будет заблокирована для изменения. Продолжить?';cz='Begin date of this questionnaire will be changed to current "
"date. This document will be written and uploaded to server on next "
"synchronization. Document header (periodicity, period and schedule, "
"selectors) will be blocked for changing. Continue?'"),
						QuestionDialogMode.YesNo,
						0,
						DialogReturnCode.No,
						NStr("en='Change status to ""Active""?';ru='Изменить статус на ""Активна""?';cz='Změnit stav za ""Aktivní""?'"));
			
		// Если новый статус "Неактивна"
		ElsIf StatusIs("Inactive") Then
			
			// Спрашиваем пользователя хочет ли он сменить дату конца действия анкеты
			// на текущую и записать документ.
			// Если да, меняем статус, меняем дату, записываем документ.
			// Если нет, устанавливаем статус обратно в значение "Активна".
			ShowQueryBox(New NotifyDescription("StatusChangeFromActiveToInactiveProcessing", ThisForm),
						NStr("en='End date of this questionnaire will be changed to current "
"date. This document will be saved and blocked for changing. "
"Continue?';ru='Дата конца периода действия данной анкеты будет изменена на "
"текущую дату. Этот документ будет записан и заблокирован для "
"изменения. Продолжить?';cz='End date of this questionnaire will be changed to current "
"date. This document will be saved and blocked for changing. "
"Continue?'"),
						QuestionDialogMode.YesNo,
						0,
						DialogReturnCode.No,
						NStr("en='Change status to ""Inactive""';ru='Изменить статус на ""Неактивна""';cz='Změnit stav za ""Neaktivní""?'"));
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusChangeFromPlanningToActiveProcessing(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		SetStatusTo("Active");
		
		Object.BeginDate = BegOfDay(CurrentDate());
		
		WriteParameters = GetWriteParameters();
		
		ThisForm.Write(WriteParameters);
		
	ElsIf Result = DialogReturnCode.No Then
		
		SetStatusTo("Planning");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusChangeFromReadyToActiveProcessing(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		SetStatusTo("Active");
		
		Object.BeginDate = BegOfDay(CurrentDate());
		
		WriteParameters = GetWriteParameters();
		
		ThisForm.Write(WriteParameters);
	
	ElsIf Result = DialogReturnCode.No Then
		
		SetStatusTo("Ready");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusChangeFromActiveToInactiveProcessing(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		SetStatusTo("Inactive");
		
		Object.EndDate = EndOfDay(CurrentDate());
		
		WriteParameters = GetWriteParameters();
		
		ThisForm.Write(WriteParameters);
		
	ElsIf Result = DialogReturnCode.No Then
		
		SetStatusTo("Active");
		
	EndIf;
	
EndProcedure

&AtClient
Function GetWriteParameters()
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Write);
	
	Return WriteParameters;

EndFunction

&AtClient
Procedure FillAvailableStatuses(Status)
	
	AvailableStatuses = GetAvailableStatuses(Status);
	
EndProcedure

#EndRegion

#Region EndDate

&AtClient
Procedure EndDateOnChange(Item)
	
	If ValueIsFilled(Object.EndDate) Then
	
		// Если новая дата конца действия анкеты раньше даты начала действия анкеты
		// Ставим новую дату конца действия анкеты равной дате начала действия анкеты
		Object.EndDate = ?(EndOfDay(Object.EndDate) >= EndOfDay(Object.BeginDate),
							Object.EndDate, 
							Object.BeginDate);
		                             
		
		//// Если новая дата окончания действия анкеты меньше чем текущая дата
		//If EndOfDay(Object.EndDate) < EndOfDay(CurrentDate()) Then
		//	
		//	// Устанавливаем дату окончания действия анкеты равной текущей дате
		//	Object.EndDate = CurrentDate();
			
			// Если анкета активна
			If StatusIs("Active") Then
				
				// Спрашиваем у пользователя хочет ли он сменить статус анкеты на "Неактивна".
				// Если да, то меняем статус, записываем документ.
				// Если нет, то оставляем статус старым, дату конца периода действия анкеты
				// устанавливаем равной старой дате (та что записана в объекте).
				ShowQueryBox(New NotifyDescription("ChangeEndDateInActiveStatus", ThisForm),
							NStr("en='New end period date of questionnaire is before current date. "
"Status will be automatically set to value ""Inactive"". End period date "
"of questionnaire will be set to current date."
"Questionnaire will be rewritten and blocked for changing. "
"Continue?';ru='Новая дата конца действия анкеты меньше чем текущая дата. "
"Статус будет автоматически установлен в значение ""Неактивна"", Дата конца "
"действия анкеты будет установлена соответствующей текущей дате."
"Анкета будет перезаписана и заблокирована для изменения. Продолжить?';cz='New end period date of questionnaire is before current date. "
"Status will be automatically set to value ""Inactive"". End period date "
"of questionnaire will be set to current date."
"Questionnaire will be rewritten and blocked for changing. "
"Continue?'"),
							QuestionDialogMode.YesNo,
							0,
							DialogReturnCode.No,
							NStr("en='Change status to ""Inactive""?';ru='Изменить статус на ""Неактивна""?';cz='Změnit stav za ""Neaktivní""?'"));
				
			EndIf;
			
		//EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeEndDateInActiveStatus(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		SetStatusTo("Inactive");
		
		WriteParameters = New Structure;
		WriteParameters.Insert("WriteMode", DocumentWriteMode.Write);
		
		ThisForm.Write(WriteParameters);
		
	ElsIf Result = DialogReturnCode.No Then
		
		Object.EndDate = GetOldEndDate();
		
	EndIf;
	
EndProcedure

&AtServer
Function GetOldEndDate()
	
	Return Object.Ref.EndDate;
	
EndFunction

#EndRegion

#Region Schedule

&AtClient
Procedure SetSchedule(Command)
	
	PrevSchedule = Object.Schedule;
	
	Params = New Structure("Schedule, Source", Object.Schedule, "ScheduleChanged" + String(ThisForm.UUID));
	
	OpenForm("CommonForm.ScheduleForm", Params);
	
EndProcedure

&AtClient
Procedure RegularityOnChange(Item)
	
	Object.Single = ?(Regularity = "Single", True, False);
	
	Items.FillPeriod.Enabled = Object.Single;
	
EndProcedure

#EndRegion

#Region Selectors

&AtClient
Procedure SelectorsTableOnChange(Item)
	
	SetOutletsSRsSelected();
	
EndProcedure

&AtClient
Procedure SelectOutlets(Command)
	
	SetOutletsSRsSelected();
	
EndProcedure

&AtClient
Procedure SelectorsTableOnStartEdit(Item, NewRow, Clone)

	If NewRow Then 
		
		Items.SelectorsTable.CurrentData.ComparisonType = GetEqualComparisonType();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectorsTableBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	If Selectors.Count() = 10 Then 
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='Available only 10 selectors';ru='Доступно только 10 параметров отбора';cz='Available only 10 selectors'");
		
		UserMessage.Message();
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectorsSelectorRepresentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowChooseFromList(New NotifyDescription("SelectorsSelectorRepresentChoiseProcessing", ThisForm), GetSelectorList(), Item, );
	
EndProcedure

&AtClient
Procedure SelectorsSelectorRepresentChoiseProcessing(Result, AdditionalParameter) Export
	
	Row = Selectors.FindByID(Items.SelectorsTable.CurrentRow);
	
	If Not Result = Undefined Then
		
		If Not Row.Selector = Result.Value Then 
			
			Row.Selector = Result.Value;
			
			Row.Value = Undefined;
			
		EndIf;
		
		If Not IsOutletParameter(Result.Value) Then
			
			Row.SelectorRepresent = Result.Presentation;
			
		Else
			
			ChoiceForm = GetForm("Catalog.OutletParameter.ChoiceForm");
			
			Filter = ChoiceForm.List.Filter;
			
			FilterElement 					= Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue 		= New DataCompositionField("Ref.DataType");
			FilterElement.Use 				= True;
			FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
			FilterElement.ComparisonType	= DataCompositionComparisonType.NotEqual;
			FilterElement.RightValue		= GetSnapshotDataType();
			
			ChoiceForm.OnCloseNotifyDescription	= New NotifyDescription("SelectorsSelectorChoiseProcessing", ThisForm);
			ChoiceForm.WindowOpeningMode		= FormWindowOpeningMode.LockWholeInterface;
			
			ChoiceForm.Open();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectorsSelectorChoiseProcessing(Result, AdditionalParameter) Export 
	
	If Not Result = Undefined Then
		
		Row = Selectors.FindByID(Items.SelectorsTable.CurrentRow);
		
		If Not Row.SelectorRepresent = Result Then 
			
			Row.Value = Undefined;
			
		EndIf;
		
		Row.SelectorRepresent = Result;
		
		Row.AdditionalParameter = GetParameterType(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectorsValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.SelectorsTable.CurrentData.SelectorRepresent = Undefined Or Items.SelectorsTable.CurrentData.Selector = Undefined Then
		
		Return;
		
	EndIf;
	
	If Not IsList(Items.SelectorsTable.CurrentData.ComparisonType) Then 
		
		If Not IsOutletParameter(Items.SelectorsTable.CurrentData.Selector) Then
			
			Str = StrReplace(Items.SelectorsTable.CurrentData.Selector, "_", ".");
			
			OpenForm(Str + ".ChoiceForm", , Item, , , , , FormWindowOpeningMode.LockWholeInterface);
			
		Else
			
			OpenForm("Document.Questionnaire.Form.Input", New Structure("StringNumber, DataType, OutletParameter, Source, CurrentValue", Selectors.IndexOf(Items.SelectorsTable.CurrentData), Items.SelectorsTable.CurrentData.AdditionalParameter, Items.SelectorsTable.CurrentData.SelectorRepresent, "QuestionnaireForm" + String(ThisForm.UUID), Items.SelectorsTable.CurrentData.Value));
			
		EndIf;
		
	Else
		
		OpenForm("Document.Questionnaire.Form.SelectorsListForm", New Structure("StringNumber, Selector, DataType, CurrentValue, OutletParameter, Source", Selectors.IndexOf(Items.SelectorsTable.CurrentData), Items.SelectorsTable.CurrentData.Selector, Items.SelectorsTable.CurrentData.AdditionalParameter, Items.SelectorsTable.CurrentData.Value, Items.SelectorsTable.CurrentData.SelectorRepresent, "ValueListOk" + String(ThisForm.UUID)));
		
	EndIf

EndProcedure

&AtClient
Procedure SelectorsComparisonTypeChoiceProcessing(Item, SelectedValue, StandardProcessing)

	
	If Not Items.SelectorsTable.CurrentData.Value = Undefined And Not Items.SelectorsTable.CurrentData.ComparisonType = SelectedValue Then
		
		If IsList(Items.SelectorsTable.CurrentData.ComparisonType) Then
			
			Items.SelectorsTable.CurrentData.Value = Items.SelectorsTable.CurrentData.Value[0].Value;
			
		EndIf; 
		
		If IsList(SelectedValue) Then
			
			ListOfValues = new ValueList;
			ListOfValues.Add(Items.SelectorsTable.CurrentData.Value);
			
			Items.SelectorsTable.CurrentData.Value = ListOfValues;
			
		EndIf; 
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectorsComparisonTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region Questions

&AtClient
Procedure AddQuestion(Command)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		ItemElement	= Items.SKUQuestions;
		Tree		= SKUQuestions;
		RightValue	= GetQuestionGroupType("SKUQuestions");
		
	Else 
		
		ItemElement	= Items.RegularQuestions;
		Tree		= RegularQuestions;
		RightValue	= GetQuestionGroupType("RegularQuestions");
		
	EndIf;
	
	If CheckAdding(Tree, ItemElement.CurrentRow) Then
		
		IsChildQuestionAdding = True;
		
		ChoiseForm = GetForm("Catalog.Question.Form.ChoiceFormWithGroups");
		
		FilterOfList = ChoiseForm.List.Filter;
		
		FilterElement				= FilterOfList.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue		= New DataCompositionField("Owner.Type");
		FilterElement.Use			= True;
		FilterElement.ViewMode		= DataCompositionSettingsItemViewMode.Inaccessible;
		FilterElement.RightValue	= RightValue;
		
		ChoiseForm.FormOwner			= ItemElement;
		ChoiseForm.CloseOnChoice		= False;
		ChoiseForm.CloseOnOwnerClose	= True;
		
		ChoiseForm.Open();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddParentQuestion(Command)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		ItemElement	= Items.SKUQuestions;
		Tree		= SKUQuestions;
		RightValue	= GetQuestionGroupType("SKUQuestions");
		
	Else 
		
		ItemElement	= Items.RegularQuestions;
		Tree		= RegularQuestions;
		RightValue	= GetQuestionGroupType("RegularQuestions");
		
	EndIf;
	
	IsChildQuestionAdding = False;
	
	ChoiseForm = GetForm("Catalog.Question.Form.ChoiceFormWithGroups");
	
	ChoiseForm.CurrentItem.AdditionalCreateParameters = New FixedStructure("GroupType", RightValue);
	
	FilterOfList = ChoiseForm.List.Filter;
	
	FilterElement				= FilterOfList.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("Owner.Type");
	FilterElement.Use			= True;
	FilterElement.ViewMode		= DataCompositionSettingsItemViewMode.Inaccessible;
	FilterElement.RightValue	= RightValue;
	
	ChoiseForm.FormOwner			= ItemElement;
	ChoiseForm.CloseOnChoice		= False;
	ChoiseForm.CloseOnOwnerClose	= True;
	
	ChoiseForm.Open();
	
EndProcedure

&AtClient
Procedure ClearParentOnQuestion(Command)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		If Not Items.SKUQuestions.CurrentRow = Undefined Then 
			
			Source = SKUQuestions.FindByID(Items.SKUQuestions.CurrentRow);
			
			ClearParent(SKUQuestions, Source);
			
		EndIf;
		
	Else 
		
		If Not Items.RegularQuestions.CurrentRow = Undefined Then
			
			Source = RegularQuestions.FindByID(Items.RegularQuestions.CurrentRow);
			
			ClearParent(RegularQuestions, Source);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RegularQuestionsBeforeDeleteRow(Item, Cancel)
	
	For Each SelectedRows In Item.SelectedRows Do	
		DeleteQuestion(Cancel,SelectedRows);
	EndDo

EndProcedure

&AtClient
Procedure SKUQuestionsBeforeDeleteRow(Item, Cancel)
	
	For Each SelectedRows In Item.SelectedRows Do	
		DeleteQuestion(Cancel,SelectedRows);
	EndDo
	
EndProcedure

&AtClient
Procedure DeleteQuestion(Cancel,SelectedRows)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		ItemElement		= Items.SKUQuestions;
		Tree			= SKUQuestions;
		DeletedTable	= DeletedSKUQuestions;
		
	Else 
		
		ItemElement		= Items.RegularQuestions;
		Tree			= RegularQuestions;
		DeletedTable	= DeletedRegularQuestions;
		
	EndIf;
		
	If Not ItemElement.CurrentData = Undefined And Not ItemElement.CurrentRow = Undefined Then 
			
		CurrentRow = Tree.FindByID(SelectedRows);
		
		CurrenRowItems = CurrentRow.GetItems();
		
		If Not CurrenRowItems.Count() = 0 Then 
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en='At question has dependent issues. Deletion is disabled';ru='У вопроса есть зависимые вопросы. Удаление невозможно';cz='Nelze odstranit, protože všechny dotazy mají podřizené položky. Odstranění bylo zrušeno.'");
			
			UserMessage.Message();
			
			Cancel = True;
			
		Else 
			
			If CurrentRow.IsOldQuestion Then 
			
				InsDeletedRow					= DeletedTable.Add();
				InsDeletedRow.StatusDate		= CurrentDate();
				InsDeletedRow.Question			= CurrentRow.Question;
				InsDeletedRow.Obligatoriness	= CurrentRow.Obligatoriness;
				
				CurrentParent = CurrentRow.GetParent();
				
				If Not CurrentParent = Undefined Then 
					
					InsDeletedRow.ParentQuestion = CurrentParent.Question;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		If IsChildQuestionAdding Then 
			
			AddQuestionsToTree(SelectedValue, SKUQuestions, Items.SKUQuestions, SKUQuestions.FindByID(Items.SKUQuestions.CurrentRow), Items.SKUQuestions.CurrentRow);
			
		Else 
			
			AddQuestionsToTree(SelectedValue, SKUQuestions, Items.SKUQuestions);	
			
		EndIf;
			
	Else 
		
		If IsChildQuestionAdding Then
			
			AddQuestionsToTree(SelectedValue, RegularQuestions, Items.RegularQuestions, RegularQuestions.FindByID(Items.RegularQuestions.CurrentRow), Items.RegularQuestions.CurrentRow);
			
		Else 
			
			AddQuestionsToTree(SelectedValue, RegularQuestions, Items.RegularQuestions);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionsQuestionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SKUQuestionsQuestionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure QuestionsObligatorinessOnChange(Item)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		ItemElement = Items.SKUQuestions;
		
	Else 
		
		ItemElement = Items.RegularQuestions;
		
	EndIf;
	
	If Not ItemElement.CurrentData = Undefined Then 
		
		If ItemElement.CurrentData.IsOldQuestion Then 
		
			ItemElement.CurrentData.Status		= GetStatusToRow("Modified");
			ItemElement.CurrentData.StatusDate	= CurrentDate();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		Tree = SKUQuestions;
		
	Else 
		
		Tree = RegularQuestions;
		
	EndIf;
	
	IDNewParent = Row;
	
	NewParent = ?(IDNewParent = Undefined, Undefined, Tree.FindByID(IDNewParent));
	
	ArrayIDElements = DragParameters.Value;
	
	For Each IDElement In ArrayIDElements Do 
		
		If Not IDElement = Undefined Then
		
			Element = Tree.FindByID(IDElement);
		
			If Not DragAvailable(Element, NewParent) Then 
				
				DragParameters.Action = DragAction.Cancel;
				
				Break;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure QuestionsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		ItemElement	= Items.SKUQuestions;
		Tree		= SKUQuestions;
		
	Else 
		
		ItemElement	= Items.RegularQuestions;
		Tree		= RegularQuestions;
		
	EndIf;
	
	IDReceiver = Row;
	
	Receiver = ?(IDReceiver = Undefined, Undefined, Tree.FindByID(IDReceiver));
	
	ArrayIDSource = DragParameters.Value;
	
	For Each IDSource In ArrayIDSource Do 
		
		If Not IDSource = Undefined Then 
		
			Source = Tree.FindByID(IDSource); 
			
			NewRow = CopyRow(Tree, Receiver, Source);
			
			If Receiver = Undefined And Not NewRow = Undefined Then 
				
				ItemElement.Expand(NewRow.GetID(), True);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not Receiver = Undefined Then 
		
		ItemElement.Expand(IDReceiver, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscardСhanges(Command)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		DeletedSKUQuestions.Clear();
		
		FillQuestionsTree(GetQuestionGroupType("SKUQuestions"));
		
	Else 
		
		DeletedRegularQuestions.Clear();
		
		FillQuestionsTree(GetQuestionGroupType("RegularQuestions"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionsOnActivateRow(Item)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		If Items.SKUQuestions.CurrentData = Undefined Then 
			
			Items.SKUQuestionsAddChildQuestion.Enabled				= False;
			Items.SKUQuestionsAddChildQuestionContext.Enabled		= False;
			Items.SKUQuestionsClearParentOnQuestionContext.Enabled	= False;
			
		Else
			
			If IsLogicAnswerType(Items.SKUQuestions.CurrentData.Question) Then 
				
				Items.SKUQuestionsAddChildQuestion.Enabled			= True;
				Items.SKUQuestionsAddChildQuestionContext.Enabled	= True;
				
			Else 
				
				Items.SKUQuestionsAddChildQuestion.Enabled			= False;
				Items.SKUQuestionsAddChildQuestionContext.Enabled	= False;
				
			EndIf;
			
			ItemElement = SKUQuestions.FindByID(Items.SKUQuestions.CurrentData.GetID());
			
			If ItemElement.GetParent() = Undefined Then 
				
				Items.SKUQuestionsClearParentOnQuestionContext.Enabled = False;
				
			Else 
				
				Items.SKUQuestionsClearParentOnQuestionContext.Enabled = True;
				
			EndIf;
			
		EndIf;
		
	Else 
		
		If Items.RegularQuestions.CurrentData = Undefined Then 
			
			Items.QuestionsAddChildQuestion.Enabled					= False;
			Items.QuestionsAddChildQuestionContext.Enabled			= False;
			Items.QuestionsClearParentOnQuestionContext.Enabled		= False;
			
		Else
			
			If IsLogicAnswerType(Items.RegularQuestions.CurrentData.Question) Then 
				
				Items.QuestionsAddChildQuestion.Enabled				= True;
				Items.QuestionsAddChildQuestionContext.Enabled		= True;
				
			Else 
				
				Items.QuestionsAddChildQuestion.Enabled				= False;
				Items.QuestionsAddChildQuestionContext.Enabled		= False;
				
			EndIf;
			
			ItemElement = RegularQuestions.FindByID(Items.RegularQuestions.CurrentData.GetID());
			
			If ItemElement.GetParent() = Undefined Then 
				
				Items.QuestionsClearParentOnQuestionContext.Enabled = False;
				
			Else 
				
				Items.QuestionsClearParentOnQuestionContext.Enabled = True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetObligatoriness(Command)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		Tree = SKUQuestions;
		
	Else 
		
		Tree = RegularQuestions;
		
	EndIf;

	DeletedRowStatus	= GetStatusToRow("Deleted");
	MobifiedRowStatus	= GetStatusToRow("Modified");
	
	For Each TreeElement In Tree.GetItems() Do 
		
		If TreeElement.Status = DeletedRowStatus Then 
			
			Continue;
			
		Else 
			
			If Not TreeElement.Obligatoriness Then 
				
				TreeElement.Obligatoriness = True;
				
				If TreeElement.IsOldQuestion Then 
					
					TreeElement.Status = MobifiedRowStatus;
					
				EndIf;
					
				TreeElement.StatusDate = CurrentDate();
				
			EndIf;
			
			For Each ChildElement In TreeElement.GetItems() Do
				
				If ChildElement.Status = DeletedRowStatus Then 
					
					Continue;
					
				Else 
					
					If Not ChildElement.Obligatoriness Then
						
						ChildElement.Obligatoriness = True;	
						
						If ChildElement.IsOldQuestion Then 
							
							ChildElement.Status = MobifiedRowStatus;
							
						EndIf;
						
						ChildElement.StatusDate = CurrentDate();
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UnsetObligatoriness(Command)
	
	If Items.Pages.CurrentPage = Items.GroupSKUQuestions Then
		
		Tree = SKUQuestions;
		
	Else 
		
		Tree = RegularQuestions;
		
	EndIf;

	DeletedRowStatus	= GetStatusToRow("Deleted");
	MobifiedRowStatus	= GetStatusToRow("Modified");
	
	For Each TreeElement In Tree.GetItems() Do 
		
		If TreeElement.Status = DeletedRowStatus Then 
			
			Continue;
			
		Else 
			
			If TreeElement.Obligatoriness Then
			
				TreeElement.Obligatoriness = False;
				
				If TreeElement.IsOldQuestion Then 
					
					TreeElement.Status = MobifiedRowStatus;
					
				EndIf;
					
				TreeElement.StatusDate = CurrentDate();
				
			EndIf;
			
			For Each ChildElement In TreeElement.GetItems() Do
				
				If ChildElement.Status = DeletedRowStatus Then 
					
					Continue;
					
				Else 
					
					If ChildElement.Obligatoriness Then
					
						ChildElement.Obligatoriness = False;	
						
						If ChildElement.IsOldQuestion Then 
							
							ChildElement.Status = MobifiedRowStatus;
							
						EndIf;
							
						ChildElement.StatusDate = CurrentDate();
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region SKUs

&AtClient
Procedure SKUSourceTypeStartChoice(Item, ChoiceData, StandardProcessing)
	
	OldSKUSourceType = Object.SKUSourceType;
	
EndProcedure

&AtClient
Procedure SKUSourceTypeChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	If Not SelectedValue = Undefined Then
		
		If Not SKUsValueTable.Count() = 0 And ValueIsFilled(Object.SKUSourceType) And Not OldSKUSourceType = SelectedValue Then
			
			ShowQueryBox(New NotifyDescription("AfterQuestionClose", ThisForm, SelectedValue),
						NStr("en = 'All rows with catalog """ + String(OldSKUSourceType) + """ elements will be deleted. Continue?'; ru = 'Все строки являющиеся элементами справочника """ + String(OldSKUSourceType) + """ будут удалены. Продолжить?'"),
						QuestionDialogMode.YesNo,
						0,
						DialogReturnCode.No,
						NStr("en = 'Value table сhange '; ru = 'Изменение табличной части'"));
		ElsIf Object.SKUSourceType=ReturnSourceTypeBrand() Then
			Items.SelectSkuGroup.Enabled = True;
			Items.SKUsValueTableSelectSku.Enabled = True;
			Items.GroupSkusTabel.CurrentPage=Items.SkusWithoutSelect;
			Items.SelectSkuGroup.Check = False;
			Items.SKUsValueTableSelectSku.Check = False;
		Else
			Items.SelectSkuGroup.Enabled = False;
			Items.SKUsValueTableSelectSku.Enabled = False;
			Items.GroupSkusTabel.CurrentPage=Items.SkusWithoutSelect;
			Items.SelectSkuGroup.Check = False;
			Items.SKUsValueTableSelectSku.Check = False;		
		EndIf;	

	EndIf;
	
EndProcedure

&AtServer
Function ReturnSourceTypeBrand()
	
	Return Enums.SKUSourceTypes.Brand;	
	
EndFunction
&AtClient 
Procedure AfterQuestionClose(Result, Parameter) Export
	
	If Result = DialogReturnCode.Yes Then
		
		Object.SKUSourceType = Parameter;
		If Object.SKUSourceType = ReturnSourceTypeBrand() Then
			Items.SelectSkuGroup.Enabled = False;
			Items.SKUsValueTableSelectSku.Enabled = False;
			Items.GroupSkusTabel.CurrentPage=Items.SkusWithoutSelect;
			Items.SelectSkuGroup.Check = False;
			Items.SKUsValueTableSelectSku.Check = False;			
		Else
			Items.SelectSkuGroup.Enabled = True;
			Items.SKUsValueTableSelectSku.Enabled = True;
		EndIf;
		If ValueIsFilled(OldSKUSourceType) And Not OldSKUSourceType = Object.SKUSourceType Then
		
			FilterParameters = New Structure;
			FilterParameters.Insert("SourceType", String(OldSKUSourceType));
			
			RowsArray = SKUsValueTable.FindRows(FilterParameters);
			
			Modified = RowsArray.Count() > 0;
			
			For Each Row In RowsArray Do;
				
				Index = SKUsValueTable.IndexOf(Row);
				SKUsValueTable.Delete(Index);
				
			EndDo;
			
		EndIf;
		
	Else 
		
		Object.SKUSourceType = OldSKUSourceType;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SKUsValueTableOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then 
	
		ID	= Item.CurrentRow;
		Row	= SKUsValueTable.FindByID(ID);
		
		If ValueIsFilled(Row.SKU) Then
			
			Row.SourceType = TypeOf(Row.SKU);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SKUsValueTableSKUStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TypesArray = New ValueList;
	TypesArray.Add("Catalog.SKU", NStr("en='SKU';ru='Номенклатура';cz='Zboží'"));
	
	If Object.SKUSourceType = GetSKUSourceType("SKUGroup") Then
		
		TypesArray.Add("Catalog.SKUGroup", NStr("en='SKU Group';ru='Группа номенклатуры';cz='Skupina zboží '"));
		
	EndIf;
		
	If Object.SKUSourceType = GetSKUSourceType("Brand") Then
		
		TypesArray.Add("Catalog.Brands", NStr("en='Brand';ru='Бренд';cz='Značka'"));
		
	EndIf;
	
	ShowChooseFromList(New NotifyDescription("SKUsValueTableSKUChoiceProcessing", ThisForm), TypesArray, Item, );
	
EndProcedure

&AtClient
Procedure SKUsValueTableSKUChoiceProcessing(Result, AdditionalParameter) Export 
	
	If Not Result = Undefined Then	
		
		If Result.Value = "Catalog.SKU" Or Result.Value = "Catalog.SKUGroup" Then 
			
			FilterOfList = GetDataCompositionFilter(Result.Value);
			
			ChoiseForm = GetForm(Result.Value + ".ChoiceForm");
			
			For Each FilterItem In FilterOfList.Items Do 
				
				NewFilterItem = ChoiseForm.List.Filter.Items.Add(Type("DataCompositionFilterItem"));
				
				FillPropertyValues(NewFilterItem, FilterItem);	
				
			EndDo;
			
			ChoiseForm.OnCloseNotifyDescription	= New NotifyDescription("CheckSKUValue", ThisForm, Result);
			ChoiseForm.WindowOpeningMode		= FormWindowOpeningMode.LockWholeInterface;
			
			ChoiseForm.Open();
			
		ElsIf Result.Value = "Catalog.Brands" Then
			
			OpenForm("Catalog.Brands.ChoiceForm"
					, 
					, 
					, 
					, 
					, 
					, New NotifyDescription("CheckSKUValue", ThisForm, Result)
					, FormWindowOpeningMode.LockWholeInterface);	
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckSKUValue(Result, AdditionalParameter) Export 
	
	If Not Result = Undefined Then
		
		FoundedRows = SKUsValueTable.FindRows(New Structure("SKU", Result));
		
		If Not FoundedRows.Count() = 0 Then 
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en = 'Value """ + String(Result) + """ has already been added'; ru = 'Значение """ + String(Result) + """ уже добавлено'");
			
			UserMessage.Message();
			
			SKUsValueTableSKUChoiceProcessing(AdditionalParameter, Undefined);
			
		Else 
			
			IsCorrect = False;
			
			If TypeOf(Result) = Type("CatalogRef.Brands") Then 
				
				CheckBrand(Result, IsCorrect);
				
			ElsIf TypeOf(Result) = Type("CatalogRef.SKUGroup") Then
				
				CheckGroup(Result, IsCorrect);
				
			Else 
				
				IsCorrect = True;
				
			EndIf;
			
			If IsCorrect Then 
				
				Items.SKUsValueTable.CurrentData.SKU = Result;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure
	
&AtClient
Procedure CheckSelectorsForSKUs(Command)
	
	SKUArray		= New Array;
	SKUGroupsArray	= New Array;
	
	For Each Element In SKUsValueTable Do 
		
		If TypeOf(Element.SKU) = Type("CatalogRef.SKU") Then 
			
			SKUArray.Add(Element.SKU);
			
		EndIf;
		
		If TypeOf(Element.SKU) = Type("CatalogRef.SKUGroup") Then 
			
			SKUGroupsArray.Add(Element.SKU);
			
		EndIf;
		
	EndDo;
	
	FilterOfSKUList			= GetDataCompositionFilter("Catalog.SKU", "Ref.");
	FilterOfSKUGroupList	= GetDataCompositionFilter("Catalog.SKUGroup", "Ref.");
	
	If Not SKUArray.Count() = 0 And Not FilterOfSKUList.Items.Count() = 0 Then 
		
		SKUArray = CheckSelectorsForSKUsAtServer("Catalog.SKU", FilterOfSKUList, SKUArray);
		
	EndIf;
	
	If Not SKUGroupsArray.Count() = 0 And Not FilterOfSKUGroupList.Items.Count() = 0 Then 
		
		SKUGroupsArray = CheckSelectorsForSKUsAtServer("Catalog.SKUGroup", FilterOfSKUGroupList, SKUGroupsArray);
		
	EndIf;
	
	For Each Element In SKUsValueTable Do
		
		If TypeOf(Element.SKU) = Type("CatalogRef.SKU") Then 
			
			If SKUArray.Find(Element.SKU) = Undefined Then 
				
				Element.Index = 1;
				
			Else 
				
				Element.Index = 0;
				
			EndIf;
			
		ElsIf TypeOf(Element.SKU) = Type("CatalogRef.SKUGroup") Then 
			
			If SKUGroupsArray.Find(Element.SKU) = Undefined Then 
				
				Element.Index = 1;
				
			Else 
				
				Element.Index = 0;
				
			EndIf;
			
		Else 
			
			Element.Index = 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ToogleSkuGroupSelect(Command)
			
	IsSelectHidden = Items.GroupSkusTabel.CurrentPage = Items.SkusWithoutSelect Or Items.GroupSkusTabel.CurrentPage = Items.SkusWithSelect;
	
	CurrentFormTable = ?(IsSelectHidden, "SKUsValueTable", "SKUsValueTable1");
	NextFormTable = ?(IsSelectHidden, "SKUsValueTable1", "SKUsValueTable");
	
	Items[NextFormTable].CurrentRow = Items[CurrentFormTable].CurrentRow;
	
	Items.GroupSkusTabel.CurrentPage = ?(IsSelectHidden, Items.SkusWithSelectGroup, Items.SkusWithoutSelect);
	
	ThisForm.CurrentItem = Items[NextFormTable];
	
	If ThisForm.CurrentItem.Name = "SKUsValueTable" Then 
		Items.SelectSkuGroup.Check = False;
		Items.SKUsValueTableSelectSku.Check = False;
	Else 
		Items.SelectSkuGroup.Check = True;
		Items.SKUsValueTableSelectSku.Check = False;		
	EndIf;
	


EndProcedure

&AtClient
Procedure AddSkusFromSelect(Command)
		
	AddToSkusVT(ThisForm.Items.SkusSelect.SelectedRows);

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
Function GetArrayWithSelect(ArrayInFolder)
	
	SKUGroupsArray	= ArrayInFolder;
		
	FilterOfSKUGroupList	= GetDataCompositionFilter("Catalog.SKUGroup", "Ref.");
		
	If Not SKUGroupsArray.Count() = 0 And Not FilterOfSKUGroupList.Items.Count() = 0 Then 
		
		SKUGroupsArray = CheckSelectorsForSKUsAtServer("Catalog.SKUGroup", FilterOfSKUGroupList, SKUGroupsArray);
		
	EndIf;
	
	Return SKUGroupsArray;
	
EndFunction
&AtClient
Procedure AddAllSkusFromSelect(Command)
			
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
	If Items.GroupSkusTabel.CurrentPage.Name = "SkusWithSelectGroup" Then			
		DataSet.Query = SkusGroupSelect.QueryText;
	Else
		DataSet.Query = SkusSelect.QueryText;
	EndIf;						
	
	DataSet.DataSource = "DataSource1";
	DataSet.AutoFillAvailableFields = True;
	
	DCG = DCS.DefaultSettings.Structure.Add(Type("DataCompositionGroup"));
	DCG.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	DCG.Use = True;
	
	FieldsArray = New Array;
	
	If Items.GroupSkusTabel.CurrentPage.Name = "SkusWithSelectGroup" Then			
		FieldsArray.Add("SkuGroup");
	Else
		FieldsArray.Add("SKU");
	EndIf;						

	
	For Each FieldName In FieldsArray Do
		
		NewField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field = FieldName;
		NewField.DataPath = FieldName;
		NewField.Title = FieldName;
		
		ChoiceField = DCS.DefaultSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		ChoiceField.Field = New DataCompositionField(FieldName);
		ChoiceField.Use = True;
		
	EndDo;
	
	If Items.GroupSkusTabel.CurrentPage.Name = "SkusWithSelectGroup" Then			
		FillDataCompositionSchemeFilters(DCS, SkusGroupSelect.Filter.Items);
	Else
		FillDataCompositionSchemeFilters(DCS, SkusSelect.Filter.Items);
	EndIf;						

	
	
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
	If Items.GroupSkusTabel.CurrentPage.Name = "SkusWithSelectGroup" Then			
		Return SkusGroupVT.UnloadColumn("SkuGroup");
	Else
		Return SkusGroupVT.UnloadColumn("SKU");
	EndIf;						
	
	
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

&AtClient
Procedure RemoveSkuGroup(Command)
			
	CurrentItem = ?(Items.GroupSkusTabel.CurrentPage = Items.SkusWithSelectGroup, Items.SKUsValueTable1, Items.SKUsValueTable2);
	
	If Not CurrentItem.CurrentData = Undefined Then
		
		
		Index =SKUsValueTable.IndexOf(CurrentItem.CurrentData);
		SKUsValueTable.Delete(Index);
		
		Modified = True;
		
		
	EndIf;
	

EndProcedure

&AtClient
Procedure RemoveAllSkuGroup(Command)
			
	CurrentItem = ?(Items.GroupSkusTabel.CurrentPage = Items.SkusWithSelect, Items.SKUsValueTable2, Items.SKUsValueTable1);
	
	Rows = SKUsValueTable.FindRows(New Structure(CurrentItem.RowFilter));
	
	For Each Row In Rows Do
		If Items.GroupSkusTabel.CurrentPage.Name = "SkusWithSelectGroup" Then
			If Row.SourceType = "Группа номенклатуры" Then  
				Index = SKUsValueTable.IndexOf(Row);
				SKUsValueTable.Delete(Index);			
				Modified = True;
			EndIf;
		EndIf;
		If Items.GroupSkusTabel.CurrentPage.Name = "SkusWithSelect" Then
			If Row.SourceType = "Номенклатура" Then  
				Index = SKUsValueTable.IndexOf(Row);
				SKUsValueTable.Delete(Index);			
				Modified = True;
			EndIf;
		EndIf;
	
	EndDo;
	
EndProcedure

&AtClient
Procedure ToogleSkuSelect(Command)
	
				
	IsSelectHidden = Items.GroupSkusTabel.CurrentPage = Items.SkusWithoutSelect Or Items.GroupSkusTabel.CurrentPage=Items.SkusWithSelectGroup;
	
	CurrentFormTable = ?(IsSelectHidden, "SKUsValueTable", "SKUsValueTable2");
	NextFormTable = ?(IsSelectHidden, "SKUsValueTable2", "SKUsValueTable");
	
	Items[NextFormTable].CurrentRow = Items[CurrentFormTable].CurrentRow;
	
	Items.GroupSkusTabel.CurrentPage = ?(IsSelectHidden, Items.SkusWithSelect, Items.SkusWithoutSelect);
	
	ThisForm.CurrentItem = Items[NextFormTable];
	If ThisForm.CurrentItem.Name = "SKUsValueTable" Then 
		Items.SelectSkuGroup.Check = False;
		Items.SKUsValueTableSelectSku.Check = False;
	Else 
		Items.SKUsValueTableSelectSku.Check = True;
		Items.SelectSkuGroup.Check = False;		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddSkuFromSelect(Command)
	
	AddToSkusVT(ThisForm.Items.SkusSelect1.SelectedRows);
	
EndProcedure

&AtClient
Procedure AddToSkusVT(SkusArray)
	
	For Each SKU In SkusArray Do		
		If Items.GroupSkusTabel.CurrentPage.Name = "SkusWithSelectGroup" Then			
			If ItsFolder(SKU) Then 
				ArrayInFolder = GetArraySkusGroupFromFolder(SKU);
				ArrayInFolder = GetArrayWithSelect(ArrayInFolder);
				For Each ElInFolder In ArrayInFolder Do
					FilterParameters = New Structure;
					FilterParameters.Insert("SKU", ElInFolder);
					
					If SKUsValueTable.FindRows(FilterParameters).Count() = 0 Then			
						NewSKUGroupsRow = SKUsValueTable.Add();
						NewSKUGroupsRow.SKU = ElInFolder;
						NewSKUGroupsRow.SourceType = "Группа номенклатуры";
						Modified = True;			
					EndIf;
					
				EndDo;
				Else
				FilterParameters = New Structure;
				FilterParameters.Insert("SKU", SKU);	
			If SKUsValueTable.FindRows(FilterParameters).Count() = 0 Then			
				NewSKUGroupsRow = SKUsValueTable.Add();
				NewSKUGroupsRow.SKU = SKU;
				NewSKUGroupsRow.SourceType = "Группа номенклатуры";
				Modified = True;			
			EndIf;
		
			EndIf;
		Else
				FilterParameters = New Structure;
				FilterParameters.Insert("SKU", SKU);	
			If SKUsValueTable.FindRows(FilterParameters).Count() = 0 Then			
				NewSKUGroupsRow = SKUsValueTable.Add();
				NewSKUGroupsRow.SKU = SKU;
				NewSKUGroupsRow.SourceType = "Номенклатура";
				Modified = True;			
			EndIf;
	
		EndIf;
		
				
	EndDo;
	
EndProcedure

&AtClient
Procedure SkusSelect(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	If Not Item.CurrentData = Undefined Then
		If Items.GroupSkusTabel.CurrentPage.Name="SkusWithSelectGroup" Then				
			SkuGroup = Item.CurrentData.SkuGroup;
		Else 
			SkuGroup = Item.CurrentData.SKU;
		EndIf;			
		SkusArray = New Array;
		SkusArray.Add(SkuGroup);
		AddToSkusVT(SkusArray);
	
	EndIf;
	
EndProcedure

&AtServer
Function GetRefEnumsComp()
	
	StructureForRef = New Structure();
	StructureForRef.Insert("Equal",Enums.ComparisonType.Equal);
	StructureForRef.Insert("InList",Enums.ComparisonType.InList);
	StructureForRef.Insert("NotEqual",Enums.ComparisonType.NotEqual);
	Return StructureForRef;
	
EndFunction
&AtServer
Procedure FillComprasionInSelect()
	
	StructureForRef = GetRefEnumsComp();
	SkusSelect.Filter.Items.Clear();
	SkusGroupSelect.Filter.Items.Clear();
	For Each Elem In Selectors Do
		If Elem.Selector = "Catalog_Territory" Or Elem.Selector="Catalog_Region" Then 
			
			FilterElement					= SkusGroupSelect.Filter.Items.Add(Type("DataCompositionFilterItem"));
			If Elem.Selector = "Catalog_Territory" Then
				FilterElement.LeftValue			= New DataCompositionField("SkuGroup.Territories.Territory");
			Else 
				FilterElement.LeftValue			= New DataCompositionField("SkuGroup.Territories.Territory.Owner");
			EndIf;
			FilterElement.Use				= True;
			If Elem.ComparisonType = StructureForRef.Equal Then
				FilterElement.ComparisonType	= DataCompositionComparisonType.Equal;
			EndIf;	
			If Elem.ComparisonType = StructureForRef.InList Then
				FilterElement.ComparisonType	= DataCompositionComparisonType.InList;
			EndIf;	
			If Elem.ComparisonType = StructureForRef.NotEqual Then
				FilterElement.ComparisonType	= DataCompositionComparisonType.NotEqual;
			EndIf;	
				
			FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
			FilterElement.RightValue		= Elem.Value;
			
			
			FilterElement					= SkusSelect.Filter.Items.Add(Type("DataCompositionFilterItem"));
			If Elem.Selector = "Catalog_Territory" Then
				FilterElement.LeftValue			= New DataCompositionField("SKU.Owner.Territories.Territory");
			Else 
				FilterElement.LeftValue			= New DataCompositionField("SKU.Owner.Territories.Territory.Owner");
			EndIf;
			FilterElement.Use				= True;
			If Elem.ComparisonType = StructureForRef.Equal Then
				FilterElement.ComparisonType	= DataCompositionComparisonType.Equal;
			EndIf;	
			If Elem.ComparisonType = StructureForRef.InList Then
				FilterElement.ComparisonType	= DataCompositionComparisonType.InList;
			EndIf;	
			If Elem.ComparisonType = StructureForRef.NotEqual Then
				FilterElement.ComparisonType	= DataCompositionComparisonType.NotEqual;
			EndIf;	
				
			FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
			FilterElement.RightValue		= Elem.Value;
			
	   EndIf;
	EndDo;		
	
EndProcedure

&AtClient
Procedure SelectorsTableBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	FillComprasionInSelect();
	Items.SkusSelect.Refresh();
	Items.SkusSelect1.Refresh();

EndProcedure

&AtClient
Procedure SelectorsTableAfterDeleteRow(Item)
	
	FillComprasionInSelect();
	Items.SkusSelect.Refresh();
	Items.SkusSelect1.Refresh();
	
EndProcedure

&AtClient
Procedure EndDateTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	//StandardProcessing = False;
	try
		DateEnd = Date(Text);
	Except
		Text1=StrReplace(Text," ","0");
		MonthInText = Left(Right(Text1,7),2);
		NumberMonth = Number(MonthInText);
		If (NumberMonth = 0) or (NumberMonth>12) Then 
			MonthInText = "01";	
		EndIf;
		YearInText = Right(Text1,4);
		NumberYear = Number(YearInText);
		If NumberYear < 2000 Then
			YearInText = "2000";
		EndIf;
		
		DayInText = Left(Text1,2);
		NumberDay=Number(DayInText);
		If NumberDay = 0 Then
			EndMonth = Date(YearInText+MonthInText+"01");
			DayInText="01";
		EndIf;
		If (NumberDay > Day(EndOfMonth(Date(YearInText+MonthInText+"01")))) Then 
			EndMonth = EndOfMonth(Date(YearInText+MonthInText+"01"));
		Else
			EndMonth = Date(YearInText + MonthInText + DayInText);
		EndIf;
		
		Text1 = EndMonth;
		If Item = Items.EndDate Then 
			Object.EndDate = Text1;
		Else 
			Object.BeginDate = Text1;
		EndIf;
	EndTry;
	//Text.Month()
EndProcedure

&AtClient
Procedure DateTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	Try
		DateCreate = Date(Left(Text,10));
	Except
		Text0=Left(Text,10);
		Text1=StrReplace(Text0," ","0");
		Text2=Right(Text,8);
		Text3=StrReplace(Text2," ","0");
		
		MonthInText = Right(Left(Text1,5),2);  
		NumberMonth = Number(MonthInText);
		If (NumberMonth = 0) or (NumberMonth>12) Then 
			MonthInText = "01";	
		EndIf;
		YearInText = Right(Left(Text1,10),4);
		NumberYear = Number(YearInText);
		If NumberYear < 2000 Then
			YearInText = "2000";
		EndIf;
		
		DayInText = Left(Text1,2);
		NumberDay=Number(DayInText);
		If NumberDay = 0 Then
			EndMonth = Date(YearInText+MonthInText+"01");
			DayInText="01";
		EndIf;
		If (NumberDay > Day(EndOfMonth(Date(YearInText+MonthInText+"01")))) Then 
			EndMonth = EndOfMonth(Date(YearInText+MonthInText+"01"));
		Else
			EndMonth = Date(YearInText + MonthInText + DayInText);
		EndIf;
		
		Text1 = EndMonth;
		Object.Date = Left(Text1,10)+" "+Text3;
	EndTry;
EndProcedure

&AtClient
Procedure BeginDateOnChange(Item)
	
	If ValueIsFilled(Object.BeginDate) And ValueIsFilled(Object.EndDate) Then
	
		//  Если новая дата начала действия анкеты больше даты конца действия анкеты
		// Ставим новую дату начала действия анкеты равной дате конца действия анкеты
		Object.BeginDate = ?(EndOfDay(Object.BeginDate) >= EndOfDay(Object.EndDate),
							Object.EndDate, 
							Object.BeginDate);
	EndIf;
						
EndProcedure


#EndRegion

#EndRegion

TypesMap = new Map();
TypesMap.Insert("String", "String");
TypesMap.Insert("Строка", "String");
TypesMap.Insert("Integer", "Integer");
TypesMap.Insert("Целое число", "Integer");
TypesMap.Insert("Decimal", "Decimal");
TypesMap.Insert("Десятичная дробь", "Decimal");
TypesMap.Insert("Boolean", "Boolean");
TypesMap.Insert("Логический тип", "Boolean");
TypesMap.Insert("Date time", "Date time");
TypesMap.Insert("Дата и время", "Date time");
TypesMap.Insert("Value list", "Value list");
TypesMap.Insert("Список значений", "Value list");
