
#Region CommonProceduresAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillRegions();
	
	FillTerritories();
	
	SetConditionalAppearence();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	If ValueIsFilled(CurrentObject.Ref) Then
	
		Query = New Query(
		"SELECT
		|	ObjectTerritories.Territory
		|INTO ObjectTerritories
		|FROM
		|	&ObjectTerritories AS ObjectTerritories
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TerritoryOutlets.Ref AS Territory,
		|	OutletContractorsList.Ref AS Outlet
		|INTO OutletTerritories
		|FROM
		|	Catalog.Territory.Outlets AS TerritoryOutlets
		|		LEFT JOIN Catalog.Outlet.ContractorsList AS OutletContractorsList
		|		ON TerritoryOutlets.Outlet = OutletContractorsList.Ref
		|WHERE
		|	OutletContractorsList.Contractor = &Contractor
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OutletTerritories.Outlet,
		|	COUNT(DISTINCT OutletTerritories.Territory) AS OutletTerritory,
		|	COUNT(DISTINCT ObjectTerritories.Territory) AS PartnerTerritory
		|FROM
		|	OutletTerritories AS OutletTerritories
		|		LEFT JOIN ObjectTerritories AS ObjectTerritories
		|		ON OutletTerritories.Territory = ObjectTerritories.Territory
		|
		|GROUP BY
		|	OutletTerritories.Outlet
		|
		|HAVING
		|	COUNT(ObjectTerritories.Territory) = 0");
		
		Query.SetParameter("ObjectTerritories", CurrentObject.Territories.Unload());
		Query.SetParameter("Contractor", CurrentObject.Ref);
		Result = Query.Execute().Unload();
		
		Cancel = Result.Count() > 0;
		
		If Cancel Then
			
			OutletsRow = Chars.LF;
			
			For Each Row In Result Do
				
				OutletsRow = OutletsRow + Row.Outlet + Chars.LF;
				
			EndDo;
			
			Message("Невозможно записать изменения, так как ни одна территория контрагента не совпадает с территориями следующих торговых точек: " + OutletsRow);
			
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		
		If Not IsInRole("Admin") Then
		
			If ThisForm.Object.Regions.Count() = 0 Then
				
				Message(NStr("en = 'You cannot write contractor with empty list of regions.'; ru = 'Нельзя записывать контрагента с пустым списком регионов.'"));
				Cancel = True;
				
			EndIf;
			
			If ThisForm.Object.Territories.Count() = 0 Then
				
				Message(NStr("en = 'You cannot write contractor with empty list of territories.'; ru = 'Нельзя записывать контрагента с пустым списком территорий.'"));
				Cancel = True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#Region Regions

&AtServer
Procedure FillRegions()
	
	Query = New Query(
	"SELECT ALLOWED
	|	ContractorsRegions.Region
	|INTO SavedRegions
	|FROM
	|	Catalog.Contractors.Regions AS ContractorsRegions
	|WHERE
	|	ContractorsRegions.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	RegionCatalog.Ref AS Region,
	|	CASE
	|		WHEN SavedRegions.Region IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS USE
	|FROM
	|	Catalog.Region AS RegionCatalog
	|		LEFT JOIN SavedRegions AS SavedRegions
	|		ON RegionCatalog.Ref = SavedRegions.Region
	|
	|ORDER BY
	|	Region HIERARCHY
	|AUTOORDER");
	Query.SetParameter("Ref", ThisForm.Object.Ref);
	Result = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	ValueToFormAttribute(Result, "Regions");
	
EndProcedure

#EndRegion

#Region Territories

&AtServer
Procedure FillTerritories()
	
	Query = New Query(
	"SELECT ALLOWED
	|	ContractorsTerritories.Territory
	|INTO SavedTerritories
	|FROM
	|	Catalog.Contractors.Territories AS ContractorsTerritories
	|WHERE
	|	ContractorsTerritories.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TerritoryCatalog.Owner AS Region,
	|	TerritoryCatalog.Ref AS Territory,
	|	CASE
	|		WHEN SavedTerritories.Territory IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Use
	|FROM
	|	Catalog.Territory AS TerritoryCatalog
	|		LEFT JOIN SavedTerritories AS SavedTerritories
	|		ON TerritoryCatalog.Ref = SavedTerritories.Territory
	|
	|ORDER BY
	|	Region
	|AUTOORDER");
	
	Query.SetParameter("Ref", ThisForm.Object.Ref);
	
	Result = Query.Execute().Unload();
	
	ThisForm.Territories.Load(Result);
	
EndProcedure

#EndRegion

&AtServer
Procedure SetConditionalAppearence()
	
	// Green color for territories with current selected region
	CA = ThisForm.ConditionalAppearance;
	CAItem = CA.Items.Add();
	
	Field = CAItem.Fields.Items.Add();
	Field.Field = New DataCompositionField("TerritoriesRegion");
	Field.Use = True;
	
	Field = CAItem.Fields.Items.Add();
	Field.Field = New DataCompositionField("TerritoriesTerritory");
	Field.Use = True;
	
	Field = CAItem.Fields.Items.Add();
	Field.Field = New DataCompositionField("TerritoriesUse");
	Field.Use = True;
	
	FilterItem = CAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("Territories.Region");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = New DataCompositionField("CurrentRegion");
	
	CAItem.Appearance.SetParameterValue("BackColor", WebColors.PaleGreen);
	
	// Block use of territories that are not in current selected region
	CAItem = CA.Items.Add();
	
	Field = CAItem.Fields.Items.Add();
	Field.Field = New DataCompositionField("TerritoriesUse");
	Field.Use = True;
	
	FilterItem = CAItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("Territories.Region");
	FilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	FilterItem.RightValue = New DataCompositionField("CurrentRegion");
	
	CAItem.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not Cancel Then
		
		// Выполнить валидацию телефонного номера
		If ValueIsFilled(Object.PhoneNumber) Then 
			
			ParamArray = New Array;
			ParamArray.Add("/^((8|\+7)[\- ]?)?(\(?\d{3,4}\)?[\- ]?)?[\d\- ]{5,10}$/");
			ParamArray.Add(Object.PhoneNumber);
			
			If Not CommonProcessorsClient.ExecuteJSFunction("checkRegExp", ParamArray) Then 
				
				Cancel = True;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en='Incorrect value in the ""Phone number""';ru='Неверное значение в поле ""Телефонный номер""';cz='Incorrect value in the ""Phone number""'");
				
				UserMessage.Message();
				
			EndIf;
			
		EndIf;
		
		// Выполнить валидацию почты
		If ValueIsFilled(Object.Email) Then
			
			ParamArray = New Array;
			ParamArray.Add("/^([а-яА-ЯёЁa-zA-Z0-9_-]+\.)*[а-яА-ЯёЁa-zA-Z0-9_-]+@[а-яА-ЯёЁa-zA-Z0-9_-]+(\.[а-яА-ЯёЁa-zA-Z0-9_-]+)*\.[а-яА-ЯёЁa-zA-Z]{2,6}$/");
			ParamArray.Add(Object.Email);
			
			If Not CommonProcessorsClient.ExecuteJSFunction("checkRegExp", ParamArray) Then 
				
				Cancel = True;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en='Incorrect value in the field ""E-mail""';ru='Неверное значение в поле ""E-mail""';cz='Incorrect value in the field ""E-mail""'");
				
				UserMessage.Message();
				
			EndIf;
			
		EndIf;
		
		// Выполнить валидацию ИНН
		If ValueIsFilled(Object.INN) Then 
			
			INN			= TrimAll(Object.INN);
			INN_Lenght	= StrLen(INN);
			
			If Not INN_Lenght = 10 And Not INN_Lenght = 12 Then 
				
				Cancel = True;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en = 'INN  shall consist of 10 or 12 digits'; ru = 'ИНН должен состоять из 10 или 12 цифр'");
				
				UserMessage.Message();
				
			EndIf;
			
			If Not СтроковыеФункцииКлиентСервер.ТолькоЦифрыВСтроке(INN) And Not Cancel Then 
				
				Cancel = True;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en = 'INN shall consist only of digits'; ru = 'ИНН должен состоять только из цифр'");
				
				UserMessage.Message();
				
			КонецЕсли;
			
			If Not Cancel Then
				
				If INN_Lenght = 10 Then
					
					ControlSum = 0;
					
					For N = 1 To 9 Do 
						
						If N = 1 Then
							Multiplier = 2;
						ElsIf N = 2 Then
							Multiplier = 4;
						ElsIf N = 3 Then
							Multiplier = 10;
						ElsIf N = 4 Then
							Multiplier = 3;
						ElsIf N = 5 Then
							Multiplier = 5;
						ElsIf N = 6 Then
							Multiplier = 9;
						ElsIf N = 7 Then
							Multiplier = 4;
						ElsIf N = 8 Then
							Multiplier = 6;
						ElsIf N = 9 Then
							Multiplier = 8;
						EndIf;
						
						Digit = Number(Mid(INN, N, 1));
						
						ControlSum = ControlSum + Digit * Multiplier;
						
					EndDo;
					
					CheckDigit = (ControlSum %11) %10;
					
					If Not CheckDigit = Number(Mid(INN, 10, 1)) Тогда
						
						Cancel = True;
						
						UserMessage			= New UserMessage;
						UserMessage.Text	= NStr("en = 'The control number for the INN does not coincide with the calculated'; ru = 'Контрольное число для ИНН не совпадает с рассчитанным'");
						
						UserMessage.Message();
						
					EndIf;
					
				Else 
					
					ControlSum11 = 0;
					ControlSum12 = 0;
					
					For N = 1 To 11 Do 
					
						// Расчет множителя для 11-го и 12-го разрядов
						If N = 1 Then
							Multiplier11 = 7;
							Multiplier12 = 3;
						ElsIf N = 2 Then
							Multiplier11 = 2;
							Multiplier12 = 7;
						ElsIf N = 3 Then
							Multiplier11 = 4;
							Multiplier12 = 2;
						ElsIf N = 4 Then
							Multiplier11 = 10;
							Multiplier12 = 4;
						ElsIf N = 5 Then
							Multiplier11 = 3;
							Multiplier12 = 10;
						ElsIf N = 6 Then
							Multiplier11 = 5;
							Multiplier12 = 3;
						ElsIf N = 7 Then
							Multiplier11 = 9;
							Multiplier12 = 5;
						ElsIf N = 8 Then
							Multiplier11 = 4;
							Multiplier12 = 9;
						ElsIf N = 9 Then
							Multiplier11 = 6;
							Multiplier12 = 4;
						ElsIf N = 10 Then
							Multiplier11 = 8;
							Multiplier12 = 6;
						ElsIf N = 11 Then
							Multiplier11 = 0;
							Multiplier12 = 8;
						EndIf;
						
						Digit = Number(Mid(INN, N, 1));
						
						ControlSum11 = ControlSum11 + Digit * Multiplier11;
						ControlSum12 = ControlSum12 + Digit * Multiplier12;
						
					EndDo;
					
					CheckDigit11 = (ControlSum11 %11) %10;
					CheckDigit12 = (ControlSum12 %11) %10;
					
					If Not CheckDigit11 = Number(Mid(INN,11,1)) Or Not CheckDigit12 = Number(Mid(INN,12,1)) Then 
						
						Cancel = True;
						
						UserMessage			= New UserMessage;
						UserMessage.Text	= NStr("en = 'The control number for the INN does not coincide with the calculated'; ru = 'Контрольное число для ИНН не совпадает с рассчитанным'");
						
						UserMessage.Message();
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		// Выполнить валидацию КПП
		If ValueIsFilled(Object.KPP) Then 
			
			KPP			= TrimAll(Object.KPP);
			KPP_Lenght	= StrLen(KPP);
			
			If Not KPP_Lenght = 9 Then 
				
				Cancel = True;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en = 'KPP shall consist of 9 digits'; ru = 'КПП должен состоять из 9 цифр'");
				
				UserMessage.Message();
				
			EndIf;
			
			If Not СтроковыеФункцииКлиентСервер.ТолькоЦифрыВСтроке(KPP) And Not Cancel Then 
				
				Cancel = True;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en = 'KPP shall consist only of digits'; ru = 'КПП должен состоять только из цифр'");
				
				UserMessage.Message();
				
			КонецЕсли;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#Region Regions

&AtClient
Procedure RegionsBeforeCollapse(Item, Row, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure RegionsOnActivateRow(Item)
	
	CurrentData = ThisForm.Items.Regions.CurrentData;
	
	CurrentRegion = ?(CurrentData = Undefined, Undefined, CurrentData.Region);
	
	Filter = New FixedStructure("Region", CurrentRegion);
	ThisForm.Items.Territories.RowFilter = ?(ThisForm.Items.ShowAllTerritories.Check, Undefined, Filter);
	
	ThisForm.CurrentRegion = CurrentRegion;
	
	ThisForm.Items.Territories.Refresh();
	
EndProcedure

&AtClient
Procedure RegionsUseOnChange(Item)
	
	CurrentData = ThisForm.Items.Regions.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		If Not CurrentData.Use Then
		
			Filter = New Structure;
			Filter.Insert("Region", CurrentData.Region);
			
			TerritoriesRows = ThisForm.Territories.FindRows(Filter);
			
			For Each Row In TerritoriesRows Do
				
				Row.Use = False;
				
			EndDo;
			
			Filter = New Structure("Region", CurrentData.Region);
			RowsToDelete = ThisForm.Object.Regions.FindRows(Filter);
			For Each Row In RowsToDelete Do
				
				ThisForm.Object.Regions.Delete(Row);
				
			EndDo;
			
		Else
			
			NewRow = ThisForm.Object.Regions.Add();
			NewRow.Region = CurrentData.Region;
			
		EndIf;
		
	EndIf;
	
	ThisForm.RefreshDataRepresentation();
	
EndProcedure

#EndRegion

#Region Territories

&AtClient
Procedure CheckTerritories(Value)
	
	CurrentData = ThisForm.Items.Regions.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		If CurrentData.Use Then
		
			Filter = New Structure;
			Filter.Insert("Region", CurrentData.Region);
			
			Rows = ThisForm.Territories.FindRows(Filter);
			
			For Each Row In Rows Do
				
				Row.Use = Value;
				Modified = True;
				
				Filter = New Structure("Territory", Row.Territory);
				
				If Value = True Then
				
					If ThisForm.Object.Territories.FindRows(Filter).Count() = 0 Then
						
						NewRow = ThisForm.Object.Territories.Add();
						NewRow.Territory = Row.Territory;
						
					EndIf;
					
				Else
					
					RowsToDelete = ThisForm.Object.Territories.FindRows(Filter);
					
					For Each RowToDelete In RowsToDelete Do
						
						ThisForm.Object.Territories.Delete(RowToDelete);
						
					EndDo;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TerritoriesUseOnChange(Item)
	
	CurrentData = ThisForm.Items.Territories.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		If CurrentData.Use Then
			
			NewRow = ThisForm.Object.Territories.Add();
			NewRow.Territory = CurrentData.Territory;
			
		Else
			
			Filter = New Structure("Territory", CurrentData.Territory);
			RowsToDelete = ThisForm.Object.Territories.FindRows(Filter);
			
			For Each Row In RowsToDelete Do
				
				ThisForm.Object.Territories.Delete(Row);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Commands

&AtClient
Procedure CheckAllTerritories(Command)
	
	CheckTerritories(True);
	
EndProcedure

&AtClient
Procedure UncheckAllTerritories(Command)
	
	CheckTerritories(False);
	
EndProcedure

&AtClient
Procedure ShowAllTerritories(Command)
	
	ThisForm.Items.ShowAllTerritories.Check = Not ThisForm.Items.ShowAllTerritories.Check;
	ShowAll = ThisForm.Items.ShowAllTerritories.Check;
	CurrentData = ThisForm.Items.Regions.CurrentData;
	RegionSelected = Not CurrentData = Undefined;
	ThisForm.Items.Territories.RowFilter = ?(ShowAll AND RegionSelected, Undefined, New FixedStructure("Region", ThisForm.Items.Regions.CurrentData.Region));
	
	CurrentData = ThisForm.Items.Regions.CurrentData;
	
	If Not CurrentData = Undefined Then
		
		CurrentRegion = CurrentData.Region;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

#EndRegion

#EndRegion