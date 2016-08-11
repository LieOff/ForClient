&AtServer
Function NotAllowed()
	
	If Object.DataType=Enums.DataType.ValueList AND Object.ValueList.Count()=0 Then
		
		Message(NStr("en=""Tabular section couldn't be empty!"";ru='Табличная часть не может быть пустой!';cz='Tabulkovб sekce nesmн bэt prбzdnб!'"));
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function  DataTypeOnChangeServer()
	
	Return Object.DataType = Enums.DataType.ValueList;
	
EndFunction

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
	Items.ValueList.Visible = NOT Object.ValueList.Count() = 0;
	Items.EditableInMA.ReadOnly = Not Object.VisibleInMA;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotAllowed() Then
		
		Cancel=True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DataTypeOnChange(Item)
	
	If DataTypeOnChangeServer() Then
		
		Items.ValueList.Visible = True;
		
	Else
		
		If Object.ValueList.Count() <> 0 Then
			
			Text = "en = ""The tabular section will be cleaned. 
			|Are you sure you want to continue?"";
			|ru = ""Табличная часть будет очищена.
			|Продолжить?""";
			OpenForm("CommonForm.DoQueryBox", New Structure("Text, Source", NStr(Text), "ClearParameters"));
			
		Else
			
			Items.ValueList.Visible = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure VisibleInMAOnChange(Item)
	
	If  NOT Object.VisibleInMA Then
		
		Object.EditableInMA = False;
		
	EndIf;
	
	Items.EditableInMA.ReadOnly = Not Object.VisibleInMA;
	
EndProcedure



