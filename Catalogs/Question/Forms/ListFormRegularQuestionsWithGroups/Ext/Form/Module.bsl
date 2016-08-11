
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseGroupFilter = True;
	
EndProcedure

&AtClient
Procedure GroupsListOnActivateRow(Item)
	
	If UseGroupFilter Then
	
		If Not Items.GroupsList.CurrentData = Undefined Then 
		
			FilterOfList = List.Filter;
			
			FilterElement = Undefined;
			
			Field = New DataCompositionField("Owner");
			
			For Each Element In FilterOfList.Items Do 
			
				If Element.LeftValue = Field Then 
					
					FilterElement = Element;			
					
				EndIf;		
				
			EndDo;
			
			If FilterElement = Undefined Then 
			
				FilterElement 				= FilterOfList.Items.Add(Type("DataCompositionFilterItem"));
				
			EndIf;
			
			FilterElement.LeftValue 	= Field;
			FilterElement.Use 			= True;
			FilterElement.ViewMode		= DataCompositionSettingsItemViewMode.Inaccessible;
			FilterElement.RightValue 	= Items.GroupsList.CurrentData.Ref;
			
		EndIf;
		
	EndIf;	
		
EndProcedure

&AtClient
Procedure UseGroupFilterOnChange(Item)
	
	If UseGroupFilter Then 
		
		GroupsListOnActivateRow(Items.GroupList);
		
	Else 
		
		FilterOfList = List.Filter;
			
		FilterElement = Undefined;
		
		Field = New DataCompositionField("Owner");
		
		For Each Element In FilterOfList.Items Do 
		
			If Element.LeftValue = Field Then 
				
				FilterElement = Element;			
				
			EndIf;		
			
		EndDo;
		
		If Not FilterElement = Undefined Then 
		
			FilterElement.Use = False;
			
		EndIf;
				
	EndIf;		
	
EndProcedure
