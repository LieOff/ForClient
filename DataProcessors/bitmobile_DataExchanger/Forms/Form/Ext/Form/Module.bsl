
#Region CommonProceduresAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(Object, DataProcessors.bitmobile_DataExchanger.GetSettings());
	
	Items.UseHTTPS.EditFormat = "BF=HTTP; BT=HTTPS";
	if NOT ValueIsFilled(Object.ExchangePlanName) then
		Object.ExchangePlanName = "bitmobile_УправлениеТорговлейСуперагент";
	endIf;
	Object.OutletClassDef = Constants.OutletCalssDef.Get();
	Object.OutletTypeDef = Constants.OutletTypeDef.Get();
	Object.SourceConfiguration = Constants.SourceConfigurationForExchange.Get();
EndProcedure

&AtServer
Procedure SaveSettingsServer()
	
	Constants.SourceConfigurationForExchange.Set(Object.SourceConfiguration);
	Constants.OutletTypeDef.Set(Object.OutletTypeDef);
	Constants.OutletCalssDef.Set(Object.OutletClassDef);
	SettingsStructure = DataProcessors.bitmobile_DataExchanger.GetEmptySettingsStructure();
	
	FillPropertyValues(SettingsStructure, Object);
	
	DataProcessors.bitmobile_DataExchanger.SetSettings(SettingsStructure);
	
	Modified = False;
	
EndProcedure

&AtServer
Procedure CheckConnectionServer()
	
	Connection = DataProcessors.bitmobile_DataExchanger.GetConnection();
	
	If Not Connection = Undefined Then
		
		Try
		
			Request = New HttpRequest(Object.PublicationName + "/odata/standard.odata");
			Result = Connection.Get(Request);
			
			Object.StatusCode = Result.StatusCode;
			
		Except
			
			Object.StatusCode = 1;
			
		EndTry;
		
	Else
		
		Object.StatusCode = 0;
		
	EndIf;
	
	If Object.StatusCode = 200 Then
		
		ThisForm.ConnectionStatus = NStr("en = 'Connection success'; ru = 'Соединение успешно'");
		
	Else
		
		ThisForm.ConnectionStatus = NStr("en = 'Connection failed'; ru = 'Ошибка соединения'");
		
		EndIf;
	
EndProcedure

&AtServer
Procedure SendSuccessMessageServer()
	
	Connection = DataProcessors.bitmobile_DataExchanger.GetConnection();
	
	If Not Connection = Undefined Then
		
		Request = New HTTPRequest(Object.PublicationName + "/odata/standard.odata/NotifyChangesReceived?DataExchangePoint='" + Object.CurrentExchangePlanNodeId + "'&MessageNo=" + Object.MessageNo);
		
		Result = Connection.Post(Request);
		
		If Result.StatusCode = 200 Then
			
			Object.MessageNo = Object.MessageNo + 1;
			SaveSettingsServer();
			
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure GetExchangePlanNodesAtServer()
	
	ThisForm.Items.ExchangePlanError.Title = "";
	
	Connection = DataProcessors.bitmobile_DataExchanger.GetConnection();
	
	If Not Connection = Undefined Then
		
		Request = New HTTPRequest(Object.PublicationName + "/odata/standard.odata/ExchangePlan_" + Object.ExchangePlanName);
		Result = Connection.Get(Request);
		
		If Result.StatusCode = 200 Then
			
			Body = Result.GetBodyAsString();
			
			XMLReader = New XMLReader;
			XMLReader.SetString(Body);
			
			Entries = New Array;
			
			While XMLReader.Read() Do
				
				If XMLReader.NodeType = XMLNodeType.StartElement AND XMLReader.Name = "entry" Then
					
					Entry = New Map;
					ReadEntry(XMLReader, Entry);
					Entries.Add(Entry);
					
				EndIf;
				
			EndDo;
			
			For Each Entry in Entries Do
				
				ExchangePlanRow = ExchangePlansVT.Add();
				ExchangePlanRow.Id = Entry["id"];
				ExchangePlanRow.Ref_Key = Entry["d:Ref_Key"];
				ExchangePlanRow.Description = Entry["d:Description"];
				
			EndDo;
			
		Else
			
			ThisForm.Items.ExchangePlanError.Title = NStr("en = 'Error'; ru = 'Ошибка'");
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadEntry(XMLReader, Entry)
	
	XMLReader.Read();
	
	WriteLogEvent("Загрузка УТ103.Тестирование получение узлов",,,,"Тип элемента " + XMLReader.NodeType + ", имя " + XMLReader.Name);	
	
	If XMLReader.NodeType = XMLNodeType.StartElement
	AND XMLReader.Name = "d:ГруппыНоменклатуры" then
	
		skipNode(XMLReader);	
	EndIf;
	
	If Not (XMLReader.NodeType = XMLNodeType.EndElement AND XMLReader.Name = "entry") Then
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			
			EntryKey = XMLReader.Name;
			XMLReader.Read();
			EntryValue = XMLReader.Value;
			Entry.Insert(EntryKey, EntryValue);
			
			WriteLogEvent("Загрузка УТ103.Тестирование получение узлов",,,,"имя " + EntryKey + " , значение " + EntryValue);	

		EndIf;
			
		ReadEntry(XMLReader, Entry);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure skipNode(XMLReader)
	counter = 1;
	while counter <> 0 do
		XMLReader.read();
		if XMLReader.NodeType = XMLNodeType.StartElement then
			counter = counter + 1;
		elsIf XMLReader.NodeType = XMLNodeType.EndElement then 
			counter = counter - 1;
		elsIf XMLReader.NodeType = XMLNodeType.None then
			//error case
			return;
		endIf;
	endDo;	
EndProcedure


&AtServer
Function GetObject(ObjectName, UUID)
	
	ObjectRef = Catalogs[ObjectName].GetRef(New UUID(UUID));
	Obj = ObjectRef.GetObject();
	
	If Obj = Undefined Then
		
		Obj = Catalogs[ObjectName].CreateItem();
		Obj.SetNewCode(ObjectRef);
		
	EndIf;
	
	Return Obj;
	
EndFunction

&AtServer
Procedure GetChangesServer() 
	
	FormAttributeToValue("Object").GetChanges();
	
EndProcedure

#EndRegion

#Region UserInterface

#Region Commands

&AtClient
Procedure CheckConnection(Command)
	
	SaveSettingsServer();
	
	If CheckFilling() Then
		
		CheckConnectionServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetChanges(Command)
	
	SaveSettingsServer();
	
	If CheckFilling() Then
		
		GetChangesServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetExchangePlanNodes(Command)
	
	ExchangePlansVT.Clear();
	
	If CheckExchangePlanSettingsFilling() Then
		
		GetExchangePlanNodesAtServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveSettings(Command)
	
	SaveSettingsServer();
	CheckFilling();
	
EndProcedure

#EndRegion

&AtClient
Procedure ExchangePlansSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentRow = ExchangePlansVT.FindByID(SelectedRow);
	
	Object.CurrentExchangePlanNodeId = CurrentRow.Id;
	Object.CurrentExchangePlanNodeRefKey = CurrentRow.Ref_Key;
	Object.CurrentExchangePlanNodeDescription = CurrentRow.Description;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	SaveSettingsServer();
	
EndProcedure

&AtClient
Function CheckExchangePlanSettingsFilling()
	
	FilledRight = True;
	
	If Not ValueIsFilled(Object.ExchangePlanName) Then
		
		FilledRight = False;
		Message(NStr("ru = 'Имя плана обменов должно быть заполнено'; en = 'Exchange plan name must be filled'"));
		
	EndIf;
	
	Return FilledRight;
	
EndFunction


&AtClient
Procedure SendChanges(Command)
	
	SaveSettingsServer();
	
	If CheckFilling() Then
		
		SendChangesServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SendChangesServer()
	
	FormAttributeToValue("Object").SendChanges();
	
EndProcedure

#EndRegion