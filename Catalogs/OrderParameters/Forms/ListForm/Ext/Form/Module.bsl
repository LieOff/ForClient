
&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	FlagName = Item.CurrentItem.Name;
	CurrentData = Item.CurrentData;
	
	If FlagName = "VisibleInMA" OR FlagName = "EditableInMA" Then
		
		Cancel = True;
		
		ParameterRef = Item.CurrentRow;
		
		If FlagName = "VisibleInMA" Then
			
			If NOT CurrentData.VisibleInMA Then
				
				ChangeFlag("VisibleInMA", ParameterRef);
				
			Else
				
				ChangeFlag("VisibleInMA", ParameterRef);
				
				If CurrentData.EditableInMA Then
					
					ChangeFlag("EditableInMA", ParameterRef);
					
				EndIf;
				
			EndIf;
			
		ElsIf FlagName = "EditableInMA" Then
			
			If CurrentData.VisibleInMA Then
				
				ChangeFlag("EditableInMA", ParameterRef);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure ChangeFlag(FlagName, ParameterRef)
	
	ParameterObject = ParameterRef.GetObject();
	ParameterObject[FlagName] = Not ParameterObject[FlagName];
	ParameterObject.Write();
	
EndProcedure