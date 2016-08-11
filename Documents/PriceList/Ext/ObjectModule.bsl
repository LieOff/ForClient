
Procedure OnWrite(Cancel)
	
	If Not Cancel Then
		
		If AdditionalProperties.Property("Prices") Then
		
			RecordSet = InformationRegisters.Prices.CreateRecordSet();
			RecordSet.Filter.PriceList.Set(ThisObject.Ref);
			
			PricesVT = AdditionalProperties.Prices;
			Query = New Query(
			"SELECT
			|	&PriceList,
			|	Prices.SKU,
			|	Prices.Price
			|INTO PricesVT
			|FROM
			|	&Prices AS Prices
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	PricesVT.PriceList,
			|	PricesVT.SKU,
			|	PricesVT.Price
			|FROM
			|	PricesVT AS PricesVT
			|WHERE
			|	NOT PricesVT.SKU = VALUE(Catalog.SKU.EmptyRef)");
			Query.SetParameter("PriceList", ThisObject.Ref);
			Query.SetParameter("Prices", PricesVT);
			Result = Query.Execute().Unload();
			
			RecordSet.Load(Result);
			
			RecordSet.Write();
			
		EndIf;
		
	EndIf;
	
EndProcedure





