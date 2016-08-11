
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Catalogs.QuestionGroup.HasQuestions(Object.Ref) Then 
		
		ThisForm.Items.Type.Enabled = False;
		
	Else 
		
		ThisForm.Items.Type.Enabled = True;
		
	EndIf;	
		
EndProcedure

&AtServerNoContext
Function GetQuestionGroupType(TypeString = "SKUQuestions")
	
	Return CommonProcessors.GetQuestionGroupType(TypeString);
			
EndFunction

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
	Try
		
		If FormOwner.Parent.FormName = "Catalog.Question.Form.ListFormRegularQuestionsWithGroups" Then 
			
			Object.Type = GetQuestionGroupType("RegularQuestions");
				
			Items.Type.Enabled = False;
								
		EndIf;
		
		If FormOwner.Parent.FormName = "Catalog.Question.Form.ListFormSKUQuestionsWithGroups" Then 
			
			Object.Type = GetQuestionGroupType("SKUQuestions");
				
			Items.Type.Enabled = False;
								
		EndIf;
		
	Except
		
	EndTry;	
		
EndProcedure
