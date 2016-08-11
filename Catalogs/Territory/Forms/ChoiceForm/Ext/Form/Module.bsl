&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SR") Then
	
		List.CustomQuery = True;
		List.QueryText = "SELECT
		                 |	CatalogTerritory.Ref,
		                 |	CatalogTerritory.Code,
		                 |	CatalogTerritory.Description
		                 |FROM
		                 |	Catalog.Territory AS CatalogTerritory
		                 |WHERE
		                 |	&SR IN (CatalogTerritory.SRs.SR)";
		List.MainTable = "Catalog.Territory";
		List.Parameters.SetParameterValue("SR", Parameters.SR);
	EndIf;
	
EndProcedure
