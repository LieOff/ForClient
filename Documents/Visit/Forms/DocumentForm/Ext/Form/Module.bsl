
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Object.Ref) Then 
		
		RecordSet								= InformationRegisters.QuestioningResults.CreateRecordSet();
		RecordSet.Filter.Visit.Use				= True;
		RecordSet.Filter.Visit.ComparisonType	= ComparisonType.Equal;
		RecordSet.Filter.Visit.Value			= Object.Ref;
		
		RecordSet.Read();
		
		ValueToFormData(RecordSet, TempQuestionaires);
		
		For Each StrResult In TempQuestionaires Do 
			
			StrResult.QuestionnaireResult = NStr("en='Result for ""';ru='Результат для ""';cz='Vэsledek pro ""'") + String(StrResult.Questionnaire) + """";
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetRecordKey(KeyData)
	
	Return InformationRegisters.QuestioningResults.CreateRecordKey(KeyData);
	
EndFunction

&AtServer
Procedure OnOpenAtServer()
	
	Items.Number.ReadOnly = Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditDocumentNumbers);
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure TempQuestionairesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Not Items.TempQuestionaires.CurrentData = Undefined Then 
		
		CurrenRowData = TempQuestionaires.FindByID(Items.TempQuestionaires.CurrentRow);
		
		KeyData = New Structure;
		KeyData.Insert("Questionnaire",CurrenRowData.Questionnaire);
		KeyData.Insert("Visit",CurrenRowData.Visit);
		KeyData.Insert("Outlet",CurrenRowData.Outlet);
		KeyData.Insert("SR",CurrenRowData.SR);
		KeyData.Insert("Date",CurrenRowData.Date);
		
		RecordKey = GetRecordKey(KeyData);
		
		OpenForm("InformationRegister.QuestioningResults.RecordForm", New Structure("Key", RecordKey));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

#EndRegion
