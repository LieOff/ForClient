
#Region CommonProceduresAndFunctions

&AtServer
Procedure SetEnableForElementsAtServer()
	Items.UseAutoFillForRecOrder.Enabled = ThisForm.RecOrderEnabled;
	If Not ThisForm.RecOrderEnabled Then
		ThisForm.UseAutoFillForRecOrder = False;
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.GPSSource.EditFormat = "BF='" + NStr("ru='Мобильные сети';en='Mobile networks'") + "'; BT=" + NStr("ru=Спутники;en=Satellites");
	
	ControlOrderReasonEnabled	 = Catalogs.MobileAppSettings.ControlOrderReasonEnabled.LogicValue;
	ControlVisitReasonEnabled	 = Catalogs.MobileAppSettings.ControlVisitReasonEnabled.LogicValue;
	CoordinateControlEnabled	 = Catalogs.MobileAppSettings.CoordinateControlEnabled.LogicValue;
	EmptyStockEnabled			 = Catalogs.MobileAppSettings.EmptyStockEnabled.LogicValue;
	MultistockEnabled			 = Catalogs.MobileAppSettings.MultistockEnabled.LogicValue;
	PlanVisitEnabled			 = Catalogs.MobileAppSettings.PlanVisitEnabled.LogicValue;
	RecOrderEnabled				 = Catalogs.MobileAppSettings.RecOrderEnabled.LogicValue;
	UseAutoFillForRecOrder		 = (RecOrderEnabled AND Catalogs.MobileAppSettings.UseAutoFillForRecOrder.LogicValue);
	SnapshotSize				 = Catalogs.MobileAppSettings.SnapshotSize.NumericValue;
	SKUFeaturesRegistration		 = Catalogs.MobileAppSettings.SKUFeaturesRegistration.LogicValue;
	UserCoordinatesActualityTime = Catalogs.MobileAppSettings.UserCoordinatesActualityTime.NumericValue;
	UseSaveQuest = Catalogs.MobileAppSettings.UseSaveQuest.LogicValue;
	
	GPSSource = Catalogs.MobileAppSettings.GPSSource.LogicValue;
	GPSTrackSendFrequency = Catalogs.MobileAppSettings.GPSTrackSendFrequency.NumericValue;
	GPSTrackWriteFrequency = Catalogs.MobileAppSettings.GPSTrackWriteFrequency.NumericValue;
	
	CreateReturnsEnabled		= Constants.UseReturns.Get();
	CreateOrdersEnabled			= Constants.UseOrders.Get();
	CreateEncashmentsEnabled	= Constants.UseEncashments.Get();
	
	SizeOfThumbnailPhotos		= Constants.SizeOfThumbnailPhotos.Get();
	
	DefaultCity = Constants.DefaultCity.Get();
	
	SetEnableForElementsAtServer();
	
EndProcedure

&AtServer
Procedure SaveSettingsServer()
	
	ControlOrderReasonEnabledObject				= Catalogs.MobileAppSettings.ControlOrderReasonEnabled.GetObject();
	ControlOrderReasonEnabledObject.LogicValue	= ControlOrderReasonEnabled;
	
	ControlOrderReasonEnabledObject.Write();
	
	SaveQuest = Catalogs.MobileAppSettings.UseSaveQuest.GetObject();
	SaveQuest.LogicValue = UseSaveQuest;
	
	SaveQuest.Write();
	
	ControlVisitReasonEnabledObject				= Catalogs.MobileAppSettings.ControlVisitReasonEnabled.GetObject();
	ControlVisitReasonEnabledObject.LogicValue	= ControlVisitReasonEnabled;
	
	ControlVisitReasonEnabledObject.Write();
	
	CoordinateControlEnabledObject				= Catalogs.MobileAppSettings.CoordinateControlEnabled.GetObject();
	CoordinateControlEnabledObject.LogicValue	= CoordinateControlEnabled;
	
	CoordinateControlEnabledObject.Write();
	
	EmptyStockEnabledObject						= Catalogs.MobileAppSettings.EmptyStockEnabled.GetObject();
	EmptyStockEnabledObject.LogicValue			= EmptyStockEnabled;
	
	EmptyStockEnabledObject.Write();
	
	SKUFeaturesRegistrationObject				= Catalogs.MobileAppSettings.SKUFeaturesRegistration.GetObject();
	SKUFeaturesRegistrationObject.LogicValue	= SKUFeaturesRegistration;
	
	SKUFeaturesRegistrationObject.Write();
	
	Constants.SKUFeaturesRegistration.Set(SKUFeaturesRegistration);
	
	MultistockEnabledObject						= Catalogs.MobileAppSettings.MultistockEnabled.GetObject();
	MultistockEnabledObject.LogicValue			= MultistockEnabled;
	
	MultistockEnabledObject.Write();
	
	Constants.MultiStock.Set(MultistockEnabled);
	
	PlanVisitEnabledObject						= Catalogs.MobileAppSettings.PlanVisitEnabled.GetObject();
	PlanVisitEnabledObject.LogicValue			= PlanVisitEnabled;
	
	PlanVisitEnabledObject.Write();
	
	RecOrderEnabledObject						= Catalogs.MobileAppSettings.RecOrderEnabled.GetObject();
	RecOrderEnabledObject.LogicValue			= RecOrderEnabled;
	
	RecOrderEnabledObject.Write();
	
	UseAutoFillForRecOrderObject				= Catalogs.MobileAppSettings.UseAutoFillForRecOrder.GetObject();
	UseAutoFillForRecOrderObject.LogicValue		= UseAutoFillForRecOrder;
	
	UseAutoFillForRecOrderObject.Write();
	
	SnapshotSizeObject							= Catalogs.MobileAppSettings.SnapshotSize.GetObject();
	SnapshotSizeObject.NumericValue				= SnapshotSize;
	
	SnapshotSizeObject.Write();
	
	UserCoordinatesActualityTimeObject = Catalogs.MobileAppSettings.UserCoordinatesActualityTime.GetObject();
	UserCoordinatesActualityTimeObject.NumericValue = UserCoordinatesActualityTime;
	
	UserCoordinatesActualityTimeObject.Write();
	
	GPSSourceObject = Catalogs.MobileAppSettings.GPSSource.GetObject();
	GPSSourceObject.LogicValue = GPSSource;
	
	GPSSourceObject.Write();
	
	GPSTrackSendFrequencyObject = Catalogs.MobileAppSettings.GPSTrackSendFrequency.GetObject();
	GPSTrackSendFrequencyObject.NumericValue = GPSTrackSendFrequency;
	
	GPSTrackSendFrequencyObject.Write();
	
	GPSTrackWriteFrequencyObject = Catalogs.MobileAppSettings.GPSTrackWriteFrequency.GetObject();
	GPSTrackWriteFrequencyObject.NumericValue = GPSTrackWriteFrequency;
	
	GPSTrackWriteFrequencyObject.Write();
	
	Constants.UseReturns.Set(CreateReturnsEnabled);
	Constants.UseOrders.Set(CreateOrdersEnabled);
	Constants.UseEncashments.Set(CreateEncashmentsEnabled);
	Constants.DefaultCity.Set(DefaultCity);
	
	Constants.SizeOfThumbnailPhotos.Set(SizeOfThumbnailPhotos);
	
	If Not CreateReturnsEnabled Then 
		
		DeleteAccessRightFromRole(Catalogs.MobileAppAccessRights.AccessToReturn);
		
	Else 
		
		AddAccessRightToRole(Catalogs.MobileAppAccessRights.AccessToReturn);
		
	EndIf;
	
	If Not CreateOrdersEnabled Then 
		
		DeleteAccessRightFromRole(Catalogs.MobileAppAccessRights.AccessToOrder);
		
	Else 
		
		AddAccessRightToRole(Catalogs.MobileAppAccessRights.AccessToOrder);
		
	EndIf;
	
	If Not CreateEncashmentsEnabled Then 
		
		DeleteAccessRightFromRole(Catalogs.MobileAppAccessRights.AccessToEncashment);
		
	Else 
		
		AddAccessRightToRole(Catalogs.MobileAppAccessRights.AccessToEncashment);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteAccessRightFromRole(AccessRight)
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	RolesOfUsersMobileAppAccessRights.AccessRight,
		|	RolesOfUsersMobileAppAccessRights.Ref AS RolesOfUser
		|FROM
		|	Catalog.RolesOfUsers.MobileAppAccessRights AS RolesOfUsersMobileAppAccessRights
		|WHERE
		|	RolesOfUsersMobileAppAccessRights.AccessRight = &AccessRight";
	
	Query.SetParameter("AccessRight", AccessRight);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		RO_Object = Selection.RolesOfUser.GetObject();
		
		RowToDelete = RO_Object.MobileAppAccessRights.Find(AccessRight);
		
		RO_Object.MobileAppAccessRights.Delete(RowToDelete);
		
		RO_Object.Write();
		
		RightName = NStr(AccessRight.Description);
		
		UserMessage			= New UserMessage;
		UserMessage.Text	= NStr("en = 'For user roles """ + RO_Object.Description + """ turned off the right """ + RightName +"""'; ru = 'Для роли пользователей """ + RO_Object.Description + """ отключено право """ + RightName +"""'");
		
		UserMessage.Message();
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddAccessRightToRole(AccessRight)
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	RolesOfUsersMobileAppAccessRights.Ref AS RolesOfUser
		|FROM
		|	Catalog.RolesOfUsers.MobileAppAccessRights AS RolesOfUsersMobileAppAccessRights
		|WHERE
		|	RolesOfUsersMobileAppAccessRights.AccessRight = &AccessRight";
	
	Query.SetParameter("AccessRight", Catalogs.MobileAppAccessRights.AccessToMobileApp);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		RO_Object = Selection.RolesOfUser.GetObject();
		
		RowWithRight = RO_Object.MobileAppAccessRights.Find(AccessRight);
		
		If RowWithRight = Undefined Then 
			
			Ins				= RO_Object.MobileAppAccessRights.Add();
			Ins.AccessRight	= AccessRight;
			
			RO_Object.Write();
			
			RightName = NStr(AccessRight.Description);
			
			UserMessage			= New UserMessage;
			UserMessage.Text	= NStr("en = 'For user roles """ + RO_Object.Description + """ including the right """ + RightName +"""'; ru = 'Для роли пользователей """ + RO_Object.Description + """ включено право """ + RightName +"""'");
			
			UserMessage.Message();
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region UserInterface

&AtClient
Procedure SaveSettings(Command)
	
	SaveSettingsServer();
	
	RefreshInterface();
	
	Notify("UserRoleWrite");
	
EndProcedure

&AtClient
Procedure RecOrderEnabledOnChange(Item)
	// Вставить содержимое обработчика.
	SetEnableForElementsAtServer();
EndProcedure

#EndRegion