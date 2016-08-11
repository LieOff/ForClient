
Procedure BeforeWrite(Cancel)
	
	If DeletionMark And ValueIsFilled(Assignment) Then 
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='Question is pre-installed. Mark for deletion is prohibited.';ru='Это предустановленный вопрос. Пометка на удаление запрещена.';cz='Question is pre-installed. Mark for deletion is prohibited.'");
		
		UserMessage.Message();
		
		Cancel = True;
		
	EndIf;
	
EndProcedure


