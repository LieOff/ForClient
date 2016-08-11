
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnOpenServer()
	
	Items.Number.ReadOnly = Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditDocumentNumbers);

	If Not IsInRole("Admin") Then
		
		Items.Number.ReadOnly		= True;
		Items.Date.ReadOnly			= True;
		Items.Outlet.ReadOnly		= True;
		Items.SR.ReadOnly			= True;
		Items.Visit.ReadOnly		= True;
		Items.PriceList.ReadOnly	= True;
		Items.Stock.ReadOnly		= True;
		Items.Lattitude.ReadOnly	= True;
		Items.Longitude.ReadOnly	= True;
		Items.Commentary.ReadOnly	= True;
		Items.SKUs.ReadOnly			= True;
		Items.Contractor.ReadOnly	= True;
		
	EndIf;

EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenServer();
	
EndProcedure

&AtClient
Procedure GetAmount()
	
	Str			= Items.SKUs.CurrentData;
	Str.Total	= Str.Price * (Str.Discount/100+1);
	Str.Amount	= Str.Total * Str.Qty;
	
EndProcedure

&AtClient
Procedure SKUsSKUOnChange(Item)
	
	GetAmount();
	
EndProcedure

&AtClient
Procedure SKUsQtyOnChange(Item)
	
	GetAmount();
	
EndProcedure

&AtClient
Procedure SKUsPriceOnChange(Item)
	
	GetAmount();
	
EndProcedure

&AtClient
Procedure SKUsDiscountOnChange(Item)
	
	GetAmount();
	
EndProcedure

&AtClient
Procedure SKUsTotalOnChange(Item)

	GetAmount();
	
EndProcedure

#EndRegion
