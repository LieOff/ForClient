
&AtClient
Var PrevUserRoleRow;

#Region CommonProceduresAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.AccessRightsToSystemObjectsRead.ThreeState			= True;
	Items.AccessRightsToSystemObjectsEdit.ThreeState			= True;
	Items.AccessRightsToSystemObjectsMarkForDeletion.ThreeState	= True;
	
	Items.WriteChanges.Enabled = False;
	
	ValueToFormAttribute(Catalogs.RolesOfUsers.GetRightsValueTree(), "AccessRightsToSystemObjects");
	
	ValueToFormAttribute(Catalogs.RolesOfUsers.GetOtherRightsTable("AdditionalAccessRights"), "AdditionalAccessRights");
	
	ValueToFormAttribute(Catalogs.RolesOfUsers.GetOtherRightsTable("MobileAppAccessRights"), "MobileAppAccessRights");
	
EndProcedure

#Region AccessRights

&AtServer
Procedure WriteChangesAtServer(UserRole)
	
	RightsValueTree = FormAttributeToValue("AccessRightsToSystemObjects");
	
	SelectedRights = Catalogs.RolesOfUsers.GetSelectedRightsFromValueTree(RightsValueTree);
	
	SelectedAdditionalRights = New ValueTable;
	SelectedAdditionalRights.Columns.Add("AccessRight");
	
	For Each TableItem In AdditionalAccessRights Do 
		
		If TableItem.Use Then 
			
			Ins = SelectedAdditionalRights.Add();
			Ins.AccessRight = TableItem.AccessRight;
			
		EndIf;
		
	EndDo;
	
	SelectedMobileAppRights = New ValueTable;
	SelectedMobileAppRights.Columns.Add("AccessRight");
	
	For Each TableItem In MobileAppAccessRights Do 
		
		If TableItem.Use Then 
			
			Ins = SelectedMobileAppRights.Add();
			Ins.AccessRight = TableItem.AccessRight;
			
		EndIf;
		
	EndDo;
	
	UserRoleObject = UserRole.GetObject();
	UserRoleObject.AccessRightsToSystemObjects.Load(SelectedRights);
	UserRoleObject.AdditionalAccessRights.Load(SelectedAdditionalRights);
	UserRoleObject.MobileAppAccessRights.Load(SelectedMobileAppRights);
	UserRoleObject.Write();
	
EndProcedure

&AtServer
Procedure GetRolesOfUsersSystemObjectRights(RoleOfUsers)
	
	ValueToFormAttribute(Catalogs.RolesOfUsers.GetOtherRightsTable("MobileAppAccessRights"), "MobileAppAccessRights");
	
	If ValueIsFilled(RoleOfUsers) Then 
		
		RightsTable = RoleOfUsers.AccessRightsToSystemObjects;
		
		For Each TreeItem in AccessRightsToSystemObjects.GetItems() Do 
			
			FillTreeRecursive(TreeItem.GetItems(), RightsTable);
			
		EndDo;
		
		For Each TableItem In AdditionalAccessRights Do 
			
			FindedRow = RoleOfUsers.AdditionalAccessRights.Find(TableItem.AccessRight, "AccessRight");
			
			If Not FindedRow = Undefined Then 
				
				TableItem.Use = True;
				
			Else 
				
				TableItem.Use = False;
				
			EndIf;
			
			
		EndDo;
		
		For Each TableItem In MobileAppAccessRights Do 
			
			FindedRow = RoleOfUsers.MobileAppAccessRights.Find(TableItem.AccessRight, "AccessRight");
			
			If Not FindedRow = Undefined Then 
				
				TableItem.Use = True;
				
			Else 
				
				TableItem.Use = False;
				
			EndIf;
			
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer 
Procedure FillTreeRecursive(TreeItems, RightsTable)
	
	ColumnsArray = New Array;
	ColumnsArray.Add("Read");
	ColumnsArray.Add("Edit");
	ColumnsArray.Add("MarkForDeletion");
	
	For Each TreeItem In TreeItems Do 
		
		If TreeItem.Picture = 1 Then 
			
			FillTreeRecursive(TreeItem.GetItems(), RightsTable);
			
		Else 
			
			FindedRow = RightsTable.Find(TreeItem.SystemObject, "SystemObject");
			
			If Not FindedRow = Undefined Then 
				
				TreeItem.Read				= FindedRow.Read			= True;
				TreeItem.Edit				= FindedRow.Edit			= True;
				TreeItem.MarkForDeletion	= FindedRow.MarkForDeletion	= True;
				
				ChangeRowCheckBoxes(TreeItem, ColumnsArray);
				
			Else 
				
				TreeItem.Read				= False;
				TreeItem.Edit				= False;
				TreeItem.MarkForDeletion	= False;
				
				ChangeRowCheckBoxes(TreeItem, ColumnsArray);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ChangeCheckBox(ColumnName)
	
	CurrentRow = Items.AccessRightsToSystemObjects.CurrentRow;
	
	CurrentRowData = AccessRightsToSystemObjects.FindByID(CurrentRow);
	
	If ColumnName = "Read" Then 
		
		ColumnsArray = New Array;
		
		ColumnsArray.Add(ColumnName);
		
		If CurrentRowData[ColumnName] = 0 Or CurrentRowData[ColumnName] = 2 Then 
			
			If Not CurrentRowData.ItsReport Then 
			
				CurrentRowData["Edit"]				= 0;
				CurrentRowData["MarkForDeletion"]	= 0;
				
				ColumnsArray.Add("Edit");
				ColumnsArray.Add("MarkForDeletion");
				
			EndIf;
			
		EndIf;
		
		ChangeRowCheckBoxes(CurrentRowData, ColumnsArray);
		
	ElsIf ColumnName = "Edit" Then
		
		ColumnsArray = New Array;
		
		ColumnsArray.Add(ColumnName);
		
		If CurrentRowData[ColumnName] = 0 Or CurrentRowData[ColumnName] = 2 Then 
			
			CurrentRowData["MarkForDeletion"] = 0;
			
			ColumnsArray.Add("MarkForDeletion");
		
		EndIf;
		
		If CurrentRowData[ColumnName] = 1 Then 
			
			CurrentRowData["Read"] = 1;
			
			ColumnsArray.Add("Read");
			
		EndIf;
		
		ChangeRowCheckBoxes(CurrentRowData, ColumnsArray, True);
		
	ElsIf ColumnName = "MarkForDeletion" Then
		
		ColumnsArray = New Array;
		ColumnsArray.Add(ColumnName);
		
		If CurrentRowData[ColumnName] = 1 Then 
			
			CurrentRowData["Edit"] = 1;
			CurrentRowData["Read"] = 1;
			
			ColumnsArray.Add("Edit");
			ColumnsArray.Add("Read");
			
		EndIf;
		
		ChangeRowCheckBoxes(CurrentRowData, ColumnsArray, True);
		
	EndIf;
	
	Items.WriteChanges.Enabled = True;
	
