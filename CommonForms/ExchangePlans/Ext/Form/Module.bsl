
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	For Each ExPlan In Metadata.ExchangePlans Do 
		
		Ins				= ExchangePlans.Add();
		Ins.PlanName	= ExPlan.Name;
		Ins.PlanSynonym	= ExPlan.Synonym;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure ExchangePlansSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Not Items.ExchangePlans.CurrentData = Undefined Then 
		
		If ValueIsFilled(Items.ExchangePlans.CurrentData.PlanName) Then
			
			OpenForm("ExchangePlan." + Items.ExchangePlans.CurrentData.PlanName + ".ФормаСписка");
			
		КонецЕсли;
		
	КонецЕсли;
	
EndProcedure

#EndRegion

