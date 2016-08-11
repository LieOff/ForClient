
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Maps.AddMap(ThisForm, , , Constants.DefaultCity.Get());
	
	If Parameters.Property("Date") Then
		
		Date = BegOfDay(Parameters.Date);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DetachInitMapAction()
	
	Items.Map.SetAction("DocumentComplete", "");
	
EndProcedure

&AtServer
Function GetMarkers(Outlets)
	
	Array = New Array;
	
	For Each Row In Outlets Do
		
		If Row.Date >= BegOfDay(Date) And Row.Date <= EndOfDay(Date) Then
			
			SetPrivilegedMode(True);
			
			Lat = Row.Outlet.Lattitude;
			Lng = Row.Outlet.Longitude;
			
			If Lat > 0 And Lng > 0 Then
				
				Coordinates = Maps.GetCoordinates(Lat, Lng);
				Coordinates.Insert("Description", "<center><b>Торговая точка: </b>" + Row.Outlet.Description + "</center>");
				Coordinates.Insert("FullInfo", "<p><b>Наименование: </b><a href='' class='outlet' id='" + Row.Outlet.UUID() + "'>" + Row.Outlet.Description + "</a></p><p><b>Адрес: </b>" + Row.Outlet.Address + "</p><p><b>Тип: </b>" + Row.Outlet.Type + "</p><p><b>Класс: </b>" + Row.Outlet.Class + "</p>");
				Array.Add(Coordinates);
				
			EndIf;
			
			SetPrivilegedMode(False);
			
		EndIf;
		
	EndDo;
	
	Return Array;
	
EndFunction

&AtServer
Function GetPaths(Outlets)
	
	Array = New Array;
	
	For Each Row In Outlets Do
		
		If Row.Date >= BegOfDay(Date) And Row.Date <= EndOfDay(Date) Then
			
			If Not Row.Date = BegOfDay(Date) Then
				
				Lat = Row.Outlet.Lattitude;
				Lng = Row.Outlet.Longitude;
				
				Array.Add(Maps.GetCoordinates(Lat, Lng));
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Array;
	
EndFunction

&AtClient
Procedure InitMap(Item)
	
	DetachInitMapAction();
	
	InitMapBool = True;
	
	ShowMarkers();
	
EndProcedure

&AtClient
Procedure ShowMarkers()
	
	Maps.ClearMarkers(ThisForm);
	Maps.ClearPathCoordinates(ThisForm);
	Maps.ClearPath(ThisForm);
	
	Outlets = ThisForm.FormOwner.Object.Outlets;
	Outlets.Sort("Date");
	
	Markers = GetMarkers(Outlets);
	
	For Each Marker In Markers Do
		
		Maps.AddMarker(ThisForm, Marker);
		
	EndDo;
	
	Paths = GetPaths(Outlets);
	
	For Each Path In Paths Do
		
		Maps.AddPathCoordinates(ThisForm, Path);
		
	EndDo;
	
	Maps.ShowPath(ThisForm);
	
	If Markers.Count() > 0 And Not InitMapBool Then
		
		Maps.SetMapCenter(ThisForm, Markers[0]);
		
	EndIf;
	
	InitMapBool = False;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	ShowMarkers();
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If ValueIsFilled(Date) Then
		
		Date = BegOfDay(BegOfDay(Date) - 1);
		ShowMarkers();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Forward(Command)
	
	If ValueIsFilled(Date) Then
		
		Date = EndOfDay(Date) + 1;
		ShowMarkers();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnMapClick(Item, EventData, StandardProcessing)
	
	IsOutlet = EventData.Element.className = "outlet";
	StandardProcessing = Not IsOutlet;
	
	If IsOutlet Then
		
		ShowValue(,GetOutletRef(EventData.Element.Id));
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetOutletRef(UUID)
	
	Return Catalogs.Outlet.GetRef(New UUID(UUID));
	
EndFunction
