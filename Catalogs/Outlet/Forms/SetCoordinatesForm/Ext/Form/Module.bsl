
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AddresOutl") Then 
		If ValueIsFilled(Parameters.AddresOutl) Then
			Maps.AddMap(ThisForm, , True, Parameters.AddresOutl);
			Address=Parameters.AddresOutl;
		Else 
			Maps.AddMap(ThisForm, , True, Constants.DefaultCity.Get());
		EndIf;
	Else
		Maps.AddMap(ThisForm, , True, Constants.DefaultCity.Get());		
	EndIf;

	Latitude = Parameters.Latitude;
	Longitude = Parameters.Longitude;
	
EndProcedure

&AtClient
Procedure SetCoordinates(Command)
	
	Coordinates = Maps.GetLastMarkerCoordinates(ThisForm);
	
	Change = False;
	
	If Not (Coordinates.Latitude = "" And Coordinates.Longitude = "") Then
		
		Close(Maps.GetLastMarkerCoordinates(ThisForm));
		
	Else
		
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Change=False;
	Close();
	
EndProcedure

&AtClient
Procedure InitMap(Item)
	
	DetachInitMapAction();
	
	//Maps.SetMapCenter(ThisForm, Maps.GetCoordinates(Latitude, Longitude));
	Maps.AddInitialMarker(ThisForm, Maps.GetCoordinates(Latitude, Longitude));
	
	SetSetCoordinatesAvailability();
	
EndProcedure

&AtClient
Procedure SetSetCoordinatesAvailability()
	
	Coordinates = Maps.GetLastMarkerCoordinates(ThisForm);
	HasMarker = Not (Coordinates.Latitude = "" And Coordinates.Longitude = "");
	Items.FormSetCoordinates.Enabled = HasMarker;
	If HasMarker Then
		If Round(Number(Coordinates.Latitude),3)<>Round(Latitude,3) Or Round(Number(Coordinates.Longitude),3)<> Round(Longitude,3) Then
			Change=True;	
		EndIf;
	EndIf;		
		
EndProcedure

&AtClient
Procedure OnMapClick(Item)
	
	SetSetCoordinatesAvailability();
	
	
EndProcedure

&AtServer
Procedure DetachInitMapAction()
	
	Items.Map.SetAction("DocumentComplete", "");
	
EndProcedure

&AtClient
Procedure AddressOnChange(Item)
	
	Maps.AddMarkerOnAddress(ThisForm, Address);
	SetSetCoordinatesAvailability()
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Change Then 
		Cancel = True;
		ShowQueryBox(New NotifyDescription("CheckAnswerWrite",ThisObject),
		NStr("en = 'Do you want save coordinats?'; ru = 'Вы хотите записать координаты?'"),
		QuestionDialogMode.YesNoCancel); 
	EndIf;
	
EndProcedure
&AtClient
Procedure CheckAnswerWrite(ResultQuestion,AdditionalParametrs) Export 
		
	If ResultQuestion = DialogReturnCode.Cancel Then 	
	ElsIf ResultQuestion = DialogReturnCode.Yes then
		Change = False;
		Close(Maps.GetLastMarkerCoordinates(ThisForm));
	ElsIf  ResultQuestion = DialogReturnCode.No Then 
		Change = False;
		Close();		
	EndIf;
	
EndProcedure
