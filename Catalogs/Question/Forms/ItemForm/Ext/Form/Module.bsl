
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Object.Assignment) Then 
		
		ThisForm.ReadOnly = True;
		
		Items.Owner.Enabled = False;
		
	Else 
		
		Items.Owner.Enabled = Not ValueIsFilled(Object.Ref);
		
		OwnerOnChangeAtServer();
		
	EndIf;
	
	Query = New Query(
	"SELECT
	|	QuestionsInQuestionnaires.Questionnaire
	|FROM
	|	InformationRegister.QuestionsInQuestionnaires AS QuestionsInQuestionnaires
	|WHERE
	|	QuestionsInQuestionnaires.ChildQuestion = &ChildQuestion");
	Query.SetParameter("ChildQuestion", ThisForm.Object.Ref);
	Result = Query.Execute().Unload();
	InQuestionnaires = Result.Count() > 0;
	
	ThisForm.Items.AnswerType.ReadOnly = InQuestionnaires;
	ThisForm.Items.ValueList.ReadOnly = InQuestionnaires;
	ThisForm.Items.Decoration1.Visible = InQuestionnaires;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Items.Owner.Enabled = Not ValueIsFilled(Object.Ref);
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT DISTINCT
	|	QuestionsInQuestionnairesSliceLast.Questionnaire
	|FROM
	|	InformationRegister.QuestionsInQuestionnaires.SliceLast AS QuestionsInQuestionnairesSliceLast
	|WHERE
	|	QuestionsInQuestionnairesSliceLast.Status <> VALUE(Enum.ValueTableRowStatuses.Deleted)
	|	AND QuestionsInQuestionnairesSliceLast.ChildQuestion = &Question");
	Query.SetParameter("Question", ThisForm.Object.Ref);
	Result = Query.Execute().Unload();
	
	For Each Row In Result Do
		
		RecordManager = InformationRegisters.bitmobile_ИзмененныеДанные.CreateRecordManager();
		RecordManager.Ссылка = Row.Questionnaire;
		RecordManager.Порядок = FindSetting();
		RecordManager.Write();
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Function FindSetting()
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	bitmobile_НастройкиСинхронизации.Ссылка КАК Ссылка
		|ИЗ
		|	Справочник.bitmobile_НастройкиСинхронизации КАК bitmobile_НастройкиСинхронизации
		|ГДЕ
		|	bitmobile_НастройкиСинхронизации.ПометкаУдаления = ЛОЖЬ
		|	И bitmobile_НастройкиСинхронизации.ВыгрузкаДанных = ИСТИНА
		|	И bitmobile_НастройкиСинхронизации.ОбъектКонфигурации = &ИмяМетаданного";
	
	Запрос.УстановитьПараметр("ИмяМетаданного", Metadata.Documents.Questionnaire.FullName());
	
	Результат = Запрос.Выполнить();
	
	Выборка = Результат.Выбрать();
	
	Если Выборка.Следующий() Тогда
		
		Возврат Выборка.Ссылка;
		
	Иначе 
		
		Возврат Неопределено;
		
	КонецЕсли;
	
EndFunction

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotAllowed() Then
		
		Cancel = True;
		
	EndIf; 
	
EndProcedure

&AtServer
Function IsValueList()
	
	If Object.AnswerType = Enums.DataType.ValueList Then
		
		Return True;
		
	Else 
		
		Return False;
		
	EndIf;
	
EndFunction

&AtServer
Function GetQuestionGroupType(TypeString = "SKUQuestions")
	
	If TypeString = "SKUQuestions" Then 
		
		Return Enums.QuestionGroupTypes.SKUQuestions;
		
	Else 
		
		Return Enums.QuestionGroupTypes.RegularQuestions;
		
	EndIf;
	
EndFunction

&AtServer
Function NotAllowed()
	
	If Object.AnswerType = Enums.DataType.ValueList And Object.ValueList.Count() = 0 Then
		
		Message(NStr("en=""Tabular section couldn't be empty!"";ru='Табличная часть не может быть пустой!';cz='Tabulkovб sekce nesmн bэt prбzdnб!'"));
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function GetValueList()
	
	Return Enums.DataType.ValueList;
	
EndFunction

&AtServer
Procedure OwnerOnChangeAtServer()
	
	//If Object.Owner = Catalogs.QuestionGroup.EmptyRef() Or Object.Owner.Type = Enums.QuestionGroupTypes.RegularQuestions Then 
	//	
	//	Items.Assignment.Enabled = False;
	//	
	//	Object.Assignment = Undefined;
	//	
	//Else 
	//	
	//	Items.Assignment.Enabled = True;
	//	
	//EndIf;	
	
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
	If Not IsValueList() Then
		
		Items.ValueList.Visible = False;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then 
		
		Try
		
			If FormOwner.Parent.Parent.FormName = "Catalog.Question.Form.ListFormSKUQuestionsWithGroups"
				Or FormOwner.Parent.Parent.FormName = "Catalog.Question.Form.ListFormRegularQuestionsWithGroups" Then 
				
				If Not FormOwner.Parent.Parent.ChildItems.GroupsList.CurrentData = Undefined Then 
					
					Object.Owner = FormOwner.Parent.Parent.ChildItems.GroupsList.CurrentData.Ref;
					
					ParamArray = New Array;
					
					If FormOwner.Parent.Parent.FormName = "Catalog.Question.Form.ListFormSKUQuestionsWithGroups" Then 
						
						ParamArray.Add(New ChoiceParameter("Filter.Type", GetQuestionGroupType("SKUQuestions")));
						
					Else 
						
						ParamArray.Add(New ChoiceParameter("Filter.Type", GetQuestionGroupType("RegularQuestions")));
						
					EndIf;
					
					Items.Owner.ChoiceParameters = New FixedArray(ParamArray);
					
					If FormOwner.Parent.Parent.UseGroupFilter Then 
						
						Items.Owner.Enabled = False;
						
					Else 
						
						Items.Owner.Enabled = True;
						
					EndIf;
					
				Else 
					
					Cancel = True;
					
				EndIf;
				
			EndIf;
			
		Except
			
			Try
				
				ParamArray = New Array;
				
				ParamArray.Add(New ChoiceParameter("Filter.Type", FormOwner.AdditionalCreateParameters.GroupType));
				
				Items.Owner.ChoiceParameters = New FixedArray(ParamArray);
				
				If ValueIsFilled(FormOwner.CurrentData.ParentRowGrouping) Then 
					
					Object.Owner = FormOwner.CurrentData.ParentRowGrouping.Key;
					
				ElsIf ValueIsFilled(FormOwner.CurrentData.RowGroup) Then 
					
					Object.Owner = FormOwner.CurrentData.RowGroup.Key;
					
				EndIf;
				
			Except
				
			EndTry;
			
		EndTry;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ClearQuestions" And Parameter = "Ok" Then
		
		Object.ValueList.Clear();
		
		Items.ValueList.Visible = False;
		
	EndIf;
	
	If EventName = "ClearQuestions" And Parameter = "Cancel" Then
		
		Object.AnswerType = GetValueList();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AnswerTypeOnChange(Item)
	
	If IsValueList() Then
		
		Items.ValueList.Visible = True;
		
	Else
		
		If Not Object.ValueList.Count() = 0 Then
			
			Text = "en = ""The tabular section will be cleaned. 
					|Are you sure you want to continue?"";
					|ru = ""Табличная часть будет очищена.
					|Продолжить?""";
			
			OpenForm("CommonForm.DoQueryBox", New Structure("Text, Source", NStr(Text), "ClearQuestions"));
			
		Else
			
			Items.ValueList.Enabled = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OwnerOnChange(Item)
	
	OwnerOnChangeAtServer();
	
EndProcedure

#EndRegion
