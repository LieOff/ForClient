
Procedure BeforeWrite(Cancel)

	If IsNew() Then 
		
		If AdditionalProperties.Property("ЗагрузкаBitmobile") Then 
			
			AdditionalProperties.Delete("ЗагрузкаBitmobile");
			
		EndIf;
		
	EndIf;
	
	TransformIntoVisitPlans();
	
EndProcedure

Procedure TransformIntoVisitPlans()
    planDoc = GetPlanDoc();
    CreatePlan(planDoc);
    ThisObject.Transformed = True;
EndProcedure

Function GetPlanDoc()
	
	Query = new Query;
	Query.Text = "SELECT ALLOWED
				|	VisitPlan.Ref
				|FROM
				|	Document.VisitPlan AS VisitPlan
				|WHERE
				|	&Date BETWEEN VisitPlan.DateFrom AND ENDOFPERIOD(VisitPlan.DateTo, DAY)
				|	AND VisitPlan.SR = &SR";
	
	Query.SetParameter("Date", ThisObject.planDate);
	Query.SetParameter("SR", ThisObject.SR);
	
	Recordset = Query.Execute();
	
	If Recordset.IsEmpty() Then
		
		Return CreatePlanDoc();
		
	Else
		
		SelectedRecord = Recordset.Select();
		
		SelectedRecord.Next();
		
		Return SelectedRecord.Ref;
		
	EndIf;
	
EndFunction // GetPlanDoc()

Function CreatePlanDoc()
    
    newDoc = Documents.VisitPlan.CreateDocument();
    newDoc.Date = CurrentDate();
    newDoc.DateFrom = BegOfWeek(ThisObject.PlanDate);
    newDoc.DateTo = EndOfWeek(ThisObject.PlanDate);
    newDoc.Owner = ThisObject.SR;
    newDoc.SR = ThisObject.SR;
    newDoc.WeekNumber = newDoc.GetWeekOfYear(ThisObject.PlanDate);
    newDoc.Year = BegOfYear(ThisObject.PlanDate);
    newDoc.Write();
    
    Return newDoc.Ref;
    
EndFunction // CreatePlanDoc()

Procedure CreatePlan(planDoc)
    
    tabularSection = planDoc.Outlets.Unload();
    query = New Query();
    query.Text = "SELECT ALLOWED
                 |  VisitPlanOutlets.Outlet,
                 |  VisitPlanOutlets.Date,
                 |  VisitPlanOutlets.LineNumber
                 |FROM
                 |  Document.VisitPlan.Outlets AS VisitPlanOutlets
                 |WHERE
                 |  VisitPlanOutlets.Ref = &Ref
                 |  AND VisitPlanOutlets.Outlet = &Outlet
                 |  AND BEGINOFPERIOD(VisitPlanOutlets.Date, DAY) = BEGINOFPERIOD(&Date, DAY)";
                 query.SetParameter("Outlet", Outlet);
                 query.SetParameter("Ref", planDoc);
                 query.SetParameter("Date", PlanDate);
    res = query.Execute();    
    If res.IsEmpty() Then
        newRow = tabularSection.Add();
        newRow.Outlet = ThisObject.Outlet;
        newRow.Date = ThisObject.PlanDate;
    Else        
        row = res.Unload();
        rowByOutlet = tabularSection.Get(row[0].LineNumber-1);
        rowByOutlet.Date = ThisObject.PlanDate;    	    
    EndIf;
    planDoc = planDoc.GetObject();
    planDoc.Outlets.Load(tabularSection);
    planDoc.Write();    
    
EndProcedure







