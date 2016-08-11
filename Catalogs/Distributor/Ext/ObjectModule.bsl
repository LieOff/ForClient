
Procedure OnWrite(Cancel)
	
	If Not Cancel Then
		
		Setting = FindSetting();
		
		For Each Row In ThisObject.Territories Do
			
			RecordManager = InformationRegisters.bitmobile_ИзмененныеДанные.CreateRecordManager();
			RecordManager.Period = CurrentDate();
			RecordManager.Ссылка = Row.Territory;
			RecordManager.Порядок = Setting.ПозицияВВыгрузке;
			RecordManager.Write();
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function FindSetting()
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	bitmobile_НастройкиСинхронизации.Ссылка КАК Ссылка
		|ИЗ
		|	Справочник.bitmobile_НастройкиСинхронизации КАК bitmobile_НастройкиСинхронизации
		|ГДЕ
		|	bitmobile_НастройкиСинхронизации.ПометкаУдаления = ЛОЖЬ
		|	И bitmobile_НастройкиСинхронизации.ВыгрузкаДанных = ИСТИНА
		|	И bitmobile_НастройкиСинхронизации.ОбъектКонфигурации = &ИмяМетаданного";
	
	Запрос.УстановитьПараметр("ИмяМетаданного", Metadata.Catalogs.Territory.FullName());
	
	Результат = Запрос.Выполнить();
	
	Выборка = Результат.Выбрать();
	
	Если Выборка.Следующий() Тогда 
		
		Возврат Выборка.Ссылка; 	
		
	Иначе 
		
		Возврат Неопределено;		
		
	КонецЕсли;
	
EndFunction
