
Procedure SetSettings(Settings) Export
	
	Writer = New JSONWriter;
	Writer.SetString(New JSONWriterSettings(Undefined, Chars.Tab));
	WriteJSON(Writer, Settings);
	Result = Writer.Close();
	Constants.bitmobile_НастройкиОбмена.Set(Result);
	
EndProcedure

Function GetSettings() Export
	
	Reader = New JSONReader;
	JSONString = Constants.bitmobile_НастройкиОбмена.Get();
	
	If Not JSONString = "" Then
		
		Reader.SetString(JSONString);
		Result = ReadJSON(Reader);
		Reader.Close();
		
		Return Result;
		
	Else
		
		Return New Structure;
		
	EndIf;
	
EndFunction

Function GetEmptySettingsStructure() Export
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("Host", );
	SettingsStructure.Insert("Port", );
	SettingsStructure.Insert("User", );
	SettingsStructure.Insert("Password", );
	SettingsStructure.Insert("PublicationName", );
	SettingsStructure.Insert("ExchangePlanName", );
	SettingsStructure.Insert("CurrentExchangePlanNodeDescription", );
	SettingsStructure.Insert("CurrentExchangePlanNodeId", );
	SettingsStructure.Insert("CurrentExchangePlanNodeRefKey", );
	SettingsStructure.Insert("MessageNo", );
	SettingsStructure.Insert("UseHTTPS", );

	Return SettingsStructure;
	
EndFunction

Function GetConnection() Export
	
	Settings = GetSettings();
	
	If CheckConnectionSettingsFilling(Settings) Then
		
		Port = ?(Settings.Port = 0, ?(Settings.UseHTTPS, 443, 80), Settings.Port);
		SecureConnection = ?(Settings.UseHTTPS, New OpenSSLSecureConnection(Undefined, Undefined), Undefined);
		
		Connection = New HTTPConnection(Settings.Host, Port, Settings.User, Settings.Password, , , SecureConnection);
		Return Connection;
		
	EndIf;
	
EndFunction

Function CheckConnectionSettingsFilling(Settings)
	
	FilledRight = True;
	
	If Not SettingIsFilled(Settings, "Host") Then
		
		FilledRight = False;
		Message(NStr("en = 'Host must be filled'; ru = 'Хост должен быть заполнен'"));
		
	EndIf;
	
	If Not SettingIsFilled(Settings, "Port") Then
		
		FilledRight = False;
		Message(NStr("en = 'Port must be filled'; ru = 'Порт должен быть заполнен'"));
		
	EndIf;
	
	If Not SettingIsFilled(Settings, "User") Then
		
		FilledRight = False;
		Message(NStr("en = 'User must be filled'; ru = 'Пользователь должен быть заполнен'"));
		
	EndIf;
	
	If Not SettingIsFilled(Settings, "PublicationName") Then
		
		FilledRight = False;
		Message(NStr("en = 'Publication name must be filled'; ru = 'Имя публикации должно быть заполнено'"));
		
	EndIf;
	
	Return FilledRight;
	
EndFunction

Function SettingIsFilled(Settings, SettingName) 
	
	Return Not Settings.Property(SettingName) = Undefined And ValueIsFilled(Settings.Property(SettingName));
	
EndFunction
