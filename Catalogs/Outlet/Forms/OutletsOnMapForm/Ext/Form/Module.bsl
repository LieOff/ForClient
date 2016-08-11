
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Maps.AddMap(ThisForm, Items.GroupMap, , Constants.DefaultCity.Get());
	Scheme=Catalogs.Outlet.GetTemplate("MainDataCompositionSchema");
	Settings=Scheme.DefaultSettings;
	SettingComp = New DataCompositionSettingsComposer;
	SchemeOr=PutToTempStorage(Scheme,New UUID());
	SettingComp.Initialize(New DataCompositionAvailableSettingsSource(SchemeOr));
	SettingComp.LoadSettings(Settings);

EndProcedure

&AtClient
Procedure Show(Command)
	
	Maps.ClearMarkers(ThisForm);
	
	Markers = ShowServer();
	
	For Each Element In Markers Do
		
		Maps.AddMarker(ThisForm, Element);
		
	EndDo;
	
	If Markers.Count() > 0 Then
		
		Maps.SetMapCenter(ThisForm, Markers[0]);
		
	EndIf;
	
EndProcedure

&AtServer
Function ShowServer()
	
	Scheme=Catalogs.Outlet.GetTemplate("MainDataCompositionSchema");
	Settings=SettingComp.GetSettings();
	Composer = New DataCompositionTemplateComposer();
	Template = Composer.Execute(Scheme, Settings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	Processor = New DataCompositionProcessor;
	Processor.Initialize(Template);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor; // DataCompositionResultValueCollectionOutputProcessor;
	VT = New ValueTable;
	OutputProcessor.SetObject(VT);
	
	Result = OutputProcessor.Output(Processor);
	Result.GroupBy("Lattitude,Longitude,Ref");	
	Array = New Array;
	
	For Each Row In Result Do
		
		If Not (Row.Lattitude = 0 And Row.Longitude = 0) Then
			
			Coordinates = Maps.GetCoordinates(Row.Lattitude, Row.Longitude);
			Coordinates.Insert("Description", "<center><b>Торговая точка: </b>" + Row.Ref.Description + "</center>");
			Coordinates.Insert("FullInfo", "<p><b>Наименование: </b><a href='' class='outlet' id='" + Row.Ref.UUID() + "'>" + Row.Ref.Description + "</a></p><p><b>Адрес: </b>" + Row.Ref.Address + "</p><p><b>Тип: </b>" + Row.Ref.Type + "</p><p><b>Класс: </b>" + Row.Ref.Class + "</p>");
			Array.Add(Coordinates);
			
		EndIf;
		
	EndDo;
	
	Return Array;
	
EndFunction

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