EndProcedure

&AtServer
Procedure ChangeRowCheckBoxes(CurrentRowData, CheckBoxColumnNamesArray, BlockRead = False)
	
	For Each CheckBoxColumnName In CheckBoxColumnNamesArray Do 
	
		If CurrentRowData[CheckBoxColumnName] = 2 Then
			
			CurrentRowData[CheckBoxColumnName] = 0;
			
		EndIf;
		
		SetCheckBoxes(CurrentRowData, CheckBoxColumnName, CurrentRowData[CheckBoxColumnName], BlockRead);
		
		Parent = CurrentRowData.GetParent();
		
		TempCurrentRowData = CurrentRowData;
		
		While Parent <> Undefined Do
			
			If Not (CurrentRowData.ItsReport And (CheckBoxColumnName = "Edit" Or CheckBoxColumnName = "MarkForDeletion")) Then
				
				Parent[CheckBoxColumnName] = ?(IsSetForAll(TempCurrentRowData, CheckBoxColumnName), TempCurrentRowData[CheckBoxColumnName], 2);
				
			EndIf;
			
			TempCurrentRowData = TempCurrentRowData.GetParent();
			Parent = TempCurrentRowData.GetParent();
			
		EndDo;
		
		If BlockRead And Parent = Undefined And CheckBoxColumnName = "Read" Then 
			
			AllSet = True;
			
			For Each Row In CurrentRowData.GetItems() Do
		
				If Not (Row.ItsReport = True And (CheckBoxColumnName = "Edit" Or CheckBoxColumnName = "MarkForDeletion")) Then
				
					If Row[CheckBoxColumnName] <> CurrentRowData[CheckBoxColumnName] Then
						
						AllSet = False;
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
			CurrentRowData[CheckBoxColumnName] = ?(AllSet, CurrentRowData[CheckBoxColumnName], 2); 
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetCheckBoxes(CurrentRowData, CheckBoxColumnName, Value, BlockRead)
	
	For Each Row In CurrentRowData.GetItems() Do
		
		If Not (Row.ItsReport And (CheckBoxColumnName = "Edit" Or CheckBoxColumnName = "MarkForDeletion")) Then  
			
			If BlockRead Then 
				
				If Not (Row.ItsReport And CheckBoxColumnName = "Read") Then
					
					Row[CheckBoxColumnName] = Value;
					SetCheckBoxes(Row, CheckBoxColumnName, Row[CheckBoxColumnName], BlockRead);
					
				EndIf;
				
			Else 
				
				Row[CheckBoxColumnName] = Value;
				SetCheckBoxes(Row, CheckBoxColumnName, Row[CheckBoxColumnName], BlockRead);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function IsSetForAll(CurrentRowData, CheckBoxColumnName)
	
	For Each Row In CurrentRowData.GetParent().GetItems() Do
		
		If Not (Row.ItsReport = True And (CheckBoxColumnName = "Edit" Or CheckBoxColumnName = "MarkForDeletion")) Then
		
			If Row[CheckBoxColumnName] <> CurrentRowData[CheckBoxColumnName] Then
				
				Return False;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtServer
Function GetPredefinedAccessElement()
	
	Return Catalogs.MobileAppAccessRights.AccessToMobileApp;
	
EndFunction

#EndRegion

#EndRegion

#Region UserInterface

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UserRoleWrite" Then
		
		RolesOfUsersOnActivateRow(Items.RolesOfUsers);
		
	EndIf;
	
EndProcedure

#Region RolesOfUsers

&AtClient
Procedure WriteChangesQueryProcessing(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		WriteChangesAtServer(AdditionalParameters.PrevUserRole);
		
	EndIf;
	
	If Not Items.RolesOfUsers.CurrentData = Undefined Then
		
		GetRolesOfUsersSystemObjectRights(Items.RolesOfUsers.CurrentData.Ref);
		
	EndIf;
	
	Modified = False;
	
	Items.WriteChanges.Enabled = False;
	
EndProcedure 

&AtClient
Procedure WriteChanges(Command)
	
	If Modified Then
		
		CurrentData = Items.RolesOfUsers.CurrentData;
		UsersRoleIsChosen = Not CurrentData = Undefined;
		
		If UsersRoleIsChosen Then
			
			UsersRole = CurrentData.Ref;
			WriteChangesAtServer(UsersRole);
			
			Modified = False;
			
			Items.WriteChanges.Enabled = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RolesOfUsersOnActivateRow(Item)
	
	If Modified And CurrentItem = Items.RolesOfUsers Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("PrevUserRole", PrevUserRoleRow);
		
		ShowQueryBox(New NotifyDescription("WriteChangesQueryProcessing", ThisForm, AdditionalParameters),
			NStr("en='Previous chosen user role access rights changes were made. Write?';ru='Были сделаны изменения прав доступа для предыдущей выбранной роли пользователя. Записать?';cz='Previous chosen user role access rights changes were made. Write?'"),
			QuestionDialogMode.YesNo,
			0,
			DialogReturnCode.No,
			NStr("en='Write changes?';ru='Записать изменения?';cz='Uložit změny?'"));
		
	Else
		
		If Not Item.CurrentData = Undefined Then
			
			GetRolesOfUsersSystemObjectRights(Item.CurrentData.Ref);
			
		EndIf;
		
	EndIf;
	
	PrevUserRoleRow = Item.CurrentRow;
	
EndProcedure

#EndRegion

#Region AccessRights

&AtClient
Procedure AccessRightsToSystemObjectsReadOnChange(Item)
	
	ChangeCheckBox("Read");
	
EndProcedure

&AtClient
Procedure AccessRightsToSystemObjectsEditOnChange(Item)
	
	ChangeCheckBox("Edit");
	
EndProcedure

&AtClient
Procedure AccessRightsToSystemObjectsMarkForDeletionOnChange(Item)
	
	ChangeCheckBox("MarkForDeletion");
	
EndProcedure

&AtClient
Procedure AdditionalRightsUseOnChange(Item)
	
	Items.WriteChanges.Enabled = True;
	
EndProcedure

&AtClient
Procedure MobileAppAccessRightsUseOnChange(Item)
	
	AccessElement = GetPredefinedAccessElement();
	
	If Items.MobileAppAccessRights.CurrentData.AccessRight = AccessElement Then 
		
		If Not Items.MobileAppAccessRights.CurrentData.Use Then 
			
			For Each Item In MobileAppAccessRights Do 
				
				Item.Use = False;
				
			EndDo;
			
		EndIf;
		
	Else
		
		For Each Item In MobileAppAccessRights Do 
			
			If Item.AccessRight = AccessElement Then
			
				Item.Use = True;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Items.WriteChanges.Enabled = True;
	
EndProcedure

&AtClient
Procedure CurrentPageIndexOnChange(Item)
	
	If CurrentPageIndex = 0 Then 
		
		Items.GroupRightsPages.CurrentPage = Items.GroupRightsToSystemObjects;
		
	ElsIf CurrentPageIndex = 1 Then 
		
		Items.GroupRightsPages.CurrentPage = Items.GroupAdditionalRights;
		
	ElsIf CurrentPageIndex = 2 Then 
		
		Items.GroupRightsPages.CurrentPage = Items.GroupMobileAppRights;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
