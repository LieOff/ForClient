
Function SelectOutlets(SourceTable) Export 
	
	SetPrivilegedMode(True);
	
	OutletParametersMap = CreateOutletParametersMap();
	
	Query = New Query();
	
	// Убрать селекторы по позициям
	RowsToDelete = SourceTable.FindRows(New Structure("Selector", "Catalog_Positions"));
	
	For Each r In RowsToDelete Do
		
		SourceTable.Delete(r);
		
	EndDo;
	
	NewSourceTable = SourceTable.Copy();
	
	OutletParametersTable = SourceTable.Copy(New Structure("Selector", "Catalog_OutletParameter"));
	
	RowsToDelete = NewSourceTable.FindRows(New Structure("Selector", "Catalog_OutletParameter"));
	
	For Each Str In RowsToDelete Do
		
		NewSourceTable.Delete(Str);
		
	EndDo;
	
	TerritoryTable	= NewSourceTable.Copy(New Structure("Selector", "Catalog_Territory"));
	RegionTable		= NewSourceTable.Copy(new Structure("Selector", "Catalog_Region"));
	
	For Each Str In RegionTable Do
		
		Ins					= TerritoryTable.Add();
		Ins.Selector		= Str.Selector;
		Ins.ComparisonType	= Str.ComparisonType;
		Ins.Value			= Str.Value;
		
	EndDo;
	
	RowsToDelete = NewSourceTable.FindRows(new Structure("Selector", "Catalog_Territory"));
	
	For Each Str In RowsToDelete Do
		
		NewSourceTable.Delete(Str);
		
	EndDo;
	
	RowsToDelete = NewSourceTable.FindRows(new Structure("Selector", "Catalog_Region"));
	
	For Each Str In RowsToDelete Do
		
		NewSourceTable.Delete(Str);
		
	EndDo;
	
	SourceTable = NewSourceTable;
	
	// Outlet_Parameters
	ParametersString = "";
	
	i = 0;
	
	Skip = False;
	
	For Each Selector In OutletParametersTable Do
		
		If Not Skip Then
			
			ParametersString = ParametersString + CreateQueryString(i);
			
			Query.SetParameter(String("Parameter"+i), Selector.AdditionalParameter);
			
			If Selector.ComparisonType <> Enums.ComparisonType.InList Then
				
				ParametersString = ParametersString + "= &Value"+ i +" ";
				
				Query.SetParameter(String("Value" + i), Selector.Value);
				
			Else 
				
				ParametersString = ParametersString + " IN(";
				
				ListTable = OutletParametersTable.FindRows(New Structure("AdditionalParameter, ComparisonType", Selector.AdditionalParameter, Enums.ComparisonType.InList));
				
				c = 1;
				
				For Each ListItem In ListTable Do
					
					ParametersString = ParametersString + String(" &Value" + String(i) + String(c)) + ?(c <> ListTable.Count(), ", ", ") ");
					
					Query.SetParameter(String("Value" + String(i) + String(c)), ListItem.Value);
					
					c = c + 1;
					
				EndDo;
				
				EndOfList = ListItem;
				
				Skip = True;
				
			EndIf;
			
		EndIf; 
		
		if Selector = EndOfList Then
			
			Skip = False;
			
		EndIf;
		
		i = i + 1;
		
	EndDo;
	
	// Territories
	TerritoriesString = "";
	
	Skip = False;
	
	For Each Selector In TerritoryTable Do
		
		If Not Skip Then
			
			TerritoriesString = TerritoriesString + " INNER JOIN Catalog.Territory.Outlets AS T" + i + 
													" ON O.Ref = T" + i + ".Outlet AND T"+i+".Ref";
			
			If Selector.ComparisonType <> Enums.ComparisonType.InList Then
				
				If Selector.ComparisonType = Enums.ComparisonType.Equal Then  
					
					TerritoriesString = TerritoriesString + ?(Selector.Selector = "Catalog_Territory", "=&parameter" + i, ".Owner IN HIERARCHY(&parameter" + i + ") ");
					
				Else 
					
					TerritoriesString = TerritoriesString + ?(Selector.Selector = "Catalog_Territory", "<>&parameter" + i, ".Owner NOT IN HIERARCHY(&parameter" + i + ") ");
					
				EndIf;
				
				Query.SetParameter(String("parameter" + i), Selector.Value);
				
			Else 
				
				TerritoriesString = TerritoriesString + ?(Selector.Selector = "Catalog_Territory", " IN(", ".Owner IN HIERARCHY(");
				
				ListTable = TerritoryTable.FindRows(new Structure("Selector, ComparisonType", Selector.Selector, Enums.ComparisonType.InList));
				
				c = 1;
				
				For Each ListItem In ListTable Do
					
					TerritoriesString = TerritoriesString + String(" &parameter" + String(i) + String(c)) + ?(c <> ListTable.Count(), ", ", ") ");
					
					Query.SetParameter(String("parameter" + String(i) + String(c)), ListItem.Value);
					
					c = c + 1;
					
				EndDo;
				
				EndOfList = ListItem;
				
				Skip = True;
				
			EndIf;
			
		EndIf; 
		
		if Selector = EndOfList Then
			
			Skip = False;
			
		EndIf;
		
		i = i + 1;
		
	EndDo;
	
	string = ?(SourceTable.Count() > 0, " WHERE ", "");
	
	j = 1;
	
	Skip = False;
	
	For Each Selector In SourceTable Do
		
		If Not Skip Then
			
			String = String + " O." + outletParametersMap.Get(Selector.Selector);
			
			If Selector.ComparisonType <> Enums.ComparisonType.InList Then
				
				c = ?(Selector.ComparisonType = Enums.ComparisonType.Equal, " = ", " <> ");
				
				String = String + c + String(" &parameter" + i);
				
				Query.SetParameter(String("parameter" + i), Selector.Value);
				
			Else
				
				ListTable = SourceTable.FindRows(New Structure("Selector, ComparisonType", Selector.Selector, Enums.ComparisonType.InList));
				
				String = String + " IN( ";
				
				c = 1;
				
				For Each ListItem In ListTable Do
					
					String = String + String(" &parameter" + i + String(c)) + ?(c <> ListTable.Count(), ", ", ") ");
					
					Query.SetParameter(String("parameter" + i + String(c)), ListItem.Value);
					
					c = c + 1;
					
				EndDo;
				
				EndOfList = ListItem;
				
				Skip = True;
				
			EndIf;
			
		EndIf;
		
		if Selector = EndOfList Then
			
			Skip = False;
			
		EndIf;
		
		If j <> SourceTable.Count() AND Skip = False Then
			
			String = String + " AND ";
			
		EndIf;
		
		i = i + 1;
		j = j + 1;
		
	EndDo;
	
	Try
		
		Query.Text="SELECT ALLOWED DISTINCT O.Ref FROM Catalog.Outlet AS O " + ParametersString + TerritoriesString + String;
		
		Result = Query.Execute().Unload(); 
		
		Return Result;
		
	Except
		
		Result = New ValueTable;
		Result.Columns.Add("Ref");
		
		Return Result;
		
	EndTry;
	
EndFunction

Function CreateQueryString(sValue)
	
	String = " INNER JOIN Catalog.Outlet.Parameters AS OP" + sValue + "
	| ON O.Ref = OP" + sValue + ".Ref AND OP" + sValue + ".Parameter = &Parameter" + sValue + " AND OP" + sValue + ".Value ";          
	
	Return String;
	
EndFunction

Function CreateOutletParametersMap()
	
	sMap = new Map;
	
	For Each Item In Metadata.Enums.QuestionnaireSelectors.EnumValues Do
		
		If Item.Name = "Enum_OutletStatus" Then
			
			sMap.Insert(Item.Name, "OutletStatus");
			
		ElsIf Item.Name = "Catalog_OutletType" Then
			
			sMap.Insert(Item.Name, "Type");
			
		ElsIf Item.Name = "Catalog_OutletClass" Then
			
			sMap.Insert(Item.Name, "Class");
			
		ElsIf Item.Name = "Catalog_Distributor" Then
			
			sMap.Insert(Item.Name, "Distributor");
			
		ElsIf Item.Name = "Catalog_Outlet" Then
			
			sMap.Insert(Item.Name, "Ref");
			
		EndIf;
		
	EndDo;
	
	Return sMap;
	
EndFunction

Function SelectPositions(Positions) Export 

  	qPositions = new Query;
	
	String = ?(Positions.Count()=0, "", " WHERE ");
	
	Skip = False;
	
	i = 0;
	
	For Each Row In Positions Do
	
		If Skip = False Then
			
			If Not Row.ComparisonType = Enums.ComparisonType.InList Then
				
				c = ?(Row.ComparisonType = Enums.ComparisonType.Equal, " = ", " <> ");
				
				String = String + " Ref " + c +  " &Ref" + i;
				
				qPositions.SetParameter(String("Ref" + String(i)), Row.Value);
				
			Else
				
				String = String + " Ref IN(";
				
				ListTable = positions.FindRows(New Structure("ComparisonType", Enums.ComparisonType.InList));
				
				cs = 1;
				
				For Each ListItem In ListTable Do
					
					String = String + "&Ref" + i + String(cs) + ?(cs = ListTable.Count(), ") ", ", ");
					
					qPositions.SetParameter(String("Ref" + i + String(cs)), ListItem.Value);
					
					cs = cs + 1;
					
				EndDo;
				
				EndOfList = ListItem;
				
				Skip = True;
				
			EndIf;
			
		EndIf;
		
		If Row = EndOfList Then
			
			Skip = False;
			
		EndIf;
		
		i = i + 1;
		
	EndDo;
	
	Try
		
		qPositions.Text = "SELECT ALLOWED Ref AS Position FROM Catalog.Positions " + string;
		
		Return qPositions.Execute().Unload().UnloadColumn("Position");
		
	Except
		
		Return New Array;
		
	EndTry;
	
EndFunction

Function SelectSRs(SelectorsList, PositionList) Export 
	
	SetPrivilegedMode(True);
	
	PositionsEquals = PositionList.Find(Enums.ComparisonType.Equal, "ComparisonType");
	PositionsInList = PositionList.Find(Enums.ComparisonType.InList, "ComparisonType");
	
	NeedEmptyRef = True;
	
	If Not PositionsEquals = Undefined Then 
		
		NeedEmptyRef = False;
		
	EndIf;
	
	If Not PositionsInList = Undefined Then 
		
		NeedEmptyRef = False;
		
	EndIf;
	
	PositionsArray = SelectPositions(PositionList);
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED DISTINCT
	             |	TerritorySRs.SR AS SR
	             |FROM
	             |	Catalog.Territory.SRs AS TerritorySRs
	             |		INNER JOIN Catalog.Territory AS Territory
	             |		ON TerritorySRs.Ref = Territory.Ref
	             |		INNER JOIN Catalog.User AS User
	             |		ON TerritorySRs.SR = User.Ref";
	
	If PositionList.Count() = 0 And PositionsArray.Count() = 0 Then 
		
		Query.Text = Query.Text + " WHERE TRUE";
		
	Else 
		
		If NeedEmptyRef Then 
			
			Query.Text = Query.Text + " WHERE (User.Position IN (&PositionsArray) OR User.Position = VALUE(Catalog.Positions.EmptyRef))";
			
		Else 
			
			Query.Text = Query.Text + " WHERE User.Position IN (&PositionsArray)";
			
		EndIf;
		
		Query.SetParameter("PositionsArray", PositionsArray);
		
	EndIf;
	
	Ind = 0;
	
	TableRegionOr = SelectorsList.Copy(New Structure("Selector, ComparisonType", "Catalog_Region", Enums.ComparisonType.InList)); 
	
	If Not TableRegionOr.Count() = 0 Then 
		
		Query.Text = Query.Text + " AND (";
		
		For Each TableRegionOrElement In TableRegionOr Do 
			
			Query.Text = Query.Text + "Territory.Owner IN HIERARCHY(&parameter" + String(Ind) + ") OR "; 
			Query.SetParameter("parameter" + String(Ind), TableRegionOrElement.Value);
			
			Ind = Ind + 1;
			
		EndDo;
		
		Query.Text = Left(Query.Text, StrLen(Query.Text) - 4);
		
		Query.Text = Query.Text + ") ";
		
	EndIf;
	
	TableTerritoryOr = SelectorsList.Copy(New Structure("Selector, ComparisonType", "Catalog_Territory", Enums.ComparisonType.InList)); 
	
	If Not TableTerritoryOr.Count() = 0 Then 
		
		Query.Text = Query.Text + " AND (";
		
		For Each TableTerritoryOrElement In TableTerritoryOr Do 
			
			Query.Text = Query.Text + "Territory.Ref = &parameter" + String(Ind) + " OR "; 
			Query.SetParameter("parameter" + String(Ind), TableTerritoryOrElement.Value);
			
			Ind = Ind + 1;
			
		EndDo;
		
		Query.Text = Left(Query.Text, StrLen(Query.Text) - 4);
		
		Query.Text = Query.Text + ") ";
		
	EndIf;
	
	For Each SelectorElement In SelectorsList Do 
		
		If Not SelectorElement.ComparisonType = Enums.ComparisonType.InList Then 
		
			If SelectorElement.Selector = "Catalog_Region" Then 
				
				If SelectorElement.ComparisonType = Enums.ComparisonType.Equal Then 
					
					Query.Text = Query.Text + " AND Territory.Owner IN HIERARCHY(&parameter" + String(Ind) + ")"; 
					
				Else 
					
					Query.Text = Query.Text + " AND NOT Territory.Owner IN HIERARCHY(&parameter" + String(Ind) + ")";
					
				EndIf;
				
				Query.SetParameter("parameter" + String(Ind), SelectorElement.Value);
				
				Ind = Ind + 1;
				
			EndIf;
			
			If SelectorElement.Selector = "Catalog_Territory" Then 
				
				If SelectorElement.ComparisonType = Enums.ComparisonType.Equal Then
					
					Query.Text = Query.Text + " AND Territory.Ref = &parameter" + String(Ind); 
					
				Else 
					
					Query.Text = Query.Text + " AND Territory.Ref <> &parameter" + String(Ind);
					
				EndIf;
				
				Query.SetParameter("parameter" + String(Ind), SelectorElement.Value);
				
				Ind = Ind + 1;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ResultTable = Query.Execute().Unload();
	
	Return ResultTable;
	
EndFunction





