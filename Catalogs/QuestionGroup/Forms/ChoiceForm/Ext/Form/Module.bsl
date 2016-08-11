
&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)
	//StandardProcessing = False;
	QuestionsInGroup = GetQuestionsInGroup(SelectedRow);
	If TypeOf(ThisForm.FormOwner) = Type("FormTable") Then
		NotifyChoice(QuestionsInGroup);
	ElsIf TypeOf(ThisForm.FormOwner) = Type("FormField") Then
		NotifyChoice(Item.CurrentRow);
	EndIf;

EndProcedure

&AtServer
Function GetQuestionsInGroup(Group)
	Selection = Catalogs.Question.Select(, Group);
	Array = New Array;
	While Selection.Next() Do
		Array.Add(Selection.Ref);
	EndDo;
	Return Array;
EndFunction
