
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If IsNew() Then 
		
		AdditionalProperties.Delete("ЗагрузкаBitmobile");
		
	EndIf;
	
	//Earth radius
	R = 6372795;
	Pi = 3.14159265359;
	
	//convert coordinates into radians
	lat1 = ThisObject.Lattitude * Pi / 180;
	lat2 = Outlet.Lattitude * Pi / 180;
	long1 = ThisObject.Longitude * Pi / 180;
	long2 = Outlet.Longitude * Pi / 180;
	
	//calculate sin, cos and coordinates differences
	cl1 = Cos(lat1);
	cl2 = Cos(lat2);
	sl1 = Sin(lat1);
	sl2 = Sin(lat2);
	delta = long2 - long1;
	cdelta = Cos(delta);
	sdelta = Sin(delta);
	
	//calculate great circle distance
	y = Sqrt(Pow((cl2*sdelta),2) + Pow((cl1*sl2 - sl1*cl2*cdelta),2));
	x = sl1 * sl2 + cl1 * cl2 * cdelta;
	ad = 2 * ATan(y / (Sqrt(Pow(x,2) + Pow(y,2)) + x));
	dist = ad * R;
	
	ThisObject.GPSDifference = dist;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	Query = New Query(
	"SELECT
	|	Visit.Date AS Period,
	|	VisitSKUs.Ref AS Visit,
	|	VisitSKUs.SKU AS SKU,
	|	Visit.Outlet AS Outlet,
	|	VisitSKUs.Question AS Question,
	|	AllQuestions.AnswerType AS DataType,
	|	AllQuestions.Assignment AS QuestionAssignment,
	|	VisitSKUs.Answer AS Answer
	|FROM
	|	Document.Visit.SKUs AS VisitSKUs
	|		LEFT JOIN Document.Visit AS Visit
	|		ON VisitSKUs.Ref = Visit.Ref
	|		LEFT JOIN Catalog.Question AS AllQuestions
	|		ON VisitSKUs.Question = AllQuestions.Ref
	|WHERE
	|	VisitSKUs.Ref = &Ref");
	
	Query.SetParameter("Ref", ThisObject.Ref);
	QueryResult = Query.Execute().Unload();
	
	For Each Row In QueryResult Do
		
		DataType = Row.DataType;
		TypedAnswer = Row.Answer;
		
		If DataType = Enums.DataType.Boolean Then
			
			TypedAnswer = ?(TypedAnswer = "Да" OR TypedAnswer = "Yes", True, False);
			
		ElsIf DataType = Enums.DataType.Decimal 
			OR DataType = Enums.DataType.Integer Then
			
			TypedAnswer = StrReplace(TypedAnswer, " ", "");
			TypedAnswer = StrReplace(TypedAnswer, Chars.NBSp, "");
			
			TypedAnswer = ?(TypedAnswer = "", 0, Number(TypedAnswer));
			
		EndIf;
		
		RecordManager = InformationRegisters.Answers.CreateRecordManager();
		RecordManager.Answer = TypedAnswer;
		FillPropertyValues(RecordManager, Row, , "Answer");
		RecordManager.Write();
		
	EndDo;
	
EndProcedure
