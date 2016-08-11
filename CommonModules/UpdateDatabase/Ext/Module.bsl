
#Region CommonUpdateProcessors

Function StartUpdate() Export 
	
	CurrentVersion = Constants.bitmobile_ВерсияКонфигурации.Get();
	
	If ValueIsFilled(CurrentVersion) Then 
		
		ArrayOfCurrentVersion = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(CurrentVersion, ".");
		
		CurrentVersion = ArrayOfCurrentVersion[0] + "." + ArrayOfCurrentVersion[1] + "." + ArrayOfCurrentVersion[2];
		
	EndIf;
	
	MetadataVersion = Metadata.Version;
	
	ArrayOfMetadataVersion = ОбщегоНазначения.РазложитьСтрокуВМассивПодстрок(MetadataVersion, ".");
	
	MetadataVersionForUpdate = ArrayOfMetadataVersion[0] + "." + ArrayOfMetadataVersion[1] + "." + ArrayOfMetadataVersion[2];
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("NeedUpdate", False);
	ReturnStructure.Insert("NeedRestart", False);
	ReturnStructure.Insert("UpdateComplete", False);
	ReturnStructure.Insert("Error", "");
	
	If Not CurrentVersion = MetadataVersionForUpdate Then
		
		ReturnStructure.NeedUpdate = True;
		
		CurrenUser = InfoBaseUsers.CurrentUser();
		
		If Not IsInRole("Admin") Then 
			
			ErrorText = NStr("en = 'Insufficient permissions to perform the update. Required role: Administrator." 
							+ Chars.LF + "System operation is completed.';"
							+ "ru = 'Недостаточно прав для выполнения обновления. Требуется роль: Администратор."
							+ Chars.LF + "Работа системы будет завершена.'");
			
			ReturnStructure.Error = ErrorText;
			
			Return ReturnStructure;
			
		EndIf;
		
		Try
			
			SetExclusiveMode(True);
			
		Except
			
			ErrorText = NStr("en = 'Failed to set exclusive mode."
							+ Chars.LF + "Description of error: %1%."
							+ Chars.LF + "System operation is completed.';"
							+ "ru = 'Не удалось установить монопольный режим."
							+ Chars.LF + "Описание ошибки: %1%."
							+ Chars.LF + "Работа системы будет завершена.'");
			
			ErrorText = StrReplace(ErrorText, "%1%", String(ErrorDescription()));
			
			ReturnStructure.Error = ErrorText;
			
			Return ReturnStructure;
			
		EndTry;
		
		BeginTransaction();
		
		LastState = "";
		
		Try
		
			VersionListForThisRelease = New ValueList;
			VersionListForThisRelease.Add("");
			VersionListForThisRelease.Add("1.4.0");
			VersionListForThisRelease.Add("1.5.0");
			VersionListForThisRelease.Add("1.5.1");
			VersionListForThisRelease.Add("1.6.0");
			VersionListForThisRelease.Add("1.6.T");
			VersionListForThisRelease.Add("1.7.0");
			VersionListForThisRelease.Add("1.7.T");
			VersionListForThisRelease.Add("1.8.0");
			VersionListForThisRelease.Add("1.8.1");
			VersionListForThisRelease.Add("1.8.T");
			VersionListForThisRelease.Add("1.9.0");
			VersionListForThisRelease.Add("1.9.T");
			VersionListForThisRelease.Add("1.10.0");
			VersionListForThisRelease.Add("1.10.T");
			VersionListForThisRelease.Add("1.11.0");
			VersionListForThisRelease.Add("1.11.T");
			VersionListForThisRelease.Add("1.12.0");
			VersionListForThisRelease.Add("1.12.T");
			
			If Not VersionListForThisRelease.FindByValue(CurrentVersion) = Undefined Then 
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en='Database update is started';ru='Выполняется обновление базы данных';cz='Aktualizace databбze byla zahбjena'");
				
				UserMessage.Message();
				
				Step = 0;
				
				UserMessage			= New UserMessage;
				UserMessage.Text	= NStr("en='Common processors';ru='Общие обработчики';cz='Obecnй handlery'");
				
				UserMessage.Message();
				
				// Общие обработчики для всех релизов
				UpdateForAllReleases(LastState, Step);
				
				If Not ValueIsFilled(CurrentVersion) Then
				
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.4.0';ru='Версия 1.4.0';cz='Verze 1.4.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_4_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.6.0';ru='Версия 1.6.0';cz='Verze 1.6.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_6_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.7.0';ru='Версия 1.7.0';cz='Verze 1.7.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_7_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.8.0';ru='Версия 1.8.0';cz='Verze 1.8.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_8_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en = 'Version 1.9.0'; ru = 'Версия 1.9.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_9_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.10.0'; ru = 'Версия 1.10.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_10_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.0'; ru = 'Версия 1.11.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.1'; ru = 'Версия 1.11.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_1(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.0'; ru = 'Версия 1.12.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
				If CurrentVersion = "1.4.0" Or CurrentVersion = "1.5.0" Or CurrentVersion = "1.5.1" Then 
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.6.0';ru='Версия 1.6.0';cz='Verze 1.6.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_6_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.7.0';ru='Версия 1.7.0';cz='Verze 1.7.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_7_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.8.0';ru='Версия 1.8.0';cz='Verze 1.8.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_8_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en = 'Version 1.9.0'; ru = 'Версия 1.9.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_9_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.10.0'; ru = 'Версия 1.10.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_10_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.0'; ru = 'Версия 1.11.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.1'; ru = 'Версия 1.11.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_1(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.0'; ru = 'Версия 1.12.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
				If CurrentVersion = "1.6.0" Or CurrentVersion = "1.6.T" Then 
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.7.0';ru='Версия 1.7.0';cz='Verze 1.7.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_7_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.8.0';ru='Версия 1.8.0';cz='Verze 1.8.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_8_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en = 'Version 1.9.0'; ru = 'Версия 1.9.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_9_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.10.0'; ru = 'Версия 1.10.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_10_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.0'; ru = 'Версия 1.11.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.1'; ru = 'Версия 1.11.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_1(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.0'; ru = 'Версия 1.12.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
				If CurrentVersion = "1.7.0" OR CurrentVersion = "1.7.T" Then
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en='Version 1.8.0';ru='Версия 1.8.0';cz='Verze 1.8.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_8_0(LastState, Step);
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en = 'Version 1.9.0'; ru = 'Версия 1.9.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_9_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.10.0'; ru = 'Версия 1.10.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_10_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.0'; ru = 'Версия 1.11.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.1'; ru = 'Версия 1.11.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_1(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.0'; ru = 'Версия 1.12.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
				If CurrentVersion = "1.8.0" OR CurrentVersion = "1.8.1" OR CurrentVersion = "1.8.T" Then
					
					UserMessage			= New UserMessage;
					UserMessage.Text	= NStr("en = 'Version 1.9.0'; ru = 'Версия 1.9.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_9_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.10.0'; ru = 'Версия 1.10.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_10_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.0'; ru = 'Версия 1.11.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.1'; ru = 'Версия 1.11.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_1(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.0'; ru = 'Версия 1.12.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
				If CurrentVersion = "1.9.0" OR CurrentVersion = "1.9.T" Then
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.10.0'; ru = 'Версия 1.10.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_10_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.0'; ru = 'Версия 1.11.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.1'; ru = 'Версия 1.11.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_1(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.0'; ru = 'Версия 1.12.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
				If CurrentVersion = "1.10.0" OR CurrentVersion = "1.10.T" Then
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.0'; ru = 'Версия 1.11.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.1'; ru = 'Версия 1.11.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_1(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.0'; ru = 'Версия 1.12.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
				If CurrentVersion = "1.11.0" OR CurrentVersion = "1.11.T" Then
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.11.1'; ru = 'Версия 1.11.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_11_1(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.0'; ru = 'Версия 1.12.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
				If CurrentVersion = "1.11.1" OR CurrentVersion = "1.11.T" Then
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.0'; ru = 'Версия 1.12.0'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_0(LastState, Step);
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
				If CurrentVersion = "1.12.0" OR CurrentVersion = "1.12.T" Then
					
					UserMessage = New UserMessage;
					UserMessage.Text = NStr("en = 'Version 1.12.1'; ru = 'Версия 1.12.1'");
					
					UserMessage.Message();
					
					UpdateForRelease_1_12_1(LastState, Step);
					
				EndIf;
				
			EndIf;
			
			Constants.bitmobile_ВерсияКонфигурации.Set(MetadataVersion);
		
			CommitTransaction();
			
			SetExclusiveMode(False);
			
			ReturnStructure.UpdateComplete = True;
			
			Return ReturnStructure;
			
		Except
			
			RollbackTransaction();
			
			ErrorText = NStr("en = 'Database update aborted at step: %1%. " 
							+ Chars.LF + "Description of error: %2%. " 
							+ Chars.LF + "System operation is completed.';" 
							+ "ru = 'Обновление базы данных прервано на этапе: %1%." 
							+ Chars.LF +  "Описание ошибки: %2%. " 
							+ Chars.LF +  "Работа системы будет завершена.'");
			
			ErrorText = StrReplace(ErrorText, "%1%", LastState);
			ErrorText = StrReplace(ErrorText, "%2%", String(ErrorDescription()));
			
			ReturnStructure.Error = ErrorText;
			
			Return ReturnStructure;
			
		EndTry;
	
	EndIf;
	
	Return ReturnStructure;

EndFunction

Procedure WriteProtocol(LastState, Step, Text)
	
	Step		= Step + 1;
	LastState 	= Text;
	
	UserMessage 		= New UserMessage;
	UserMessage.Text	= NStr("en = 'Step '; ru = 'Этап '") + String(Step) + ": " + Text;
	
	UserMessage.Message();
	
EndProcedure	

#EndRegion

#Region ForAllReleases

Procedure UpdateForAllReleases(LastState, Step)
	
	WriteProtocol(LastState, Step, NStr("en='Update sync settings';ru='Обновление настроек синхронизации';cz='Update sync settings'"));  
	ProcessSyncSettings();
	
	WriteProtocol(LastState, Step, NStr("en='Filling database';ru='Заполнение базы данных';cz='Filling database'"));  
	FillInProcessing();
	
	FillConfigurationData();
	
	WriteProtocol(LastState, Step, NStr("en='Update roles os users';ru='Обновление ролей пользователей';cz='Update roles os users'"));  
	ProcessPredefinedRoles();
	
	WriteProtocol(LastState, Step, NStr("en='Update users';ru='Обновление пользователей';cz='Aktualizovat uživatele'"));  
	ProcessUsers();
	
	WriteProtocol(LastState, Step, NStr("en='Update mobile apps settings';ru='Обновление настроек мобильных приложений';cz='Update mobile apps settings'"));  
	ProcessMobileAppSettings();
	
	WriteProtocol(LastState, Step, NStr("en = 'Update system objects'; ru = 'Обновление объектов системы'"));  
	ProcessSystemObjects();
	
	WriteProtocol(LastState, Step, NStr("en = 'Update information register ""Default values""'; ru = 'Обновление регистра сведений ""Значения по умолчанию""'"));
	CommonProcessors.FillDefaultValuesInformationRegister();
	
EndProcedure

Procedure ProcessPredefinedRoles()
	
	SRMRole = Catalogs.RolesOfUsers.SRM.GetObject();
	SRMRole.AccessRightsToSystemObjects.Clear();
	SRMRole.AdditionalAccessRights.Clear();
	SRMRole.MobileAppAccessRights.Clear();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SystemObjects.Ref AS SystemObject,
		|	TRUE AS Read,
		|	CASE
		|		WHEN SystemObjects.Ref.Parent.Description = ""en = 'Reports'; ru = 'Отчеты'""
		|				OR SystemObjects.Ref.Description = ""en = 'Reports'; ru = 'Отчеты'""
		|				OR SystemObjects.Ref.Description = ""en = 'Encashment'; ru = 'Инкассация'""
		|				OR SystemObjects.Ref.Description = ""en = 'Visit'; ru = 'Визит'""
		|				OR SystemObjects.Ref.Description = ""en = 'Roles of users'; ru = 'Роли пользователей'""
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS Edit,
		|	CASE
		|		WHEN SystemObjects.Ref.Parent.Description = ""en = 'Reports'; ru = 'Отчеты'""
		|				OR SystemObjects.Ref.Description = ""en = 'Reports'; ru = 'Отчеты'""
		|				OR SystemObjects.Ref.Description = ""en = 'Encashment'; ru = 'Инкассация'""
		|				OR SystemObjects.Ref.Description = ""en = 'Visit'; ru = 'Визит'""
		|				OR SystemObjects.Ref.Description = ""en = 'Roles of users'; ru = 'Роли пользователей'""
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS MarkForDeletion
		|FROM
		|	Catalog.SystemObjects AS SystemObjects
		|WHERE
		|	SystemObjects.Predefined = TRUE
		|	AND SystemObjects.IsFolder = FALSE";
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		FillPropertyValues(SRMRole.AccessRightsToSystemObjects.Add(), Selection);
		
	EndDo;
	
	InsRightToOutletParameterEdit				= SRMRole.AdditionalAccessRights.Add();
	InsRightToOutletParameterEdit.AccessRight	= Catalogs.AdditionalAccessRights.EditParametersInOutlet;
	
	SRMRole.Write();
	
	SRRole = Catalogs.RolesOfUsers.SR.GetObject();
	SRRole.AccessRightsToSystemObjects.Clear();
	SRRole.AdditionalAccessRights.Clear();
	SRRole.MobileAppAccessRights.Clear();
	
	InsMobileRights				= SRRole.MobileAppAccessRights.Add();
	InsMobileRights.AccessRight	= Catalogs.MobileAppAccessRights.AccessToMobileApp;
	
	InsMobileRights				= SRRole.MobileAppAccessRights.Add();
	InsMobileRights.AccessRight	= Catalogs.MobileAppAccessRights.AccessToEncashment;
	
	InsMobileRights				= SRRole.MobileAppAccessRights.Add();
	InsMobileRights.AccessRight	= Catalogs.MobileAppAccessRights.EditParametersInOutlet;
	
	SRRole.Write();
	
EndProcedure

Procedure FillConfigurationData()
	
	Constants.bitmobile_ИмяКонфигурации.Set(Metadata.Name);
	
	AvailebleFileSize = Constants.bitmobile_ДопустимыйРазмерФайла.Get();
	
	If AvailebleFileSize = 0 Then 
		
		Constants.bitmobile_ДопустимыйРазмерФайла.Set(500);
		
	EndIf;
	
	UploadObjectsCount = Constants.bitmobile_КоличествоОбъектовВВыгрузке.Get();
	
	If UploadObjectsCount = 0 Then 
		
		Constants.bitmobile_КоличествоОбъектовВВыгрузке.Set(200);
		
	EndIf;
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		ExchangePlanProc = ExchangePlans[ExchangePlan.Name];
		
		ThisNodeRef = ExchangePlanProc.ThisNode();
	
		ThisNodeObject				= ThisNodeRef.GetObject();
		ThisNodeObject.Code			= "sagent";
		ThisNodeObject.Description	= "SuperAgent";
		
		ThisNodeObject.Write();
		
	EndDo;
	
EndProcedure

Procedure FillInProcessing()
	
	// Добавить элементы для справочников OutletType, Class, Territory, Users, SKUGroup, Region, Brand, Units
	EntityElements = New ValueTable();
	
	EntityElements.Columns.Add("Key");
	EntityElements.Columns.Add("Value");
	
	EntityElements = AddInValueTable(EntityElements, "User", NStr("en='Default sales representative';ru='Основной торговый представитель';cz='Vэchozн zбstupce'"));
	EntityElements = AddInValueTable(EntityElements, "OutletType", NStr("en='Default type';ru='Основной тип';cz='Vэchozн typ'"));
	EntityElements = AddInValueTable(EntityElements, "OutletClass", NStr("en='Default class';ru='Основной класс';cz='Výchozí třída'"));
	EntityElements = AddInValueTable(EntityElements, "Region", NStr("en='Default region';ru='Основной регион';cz='Vэchozн region'"));
	EntityElements = AddInValueTable(EntityElements, "Territory", NStr("en='Default territory';ru='Основная территория';cz='Vэchozн ъzemн'"));
	//EntityElements = AddInValueTable(EntityElements, "Distributor", NStr("en='Default distributor';ru='Основной дистрибьютор';cz='Vэchozн distributor'"));
	EntityElements = AddInValueTable(EntityElements, "SKUGroup", NStr("en='Default group';ru='Основная группа';cz='Vэchozн skupina'"));
	EntityElements = AddInValueTable(EntityElements, "Brands", NStr("en='Default brand';ru='Основной бренд';cz='Výchozí značka'"));
	EntityElements = AddInValueTable(EntityElements, "UnitsOfMeasure", NStr("en='pcs.';ru='шт.';cz='pcs.'"));
	
	For Each Entity In EntityElements Do
		
		If NoItems(Entity.Key) Then
			
			NewObject				= Catalogs[Entity.Key].CreateItem();
			NewObject.Description	= Entity.Value;
			
			If Entity.Key = "User" Then
				
				NewObject.Description		= "srm";
				NewObject.RoleOfUser		= Catalogs.RolesOfUsers.SRM;
				NewObject.UserName			= "srm";
				NewObject.Password			= "srm";
				NewObject.InterfaceLanguage	= Metadata.Languages.Русский.Name;
				
				NewObject.Write();
				
				SRMRef = NewObject.Ref;
				
				NewObject = Catalogs[Entity.Key].CreateItem();
				
				NewObject.Description		= "sr";
				NewObject.RoleOfUser		= Catalogs.RolesOfUsers.SR;
				NewObject.UserName			= "sr";
				NewObject.Password			= "sr";
				NewObject.InterfaceLanguage	= Metadata.Languages.Русский.Name;
				NewObject.Manager = SRMRef;
				
			EndIf;
			
			If Entity.Key = "Territory" Then
				
				Ins		= NewObject.SRs.Add();
				Ins.SR	= Catalogs.User.FindByDescription("sr", True);
				
				NewObject.Owner = Catalogs.Region.FindByCode("000000001");
				
			EndIf;
			
			If Entity.Key = "Region" Then
				
				Manager = Catalogs.User.FindByAttribute("RoleOfUser", Catalogs.RolesOfUsers.SRM);
				
				Ins			= NewObject.Managers.Add();
				Ins.Manager	= Manager;
				NewObject.Manager = Manager;
				
			EndIf;
			
			NewObject.Write();
			
		EndIf;
		
	EndDo;
	
	PotentialObject = Catalogs.OutletsStatusesSettings.Potential.GetObject();
	PotentialObject.Status = Enums.OutletStatus.Potential;
	PotentialObject.Write();
	
	ActiveObject = Catalogs.OutletsStatusesSettings.Active.GetObject();
	ActiveObject.Status = Enums.OutletStatus.Active;
	ActiveObject.Write();
	
	ClosedObject = Catalogs.OutletsStatusesSettings.Closed.GetObject();
	ClosedObject.Status = Enums.OutletStatus.Closed;
	ClosedObject.Write();
	
EndProcedure

Procedure ProcessSystemObjects()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	RolesOfUsers.Ref AS Role
		|FROM
		|	Catalog.RolesOfUsers AS RolesOfUsers";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		RoleOfUserObject = Selection.Role.GetObject();
		
		DeletedRows = New Array;
		
		For Each SORow In RoleOfUserObject.AccessRightsToSystemObjects Do 
			
			If SORow.SystemObject.DeletionMark Then 
				
				DeletedRows.Add(SORow);
				
			EndIf;
			
		EndDo;
		
		For Each DRow In DeletedRows Do 
			
			RoleOfUserObject.AccessRightsToSystemObjects.Delete(DRow);
			
		EndDo;
		
		RoleOfUserObject.Write();
		
	EndDo;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SystemObjects.Ref AS SObject
		|FROM
		|	Catalog.SystemObjects AS SystemObjects
		|WHERE
		|	SystemObjects.DeletionMark = TRUE
		|
		|ORDER BY
		|	SystemObjects.IsFolder";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		DeleteObject = Selection.SObject.GetObject();
		
		DeleteObject.Delete();
		
	EndDo;
	
EndProcedure

Procedure ProcessUsers()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	User.Ref AS User,
		|	User.Role AS Role,
		|	User.InterfaceLanguage AS Language,
		|	User.RoleOfUser AS RoleOfUser
		|FROM
		|	Catalog.User AS User";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		NeedWriteUser = False;
		
		RoleToSet = Undefined;
		
		LanguageToSet = Undefined;
		
		If Lower(Selection.Role) = "sr" And Not ValueIsFilled(Selection.RoleOfUser) Then 
			
			RoleToSet = Catalogs.RolesOfUsers.SR;
			
			NeedWriteUser = True;
			
		ElsIf Lower(Selection.Role) = "srm" And Not ValueIsFilled(Selection.RoleOfUser) Then
			
			RoleToSet = Catalogs.RolesOfUsers.SRM;
			
			NeedWriteUser = True;
			
		EndIf;
		
		If Not ValueIsFilled(Selection.Language) Then 
			
			LanguageToSet = Metadata.Languages.Русский.Name;
			
			NeedWriteUser = True;
			
		EndIf;
		
		If NeedWriteUser Then 
			
			UserObject = Selection.User.GetObject();
			
			If Not RoleToSet = Undefined Then 
				
				UserObject.RoleOfUser = RoleToSet;
				
			EndIf;
			
			If Not LanguageToSet = Undefined Then 
				
				UserObject.InterfaceLanguage = LanguageToSet;
				
			EndIf;
			
			UserObject.Write();
			
		EndIf;
		
	EndDo;
	
	UsersArray = InfoBaseUsers.GetUsers();
	
	For Each UserElement In UsersArray Do
		
		If UserElement.Roles.Contains(Metadata.Roles.Admin) Then 
			
			FoundedUser = Catalogs.User.FindByAttribute("UserID", UserElement.UUID); 
			
			If Not ValueIsFilled(FoundedUser) Then 
				
				NewAdmin = Catalogs.User.CreateItem();
				
				NewAdmin.Description	= UserElement.FullName;
				NewAdmin.Role			= "Admin";
				NewAdmin.UserName		= UserElement.Name;
				NewAdmin.UserID			= UserElement.UUID;
				
				If UserElement.PasswordIsSet Then 
				
					NewAdmin.Password		= UserElement.Password;
					
				EndIf;
				
				If UserElement.Language = Undefined Then 
					
					UserElement.Language		= Metadata.Languages.Русский;
					
					NewAdmin.InterfaceLanguage	= Metadata.Languages.Русский.Name;
					
				Else 
					
					NewAdmin.InterfaceLanguage	= UserElement.Language.Name;
					
				EndIf;
				
				NewAdmin.Write();
				
			EndIf;
				
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessSyncSettings()
	
	DataProcessors.bitmobile_СинхронизацияИНастройки.ВосстановитьНастройкиИзФайла(Undefined, True, True);
	
EndProcedure

Function NoItems(EntityName)
    
    If EntityName = "User" Then
        Text = 
        "SELECT ALLOWED
        |   COUNT(DISTINCT User.Ref) AS Ref
        |FROM
        |   Catalog.User AS User
        |WHERE
        |   User.Role = &Role";
        Query = New Query;
        Query.Text = Text;
        Query.SetParameter("Role", "SR");
    Else
        Text = "SELECT ALLOWED COUNT(DISTINCT Ref) FROM Catalog." + EntityName;
        Query = New Query;
        Query.Text = Text;
    EndIf;
    
    Result = Query.Execute().Unload();
    If Result[0].Ref > 0  Then
        Return False;
    Else
        Return True;
    EndIf;
    
EndFunction 

Function AddInValueTable(EntityElements, Entity, Value)
    
    NewRow 			= EntityElements.Add();
    NewRow.Key 		= Entity;
    NewRow.Value 	= Value;
	
	Return EntityElements;
    
EndFunction 

Procedure ProcessMobileAppSettings()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MobileAppSettings.Ref AS Setting,
		|	MobileAppSettings.Description
		|FROM
		|	Catalog.MobileAppSettings AS MobileAppSettings
		|WHERE
		|	MobileAppSettings.Predefined = TRUE";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		SettingObject = Selection.Setting.GetObject();
		
		OldSetting = Undefined;
		
		If Selection.Description = "ControlOrderReasonEnabled" Then 
			
			OldSetting = Catalogs.MobileAppSettings.FindByCode("NOR");
			
			RefillMobileAppSetting(SettingObject, OldSetting);
			
		ElsIf Selection.Description = "ControlVisitReasonEnabled" Then
			
			OldSetting = Catalogs.MobileAppSettings.FindByCode("UVR");
			
			RefillMobileAppSetting(SettingObject, OldSetting);
			
		ElsIf Selection.Description = "CoordinateControlEnabled" Then
			
			OldSetting = Catalogs.MobileAppSettings.FindByCode("CoordCtrl");
			
			RefillMobileAppSetting(SettingObject, OldSetting);
			
		ElsIf Selection.Description = "EmptyStockEnabled" Then
			
			OldSetting = Catalogs.MobileAppSettings.FindByCode("NoStkEnbl");
			
			RefillMobileAppSetting(SettingObject, OldSetting);
			
		ElsIf Selection.Description = "MultistockEnabled" Then
			
			OldSetting = Catalogs.MobileAppSettings.FindByCode("MultStck");
			
			RefillMobileAppSetting(SettingObject, OldSetting);
			
		ElsIf Selection.Description = "PlanVisitEnabled" Then
			
			OldSetting = Catalogs.MobileAppSettings.FindByCode("PlanEnbl");
			
			RefillMobileAppSetting(SettingObject, OldSetting);
			
		ElsIf Selection.Description = "RecOrderEnabled" Then 
			
			OldSetting = Catalogs.MobileAppSettings.FindByCode("OrderCalc");
			
			RefillMobileAppSetting(SettingObject, OldSetting);
			
		ElsIf Selection.Description = "SnapshotSize" Then 
			
			SettingObject.DataType = Enums.DataType.Integer;
			
		ElsIf Selection.Description = "SKUFeaturesRegistration" Then 
			
			SettingObject.DataType = Enums.DataType.Boolean;
			
		ElsIf Selection.Description = "UserCoordinatesActualityTime" Then
			
			SettingObject.DataType = Enums.DataType.Integer;
			
		EndIf;
		
		SettingObject.Write();
		
	EndDo;
	
EndProcedure

Procedure RefillMobileAppSetting(SettingObject, OldSetting)
	
	SettingObject.DataType = Enums.DataType.Boolean;
	
	If ValueIsFilled(OldSetting) Then 
		
		SettingObject.LogicValue = OldSetting.LogicValue;
		
		OldSettingObject = OldSetting.GetObject();
		
		OldSettingObject.Delete();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Release_1_4_0

Procedure UpdateForRelease_1_4_0(LastState, Step)
	
	WriteProtocol(LastState, Step, NStr("en='Update groups of questions';ru='Обновление групп вопросов';cz='Update groups of questions'"));
	ProcessQuestionGroups();
	
	WriteProtocol(LastState, Step, NStr("en='Update territories in SKU groups';ru='Обновление территорий в группах номенклатуры';cz='Update territories in SKU groups'"));
	ProcessTerritoryInSKUGroups();
	
	WriteProtocol(LastState, Step, NStr("en='Update questionnaires';ru='Обновление анкет';cz='Update questionnaires'"));
	ProcessQuestionnaires();
	
	WriteProtocol(LastState, Step, NStr("en='Update SKU questions in questionnaires';ru='Обновление вопросов по номенклатуре в анкетах';cz='Update SKU questions in questionnaires'"));
	ProcessSKUQuestions();
	
	WriteProtocol(LastState, Step, NStr("en='Update regular questions in questionnaires';ru='Обновление общих вопросов в анкетах';cz='Update regular questions in questionnaires'"));
	ProcessQuestions();
	
	WriteProtocol(LastState, Step, NStr("en='Update SKUs in questionnaires';ru='Обновление номенклатуры в анкетах';cz='Update SKUs in questionnaires'"));
	ProcessSKUs();
	
	WriteProtocol(LastState, Step, NStr("en='Update selectors in questionnaires';ru='Обновление параметров отбора в анкетах';cz='Update selectors in questionnaires'"));
	ProcessSelectors();
	
	WriteProtocol(LastState, Step, NStr("en='Update visits';ru='Обновление результатов визитов';cz='Aktualizovat návštěvy'"));
	UpdateSKUQuestionsInVisit();
	
EndProcedure	

#Region Update_QuestionGroups_Territories

Procedure ProcessQuestionGroups()
	
	Selection = Catalogs.QuestionGroup.Select();
	
	While Selection.Next() Do
		
		If Selection.Type = Enums.QuestionGroupTypes.EmptyRef() Then
			
			Object = Selection.GetObject();
			Object.DataExchange.Load = True;
			Object.Type = Enums.QuestionGroupTypes.RegularQuestions;
			Object.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessTerritoryInSKUGroups()
	
	// Очистить списки территорий в группах
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SKUGroup.Ref AS SKUGroup
		|FROM
		|	Catalog.SKUGroup AS SKUGroup
		|WHERE
		|	SKUGroup.IsFolder = FALSE";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		GroupObject = Selection.SKUGroup.GetObject();
		
		GroupObject.Territories.Clear();
		
		GroupObject.Write();
				
	EndDo;
		
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	Territory.Ref AS Territory
		|FROM
		|	Catalog.Territory AS Territory";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		Territory = Selection.Territory;
		
		For Each Row In Territory.SKUGroups Do 
			
			If Not Row.SKUGroup.IsFolder Then 
			
				GroupObject = Row.SKUGroup.GetObject();
				
				If Not GroupObject = Undefined Then  
				
					If GroupObject.Territories.Find(Territory) = Undefined Then 
						
						NewRow = GroupObject.Territories.Add();
						NewRow.Territory = Territory;			
						
					EndIf;
					
					GroupObject.Write();
					
				EndIf;	
				
			EndIf;	
			
		EndDo;	
		
	EndDo;
		
EndProcedure

#EndRegion

#Region Update_Questionaire

Procedure ProcessQuestionnaires()
	
	Select = Documents.Questionnaire.Select();
	
	While Select.Next() Do
		
		Object 				= Select.GetObject();
		Object.BeginDate 	= Object.Date;
		Object.Schedule 	= "Day;1";
		Object.Status 		= Enums.QuestionnareStatus.Active;
		Object.Single 		= False;
		Object.FillPeriod 	= Enums.QuestionsSaveIntervals.ScheduleInterval;
		
		Object.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessSKUQuestions()
	
	SKUQuestionsGroup = GetSKUQuestionsGroup();
	
	SKUQuestionsAssignment = New ValueTable;
	SKUQuestionsAssignment.Columns.Add("Question");
	SKUQuestionsAssignment.Columns.Add("Assignment");
		
	Question = CreateQuestion(NStr("en='Available';ru='Доступность';cz='Available'"), Enums.DataType.Boolean, Enums.SKUQuestions.Available, SKUQuestionsGroup);
	
	NewAssignment 				= SKUQuestionsAssignment.Add();
	NewAssignment.Question 		= Question;
	NewAssignment.Assignment 	= Enums.SKUQuestions.Available;
	
	Question = CreateQuestion(NStr("en='Facing';ru='Фейсинг';cz='Facing'"), Enums.DataType.Decimal, Enums.SKUQuestions.Facing, SKUQuestionsGroup);
	
	NewAssignment 				= SKUQuestionsAssignment.Add();
	NewAssignment.Question 		= Question;
	NewAssignment.Assignment 	= Enums.SKUQuestions.Facing;
	
	Question = CreateQuestion(NStr("en='Mark up';ru='Наценка';cz='Mark up'"), Enums.DataType.Decimal, Enums.SKUQuestions.MarkUp, SKUQuestionsGroup);
	
	NewAssignment 				= SKUQuestionsAssignment.Add();
	NewAssignment.Question 		= Question;
	NewAssignment.Assignment 	= Enums.SKUQuestions.MarkUp;
	
	Question = CreateQuestion(NStr("en='Out of stock';ru='Наличие на складе';cz='Out of stock'"), Enums.DataType.Boolean, Enums.SKUQuestions.OutOfStock, SKUQuestionsGroup);
	
	NewAssignment 				= SKUQuestionsAssignment.Add();
	NewAssignment.Question 		= Question;
	NewAssignment.Assignment 	= Enums.SKUQuestions.OutOfStock;
	
	Question = CreateQuestion(NStr("en='Price';ru='Цена';cz='Cena'"), Enums.DataType.Decimal, Enums.SKUQuestions.Price, SKUQuestionsGroup);
	
	NewAssignment 				= SKUQuestionsAssignment.Add();
	NewAssignment.Question 		= Question;
	NewAssignment.Assignment 	= Enums.SKUQuestions.Price;
	
	Question = CreateQuestion(NStr("en='Stock';ru='Остаток';cz='Skladem'"), Enums.DataType.Decimal, Enums.SKUQuestions.Stock, SKUQuestionsGroup);
	
	NewAssignment 				= SKUQuestionsAssignment.Add();
	NewAssignment.Question 		= Question;
	NewAssignment.Assignment 	= Enums.SKUQuestions.Stock;
	
	Question = CreateQuestion(NStr("en='Snapshot';ru='Снимок';cz='Foto'"), Enums.DataType.Snapshot, Enums.SKUQuestions.Snapshot, SKUQuestionsGroup);
	
	NewAssignment 				= SKUQuestionsAssignment.Add();
	NewAssignment.Question 		= Question;
	NewAssignment.Assignment 	= Enums.SKUQuestions.Snapshot;
	
	Question = CreateQuestion(NStr("en='Promo';ru='Промо';cz='Promo'"), Enums.DataType.Boolean, Enums.SKUQuestions.Promo, SKUQuestionsGroup);
	
	NewAssignment 				= SKUQuestionsAssignment.Add();
	NewAssignment.Question 		= Question;
	NewAssignment.Assignment 	= Enums.SKUQuestions.Promo;
	
	Query = New Query(
	"SELECT ALLOWED
	|	QuestionnaireSKUQuestions1.Ref AS Ref,
	|	QuestionnaireSKUQuestions1.SKUQuestion AS SKUQuestion,
	|	QuestionnaireSKUQuestions1.LineNumber AS LineNumber
	|FROM
	|	Document.Questionnaire.SKUQuestions AS QuestionnaireSKUQuestions1
	|WHERE
	|	QuestionnaireSKUQuestions1.UseInQuestionaire
	|
	|ORDER BY
	|	Ref
	|TOTALS BY
	|	Ref");
	
	SKUQuestions = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
		
	If SKUQuestions.Rows.Count() > 0 Then
		
		For Each QuestionnaireRow In SKUQuestions.Rows Do
			
			For Each SKUQuestionsRow In QuestionnaireRow.Rows Do
				
				Question = GetSKUQuestion(SKUQuestionsRow.SKUQuestion, SKUQuestionsAssignment);
				
				If ValueIsFilled(Question) Then 
				
					RecordManager 					= InformationRegisters.QuestionsInQuestionnaires.CreateRecordManager();
					RecordManager.Questionnaire 	= QuestionnaireRow.Ref;
					RecordManager.ChildQuestion 	= Question;
					RecordManager.QuestionType 		= Enums.QuestionGroupTypes.SKUQuestions;
					RecordManager.Order				= SKUQuestionsRow.LineNumber;
					RecordManager.Obligatoriness 	= False;
					RecordManager.Status 			= Enums.ValueTableRowStatuses.Added;
					RecordManager.Period 			= QuestionnaireRow.Ref.Date;
					
					RecordManager.Write();
					
				EndIf;	
 								
			EndDo;
						
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ProcessQuestions() 
	
	Query = New Query(
	"SELECT ALLOWED
	|	QuestionnaireQuestions.Ref AS Questionnaire,
	|	QuestionnaireQuestions.Question AS ChildQuestion,
	|	VALUE(Enum.QuestionGroupTypes.RegularQuestions) AS QuestionType,
	|	QuestionnaireQuestions.LineNumber AS Order,
	|	FALSE AS Obligatoriness,
	|	VALUE(Enum.ValueTableRowStatuses.Added) AS Status,
	|	QuestionnaireQuestions.Ref.Date AS Period
	|FROM
	|	Document.Questionnaire.Questions AS QuestionnaireQuestions");
	
	QueryResult = Query.Execute().Unload();
	
	For Each Line In QueryResult Do
		
		RecordManager = InformationRegisters.QuestionsInQuestionnaires.CreateRecordManager();
		FillPropertyValues(RecordManager, Line);
		RecordManager.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessSKUs()
	
	Query = New Query(
	"SELECT ALLOWED
	|	QuestionnaireSKUs.Ref.Date AS Period,
	|	QuestionnaireSKUs.Ref AS Questionnaire,
	|	QuestionnaireSKUs.SKU,
	|	QuestionnaireSKUs.SKU AS Source,
	|	VALUE(Enum.ValueTableRowStatuses.Added) AS Status
	|FROM
	|	Document.Questionnaire.SKUs AS QuestionnaireSKUs");
	
	QueryResult = Query.Execute().Unload();
	
	For Each Line In QueryResult Do
		
		RecordManager = InformationRegisters.SKUsInQuestionnaires.CreateRecordManager();
		FillPropertyValues(RecordManager, Line);
		RecordManager.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessSelectors()
	
	Query = New Query(
		"SELECT ALLOWED
		|	Territories.Ref AS Questionnaire,
		|	Territories.Territory AS Value,
		|	""Catalog_Territory"" AS Selector
		|INTO SelectorValues
		|FROM
		|	Document.Questionnaire.Territories AS Territories
		|WHERE
		|	Territories.Ref.Scale = VALUE(Enum.QuestionnaireScale.Territory)
		|
		|UNION ALL
		|
		|SELECT 
		|	Regions.Ref,
		|	Regions.Territory.Owner,
		|	""Catalog_Region""
		|FROM
		|	Document.Questionnaire.Territories AS Regions
		|WHERE
		|	Regions.Ref.Scale = VALUE(Enum.QuestionnaireScale.Region)
		|
		|GROUP BY
		|	Regions.Ref,
		|	Regions.Territory.Owner
		|
		|UNION ALL
		|
		|SELECT 
		|	Questionnaire.Ref,
		|	Questionnaire.OutletType,
		|	""Catalog_OutletType""
		|FROM
		|	Document.Questionnaire AS Questionnaire
		|
		|UNION ALL
		|
		|SELECT 
		|	Questionnaire.Ref,
		|	Questionnaire.OutletClass,
		|	""Catalog_OutletClass""
		|FROM
		|	Document.Questionnaire AS Questionnaire
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	SelectorValues.Questionnaire AS Questionnaire,
		|	SelectorValues.Value,
		|	VALUE(Enum.ComparisonType.Equal) AS ComparisonType,
		|	SelectorValues.Selector
		|FROM
		|	SelectorValues AS SelectorValues
		|
		|ORDER BY
		|	Questionnaire");
	
	QueryResult = Query.Execute().Unload();
	
	CurrentQuestionaire = Undefined;
	
	For Each Line In QueryResult Do
		
		If CurrentQuestionaire = Undefined Then 
			
			CurrentQuestionaire = Line.Questionnaire;
			
			CurrentQuestionaireObject = CurrentQuestionaire.GetObject();
			
			CurrentQuestionaireObject.Selectors.Clear();
			
		EndIf;	
		
		If CurrentQuestionaire = Line.Questionnaire Then 
			
			If ValueIsFilled(Line.Value) Then
			
				Row = CurrentQuestionaireObject.Selectors.Add();
				
				FillPropertyValues(Row, Line);
				
				Row.StringValue	= GetStringFromValue(Row.Value);
				
			EndIf;	
			
		Else 	
			
			CurrentQuestionaire = Line.Questionnaire;
			
			CurrentQuestionaireObject.Write();
			
			CurrentQuestionaireObject = CurrentQuestionaire.GetObject();
			
			CurrentQuestionaireObject.Selectors.Clear();
			
			If ValueIsFilled(Line.Value) Then 
			
				Row = CurrentQuestionaireObject.Selectors.Add();
				
				FillPropertyValues(Row, Line);
				
				Row.StringValue	= GetStringFromValue(Row.Value);
				
			EndIf;	
				
		EndIf;	
				
	EndDo;
	
	If Not CurrentQuestionaire = Undefined Then 
	
		CurrentQuestionaireObject.Write();
		
	EndIf;
	
EndProcedure

Function GUIDFromEnumValue(Value) 
	
	GUID = Mid(ValueToStringInternal(Value), StrLen(ValueToStringInternal(Value))-32,32);
	GUID = Left(GUID,8) + "-" + Mid(GUID,9,4) + "-" + Mid(GUID,13,4) + "-" + Mid(GUID,17,4) + "-" + Right(GUID,12);
	
	Return GUID;	
	
EndFunction

Function GetStringFromValue(Value) 
	
	TypeOfValue = TypeOf(Value);
	
	If TypeOfValue = Type("Boolean") Then  
				
		If Value Then
				
	    	Return "True";
				
		Else   
				
			Return "False";
				
		EndIf;
				
	ElsIf TypeOfValue = Type("Number") Then 
				
	    Value = String(Value);
        Value = StrReplace(Value, " ", "");
        Value = StrReplace(Value, Chars.NBSp, "");
		
		Return Value;
				
	ElsIf Enums.AllRefsType().ContainsType(TypeOfValue) Then 
			
		Return GUIDFromEnumValue(Value);
			
	ElsIf Catalogs.AllRefsType().ContainsType(TypeOfValue) Or Documents.AllRefsType().ContainsType(TypeOfValue) Then  
		
		Return String(Value.UUID());
						
	Else   
			
		Return String(Value);	
				
	EndIf;	    
	
EndFunction

Function GetSKUQuestionsGroup()
	
	SKUQuestionsGroupDescription = NStr("en='SKU questions (created automaticaly)';ru='Вопросы по номенклатуре (создано автоматически)';cz='SKU questions (created automaticaly)'");
	
	SKUQuestionsGroup = Catalogs.QuestionGroup.FindByDescription(SKUQuestionsGroupDescription);
	
	If SKUQuestionsGroup = Catalogs.QuestionGroup.EmptyRef() OR SKUQuestionsGroup.Type = Enums.QuestionGroupTypes.RegularQuestions Then
		
		SKUQuestionsGroup 				= Catalogs.QuestionGroup.CreateItem();
		SKUQuestionsGroup.Description 	= SKUQuestionsGroupDescription;
		SKUQuestionsGroup.Type 			= Enums.QuestionGroupTypes.SKUQuestions;
		
		SKUQuestionsGroup.Write();
		
	EndIf;	
	
	Return SKUQuestionsGroup.Ref;
	
EndFunction

Function GetSKUQuestion(SKUQuestion, SKUQuestionsAssignment)
	
	FindRows = SKUQuestionsAssignment.FindRows(New Structure("Assignment", SKUQuestion));
	
	If Not FindRows.Count() = 0 Then 
	
		Return FindRows.Get(0).Question;
		
	Else 
		
		Return Undefined;
		
	EndIf;
			
EndFunction

Function CreateQuestion(Description, Type, Assignment, Group)
	
	Question = Catalogs.Question.FindByAttribute("Assignment", Assignment, , Group);
	
	If Question = Catalogs.Question.EmptyRef() Then 	
	
		Question 				= Catalogs.Question.CreateItem();
		Question.Description 	= Description;
		Question.AnswerType 	= Type;
		Question.Owner 			= Group;
		Question.Assignment		= Assignment;
			
		Question.Write();
		
	EndIf;
	
	Return Question.Ref;
	
EndFunction

#EndRegion

#Region Update_Visits

Procedure UpdateSKUQuestionsInVisit()
    
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	Question.Ref AS Question,
		|	Question.Assignment AS Assignment
		|FROM
		|	Catalog.Question AS Question
		|WHERE
		|	NOT Question.Assignment = VALUE(Enum.SKUQuestions.EmptyRef)";
	
	SKUQuestionsAssignment = Query.Execute().Unload();
	
	Query = New Query();
    Query.Text = 
    "SELECT ALLOWED
    |   Visit.Ref
    |FROM
    |   Document.Visit AS Visit";
	
	RecordSet = query.Execute().Unload();
    
    For Each Row In RecordSet Do
        
        If Row.Ref.SKUs.Count() > 0 Then
			
			VisitObj = Row.Ref.GetObject();
			
			VT = VisitObj.SKUs.Unload();
			
			NewTable = VisitObj.SKUs.Unload();
            NewTable.Clear();
			
			For Each VTRow In VT Do
				
				If Not IsBlankString(VTrow.Available) Then
					
					NewRow 			= NewTable.Add();
                    NewRow.SKU 		= VTRow.SKU;
					
					FindRows = SKUQuestionsAssignment.FindRows(New Structure("Assignment", Enums.SKUQuestions.Available));
					
					NewRow.Question = FindRows.Get(0).Question;
					NewRow.Answer 	= VTRow.Available;
					
				EndIf;
				
				If Not IsBlankString(VTrow.Facing) Then
					
					NewRow 			= NewTable.Add();
                    NewRow.SKU 		= VTRow.SKU;
					
					FindRows = SKUQuestionsAssignment.FindRows(New Structure("Assignment", Enums.SKUQuestions.Facing));
					
					NewRow.Question = FindRows.Get(0).Question;
					NewRow.Answer 	= VTRow.Facing;
					
				EndIf;
				
				If Not IsBlankString(VTrow.Stock) Then
					
					NewRow 			= NewTable.Add();
                    NewRow.SKU 		= VTRow.SKU;
					
					FindRows = SKUQuestionsAssignment.FindRows(New Structure("Assignment", Enums.SKUQuestions.Stock));
					
					NewRow.Question = FindRows.Get(0).Question;
					NewRow.Answer 	= VTRow.Stock;
					
				EndIf;
				
				If Not IsBlankString(VTrow.Price) Then
					
					NewRow 			= NewTable.Add();
                    NewRow.SKU 		= VTRow.SKU;
					
					FindRows = SKUQuestionsAssignment.FindRows(New Structure("Assignment", Enums.SKUQuestions.Price));
					
					NewRow.Question = FindRows.Get(0).Question;
					NewRow.Answer 	= VTRow.Price;
					
                EndIf;
				
				If Not IsBlankString(VTrow.MarkUp) Then
					
					NewRow 			= NewTable.Add();
                    NewRow.SKU 		= VTRow.SKU;
					
					FindRows = SKUQuestionsAssignment.FindRows(New Structure("Assignment", Enums.SKUQuestions.MarkUp));
					
					NewRow.Question = FindRows.Get(0).Question;
					NewRow.Answer 	= VTRow.MarkUp;
					
				EndIf;
				
                If Not IsBlankString(VTrow.OutOfStock) Then
					
					NewRow 			= NewTable.Add();
                    NewRow.SKU 		= VTRow.SKU;
					
					FindRows = SKUQuestionsAssignment.FindRows(New Structure("Assignment", Enums.SKUQuestions.OutOfStock));
					
					NewRow.Question = FindRows.Get(0).Question;
					NewRow.Answer 	= VTRow.OutOfStock;
					
				EndIf;
				
                If Not IsBlankString(VTrow.Snapshot) Then
					
					NewRow 			= NewTable.Add();
                    NewRow.SKU 		= VTRow.SKU;
					
					FindRows = SKUQuestionsAssignment.FindRows(New Structure("Assignment", Enums.SKUQuestions.Snapshot));
					
					NewRow.Question = FindRows.Get(0).Question;
	        		NewRow.Answer 	= VTRow.Snapshot;
					
				EndIf;                
				
			EndDo;
            
            VisitObj.SKUs.Load(NewTable);
            VisitObj.Write();
            
        EndIf; 
                
    EndDo;
    
EndProcedure

#EndRegion

#EndRegion

#Region Release_1_6_0

Procedure UpdateForRelease_1_6_0(LastState, Step)

	WriteProtocol(LastState, Step, NStr("en='Update regions';ru='Обновление регионов';cz='Update regions'"));
	ProcessRegions();
	
	WriteProtocol(LastState, Step, NStr("en='Update territories';ru='Обновление территорий';cz='Update territories'"));
	ProcessTerritories();
	
	WriteProtocol(LastState, Step, NStr("en='Update visits';ru='Обновление визитов';cz='Aktualizovat návštěvy'"));
	ProcessVisits();
	
	WriteProtocol(LastState, Step, NStr("en='Update outlets statuses';ru='Обновление статусов торговых точек';cz='Update outlets statuses'"));
	ProcessOutletsStatuses();
	
	WriteProtocol(LastState, Step, NStr("en='Update SKU questions';ru='Обновление вопросов по номенклатуре';cz='Update SKU questions'"));
	ProcessPromoQuestion();
	
	WriteProtocol(LastState, Step, NStr("en='Update questionnaires';ru='Обновление анкет';cz='Update questionnaires'"));
	RewriteQuestionnaires();
	
EndProcedure

Procedure ProcessPromoQuestion()
	
	SKUQuestionsGroup = GetSKUQuestionsGroup();
	
	Question = CreateQuestion(NStr("en='Promo';ru='Промо';cz='Promo'"), Enums.DataType.Boolean, Enums.SKUQuestions.Promo, SKUQuestionsGroup);
	
EndProcedure

Procedure ProcessRegions()
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	Region.Ref AS Region,
		|	Region.Manager
		|FROM
		|	Catalog.Region AS Region";
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do 
		
		RegionObject = Selection.Region.GetObject();
		
		RegionObject.Managers.Clear();
		
		If ValueIsFilled(Selection.Manager) Then 
			
			InsToManagers					= RegionObject.Managers.Add();
			InsToManagers.Manager			= Selection.Manager;
			InsToManagers.LineNumberInUser	= 1;
			
		EndIf;
		
		RegionObject.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessTerritories()
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	Territory.Ref AS Territory,
		|	Territory.SR
		|FROM
		|	Catalog.Territory AS Territory";
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do 
		
		TerritoryObject = Selection.Territory.GetObject();
		
		If ValueIsFilled(Selection.SR) Then 
			
			InsToSRs					= TerritoryObject.SRs.Add();
			InsToSRs.SR					= Selection.SR;
			InsToSRs.LineNumberInUser	= 1;
			
		EndIf;
		
		TerritoryObject.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessVisits()
	
	Selection = Documents.Visit.Select();
	
	While Selection.Next() Do
		
		VisitObject = Selection.GetObject();
		VisitObject.Write(DocumentWriteMode.Write);
		
	EndDo;
	
EndProcedure

Procedure ProcessOutletsStatuses()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	OutletStatusHistorySliceLast.Period,
		|	OutletStatusHistorySliceLast.Outlet,
		|	OutletStatusHistorySliceLast.Status
		|INTO CurrentStatuses
		|FROM
		|	InformationRegister.OutletStatusHistory.SliceLast AS OutletStatusHistorySliceLast
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Outlets.Ref AS Outlet,
		|	Outlets.OutletStatus
		|FROM
		|	Catalog.Outlet AS Outlets
		|		LEFT JOIN CurrentStatuses AS CurrentStatuses
		|		ON Outlets.Ref = CurrentStatuses.Outlet
		|WHERE
		|	NOT Outlets.OutletStatus = CurrentStatuses.Status OR CurrentStatuses.Status IS NULL";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		Record			= InformationRegisters.OutletStatusHistory.CreateRecordManager();
		Record.Outlet	= Selection.Outlet;
		Record.Status	= Selection.OutletStatus;
		Record.Period	= CurrentDate();
		
		Record.Write();
		
	EndDo;
	
EndProcedure

Procedure RewriteQuestionnaires()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Questionnaire.Ref AS Questionnaire
		|FROM
		|	Document.Questionnaire AS Questionnaire";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		QuestionnaireObject = Selection.Questionnaire.GetObject();
		QuestionnaireObject.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Release_1_7_0

Procedure UpdateForRelease_1_7_0(LastState, Step)

	WriteProtocol(LastState, Step, NStr("en='Update encashments';ru='Обновление инкассаций';cz='Update encashments'"));
	ProcessEncashments();
	
	WriteProtocol(LastState, Step, NStr("en='Update outlets primary parameters settings';ru='Обновление настроек основных параметров торговых точек';cz='Update outlets primary parameters settings'"));
	ProcessOutletsPrimaryParametersSettings();
	
	WriteProtocol(LastState, Step, NStr("en='Update outlets parameters';ru='Обновление параметров торговых точек';cz='Update outlets parameters'"));
	ProcessOutletsParametersVisible();
	
	WriteProtocol(LastState, Step, NStr("en='Update skus';ru='Обновление номенклатуры';cz='Update skus'"));
	ProcessSKUPacking();
	
	WriteProtocol(LastState, Step, NStr("en='Update selectors in questionnaires';ru='Обновление параметров отбора в анкетах';cz='Update selectors in questionnaires'"));
	ProcessDateSelectors();
	
EndProcedure

Procedure ProcessEncashments()
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	Encashment.Ref AS Encashment,
		|	Encashment.DocNumber AS DocNumber
		|FROM
		|	Document.Encashment AS Encashment";
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do 
		
		If Selection.DocNumber = "0" Then 
		
			EncashmentObject = Selection.Encashment.GetObject();
			
			EncashmentObject.DocNumber = "";
			
			EncashmentObject.Write();
			
		ElsIf Find(Selection.DocNumber, Chars.NBSp) Then 
			
			EncashmentObject = Selection.Encashment.GetObject();
			
			EncashmentObject.DocNumber = StrReplace(Selection.DocNumber, Chars.NBSp, "");
			
			EncashmentObject.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessOutletsPrimaryParametersSettings()
	
	Selection = Catalogs.OutletsPrimaryParametersSettings.Select();
	
	While Selection.Next() Do
		
		Object = Selection.GetObject();
		Object.EditableInMA = NOT (Selection.Ref = Catalogs.OutletsPrimaryParametersSettings.Description OR 
								 Selection.Ref = Catalogs.OutletsPrimaryParametersSettings.Address);
		Object.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessOutletsParametersVisible()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	OutletParameter.Ref AS Parameter
		|FROM
		|	Catalog.OutletParameter AS OutletParameter";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		ParameterObject				= Selection.Parameter.GetObject();
		ParameterObject.VisibleInMA	= True;
		
		ParameterObject.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessSKUPacking()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SKU.Ref AS SKU
		|FROM
		|	Catalog.SKU AS SKU";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		SKUObject = Selection.SKU.GetObject();
		
		SKUObject.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessDateSelectors()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Questionnaire.Ref AS Questionnaire
		|FROM
		|	Document.Questionnaire.Selectors AS QuestionnaireSelectors
		|		LEFT JOIN Document.Questionnaire AS Questionnaire
		|		ON QuestionnaireSelectors.Ref = Questionnaire.Ref
		|WHERE
		|	QuestionnaireSelectors.AdditionalParameter.DataType = VALUE(Enum.DataType.DateTime)";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		QuestionnaireObject = Selection.Questionnaire.GetObject();
		
		For Each StrSelector In QuestionnaireObject.Selectors Do
			
			If ValueIsFilled(StrSelector.AdditionalParameter) Then 
				
				If StrSelector.AdditionalParameter.DataType = Enums.DataType.DateTime And ValueIsFilled(StrSelector.Value) Then 
					
					StrSelector.StringValue = String(StrSelector.Value);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		QuestionnaireObject.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Release_1_8_0

Procedure UpdateForRelease_1_8_0(LastState, Step)
	
	WriteProtocol(LastState, Step, NStr("en='Update outlet statuses settings';ru='Обновление настроек статусов торговых точек';cz='Update outlet statuses settings'"));
	ProcessOutletsStatusesSettings();
	
	WriteProtocol(LastState, Step, NStr("en='Update mobile apps settings';ru='Обновление настроек мобильных приложений';cz='Update mobile apps settings'"));
	ProcessSnapshotSize();
	
	WriteProtocol(LastState, Step, NStr("en='Update user roles';ru='Обновление ролей пользователей';cz='Update user roles'"));
	ProcessUserRights();
	
	WriteProtocol(LastState, Step, NStr("en='Update application settings';ru='Обновление настроек приложения';cz='Update application settings'"));
	ProcessNewAccessSettings();
	
	WriteProtocol(LastState, Step, NStr("en='File processing';ru='Обработка файлов';cz='Zpracování souborů'"));
	ProcessFiles();
	
	WriteProtocol(LastState, Step, NStr("en='Update visits';ru='Обновление визитов';cz='Aktualizovat návštěvy'"));
	ProcessRewriteAllVisits();
	
EndProcedure

Procedure ProcessOutletsStatusesSettings()
	
	PotentialObject = Catalogs.OutletsStatusesSettings.Potential.GetObject();
	PotentialObject.Status = Enums.OutletStatus.Potential;
	PotentialObject.ShowOutletInMA = True;
	PotentialObject.DoVisitInMA = True;
	PotentialObject.CreateOrderInMA = False;
	PotentialObject.FillQuestionnaireInMA = True;
	PotentialObject.DoEncashmentInMA = False;
	PotentialObject.CreateReturnInMA = False;
	PotentialObject.Write();
	
	ActiveObject = Catalogs.OutletsStatusesSettings.Active.GetObject();
	ActiveObject.Status = Enums.OutletStatus.Active;
	ActiveObject.ShowOutletInMA = True;
	ActiveObject.DoVisitInMA = True;
	ActiveObject.CreateOrderInMA = True;
	ActiveObject.FillQuestionnaireInMA = True;
	ActiveObject.DoEncashmentInMA = True;
	ActiveObject.CreateReturnInMA = True;
	ActiveObject.Write();
	
	ClosedObject = Catalogs.OutletsStatusesSettings.Closed.GetObject();
	ClosedObject.Status = Enums.OutletStatus.Closed;
	ClosedObject.ShowOutletInMA = False;
	ClosedObject.DoVisitInMA = False;
	ClosedObject.CreateOrderInMA = False;
	ClosedObject.FillQuestionnaireInMA = False;
	ClosedObject.DoEncashmentInMA = False;
	ClosedObject.CreateReturnInMA = False;
	ClosedObject.Write();
	
EndProcedure

Procedure ProcessSnapshotSize()
	
	SettingObject = Catalogs.MobileAppSettings.SnapshotSize.GetObject();
	SettingObject.NumericValue = 300;
	SettingObject.Write();
	
EndProcedure

Procedure ProcessUserRights()
	
	UserRoleObject = Catalogs.RolesOfUsers.SRM.GetObject();
	NewRight = UserRoleObject.AccessRightsToSystemObjects.Add();
	NewRight.SystemObject = Catalogs.SystemObjects.Document_Return;
	NewRight.Read = True;
	NewRight.Edit = True;
	NewRight.Edit = True;
	UserRoleObject.Write();
	
EndProcedure

Procedure ProcessNewAccessSettings()
	
	Constants.UseReturns.Set(True);
    Constants.UseOrders.Set(True);
    Constants.UseEncashments.Set(True);
	
EndProcedure

Procedure ProcessFiles()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	bitmobile_ХранилищеФайлов.Объект,
		|	bitmobile_ХранилищеФайлов.НаправлениеСинхронизации,
		|	bitmobile_ХранилищеФайлов.Действие,
		|	bitmobile_ХранилищеФайлов.ИмяФайла,
		|	bitmobile_ХранилищеФайлов.ПолноеИмяФайла,
		|	bitmobile_ХранилищеФайлов.Расширение,
		|	bitmobile_ХранилищеФайлов.Хранилище,
		|	bitmobile_ХранилищеФайлов.ФайлЗаблокирован
		|FROM
		|	InformationRegister.bitmobile_ХранилищеФайлов AS bitmobile_ХранилищеФайлов";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	FilesRecordset = InformationRegisters.bitmobile_ХранилищеФайлов.CreateRecordSet();
	
	While Selection.Next() Do
		
		FileRecord = FilesRecordset.Add();
		
		FillPropertyValues(FileRecord, Selection);
		
		If Not Selection.Действие = Enums.bitmobile_ДействияПриСинхронизации.УдалитьФайл Then  
			
			FileRecord.Действие = Enums.bitmobile_ДействияПриСинхронизации.ДобавитьФайл;
			
		EndIf;
		
	EndDo;
	
	FilesRecordset.Write();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	AnsweredQuestions.Questionaire,
		|	AnsweredQuestions.Outlet,
		|	AnsweredQuestions.Question,
		|	AnsweredQuestions.SKU,
		|	AnsweredQuestions.Answer,
		|	AnsweredQuestions.AnswerDate,
		|	AnsweredQuestions.Visit,
		|	AnsweredQuestions.UploadSnapshot,
		|	AnsweredQuestions.Snapshot
		|FROM
		|	InformationRegister.AnsweredQuestions AS AnsweredQuestions
		|WHERE
		|	AnsweredQuestions.Question.AnswerType = VALUE(Enum.DataType.Snapshot)";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.Answer) Then
			
			RecordManager = InformationRegisters.AnsweredQuestions.CreateRecordManager();
			
			FillPropertyValues(RecordManager, Selection);
			
			RecordManager.UploadSnapshot	= True;
			RecordManager.Snapshot			= New UUID(Selection.Answer);
			
			RecordManager.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessRewriteAllVisits()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Visit.Ref
		|FROM
		|	Document.Visit AS Visit";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		VisitObject = Selection.Ref.GetObject();
		
		VisitObject.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Release_1_9_0

Procedure UpdateForRelease_1_9_0(LastState, Step)
	
	WriteProtocol(LastState, Step, NStr("en = 'Update contractors'; ru = 'Обновление контрагентов'"));
	ProcessContractors();
	
	WriteProtocol(LastState, Step, NStr("en = 'Update contacts'; ru = 'Обновление контактов'"));
	ProcessContacts();
	
	WriteProtocol(LastState, Step, NStr("en='Update territories';ru='Обновление территорий';cz='Update territories'"));
	ProcessTerritoriesOutletsAndStocks();
	
	WriteProtocol(LastState, Step, NStr("en = 'Update pricelists'; ru = 'Обновление прайс-листов'"));
	ProcessPriceLists();
	
	WriteProtocol(LastState, Step, NStr("en = 'Update mobile app settings'; ru = 'Обновление настроек мобильного приложения'"));
	ProcessUserCoordinatesActualityTime();
	
EndProcedure

Procedure ProcessContractors()
	
	Selection = Catalogs.Outlet.Select();
	
	While Selection.Next() Do
		
		OutletObject = Selection.GetObject();
		OutletObject.Distributor = Catalogs.Distributor.EmptyRef();
		
		If OutletObject.ContractorsList.Count() = 0 Then
		
			If ValueIsFilled(Selection.INN) Then
				
				ContractorRef = Catalogs.Contractors.FindByAttribute("INN", Selection.INN);
				
				If ContractorRef = Catalogs.Contractors.EmptyRef() Then
					
					ContractorObject = Catalogs.Contractors.CreateItem();
					
				Else
					
					ContractorObject = ContractorRef.GetObject();
					
				EndIf;
				
			Else
				
				ContractorObject = Catalogs.Contractors.CreateItem();
				
			EndIf;
			
			FillPropertyValues(ContractorObject, Selection, "Email, INN, KPP, LegalAddress, LegalName, OwnershipType, PhoneNumber, WebSite");
			ContractorObject.Description = ?(ValueIsFilled(Selection.LegalName), Selection.LegalName, Selection.Description);
			
			Query = New Query(
			"SELECT
			|	TerritoryOutlets.Ref AS Territory
			|FROM
			|	Catalog.Territory.Outlets AS TerritoryOutlets
			|WHERE
			|	TerritoryOutlets.Outlet = &Outlet");
			Query.SetParameter("Outlet", OutletObject.Ref);
			Result = Query.Execute().Unload();
			
			For Each Row In Result Do
				
				TerritoryExists = NOT ContractorObject.Territories.Find(Row.Territory) = Undefined;
				
				If Not TerritoryExists Then
					
					TerritoryRow = ContractorObject.Territories.Add();
					TerritoryRow.Territory = Row.Territory;
					
				EndIf;
				
			EndDo;
			
			For Each TerritoryRow In ContractorObject.Territories Do
				
				RegionExists = Not ContractorObject.Regions.Find(Row.Territory.Owner) = Undefined;
				
				If Not RegionExists Then
					
					RegionRow = ContractorObject.Regions.Add();
					RegionRow.Region = TerritoryRow.Territory.Owner;
					
				EndIf;
				
			EndDo;
			
			ContractorObject.Write();
			
			ContractorRow = OutletObject.ContractorsList.Add();
			ContractorRow.Contractor = ContractorObject.Ref;
			ContractorRow.Default = True;
			
			OutletObject.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessContacts()
	
	Selection = Catalogs.Outlet.Select();
	
	While Selection.Next() Do
		
		OutletObject = Selection.GetObject();
		
		For Each Row In Selection.Contacts Do
			
			ContactObject = Catalogs.ContactPersons.CreateItem();
			FillPropertyValues(ContactObject, Row, "Position, PhoneNumber, Email");
			ContactObject.Description = ?(ValueIsFilled(TrimAll(Row.ContactName)), Row.ContactName, Selection.Description);
			ContactObject.Write();
			
			NewRow = OutletObject.ContactPersons.Add();
			NewRow.ContactPerson = ContactObject.Ref;
			NewRow.NotActual = Row.NotActual;
			
		EndDo;
		
		OutletObject.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessTerritoriesOutletsAndStocks()
	
	Selection = Catalogs.Territory.Select();
	
	While Selection.Next() Do
		
		TerritoryObject = Selection.GetObject();
		
		EmptyOutletStructure = New Structure;
		EmptyOutletStructure.Insert("Outlet", Catalogs.Outlet.EmptyRef());
		EmptyOutletRows = TerritoryObject.Outlets.FindRows(EmptyOutletStructure);
		
		For Each EmptyOutletRow In EmptyOutletRows Do
			
			EmptyOutletRowIndex = TerritoryObject.Outlets.IndexOf(EmptyOutletRow);
			TerritoryObject.Outlets.Delete(EmptyOutletRowIndex);
			
		EndDo;
		
		EmptyStockStructure = New Structure;
		EmptyStockStructure.Insert("Stock", Catalogs.Stock.EmptyRef());
		EmptyStockRows = TerritoryObject.Stocks.FindRows(EmptyStockStructure);
		
		For Each EmptyStockRow In EmptyStockRows Do
			
			EmptyStockRowIndex = TerritoryObject.Stocks.IndexOf(EmptyStockRow);
			TerritoryObject.Outlets.Delete(EmptyStockRowIndex);
			
		EndDo;
		
		TerritoryObject.Write();
		
	EndDo;
	
EndProcedure

Procedure ProcessPriceLists()
	
	Query = New Query(
	"SELECT
	|	PriceListPrices.Ref AS PriceList,
	|	PriceListPrices.SKU,
	|	MAX(PriceListPrices.Price) AS Price
	|FROM
	|	Document.PriceList.Prices AS PriceListPrices
	|
	|GROUP BY
	|	PriceListPrices.Ref,
	|	PriceListPrices.SKU");
	PricesVT = Query.Execute().Unload();
	RecordSet = InformationRegisters.Prices.CreateRecordSet();
	RecordSet.Load(PricesVT);
	RecordSet.Write();
	
EndProcedure

Procedure ProcessUserCoordinatesActualityTime()
	
	SettingObject = Catalogs.MobileAppSettings.UserCoordinatesActualityTime.GetObject();
	SettingObject.NumericValue = 5;
	SettingObject.Write();
	
EndProcedure

#EndRegion

#Region Release_1_10_0

Procedure UpdateForRelease_1_10_0(LastState, Step)
	
	WriteProtocol(LastState, Step, NStr("en = 'Update mobile application access rights'; ru = 'Обновление прав в мобильном приложении'"));
	ProcessMobileAppAccessRights();
	
EndProcedure

Procedure ProcessMobileAppAccessRights()
	
	SRRoleRef = Catalogs.RolesOfUsers.SR;
	SRRoleObject = SRRoleRef.GetObject();
	MobileAppAccessRight = SRRoleObject.MobileAppAccessRights.Add();
	MobileAppAccessRight.AccessRight = Catalogs.MobileAppAccessRights.PercentDiscount;
	SRRoleObject.Write();
	
EndProcedure

#EndRegion

#Region Release_1_11_0

Procedure UpdateForRelease_1_11_0(LastState, Step) Export
	
	WriteProtocol(LastState, Step, NStr("en = 'Update tasks'; ru = 'Обновление Задач'"));
	Res = ProcessTasksUpdate();
	If ValueIsFilled(Res) Then
		WriteProtocol(LastState, Step, NStr("en = 'Update tasks ERRORS'; ru = 'ОШИБИ при обновлении Задач'"));
	EndIf;
	
EndProcedure

Procedure UpdateForRelease_1_11_1(LastState, Step) Export
	
	WriteProtocol(LastState, Step, NStr("en='Update users';ru='Обновление пользователей';cz='Aktualizovat uživatele'"));
	ProcessUserUpdate();
	
EndProcedure

Procedure ProcessUserUpdate()
	
	Select = Catalogs.User.Select();
	
	While Select.Next() Do
		
		UserObj = Select.GetObject();
		UserObj.Write();
		
	EndDo;
	
EndProcedure

Function ProcessTasksUpdate() Export
	
	Query = New Query("SELECT
	                  |	Task.Ref AS TaskRef,
	                  |	Visitdeprecated_Task.TextTask AS depTaskTextTask,
	                  |	Visitdeprecated_Task.Result AS depTaskResult,
	                  |	VisitPlan.SR AS VisitPlanSR,
	                  |	VisitPlan.Owner AS VisitPlanOwner,
	                  |	Visitdeprecated_Task.Ref.SR AS depTaskSR1,
	                  |	Visitdeprecated_Task.Ref.Outlet AS depTaskOutlet,
	                  |	Task.deprecated_StatusTask,
	                  |	Task.deprecated_Target
	                  |FROM
	                  |	Document.Task AS Task
	                  |		LEFT JOIN Document.VisitPlan AS VisitPlan
	                  |		ON Task.deprecated_VisitPlan = VisitPlan.Ref
	                  |		LEFT JOIN Document.Visit.deprecated_Task AS Visitdeprecated_Task
	                  |		ON Task.Ref = Visitdeprecated_Task.TaskRef");
					  
	QueryRes = Query.Execute();
	
	If QueryRes.IsEmpty() Then
		Return("");
	EndIf;
	
	Selection = QueryRes.Select();
	
	Protocol = "";	
	
	While Selection.Next() Do
		TaskObj = Selection.TaskRef.GetObject();
		
		TaskObj.TextTask 		= 	StrReplace(TaskObj.TextTask, Selection.depTaskTextTask,"") + Selection.depTaskTextTask;
		TaskObj.Status 			= 	True; // ?(TaskObj.Status, True, ?(Selection.deprecated_StatusTask=Enums.StatusTask.Completed, True, Selection.depTaskResult));
		TaskObj.ExecutionDate	= 	CurrentSessionDate();
		TaskObj.PlanExecutor 	= 	?(ValueIsFilled(TaskObj.PlanExecutor), TaskObj.PlanExecutor, Selection.VisitPlanSR);
		TaskObj.FactExecutor 	= 	?(ValueIsFilled(TaskObj.FactExecutor), TaskObj.FactExecutor, Selection.depTaskSR1);
		TaskObj.Responsible 	= 	?(ValueIsFilled(TaskObj.Responsible), TaskObj.Responsible, Selection.VisitPlanOwner);
		TaskObj.Outlet 			= 	?(ValueIsFilled(TaskObj.Outlet), TaskObj.Outlet, Selection.depTaskOutlet);
		AdditionalComment 		= 	NStr("en = 'Edited by Update Procedure'; ru = 'Изменено процедурой обновления'");
		TaskObj.TextTask 		= 	StrReplace(TaskObj.TextTask, AdditionalComment,"") + AdditionalComment;
		
		If ValueIsFilled(TaskObj.Outlet) Then
			Try
				TaskObj.Write();
			Except
				Protocol = Protocol + NStr("en = 'Task update ERROR'; ru = 'Ошибка при обновлении Задач'")+": "+ОписаниеОшибки()+Символы.ПС;
			EndTry;
		Else
			Try
				TaskObj.Delete();
			Except
				Protocol = Protocol + NStr("en = 'Task update ERROR'; ru = 'Ошибка при обновлении Задач'")+": "+ОписаниеОшибки()+Символы.ПС;
			EndTry;
		EndIf;
	EndDo;
	
EndFunction

#EndRegion

#Region Release_1_12_0

Procedure UpdateForRelease_1_12_0(LastState, Step) Export
	//
	//WriteProtocol(LastState, Step, NStr("en = 'Update gps tracking settings'; ru = 'Обновление настроек GPS'"));
	//ProcessGPSTrackingSettings();
	//
	//WriteProtocol(LastState, Step, NStr("en = 'Update visit plans'; ru = 'Обновление планов визитов'"));
	//ProcessVisitPlans();
	//
EndProcedure

Procedure ProcessGPSTrackingSettings()
	
	Constants.DefaultCity.Set(NStr("en = 'Moscow'; ru = 'Москва'"));
	
	GPSSourceObject = Catalogs.MobileAppSettings.GPSSource.GetObject();
	GPSSourceObject.LogicValue = False;
	
	GPSSourceObject.Write();
	
	GPSTrackSendFrequencyObject = Catalogs.MobileAppSettings.GPSTrackSendFrequency.GetObject();
	GPSTrackSendFrequencyObject.NumericValue = 300;
	
	GPSTrackSendFrequencyObject.Write();
	
	GPSTrackWriteFrequencyObject = Catalogs.MobileAppSettings.GPSTrackWriteFrequency.GetObject();
	GPSTrackWriteFrequencyObject.NumericValue = 300;
	
	GPSTrackWriteFrequencyObject.Write();
	
EndProcedure

#EndRegion

#Region Release_1_12_1

Procedure UpdateForRelease_1_12_1(LastState, Step) Export
	
	WriteProtocol(LastState, Step, NStr("en = 'Update visit plans'; ru = 'Обновление планов визитов'"));
	ProcessVisitPlans();
	
	//Попытка удаления всех пользовательских элементов справочника MobileAppAccessRights, не связанных с предопределенными
	Query=New Query;
	Query.Text= 
	"SELECT
	|	MobileAppAccessRights.Predefined,
	|	MobileAppAccessRights.Ref
	|FROM
	|	Catalog.MobileAppAccessRights AS MobileAppAccessRights
	|WHERE
	|	MobileAppAccessRights.Predefined = FALSE";
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
	Try 
		//FillPropertyValues(SRMRole.AccessRightsToSystemObjects.Add(), Selection);
		Object=Selection.Ref.GetObject();
		Object.Delete();
	Except 
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='Not all outdated elements of the catalog _Access rights in mobile app_ were removed!';ru='Не все устаревшие элементы справочника _Права доступа в мобильном приложении_ удалось удалить!';cz='Not all outdated elements of the catalog _Access rights in mobile app_ were removed!'");		
		UserMessage.Message();
	EndTry;
	EndDo;
EndProcedure

Procedure ProcessVisitPlans()
	
	VisitPlanSelection = Documents.VisitPlan.Select();
	
	While VisitPlanSelection.Next() Do
		
		VisitPlanRef = VisitPlanSelection.Ref;
		ChangedDataSelection = InformationRegisters.bitmobile_ИзмененныеДанные.Select(New Structure("Ссылка", VisitPlanRef));
		RemoveVisitPlanFromChangedData = Not ChangedDataSelection.Next();
		
		VisitPlanObject = VisitPlanSelection.GetObject();
		VisitPlanObject.WeekNumber = VisitPlanObject.GetWeekOfYear(VisitPlanObject.DateFrom);
		VisitPlanObject.Year = VisitPlanObject.GetYear(VisitPlanObject.DateFrom);
		VisitPlanObject.Write();
		
		If RemoveVisitPlanFromChangedData Then
			
			RecordSet = InformationRegisters.bitmobile_ИзмененныеДанные.CreateRecordSet();
			RecordSet.Filter.Ссылка.Set(VisitPlanRef);
			RecordSet.Clear();
			RecordSet.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion