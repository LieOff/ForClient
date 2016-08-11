
#Region CommonProcedureAndFunctions

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If IsInRole("User") And Not ValueIsFilled(CurrentObject.Parent) Then 
		
		Cancel = True;
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='Creating a top-level regions is available only to administrators';ru='Создание регионов верхнего уровня доступно только администраторам';cz='Creating a top-level regions is available only to administrators'");
		
		UserMessage.Message();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure

#EndRegion

&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure
