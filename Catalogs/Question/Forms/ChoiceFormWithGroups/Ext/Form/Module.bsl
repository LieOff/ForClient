
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.QuestionType = Enums.QuestionGroupTypes.EmptyRef() Then 
		
		FilterElement 					= List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue 		= New DataCompositionField("Owner.Type");
		FilterElement.Use 				= True;
		FilterElement.ComparisonType	= DataCompositionComparisonType.Equal;
		FilterElement.ViewMode			= DataCompositionSettingsItemViewMode.Inaccessible;
		FilterElement.RightValue 		= Parameters.QuestionType;
		
	EndIf;
	
EndProcedure
