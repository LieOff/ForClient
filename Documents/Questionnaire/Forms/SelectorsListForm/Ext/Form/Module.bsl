
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StringNumber 	= Parameters.StringNumber;
    Selector 		= Parameters.Selector;
    DataType 		= Parameters.DataType;
    OutletParameter = Parameters.OutletParameter;
	Source			= Parameters.Source;
	
    If TypeOf(Parameters.CurrentValue) = Type("ValueList") Then
		
		For Each Element In Parameters.CurrentValue Do
			
			AddRow = Values.Add();
			AddRow.ValueRow = Element.Value;
			
		EndDo;
		
	EndIf;
	If Selector = "Catalog_OutletParameter" Then
		ThisForm.Items.ValuesTableSelect.Visible = False;
	EndIf;
    
EndProcedure

&AtServer
Function IsOutletParameter(Value)
    
    If Value = "Catalog_OutletParameter" Then
		
		Return True;
		
	Else
		
		Return False;    	    
		
	EndIf; 
    
EndFunction

#EndRegion

#Region UserInterface

&AtClient
Procedure Ok(Command)

    List = new ValueList;
	
	For Each Element In Values Do
		
		List.Add(Element.ValueRow);    	    
		
	EndDo;

    ReturnStructure = New Structure("StringNumber, List", StringNumber, List);    
	
	Notify(Source, ReturnStructure, ThisForm);
	
	Close();
	
EndProcedure

&AtClient
Procedure ValuesValueRowStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not IsOutletParameter(Selector) Then
		
		Str = StrReplace(Selector, "_", ".");
        OpenForm(Str + ".ChoiceForm", , Item, , , , , FormWindowOpeningMode.LockWholeInterface);    	    
		
	Else
		
		OpenForm("Document.Questionnaire.Form.Input", New Structure("StringNumber, DataType, OutletParameter, Source, CurrentValue", Items.ValuesTable.CurrentData.GetID(), DataType, OutletParameter, "ListForm", Items.ValuesTable.CurrentData.ValueRow));                
		
	EndIf;    
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ListForm" Then                       
		
		Items.ValuesTable.CurrentData.ValueRow = Parameter.Str;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ValuesTableBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If Not CancelEdit Then 
	
		If Not ValueIsFilled(Items.ValuesTable.CurrentData.ValueRow) Then 
			
			Message(NStr("en='Value is not selected';ru='Значение не выбрано';cz='Nebyla zvolena žádná hodnota'"));
			
			Cancel = True;
			
		EndIf;
		
	EndIf;
		
EndProcedure

&AtClient
Procedure Select(Command)
	NewString=Items.ValuesTable;
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("CloseOnOwnerClose", True);
	ParametrsForm=New Structure("ChoiceMode", True);
	ParametrsForm=New Structure("CloseOnChoice", False);
	If Selector = "Catalog_Region" Then
		OpenForm("Catalog.Region.ChoiceForm",ParametrsForm, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);	
	EndIf;
	If Selector = "Catalog_Outlet" Then
		OpenForm("Catalog.Outlet.ChoiceForm",ParametrsForm, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Enum_OutletStatus" Then
		OpenForm("Enum.OutletStatus.ChoiceForm",ParametrsForm, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_OutletType" Then
		OpenForm("Catalog.OutletType.ChoiceForm",ParametrsForm, NewString, , , , , FormWindowOpeningMode.Independent);
	EndIf;
	If Selector = "Catalog_OutletClass" Then
		OpenForm("Catalog.OutletClass.ChoiceForm",ParametrsForm, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_Distributor" Then
		OpenForm("Catalog.Distributor.ChoiceForm",ParametrsForm, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_Territory" Then
		OpenForm("Catalog.Territory.ChoiceForm",ParametrsForm, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_Positions" Then
		OpenForm("Catalog.Positions.ChoiceForm",ParametrsForm, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
//	If Selector = "Catalog_OutletParameter" Then
//		OpenForm("Catalog.OutletParameter.ChoiceForm",ParametrsForm, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
//	EndIf;
	
EndProcedure

&AtClient
Procedure ValuesTableChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	Coincidence=False;
	For Each Row In Values Do
		If SelectedValue=Row.ValueRow Then
			Coincidence=True;	
		EndIf;
	EndDo;
	If Not(Coincidence) Then
	NewString=Values.Add();
	NewString.ValueRow=SelectedValue;
	EndIf;
	// Вставить содержимое обработчика.
EndProcedure

&AtClient
Procedure AddValue(Command)
	NewString=Items.ValuesTable;
	If Selector = "Catalog_Region" Then
		OpenForm("Catalog.Region.ChoiceForm",, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);	
	EndIf;
	If Selector = "Catalog_Outlet" Then
		OpenForm("Catalog.Outlet.ChoiceForm",, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Enum_OutletStatus" Then
		OpenForm("Enum.OutletStatus.ChoiceForm",, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_OutletType" Then
		OpenForm("Catalog.OutletType.ChoiceForm",, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_OutletClass" Then
		OpenForm("Catalog.OutletClass.ChoiceForm",, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_Distributor" Then
		OpenForm("Catalog.Distributor.ChoiceForm",, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_Territory" Then
		OpenForm("Catalog.Territory.ChoiceForm",, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_Positions" Then
		OpenForm("Catalog.Positions.ChoiceForm",, NewString, , , , , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	If Selector = "Catalog_OutletParameter" Then
		InputFormParameters = New Structure;
		InputFormParameters.Insert("StringNumber", 0);
		InputFormParameters.Insert("OutletParameter", OutletParameter);
		InputFormParameters.Insert("PreviousValue", "");

		OpenForm("CommonForm.OutletParameterValueInputForm",InputFormParameters, ThisForm, , , ,New NotifyDescription("OutletParameterValueInputProcessing", ThisForm) , FormWindowOpeningMode.LockWholeInterface);
	EndIf;
EndProcedure
&AtClient
Procedure OutletParameterValueInputProcessing(Result, AdditionalParameter) Export
	
	If Result = Undefined Then
		
//		Items.Parameters.EndEditRow(True);
		
	Else
		
		ObjectRow = ThisForm.Values.Add();
		ObjectRow.ValueRow = Result.Str;
//		ObjectRow.Value = Result.Str;
//		ObjectRow.Presentation = ObjectRow.Value;
		
//		Items.Parameters.EndEditRow(False);
		
//		Modified = True;
		
	EndIf;
	
EndProcedure 
#EndRegion