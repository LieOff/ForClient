﻿
Функция ПолучитьКартуGoogle(ТаблицаТочекДляОтображения, ПодсказкаПриНаведении =  Истина, АдресСтарта = "Москва") Экспорт
	
	Макет = ЭтотОбъект.ПолучитьМакет("NSI_МакетКартыGoogle");
	
	ТекстКарты = Макет.ПолучитьТекст();
		
	ТекстКарты = СтрЗаменить(ТекстКарты, "geocoder.geocode( { 'address': StartAdress}, function(results, status) {", "geocoder.geocode( { 'address': """ + АдресСтарта + """}, function(results, status) {");
	
	Возврат ТекстКарты;
	
КонецФункции

Функция СоздатьТаблицуДляПередачиКоординат() Экспорт
	
	Таблица = Новый ТаблицаЗначений;
	Таблица.Колонки.Добавить("Широта", Новый ОписаниеТипов("Число", Новый КвалификаторыЧисла(20,10)));
	Таблица.Колонки.Добавить("Долгота", Новый ОписаниеТипов("Число", Новый КвалификаторыЧисла(20,10)));
	Таблица.Колонки.Добавить("Адрес", Новый ОписаниеТипов("Строка"));
	Таблица.Колонки.Добавить("Цвет", Новый ОписаниеТипов("Строка"));
	Таблица.Колонки.Добавить("Текст", Новый ОписаниеТипов("Строка"));
	Таблица.Колонки.Добавить("НавигационнаяСсылка", Новый ОписаниеТипов("Строка"));
	Возврат Таблица;
	
КонецФункции

