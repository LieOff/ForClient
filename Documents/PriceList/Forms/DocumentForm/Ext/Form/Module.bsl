
#Region CommonProcedureAndFunctions

&AtServer
 Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPrices();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillPrices();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.AdditionalProperties.Insert("Prices", ThisForm.Prices.Unload());
	
EndProcedure

&AtServer
Procedure FillPrices()
	
	Query = New Query(
	"SELECT ALLOWED
	|	Prices.SKU,
	|	Prices.Price
	|FROM
	|	InformationRegister.Prices AS Prices
	|WHERE
	|	Prices.PriceList = &PriceList");
	Query.SetParameter("PriceList", ThisForm.Object.Ref);
	Result = Query.Execute().Unload();
	
	ThisForm.Prices.Load(Result);
	
EndProcedure

&AtServer
Procedure FillSKUServer()
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	SKU.Ref
		|FROM
		|	Catalog.SKU AS SKU
		|WHERE
		|	NOT SKU.Ref IN (&SKUArray)";
		
	Query.SetParameter("SKUArray", ThisForm.Prices.Unload(, "SKU"));
	
	Result = Query.Execute().Unload();
	
	For Each Value In Result Do
		
		NewRow = ThisForm.Prices.Add();
		NewRow.SKU = Value.Ref;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	
	Items.Number.ReadOnly = Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditDocumentNumbers);

EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure FillSKU(Command)
    
    FillSKUServer();

EndProcedure

&AtClient
Procedure SKUSKUOnChange(Item)
   
    requestMap = New Map;
    requestMap.Insert("pName", "SKU");
    requestMap.Insert("checkingItem", Items.SKU.CurrentData);
    requestMap.Insert("tabularSection", Object.Prices);
    
    ClientProcessors.UniqueRows(requestMap); 
    
EndProcedure

&AtClient
Procedure DeleteSKU(Command)
	
	CurrentData = ThisForm.Items.Prices.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		ThisForm.Prices.Delete(ThisForm.Prices.IndexOf(CurrentData));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

#EndRegion








