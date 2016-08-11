
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Если Object.Ref.IsEmpty() Тогда 
		Object.Responsible = SessionParameters.CurrentUser;	
	КонецЕсли; 	

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
    
    OnOpenServer();    

EndProcedure

Procedure OnOpenServer()
	
	Items.Number.ReadOnly = Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditDocumentNumbers);
	
EndProcedure


&AtClient
Procedure PlanExecutorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing=False;
	OpenForm("Catalog.User.ChoiceForm",New Structure("Outlet",Object.Outlet),Item);
	
EndProcedure


&AtClient
Procedure PlanExecutorChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	Object.PlanExecutor=SelectedValue;
	
EndProcedure


&AtClient
Procedure OutletStartChoice(Item, ChoiceData, StandardProcessing)

//	StandardProcessing=False;
//	OpenForm("Catalog.Outlet.ChoiceForm",New Structure("PlanExecutor",Object.PlanExecutor),Item);		
	
EndProcedure


&AtClient
Procedure OutletChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	OutletChoiceProcessingServer(SelectedValue);
	
EndProcedure


Function OutletChoiceProcessingServer(SelectedValue)
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	TerritoryOutlets.Outlet AS Outlet
		|FROM
		|	Catalog.Territory.Outlets AS TerritoryOutlets
		|		LEFT JOIN Catalog.Territory AS Territory
		|		ON TerritoryOutlets.Ref = Territory.Ref
		|WHERE
		|	Territory.SRs.SR IN(&Ref)";
	
	Query.SetParameter("Ref", Object.PlanExecutor);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	PlanExecutorClear=False;
	
	While SelectionDetailRecords.Next() Do
		
		If SelectionDetailRecords.Outlet=SelectedValue Then 			
			PlanExecutorClear=True;
		EndIf;
		
	EndDo;
	
	If Not(PlanExecutorClear) Then
		Object.PlanExecutor= Catalogs.User.EmptyRef();
	EndIf;
EndFunction
