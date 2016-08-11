
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnOpenServer()
	
	If InfoBaseUsers.CurrentUser().Language = Metadata.Languages.Русский Then 
		
		PictAddress = PutToTempStorage(PictureLib.Logo_Ru, ThisForm.UUID);
		
	Else 
		
		PictAddress = PutToTempStorage(PictureLib.Logo_En, ThisForm.UUID);
		
	EndIf;
	
	LogoText = GetCommonTemplate("Logo").GetText();
	
	Logo = StrReplace(LogoText, "//-PictureAddress-//", PictAddress);
	
	DBSessions 		= GetInfoBaseSessions();
	SessionNumber 	= InfoBaseSessionNumber();
				
	For Each DBSession In DBSessions Do  
		
		If DBSession.SessionNumber = SessionNumber Тогда 
			
			IDSession = String(DBSession.SessionNumber) + String(DBSession.SessionStarted);
			
		EndIf;
		
	EndDo;
		
EndProcedure

&AtServer
Procedure CheckSyncState(SyncStarted)
	
	Try
		
		SyncStarted = Constants.bitmobile_СинхронизацияЗапущена.Get();
		
	Except
		                      
		Return;

	EndTry;
					
EndProcedure

&AtServer
Function CheckAsyncUpload(IDUpload, IDForm)
	
	 DataProcessors.bitmobile_СинхронизацияИНастройки.ПроверитьАсинхроннуюВыгрузку(IDUpload, IDForm);
	 
	 GetUserMessages(True);
	 
EndFunction
 
&AtServer
Function GetIDUpload()
	
	Return Constants.bitmobile_IDВыгрузки.Get();

EndFunction

&AtServer
Function GetUploadInfo(LastDate, LastStatus)

	LastDate 	= Constants.bitmobile_ДатаПоследнейВыгрузкиДанных.Get();
    LastStatus 	= Constants.bitmobile_СтатусПоследнейВыгрузкиДанных.Get();

EndFunction

&AtServer
Function GetDownloadInfo(LastDate, LastStatus)

	LastDate 	= Constants.bitmobile_ДатаПоследнейЗагрузкиДанных.Get();
    LastStatus 	= Constants.bitmobile_СтатусПоследнейЗагрузкиДанных.Get();

EndFunction

&AtServer
Function GetFilesSyncInfo(LastDate, LastStatus, FilesSyncStarted)

	LastDate 			= Constants.bitmobile_ДатаПоследнейСинхронизацииФайлов.Get();
    LastStatus 			= Constants.bitmobile_СтатусПоследнейСинхронизацииФайлов.Get();
	FilesSyncStarted 	= Constants.bitmobile_СинхронизацияФайловЗапущена.Get();
	
EndFunction

&AtServer 
Procedure SyncronizeDataServer()
	
	SyncStarted = "";
	
	CheckSyncState(SyncStarted);
	
	If Not ValueIsFilled(SyncStarted) Then 
		
		bitmobile_ОбработчикиСинхронизацииИПодписок.Синхронизация();
		
	EndIf;	
	
	GetUserMessages(True);
	
EndProcedure

&AtServer
Procedure SyncronizeFilesServer()
	
	IsAlreadyStarted = Constants.bitmobile_СинхронизацияФайловЗапущена.Get();
	
	If Not IsAlreadyStarted Then 
		
		ConstantIsSet = False;	
		
		Try
		
			Constants.bitmobile_СинхронизацияФайловЗапущена.Set(True);
			
			ConstantIsSet = True;
			
		Except
				
		EndTry;
		
		If ConstantIsSet Then 
		
			DataProcessors.bitmobile_СинхронизацияИНастройки.СинхронизироватьФайлы();
			
			Constants.bitmobile_СинхронизацияФайловЗапущена.Set(False);
			
		EndIf;
		
	EndIf;	
	
	GetUserMessages(True);
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenServer();
	
	UpdateTextInfo();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ReloadInfoOnStartPage" Then 
		
		UpdateTextInfo(True);
		
	EndIf;
		
EndProcedure

