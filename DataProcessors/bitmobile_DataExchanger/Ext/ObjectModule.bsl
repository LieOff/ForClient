
#Region Vars

Var Catalog;
Var AccumulationRegister;
Var InformationRegister;
Var Agreement;
Var Brands;
Var PriceLists;
Var SKUs;
Var SKUGroups;
Var Packs;
Var Units;
Var Prices;
Var Stocks;
Var Outlets;
Var Partners;
Var Contacts;
Var Agreements;
Var UpdatedSKUStocks;
Var OutletsMutualSettlements103;
Var SKUs103;
Var UsersCat;
Var Units103;
Var Series;
//Var SKUsInStocks;
Var ContactInfo;
Var Contacts103;
Var PriceTypes;

Var AddressKind;
Var PhoneKind;
Var EmailKind;
Var StocksForRemains103;

Var ExchangePlan;

Var EmptyRefString;

Var SOURCE_CONFIG_UT11;
Var SOURCE_CONFIG_UT103;
Var MAX_ENTRY_NUMBER_PER_FILE; 

#EndRegion


Procedure DoLog(LogText)
	If False then
		WriteLogEvent("SA Data exchange loggin",,,,LogText);		
	EndIf;
EndProcedure


Procedure LoadSettings()
	
	FillPropertyValues(ThisObject, DataProcessors.bitmobile_DataExchanger.GetSettings());
	
EndProcedure

Procedure GetChanges() Export
	
	LoadSettings();
	
	
	Connection = DataProcessors.bitmobile_DataExchanger.GetConnection();
		
	If Not Connection = Undefined Then
		
		
		ObjectArrays = GetObjectArrays(Connection);
		
		Try
			
			BeginTransaction();
			
			If SourceConfiguration = SOURCE_CONFIG_UT11 Then
			
				For Each Unit In ObjectArrays.Get(Units) Do
					
					WriteUnit(Unit);
					
				EndDo;
				
				For Each Stock In ObjectArrays.Get(Stocks) Do
					
					WriteStocks(Stock);
					
				EndDo;
				
				For Each Pack In ObjectArrays.Get(Packs) Do
					
					WritePack(Pack);
					
				EndDo;
				
				For Each Brand In ObjectArrays.Get(Brands) Do
					
					WriteBrand(Brand);
					
				EndDo;
				
				TerritoryObject = Catalogs.Territory.FindByDescription("Основная территория").GetObject();
				
				RegionObject = Catalogs.Region.FindByDescription("Основной регион").GetObject();
				
				If RegionObject = Undefined Then
					
					RegionObject = Catalogs.Region.CreateItem();
					RegionObject.Description = "Основной регион";
					RegionObject.Write();
					
					
				EndIf;
				
				RegionRef = RegionObject.Ref;
				
				If TerritoryObject = Undefined Then
					
					TerritoryObject = Catalogs.Territory.CreateItem();
					TerritoryObject.Description = "Основная территория";
					TerritoryObject.Owner = RegionRef;
					TerritoryObject.Write();
					
				EndIf;
				
				WriteUsers(ObjectArrays);
				
				WriteOutlets(ObjectArrays, TerritoryObject);
				
				WriteContacts(ObjectArrays);
				
				SKUGroupsArray = ObjectArrays.Get(SKUGroups);
				SKUGroupsTree = GetSKUGroupsTree(SKUGroupsArray);
				WriteSKUGroups(SKUGroupsTree);
				PacksMap = GetPacks();
				SKUObjectStructures = ObjectArrays.Get(SKUs);
				For Each SKUObjectStructure In SKUObjectStructures Do
					
					WriteSKU(SKUObjectStructure, SKUGroupsTree, PacksMap);
					
				EndDo;
				
				SKUStocksVT = ObjectArrays.Get(UpdatedSKUStocks + "VT");
				SKUStocksArray = ObjectArrays.Get(UpdatedSKUStocks);
				For Each ChangedSKUStock In SKUStocksArray Do
					
					WriteSKUStocks(ChangedSKUStock, SKUStocksVT);
					
				EndDo;
				
				PriceListsArray = ObjectArrays.Get(PriceLists);
				
				For Each PriceListStructure In PriceListsArray Do
					
					WritePriceList(PriceListStructure);
					
				EndDo;
				
				WritePrices(ObjectArrays);
				
				WritePriceListsToOutlets(ObjectArrays);
				
			ElsIf SourceConfiguration = SOURCE_CONFIG_UT103 Then
				
				//todo	
				
				WriteUsers(ObjectArrays);		
				
				WriteSKUGroups103(ObjectArrays);
				
				WriteSKUs103(ObjectArrays);
				
				WriteContacts103(ObjectArrays);
				
				WriteOutlets103(ObjectArrays);
				
				WritePriceLists103(ObjectArrays);
				
				WritePrices103(ObjectArrays);
				
				For Each Stock In ObjectArrays.Get(Stocks) Do
					
					WriteStocks(Stock);
					
				EndDo;				
				gelAllSKUStocks103(Connection, ObjectArrays);
				
				getAllOutletsMutualSettlements103(Connection, ObjectArrays);				
				
				writeMutualSettlements103(ObjectArrays);
				
				writeStocks103(ObjectArrays);
				
				WritePriceListsToOutlets103(ObjectArrays);
							
			EndIf;
			
			CommitTransaction();
			
			//todo
			SendSuccessMessageServer();
			
		Except
			
			Message(ErrorInfo());
			Message(ErrorDescription());
			
			RollbackTransaction();
			
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure WritePriceLists103(ObjectArrays)
	
	PriceListsArray = ObjectArrays.Get(PriceTypes);
	
	For Each PriceListStructure In PriceListsArray Do
		
		PriceListObj = GetDocumentObject("PriceList", New UUID(PriceListStructure.Ref_Key));
		PriceListObj.Description = PriceListStructure.Description;
		
		If Not (PriceListObj.Ref.Description = PriceListStructure.Description) Then
			
			PriceListObj.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WritePrices103(ObjectArrays)
	
	PricesArray = ObjectArrays.Get(Prices);
	SeriesArray = ObjectArrays.Get(Series);
	
	PricesVT = New ValueTable;
	PricesVT.Columns.Add("Period");
	PricesVT.Columns.Add("PriceList");
	PricesVT.Columns.Add("SKU");
	PricesVT.Columns.Add("Price");
	
	For Each PriceStructure In PricesArray Do
		
		SKURef = Catalogs.SKU.GetRef(New UUID(PriceStructure.Номенклатура_Key));
		
		If SKURef.GetObject() = Undefined Then
			
			For Each SerieStructure In SeriesArray Do
				
				If SerieStructure.Owner_Key = PriceStructure.Номенклатура_Key Then
					
					SerieRef = Catalogs.SKU.GetRef(New UUID(SerieStructure.Ref_key));
					
					If Not SerieRef.GetObject() = Undefined Then
						
						NewPriceRow = PricesVT.Add();
						NewPriceRow.Period = Date(СтроковыеФункцииКлиентСервер.ЗаменитьОдниСимволыДругими("-T:", PriceStructure.Period, ""));
						NewPriceRow.PriceList = Documents.PriceList.GetRef(New UUID(PriceStructure.ТипЦен_Key));
						NewPriceRow.SKU = SerieRef;
						NewPriceRow.Price = Number(PriceStructure.Цена);
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		Else
			
			NewPriceRow = PricesVT.Add();
			NewPriceRow.Period = Date(СтроковыеФункцииКлиентСервер.ЗаменитьОдниСимволыДругими("-T:", PriceStructure.Period, ""));
			NewPriceRow.PriceList = Documents.PriceList.GetRef(New UUID(PriceStructure.ТипЦен_Key));
			NewPriceRow.SKU = SKURef;
			NewPriceRow.Price = Number(PriceStructure.Цена);
			
		EndIf;
		
	EndDo;
	
	PricesVT.Sort("PriceList, SKU, Period");
	
	For Each PriceRow In PricesVT Do
		
		RecordManager = InformationRegisters.Prices.CreateRecordManager();
		FillPropertyValues(RecordManager, PriceRow);
		RecordManager.Write();
		
	EndDo;
	
EndProcedure

Procedure WriteContacts103(ObjectArrays)
	
	ContactsArray = ObjectArrays.Get(Contacts103);
	ContactInfosArray = ObjectArrays.Get(ContactInfo);
	
	For Each ContactStructure In ContactsArray Do
		
		ContactObject = GetCommonRefCatalogObject("ContactPersons", ContactStructure.Ref_Key);
		ContactObject.Description = ContactStructure.Description;
		ContactObject.Position = ContactStructure.Должность;
		
		For Each ContactInfoStructure In ContactInfosArray Do
			
			If ContactInfoStructure.Объект_Type = Contacts103 And ContactStructure.Ref_Key = ContactInfoStructure.Объект Then
				
				If ContactInfoStructure.Вид = PhoneKind Then
					
					ContactObject.PhoneNumber = ContactInfoStructure.Представление;
					
				EndIf;
				
				If ContactInfoStructure.Вид = EmailKind Then
					
					ContactObject.Email = ContactInfoStructure.Представление;
					
				EndIf;
				
			EndIf;
			
			If Not (ContactObject.Ref.Description = ContactObject.Description And
				ContactObject.Ref.Position = ContactObject.Position And
				ContactObject.Ref.PhoneNumber = ContactObject.PhoneNumber And
				ContactObject.Ref.Email = ContactObject.Email) Then
				
				ContactObject.Write();
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure WriteOutlets103(ObjectArrays)
	
	OutletsArray = ObjectArrays.Get(Outlets);
	ContactInfosArray = ObjectArrays.Get(ContactInfo);
		
	_RegionObject = Catalogs.Region.FindByDescription("Основной регион");;
	
	If NOT ValueIsFilled(_RegionObject) Then		
		_RegionObject = Catalogs.Region.CreateItem();
		_RegionObject.Description = "Основной регион";
		_RegionObject.Write();	
	else 
		_RegionObject = _RegionObject.getObject();		
	EndIf;
	RegionRef = _RegionObject.Ref;
	
	
	_TerritoryObject = Catalogs.Territory.FindByDescription("Основная территория");

	
	If NOT ValueIsFilled(_TerritoryObject) Then		
		_TerritoryObject = Catalogs.Territory.CreateItem();
		_TerritoryObject.Description = "Основная территория";
		_TerritoryObject.Owner = RegionRef;
	else
		_TerritoryObject = _TerritoryObject.getObject();
	EndIf;
	
	if _TerritoryObject.Stocks.Count() = 0 then
		
		newStokLine =  _TerritoryObject.Stocks.Add();
		newStokLine.Stock = Catalogs.Stock.DefaultStock;
		_TerritoryObject.Write();
	endIf;

	
	
	For Each OutletStructure In OutletsArray Do
		
		Address = "";
		//////
		Phone="";
		Email="";
		//////
		ContractorObject = GetCommonRefCatalogObject("Contractors", OutletStructure.Ref_Key);
		OutletObj = GetCommonRefCatalogObject("Outlet", OutletStructure.Ref_Key);
		
		For Each ContactInfoStructure In ContactInfosArray Do
			
			If ContactInfoStructure.Объект_Type = Outlets And ContactInfoStructure.Объект = OutletStructure.Ref_Key And ContactInfoStructure.Вид = AddressKind Then
				
				Address = ContactInfoStructure.Представление;
				
			EndIf;
			//////
			If ContactInfoStructure.Объект_Type = Outlets And ContactInfoStructure.Объект = OutletStructure.Ref_Key And ContactInfoStructure.Вид = PhoneKind Then
				
				Phone = ContactInfoStructure.Представление;
				
			EndIf;
			If ContactInfoStructure.Объект_Type = Outlets And ContactInfoStructure.Объект = OutletStructure.Ref_Key And ContactInfoStructure.Вид = EmailKind Then
				
				Email = ContactInfoStructure.Представление;
				
			EndIf;
			//////
			
		EndDo;
		
		If ValueIsFilled(Address) And Not ContractorObject.LegalAddress = Address Then
			
			ContractorObject.LegalAddress = Address;
			
		EndIf;
		//////////
		If ValueIsFilled(Phone) And Not ContractorObject.PhoneNumber = Phone Then
			
			ContractorObject.PhoneNumber = Phone;
			
		EndIf;
		If ValueIsFilled(Email) And Not ContractorObject.Email = Email Then
			
			ContractorObject.Email = Email;
			
		EndIf;
		//////////
		
		If ValueIsFilled(ContractorObject.LegalAddress) Then
			
			ContractorObject.Description = OutletStructure.Description;
			ContractorObject.LegalName = OutletStructure.НаименованиеПолное;
			ContractorObject.LegalAddress = Address;
			ContractorObject.INN = OutletStructure.ИНН;
			ContractorObject.KPP = OutletStructure.КПП;
			////////
			//ContractorObject.Email = OutletStructure.АдресЭлектроннойПочты;
			//ContractorObject.PhoneNumber = OutletStructure.Телефон;
			////////			
			ContractorObject.OwnershipType = ?(OutletStructure.ЮрФизЛицо = "ЮрЛицо", Enums.OwnershipType.OOO, Enums.OwnershipType.IP);
			
			If ContractorObject.IsNew() Then
				
				NewRegionRow = ContractorObject.Regions.Add();
				NewRegionRow.Region = Catalogs.Region.FindByDescription(NStr("en = 'Default region'; ru = 'Основной регион'"));
				
			EndIf;
			
			If OutletStructure.МенеджерыПокупателя.Count() <> 0 then
				For Each ManagerRef In OutletStructure.МенеджерыПокупателя Do
					
					TerritoryRef = Catalogs.Territory.FindByAttribute("ExternalId", ManagerRef);
					
					If ContractorObject.Territories.Find(ManagerRef) = Undefined Then
						
						NewTerritoryRow = ContractorObject.Territories.Add();
						NewTerritoryRow.Territory = TerritoryRef;
						
					EndIf;
					
				EndDo;
				
			else
				
				NewTerritoryRow = ContractorObject.Territories.Add();
				NewTerritoryRow.Territory = _TerritoryObject.Ref;
				
			endIf;
			
			If Not (ContractorObject.Ref.Description = ContractorObject.Description And
				ContractorObject.Ref.LegalName = ContractorObject.LegalName And
				ContractorObject.Ref.LegalAddress = ContractorObject.LegalAddress And
				ContractorObject.Ref.INN = ContractorObject.INN And
				ContractorObject.Ref.KPP = ContractorObject.KPP And
				////////////////////
				//ContractorObject.Ref.PhoneNumber = ContractorObject.PhoneNumber And
				//ContractorObject.Ref.Email = ContractorObject.Email And
				////////////////////
				ContractorObject.Ref.OwnershipType = ContractorObject.OwnershipType) Then
				
				ContractorObject.Write();
				
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(Address) And Not OutletObj.Address = Address Then
			
			OutletObj.Address = Address;
			
		EndIf;
		
		If ValueIsFilled(OutletObj.Address) Then
			
			OutletObj.Description = OutletStructure.Description;
			
			If Not ValueIsFilled(OutletObj.OutletStatus) Then
				
				OutletObj.OutletStatus = Enums.OutletStatus.Active;
				
			EndIf;
			
			If Not ValueIsFilled(OutletObj.Type) Then
				
				OutletObj.Type = Constants.OutletTypeDef.Get();//Catalogs.OutletType.FindByDescription(NStr("en = 'Default type'; ru = 'Основной тип'"));
				
			EndIf;
			
			If Not ValueIsFilled(OutletObj.Class) Then
				
				OutletObj.Class = Constants.OutletCalssDef.Get();//Catalogs.OutletClass.FindByDescription(NStr("en = 'Default class'; ru = 'Основной класс'"));
				
			EndIf;
			
			ContactRef = Catalogs.ContactPersons.GetRef(New UUID(OutletStructure.ОсновноеКонтактноеЛицо_Key));
			
			NeedWrite = False;
			
			If Not ContactRef = Catalogs.ContactPersons.EmptyRef() And Not ContactRef.GetObject() = Undefined Then
				
				If OutletObj.ContactPersons.Find(ContactRef) = Undefined Then
					
					NewContactPersonRow = OutletObj.ContactPersons.Add();
					NewContactPersonRow.ContactPerson = ContactRef;
					
					NeedWrite = True;
					
				EndIf;
				
			EndIf;
			
			If OutletObj.ContractorsList.Find(ContractorObject.Ref) = Undefined Then
				
				OutletObj.ContractorsList.Clear();
				NewContractorRow = OutletObj.ContractorsList.Add();
				NewContractorRow.Contractor = ContractorObject.Ref;
				NewContractorRow.Default = True;
				
				NeedWrite = True;
				
			EndIf;
			
			If Not (OutletObj.Ref.Description = OutletObj.Description) And NeedWrite Then
				
				OutletObj.Write();
				
			EndIf;
			
			If OutletStructure.МенеджерыПокупателя.count() <> 0 then
				For Each ManagerRef In OutletStructure.МенеджерыПокупателя Do
				
					//TerritoryRef = Catalogs.Territory.GetRef(New UUID(ManagerRef));
					//TerritoryObj = TerritoryRef.GetObject();
					
					TerritoryRef = Catalogs.Territory.FindByAttribute("ExternalId", ManagerRef);
					
					//If Not TerritoryObj = Undefined Then
					
					If Not TerritoryRef.IsEmpty() Then
						
						TerritoryObj = TerritoryRef.GetObject();
						
						If TerritoryObj.Outlets.Find(OutletObj.Ref) = Undefined Then
							
							NewOutletRow = TerritoryObj.Outlets.Add();
							NewOutletRow.Outlet = OutletObj.Ref;
							TerritoryObj.Write();
							
						EndIf;
						
					EndIf;
					
				EndDo;
				
			else
				If _TerritoryObject.Outlets.Find(OutletObj.Ref)=Undefined Then
					newOutletLine = _TerritoryObject.Outlets.Add();	
					newOutletLine.Outlet = OutletObj.Ref;
				EndIf;								
			endIf;
			
		EndIf;
		
	EndDo;
	
	_TerritoryObject.Write();
	
EndProcedure

Procedure WriteUnitsForSKU103(SCUObject, SKURef_Key, UnitStructureArray)
	
	For each UnitStructure In UnitStructureArray Do
		
		If UnitStructure.Owner = SKURef_Key then
			UnitObject = GetCatalogObject("UnitsOfMeasure", New UUID(UnitStructure.Ref_Key));
			UnitObject.Description = UnitStructure.Description;
			UnitObject.FullDescription = UnitStructure.Description;	
			
			If Not (UnitObject.Ref.Description = UnitObject.Description And
				UnitObject.Ref.FullDescription = UnitObject.FullDescription) Then
				UnitObject.Write();
			EndIf;
			If false then
				SCUObject = Catalogs.SKU.CreateItem();
			endIF;
			
			If SCUObject.Packing.Find(UnitObject.Ref, "Pack") = Undefined then
				newPackLine = SCUObject.Packing.Add();
				newPackLine.Pack       = UnitObject.Ref;
				newPackLine.Multiplier = UnitStructure.Коэффициент;
				If Not ValueIsFilled(SCUObject.BaseUnit) AND newPackLine.Multiplier = 1 then
					SCUObject.BaseUnit = UnitObject.Ref;		
				EndIf;
				SCUObject.Write();
			EndIf;			
		EndIf;			
	EndDo;
	
	
EndProcedure

Procedure WriteSKUs103(ObjectArrays)
	
	SKUsStructureArray = ObjectArrays.Get(SKUs);
	SeriesStructureArray = ObjectArrays.Get(Series);
	UnitStructureArray = ObjectArrays.Get(Units103);
	
	For Each SKUStructure In SKUsStructureArray Do
		
		SKUGroupRef = Catalogs.SKUGroup.GetRef(New UUID(SKUStructure.Parent_Key));
		SKUGroupObject = SKUGroupRef.GetObject();
		
		If Not SKUGroupObject = Undefined And Not SKUGroupObject.IsFolder Then
			
			If SKUStructure.ВестиУчетПоСериям = "true" Then
				
				For Each SerieStructure In SeriesStructureArray Do
					
					If SerieStructure.Owner_Key = SKUStructure.Ref_Key Then
						
						SKUObject = GetCatalogObject("SKU", SerieStructure.Ref_Key);
						SKUObject.Description = SKUStructure.Description + " (" + SerieStructure.Description + ")";
						SKUObject.Owner = SKUGroupRef;
						SKUObject.Brand = Catalogs.Brands.DefaultBrand;
						SKUObject.ExternalId = SKUStructure.Ref_Key;
						
						WriteUnitsForSKU103(SKUObject, SerieStructure.Owner_Key, UnitStructureArray);
						
						If Not (SKUObject.Ref.Description = SKUObject.Description And
							SKUObject.Ref.Owner = SKUObject.Owner And
							SKUObject.Ref.Brand = SKUObject.Brand And
							SKUObject.Ref.BaseUnit = SKUObject.BaseUnit AND
							SKUObject.Ref.ExternalId = SKUObject.ExternalId) Then
							
							SKUObject.Write();
							
						EndIf;
						
					EndIf;
					
				EndDo;
				
			ElsIf SKUStructure.ВестиУчетПоСериям = "false" Then
				
				SKUObject = GetCatalogObject("SKU", SKUStructure.Ref_Key);
				SKUObject.Description = SKUStructure.Description;
				SKUObject.Owner = SKUGroupRef;
				SKUObject.Brand = Catalogs.Brands.DefaultBrand;
				WriteUnitsForSKU103(SKUObject, SKUStructure.Ref_Key, UnitStructureArray);
				
				If Not (SKUObject.Ref.Description = SKUObject.Description And
					SKUObject.Ref.Owner = SKUObject.Owner And
					SKUObject.Ref.Brand = SKUObject.Brand And
					SKUObject.Ref.BaseUnit = SKUObject.BaseUnit) Then
					
					SKUObject.Write();
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WriteSKUGroups103(ObjectArrays)
	
	SKUGroupsArray = ObjectArrays.Get(SKUGroups);
					
	SKUGroupsTree = GetSKUGroupsTree(SKUGroupsArray);
	
	WriteSKUGroups(SKUGroupsTree);
	
EndProcedure

Procedure writeMutualSettlements103(ObjectArrays)
	MutualSettlements = ObjectArrays.get(OutletsMutualSettlements103 + "VT");
	For each mutualSettlement in MutualSettlements do
		//Outlet = GetCatalogObject("Outlet", mutualSettlement.Контрагент_key);
		Outlet = Catalogs.Outlet.FindByAttribute("ExternalId", mutualSettlement.Контрагент_key);
		if not ValueIsFilled(Outlet) then
			Continue;
		endIf;
		doc = getMutualSettlementDocByOutlet(Outlet.ref).GetObject();
		
		if false then
			doc = Documents.AccountReceivable.CreateDocument();
		endIf;
		
		if doc.ReceivableDocuments.Count() = 1 And doc.ReceivableDocuments[0].DocumentSum = mutualSettlement.СуммаВзаиморасчетовBalance then
			Continue;
		endIf;
		
		if doc.ReceivableDocuments.Count() = 0 And  mutualSettlement.СуммаВзаиморасчетовBalance = 0 then
			continue;
		endIf;
		
		doc.ReceivableDocuments.Clear();
		if mutualSettlement.СуммаВзаиморасчетовBalance > 0 then
			newLine = doc.ReceivableDocuments.Add();
			newLine.DocumentSum = mutualSettlement.СуммаВзаиморасчетовBalance;
			newLine.DocumentName = "Взаиморасчеты с " + doc.Outlet;
		endIf;
		
		doc.Write(DocumentWriteMode.Write);
	EndDo;
EndProcedure

Procedure writeStocks103(ObjectArrays)
	mStocks = ObjectArrays.get(SKUs103 + "VT");
	while mStocks.count() do
		guid = Undefined;
		lines = new ValueTable;
		if ValueIsFilled(mStocks[0].СерияНоменклатуры_Key) then  
			guid = mStocks[0].СерияНоменклатуры_Key;
			lines = mStocks.FindRows(new Structure("СерияНоменклатуры_Key", guid));
		else
			guid = mStocks[0].Номенклатура_key;			
			lines = mStocks.FindRows(new Structure("Номенклатура_key", guid));
		endIf;
		
		SKU = GetCatalogObject("SKU", guid);	
		if SKU = Undefined then
			for each FoundLine in lines do
				mStocks.delete(FoundLine);	
			endDo;
			continue;
		endIf;
		
		if false then
			SKU = Catalogs.SKU.CreateItem();
		endIf;
		SKU.Stocks.Clear();
		for each foundLine in lines do
			newStockLine = SKU.Stocks.Add();
			newStockLine.Stock = GetCatalogObject("Stock", foundLine.Склад_Key).Ref;
			newStockLine.StockValue = foundLine.КоличествоBalance;
			newStockLine.Feature = Catalogs.SKUFeatures.DefaultFeature
		endDo;
		for each FoundLine in lines do
			mStocks.delete(FoundLine);	
		endDo;
		SKU.Write();
	endDO;
		
EndProcedure

