
///////////////////////////////////////////////////////
// Common procedure and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StringNumber = Parameters.StringNumber;
	OutletParameter = Parameters.OutletParameter;
	PreviousValue = Parameters.PreviousValue;
	
	DataType = GetStringFromEnumValue("DataType", Parameters.OutletParameter.DataType);
	
	ThisForm[DataType] = PreviousValue;
	
	Items[DataType].Visible = True;
	
EndProcedure

&AtServerNoContext
Function GetStringFromEnumValue(Enum, Value)
	
	IndexOfValue = Enums[Enum].IndexOf(Value);
	
	Return Metadata.Enums[Enum].EnumValues[IndexOfValue].Name;
	
EndFunction

&AtServer
Function GetParametersList()
	
	List = new ValueList;
	
	Table = OutletParameter.ValueList.Unload();
	
	For Each Row In Table Do
		
		List.Add(Row.Value);
		
	EndDo;
	
	Return List;
	
EndFunction

///////////////////////////////////////////////////////
// User interface

&AtClient
Procedure Ok(Command)
	
	If ThisForm[DataType] = PreviousValue Then
		
		Close();
		
	Else
		
		ReturnStructure = New Structure;
		ReturnStructure.Insert("StringNumber", StringNumber);
		ReturnStructure.Insert("Str",  ThisForm[DataType]);
		
		Close(ReturnStructure);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueListStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowChooseFromList(New NotifyDescription("VListChoiceProcessing", ThisForm), GetParametersList(), Item, );
	
EndProcedure

&AtClient
Procedure ValueListStartListChoice(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowChooseFromList(New NotifyDescription("VListChoiceProcessing", ThisForm), GetParametersList(), Item, );
	
EndProcedure

&AtClient
Procedure VListChoiceProcessing(Result, AdditionalParameter) Export
	
	If Not Result = Undefined Then 
		
		ValueList = Result;
		
	EndIf;	
	
EndProcedure	

&AtClient
Procedure BoolStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	List = new ValueList;
	List.Add(NStr("en='Yes';ru='Да';cz='Ano'"));
	List.Add(NStr("en='No';ru='Нет';cz='No'"));
	
	ShowChooseFromList(New NotifyDescription("BoolChoiceProcessing", ThisForm), List, Item, );
	
EndProcedure

&AtClient
Procedure BoolChoiceProcessing(Result, AdditionalParameter) Export
	
	If Not Result = Undefined Then 
		
		Boolean = Result;
		
	EndIf;
	
EndProcedure



