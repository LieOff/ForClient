
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
If Parameters.Property("PlanExecutor") Then	
		
	If ValueIsFilled(Parameters.PlanExecutor) Then	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TerritoryOutlets.Outlet AS Outlet
		|FROM
		|	Catalog.Territory.Outlets AS TerritoryOutlets
		|		LEFT JOIN Catalog.Territory AS Territory
		|		ON TerritoryOutlets.Ref = Territory.Ref
		|WHERE
		|	Territory.SRs.SR IN(&Ref)";
	
	Query.SetParameter("Ref", Parameters.PlanExecutor);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	EnabelOutlet=QueryResult.Unload().UnloadColumn("Outlet");

		
		FilterElement					= List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue			= New DataCompositionField("Ref");
		FilterElement.Use				= True;
		FilterElement.ComparisonType	= DataCompositionComparisonType.InList;
		FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
		FilterElement.RightValue		= EnabelOutlet;	
	EndIf;
	
EndIf

	
EndProcedure
