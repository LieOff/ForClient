
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.Role) Then
		
		EnabledRoles = New ValueList;
		
		If Parameters.Role = "SRM" Then 
			
			EnabledRoles.Add("SRM");
			EnabledRoles.Add("SRM_SR");
			
		Else 
			
			EnabledRoles.Add("SR");
			EnabledRoles.Add("SRM_SR");
			
		EndIf;
		
		FilterElement					= List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue			= New DataCompositionField("RoleOfUser.Role");
		FilterElement.Use				= True;
		FilterElement.ComparisonType	= DataCompositionComparisonType.InList;
		FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
		FilterElement.RightValue		= EnabledRoles;
		
	EndIf; 
	
If Parameters.Property("Outlet") Then	
		
	If ValueIsFilled(Parameters.Outlet) Then	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TerritorySRs.SR As Sr
		|FROM
		|	Catalog.Territory.SRs AS TerritorySRs
		|		LEFT JOIN Catalog.Territory AS Territory
		|		ON TerritorySRs.Ref = Territory.Ref
		|WHERE
		|	Territory.Outlets.Outlet IN(&Ref)";
	
	Query.SetParameter("Ref", Parameters.Outlet);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	EnabelSrs=QueryResult.Unload().UnloadColumn("Sr");

		
		FilterElement					= List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue			= New DataCompositionField("Ref");
		FilterElement.Use				= True;
		FilterElement.ComparisonType	= DataCompositionComparisonType.InList;
		FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
		FilterElement.RightValue		= EnabelSrs;	
	EndIf;
	
EndIf
EndProcedure
