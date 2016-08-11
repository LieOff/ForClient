
// Данная процедура получает форму и добавляет на эту форму элементы формы и реквизиты формы
// необходимые для отображения карт. Вызывать лучше всего из обработчика события 
// "ПриСозданииНаСервере". Хотя в принципе должно взлететь при вызове из любой точки кода.
// Параметры процедуры:
// Form - форма на которую нужно добавить элементы формы и реквизиты
// Parent - родительский элемент в который нужно добавить элементы формы. Если этот
// параметр равен Неопределено, тогда элементы формы добавляются в корень формы.
// SingleMarker - если истина - используется логика одного маркера. То есть при клике на карте
// существующий маркер удаляется и добавляется новый в место клика. Координаты последнего 
// установленного маркера можно получить через функцию GetLastMarkerCoordinates()
// DefaultCity - Устанавливает адрес на котором будет центрироваться карта при открытии. Если
// этот параметр равен Неопределено, тогда карта будет пытаться центрироваться на Москве
&AtServer
Procedure AddMap(Form, Parent = Undefined, SingleMarker = False, DefaultCity = Undefined) Export
	
	// Подготовка полученной формы к работе с картами
	// Добавление на форму необходимых для работы карт реквизитов формы
	AddMapAttribute(Form);
	
	// Добавление на форму необходимых для работы карт элементов формы
	AddMapItem(Form, Parent);
	
	// Подготовка к работе кода HTML-страницы для отображения карт
	// Получение макета содержащего код HTML-страницы для отображения карт
	MapCode = GetCommonTemplate("MapCode").GetText();
	
	
	If SingleMarker Then
		
		// Установка свойства указывающего на использование логики одного маркера
		SetSingleMarkerSetting(MapCode);
		
	EndIf;
	
	// Установка адреса на котором карта будет пытаться центрироваться при открытии
	SetMapDefaultCity(MapCode, DefaultCity);
	
	// Подготовленный код HTML-страницы скармливаем в элемент формы предназначенный для вывода карт
	Form.Map = MapCode;
	
EndProcedure

#Region InitHelpers

&AtServer
Procedure SetMapDefaultCity(MapCode, DefaultCity)
	
	MapCode = StrReplace(MapCode, "<div id=""address"" class=""invis""></div>", "<div id=""address"" class=""invis"">" + DefaultCity + "</div>");
	
EndProcedure

&AtServer
Procedure SetSingleMarkerSetting(MapCode)
	
	MapCode = StrReplace(MapCode, "<div id=""singleMarker"" class=""invis""></div>", "<div id=""singleMarker"" class=""invis"">1</div>");
	
EndProcedure

&AtServer
Procedure AddMapAttribute(Form)
	
	AttributesToBeAdded = New Array;
	AttributesToBeAdded.Add(GetMapFormAttribute());
	
	Form.ChangeAttributes(AttributesToBeAdded);
	
EndProcedure

&AtServer
Procedure AddMapItem(Form, Parent)
	
	MapFormField = GetMapFormItem(Form, Parent);
	MapFormField.Type = FormFieldType.HTMLDocumentField;
	MapFormField.DataPath = "Map";
	MapFormField.TitleLocation = FormItemTitleLocation.None;
	MapFormField.SetAction("DocumentComplete", "InitMap");
	MapFormField.SetAction("OnClick", "OnMapClick");
	
EndProcedure

&AtServer
Function GetMapFormItem(Form, Parent)
	
	Return Form.Items.Add("Map", Type("FormField"), Parent);
	
EndFunction

&AtServer
Function GetMapFormAttribute()
	
	Return New FormAttribute("Map", New TypeDescription("String"));;
	
EndFunction

#EndRegion

#Region Helpers

// Процедура для установки переменных на карте. 
// Параметры процедуры:
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
// VarName - идентификатор div'а в котором хранится значение переменной
// Value - значение которое нужно установить div'у
&AtClient
Procedure SetVariableValue(Form, VarName, Value)
	
	Form.Items.Map.Document.getElementById(VarName).innerHTML = Value;
	
EndProcedure

// Процедура для вызова функций на карте
// Параметры процедуры:
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
// FunctionName - идентификатор Button'а в качестве обработчика нажатия на который указана
// функция которую нужно вызвать
&AtClient
Procedure CallFunction(Form, FunctionName)
	
	Form.Items.Map.Document.getElementById(FunctionName).click();
	
EndProcedure

// Функция для получения значений переменных с карты
// Параметры процедуры:
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
// VarName - идентификатор div'а в котором хранится значение переменной
&AtClient
Function GetVariableValue(Form, VarName)
	
	Return Form.Items.Map.Document.getElementById(VarName).innerHTML;
	
EndFunction

Function FormatCoordinate(Num)
	
	Num = ?(Num = Undefined, 0, Num);
	
	Return Format(Num, "NDS=.; NG=0");
	
EndFunction

Function GetCoordinates(Latitude, Longitude) Export
	
	Coordinates = New Structure;
	Coordinates.Insert("Lat", FormatCoordinate(Latitude));
	Coordinates.Insert("Lng", FormatCoordinate(Longitude));
	Return Coordinates;
	
