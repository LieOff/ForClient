
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ThisForm.Items.ValueListValue.TypeRestriction = Parameters.FieldValueType;
	ThisForm.TypeDescription = Parameters.FieldValueType;
	
EndProcedure

&AtServerNoContext
Function GetName(Ref)
	
	Return Ref.Metadata().FullName();
	
EndFunction

#EndRegion

#Region UserInterface

&AtClient
Procedure OpenChoiceForm(FormParameters, FormOwner)
	
	Type = ThisForm.TypeDescription.Types()[0];
	TypeRef = New(Type);
	ObjectName = GetName(TypeRef);
	
	For Each Row In ThisForm.Filter Do
		
		If Find(Row.FilterName, "Filter.") Then
			
			FormParameters.Insert(Right(Row.FilterName, StrLen(Row.FilterName) - StrLen("Filter.")), Row.Value);
			
		Else
			
			FormParameters.Insert(Row.FilterName, Row.Value);
			
		EndIf;
		
	EndDo;
	
	OpenForm(ObjectName + ".ChoiceForm", FormParameters, FormOwner, , , , , FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure ValueListValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", True);
	FormParameters.Insert("CloseOnOwnerClose", True);
	OpenChoiceForm(FormParameters, Item);
	
EndProcedure

&AtClient
Procedure ValueListChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	StandardProcessing = False;
	
	ValueList.Add(SelectedValue);
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("CloseOnOwnerClose", True);
	OpenChoiceForm(FormParameters, ThisForm.Items.ValueList);
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	NotifyChoice(ThisForm.ValueList);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion