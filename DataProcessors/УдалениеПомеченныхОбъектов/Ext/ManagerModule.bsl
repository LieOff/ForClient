﻿#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

////////////////////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

// Возвращает помеченные на удаление объекты. Возможен отбор по фильтру.
//
Функция ПолучитьПомеченныеНаУдаление() Экспорт
	
	УстановитьПривилегированныйРежим(Истина);
	МассивПомеченные = НайтиПомеченныеНаУдаление();
	УстановитьПривилегированныйРежим(Ложь);
	
	Результат = Новый Массив;
	Для Каждого ЭлементПомеченный Из МассивПомеченные Цикл
		Если ПравоДоступа("ИнтерактивноеУдалениеПомеченных", ЭлементПомеченный.Метаданные()) Тогда
			Результат.Добавить(ЭлементПомеченный);
		КонецЕсли
	КонецЦикла;
	
	Возврат Результат;
	
КонецФункции

// Получает массив помеченных для удаления объектов.
//
// Параметры:
//	СписокПомеченныхНаУдаление - ДеревоЗначений - дерево помеченных на удаление объектов.
//	РежимУдаления - Строка - режим удаоения.
// 
// Возвращаемое значение:
//	Массив- массив помеченных на удаление объектов.
//
Функция ПолучитьМассивПомеченныхОбъектовНаУдаление(СписокПомеченныхНаУдаление, РежимУдаления)
	
	Удаляемые = Новый Массив;
	
	Если РежимУдаления = "Full" Тогда
		// При полном удалении получаем весь список помеченных на удаление
		Удаляемые = ПолучитьПомеченныеНаУдаление();
	Иначе
		// Заполняем массив ссылками на выбранные элементы, помеченные на удаление
		КоллекцияСтрокМетаданных = СписокПомеченныхНаУдаление.ПолучитьЭлементы();
		Для Каждого СтрокаОбъектаМетаданных Из КоллекцияСтрокМетаданных Цикл
			КоллекцияСтрокСсылок = СтрокаОбъектаМетаданных.ПолучитьЭлементы();
			Для Каждого СтрокаСсылки Из КоллекцияСтрокСсылок Цикл
				Если СтрокаСсылки.Пометка Тогда
					Удаляемые.Добавить(СтрокаСсылки.Значение);
				КонецЕсли;
			КонецЦикла;
		КонецЦикла;
	КонецЕсли;
	
	Возврат Удаляемые;

КонецФункции	

// Выполняет процесс по удалению объектов.
//
// Параметры:
//	ПараметрыУдаления - Структура - параметры, необходимые для удаления.
//	АдресХранилища - Строка - адрес внутреннего хранилища.
//
Процедура УдалитьПомеченныеОбъекты(ПараметрыУдаления, АдресХранилища) Экспорт
	
	// Извлекаем параметры
	СписокПомеченныхНаУдаление	= ПараметрыУдаления.СписокПомеченныхНаУдаление;
	РежимУдаления				= ПараметрыУдаления.РежимУдаления;
	ТипыУдаленныхОбъектов		= ПараметрыУдаления.ТипыУдаленныхОбъектов;
	
	Удаляемые = ПолучитьМассивПомеченныхОбъектовНаУдаление(СписокПомеченныхНаУдаление, РежимУдаления);
	КоличествоУдаляемых = Удаляемые.Количество();
	
	// Выполняем удаление
	Результат = ВыполнитьУдаление(Удаляемые, ТипыУдаленныхОбъектов);
	
	// Добавляем параметры 
	Если ТипЗнч(Результат.Значение) = Тип("Структура") Тогда 
		КоличествоНеУдаленныхОбъектов = Результат.Значение.НеУдаленные.Количество();
	Иначе	
		КоличествоНеУдаленныхОбъектов = 0;
	КонецЕсли;	
	Результат.Вставить("КоличествоНеУдаленныхОбъектов", КоличествоНеУдаленныхОбъектов);
	Результат.Вставить("КоличествоУдаляемых",			КоличествоУдаляемых);
	Результат.Вставить("ТипыУдаленныхОбъектов",			ТипыУдаленныхОбъектов);
	
	ПоместитьВоВременноеХранилище(Результат, АдресХранилища);

КонецПроцедуры

// Выполняет удаление объектов.
//
// Параметры:
//	Удаляемые - Массив - массив помеченных на удаление.
//	ТипыУдаленныхОбъектовМассив - Массив - массив типов удаленных объектов. 
//
// Возвращаемое значение:
//	Структура - структура с результатом удаления.
//
Функция ВыполнитьУдаление(Знач Удаляемые, ТипыУдаленныхОбъектовМассив) 
	РезультатУдаления = Новый Структура("Статус, Значение", Ложь, "");
	
	Если НЕ Users.IsFullRightUser() Тогда
		ВызватьИсключение НСтр("ru = 'Недостаточно прав для выполнения операции.'");
	КонецЕсли;
	
	Попытка
		ОбщегоНазначения.ЗаблокироватьИБ();
	Исключение
		РезультатУдаления.Значение = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Не удалось установить монопольный режим (%1)'"),
			КраткоеПредставлениеОшибки(ИнформацияОбОшибке())
		);
		Возврат РезультатУдаления;
	КонецПопытки;
	
	ТипыУдаленныхОбъектов = Новый ТаблицаЗначений;
	ТипыУдаленныхОбъектов.Колонки.Добавить("Тип", Новый ОписаниеТипов("Тип"));
	Для Каждого УдаляемыйОбъект Из Удаляемые Цикл
		НовыйТип = ТипыУдаленныхОбъектов.Добавить();
		НовыйТип.Тип = ТипЗнч(УдаляемыйОбъект);
	КонецЦикла;
	ТипыУдаленныхОбъектов.Свернуть("Тип");
	
	НеУдаленные = Новый Массив;
	
	Найденные = Новый ТаблицаЗначений;
	Найденные.Колонки.Добавить("УдаляемыйСсылка");
	Найденные.Колонки.Добавить("ОбнаруженныйСсылка");
	Найденные.Колонки.Добавить("ОбнаруженныйМетаданные");
	
	УдаляемыеОбъекты = Новый Массив;
	Для Каждого СсылкаНаОбъект Из Удаляемые Цикл
		УдаляемыеОбъекты.Добавить(СсылкаНаОбъект);
	КонецЦикла;
	
	МетаданныеРегистрыСведений = Метаданные.РегистрыСведений;
	МетаданныеРегистрыНакопления = Метаданные.РегистрыНакопления;
	МетаданныеРегистрыБухгалтерии = Метаданные.РегистрыБухгалтерии;
	
	ИсключенияПоискаСсылок = ОбщегоНазначения.ПолучитьОбщийСписокИсключенийПоискаСсылок();
	
	ИсключающиеПравилаОбъектаМетаданных = Новый Соответствие;
	
	Пока УдаляемыеОбъекты.Количество() > 0 Цикл
		ПрепятствуюшиеУдалению = Новый ТаблицаЗначений;
		
		// Попытка удалить с контролем ссылочной целостности.
		Попытка
			УстановитьПривилегированныйРежим(Истина);
			УдалитьОбъекты(УдаляемыеОбъекты, Истина, ПрепятствуюшиеУдалению);
			УстановитьПривилегированныйРежим(Ложь);
		Исключение
			ОбщегоНазначения.РазблокироватьИБ();
			РезультатУдаления.Значение = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
			Возврат РезультатУдаления;
		КонецПопытки;
		
		КоличествоУдаляемыхОбъектов = УдаляемыеОбъекты.Количество();
		
		// Назначение имен колонок для таблицы конфликтов, возникших при удалении.
		ПрепятствуюшиеУдалению.Колонки[0].Имя = "УдаляемыйСсылка";
		ПрепятствуюшиеУдалению.Колонки[1].Имя = "ОбнаруженныйСсылка";
		ПрепятствуюшиеУдалению.Колонки[2].Имя = "ОбнаруженныйМетаданные";
		
		// Перемещение удаляемых объектов в список не удаленных
		// и добавление в список найденных зависимых объектов
		// с учетом исключения поиска ссылок.
		Для Каждого СтрокаТаблицы Из ПрепятствуюшиеУдалению Цикл
			ИсключениеПоиска = ИсключенияПоискаСсылок[СтрокаТаблицы.ОбнаруженныйМетаданные];
			
			Если ИсключениеПоиска = "*" Тогда
				Продолжить; // Можно удалять (обнаруженный объект метаданных не мешает).
			КонецЕсли;
			
			// Определение исключащего правила для объекта метаданных, препятствующего удалению:
			// Для регистров (т.н. "необъектных таблиц") - массива реквизитов для поиска в записи регистра.
			// Для ссылочных типов (т.н. "объектных таблиц") - готового запроса для поиска в реквизитах.
			ИменаРеквизитовИлиЗапрос = ИсключающиеПравилаОбъектаМетаданных[СтрокаТаблицы.ОбнаруженныйМетаданные];
			Если ИменаРеквизитовИлиЗапрос = Неопределено Тогда
				
				// Формирование исключащего правила.
				ЭтоРегистрСведений = МетаданныеРегистрыСведений.Содержит(СтрокаТаблицы.ОбнаруженныйМетаданные);
				Если ЭтоРегистрСведений
					ИЛИ МетаданныеРегистрыБухгалтерии.Содержит(СтрокаТаблицы.ОбнаруженныйМетаданные) // ЭтоРегистрБухгалтерии
					ИЛИ МетаданныеРегистрыНакопления.Содержит(СтрокаТаблицы.ОбнаруженныйМетаданные) Тогда // ЭтоРегистрНакопления
					
					ИменаРеквизитовИлиЗапрос = Новый Массив;
					Если ЭтоРегистрСведений Тогда
						Для Каждого Измерение Из СтрокаТаблицы.ОбнаруженныйМетаданные.Измерения Цикл
							Если Измерение.Ведущее Тогда
								ИменаРеквизитовИлиЗапрос.Добавить(Измерение.Имя);
							КонецЕсли;
						КонецЦикла;
					Иначе
						Для Каждого Измерение Из СтрокаТаблицы.ОбнаруженныйМетаданные.Измерения Цикл
							ИменаРеквизитовИлиЗапрос.Добавить(Измерение.Имя);
						КонецЦикла;
					КонецЕсли;
					
					Если ТипЗнч(ИсключениеПоиска) = Тип("Массив") Тогда
						Для Каждого ИмяРеквизита Из ИсключениеПоиска Цикл
							Если ИменаРеквизитовИлиЗапрос.Найти(ИмяРеквизита) = Неопределено Тогда
								ИменаРеквизитовИлиЗапрос.Добавить(ИмяРеквизита);
							КонецЕсли;
						КонецЦикла;
					КонецЕсли;
					
				ИначеЕсли ТипЗнч(ИсключениеПоиска) = Тип("Массив") Тогда
					
					ТекстЗапроса =
					"ВЫБРАТЬ РАЗРЕШЕННЫЕ ПЕРВЫЕ 1
					|	1
					|ИЗ
					|	&ПутьКТаблице КАК Таблица
					|ГДЕ
					|	Таблица.Ссылка = &ОбнаруженныйСсылка
					|	И (&ОтборПоСсылкеУдаляемого)";
					
					ОтборПоСсылкеУдаляемого = "";
					
					Для Каждого ИмяРеквизита Из ИсключениеПоиска Цикл
						Если ОтборПоСсылкеУдаляемого <> "" Тогда
							ОтборПоСсылкеУдаляемого = ОтборПоСсылкеУдаляемого + Символы.ПС + Символы.Таб + Символы.Таб + "ИЛИ ";
						КонецЕсли;
						ОтборПоСсылкеУдаляемого = ОтборПоСсылкеУдаляемого + "Таблица." + ИмяРеквизита + " = &УдаляемыйСсылка";
					КонецЦикла;
					
					ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ПутьКТаблице", СтрокаТаблицы.ОбнаруженныйМетаданные.ПолноеИмя());
					ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ОтборПоСсылкеУдаляемого", ОтборПоСсылкеУдаляемого);
					
					ИменаРеквизитовИлиЗапрос = Новый Запрос;
					ИменаРеквизитовИлиЗапрос.Текст = ТекстЗапроса;
					
				Иначе
					
					ИменаРеквизитовИлиЗапрос = "";
					
				КонецЕсли;
				
				ИсключающиеПравилаОбъектаМетаданных.Вставить(СтрокаТаблицы.ОбнаруженныйМетаданные, ИменаРеквизитовИлиЗапрос);
				
			КонецЕсли;
			
			// Проверка исключащего правила.
			Если ТипЗнч(ИменаРеквизитовИлиЗапрос) = Тип("Массив") Тогда
				УдаляемаяСсылкаВИсключаемомРеквизите = Ложь;
				
				Для Каждого ИмяРеквизита Из ИменаРеквизитовИлиЗапрос Цикл
					Если СтрокаТаблицы.ОбнаруженныйСсылка[ИмяРеквизита] = СтрокаТаблицы.УдаляемыйСсылка Тогда
						УдаляемаяСсылкаВИсключаемомРеквизите = Истина;
						Прервать;
					КонецЕсли;
				КонецЦикла;
				
				Если УдаляемаяСсылкаВИсключаемомРеквизите Тогда
					Продолжить; // Можно удалять (обнаруженная запись регистра не мешает).
				КонецЕсли;
			ИначеЕсли ТипЗнч(ИменаРеквизитовИлиЗапрос) = Тип("Запрос") Тогда
				ИменаРеквизитовИлиЗапрос.УстановитьПараметр("УдаляемыйСсылка", СтрокаТаблицы.УдаляемыйСсылка);
				ИменаРеквизитовИлиЗапрос.УстановитьПараметр("ОбнаруженныйСсылка", СтрокаТаблицы.ОбнаруженныйСсылка);
				Если НЕ ИменаРеквизитовИлиЗапрос.Выполнить().Пустой() Тогда
					Продолжить; // Можно удалять (обнаруженная ссылка не мешает).
				КонецЕсли;
			КонецЕсли;
			
			// Все исключающие правила пройдены.
			// Невозможно удалить объект (мешает обнаруженная ссылка или запись регистра).
			// Сокращение удаляемых объектов.
			Индекс = УдаляемыеОбъекты.Найти(СтрокаТаблицы.УдаляемыйСсылка);
			Если Индекс <> Неопределено Тогда
				УдаляемыеОбъекты.Удалить(Индекс);
			КонецЕсли;
			
			// Добавление не удаленных объектов.
			Если НеУдаленные.Найти(СтрокаТаблицы.УдаляемыйСсылка) = Неопределено Тогда
				НеУдаленные.Добавить(СтрокаТаблицы.УдаляемыйСсылка);
			КонецЕсли;
			
			// Добавление найденных зависимых объектов.
			НоваяСтрока = Найденные.Добавить();
			ЗаполнитьЗначенияСвойств(НоваяСтрока, СтрокаТаблицы);
			
		КонецЦикла;
		
		// Удаление без контроля, если состав удаляемых объектов не был изменён на этом шаге цикла.
		Если КоличествоУдаляемыхОбъектов = УдаляемыеОбъекты.Количество() Тогда
			Попытка
				// Удаление без контроля ссылочной целостности.
				УстановитьПривилегированныйРежим(Истина);
				УдалитьОбъекты(УдаляемыеОбъекты, Ложь);
				УстановитьПривилегированныйРежим(Ложь);
			Исключение
				ОбщегоНазначения.РазблокироватьИБ();
				РезультатУдаления.Значение = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
				Возврат РезультатУдаления;
			КонецПопытки;
			
			// Удаление всего, что возможно, завершено - выход из цикла.
			Прервать;
		КонецЕсли;
	КонецЦикла;
	
	Для Каждого НеУдаленныйОбъект Из НеУдаленные Цикл
		НайденныеСтроки = ТипыУдаленныхОбъектов.НайтиСтроки(Новый Структура("Тип", ТипЗнч(НеУдаленныйОбъект)));
		Если НайденныеСтроки.Количество() > 0 Тогда
			ТипыУдаленныхОбъектов.Удалить(НайденныеСтроки[0]);
		КонецЕсли;
	КонецЦикла;
	
	ТипыУдаленныхОбъектовМассив = ТипыУдаленныхОбъектов.ВыгрузитьКолонку("Тип");
	
	ОбщегоНазначения.РазблокироватьИБ();
	
	Найденные.Колонки.УдаляемыйСсылка.Имя        = "Ссылка";
	Найденные.Колонки.ОбнаруженныйСсылка.Имя     = "Данные";
	Найденные.Колонки.ОбнаруженныйМетаданные.Имя = "Метаданные";
	
	РезультатУдаления.Статус = Истина;
	РезультатУдаления.Значение = Новый Структура("Найденные, НеУдаленные", Найденные, НеУдаленные);
	
	Возврат РезультатУдаления;
КонецФункции

#КонецЕсли

