
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Object.Role = "Admin" Then 
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='Changing users with full rights is disabled';ru='Нельзя изменять пользователей с полными правами';cz='Ъpravy nad sprбvci provйst nelze.'");
		
		UserMessage.Message();
		
		ThisForm.ReadOnly = True;
		
		Items.RoleOfUser.Visible = False;
		Items.Password.Visible = False;
		Items.Manager.Visible = False;
		Items.Position.Visible = False;
		Items.EMail.Visible = False;
		Items.GenerateRandomPassword.Visible = False;
		Items.SendUserPassword.Visible = False;
		
	EndIf;
	
	// Заполнить языки интерфейса
	If Metadata.Languages.Count() < 2 Then 
		
		Items.InterfaceLanguage.Visible = False;
		
	Else 
		
		For Each MetaLanguage In Metadata.Languages Do 
			
			Items.InterfaceLanguage.ChoiceList.Add(MetaLanguage.Name);
			
		EndDo;
		
	EndIf;
		
	If Not ValueIsFilled(Object.Ref) Then 
		
		// Первоначальное заполнение пользователя
		Object.InterfaceLanguage = Metadata.Languages.Русский.Name;
		
	Else 
		
		// Запрет изменения логина у уже записанного пользователя
		Items.Login.ReadOnly = True;
		
	EndIf;
	If Parameters.CopyingValue<>Catalogs.User.EmptyRef() Then 
		Object.UserID = new UUID("00000000-0000-0000-0000-000000000000");
		FillRegionsFromCopy();
		FillTerritoriesFromCopy();
	Else
		FillRegions();
		FillTerritories();
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not CurrentObject.Role = "Admin" Then 
	
		If Not ValueIsFilled(Object.RoleOfUser) Then 
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en='Not filled role of user';ru='Не заполнена роль пользователя';cz='Not filled role of user'");
			
			UserMessage.Message();
			
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Password) Then 
			
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='It is forbidden to create a user with a blank password';ru='Запрещено создавать пользователей с пустым паролем';cz='It is forbidden to create a user with a blank password'");
		
		UserMessage.Message();
		
		Cancel = True;
		
	EndIf;
	
	If Not ValueIsFilled(Object.InterfaceLanguage) Then 
			
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='Not filled interface language';ru='Не заполнен язык интерфейса';cz='Not filled interface language'");
		
		UserMessage.Message();
		
		Cancel = True;
		
	EndIf;
	
	// Проверить заполнение таблиц регионов и территорий
	If Object.RoleOfUser.Role = "SRM_SR" Or Object.RoleOfUser.Role = "SRM" Then 
		
		If Regions.Count() = 0 Then 
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en='User has access to the information base, the list of regions must be filled.';ru='Пользователь имеет доступ в информационную базу, список регионов должен быть заполнен.';cz='User has access to the information base, the list of regions must be filled.'");
			
			UserMessage.Message();
			
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
	If Object.RoleOfUser.Role = "SRM_SR" Or Object.RoleOfUser.Role = "SR" Then 
		
		If Territories.Count() = 0 Then 
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en='User has access to a mobile application, the list of territories must be filled.';ru='Пользователь имеет доступ к мобильному приложению, список территорий должен быть заполнен.';cz='User has access to a mobile application, the list of territories must be filled.'");
			
			UserMessage.Message();
			
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not Cancel Then 
		
		SetPrivilegedMode(True);
		
		// Записать пользователя в регионы
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	RegionManagers.Ref AS Region
			|FROM
			|	Catalog.Region.Managers AS RegionManagers
			|WHERE
			|	RegionManagers.Manager = &User
			|	AND NOT RegionManagers.Ref IN (&RGArray)";
		
		Query.SetParameter("User", CurrentObject.Ref);
		Query.SetParameter("RGArray", Regions.Unload().UnloadColumn("Region"));
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			RGObject = Selection.Region.GetObject();
			
			FoundString = RGObject.Managers.Find(CurrentObject.Ref);
			
			If Not FoundString = Undefined Then 
				
				RGObject.Managers.Delete(FoundString);
				
			EndIf;
			
			RGObject.Write();
			
		EndDo;
			
		For Each Row In Regions Do 
			
			RGObject = Row.Region.GetObject();
			
			FoundString = RGObject.Managers.Find(CurrentObject.Ref);
			
			If FoundString = Undefined Then 
				
				NewRow					= RGObject.Managers.Add();
				NewRow.Manager			= CurrentObject.Ref;
				NewRow.LineNumberInUser	= Row.LineNumber;
				
			Else 
				
				FoundString.LineNumberInUser = Row.LineNumber;
				
			EndIf;
			
			RGObject.Write();
			
		EndDo;
		
		// Записать пользователя в территории
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	TerritorySRs.Ref AS Territory
			|FROM
			|	Catalog.Territory.SRs AS TerritorySRs
			|WHERE
			|	TerritorySRs.SR = &User
			|	AND NOT TerritorySRs.Ref IN (&TRArray)";
		
		Query.SetParameter("User", CurrentObject.Ref);
		Query.SetParameter("TRArray", Territories.Unload().UnloadColumn("Territory"));
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			TRObject = Selection.Territory.GetObject();
			
			FoundString = TRObject.SRs.Find(Object.Ref);
			
			If Not FoundString = Undefined Then 
				
				TRObject.SRs.Delete(FoundString);
				
			EndIf;
			
			TRObject.Write();
			
		EndDo;
			
		For Each Row In Territories Do 
			
			TRObject = Row.Territory.GetObject();
			
			FoundString = TRObject.SRs.Find(CurrentObject.Ref);
			
			If FoundString = Undefined Then 
				
				NewRow					= TRObject.SRs.Add();
				NewRow.SR				= CurrentObject.Ref;
				NewRow.LineNumberInUser	= Row.LineNumber;
				
			Else 
				
				FoundString.LineNumberInUser = Row.LineNumber;
				
			EndIf;
			
			TRObject.Write();
			
		EndDo;
		
	EndIf;
	
