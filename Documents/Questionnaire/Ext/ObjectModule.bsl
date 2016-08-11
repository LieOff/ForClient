
Procedure OnWrite(Cancel)
	
	If Status = Enums.QuestionnareStatus.Inactive Then 
		
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	QuestionnairesSchedule.Date,
			|	QuestionnairesSchedule.Questionnaire,
			|	QuestionnairesSchedule.BeginAnswerPeriod,
			|	QuestionnairesSchedule.EndAnswerPeriod
			|FROM
			|	InformationRegister.QuestionnairesSchedule AS QuestionnairesSchedule
			|WHERE
			|	QuestionnairesSchedule.Questionnaire = &Questionnaire
			|	AND QuestionnairesSchedule.Date >= &CurrentDate";
		
		Query.SetParameter("CurrentDate", BegOfDay(CurrentDate()));
		Query.SetParameter("Questionnaire", Ref);
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		RecordManager = InformationRegisters.QuestionnairesSchedule.CreateRecordManager();
		
		While Selection.Next() Do
			
			FillPropertyValues(RecordManager, Selection);
			
			RecordManager.Read();
			
			If RecordManager.Selected() Then 
				
				RecordManager.Delete();
				
			EndIf;
			
		EndDo;
		
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	AnsweredQuestions.Questionaire,
			|	AnsweredQuestions.Outlet,
			|	AnsweredQuestions.Question,
			|	AnsweredQuestions.SKU,
			|	AnsweredQuestions.Answer,
			|	AnsweredQuestions.AnswerDate,
			|	AnsweredQuestions.Visit,
			|	AnsweredQuestions.UploadSnapshot,
			|	AnsweredQuestions.Snapshot
			|FROM
			|	InformationRegister.AnsweredQuestions AS AnsweredQuestions
			|WHERE
			|	AnsweredQuestions.Questionaire = &Questionaire";
		
		Query.SetParameter("Questionaire", Ref);
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		RecordManager = InformationRegisters.AnsweredQuestions.CreateRecordManager();
		
		While Selection.Next() Do
			
			FillPropertyValues(RecordManager, Selection);
			
			RecordManager.Read();
			
			If RecordManager.Selected() Then 
				
				RecordManager.Delete();
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure






