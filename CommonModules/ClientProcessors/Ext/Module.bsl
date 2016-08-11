
Function UniqueRows(RequestMap) Export
	
	ParametersFilter = New Structure(RequestMap.Get("pName"), RequestMap.Get("checkingItem")[RequestMap.Get("pName")]);
	
	FoundRows = RequestMap.Get("tabularSection").FindRows(ParametersFilter);
	
	If FoundRows.Count() > 1 Then
		
		RequestMap.Get("tabularSection").Delete(RequestMap.Get("checkingItem").LineNumber - 1);
		Message(NStr("en=""Key isnt't unique. Position couldn't be added."";ru='Ключ не уникален. Позиция не может быть добавлена.';cz=""Key isnt't unique. Position couldn't be added."""));
		
		Return False;
		
	Else 
		
		Return True;
		
	EndIf;
	
EndFunction

Function CheckEmptyTS(CheckMap) Export 
	
	CancelMap = New Map;
	
	For Each Row In CheckMap Do
		
		If Row.Key = 0 Then
			
			Message(NStr("en=""The tabular section can't be clear."";ru='Табличная часть не может быть пустой';cz=""The tabular section can't be clear."""));
			
			CancelMap.Insert("cancelValue", True);
			CancelMap.Insert("showPage", Row.Value);
			
			Return CancelMap;
		EndIf;
		
	EndDo;
	
	CancelMap.Insert("cancelValue", False);
	
	Return CancelMap;
	
EndFunction

#Region ValueTreeCheckBoxes

Procedure SetValueTreeCheckBoxes(ValueTreeRowItems, CheckBoxColumnNamesArray) Export
	
	For Each Row In ValueTreeRowItems Do
		
		If Row.GetItems().Count() = 0 Then
			
			ChangeRowCheckBoxes(Row, CheckBoxColumnNamesArray);
			
		Else
			
			SetValueTreeCheckBoxes(Row.GetItems(), CheckBoxColumnNamesArray);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ChangeRowCheckBoxes(CurrentRowData, CheckBoxColumnNamesArray) Export
	
	For Each CheckBoxColumnName In CheckBoxColumnNamesArray Do 
	
		If CurrentRowData[CheckBoxColumnName] = 2 Then
			
			CurrentRowData[CheckBoxColumnName] = 0;
			
		EndIf;
		
		SetCheckBoxes(CurrentRowData, CheckBoxColumnName, CurrentRowData[CheckBoxColumnName]);
		
		Parent = CurrentRowData.GetParent();
		
		TempCurrentRowData = CurrentRowData;
		
		While Parent <> Undefined Do
			
			Parent[CheckBoxColumnName] = ?(IsSetForAll(TempCurrentRowData, CheckBoxColumnName), TempCurrentRowData[CheckBoxColumnName], 2);
			TempCurrentRowData = TempCurrentRowData.GetParent();
			Parent = TempCurrentRowData.GetParent();
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure SetCheckBoxes(CurrentRowData, CheckBoxColumnName, Value)
	
	For Each Row In CurrentRowData.GetItems() Do
		
		Row[CheckBoxColumnName] = Value;
		SetCheckBoxes(Row, CheckBoxColumnName, Row[CheckBoxColumnName]);
		
	EndDo;
	
EndProcedure

Function IsSetForAll(CurrentRowData, CheckBoxColumnName)
	
	For Each Row In CurrentRowData.GetParent().GetItems() Do
		
		If Row[CheckBoxColumnName] <> CurrentRowData[CheckBoxColumnName] Then
			
			Return False;
			
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