EndProcedure
&AtServer
Procedure FillRegionsFromCopy()
	Regions.Clear();
	
	If ValueIsFilled(Parameters.CopyingValue) Then 
	
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED DISTINCT
			|	RegionManagers.Ref AS Region,
			|	RegionManagers.LineNumberInUser AS LineNumberInUser
			|FROM
			|	Catalog.Region.Managers AS RegionManagers
			|WHERE
			|	RegionManagers.Manager = &User
			|
			|ORDER BY
			|	LineNumberInUser";
		
		Query.SetParameter("User", Parameters.CopyingValue);
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			NewRow			= Regions.Add();
			NewRow.Region	= Selection.Region;
			
		EndDo;
		
	EndIf;	
	
EndProcedure
&AtServer
Procedure FillRegions()
	
	// Заполнить регионы
	Regions.Clear();
	
	If ValueIsFilled(Object.Ref) Then 
	
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED DISTINCT
			|	RegionManagers.Ref AS Region,
			|	RegionManagers.LineNumberInUser AS LineNumberInUser
			|FROM
			|	Catalog.Region.Managers AS RegionManagers
			|WHERE
			|	RegionManagers.Manager = &User
			|
			|ORDER BY
			|	LineNumberInUser";
		
		Query.SetParameter("User", Object.Ref);
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			NewRow			= Regions.Add();
			NewRow.Region	= Selection.Region;
			
		EndDo;
		
	EndIf;	
	
EndProcedure
&AtServer
Procedure FillTerritoriesFromCopy()
		Territories.Clear();
	
	If ValueIsFilled(Parameters.CopyingValue) Then 
	
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED DISTINCT
			|	TerritorySRs.Ref AS Territory,
			|	TerritorySRs.LineNumberInUser AS LineNumberInUser
			|FROM
			|	Catalog.Territory.SRs AS TerritorySRs
			|WHERE
			|	TerritorySRs.SR = &User
			|
			|ORDER BY
			|	LineNumberInUser";
		
		Query.SetParameter("User", Parameters.CopyingValue);
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			NewRow				= Territories.Add();
			NewRow.Territory	= Selection.Territory;
			
		EndDo;
		
	EndIf;
EndProcedure
&AtServer
Procedure FillTerritories()
	
	// Заполнить регионы
	Territories.Clear();
	
	If ValueIsFilled(Object.Ref) Then 
	
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED DISTINCT
			|	TerritorySRs.Ref AS Territory,
			|	TerritorySRs.LineNumberInUser AS LineNumberInUser
			|FROM
			|	Catalog.Territory.SRs AS TerritorySRs
			|WHERE
			|	TerritorySRs.SR = &User
			|
			|ORDER BY
			|	LineNumberInUser";
		
		Query.SetParameter("User", Object.Ref);
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			NewRow				= Territories.Add();
			NewRow.Territory	= Selection.Territory;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function UniqueCheck(Attribute)
	
	SetPrivilegedMode(True);
	
	FoundRef = Catalogs.User.FindByAttribute(Attribute, Object[Attribute]);
	
	SetPrivilegedMode(False);
	
	If FoundRef = Catalogs.User.EmptyRef() Then
		
		FoundRef = True;
		
	Else
		
		FoundRef = False;
		
	EndIf;
	
	Return FoundRef;

EndFunction

&AtServer
Procedure OnOpenAtServer()
	
	Items.Code.ReadOnly 	= 	Not Users.HaveAdditionalRight(Catalogs.AdditionalAccessRights.EditCatalogNumbers);
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
	TerritoriesOnChange(Items.Territories);
	RegionsOnChange(Items.Regions);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	TerritoriesOnChange(Items.Territories);
	RegionsOnChange(Items.Regions);
	
	// Запрет изменения логина у уже записанного пользователя
	Items.Login.ReadOnly = True;
		
EndProcedure

&AtClient
Procedure SetLineNumbers(Collection)
	
	Ind = 0;
	
	For Each ItemElement In Collection Do 
		
		Ind = Ind + 1;
		
		ItemElement.LineNumber = Ind;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UserNameOnChange(Item)
	
	UserNameChecked();
	
EndProcedure

&AtClient
Function UserNameChecked()

	If Not UniqueCheck("UserName") Then
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en='This login is already used';ru='Этот логин уже используется';cz='This login is already used'");
		
		UserMessage.Message();
		
		Object.UserName = Undefined;
		
		Return False;
		
	EndIf;

EndFunction

&AtClient
Procedure TerritoriesOnChange(Item)
	
	SetLineNumbers(Territories);
	
EndProcedure

&AtClient
Procedure RegionsOnChange(Item)
	
	SetLineNumbers(Regions);
	
EndProcedure

&AtClient
Procedure RegionsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If Not CancelEdit Then 
		
		If Not ValueIsFilled(Items.Regions.CurrentData.Region) Then 
			
			Message(NStr("en='Value is not selected';ru='Значение не выбрано';cz='Nebyla zvolena žádná hodnota'"));
			
			Cancel = True;
			
		EndIf;
				
	EndIf;
	
EndProcedure

&AtClient
Procedure TerritoriesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If Not CancelEdit Then 
		
		If Not ValueIsFilled(Items.Territories.CurrentData.Territory) Then 
			
			Message(NStr("en='Value is not selected';ru='Значение не выбрано';cz='Nebyla zvolena žádná hodnota'"));
			
			Cancel = True;
			
		EndIf;
				
	EndIf;
	
EndProcedure

&AtClient
Procedure SendUserPassword(Command)
	
	If Object.EMail="" Then
		Message(NStr("en = 'You need set EMail.'; ru = 'Вы должны установить Эл.почту, на которую нужно выслать логин/пароль.'"));		
		Return;
	EndIf;	
	
	If ThisForm.Modified Then
		ShowQueryBox(New NotifyDescription("SendUserPasswordOver",ThisObject),
		NStr("en = 'Do you want save this object?'; ru = 'Вы хотите записать этот объект?'"),
		QuestionDialogMode.YesNo); 
	Else
	SendUserPasswordServer();	
	EndIf;	
	
EndProcedure

&AtClient
Procedure SendUserPasswordOver(ResultQuestion,AdditionalParametrs) Export 
		
	If ResultQuestion= DialogReturnCode.Yes then
		ThisForm.Write();
		SendUserPasswordServer();
	Else
		Message(NStr("en = 'You need save this object, before send login/password'; ru = 'Вы должны записать элемент перед отправкой логина/пароля'"));
	EndIf;
EndProcedure

&AtServer
Procedure SendUserPasswordServer()
	
	If Constants.bitmobile_АдресСервераSMTP.Get()="" Then
		Message(NStr("en = 'You need set address SMTP in setting.'; ru = 'Вы должны установить адрес SMTP в настройках синхронизации.'"));
		Return;	
	EndIf;
	If Constants.bitmobile_ПользовательSMTP.Get()="" Then
		Message(NStr("en = 'You need set SMTP user in setting.'; ru = 'Вы должны установить имя пользователя в настройках синхронизации.'"));
		Return;	
	EndIf;
	If Constants.bitmobile_ПарольSMTP.Get()="" Then
		Message(NStr("en = 'You need set SMTP password in setting.'; ru = 'Вы должны установить пароль пользователя в настройках синхронизации.'"));
		Return;	
	EndIf;
	
	UserObj = FormDataToValue(Object, Type("CatalogObject.User"));
	Try
		UserObj.SendMessage();
	Except
		Message(NStr("en = 'Try to connect was fail, check mail setting.'; ru = 'Попытка подключения прошла не успешно, проверьте настройки почты.'"));
	EndTry;
EndProcedure

&AtClient
Procedure GenerateRandomPassword(Command)
	
	GenerateRandomPasswordAtServer();
	ThisForm.Modified=True;
	
EndProcedure

&AtServer
Procedure GenerateRandomPasswordAtServer()
	
	Object.Password=UsersCallServer.GenerateRandomPassword();
	Message(NStr("en = 'Yours generated password:'; ru = 'Ваш сгенерированный пароль:'")+Object.Password);
		
EndProcedure

&AtServer
Function IsNewUser()
	
	Return Object.Ref = Catalogs.User.EmptyRef();
	
EndFunction

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	If IsNewUser() Then 
		UserCheck = UserNameChecked();
		If UserCheck<>Undefined Then
			If UserCheck Then
				Cancel = True;	
			EndIf;
		EndIf;
	EndIf;	
EndProcedure

#EndRegion



 

