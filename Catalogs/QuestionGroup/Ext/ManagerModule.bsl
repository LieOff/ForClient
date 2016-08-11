Function HasQuestions(QuestionGroupRef) Export
	
	Query = New Query(
	"SELECT ALLOWED
	|	Question.Ref
	|FROM
	|	Catalog.Question AS Question
	|WHERE
	|	Question.Owner = &Owner");
	
	Query.SetParameter("Owner", QuestionGroupRef);
	QuestionsInGroupQty = Query.Execute().Select().Count();	
	
	Return QuestionsInGroupQty > 0;
	
EndFunction