EndFunction

#EndRegion

// Процедура для центрирования карты на координатах
// Параметры процедуры:
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
// Coordinates - структура полученная через функцию GetCoordinates()
&AtClient
Procedure SetMapCenter(Form, Coordinates) Export
	
	SetVariableValue(Form, "lastMarkerLat", ?(Coordinates.Lat = "", "59.934", Coordinates.Lat));
	SetVariableValue(Form, "lastMarkerLng", ?(Coordinates.Lng = "", "30.335", Coordinates.Lng));
	CallFunction(Form, "setMapCenter");
	
EndProcedure

// Процедура для добавления маркера по адресу
// Параметры процедуры:
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
// Address - адрес, который необходимо геокодировать. При успехе по полученным от геокодера
// координатам будет установлен маркер и отцентрирована карта.
&AtClient
Procedure AddMarkerOnAddress(Form, Address) Export
	
	SetVariableValue(Form, "address", Address);
	CallFunction(Form, "addMarkerOnAddress");
	
EndProcedure

// Процедура для установки центра карты при открытии. Команду на центрирование нельзя отправить
// до того как карта будет загружена и инициализирована. Поэтому этот метод нужно вызывать в событии
// InitMap() которое вызывается сразу после того как поле формы было инициализировано.
&AtClient
Procedure SetInitialMapCenter(Form, Coordinates) Export
	
	SetVariableValue(Form, "lastMarkerLat", ?(Coordinates.Lat = "", "59.934", Coordinates.Lat));
	SetVariableValue(Form, "lastMarkerLng", ?(Coordinates.Lng = "", "30.335", Coordinates.Lng));
	
EndProcedure

// Процедура для установки маркера при открытии. Команду на установку маркера нельзя отправить
// до того как карта будет загружена и инициализирована. Поэтому этот метод нужно вызывать в событии
// InitMap() которое вызывается сразу после того как поле формы было инициализировано.
&AtClient
Procedure AddInitialMarker(Form, Coordinates) Export
	
	If Not (Coordinates.Lat = "" And Coordinates.Lng = "") Then
		
		SetVariableValue(Form, "lastMarkerLat", Coordinates.Lat);
		SetVariableValue(Form, "lastMarkerLng", Coordinates.Lng);
		
		If Coordinates.Property("Time") Then
			
			SetVariableValue(Form, "additionalInfo", Coordinates.Time);
			
		EndIf;
		
		If Coordinates.Property("Description") Then
			
			SetVariableValue(Form, "description", Coordinates.Description);
			
		EndIf;
		
		If Coordinates.Property("FullInfo") Then
			
			SetVariableValue(Form, "fullInfo", Coordinates.FullInfo);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Процедура для добавления маркеров на уже инициализированную и загруженную карту.
// Параметры процедуры:
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
// Coordinates - структура полученная через функцию GetCoordinates()
&AtClient
Procedure AddMarker(Form, Coordinates) Export
	
	AddInitialMarker(Form, Coordinates);
	CallFunction(Form,"addMarkerOnCoords");
	
EndProcedure

// Процедура для показа пути на карте. При вызове берутся точки добавленные через процедуру
// AddPathCoordinates() в список точек и по этим точкам составляется путь.
&AtClient
Procedure ShowPath(Form) Export
	
	CallFunction(Form, "showPath");
	
EndProcedure

// Процедура для добавления координат в список точек по которым будет выводиться путь на карте
// Параметры процедуры:
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
// Coordinates - структура полученная через функцию GetCoordinates()
&AtClient
Procedure AddPathCoordinates(Form, Coordinates) Export
	
	AddInitialMarker(Form, Coordinates);
	CallFunction(Form, "addPathCoordinates");
	
EndProcedure

// Процедура для очистки маркеров с карты
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
&AtClient
Procedure ClearMarkers(Form) Export
	
	CallFunction(Form, "clearMarkers");
	
EndProcedure

// Процедура для очистки списка точек о которым будет выводиться путь на карте
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
&AtClient
Procedure ClearPathCoordinates(Form) Export
	
	CallFunction(Form,"clearPathCoordinates");
	
EndProcedure

// Процедура для очистки пути на карте
// Form - форма на которой добавлены необходимые для работы карт  элементы и реквизиты
&AtClient
Procedure ClearPath(Form) Export
	
	CallFunction(Form,"clearPath");
	
EndProcedure

// Функция для получения координат последнего установленного маркера. Полезна при использовании
// логики одного маркера. Возвращает структуру с ключами "Latitude" и "Longitude". Значения - 
// строковое представление широты и долготы последнего установленного на карте маркера.
// Form - форма на которой добавлены необходимые для работы карт элементы и реквизиты.
&AtClient
Function GetLastMarkerCoordinates(Form) Export
	
	Coordinates = New Structure;
	Coordinates.Insert("Latitude", GetVariableValue(Form, "lastMarkerLat"));
	Coordinates.Insert("Longitude", GetVariableValue(Form, "lastMarkerLng"));
	Return Coordinates;
	
EndFunction