Function getMutualSettlementDocByOutlet(Outlet)
	Query = New Query(
	"SELECT TOP 1
	|	AccountReceivable.Ref
	|FROM
	|	Document.AccountReceivable AS AccountReceivable
	|WHERE
	|	AccountReceivable.DeletionMark = FALSE
	|	AND AccountReceivable.Outlet = &Outlet
	|
	|ORDER BY
	|	AccountReceivable.Date");
	
	Query.SetParameter("Outlet",Outlet);
	Selecton = Query.Execute().Select();
	if Selecton.Next() then
		result = Selecton.ref;
	else
		newDoc = Documents.AccountReceivable.CreateDocument();
		newDoc.Date = CurrentDate();
		newDoc.Outlet = Outlet;
		newDoc.Write(DocumentWriteMode.Write);
		result = newDoc.Ref;
	endIf;
	
	return result;
	
EndFunction

Procedure SendChanges() Export
	
	LoadSettings();
	
	If SourceConfiguration = SOURCE_CONFIG_UT11 then
		ExchangePlanCode = "УТ11";
	elsif SourceConfiguration = SOURCE_CONFIG_UT103 then
		ExchangePlanCode = "УТ103";
	else
		Message(NStr("en = 'Unsupported source configuration'; ru = 'Неподдерживаемая конфигурация источник'"));
		return;
	endIf;
	
	ThisNode = ExchangePlans.bitmobile_ОбменСУчетнымиСистемами.FindByCode(ExchangePlanCode);
	
	If ThisNode = ExchangePlans.bitmobile_ОбменСУчетнымиСистемами.EmptyRef() Then
		Message(NStr("en = 'Create node " + ExchangePlanCode + " in exchange plan'; ru = 'Создайте узел с кодом " + ExchangePlanCode + " в плане обмена ""БИТ.СуперАгент"" в типовой конфигурации.'"));
		Return;
	EndIf;

	Connection = DataProcessors.bitmobile_DataExchanger.GetConnection();
	
	Headers = New Map;
	//Headers.Insert("1C_OData_DataLoadMode", False);
	
	If Not Connection = Undefined Then
		
		НАИМЕНОВАНИЕ_ПАРАМЕТРА_ДЛЯ_ВЫГРУЗКИ = "Не выгружать в УТ";
		
		OrderSelectionFilter = New Array;
		OrderSelectionFilter.Add(Metadata.Documents.Order);		
		ChangedOrdersSelection = ExchangePlans.SelectChanges(ThisNode, 0, OrderSelectionFilter);
		
		checkingParam = Catalogs.OrderParameters.FindByDescription(НАИМЕНОВАНИЕ_ПАРАМЕТРА_ДЛЯ_ВЫГРУЗКИ);
		While ChangedOrdersSelection.Next() Do
			If ValueIsFilled(checkingParam) and not mustBeUploaded(ChangedOrdersSelection.Get(), checkingParam) then
				continue;
			endIf;
			
			Query = New Query(
			"SELECT
			|	bitmobile_ВнешниеИдентификаторыОбъектов.Object,
			|	bitmobile_ВнешниеИдентификаторыОбъектов.ExternalID
			|FROM
			|	InformationRegister.bitmobile_ВнешниеИдентификаторыОбъектов AS bitmobile_ВнешниеИдентификаторыОбъектов
			|WHERE
			|	(CAST(bitmobile_ВнешниеИдентификаторыОбъектов.Object AS Document.Order)) = &Object");
			Query.SetParameter("Object", ChangedOrdersSelection.Get().Ref);
			Result = Query.Execute().Unload();
			
			If Result.Count() = 0 Then
				If SourceConfiguration = SOURCE_CONFIG_UT11 then     //trade 11
					SendPostOrderTrade11(Connection, Headers, ChangedOrdersSelection.Get());
				elsif SourceConfiguration = SOURCE_CONFIG_UT103 then //trade 10.3
					SendPostOrderTrade103(Connection, Headers, ChangedOrdersSelection.Get());
				EndIf;		
				
			Else
				If SourceConfiguration = SOURCE_CONFIG_UT11 then     //trade 11
					SendPatchOrderTrade11(Connection, Headers, ChangedOrdersSelection.Get(), Result[0].ExternalID);
				elsif SourceConfiguration = SOURCE_CONFIG_UT103 then //trade 10.3
					SendPatchOrderTrade103(Connection, Headers, ChangedOrdersSelection.Get(), Result[0].ExternalID);
				EndIf;						
				
			EndIf;
			
		EndDo;
		
		ReturnSelectionFilter = New Array;
		ReturnSelectionFilter.Add(Metadata.Documents.Return);
		ChangedReturnsSelection = ExchangePlans.SelectChanges(ThisNode, 0, ReturnSelectionFilter);
		
		While ChangedReturnsSelection.Next() Do
			If ValueIsFilled(checkingParam) and not mustBeUploaded(ChangedReturnsSelection.Get(), checkingParam) then
				continue;
			endIf;
						
			Query = New Query(
			"SELECT
			|	bitmobile_ВнешниеИдентификаторыОбъектов.Object,
			|	bitmobile_ВнешниеИдентификаторыОбъектов.ExternalID
			|FROM
			|	InformationRegister.bitmobile_ВнешниеИдентификаторыОбъектов AS bitmobile_ВнешниеИдентификаторыОбъектов
			|WHERE
			|	(CAST(bitmobile_ВнешниеИдентификаторыОбъектов.Object AS Document.Return)) = &Object");
			Query.SetParameter("Object", ChangedReturnsSelection.Get().Ref);
			Result = Query.Execute().Unload();
			
			If Result.Count() = 0 Then
				If SourceConfiguration = SOURCE_CONFIG_UT11 then     //trade 11
					SendPostReturnTrade11(Connection, Headers, ChangedReturnsSelection.Get());
				elsif SourceConfiguration = SOURCE_CONFIG_UT103 then //trade 10.3
					SendPostReturnTrade103(Connection, Headers, ChangedReturnsSelection.Get());
				EndIf;		
				
			Else
				If SourceConfiguration = SOURCE_CONFIG_UT11 then     //trade 11
					SendPatchReturnTrade11(Connection, Headers, ChangedReturnsSelection.Get(), Result[0].ExternalID);
				elsif SourceConfiguration = SOURCE_CONFIG_UT103 then //trade 10.3
					SendPatchReturnTrade103(Connection, Headers, ChangedReturnsSelection.Get(), Result[0].ExternalID);
				EndIf;						
				
			EndIf;
			
		EndDo;
		
		EncashmentSelectionFilter = New Array;
		EncashmentSelectionFilter.Add(Metadata.Documents.Encashment);
		ChangedEncashmentSelection = ExchangePlans.SelectChanges(ThisNode, 0, EncashmentSelectionFilter);
		
		While ChangedEncashmentSelection.Next() Do
			
			if not ValueIsFilled(ChangedEncashmentSelection.Get().Visit) then 
				continue;
			endIf;			
			
			Query = New Query(
			"SELECT
			|	bitmobile_ВнешниеИдентификаторыОбъектов.Object,
			|	bitmobile_ВнешниеИдентификаторыОбъектов.ExternalID
			|FROM
			|	InformationRegister.bitmobile_ВнешниеИдентификаторыОбъектов AS bitmobile_ВнешниеИдентификаторыОбъектов
			|WHERE
			|	(CAST(bitmobile_ВнешниеИдентификаторыОбъектов.Object AS Document.Encashment)) = &Object");
			Query.SetParameter("Object", ChangedEncashmentSelection.Get().Ref);
			Result = Query.Execute().Unload();
			
			If Result.Count() = 0 Then
				If SourceConfiguration = SOURCE_CONFIG_UT11 then     //trade 11
					//SendPostReturnTrade11(Connection, Headers, ChangedEncashmentSelection.Get());
				elsif SourceConfiguration = SOURCE_CONFIG_UT103 then //trade 10.3
					SendPostEncashmentTrade103(Connection, Headers, ChangedEncashmentSelection.Get());
				EndIf;		
				
			Else
				If SourceConfiguration = SOURCE_CONFIG_UT11 then     //trade 11
				//	SendPatchReturnTrade11(Connection, Headers, ChangedEncashmentSelection.Get(), Result[0].ExternalID);
				elsif SourceConfiguration = SOURCE_CONFIG_UT103 then //trade 10.3
					SendPatchEncashmentTrade103(Connection, Headers, ChangedEncashmentSelection.Get(), Result[0].ExternalID);
				EndIf;						
				
			EndIf;
			
		EndDo;
		
		
		ExchangePlans.DeleteChangeRecords(ThisNode);
		
	EndIf;
			
EndProcedure

// check by object parametr if it is nessasary to upload 
function mustBeUploaded(docObject, checkingParam)
	for each line in docObject.Parameters do
		if line.parameter = checkingParam AND checkingParam.DataType = Enums.DataType.Boolean then
			if line.value = true OR line.value = "Истина" OR line.value = "true" OR line.value = "Да" OR line.value = "Можетбыть" then
				return false;
			else
				return true;
			endIf;
		endIf;		
	endDo;	
	return true;
endFunction

Function GetCommonRefCatalogObject(CatalogName, UUID)
	
	Ref = Catalogs[CatalogName].FindByAttribute("ExternalId", UUID);
	
	If Ref = Catalogs[CatalogName].EmptyRef() Then
		
		Obj = Catalogs[CatalogName].CreateItem();
		Obj.ExternalId = UUID;
		
		Return Obj;
		
	Else
		
		Return Ref.GetObject();
		
	EndIf;
	
EndFunction

#Region HTTP

Function GetResponseBody(Response)

	Body = Response.GetBodyAsString();
	
	Return Body;
	
EndFunction

Function GetResponse(Connection, Request)
	
	Result = Connection.Post(Request);
	
	Return Result;
	
EndFunction

Function GetSelectChangesRequest()
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/SelectChanges?DataExchangePoint='" + ThisObject.CurrentExchangePlanNodeId + "'&MessageNo=" + "0");
	
	Return Request;
	
EndFunction

Procedure SendSuccessMessageServer()
	
	FillPropertyValues(ThisObject, DataProcessors.bitmobile_DataExchanger.GetSettings());
	
	Connection = DataProcessors.bitmobile_DataExchanger.GetConnection();
	
	If Not Connection = Undefined Then
		
		Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/NotifyChangesReceived?DataExchangePoint='" + ThisObject.CurrentExchangePlanNodeId + "'&MessageNo=" + ThisObject.MessageNo);
		
		Result = Connection.Post(Request);
		
		If Result.StatusCode = 200 Then
			
			ThisObject.MessageNo = ThisObject.MessageNo + 1;
			
			Settings = DataProcessors.bitmobile_DataExchanger.GetEmptySettingsStructure();
			FillPropertyValues(Settings, ThisObject);
			DataProcessors.bitmobile_DataExchanger.SetSettings(Settings);
			
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region XML

Function GetXMLDocumentPathesFromRequest(Connection, Request)
	
	Response = GetResponse(Connection, Request);
	Body = GetResponseBody(Response);
	
	FileName = GetTempFileName(".xml");
	FileText = New TextDocument;
	FileText.SetText(Body);
	FileText.Write(FileName);
	
	
	FilePathesArray = new Array;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileName);
	RootElemAtributesMap = getRootElementAtributesArray(XMLReader);
	
	ElementCounter = 0;
	
	XMLWriter = CreateXMLWriterExchangeFile(FilePathesArray, RootElemAtributesMap);
	
	while XMLReader.Read() do
		if ElementCounter >= MAX_ENTRY_NUMBER_PER_FILE then
			CloseXMLWriterExchangeFile(XMLWriter);
			
			XMLWriter = CreateXMLWriterExchangeFile(FilePathesArray, RootElemAtributesMap);
			ElementCounter = 0;	
		endIf;
		
		
		if XMLReader.Name = "entry" AND XMLReader.NodeType = XMLNodeType.StartElement then
			CopyEntryElement(XMLReader, XMLWriter);	
		endIf;		
			
		ElementCounter = ElementCounter + 1;
	endDo;
		
	if ElementCounter <> 0 then
		CloseXMLWriterExchangeFile(XMLWriter);	
	endIf;
	
	
	//Doc = GetXMLReaderFromString(Body);
	
	Return FilePathesArray;
	
EndFunction


Function GetXMLReaderFromString(Body)
	
	// Чтение результата запроса в XML
	XMLReader = New XMLReader;
	XMLReader.SetString(Body);
	
	DOMBuilder = New DOMBuilder;
	Doc = DOMBuilder.Read(XMLReader);
	Return Doc;
	
EndFunction

Function GetObjectArrays(Connection)
	
	ObjectPropertyNames = GetPropertyNamesMap();
	ObjectArrays = GetEmptyObjectArrays();
	
	ExchangePlanNodeXMLDoc = GetExchangePlanNodeXMLDoc(Connection);
	
	
	AddressKind = GetExchangePlanAttribute(ExchangePlanNodeXMLDoc, "d:АдресТорговойТочкиИз_Key");
	
	If SourceConfiguration = SOURCE_CONFIG_UT11 Then
		
		ObjectArrays.Insert("ManagersAsTerritories", GetManagersAsTerritoriesSetting(ExchangePlanNodeXMLDoc));
		
	ElsIf SourceConfiguration = SOURCE_CONFIG_UT103 Then
		
		PhoneKind = GetExchangePlanAttribute(ExchangePlanNodeXMLDoc, "d:ТелефонКонтактаИз_Key");
		EmailKind = GetExchangePlanAttribute(ExchangePlanNodeXMLDoc, "d:ЭлектроннаяПочтаКонтактаИз_Key");
		oldStock = GetExchangePlanAttribute(ExchangePlanNodeXMLDoc, "d:УдалитьСкладДляОстатков_Key");
		StocksForRemains103 = getStocksForRemains103(ExchangePlanNodeXMLDoc);		
		if StocksForRemains103.count() = 0 and ValueIsFilled(oldStock) then
			StocksForRemains103.add(oldStock);
		endIf;
		
	EndIf;
	
	//XMLDocument = GetXMLDocumentFromRequest(Connection, GetSelectChangesRequest());
	FilePathesArray = GetXMLDocumentPathesFromRequest(Connection, GetSelectChangesRequest());
	
	for each FilePath in FilePathesArray do
		
			// Чтение результата запроса в XML
		XMLReader = New XMLReader;
		XMLReader.OpenFile(FilePath);
		DOMBuilder = New DOMBuilder;
		XMLDocument = DOMBuilder.Read(XMLReader);
		
		Entries = XMLDocument.GetElementByTagName("entry");
		
		For Each Entry In Entries Do
			
			CategoryNode = Entry.GetElementByTagName("category")[0];
			Term = CategoryNode.GetAttributeNode("term").NodeValue;
			
			FoundPropertyNames = ObjectPropertyNames.Get(Term);
			PropertyNames = ?(FoundPropertyNames = Undefined, New Array, FoundPropertyNames);
			
			PropertiesNodes = Entry.GetElementByTagName("properties");
			
			If Left(Term, StrLen(Catalog)) = Catalog Or ((Term = Prices Or Term = ContactInfo) And SourceConfiguration = 1) Then
				
				If Term = Prices And SourceConfiguration = 1 Then
					
					ElementNodes = Entry.GetElementByTagName("element");
					
					For Each ElementNode In ElementNodes Do
						
						ObjectStructure = New Structure;
						ObjectStructure.Insert("Term", Term);
						
						For Each Property In ElementNode.ChildNodes Do
							
							If Not PropertyNames.Find(Property.LocalName) = Undefined Then
								
								ObjectStructure.Insert(Property.LocalName, Property.TextContent);
								
							EndIf;
							
						EndDo;
						
						ObjectArray = ObjectArrays.Get(ObjectStructure.Term);
						ObjectArray.Add(ObjectStructure);
						
					EndDo;
					
				Else
					
					ObjectStructure = GetObjectStructure(PropertiesNodes, PropertyNames, Term);
					ObjectArray = ObjectArrays.Get(ObjectStructure.Term);
					ObjectArray.Add(ObjectStructure);
					
				EndIf;
				
			ElsIf Left(Term, StrLen(AccumulationRegister)) = AccumulationRegister Or Left(Term, StrLen(InformationRegister)) = InformationRegister Then
				
				ElementNodes = Entry.GetElementByTagName("element");
				
				For Each ElementNode In ElementNodes Do
					
					ObjectStructure = New Structure;
					ObjectStructure.Insert("Term", Term);
					
					For Each Property In ElementNode.ChildNodes Do
						
						If Not PropertyNames.Find(Property.LocalName) = Undefined Then
							
							ObjectStructure.Insert(Property.LocalName, Property.TextContent);
							
						EndIf;
						
					EndDo;
					
					ObjectArray = ObjectArrays.Get(ObjectStructure.Term);
					ObjectArray.Add(ObjectStructure);
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
		If SourceConfiguration = SOURCE_CONFIG_UT11 Then
			
			GetAllSKUStocks(Connection, ObjectArrays);
			GetAgreements(Connection, ObjectArrays);
			
			
		EndIf;
		
	enddo;	
		
	Return ObjectArrays;
	
EndFunction

Function GetAllSKUStocks103(Connection, ObjectArrays)
	
	
	
EndFunction

Function GetExchangePlanNodeXMLDoc(Connection)
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/ExchangePlan_bitmobile_УправлениеТорговлейСуперагент(guid'" + ThisObject.CurrentExchangePlanNodeRefKey + "')");
	Response = Connection.Get(Request);
	Body = Response.GetBodyAsString();
		
	Doc = GetXMLReaderFromString(Body);
	
	Return Doc;
	
EndFunction

Function GetExchangePlanAttribute(ExchangePlanNodeXMLDoc, TagName)
	
	If ExchangePlanNodeXMLDoc.GetElementByTagName(TagName).Count()>0 Then
		ElementValue = ExchangePlanNodeXMLDoc.GetElementByTagName(TagName)[0].TextContent;
	Else
		ElementValue = "";
	EndIf;
	Return ElementValue;
	
EndFunction

Function GetManagersAsTerritoriesSetting(ExchangePlanNodeXMLDoc)
	
	If 	ExchangePlanNodeXMLDoc.GetElementByTagName("d:ПривязыватьПартнеровКТерриториям").Count()>0 Then
		ElementValue = ExchangePlanNodeXMLDoc.GetElementByTagName("d:ПривязыватьПартнеровКТерриториям")[0].TextContent;
	Else
		ElementValue = "false";
	EndIf;
	ManagersAsTerritories = ElementValue = "true";
	
	Return ManagersAsTerritories;

EndFunction

Procedure GetAgreements(Connection, ObjectArrays)
	
	AgreementsArray = ObjectArrays.Get(Agreements);
	
	AgreementsVT = New ValueTable;
	AgreementsVT.Columns.Add("Ref_Key");
	AgreementsVT.Columns.Add("Контрагент_Key");
	AgreementsVT.Columns.Add("ВидЦен_Key");
	
	For Each AgreementStructure In AgreementsArray Do
		
		AgreementRow = AgreementsVT.Add();
		FillPropertyValues(AgreementRow, AgreementStructure);
		
	EndDo;
	
	AgreementsVT.GroupBy("Контрагент_Key");
	EmptyContractorRow = AgreementsVT.Find(EmptyRefString);
	
	If Not EmptyContractorRow = Undefined Then
		AgreementsVT.Delete(EmptyContractorRow);
	EndIf;
	
	AgreementsArray = AgreementsVT.UnloadColumn("Контрагент_Key");
	
	ObjectArrays.Insert("UpdatedOutletsPricesArray", AgreementsArray);
	
	AgreementsStructuresArray = New Array;
	
	For Each Agreement In AgreementsArray Do
		
		Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Catalog_СоглашенияСКлиентами?$filter=Контрагент_Key eq guid'" + Agreement + "' and ВидЦен_Key ne guid'" + EmptyRefString + "'&$select=Контрагент_Key,ВидЦен_Key");
		Response = Connection.Get(Request);
		Body = Response.GetBodyAsString();
		
		AgreementXML = GetXMLReaderFromString(Body);
		
		EntryNodes = AgreementXML.GetElementByTagName("entry");
		
		For Each EntryNode In EntryNodes Do
			
			PropertyNodes = EntryNode.GetElementByTagName("properties");
			ObjectStructure = GetObjectStructure(PropertyNodes, GetAgreementsPropertyNames(), Agreements);
			AgreementsStructuresArray.Add(ObjectStructure);
			
		EndDo;
		
	EndDo;
	
	ObjectArrays.Insert(Agreements, AgreementsStructuresArray);

EndProcedure

Procedure GetAllSKUStocks(Connection, ObjectArrays)
	
	StatusCode = 0;
	
	Query = New Query(
	"SELECT
	|	SKU.Ref
	|FROM
	|	Catalog.SKU AS SKU");
	Result = Query.Execute().Unload();
	Result.Columns.Add("Ref_Key");
	
	For Each AllSKUsRow In Result Do
		
		AllSKUsRow.Ref_Key = AllSKUsRow.Ref.UUID();
		
	EndDo;
	
	AllSKUs = Result.UnloadColumn("Ref_Key");
	
	ChangedSKUs = ObjectArrays.Get(SKUs);
	
	For Each ChangedSKU In ChangedSKUS Do
		
		FoundSKURef = AllSKUs.Find(New UUID(ChangedSKU.Ref_Key));
		
		If FoundSKURef = Undefined Then
			
			AllSKUs.Add(ChangedSKU.Ref_Key);
			
		EndIf;
		
	EndDo;
	
	SKUStocksArray = New Array;
	
	ObjectArrays.Insert(UpdatedSKUStocks, AllSKUs);
	UpdatedSKUStocksArray = AllSKUs;
	
	SKUStocksVT = New ValueTable;
	SKUStocksVT.Columns.Add("Номенклатура_Key");
	SKUStocksVT.Columns.Add("Склад_Key");
	SKUStocksVT.Columns.Add("ВНаличииBalance");
	
	If UpdatedSKUStocksArray.Count() > 0 Then
		
		FirstElement = 0;
		Offset = UpdatedSKUStocksArray.Count() - 1;
		GetSKUStocks(Connection, UpdatedSKUStocksArray, SKUStocksArray, FirstElement, Offset);
		
		For Each SKUStock In SKUStocksArray Do
			
			NewRow = SKUStocksVT.Add();
			FillPropertyValues(NewRow, SKUStock, "Номенклатура_Key, Склад_Key");
			NewRow.ВНаличииBalance = Number(SKUStock.ВНаличииBalance);
			
		EndDo;
		
	EndIf;
	
	SKUStocksVT.GroupBy("Номенклатура_Key, Склад_Key", "ВНаличииBalance");
	ObjectArrays.Insert(UpdatedSKUStocks + "VT", SKUStocksVT);

EndProcedure

Procedure GetSKUStocks(Connection, UpdatedSKUStocksArray, SKUStocksArray, FirstElement, Offset)
	
	LastElement = ?(FirstElement + Offset > UpdatedSKUStocksArray.Count() - 1, UpdatedSKUStocksArray.Count() - 1, FirstElement + Offset);
	
	If Not (FirstElement >= UpdatedSKUStocksArray.Count()) Then
		
		FilterString = GetFilterString(UpdatedSKUStocksArray, FirstElement, LastElement);
		Request = GetStocksRequest(FilterString);
		Try
			Response = Connection.Get(Request);
			StatusCode = Response.StatusCode;
		Except
			StatusCode = 405;
		EndTry;

		
		If StatusCode = 200 Then
			
			Doc = GetXMLReaderFromString(Response.GetBodyAsString());
			ElementNodes = Doc.GetElementByTagName("element");
			
			For Each ElementNode In ElementNodes Do
			
				ObjectStructure = New Structure;
				ProcessElementNode(ElementNode, ObjectStructure);
				SKUStocksArray.Add(ObjectStructure);
				
			EndDo;
			
			FirstElement = FirstElement + Offset + 1;
			
			If Not Offset = 0 Then
				
				GetSkuStocks(Connection, UpdatedSKUStocksArray, SKUStocksArray, FirstElement, Offset);
				
			EndIf;
			
		Else
			
			Offset = Round(Offset / 2,0,RoundMode.Round15as10);
			GetSKUStocks(Connection, UpdatedSKUStocksArray, SKUStocksArray, FirstElement, Offset);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function GetStocksRequest(FilterString)
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/AccumulationRegister_СвободныеОстатки/Balance()?$filter=" + FilterString);
	
	Return Request;
	
EndFunction

Function GetFilterString(UpdatedSKUStocksArray, FirstElement, Offset)
	
	FilterString = "";
	
	For Index = FirstElement To Offset Do
		
		FilterString = FilterString + "Номенклатура_Key eq guid'" + UpdatedSKUStocksArray[Index] + "' or ";
		
	EndDo;
	
	FilterString = Left(FilterString, StrLen(FilterString) - 4);
	
	Return FilterString;
	
EndFunction

Function GetObjectStructure(PropertiesNodes, PropertyNames, Term)
	
	ObjectStructure = New Structure;
	ObjectStructure.Insert("Term", Term);
	
	GetCommonObjectStructure(ObjectStructure, PropertiesNodes, PropertyNames);
	
	Return ObjectStructure;
	
EndFunction

Procedure GetAccumulationRegisterObjectStructure(ObjectStructure, PropertiesNodes)
	
	For Each PropertiesNode In PropertiesNodes Do
		
		ElementsNodes = PropertiesNode.GetElementByTagName("element");
		
		For Each ElementNode In ElementsNodes Do
			
			ProcessElementNode(ElementNode, ObjectStructure);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure ProcessElementNode(ElementNode, ObjectStructure)
	
	For Each Property In ElementNode.ChildNodes Do
		
		ObjectStructure.Insert(Property.LocalName, Property.TextContent);
		
	EndDo;

EndProcedure

Procedure GetCommonObjectStructure(ObjectStructure, PropertiesNodes, PropertyNames)
	
	For Each PropertiesNode In PropertiesNodes Do
		
		For Each Property In PropertiesNode.ChildNodes Do
			
			If Not PropertyNames.Find(Property.LocalName) = Undefined Then
				
				ObjectStructure.Insert(Property.LocalName, Property.TextContent);
				
				If ObjectStructure.Term = SKUs And Property.LocalName = "IsFolder" And Property.TextContent = "true" Then
					
					ObjectStructure.Term = SKUGroups;
					
				EndIf;
				
				If ObjectStructure.Term = Outlets 
					Or ObjectStructure.Term = Partners 
					Or ObjectStructure.Term = Contacts 
					And Property.LocalName = "КонтактнаяИнформация" Then
					
					//ObjectStructure.Insert("КонтактнаяИнформация", "");
					
					Elements = Property.GetElementByTagName("element");
					
					For Each Element In Elements Do
						
						TypeNodes = Element.GetElementByTagName("Тип");
						
						For Each TypeNode In TypeNodes Do
							
							If TypeNode.TextContent = "Адрес" Then
								
								KindRef = Element.GetElementByTagName("Вид_Key")[0].TextContent;
								
								If KindRef = AddressKind Then
									
									PresentationNodes = Element.GetElementByTagName("Представление");
									ObjectStructure.Insert("КонтактнаяИнформация", PresentationNodes[0].TextContent);
									
								EndIf;
								
							ElsIf TypeNode.TextContent = "Телефон" Or TypeNode.TextContent = "АдресЭлектроннойПочты" Then
								
								PresentationNodes = Element.GetElementByTagName("Представление");
								ObjectStructure.Insert(TypeNode.TextContent, PresentationNodes[0].TextContent);
								
							EndIf;
						
						EndDo;
						
					EndDo;
					
				EndIf;
				
				If ObjectStructure.Term = Outlets And Property.LocalName = "МенеджерыПокупателя" Then
					
					Elements = Property.GetElementByTagName("element");
					ManagersArray = New Array;
					
					For Each Element In Elements Do
						
						ManagersArray.Add(Element.GetElementByTagName("МенеджерПокупателя_Key")[0].TextContent);
						
						
					EndDo;
					
					ObjectStructure.Insert("МенеджерыПокупателя", ManagersArray);
					
				EndIf;
				
				If ObjectStructure.Term = UsersCat And Property.LocalName = "КонтактнаяИнформация" Then
					
					ObjectStructure.Insert("Email");
					
					For Each Element In Property.ChildNodes Do
						
						TypeNodes = Element.GetElementByTagName("Тип");
						
						If TypeNodes.Count() > 0 Then
							
							If TypeNodes[0].TextContent = "АдресЭлектроннойПочты" Then
								
								EmailNodes = Element.GetElementByTagName("АдресЭП");
								
								If EmailNodes.Count() > 0 And ValueIsFilled(TrimAll(EmailNodes[0].TextContent)) Then
									
									ObjectStructure.Insert("Email", EmailNodes[0].TextContent);
									
								EndIf;
								
							EndIf;
							
						EndIf;
						
					EndDo;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure getAllOutletsMutualSettlements103(Connection, ObjectArrays)
	
	StatusCode = 0;
	
	Query = New Query(
	"SELECT
	|	Outlet.ExternalId AS Ref_Key
	|FROM
	|	Catalog.Outlet AS Outlet");
	Result = Query.Execute().Unload();	
	
	AllOutlets = Result.UnloadColumn("Ref_Key");
	
	OutletsMutualSettlementsArray = New Array;
	
	ObjectArrays.Insert(OutletsMutualSettlements103, AllOutlets);
	UpdatedOutletsMutualSettlementsArray = AllOutlets;
	
	OutletsMutualSettlementsVT = New ValueTable;
	OutletsMutualSettlementsVT.Columns.Add("Контрагент_Key");            
	OutletsMutualSettlementsVT.Columns.Add("СуммаВзаиморасчетовBalance");
	
	If UpdatedOutletsMutualSettlementsArray.Count() > 0 Then
		
		FirstElement = 0;
		Offset = UpdatedOutletsMutualSettlementsArray.Count() - 1;
		
		getOutletsMutualSettlements103(Connection, UpdatedOutletsMutualSettlementsArray, OutletsMutualSettlementsArray, FirstElement, Offset);
		
		For Each MutualSettlement In OutletsMutualSettlementsArray Do
			
			NewRow = OutletsMutualSettlementsVT.Add();                    
			FillPropertyValues(NewRow, MutualSettlement, "Контрагент_Key, СуммаВзаиморасчетовBalance");
			NewRow.СуммаВзаиморасчетовBalance = Number(MutualSettlement.СуммаВзаиморасчетовBalance);
			
		EndDo;
		
	EndIf;
	
	OutletsMutualSettlementsVT.GroupBy("Контрагент_Key", "СуммаВзаиморасчетовBalance");
	ObjectArrays.Insert(OutletsMutualSettlements103 + "VT", OutletsMutualSettlementsVT);
	
	
EndProcedure

Procedure getOutletsMutualSettlements103(Connection, UpdatedOutletsMutualSettlementsArray, OutletsMutualSettlementsArray, FirstElement, Offset)	                                 
	
	LastElement = ?(FirstElement + Offset > UpdatedOutletsMutualSettlementsArray.Count() - 1, UpdatedOutletsMutualSettlementsArray.Count() - 1, FirstElement + Offset);
	
	If Not (FirstElement >= UpdatedOutletsMutualSettlementsArray.Count()) Then
		
		FilterString = GetMutualSettlementsFilterString103(UpdatedOutletsMutualSettlementsArray, FirstElement, LastElement);
		
		Request = GetMutualSettlementsRequest103(FilterString);
		Response = Connection.Get(Request);
		StatusCode = Response.StatusCode;
		
		If StatusCode = 200 Then
			
			Doc = GetXMLReaderFromString(Response.GetBodyAsString());
			ElementNodes = Doc.GetElementByTagName("element");
			
			For Each ElementNode In ElementNodes Do
			
				ObjectStructure = New Structure;
				ProcessElementNode(ElementNode, ObjectStructure);
				OutletsMutualSettlementsArray.Add(ObjectStructure);
				
			EndDo;
			
			FirstElement = FirstElement + Offset + 1;
			
			If Not Offset = 0 Then
				
				getOutletsMutualSettlements103(Connection, UpdatedOutletsMutualSettlementsArray, OutletsMutualSettlementsArray, FirstElement, Offset);
				
			EndIf;
			
		Else
			
			Offset = Round(Offset / 2);
			getOutletsMutualSettlements103(Connection, UpdatedOutletsMutualSettlementsArray, OutletsMutualSettlementsArray, FirstElement, Offset);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function GetMutualSettlementsRequest103(FilterString)
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/AccumulationRegister_ВзаиморасчетыСКонтрагентамиПоДокументамРасчетов/Balance()?$filter=" + FilterString);
	
	Return Request;
	
EndFunction

Function GetMutualSettlementsFilterString103(UpdatedOutletsMutualSettlementsArray, FirstElement, Offset)
	                          	
	FilterString = "";
	
	For Index = FirstElement To Offset Do
		
		FilterString = FilterString + "Контрагент_Key eq guid'" + UpdatedOutletsMutualSettlementsArray[Index] + "' or ";
		
	EndDo;
	
	FilterString = Left(FilterString, StrLen(FilterString) - 4);
	
	Return FilterString;
	
EndFunction

Procedure gelAllSKUStocks103(Connection, ObjectArrays)
	
	StatusCode = 0;
	
	AllTrueSKUs = new Array; //simple sku items (номенклатура без учета серий)
	AllSeriesSKUs = new Array; //sku created from series
	
	SKUsBalanceVT = New ValueTable;
	SKUsBalanceVT.Columns.Add("Номенклатура_Key");             
	SKUsBalanceVT.Columns.Add("СерияНоменклатуры_Key");
	SKUsBalanceVT.Columns.Add("Склад_Key");
	SKUsBalanceVT.Columns.Add("КоличествоBalance");
	
	Query = New Query(
	"SELECT
	|	SKU.Ref
	|FROM
	|	Catalog.SKU AS SKU");
	Result = Query.Execute().select();
	
	while Result.next() Do
		if ValueIsFilled(Result.Ref.ExternalId) then //SKU based on series 
			AllSeriesSKUs.Add(Result.Ref.UUID());
		else 
			AllTrueSKUs.Add(Result.Ref.UUID());
		endIf;
	endDo;
	
	SKUsArray  = New Array;
	
	//ObjectArrays.Insert(SKUs103, AllSKUs);
	
	//true items 
	UpdatedSKUsArray = AllTrueSKUs;	
	If UpdatedSKUsArray.Count() > 0 Then
		
		FirstElement = 0;
		Offset = UpdatedSKUsArray.Count() - 1;
		
		getSKUStocks103(Connection, UpdatedSKUsArray, SKUsArray, FirstElement, Offset, "Номенклатура_Key");
		
		For Each SKURow In SKUsArray Do
			
			NewRow = SKUsBalanceVT.Add();                    
			FillPropertyValues(NewRow, SKURow, "Номенклатура_Key, Склад_Key, КоличествоBalance");
			NewRow.КоличествоBalance = Number(SKURow.КоличествоBalance);
			
		EndDo;
		
	EndIf;
	
	SKUsArray  = New Array;
	//series items
	UpdatedSKUsArray = AllSeriesSKUs;	
	If UpdatedSKUsArray.Count() > 0 Then
		
		FirstElement = 0;
		Offset = UpdatedSKUsArray.Count() - 1;
		
		getSKUStocks103(Connection, UpdatedSKUsArray, SKUsArray, FirstElement, Offset, "СерияНоменклатуры_Key");
		
		For Each SKURow In SKUsArray Do
			
			NewRow = SKUsBalanceVT.Add();                    
			FillPropertyValues(NewRow, SKURow, "Номенклатура_Key, Склад_Key, СерияНоменклатуры_Key, КоличествоBalance");
			NewRow.КоличествоBalance = Number(SKURow.КоличествоBalance);
			
		EndDo;
		
	EndIf;
	
	
	SKUsBalanceVT.GroupBy("Номенклатура_Key, Склад_Key, СерияНоменклатуры_Key", "КоличествоBalance");
	ObjectArrays.Insert(SKUs103 + "VT", SKUsBalanceVT);
	
	
EndProcedure	

Procedure getSKUStocks103(Connection, UpdatedSKUsArray, SKUsArray, FirstElement, Offset, DimensionName)	                                 

	LastElement = ?(FirstElement + Offset > UpdatedSKUsArray.Count() - 1, UpdatedSKUsArray.Count() - 1, FirstElement + Offset);
	
	If Not (FirstElement >= UpdatedSKUsArray.Count()) Then
		
		FilterString = GetSKUsStockFilterString103(UpdatedSKUsArray, FirstElement, LastElement, DimensionName);
		
		Request = GetSKUsStocksRequest103(FilterString);
		Try
			Response = Connection.Get(Request);
			StatusCode = Response.StatusCode;
		Except
			StatusCode = 405;
		EndTry;

		
		If StatusCode = 200 Then
			
			Doc = GetXMLReaderFromString(Response.GetBodyAsString());
			ElementNodes = Doc.GetElementByTagName("element");
			
			For Each ElementNode In ElementNodes Do
			
				ObjectStructure = New Structure;
				ProcessElementNode(ElementNode, ObjectStructure);
				SKUsArray.Add(ObjectStructure);
				
			EndDo;
			
			FirstElement = FirstElement + Offset + 1;
			
			If Not Offset = 0 Then
				
				getSKUStocks103(Connection, UpdatedSKUsArray, SKUsArray, FirstElement, Offset, DimensionName);
				
			EndIf;
			
		Else
			
			Offset = Round(Offset / 2,0,RoundMode.Round15as10);
			getSKUStocks103(Connection, UpdatedSKUsArray, SKUsArray, FirstElement, Offset, DimensionName);
			
		EndIf;
		
	EndIf;
	
EndProcedure


Function GetSKUsStockFilterString103(UpdatedSKUsArray, FirstElement, Offset, DimensionName)
	                          	
	FilterString = "";
	StockFilter = "";
	for each stockGUID in StocksForRemains103 do
		StockFilter = StockFilter + "Склад_Key eq guid'" + stockGUID + "' or ";
	endDo;
	StockFilter = Left(StockFilter, StrLen(StockFilter) - 4);
	
	if ValueIsFilled(StockFilter) then
		FilterString = "( " + StockFilter + " ) and (";
	endIf;
	
	For Index = FirstElement To Offset Do
		
		FilterString = FilterString + DimensionName + " eq guid'" + UpdatedSKUsArray[Index] + "' or ";
		
	EndDo;
	
	FilterString = Left(FilterString, StrLen(FilterString) - 4);
	
	if ValueIsFilled(StockFilter) then
		FilterString = FilterString + ")";
	endIf;

	Return FilterString;
	
EndFunction

Function GetSKUsStocksRequest103(FilterString)
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/AccumulationRegister_ТоварыНаСкладах/Balance()?$filter=" + FilterString);
	
	Return Request;
	
EndFunction







#EndRegion

#Region Mappings

Function GetEmptyObjectArrays()
	
	ObjectArrays = New Map();
	
	If SourceConfiguration = SOURCE_CONFIG_UT11 Then
	
		ObjectArrays.Insert(SKUGroups, New Array);
		ObjectArrays.Insert(SKUs, New Array);
		ObjectArrays.Insert(Brands, New Array);
		ObjectArrays.Insert(Packs, New Array);
		ObjectArrays.Insert(Units, New Array);
		ObjectArrays.Insert(PriceLists, New Array);
		ObjectArrays.Insert(Stocks, New Array);
		ObjectArrays.Insert(Outlets, New Array);
		ObjectArrays.Insert(Partners, New Array);
		ObjectArrays.Insert(Agreements, New Array);
		ObjectArrays.Insert(UpdatedSKUStocks, GetEmptyUpdatedSKUStocks());
		ObjectArrays.Insert(Prices, New Array);
		ObjectArrays.Insert(UsersCat, New Array);
		ObjectArrays.Insert(Contacts, New Array);
		
	ElsIf SourceConfiguration = SOURCE_CONFIG_UT103 Then
		
		ObjectArrays.Insert(SKUGroups, New Array);
		ObjectArrays.Insert(SKUs, New Array);
		ObjectArrays.Insert(Units103, New Array);
		ObjectArrays.Insert(Series, New Array);
		//ObjectArrays.Insert(SKUsInStocks, New Array);
		ObjectArrays.Insert(Agreement, New Array);		
		ObjectArrays.Insert(Outlets, New Array);
		ObjectArrays.Insert(ContactInfo, New Array);
		ObjectArrays.Insert(Contacts103, New Array);
		ObjectArrays.Insert(UsersCat, New Array);
		ObjectArrays.Insert(PriceTypes, New Array);
		ObjectArrays.Insert(Prices, New Array);
		ObjectArrays.Insert(Stocks, New Array);
		
	EndIf;
	
	Return ObjectArrays;
	
EndFunction

Function GetEmptyUpdatedSKUStocks()
	
	UpdatedSKUStocksVT = New ValueTable;
	UpdatedSKUStocksVT.Columns.Add("SKU");
	
	Return UpdatedSKUStocksVT;
	
EndFunction

Function GetPropertyNamesMap()
	
	PropertyNamesMap = New Map;
	
	If SourceConfiguration = SOURCE_CONFIG_UT11 Then
		
		PropertyNamesMap.Insert("StandardODATA.Catalog_Номенклатура", GetSKUPropertyNames());
		PropertyNamesMap.Insert("StandardODATA.Catalog_ЕдиницыИзмерения", GetUnitPropertyNames());
		PropertyNamesMap.Insert("StandardODATA.Catalog_УпаковкиНоменклатуры", GetPackPropertyNames());
		PropertyNamesMap.Insert("StandardODATA.Catalog_Склады", GetStockPropertyNames());
		PropertyNamesMap.Insert("StandardODATA.Catalog_Марки", GetBrandPropertyNames());
		PropertyNamesMap.Insert(PriceLists, GetPriceListsPropertyNames());
		PropertyNamesMap.Insert(Outlets, GetOutletsPropertyNames());
		PropertyNamesMap.Insert(Partners, GetPartnersPropertyNames());
		PropertyNamesMap.Insert(Contacts, GetContactsPropertyNames());
		PropertyNamesMap.Insert("StandardODATA.AccumulationRegister_СвободныеОстатки", GetUpdatedSKUStocksPropertyNames());
		PropertyNamesMap.Insert(Prices, GetPricesPropertyNames());
		PropertyNamesMap.Insert(Agreements, GetAgreementsPropertyNames());
		PropertyNamesMap.Insert(UsersCat, GetUsersPropertyNames());
		
	ElsIf SourceConfiguration = SOURCE_CONFIG_UT103 Then
		
		PropertyNamesMap.Insert("StandardODATA.Catalog_Номенклатура", GetSKUPropertyNames());
		PropertyNamesMap.Insert(Units103, GetUnits103PropertyNames());
		PropertyNamesMap.Insert(Series, GetSeriesPropertyNames());
		PropertyNamesMap.Insert(Outlets, GetOutletsPropertyNames());
		PropertyNamesMap.Insert(ContactInfo, GetContactInfoPropertyNames());
		PropertyNamesMap.Insert(Contacts103, GetContacts103PropertyNames());
		PropertyNamesMap.Insert(UsersCat, GetUsersPropertyNames());
		PropertyNamesMap.Insert(PriceTypes, GetPriceTypesPropertyNames());
		PropertyNamesMap.Insert(Prices, GetPrices103PropertyNames());
		PropertyNamesMap.Insert(Stocks, GetStockPropertyNames());
		PropertyNamesMap.Insert(Agreement, GetAgreementPropertyNames());
		
		////PropertyNamesMap.Insert(SKUsInStocks, GetSKUsInStocks103());
		
	EndIf;
	
	Return PropertyNamesMap;
	
EndFunction

Function GetPrices103PropertyNames()
	
	Prices103PropertyNames = New Array;
	Prices103PropertyNames.Add("Period");
	Prices103PropertyNames.Add("ТипЦен_Key");
	Prices103PropertyNames.Add("Номенклатура_Key");
	Prices103PropertyNames.Add("Цена");
	
	Return Prices103PropertyNames;
	
EndFunction

Function GetPriceTypesPropertyNames()
	
	PriceTypesPropertyNamesMap = New Array;
	PriceTypesPropertyNamesMap.Add("Ref_Key");
	PriceTypesPropertyNamesMap.Add("Description");
	
	Return PriceTypesPropertyNamesMap;
	
EndFunction

Function GetContacts103PropertyNames()
	
	Contacts103PropertyNames = New Array;
	Contacts103PropertyNames.Add("Ref_Key");
	Contacts103PropertyNames.Add("Description");
	Contacts103PropertyNames.Add("Должность");
	
	Return Contacts103PropertyNames;
	
EndFunction

Function GetContactInfoPropertyNames()
	
	ContactInfoPropertyNamesMap = New Array;
	ContactInfoPropertyNamesMap.Add("Объект");
	ContactInfoPropertyNamesMap.Add("Объект_Type");
	ContactInfoPropertyNamesMap.Add("Вид");
	ContactInfoPropertyNamesMap.Add("Представление");
	
	Return ContactInfoPropertyNamesMap;
	
EndFunction

Function GetSeriesPropertyNames()
	
	SeriesPropertyNames = New Array;
	SeriesPropertyNames.Add("Ref_Key");
	SeriesPropertyNames.Add("Owner_Key");
	SeriesPropertyNames.Add("Description");
	
	Return SeriesPropertyNames;
	
EndFunction

Function GetUsersPropertyNames()
	
	UsersPropertyNames = New Array;
	
	If SourceConfiguration = 0 Then
		
		UsersPropertyNames.Add("Ref_Key");
		UsersPropertyNames.Add("Description");
		UsersPropertyNames.Add("КонтактнаяИнформация");
		
	Else
		
		UsersPropertyNames.Add("Ref_Key");
		UsersPropertyNames.Add("Description");
		
	EndIf;
	
	Return UsersPropertyNames;
	
EndFunction

Function GetAgreementsPropertyNames()
	
	AgreementsPropertyNames = New Array;
	AgreementsPropertyNames.Add("Ref_Key");
	AgreementsPropertyNames.Add("ВидЦен_Key");
	AgreementsPropertyNames.Add("Контрагент_Key");
	
	Return AgreementsPropertyNames;
	
EndFunction

Function GetOutletsPropertyNames()
	
	OutletsPropertyNames = New Array;
	
	If SourceConfiguration = 0 Then
		
		OutletsPropertyNames.Add("Ref_Key");
		OutletsPropertyNames.Add("Description");
		OutletsPropertyNames.Add("КонтактнаяИнформация");
		OutletsPropertyNames.Add("НаименованиеПолное");
		OutletsPropertyNames.Add("ИНН");
		OutletsPropertyNames.Add("КПП");
		OutletsPropertyNames.Add("ЮридическоеФизическоеЛицо");
		OutletsPropertyNames.Add("Партнер_Key");
		
	ElsIf SourceConfiguration = 1 Then
		
		OutletsPropertyNames.Add("Ref_Key");
		OutletsPropertyNames.Add("Description");
		OutletsPropertyNames.Add("НаименованиеПолное");
		OutletsPropertyNames.Add("ИНН");
		OutletsPropertyNames.Add("КПП");
		OutletsPropertyNames.Add("ЮрФизЛицо");
		OutletsPropertyNames.Add("ОсновноеКонтактноеЛицо_Key");
		OutletsPropertyNames.Add("МенеджерыПокупателя");
		
	EndIf;
	
	Return OutletsPropertyNames;
	
EndFunction

Function GetPartnersPropertyNames()
	
	PartnersPropertyNames = New Array;
	PartnersPropertyNames.Add("Ref_Key");
	PartnersPropertyNames.Add("Description");
	PartnersPropertyNames.Add("ОсновнойМенеджер_Key");
	PartnersPropertyNames.Add("КонтактнаяИнформация");
	Return PartnersPropertyNames;
	
EndFunction

Function GetContactsPropertyNames()
	
	ContactsPropertyNames = New Array;
	ContactsPropertyNames.Add("Ref_Key");
	ContactsPropertyNames.Add("Description");
	ContactsPropertyNames.Add("Owner_Key");
	ContactsPropertyNames.Add("КонтактнаяИнформация");
	ContactsPropertyNames.Add("ДолжностьПоВизитке");
	Return ContactsPropertyNames;
	
EndFunction

Function GetPricesPropertyNames()
	
	PricesPropertyNames = New Array;
	PricesPropertyNames.Add("Ref_Key");
	PricesPropertyNames.Add("Номенклатура_Key");
	PricesPropertyNames.Add("ВидЦены_Key");
	PricesPropertyNames.Add("Цена");
	PricesPropertyNames.Add("Упаковка_Key");
	
	Return PricesPropertyNames;
	
EndFunction

Function GetPriceListsPropertyNames()
	
	PriceListsPropertyNames = New Array;
	PriceListsPropertyNames.Add("Ref_Key");
	PriceListsPropertyNames.Add("Description");
	
	Return PriceListsPropertyNames;
	
EndFunction

Function GetStockPropertyNames()
	
	StocksPropertyNames = New Array;
	StocksPropertyNames.Add("Ref_Key");
	StocksPropertyNames.Add("Description");
	StocksPropertyNames.Add("IsFolder");
	
	Return StocksPropertyNames;
	
EndFunction
Function GetAgreementPropertyNames()
	
	AgreementPropertyNames = New Array;
	AgreementPropertyNames.Add("Ref_Key");
	AgreementPropertyNames.Add("Owner_Key");
	AgreementPropertyNames.Add("ТипЦен");
	
	Return AgreementPropertyNames;

	
EndFunction

Function GetUnitPropertyNames()
	
	UnitsPropertyNames = New Array;
	UnitsPropertyNames.Add("Ref_Key");
	UnitsPropertyNames.Add("Description");
	UnitsPropertyNames.Add("НаименованиеПолное");
	
	Return UnitsPropertyNames;
	
EndFunction

Function GetUnits103PropertyNames()
	
	UnitsPropertyNames = New Array;
	UnitsPropertyNames.Add("Ref_Key");
	UnitsPropertyNames.Add("Description");
	UnitsPropertyNames.Add("Owner");
	UnitsPropertyNames.Add("Коэффициент");
	UnitsPropertyNames.Add("НаименованиеПолное");
	
	
	Return UnitsPropertyNames;
	
EndFunction

Function GetPackPropertyNames()
	
	PackPropertyNames = New Array;
	PackPropertyNames.Add("Ref_Key");
	PackPropertyNames.Add("Description");
	PackPropertyNames.Add("Owner");
	PackPropertyNames.Add("Коэффициент");
	
	Return PackPropertyNames;
	
EndFunction

Function GetSKUPropertyNames()
	
	SKUPropertyNames = New Array;
	
	If SourceConfiguration = 0 Then
	
		SKUPropertyNames.Add("Ref_Key");
		SKUPropertyNames.Add("Description");
		SKUPropertyNames.Add("IsFolder");
		SKUPropertyNames.Add("Parent_Key");
		SKUPropertyNames.Add("Марка_Key");
		SKUPropertyNames.Add("НаборУпаковок_Key");
		SKUPropertyNames.Add("ЕдиницаИзмерения_Key");
		
	ElsIf SourceConfiguration = 1 Then
		
		SKUPropertyNames.Add("Ref_Key");
		SKUPropertyNames.Add("Description");
		SKUPropertyNames.Add("IsFolder");
		SKUPropertyNames.Add("Parent_Key");
		SKUPropertyNames.Add("БазоваяЕдиницаИзмерения_Key");
		SKUPropertyNames.Add("ВестиУчетПоСериям");
		
	EndIf;
		
	Return SKUPropertyNames;
	
EndFunction

Function GetBrandPropertyNames()
	
	BrandPropertyNames = New Array;
	BrandPropertyNames.Add("Ref_Key");
	BrandPropertyNames.Add("Description");
	
	Return BrandPropertyNames;
	
EndFunction

Function GetUpdatedSKUStocksPropertyNames()
	
	UpdatedSKUStockNames = New Array;
	UpdatedSKUStockNames.Add("Номенклатура_Key");
	
	Return UpdatedSKUStockNames;
	
EndFunction

#EndRegion

#Region WriteObjects

Procedure WriteBrand(Brand)
	
	BrandObject = GetCatalogObject("Brands", Brand.Ref_Key);
	
	BrandObject.Description = Brand.Description;
	
	If Not BrandObject.Ref.Description = Brand.Description Then
		
		BrandObject.Write();
		
	EndIf;
	
EndProcedure

Procedure WritePack(Pack)
	
	PackRef = Catalogs.UnitsOfMeasure.FindByDescription(Pack.Description);
	
	If PackRef = Catalogs.UnitsOfMeasure.EmptyRef() Then
		
		PackObject = Catalogs.UnitsOfMeasure.CreateItem();
		
	Else
		
		PackObject = PackRef.GetObject();
		
		Query = New Query(
		"SELECT
		|	SKUPacking.Ref
		|FROM
		|	Catalog.SKU.Packing AS SKUPacking
		|WHERE
		|	SKUPacking.Pack = &Pack");
		Query.SetParameter("Pack", PackRef);
		Result = Query.Execute().Unload();
		
		For Each SKURow In Result Do
			
			SKUObject = SKURow.Ref.GetObject();
			FoundRow = SKUObject.Packing.Find(PackObject.Ref);
			FoundRow.Multiplier = Pack.Коэффициент;
			
			If Not Pack.Коэффициент = FoundRow.Multiplier Then
				
				SKUObject.Write();
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	PackObject.Description = Pack.Description;
	PackObject.FullDescription = Pack.Description;
	
	If Not Pack.Description = PackObject.Ref.Description Then
		
		PackObject.Write();
		
	EndIf;
	
EndProcedure

Procedure WriteStocks(Stock)
	
	StockObject = GetCatalogObject("Stock", Stock.Ref_Key);
	
	StockObject.Description = Stock.Description;
	
	IsNew = StockObject.IsNew();
	
	If Not Stock.Description = StockObject.Ref.Description Then
		
		StockObject.Write();
		
	EndIf;
	
	If IsNew Then
		
		Territory = Catalogs.Territory.Select();
		
		While Territory.Next() Do
			
			TerritoryObj = Territory.GetObject();
			NewStockRow = TerritoryObj.Stocks.Add();
			NewStockRow.Stock = StockObject.Ref;
			TerritoryObj.Write();
			
		EndDo;
		
				
	EndIf;
	
EndProcedure

Procedure WriteUnit(Unit)
	
	UnitObject = GetCatalogObject("UnitsOfMeasure", Unit.Ref_Key);
	
	UnitObject.Description = Unit.Description;
	UnitObject.FullDescription = Unit.НаименованиеПолное;
	
	If Not Unit.Description = UnitObject.Ref.Description Then
		
		UnitObject.Write();
		
	EndIf;
	
EndProcedure

Procedure WriteSKUGroups(SKUGroupsTree)
	
	For Each Row In SKUGroupsTree.Rows Do
		
		ProcessSKUGroupsTree(Row);
		
	EndDo;
	
EndProcedure

Procedure ProcessSKUGroupsTree(SKUGroupsTreeRow, Parent = False)
	
	предВремя = CurrentDate();
	 					
	SKUGroupRef = Catalogs.SKUGroup.GetRef(New UUID(SKUGroupsTreeRow.Ref_Key));
	SKUGroupObject = SKUGroupRef.GetObject();
	
	If SKUGroupObject = Undefined Then
		
		If SKUGroupsTreeRow.Rows.Count() = 0 Then
			
			SKUGroupObject = Catalogs.SKUGroup.CreateItem();
			
		Else
			
			SKUGroupObject = Catalogs.SKUGroup.CreateFolder();
			
		EndIf;
		
		SKUGroupObject.SetNewObjectRef(SKUGroupRef);
		
	EndIf;
	Parent = (SKUGroupsTreeRow.Parent_Key <> EmptyRefString );
	
	SKUGroupObject.Description = SKUGroupsTreeRow.Description;
	NewParent = ?(Parent, Catalogs.SKUGroup.GetRef(New UUID(SKUGroupsTreeRow.Parent_Key)), Catalogs.SKUGroup.EmptyRef());
	SKUGroupObject.Parent = NewParent;
	
	IsNew = SKUGroupObject.IsNew();
	
	If IsNew And Not SKUGroupObject.IsFolder Then
		
		TerritoriesSelection = Catalogs.Territory.Select();
		
		While TerritoriesSelection.Next() Do
			
			NewTerritoryRow = SKUGroupObject.Territories.Add();
			NewTerritoryRow.Territory = TerritoriesSelection.Ref;
			
		EndDo;
		
	EndIf;
	
	If Not (SKUGroupObject.Ref.Description = SKUGroupsTreeRow.Description 
		And SKUGroupObject.Ref.Parent = NewParent) Then
		If SKUGroupObject.Parent <> Catalogs.SKUGroup.EmptyRef() Then
			ParentObj = SKUGroupObject.Parent.GetObject();		 		
				If SKUGroupObject.Parent.IsFolder = False And Not ParentObj.IsNew() Then  
					Message(NStr("ru ='Группа номенклатуры "+SKUGroupObject.Description+" не может быть получена';en = 'Sku group "+SKUGroupObject.Description+" cant be get'"));	
				Else 			
					SKUGroupObject.Write();
				EndIf;
		Else 
			SKUGroupObject.Write();			
		EndIf;
		
	EndIf;
	
	
	For Each Row In SKUGroupsTreeRow.Rows Do
		ProcessSKUGroupsTree(Row, True);	
	EndDo;
	
EndProcedure

Procedure WriteSKU(SKUObjectStructure, SKUGroupsTree, PacksMap)
	
	SKUGroupsRows = SKUGroupsTree.Rows.FindRows(New Structure("Ref_Key", SKUObjectStructure.Parent_Key));
	
	SKUGroupRef = Catalogs.SKUGroup.GetRef(New UUID(SKUObjectStructure.Parent_Key));
	SKUGroupObject = SKUGroupRef.GetObject();
	
	If Not SKUGroupObject = Undefined And Not SKUGroupObject.IsFolder Then
		
		NeedsWrite = False;
		
		SKUObject = GetCatalogObject("SKU", SKUObjectStructure.Ref_Key);
		
		SKUObject.Description = SKUObjectStructure.Description;
		SKUObject.Owner = SKUGroupRef;
		
		BrandRef = Catalogs.Brands.GetRef(New UUID(SKUObjectStructure.Марка_Key));
		NewBrand = ?(BrandRef = Catalogs.Brands.EmptyRef(), Catalogs.Brands.DefaultBrand, BrandRef);
		SKUObject.Brand = NewBrand;
		
		UnitRef = GetUnitRef(SKUObjectStructure.ЕдиницаИзмерения_Key);
		
		SKUObject.BaseUnit = UnitRef;
		
		FoundPacks = PacksMap.Get(SKUObjectStructure.НаборУпаковок_Key);
		
		If not ValueIsFilled(SKUObject.Brand) then
			SKUObject.Brand = Catalogs.Brands.DefaultBrand;
		EndIf;
		
		If Not FoundPacks = Undefined Then
		
			For Each Pack In FoundPacks Do
				
				NewRow = SKUObject.Packing.Add();
				NewRow.Pack = Pack.Pack_Ref;
				
				If Not NewRow.Multiplier = Pack.Коэффициент Then
					
					NewRow.Multiplier = Pack.Коэффициент;
					NeedsWrite = True;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Not (SKUObject.Ref.Description = SKUObjectStructure.Description
			And  SKUObject.Ref.Owner = SKUGroupRef
			And SKUObject.Ref.BaseUnit= UnitRef
			And SKUObject.Ref.Brand = NewBrand
			And Not NeedsWrite) Then
			
				SKUObject.Packing.Sort("Multiplier");
				SKUObject.Write();
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure WriteSKUStocks(ChangedSKUStock, SKUStocksVT)
	
	SKURef = Catalogs.SKU.GetRef(New UUID(ChangedSKUStock));
	SKUObject = SKURef.GetObject();
	
	If Not SKUObject = Undefined Then
		
		NeedsWrite = False;
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Номенклатура_Key", String(ChangedSKUStock));
		
		FoundSKURows = SKUStocksVT.FindRows(FilterParameters);
		
		For Each StockRow In SKUObject.Stocks Do
			
			FilterParameters.Insert("Склад_Key", String(StockRow.Stock.UUID()));
			
			FoundSKUStockRows = SKUStocksVT.FindRows(FilterParameters);
			
			If FoundSKUStockRows.Count() = 0 Then
				
				If Not StockRow.StockValue = 0 Then
					
					StockRow.StockValue = 0;
					NeedsWrite = True;
					
				EndIf;
				
			Else
				
				For Each FoundRow In FoundSKUStockRows Do
					
					If Not StockRow.StockValue = FoundRow.ВНаличииBalance Then
						
						StockRow.StockValue = FoundRow.ВНаличииBalance;
						NeedsWrite = True;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
		For Each FoundSKURow In FoundSKURows Do
			
			StockRef = Catalogs.Stock.GetRef(New UUID(FoundSKURow.Склад_Key));
			StockObject = StockRef.GetObject();
			
			If Not StockObject = Undefined Then
				
				If SKUObject.Stocks.Find(StockRef) = Undefined Then
					
					NewStockRow = SKUObject.Stocks.Add();
					NewStockRow.Stock = StockRef;
					NewStockRow.StockValue = FoundSKURow.ВНаличииBalance;
					NeedsWrite = True;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If NeedsWrite Then
			
			SKUObject.Stocks.Sort("StockValue Desc", );
			SKUObject.Write();
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure WritePrices(ObjectArrays)
	
	PricesVT = New ValueTable;
	PricesVT.Columns.Add("Period");
	PricesVT.Columns.Add("ВидЦены_Key");
	PricesVT.Columns.Add("Номенклатура_Key");
	PricesVT.Columns.Add("Цена");
	PricesVT.Columns.Add("Упаковка_Key");
	
	For Each PriceStructure In ObjectArrays.Get(Prices) Do
		
		NewRow = PricesVT.Add();
		FillPropertyValues(NewRow, PriceStructure, , "Цена");
		NewRow.Цена = Number(PriceStructure.Цена);
		
	EndDo;
	
	PricesVT.Sort("ВидЦены_Key, Номенклатура_Key Возр, Period Возр");
	
	For Each Price In PricesVT Do
		
		PriceListRef = Documents.PriceList.GetRef(New UUID(Price.ВидЦены_Key));
		
		SKURef = Catalogs.SKU.GetRef(New UUID(Price.Номенклатура_Key));
		PackRef = Catalogs.UnitsOfMeasure.GetRef(New UUID(Price.Упаковка_Key));
		PackingRow = SKURef.Packing.Find(PackRef);
		Factor = ?(PackingRow = Undefined, 1, PackingRow.Multiplier);
		
		Try
			
			SKUObject = SKURef.GetObject();
			
		Except
			
			SKUObject = Undefined;
			
		EndTry;
		
		If Not SKUObject = Undefined Then
			
			RecordManager = InformationRegisters.Prices.CreateRecordManager();
			RecordManager.Period = PriceListRef.Date;
			RecordManager.PriceList = PriceListRef;
			RecordManager.SKU = SKURef;
			RecordManager.Price = Price.Цена / Factor;
			
			Query = New Query(
			"SELECT
			|	Prices.Price
			|FROM
			|	InformationRegister.Prices AS Prices
			|WHERE
			|	Prices.PriceList = &PriceList
			|	AND Prices.SKU = &SKU");
			Query.SetParameter("PriceList", PriceListRef);
			Query.SetParameter("SKU", SKURef);
			Result = Query.Execute().Unload();
			
			IsNewPrice = Result.Count() = 0;
			
			If IsNewPrice Then
				
				RecordManager.Write();
				
			Else
				
				If Not Result[0].Price = RecordManager.Price Then
					
					RecordManager.Write();
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WriteOutlets(ObjectArrays, TerritoryObject)
	
	ManagersAsTerritories = ObjectArrays.Get("ManagersAsTerritories");
	
	ClassSelection = Catalogs.OutletClass.Select();
	
	If ClassSelection.Next() Then
		
		ClassRef = Constants.OutletCalssDef.Get();//ClassSelection.Ref;
		
	EndIf;
	
	TypeSelection = Catalogs.OutletType.Select();
	
	If TypeSelection.Next() Then
		
		TypeRef = Constants.OutletTypeDef.Get();//TypeSelection.Ref;
		
	EndIf;
	
	RegionSelection = Catalogs.Region.Select();
	
	If RegionSelection.Next() Then
		
		RegionRef = RegionSelection.Ref;
		
	EndIf;
	
	For Each PartnerStructure In ObjectArrays.Get(Partners) Do
		
		TerritoryRef = TerritoryObject.Ref;
		
		PartnerObject = GetCommonRefCatalogObject("Distributor", PartnerStructure.Ref_Key);
		PartnerObject.Description = PartnerStructure.Description;
		
		If PartnerObject.IsNew() Then
			
			If ManagersAsTerritories Then
				
				If Not PartnerStructure.ОсновнойМенеджер_Key = EmptyRefString Then
					
					//ManagerTerritoryRef = Catalogs.Territory.GetRef(New UUID(PartnerStructure.ОсновнойМенеджер_Key));
					
					ManagerTerritoryRef = Catalogs.Territory.FindByAttribute("ExternalId", PartnerStructure.ОсновнойМенеджер_Key);
					
					Try
						
						TerritoryObj = ManagerTerritoryRef.GetObject();
						
						If Not TerritoryObj = Undefined Then
							
							TerritoryRef = ManagerTerritoryRef;
							
						EndIf;
						
					Except
						
						TerritoryRef = TerritoryObject.Ref;
						
					EndTry;
					
				EndIf;
				
			EndIf;
			
			NewTerritoryRow = PartnerObject.Territories.Add();
			NewTerritoryRow.Territory = TerritoryRef;
			
			NewRegionRow = PartnerObject.Regions.Add();
			NewRegionRow.Region = TerritoryRef.Owner;
			
		EndIf;
		
		ContactsUnchanged = True;
		
		If PartnerStructure.Property("Телефон") Or PartnerStructure.Property("АдресЭлектроннойПочты") Then
			
			PartnerContactObject = GetCommonRefCatalogObject("ContactPersons", PartnerStructure.Ref_Key);
			PartnerContactObject.Description = PartnerStructure.Description;
			PartnerContactObject.PhoneNumber = ?(PartnerStructure.Property("Телефон"), PartnerStructure.Телефон, "");
			PartnerContactObject.Email = ?(PartnerStructure.Property("АдресЭлектроннойПочты"), PartnerStructure.АдресЭлектроннойПочты, "");
			
			PhoneNumberUnchanged = True;
			EmailUnchanged = True;
			
			If PartnerStructure.Property("Телефон") Then
				
				PhoneNumberUnchanged = PartnerContactObject.Ref.PhoneNumber = PartnerStructure.Телефон;
				
			EndIf;
			
			If PartnerStructure.Property("АдресЭлектроннойПочты") Then
				
				EmailUnchanged = PartnerContactObject.Ref.Email = PartnerStructure.АдресЭлектроннойПочты;
				
			EndIf;
			
			ContactsUnchanged = PhoneNumberUnchanged And EmailUnchanged;
			
			If Not (PartnerContactObject.Ref.Description = PartnerStructure.Description And ContactsUnchanged) Then
				
				PartnerContactObject.Write();
				
			EndIf;
			
			ContactsUnchanged = ContactsUnchanged And True;
			
			If PartnerObject.Contacts.Find(PartnerContactObject.Ref) = Undefined Then
				
				NewContactRow = PartnerObject.Contacts.Add();
				NewContactRow.Contact = PartnerContactObject.Ref;
				ContactsUnchanged = False;
				
			EndIf;
			
		EndIf;
		
		If Not (PartnerObject.Ref.Description = PartnerStructure.Description And ContactsUnchanged) Then
			
			PartnerObject.Write();
			
		EndIf;
		
	EndDo;

	For Each OutletStructure In ObjectArrays.Get(Outlets) Do
		
		//PartnerRef = Catalogs.Distributor.GetRef(New UUID(OutletStructure.Партнер_Key));
		//PartnerObject = PartnerRef.GetObject();
		
		PartnerRef = Catalogs.Distributor.FindByAttribute("ExternalId", OutletStructure.Партнер_Key);
		
		//If Not PartnerObject = Undefined Then
		
		If Not PartnerRef.IsEmpty() Then
			
			PartnerObject = PartnerRef.GetObject();
		
			If Not OutletStructure.КонтактнаяИнформация = "" Then
				
				ContractorObject = GetCommonRefCatalogObject("Contractors", OutletStructure.Ref_Key);
				ContractorObject.Description = OutletStructure.Description;
				ContractorObject.LegalName = OutletStructure.НаименованиеПолное;
				ContractorObject.INN = OutletStructure.ИНН;
				ContractorObject.KPP = OutletStructure.КПП;
				//////////
				If OutletStructure.Property("АдресЭлектроннойПочты") Then
					ContractorObject.Email = OutletStructure.АдресЭлектроннойПочты;
				EndIf;
				If OutletStructure.Property("Телефон") Then 
					ContractorObject.PhoneNumber = OutletStructure.Телефон;
				EndIf;	
				//////////
				NewOwnerShipType = ?(OutletStructure.ЮридическоеФизическоеЛицо = "ЮридическоеЛицо", Enums.OwnershipType.OOO, Enums.OwnershipType.IP);
				ContractorObject.OwnershipType = NewOwnerShipType;
				
				NeedsWrite = False;
				
				If ContractorObject.IsNew() Then
					
					For Each Region In PartnerObject.Regions.UnloadColumn("Region") Do
						
						RegionRow = ContractorObject.Regions.Add();
						RegionRow.Region = Region;
						
					EndDo;
					
					For Each Territory In PartnerObject.Territories.UnloadColumn("Territory") Do
						
						TerritoryRow = ContractorObject.Territories.Add();
						TerritoryRow.Territory = Territory;
						
					EndDo;
					
				EndIf;
				
				If Not (ContractorObject.Ref.Description = OutletStructure.Description
					And ContractorObject.Ref.LegalName = OutletStructure.НаименованиеПолное
					And ContractorObject.Ref.INN = OutletStructure.ИНН
					And ContractorObject.Ref.KPP = OutletStructure.КПП
					And ContractorObject.Ref.OwnershipType = NewOwnershipType
					//////////
					And ContractorObject.Ref.Email = OutletStructure.АдресЭлектроннойПочты
					And ContractorObject.Ref.PhoneNumber = OutletStructure.Телефон
					//////////
					And Not NeedsWrite) Then
					
					ContractorObject.Write();
					
					PartnerContractors = PartnerObject.Contractors.UnloadColumn("Contractor");
					
					If PartnerContractors.Find(ContractorObject.Ref) = Undefined Then
						
						NewContractorRow = PartnerObject.Contractors.Add();
						NewContractorRow.Contractor = ContractorObject.Ref;
						NewContractorRow.Default = PartnerObject.Contractors.Count() = 1;
						
						PartnerObject.Write();
						
					EndIf;
					
				EndIf;
				
				OutletObject = GetCommonRefCatalogObject("Outlet", OutletStructure.Ref_Key);
				OutletObject.Description = OutletStructure.Description;
				
				If OutletObject.Ref.Class = Catalogs.OutletClass.EmptyRef() Then
					
					OutletObject.Class = ClassRef;
					
				EndIf;
				
				If OutletObject.Ref.Type = Catalogs.OutletType.EmptyRef() Then
					
					OutletObject.Type = TypeRef;
					
				EndIf;
				
				If OutletObject.Ref.OutletStatus = Enums.OutletStatus.EmptyRef() Then
					
					OutletObject.OutletStatus = Enums.OutletStatus.Active;
					
				EndIf;
				
				OutletObject.Address = OutletStructure.КонтактнаяИнформация;
				
				OutletObject.Distributor = PartnerObject.Ref;
				
				IsNew = OutletObject.IsNew();
				
				ContactsUnchanged = True;
				
				If OutletStructure.Property("Телефон") Or OutletStructure.Property("АдресЭлектроннойПочты") Then
					
					OutletContactObject = GetCommonRefCatalogObject("ContactPersons", OutletStructure.Ref_Key);
					OutletContactObject.Description = OutletStructure.Description;
					OutletContactObject.PhoneNumber = ?(OutletStructure.Property("Телефон"), OutletStructure.Телефон, "");
					OutletContactObject.Email = ?(OutletStructure.Property("АдресЭлектроннойПочты"), OutletStructure.АдресЭлектроннойПочты, "");
					
					PhoneNumberUnchanged = True;
					EmailUnchanged = True;
					
					If OutletStructure.Property("Телефон") Then
						
						PhoneNumberUnchanged = OutletContactObject.Ref.PhoneNumber = OutletStructure.Телефон;
						
					EndIf;
					
					If OutletStructure.Property("АдресЭлектроннойПочты") Then
						
						EmailUnchanged = OutletContactObject.Ref.Email = OutletStructure.АдресЭлектроннойПочты;
						
					EndIf;
					
					ContactsUnchanged = PhoneNumberUnchanged And EmailUnchanged;
					
					If Not (OutletContactObject.Ref.Description = OutletStructure.Description And ContactsUnchanged) Then
						
						OutletContactObject.Write();
						
					EndIf;
					
					ContactsUnchanged = ContactsUnchanged And True;
					
					If OutletObject.ContactPersons.Find(OutletContactObject.Ref) = Undefined Then
						
						ContactRow = OutletObject.ContactPersons.Add();
						ContactRow.ContactPerson = OutletContactObject.Ref;
						ContactsUnchanged = False;
						
					EndIf;
					
				EndIf;
				
				If Not (OutletObject.Ref.Description = OutletStructure.Description
					And OutletObject.Ref.Address = OutletStructure.КонтактнаяИнформация
					And ContactsUnchanged) Then
					
					OutletObject.Write();
					
				EndIf;
				
				If IsNew Then
				
					For Each Territory In PartnerObject.Territories.UnloadColumn("Territory") Do
						
						TerritoryObj = Territory.GetObject();
						NewOutletRow = TerritoryObj.Outlets.Add();
						NewOutletRow.Outlet = OutletObject.Ref;
						TerritoryObj.Write();
						
					EndDo;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WriteContacts(ObjectArrays)
	
	For Each ContactStructure In ObjectArrays.Get(Contacts) Do
		
		ContactObject = GetCatalogObject("ContactPersons", New UUID(ContactStructure.Ref_Key));
		
		ContactObject.Description = ContactStructure.Description;
		ContactObject.Position = ContactStructure.ДолжностьПоВизитке;
		ContactObject.PhoneNumber = ?(ContactStructure.Property("Телефон"), ContactStructure.Телефон, "");
		ContactObject.Email = ?(ContactStructure.Property("АдресЭлектроннойПочты"), ContactStructure.АдресЭлектроннойПочты, "");
		
		PhoneNumberUnchanged = True;
		EmailUnchanged = True;
		
		If ContactStructure.Property("Телефон") Then
			
			PhoneNumberUnchanged = ContactObject.Ref.PhoneNumber = ContactStructure.Телефон;
			
		EndIf;
		
		If ContactStructure.Property("АдресЭлектроннойПочты") Then
			
			EmailUnchanged = ContactObject.Ref.Email = ContactStructure.АдресЭлектроннойПочты;
			
		EndIf;
		
		ContactsUnchanged = PhoneNumberUnchanged And EmailUnchanged;
		
		If Not (ContactObject.Ref.Description = ContactStructure.Description 
			And ContactObject.Ref.Position = ContactStructure.ДолжностьПоВизитке
			And ContactsUnchanged) Then
			
			ContactObject.Write();
			
		EndIf;
		
		//PartnerRef = Catalogs.Distributor.GetRef(New UUID(ContactStructure.Owner_Key));
		//PartnerObj = PartnerRef.GetObject();
		
		PartnerRef = Catalogs.Distributor.FindByAttribute("ExternalId", ContactStructure.Owner_Key);
		
		//If Not PartnerObj = Undefined Then
		
		If Not PartnerRef.IsEmpty() Then
			
			PartnerObj = PartnerRef.GetObject();
			
			If PartnerObj.Contacts.Find(ContactObject.Ref) = Undefined Then
				
				NewContactRow = PartnerObj.Contacts.Add();
				NewContactRow.Contact = ContactObject.Ref;
				PartnerObj.Write();
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WriteUsers(ObjectArrays)
	
	UsersObjectsArray = ObjectArrays.Get(UsersCat);
	
	RegionSelection = Catalogs.Region.Select();
	
	If RegionSelection.Next() Then
		
		RegionRef = RegionSelection.Ref;
		
	EndIf;
	
	For Each UserStructure In UsersObjectsArray Do
		
		UserObj = GetCommonRefCatalogObject("User", UserStructure.Ref_Key);
		
		UserObj.Description = UserStructure.Description;
		
		If UserObj.RoleOfUser = Catalogs.RolesOfUsers.EmptyRef() Then
			
			UserObj.RoleOfUser = Catalogs.RolesOfUsers.SR;
			
		EndIf;
		
		If Not ValueIsFilled(UserObj.Role) Then
			
			UserObj.Role = "SR";
			
		EndIf;
		
		If Not ValueIsFilled(UserObj.InterfaceLanguage) Then
			
			UserObj.InterfaceLanguage = "Русский";
			
		EndIf;
		
		SendCredentials = False;
		
		If Not ValueIsFilled(UserObj.Username) Then
			
			UsernameExists = True;
			
			While UsernameExists Do
				
				GeneratedUsername = UsersCallServer.GenerateRandomUsername();
				UserSelect = Catalogs.User.Select(Undefined ,Undefined , New Structure("UserName", GeneratedUserName));
				UsernameExists = UserSelect.Next();
				
			EndDo;
			
			UserObj.Username = GeneratedUsername;
			SendCredentials = True;
			
		EndIf;
		
		If Not ValueIsFilled(UserObj.Password) Then
						
			UserObj.Password = UsersCallServer.GenerateRandomPassword();
			
		EndIf;
		
		If SourceConfiguration = 0 Then
		
			If UserStructure.Property("Email") And Not TrimAll(UserStructure.Email) = "" Then
				
				UserObj.EMail = UserStructure.Email;
				
			EndIf;
			
		EndIf;
		
		If SourceConfiguration = SOURCE_CONFIG_UT11 Then
		
			If Not UserObj.Ref.Description = UserStructure.Description 
				Or Not UserObj.Ref.Email = UserStructure.Email Then
				
				UserObj.Write();
				
				If ValueIsFilled(TrimAll(UserObj.EMail)) And SendCredentials Then
					
					Try
						
						UserObj.SendMessage();
						
					Except
						
						
					EndTry;
					
				EndIf;
				
			EndIf;
			
		ElsIf SourceConfiguration = SOURCE_CONFIG_UT103 Then
			
			If Not UserObj.Ref.Description = UserStructure.Description Then
				
				UserObj.Write();
				
				If ValueIsFilled(TrimAll(UserObj.EMail)) And SendCredentials Then
					
					Try
						
						UserObj.SendMessage();
						
					Except
						
						
					EndTry;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If SourceConfiguration = SOURCE_CONFIG_UT11 Then

			
			If ObjectArrays.Get("ManagersAsTerritories") Then
				
				TerritoryObject = GetCommonRefCatalogObject("Territory", UserStructure.Ref_Key);
				TerritoryObject.Description = UserStructure.Description;
				
				If TerritoryObject.IsNew() Then
					
					TerritoryObject.Owner = RegionRef;
					
					Stock = Catalogs.Stock.Select();
					
					While Stock.Next() Do
						
						NewStockRow = TerritoryObject.Stocks.Add();
						NewStockRow.Stock = Stock.Ref;
						
					EndDo;
					
				EndIf;
				
				If TerritoryObject.SRs.Find(UserObj.Ref) = Undefined Then
					
					NewUserRow = TerritoryObject.SRs.Add();
					NewUserRow.SR = UserObj.Ref;
					
				EndIf;
				
				If Not TerritoryObject.Description = TerritoryObject.Ref.Description Then
					
					TerritoryObject.Write();
					
				EndIf;
				
			Else
				
				TerritoryObject = Catalogs.Territory.FindByDescription("Основная территория").GetObject();
				
				If TerritoryObject.SRs.Find(UserObj.Ref) = Undefined Then
					
					NewUserRow = TerritoryObject.SRs.Add();
					NewUserRow.SR = UserObj.Ref;
					TerritoryObject.Write();
					
				EndIf;
				
			EndIf;
			
		ElsIf SourceConfiguration = SOURCE_CONFIG_UT103 Then
			
			TerritoryObject = GetCommonRefCatalogObject("Territory", UserStructure.Ref_Key);
			TerritoryObject.Description = UserStructure.Description;
			
			If TerritoryObject.IsNew() Then
				
				TerritoryObject.Owner = RegionRef;
				
				Stock = Catalogs.Stock.Select();
				
				While Stock.Next() Do
					
					NewStockRow = TerritoryObject.Stocks.Add();
					NewStockRow.Stock = Stock.Ref;
					
				EndDo;
				
			EndIf;
			
			NeedsWrite = False;
			
			If TerritoryObject.SRs.Find(UserObj.Ref) = Undefined Then
				
				NewUserRow = TerritoryObject.SRs.Add();
				NewUserRow.SR = UserObj.Ref;
				NeedsWrite = True;
				
			EndIf;
			
			If Not (TerritoryObject.Description = TerritoryObject.Ref.Description) And NeedsWrite Then
				
				TerritoryObject.Write();
				
			EndIf;
			
		EndIf;
		
	EndDo;

EndProcedure

Procedure WritePriceListsToOutlets103(ObjectArrays)
	
	NewArgiments = ObjectArrays.Get(Agreement);
	For Each NewArgiment In NewArgiments Do
		OutletForChange = Catalogs.Outlet.FindByAttribute("ExternalId",NewArgiment.Owner_Key);
		If OutletForChange <> Catalogs.Outlet.EmptyRef() Then
			If NewArgiment.ТипЦен<>"" Then
				PriceInOutlet = Documents.PriceList.GetRef(New UUID(NewArgiment.ТипЦен));
				If PriceInOutlet.Number <> "" Then 
					OutletObject = OutletForChange.GetObject();
					FindElemInOutl = OutletObject.Prices.FindRows(New Structure("PriceList",PriceInOutlet));
					If FindElemInOutl.Count() = 0 Then
						NewPriceList = OutletObject.Prices.Add();			
						NewPriceList.PriceList = PriceInOutlet
					EndIf;	
					OutletObject.Write();
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure WritePriceListsToOutlets(ObjectArrays)
	
	Var AgreementElement, AgreementRow, AgreementsArray, AgreementsValueTable, NewPriceListRow, OutletObj, OutletRef, PriceList, PriceListRef, PriceListsArray, UpdatedOutlet, UpdatedOutlets;
	
	UpdatedOutlets = ObjectArrays.Get("UpdatedOutletsPricesArray");
	AgreementsValueTable = New ValueTable;
	AgreementsValueTable.Columns.Add("Контрагент_Key");
	AgreementsValueTable.Columns.Add("ВидЦен_Key");
	
	AgreementsArray = ObjectArrays.Get(Agreements);
	
	For Each AgreementElement In AgreementsArray Do
		
		AgreementRow = AgreementsValueTable.Add();
		FillPropertyValues(AgreementRow, AgreementElement);
		
	EndDo;
	
	For Each UpdatedOutlet In UpdatedOutlets Do
		
		OutletRef = Catalogs.Outlet.FindByAttribute("ExternalId",UpdatedOutlet);
		
		If Not OutletRef = Catalogs.Outlet.EmptyRef() Then
			OutletObj = OutletRef.GetObject();
		EndIf;
		
		If Not OutletObj = Undefined Then
			
			PriceListsArray = AgreementsValueTable.FindRows(New Structure("Контрагент_Key", UpdatedOutlet));
			
			If Not PriceListsArray.Count() = 0 Then
				
				OutletObj.Prices.Clear();
				
				For Each PriceList In PriceListsArray Do
					
					PriceListRef = Documents.PriceList.GetRef(New UUID(PriceList.ВидЦен_Key));
					NewPriceListRow = OutletObj.Prices.Add();
					NewPriceListRow.PriceList = PriceListRef;
					
				EndDo;
				
				OutletObj.Prices.GroupBy("PriceList");
				OutletObj.Write();
				
			EndIf;
			
			
		EndIf;
		
	EndDo;

EndProcedure

Procedure WritePriceList(PriceListStructure)
	
	PriceListObject = GetDocumentObject("PriceList", PriceListStructure.Ref_Key);
	PriceListObject.Description = PriceListStructure.Description;
	
	If Not PriceListObject.Ref.Description = PriceListStructure.Description Then
		
		PriceListObject.Write();
		
	EndIf;

EndProcedure

Function IsRoot(SKUGroupsCopy,Element)
	
	For Each Elem1 In SKUGroupsCopy Do
		If(Elem1.Ref_Key = Element.Parent_Key) Then 
			Return false;	
		EndIf;					
	EndDo;
	
	Return True;	
EndFunction
Function GetSKUGroupsTree(SKUGroupsArray)
	
	ParentsGUIDs = New Array;
	ParentsGUIDs.Add("00000000-0000-0000-0000-000000000000");
	
	SKUGroupsCopy = CopyArray(SKUGroupsArray);
		
	SKUGroupsTree = New ValueTree;
	SKUGroupsTree.Columns.Add("Ref_Key");
	SKUGroupsTree.Columns.Add("Parent_Key");
	SKUGroupsTree.Columns.Add("Description");
	
	i = 0;
	
	While SKUGroupsCopy.Count() Do
		
		For Each Element In SKUGroupsCopy Do
			
			If Not ParentsGUIDs.Find(Element.Parent_Key) = Undefined Or IsRoot(SKUGroupsCopy,Element) Then
				
				ParentsGUIDs.Add(Element.Ref_Key);
				FoundIndex = SKUGroupsArray.Find(Element);
				
				If FoundIndex <> Undefined Then
					
					SKUGroupsArray.Delete(FoundIndex);
					
				EndIf;
				
				Parents = SKUGroupsTree.Rows.FindRows(New Structure("Ref_Key", Element.Parent_Key), True);
				
				If Parents.Count() = 0 Then
					
					NewRow = SKUGroupsTree.Rows.Add();
					
				Else
					
					NewRow = Parents[0].Rows.Add();
					
				EndIf;
				
				FillPropertyValues(NewRow, Element);
								
			EndIf;
			
		EndDo;
		
		SKUGroupsCopy = CopyArray(SKUGroupsArray);
	EndDo;
	Return SKUGroupsTree;

EndFunction

Function GetPacks()
	
	Connection = DataProcessors.bitmobile_DataExchanger.GetConnection();
	
	Map = New Map;
	
	If Not Connection = Undefined Then
	
		Request = New HTTPRequest("/" + ThisObject.PublicationName + "/odata/standard.odata/Catalog_УпаковкиНоменклатуры");
		Result = Connection.Get(Request);
		Body = Result.GetBodyAsString();
		
		PacksPropertyNames = New Array;
		PacksPropertyNames.Add("Ref_Key");
		PacksPropertyNames.Add("Owner");
		PacksPropertyNames.Add("Owner_Type");
		PacksPropertyNames.Add("Description");
		PacksPropertyNames.Add("Коэффициент");
		
		XMLReader = New XMLReader;
		XMLReader.SetString(Body);
		
		DOMBuilder = New DOMBuilder;
		Doc = DOMBuilder.Read(XMLReader);
		
		Entries = Doc.GetElementByTagName("entry");
		
		PacksArray = New Array;
		
		For Each Entry In Entries Do
			
			PropertyNodes = Entry.GetElementByTagName("properties");
			
			Structure = New Structure;
			
			For Each PropertyNode In PropertyNodes Do
				
				For Each Property In PropertyNode.ChildNodes Do
					
					If Not PacksPropertyNames.Find(Property.LocalName) = Undefined Then
						
						Structure.Insert(Property.LocalName, Property.TextContent);
						
					EndIf;
					
				EndDo;
				
			EndDo;
			
			PacksArray.Add(Structure);
			
		EndDo;
		
		For Each Pack In PacksArray Do
			
			FoundPack = Catalogs.UnitsOfMeasure.FindByDescription(Pack.Description, True);
			
			If FoundPack = Catalogs.UnitsOfMeasure.EmptyRef() Then
				
				PackObject = Catalogs.UnitsOfMeasure.CreateItem();
				PackObject.Description = Pack.Description;
				PackObject.FullDescription = Pack.Description;
				
				If Not PackObject.Description = Pack.Description Then
					
					PackObject.Write();
					FoundPack = PackObject.Ref;
					
				EndIf;
				
			EndIf;
			
			Pack.Insert("Pack_Ref", FoundPack);
			
		EndDo;
		
		For Each Pack In PacksArray Do
			
			OwnerPacks = Map.Get(Pack.Owner);
			
			If OwnerPacks = Undefined Then
				
				OwnerPacks = New Array;
				
			EndIf;
			
			OwnerPacks.Add(Pack);
			
			Map.Insert(Pack.Owner, OwnerPacks);
			
		EndDo;
		
	EndIf;
	
	Return Map;
	
EndFunction

Function GetUnitRef(UUID)
	
	UnitRef = Catalogs.UnitsOfMeasure.GetRef(New UUID(UUID));
	
	Try
		
		UnitRef.GetObject();
		
	Except
		
		Selection = Catalogs.UnitsOfMeasure.Select();
		
		If Selection.Next() Then
			
			UnitRef = Selection.Ref;
			
		EndIf;
		
	EndTry;
	Return UnitRef;

EndFunction

Function GetCatalogObject(CatalogName, UUID)
	
	Ref = Catalogs[CatalogName].GetRef(New UUID(UUID));
	Obj = Ref.GetObject();
	
	If Obj = Undefined Then
		
		Obj = Catalogs[CatalogName].CreateItem();
		Obj.SetNewObjectRef(Ref);
		
	EndIf;
	
	Return Obj;
	
EndFunction

Function GetDocumentObject(DocumentName, UUID)
	
	Ref = Documents[DocumentName].GetRef(New UUID(UUID));
	Obj = Ref.GetObject();
	
	If Obj = Undefined Then
		
		Obj = Documents[DocumentName].CreateDocument();
		Obj.SetNewObjectRef(Ref);
		Obj.Date = CurrentDate();
		
	EndIf;
	
	Return Obj;
	
EndFunction

#EndRegion

#Region SendObjects

Procedure SendPatchOrderTrade11(Connection, Headers, OrderSelection, ExternalID)
	
	Path = GetTempFileName(".xml");
	
	WriteOrderTrade11(OrderSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ЗаказКлиента(guid'" + String(ExternalID) + "')", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Patch(Request);
	
EndProcedure

Procedure SendPatchReturnTrade11(Connection, Headers, ReturnSelection, ExternalID)
	
	Path = GetTempFileName(".xml");
	
	WriteReturnTrade11(ReturnSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ВозвратТоваровОтКлиента", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Patch(Request);
	
EndProcedure

Procedure SendPostOrderTrade11(Connection, Headers, OrderSelection)
	
	Path = GetTempFileName(".xml");
	
	WriteOrderTrade11(OrderSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ЗаказКлиента", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Post(Request);
	
	If Result.StatusCode = 201 Then
		
		Body = Result.GetBodyAsString();
		
		XMLReader = New XMLReader;
		XMLReader.SetString(Body);
		
		DOMBuilder = New DOMBuilder;
		Doc = DOMBuilder.Read(XMLReader);
		
		IdNodes = Doc.GetElementByTagName("Ref_Key");
		
		If IdNodes.Count() > 0 Then
			
			IdNode = IdNodes[0];
			Id = New UUID(IdNode.TextContent);
			
			RecordManager = InformationRegisters.bitmobile_ВнешниеИдентификаторыОбъектов.CreateRecordManager();
			RecordManager.Object = OrderSelection.Ref;
			RecordManager.ExternalID = Id;
			RecordManager.Write();
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure SendPostReturnTrade11(Connection, Headers, ReturnSelection)
	
	Path = GetTempFileName(".xml");
	
	WriteReturnTrade11(ReturnSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ВозвратТоваровОтКлиента", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Post(Request);
	
	If Result.StatusCode = 201 Then
		
		Body = Result.GetBodyAsString();
		
		XMLReader = New XMLReader;
		XMLReader.SetString(Body);
		
		DOMBuilder = New DOMBuilder;
		Doc = DOMBuilder.Read(XMLReader);
		
		IdNodes = Doc.GetElementByTagName("Ref_Key");
		
		If IdNodes.Count() > 0 Then
			
			IdNode = IdNodes[0];
			Id = New UUID(IdNode.TextContent);
			
			RecordManager = InformationRegisters.bitmobile_ВнешниеИдентификаторыОбъектов.CreateRecordManager();
			RecordManager.Object = ReturnSelection.Ref;
			RecordManager.ExternalID = Id;
			RecordManager.Write();
			
		EndIf;
		
	Else
		
		Body = Result.GetBodyAsString();
		Message(Body);
		
	EndIf;

EndProcedure

Procedure WriteReturnTrade11(ReturnSelection, Path)
	
	UUID = ReturnSelection.Ref.UUID();
	Date = ReturnSelection.Date;
	ContractorUUID = ReturnSelection.Outlet.ExternalId;
	PartnerUUID = ReturnSelection.Outlet.Distributor.ExternalId;
	ResponsibleUUID = ReturnSelection.SR.ExternalId;
	ReturnDate = ReturnSelection.ReturnDate;
	StockUUID = ReturnSelection.Stock.UUID();
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(Path);
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("entry");
	
	XMLWriter.WriteStartElement("category");
	XMLWriter.WriteAttribute("term", "StandardODATA.Document_ВозвратТоваровОтКлиента");
	XMLWriter.WriteAttribute("scheme", "http://schemas.microsoft.com/ado/2007/08/dataservices/scheme");
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("updated");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("content");
	XMLWriter.WriteAttribute("type", "application/xml");
	
	XMLWriter.WriteStartElement("m:properties");
	XMLWriter.WriteNamespaceMapping("d", "http://schemas.microsoft.com/ado/2007/08/dataservices");
	XMLWriter.WriteNamespaceMapping("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata");
	
	XMLWriter.WriteStartElement("d:Date");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Партнер_Key");
	XMLWriter.WriteText(String(PartnerUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Контрагент_Key");
	XMLWriter.WriteText(String(ContractorUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Склад_Key");
	XMLWriter.WriteText(String(StockUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Комментарий");
	XMLWriter.WriteText(String(ThisObject.CurrentExchangePlanNodeRefKey));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Товары");
	XMLWriter.WriteAttribute("m:type", "Collection(StandardODATA.Document_ВозвратТоваровОтКлиента_Товары_RowType)");
	
	For Each Row In ReturnSelection.SKUs Do
		
		If Row.Units = Row.SKU.BaseUnit Then
			Multiplier = 1;
		Else
			If Row.SKU.Packing.Find(Row.Units) = Undefined Then
				Multiplier = 1;
			Else
				Multiplier = Row.SKU.Packing.Find(Row.Units).Multiplier;
			EndIf;
		EndIf;
		
		XMLWriter.WriteStartElement("d:element");
		XMLWriter.WriteAttribute("m:type", "StandardODATA.Document_ВозватТоваровОтКлиента_Товары_RowType");
		
		XMLWriter.WriteStartElement("d:LineNumber");
		XMLWriter.WriteText(Format(Row.LineNumber, "NG=0"));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Номенклатура_Key");
		XMLWriter.WriteText(String(Row.SKU.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Количество");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Qty * Multiplier));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:КоличествоУпаковок");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Qty));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Цена");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Price));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Сумма");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Amount));
		XMLWriter.WriteEndElement();
		
		// element
		XMLWriter.WriteEndElement();
		
	EndDo;
	
	// Товары
	XMLWriter.WriteEndElement();
	
	// properties
	XMLWriter.WriteEndElement();
	
	// content
	XMLWriter.WriteEndElement();
	
	// entry
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
	
EndProcedure

Procedure WriteOrderTrade11(OrderSelection, Path)
	
	UUID = OrderSelection.Ref.UUID();
	Date = OrderSelection.Date;
	ContractorUUID = OrderSelection.Outlet.ExternalId;
	PartnerUUID = OrderSelection.Outlet.Distributor.ExternalId;
	ResponsibleUUID = OrderSelection.SR.ExternalId;
	DeliveryDate = OrderSelection.DeliveryDate;
	StockUUID = OrderSelection.Stock.UUID();
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(Path);
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("entry");
	
	XMLWriter.WriteStartElement("category");
	XMLWriter.WriteAttribute("term", "StandardODATA.Document_ЗаказКлиента");
	XMLWriter.WriteAttribute("scheme", "http://schemas.microsoft.com/ado/2007/08/dataservices/scheme");
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("updated");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("content");
	XMLWriter.WriteAttribute("type", "application/xml");
	
	XMLWriter.WriteStartElement("m:properties");
	XMLWriter.WriteNamespaceMapping("d", "http://schemas.microsoft.com/ado/2007/08/dataservices");
	XMLWriter.WriteNamespaceMapping("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata");
	
	XMLWriter.WriteStartElement("d:Date");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Партнер_Key");
	XMLWriter.WriteText(String(PartnerUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Контрагент_Key");
	XMLWriter.WriteText(String(ContractorUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Ответственный_Key");
	XMLWriter.WriteText(String(ResponsibleUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:ЖелаемаяДатаОтгрузки");
	XMLWriter.WriteText(Format(DeliveryDate, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Склад_Key");
	XMLWriter.WriteText(String(StockUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Автор");
	XMLWriter.WriteText(String(ResponsibleUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Автор_Type");
	XMLWriter.WriteText("StandardODATA.Catalog_Пользователи");
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Комментарий");
	XMLWriter.WriteText(String(ThisObject.CurrentExchangePlanNodeRefKey));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Товары");
	XMLWriter.WriteAttribute("m:type", "Collection(StandardODATA.Document_ЗаказКлиента_Товары_RowType)");
	
	For Each Row In OrderSelection.SKUs Do
		
		If Row.Units = Row.SKU.BaseUnit Then
			Multiplier = 1;
		Else
			If Row.SKU.Packing.Find(Row.Units) = Undefined Then
				Multiplier = 1;
			Else
				Multiplier = Row.SKU.Packing.Find(Row.Units).Multiplier;
			EndIf;
		EndIf;
		
		XMLWriter.WriteStartElement("d:element");
		XMLWriter.WriteAttribute("m:type", "StandardODATA.Document_ЗаказКлиента_Товары_RowType");
		
		XMLWriter.WriteStartElement("d:LineNumber");
		XMLWriter.WriteText(Format(Row.LineNumber, "NG=0"));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Номенклатура_Key");
		XMLWriter.WriteText(String(Row.SKU.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Количество");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Qty * Multiplier));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:КоличествоУпаковок");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Qty));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Цена");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Price));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:ПроцентРучнойСкидки");
		XMLWriter.WriteText(getDoubleValueRepresentation(-Row.Discount));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:СуммаРучнойСкидки");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Price * Row.Qty * (-Row.Discount) / 100));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Сумма");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Amount));
		XMLWriter.WriteEndElement();
		
		// element
		XMLWriter.WriteEndElement();
		
	EndDo;
	
	// Товары
	XMLWriter.WriteEndElement();
	
	// properties
	XMLWriter.WriteEndElement();
	
	// content
	XMLWriter.WriteEndElement();
	
	// entry
	XMLWriter.WriteEndElement();
	XMLWriter.Close();

EndProcedure


Procedure SendPostOrderTrade103(Connection, Headers, OrderSelection)
	
	Path = GetTempFileName(".xml");
	
	WriteOrderTrade103(OrderSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ЗаказПокупателя", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Post(Request);
	
	If Result.StatusCode = 201 Then
		
		Body = Result.GetBodyAsString();
		
		XMLReader = New XMLReader;
		XMLReader.SetString(Body);
		
		DOMBuilder = New DOMBuilder;
		Doc = DOMBuilder.Read(XMLReader);
		
		IdNodes = Doc.GetElementByTagName("Ref_Key");
		
		If IdNodes.Count() > 0 Then
			
			IdNode = IdNodes[0];
			Id = New UUID(IdNode.TextContent);
			
			RecordManager = InformationRegisters.bitmobile_ВнешниеИдентификаторыОбъектов.CreateRecordManager();
			RecordManager.Object = OrderSelection.Ref;
			RecordManager.ExternalID = Id;
			RecordManager.Write();
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure SendPatchOrderTrade103(Connection, Headers, OrderSelection, ExternalID)
	
	Path = GetTempFileName(".xml");
	
	WriteOrderTrade103(OrderSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ЗаказПокупателя(guid'" + String(ExternalID) + "')", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Patch(Request);
	
EndProcedure

Procedure WriteOrderTrade103(OrderSelection, Path)
	
	UUID = OrderSelection.Ref.UUID();
	Date = OrderSelection.Date;
	ContractorUUID = OrderSelection.Outlet.ExternalId;
	PartnerUUID = OrderSelection.Outlet.Distributor.ExternalId;
	ResponsibleUUID = OrderSelection.SR.ExternalId;
	DeliveryDate = OrderSelection.DeliveryDate;
	StockUUID = OrderSelection.Stock.UUID();
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(Path);
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("entry");
	
	XMLWriter.WriteStartElement("category");
	XMLWriter.WriteAttribute("term", "StandardODATA.Document_ЗаказПокупателя");
	XMLWriter.WriteAttribute("scheme", "http://schemas.microsoft.com/ado/2007/08/dataservices/scheme");
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("updated");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("content");
	XMLWriter.WriteAttribute("type", "application/xml");
	
	XMLWriter.WriteStartElement("m:properties");
	XMLWriter.WriteNamespaceMapping("d", "http://schemas.microsoft.com/ado/2007/08/dataservices");
	XMLWriter.WriteNamespaceMapping("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata");
	
	XMLWriter.WriteStartElement("d:Date");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	//XMLWriter.WriteStartElement("d:Партнер_Key");
	//XMLWriter.WriteText(String(PartnerUUID));
	//XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Контрагент_Key");
	XMLWriter.WriteText(String(ContractorUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Ответственный_Key");
	XMLWriter.WriteText(String(ResponsibleUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:ДатаОтгрузки");
	XMLWriter.WriteText(Format(DeliveryDate, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Склад_Key");
	XMLWriter.WriteText(String(StockUUID));
	XMLWriter.WriteEndElement();
	
	//XMLWriter.WriteStartElement("d:Автор");
	//XMLWriter.WriteText(String(ResponsibleUUID));
	//XMLWriter.WriteEndElement();
	//
	//XMLWriter.WriteStartElement("d:Автор_Type");
	//XMLWriter.WriteText("StandardODATA.Catalog_Пользователи");
	//XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Комментарий");
	XMLWriter.WriteText(String(ThisObject.CurrentExchangePlanNodeRefKey));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Товары");
	XMLWriter.WriteAttribute("m:type", "Collection(StandardODATA.Document_ЗаказПокупателя_Товары_RowType)");
	
	For Each Row In OrderSelection.SKUs Do
		
		If Row.Units = Row.SKU.BaseUnit Then
			Multiplier = 1;
		Else
			If Row.SKU.Packing.Find(Row.Units) = Undefined Then
				Multiplier = 1;
			Else
				Multiplier = Row.SKU.Packing.Find(Row.Units).Multiplier;
			EndIf;
		EndIf;
		
		XMLWriter.WriteStartElement("d:element");
		XMLWriter.WriteAttribute("m:type", "StandardODATA.Document_ЗаказПокупателя_Товары_RowType");
		
		XMLWriter.WriteStartElement("d:LineNumber");
		XMLWriter.WriteText(Format(Row.LineNumber, "NG=0"));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Номенклатура_Key");	
		XMLWriter.WriteText(String(Row.SKU.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Количество");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Qty * Multiplier));
		XMLWriter.WriteEndElement();
		
		//XMLWriter.WriteStartElement("d:КоличествоУпаковок");
		//XMLWriter.WriteText(Format(Row.Qty, "NG=0"));
		//XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Цена");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Price));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:ПроцентСкидкиНаценки");
		XMLWriter.WriteText(getDoubleValueRepresentation(-1 * Row.Discount));
		XMLWriter.WriteEndElement();
		
		//XMLWriter.WriteStartElement("d:СуммаРучнойСкидки");
		//XMLWriter.WriteText(Format(Row.Price * Row.Qty * Row.Discount / 100, "NG=0"));
		//XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Сумма");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Amount));
		XMLWriter.WriteEndElement();
		
		// element
		XMLWriter.WriteEndElement();
		
	EndDo;
	
	// Товары
	XMLWriter.WriteEndElement();
	
	// properties
	XMLWriter.WriteEndElement();
	
	// content
	XMLWriter.WriteEndElement();
	
	// entry
	XMLWriter.WriteEndElement();
	XMLWriter.Close();

EndProcedure

Procedure SendPostReturnTrade103(Connection, Headers, ReturnSelection)
	
	Path = GetTempFileName(".xml");
	
	WriteReturnTrade103(ReturnSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ВозвратТоваровОтПокупателя", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Post(Request);
	
	If Result.StatusCode = 201 Then
		
		Body = Result.GetBodyAsString();
		
		XMLReader = New XMLReader;
		XMLReader.SetString(Body);
		
		DOMBuilder = New DOMBuilder;
		Doc = DOMBuilder.Read(XMLReader);
		
		IdNodes = Doc.GetElementByTagName("Ref_Key");
		
		If IdNodes.Count() > 0 Then
			
			IdNode = IdNodes[0];
			Id = New UUID(IdNode.TextContent);
			
			RecordManager = InformationRegisters.bitmobile_ВнешниеИдентификаторыОбъектов.CreateRecordManager();
			RecordManager.Object = ReturnSelection.Ref;
			RecordManager.ExternalID = Id;
			RecordManager.Write();
			
		EndIf;
		
	Else
		
		Body = Result.GetBodyAsString();
		Message(Body);
		
	EndIf;

EndProcedure

Procedure SendPatchReturnTrade103(Connection, Headers, ReturnSelection, ExternalID)
	
	Path = GetTempFileName(".xml");
	
	WriteReturnTrade103(ReturnSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ВозвратТоваровОтПокупателя", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Patch(Request);
	
EndProcedure

Procedure WriteReturnTrade103(ReturnSelection, Path)
	
	UUID = ReturnSelection.Ref.UUID();
	Date = ReturnSelection.Date;
	ContractorUUID = ReturnSelection.Outlet.ExternalId;
	PartnerUUID = ReturnSelection.Outlet.Distributor.ExternalId;
	ResponsibleUUID = ReturnSelection.SR.ExternalId;
	ReturnDate = ReturnSelection.ReturnDate;
	StockUUID = ReturnSelection.Stock.UUID();
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(Path);
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("entry");
	
	XMLWriter.WriteStartElement("category");
	XMLWriter.WriteAttribute("term", "StandardODATA.Document_ВозвратТоваровОтПокупателя");
	XMLWriter.WriteAttribute("scheme", "http://schemas.microsoft.com/ado/2007/08/dataservices/scheme");
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("updated");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("content");
	XMLWriter.WriteAttribute("type", "application/xml");
	
	XMLWriter.WriteStartElement("m:properties");
	XMLWriter.WriteNamespaceMapping("d", "http://schemas.microsoft.com/ado/2007/08/dataservices");
	XMLWriter.WriteNamespaceMapping("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata");
	
	XMLWriter.WriteStartElement("d:Date");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
		
	XMLWriter.WriteStartElement("d:Контрагент_Key");
	XMLWriter.WriteText(String(ContractorUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Ответственный_Key");
	XMLWriter.WriteText(String(ResponsibleUUID));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("d:Склад_Key");
	XMLWriter.WriteText(String(StockUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Комментарий");
	XMLWriter.WriteText(String(ThisObject.CurrentExchangePlanNodeRefKey));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Товары");
	XMLWriter.WriteAttribute("m:type", "Collection(StandardODATA.Document_ВозвратТоваровОтПокупателя_Товары_RowType)");
	
	For Each Row In ReturnSelection.SKUs Do
		
		If Row.Units = Row.SKU.BaseUnit Then
			Multiplier = 1;
		Else
			If Row.SKU.Packing.Find(Row.Units) = Undefined Then
				Multiplier = 1;
			Else
				Multiplier = Row.SKU.Packing.Find(Row.Units).Multiplier;
			EndIf;
		EndIf;
		
		XMLWriter.WriteStartElement("d:element");
		XMLWriter.WriteAttribute("m:type", "StandardODATA.Document_ВозвратТоваровОтПокупателя_Товары_RowType");
		
		XMLWriter.WriteStartElement("d:LineNumber");
		XMLWriter.WriteText(Format(Row.LineNumber, "NG=0"));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Номенклатура_Key");
		XMLWriter.WriteText(String(Row.SKU.UUID()));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Количество");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Qty * Multiplier));
		XMLWriter.WriteEndElement();
		
		//XMLWriter.WriteStartElement("d:КоличествоУпаковок");
		//XMLWriter.WriteText(Format(Row.Qty, "NG=0"));
		//XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:Цена");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Price));
		XMLWriter.WriteEndElement();
		
		XMLWriter.WriteStartElement("d:ПроцентСкидкиНаценки");
		XMLWriter.WriteText(getDoubleValueRepresentation(-1 * Row.Discount));
		XMLWriter.WriteEndElement();

		
		XMLWriter.WriteStartElement("d:Сумма");
		XMLWriter.WriteText(getDoubleValueRepresentation(Row.Amount));
		XMLWriter.WriteEndElement();
		
		// element
		XMLWriter.WriteEndElement();
		
	EndDo;
	
	// Товары
	XMLWriter.WriteEndElement();
	
	// properties
	XMLWriter.WriteEndElement();
	
	// content
	XMLWriter.WriteEndElement();
	
	// entry
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
	
EndProcedure

Procedure SendPostEncashmentTrade103(Connection, Headers, EncashmentSelection)
	
	Path = GetTempFileName(".xml");
	
	WriteEncashmentTrade103(EncashmentSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ПриходныйКассовыйОрдер", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Post(Request);
	
	If Result.StatusCode = 201 Then
		
		Body = Result.GetBodyAsString();
		
		XMLReader = New XMLReader;
		XMLReader.SetString(Body);
		
		DOMBuilder = New DOMBuilder;
		Doc = DOMBuilder.Read(XMLReader);
		
		IdNodes = Doc.GetElementByTagName("Ref_Key");
		
		If IdNodes.Count() > 0 Then
			
			IdNode = IdNodes[0];
			Id = New UUID(IdNode.TextContent);
			
			RecordManager = InformationRegisters.bitmobile_ВнешниеИдентификаторыОбъектов.CreateRecordManager();
			RecordManager.Object = EncashmentSelection.Ref;
			RecordManager.ExternalID = Id;
			RecordManager.Write();
			
		EndIf;
		
	Else
		
		Body = Result.GetBodyAsString();
		Message(Body);
		
	EndIf;

EndProcedure

Procedure WriteEncashmentTrade103(EncashmentSelection, Path)
	
	UUID = EncashmentSelection.Ref.UUID();
	Date = EncashmentSelection.Date;
	ContractorUUID = EncashmentSelection.Visit.Outlet.ExternalId;
	//PartnerUUID = ReturnSelection.Outlet.Distributor.UUID();
	ResponsibleUUID = EncashmentSelection.Visit.SR.ExternalId;
	//ReturnDate = ReturnSelection.ReturnDate;
	//StockUUID = ReturnSelection.Stock.UUID();
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(Path);
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("entry");
	
	XMLWriter.WriteStartElement("category");
	XMLWriter.WriteAttribute("term", "StandardODATA.Document_ПриходныйКассовыйОрдер");
	XMLWriter.WriteAttribute("scheme", "http://schemas.microsoft.com/ado/2007/08/dataservices/scheme");
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("updated");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("content");
	XMLWriter.WriteAttribute("type", "application/xml");
	
	XMLWriter.WriteStartElement("m:properties");
	XMLWriter.WriteNamespaceMapping("d", "http://schemas.microsoft.com/ado/2007/08/dataservices");
	XMLWriter.WriteNamespaceMapping("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata");
	
	XMLWriter.WriteStartElement("d:Date");
	XMLWriter.WriteText(Format(Date, "DF=yyyy-MM-ddTHH:mm:ss"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Контрагент_Type");
	XMLWriter.WriteText(String("StandardODATA.Catalog_Контрагенты"));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Контрагент");
	XMLWriter.WriteText(String(ContractorUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:Ответственный_Key");
	XMLWriter.WriteText(String(ResponsibleUUID));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:СуммаДокумента");
	XMLWriter.WriteText(getDoubleValueRepresentation(EncashmentSelection.EncashmentAmount));
	XMLWriter.WriteEndElement();

	
	
	XMLWriter.WriteStartElement("d:Комментарий");
	XMLWriter.WriteText(String(ThisObject.CurrentExchangePlanNodeRefKey));
	XMLWriter.WriteEndElement();
	
	//ТЧ расшифровка платежа
	XMLWriter.WriteStartElement("d:РасшифровкаПлатежа");
	XMLWriter.WriteAttribute("m:type", "Collection(StandardODATA.Document_ПриходныйКассовыйОрдер_РасшифровкаПлатежа_RowType)");
		
	XMLWriter.WriteStartElement("d:element");
	XMLWriter.WriteAttribute("m:type", "StandardODATA.Document_ПриходныйКассовыйОрдер_РасшифровкаПлатежа_RowType");
	
	XMLWriter.WriteStartElement("d:LineNumber");
	XMLWriter.WriteText(Format(1, "NG=0"));
	XMLWriter.WriteEndElement();

	XMLWriter.WriteStartElement("d:СуммаПлатежа");
	XMLWriter.WriteText(getDoubleValueRepresentation(EncashmentSelection.EncashmentAmount));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteStartElement("d:СуммаВзаиморасчетов");
	XMLWriter.WriteText(getDoubleValueRepresentation(EncashmentSelection.EncashmentAmount));
	XMLWriter.WriteEndElement();
	
	// element
	XMLWriter.WriteEndElement();
		
	
	// ТЧ расшифровка платежа
	XMLWriter.WriteEndElement();
	
		
	// properties
	XMLWriter.WriteEndElement();
	
	// content
	XMLWriter.WriteEndElement();
	
	// entry
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
	
EndProcedure

#EndRegion

#Region Helpers

Function CopyArray(ArrayFrom) 
	
	ArrayTo = New Array;
	
	For Each Element In ArrayFrom Do
		
		ArrayTo.Add(Element);
		
	EndDo;
	
	Return ArrayTo;
	
EndFunction

Procedure SendPatchEncashmentTrade103(Connection, Headers, EncashmentSelection, ExternalID)
	
	Path = GetTempFileName(".xml");
	
	WriteEncashmentTrade103(EncashmentSelection, Path);
	
	Request = New HTTPRequest(ThisObject.PublicationName + "/odata/standard.odata/Document_ПриходныйКассовыйОрдер(guid'" + String(ExternalID) + "')", Headers);
	Request.SetBodyFileName(Path);
	Result = Connection.Patch(Request);
	
EndProcedure

Function getDoubleValueRepresentation(DoubleValue)
	return Format(DoubleValue, "NDS=.; NG=0");	
EndFunction

Function CreateXMLWriterExchangeFile(FilesArray, RootElemAtributesArray)
	FileName = GetTempFileName(".xml");
	FilesArray.add(FileName);
	
	XMLWriter = new XMLWriter;
	XMLWriter.OpenFile(FileName);

	XMLWriter.WriteStartElement("feed");
	for each atributeElem in RootElemAtributesArray do
		XMLWriter.WriteAttribute(atributeElem.key, atributeElem.value);	
	EndDo;
	
	
	return xmlWriter;
	
EndFunction

Function CloseXMLWriterExchangeFile(XMLWriter)
		
	XMLWriter.WriteEndElement();
	XMLWriter.Close();	
	
EndFunction

Procedure CopyEntryElement(XMLReader, XMLWriter)
	If false then
		XMLReader = New XMLReader;
		XMLWriter = new XMLWriter;
	endIF;
	
	XMLWriter.WriteStartElement(XMLReader.Name);
	
	while XMLReader.read() do
		if XMLReader.NodeType = XMLNodeType.StartElement then
			XMLWriter.WriteStartElement(XMLReader.Name);
			If XMLReader.AttributeCount() > 0 then
				while XMLReader.ReadAttribute() do
					XMLWriter.WriteAttribute(XMLReader.Name, XMLReader.Value);	
				endDo;				
			endIf;
		elsIf XMLReader.NodeType = XMLNodeType.EndElement then
			XMLWriter.WriteEndElement();
		elsIf XMLReader.NodeType = XMLNodeType.Text then
			XMLWriter.WriteText(XMLReader.Value);			
		endIf;
		
		
		if XMLReader.LocalName = "entry" and XMLReader.NodeType = XMLNodeType.EndElement then
			break;	
		endIf;		
	endDo;
	
EndProcedure

Function getRootElementAtributesArray(XMLReader)
	XMLReader.read();
	AtributesMap = new Map;
	While XMLReader.ReadAttribute() do
		AtributesMap.Insert(XMLReader.name, XMLReader.value);
	endDo;
	
	return AtributesMap;
EndFunction

Function getStocksForRemains103(ExchangePlanNodeXMLDoc)
	mStocks = new array;
	
	ElementValue = ExchangePlanNodeXMLDoc.GetElementByTagName("d:Склады");
	For each element in ElementValue do
		For each StockElem in element.ChildNodes do
			mStocks.Add(StockElem.LastChild.TextContent);	
		endDo;
	endDo;
	
	return mStocks;
	
EndFunction

	



#EndRegion

#Region Init

AccumulationRegister = "StandardODATA.AccumulationRegister";
InformationRegister = "StandardODATA.InformationRegister";
Catalog = "StandardODATA.Catalog";

Brands = Catalog + "_Марки";
PriceLists = Catalog + "_ВидыЦен";
SKUs = Catalog + "_Номенклатура";
Series = Catalog + "_СерииНоменклатуры";
SKUGroups = Catalog + "_Номенклатура" + "Folder";
Agreement = Catalog + "_ДоговорыКонтрагентов"; 
Packs = Catalog + "_УпаковкиНоменклатуры";
Units = Catalog + "_ЕдиницыИзмерения";
Units103 = Catalog + "_ЕдиницыИзмерения";
Stocks = Catalog + "_Склады";
Outlets = Catalog + "_Контрагенты";
Partners = Catalog + "_Партнеры";
Contacts = Catalog + "_КонтактныеЛицаПартнеров";
Prices = InformationRegister + "_ЦеныНоменклатуры";
Agreements = Catalog + "_СоглашенияСКлиентами";
UpdatedSKUStocks = AccumulationRegister + "_СвободныеОстатки";
OutletsMutualSettlements103 = AccumulationRegister + "_ВзаиморасчетыСКонтрагентамиПоДокументамРасчетов"; 
SKUs103 = AccumulationRegister + "_ТоварыНаСкладах";  
UsersCat = Catalog + "_Пользователи";
//SKUsInStocks = AccumulationRegister + "_ТоварыНаСкладах";
ContactInfo = InformationRegister + "_КонтактнаяИнформация";
Contacts103 = Catalog + "_КонтактныеЛицаКонтрагентов";
PriceTypes = Catalog + "_ТипыЦенНоменклатуры";

ExchangePlan = "StandardODATA.ExchangePlan_bitmobile_УправлениеТорговлейСуперагент";

EmptyRefString = "00000000-0000-0000-0000-000000000000";

SOURCE_CONFIG_UT11  = 0;
SOURCE_CONFIG_UT103 = 1;
MAX_ENTRY_NUMBER_PER_FILE = 5000;


#EndRegion