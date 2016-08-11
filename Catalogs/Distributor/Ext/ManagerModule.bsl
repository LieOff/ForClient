
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("Territories") Then
		
		StandardProcessing = False;
		Territories = Parameters.Territories;
		ChoiceData = New ValueList;
			
		Query = New Query(
		"SELECT ALLOWED DISTINCT
		|	DistributorTerritories.Ref AS Partner
		|FROM
		|	Catalog.Distributor.Territories AS DistributorTerritories
		|WHERE
		|	DistributorTerritories.Territory IN(&Territories)
		|
		|ORDER BY
		|	Partner
		|AUTOORDER");
		Query.SetParameter("Territories", Territories);
		Result = Query.Execute().Unload();
		
		For Each Row In Result Do
			
			ChoiceData.Add(Row.Partner);
			
		EndDo;
		
	EndIf;
	
EndProcedure
