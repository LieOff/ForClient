
Function SendNotificationPOST(Request)
	
	Try
		
		Fields = GetFields(Request);
		ProcessFields(Fields); // Добавляем поля и изменяем значения в полученном наборе данных
		
		MessageTheme = GetMessageTheme(Fields);
		MessageText = GetMessageText(Fields);
		Recipients = GetRecipients();
		
		Message = DataProcessors.bitmobile_СинхронизацияИНастройки.ПолучитьПочтовоеСообщение(Recipients , MessageTheme, MessageText);
		DataProcessors.bitmobile_СинхронизацияИНастройки.ОтправитьСообщение(Message);
		
		Return New HTTPServiceResponse(200);
		
	Except
		
		WriteLogEvent("DemoAccess", , Metadata.HTTPServices.DemoAccess, , ErrorDescription());
		
		Return New HTTPServiceResponse(400);
		
	EndTry;
	
EndFunction

Procedure ProcessFields(Val Fields)
	
	Fields.Insert("Solution", "БИТ.СуперАгент");
	
	If Fields.OS = "Android" Then
		
		Fields.OS = "GooglePlay";
		
	ElsIf Fields.OS = "IOS" Then
		
		Fields.OS = "AppStore";
		
	EndIf;

EndProcedure

Function GetMessageTheme(Fields)
	
	RegisteredTheme = "СуперАгент, лид по демо-версии";
	UnregisteredTheme = "СуперАгент, в демо-версию выполнен вход без регистрации";
	
	Registered = Lower(Fields.Registered) = "true";
	
	Return ?(Registered, RegisteredTheme, UnregisteredTheme);
	
EndFunction

Function GetMessageText(Fields)
	
	FieldsMap = New Structure;
	FieldsMap.Insert("RegistrationDate", "Дата регистрации");
	FieldsMap.Insert("OS", "Магазин");
	FieldsMap.Insert("Name", "Имя");
	FieldsMap.Insert("Phone", "Телефон");
	FieldsMap.Insert("Solution", "Решение");
	
	MessageText = "";
	
	For Each Field In Fields Do
		
		If Not Field.Key = "Solution" Then
			
			MessageText = MessageText + GetFieldText(Field, FieldsMap);
			
		Else
			
			MessageText = MessageText + GetFieldText(Field, FieldsMap, False);
			
		EndIf;
		
	EndDo;
	
	Return MessageText;
	
EndFunction

Function GetFieldText(Field, FieldsMap, Encode = True)
	
	FieldText = ?(Encode, DecodeFrom1251ToUtf(Field.Value), Field.Value);
	
	Return ?(FieldsMap.Property(Field.Key), 
				FieldsMap[Field.Key] + ":" + Chars.CR + FieldText + Chars.CR + Chars.CR,
				"");
	
EndFunction

Function DecodeFrom1251ToUtf(FieldText)
	
	FileName = GetTempFileName("txt");
	
	TextWriter = New TextWriter(FileName, TextEncoding.System);
	TextWriter.WriteLine(FieldText);
	TextWriter.Close();
	
	TextReader = New TextReader(FileName, TextEncoding.UTF8);
	DecodedFieldText = TextReader.ReadLine();
	TextReader.Close();
	
	Return DecodedFieldText;

EndFunction

Function GetRecipients()
	
	Recipients = New Array;
	Recipient = InformationRegisters.bitmobile_АдресаЭлПочтыДляОтчетов.Select();
	
	While Recipient.Next() Do
		
		Recipients.Add(TrimAll(Recipient.ЭлПочта));
		
	EndDo;
	
	Return Recipients;

EndFunction

Function GetFields(Request)
	
	HeadersMap = New Map;
	HeadersMap.Insert("registered", "Registered");
	HeadersMap.Insert("regdate", "RegistrationDate");
	HeadersMap.Insert("name", "Name");
	HeadersMap.Insert("phone", "Phone");
	HeadersMap.Insert("os", "OS");
	
	Fields = New Structure;
	
	For Each KeyValue In HeadersMap Do
		
		Fields.Insert(KeyValue.Value, String(Request.Headers.Get(KeyValue.Key)));
		
	EndDo;
	
	Return Fields;
	
EndFunction

