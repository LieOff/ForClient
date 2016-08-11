
Procedure BeforeWrite(Cancel)
	
	If Not ThisObject.DataExchange.Load Then 
	
		If ValueIsFilled(ThisObject.Ref) Then
			
			If Not ThisObject.Type = ThisObject.Ref.Type Then			
				
				If Catalogs.QuestionGroup.HasQuestions(ThisObject.Ref) Then
					
					Cancel = True;
					Message(NStr("en=""You can't change question type if you have questions in group."";ru='Изменять тип группы вопросов при наличии вопросов в группе вопросов запрещено.';cz=""You can't change question type if you have questions in group."""));
					
				EndIf;            
				
			EndIf;
			
		EndIf;
		
	EndIf;	
	
EndProcedure

