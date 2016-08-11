
///////////////////////////////////////////////////////
// Common procedure and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StringNumber 	= Parameters.StringNumber;
    OutletParameter = Parameters.OutletParameter;
    Source 			= Parameters.Source;
		
	If Parameters.DataType = "String" Then
		
		Items.Str.Visible 	= True;
		DataField 			= "Str";
		Str 				= Parameters.CurrentValue;
		
	EndIf;     
	
	If Parameters.DataType = "Integer" Then
		
		Items.Integer.Visible = True;
		
		DataField = "Integer";
		
		Integer = Parameters.CurrentValue;
		
	EndIf;     
	
	If Parameters.DataType = "Decimal" Then
		
		Items.Decimal.Visible = True;
		
		DataField = "Decimal";
		
		Decimal = Parameters.CurrentValue;
		
	EndIf;     
	
	If Parameters.DataType = "Boolean" Then
		
		Items.Bool.Visible = True;
		
		Bool = Parameters.CurrentValue;
		
	EndIf;     
	
	If Parameters.DataType = "Date time" Then
		
		Items.DateField.Visible = True;
		
		DateField = Parameters.CurrentValue;
		
	EndIf;     
	
	If Parameters.DataType = "Value list" Then
		
		Items.VList.Visible = True;
		
		VList = Parameters.CurrentValue; 
		
	EndIf;     

EndProcedure

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
    
    If ValueIsFilled(Str) Then     
		
		ReturnStructure = New Structure("StringNumber, Str", StringNumber, Str);    
        Notify(Source, ReturnStructure, ThisForm);        
		
	EndIf;
	
	If ValueIsFilled(Integer) Then
		
		ReturnStructure = New Structure("StringNumber, Str", StringNumber, Integer);    
        Notify(Source, ReturnStructure, ThisForm);    	    
		
	EndIf;
	
	If ValueIsFilled(Decimal) Then
		
		ReturnStructure = New Structure("StringNumber, Str", StringNumber, Decimal);    
        Notify(Source, ReturnStructure, ThisForm);    	    
		
	EndIf;
	
	If ValueIsFilled(Bool) Then
		
		ReturnStructure = New Structure("StringNumber, Str", StringNumber, Bool);    
        Notify(Source, ReturnStructure, ThisForm);    	    
		
	EndIf;
	
	If ValueIsFilled(DateField) Then
		
		ReturnStructure = New Structure("StringNumber, Str", StringNumber, DateField);    
        Notify(Source, ReturnStructure, ThisForm);    	    
		
	EndIf;
	
	If ValueIsFilled(VList) Then
		
		ReturnStructure = New Structure("StringNumber, Str", StringNumber, VList);    
        Notify(Source, ReturnStructure, ThisForm);    	    
		
	EndIf;
    
    Close();

EndProcedure

&AtClient
Procedure VListStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowChooseFromList(New NotifyDescription("VListChoiceProcessing", ThisForm), GetParametersList(), Item, );
	
EndProcedure

&AtClient
Procedure VListChoiceProcessing(Result, AdditionalParameter) Export
	
	If Not Result = Undefined Then 
		
		VList = Result;
		
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
		
		Bool = Result;
		
	EndIf;	
	
EndProcedure