&AtClient
Procedure SetUploadInfo(LastDate, LastStatus, IsDataProcessorNotification, IDUpload = "")
	
	If ValueIsFilled(IDUpload) Then  
		                          
		Items.DateUpload.TextColor = WebColors.Green;
		DateUpload = NStr("en='In progress';ru='Выполняется';cz='In progress'");
		
		If Not IsDataProcessorNotification Then
			
			AttachIdleHandler("CheckUpload", 20);
			
		EndIf;
		
	Else
	
		If ValueIsFilled(LastDate) Then 
			
			If LastStatus Then 
				
				Items.DateUpload.TextColor = WebColors.Green;
				DateUpload = String(LastDate) + NStr("en = ' (completed)'; ru = ' (выполнена)'");
				
			Else 
				
				Items.DateUpload.TextColor = WebColors.Red;
				DateUpload = String(LastDate) + NStr("en = ' (not completed)'; ru = ' (не выполнена)'");
							
			EndIf;
					
		Else 
			
			Items.DateUpload.TextColor = WebColors.Red;
			DateUpload = NStr("en='No Information';ru='Нет данных';cz='No Information'");
							
		EndIf;
		
		DetachIdleHandler("CheckUpload");
		
	EndIf;
		
EndProcedure

&AtClient
Procedure SetDownloadInfo(LastDate, LastStatus)
	
	If ValueIsFilled(LastDate) Then 
			
		If LastStatus Then 
			
			Items.DateDownload.TextColor = WebColors.Green;
			DateDownload = String(LastDate) + NStr("en = ' (completed)'; ru = ' (выполнена)'");
			
		Else 
			
			Items.DateDownload.TextColor = WebColors.Red;
			DateDownload = String(LastDate) + NStr("en = ' (not completed)'; ru = ' (не выполнена)'");
						
		EndIf;
				
	Else 
		
		Items.DateDownload.TextColor = WebColors.Red;
		DateDownload = NStr("en='No Information';ru='Нет данных';cz='No Information'");
						
	EndIf;
	
EndProcedure

&AtClient
Procedure SetFilesSyncInfo(LastDate, LastStatus, IsDataProcessorNotification, FilesSyncStarted)
	
	If FilesSyncStarted Then 
		
		Items.FilesSync.TextColor = WebColors.Green;
		FilesSync = NStr("en='In progress';ru='Выполняется';cz='In progress'");
		
		If Not IsDataProcessorNotification Then
			
			AttachIdleHandler("CheckFilesSync", 20);
			
		EndIf;
		
	Else
	
		If ValueIsFilled(LastDate) Then 
				
			If LastStatus Then 
				
				Items.FilesSync.TextColor = WebColors.Green;
				FilesSync = String(LastDate) + NStr("en = ' (completed)'; ru = ' (выполнена)'");
				
			Else 
				
				Items.FilesSync.TextColor = WebColors.Red;
				FilesSync = String(LastDate) + NStr("en = ' (completed with errors)'; ru = ' (выполнена с ошибками)'");
							
			EndIf;
					
		Else 
			
			Items.FilesSync.TextColor = WebColors.Red;
			FilesSync = NStr("en='No information';ru='Нет данных';cz='No information'");
							
		EndIf;
		
		DetachIdleHandler("CheckFilesSync");
		
	EndIf;
		
EndProcedure

&AtClient
Procedure CheckUpload()
	
	CheckAsyncUpload(IDUpload, ThisForm.UUID);
	
	UpdateTextInfo();
					
EndProcedure

&AtClient
Procedure CheckFilesSync()
	
	UpdateTextInfo();
					
EndProcedure

&AtClient
Procedure UpdateTextInfo(IsDataProcessorNotification = False)
	
	IDUpload = GetIDUpload();
			
	LastDate 	= Undefined;
	LastStatus 	= False;
	
	GetUploadInfo(LastDate, LastStatus);
	SetUploadInfo(LastDate, LastStatus, IsDataProcessorNotification, IDUpload);
	
	LastDate 	= Undefined;
	LastStatus 	= False;
	
	GetDownloadInfo(LastDate, LastStatus);
	SetDownloadInfo(LastDate, LastStatus);
	
	LastDate 			= Undefined;
	LastStatus 			= False;
	FilesSyncStarted 	= False;
	
	GetFilesSyncInfo(LastDate, LastStatus, FilesSyncStarted);
	SetFilesSyncInfo(LastDate, LastStatus, IsDataProcessorNotification, FilesSyncStarted);
	
	If Not IsDataProcessorNotification Then 
		
		Notify("ОбновитьИнформациюОСинхронизации");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SyncronizeData(Command)
	
	SyncronizeDataServer();
	
	UpdateTextInfo();
	
EndProcedure

&AtClient
Procedure SyncronizeFiles(Command)
	
	SyncronizeFilesServer();
	
	UpdateTextInfo();
	
EndProcedure

&AtClient
Procedure UpdateInfo(Command)
	
	UpdateTextInfo();	
	
EndProcedure

#EndRegion