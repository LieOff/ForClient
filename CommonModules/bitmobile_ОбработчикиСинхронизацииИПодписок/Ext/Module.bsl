﻿
Процедура ПриЗаписи(Источник, Отказ) Экспорт
	
	Если Константы.bitmobile_ОтключитьПодпискиНаСобытия.Получить() Тогда 
		
		Возврат;
		
	КонецЕсли;
	
	Настройка = НайтиНастройку(Источник);
	
	Если Настройка = Неопределено Тогда 
		
		Возврат;
		
	КонецЕсли;
	
	Если Не Источник.ДополнительныеСвойства.Свойство("ЗагрузкаBitmobile") Тогда 
		
		Запись					= РегистрыСведений.bitmobile_ИзмененныеДанные.СоздатьМенеджерЗаписи();
		Запись.Ссылка			= Источник.Ссылка;
		Запись.Обрабатывается	= Ложь;
		Запись.Порядок			= Настройка.ПозицияВВыгрузке;
		
		Запись.Записать();
		
	КонецЕсли;
	
КонецПроцедуры
 
Процедура ПриЗаписиРегистра(Источник, Отказ, Замещение) Экспорт
	
	Если Константы.bitmobile_ОтключитьПодпискиНаСобытия.Получить() Тогда 
		
		Возврат;
		
	КонецЕсли;
	
	МетаданныеИсточника = Источник.Метаданные();
	
	Если МетаданныеИсточника.Имя = "bitmobile_ИзмененныеДанные" Тогда
		
		Возврат;
		
	КонецЕсли;
	
	ИмяРегистра = МетаданныеИсточника.ПолноеИмя();
	
	// Найти все контролируемые для этого регистра измерения
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	bitmobile_КонтролируемыеИзмеренияРегистров.ИмяИзмерения
		|ИЗ
		|	РегистрСведений.bitmobile_КонтролируемыеИзмеренияРегистров КАК bitmobile_КонтролируемыеИзмеренияРегистров
		|ГДЕ
		|	bitmobile_КонтролируемыеИзмеренияРегистров.ИмяРегистра = &ИмяРегистра";
		
	Запрос.УстановитьПараметр("ИмяРегистра", ИмяРегистра);
	
	ТаблицаИзмерений = Запрос.Выполнить().Выгрузить();
	
	Если Не ТаблицаИзмерений.Количество() = 0 Тогда
		
		// Получить таблицу актуальных настроек
		Запрос = Новый Запрос;
		Запрос.Текст = 
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ
			|	bitmobile_НастройкиСинхронизации.Ссылка КАК Ссылка,
			|	bitmobile_НастройкиСинхронизации.ОбъектКонфигурации КАК ОбъектКонфигурации,
			|	bitmobile_НастройкиСинхронизации.ПозицияВВыгрузке КАК ПозицияВВыгрузке
			|ИЗ
			|	Справочник.bitmobile_НастройкиСинхронизации КАК bitmobile_НастройкиСинхронизации
			|ГДЕ
			|	bitmobile_НастройкиСинхронизации.ПометкаУдаления = ЛОЖЬ
			|	И bitmobile_НастройкиСинхронизации.ВыгрузкаДанных = ИСТИНА";
			
		ТаблицаНастроек = Запрос.Выполнить().Выгрузить();
		
		Для Каждого ЭлементИсточника Из Источник Цикл
			
			Для Каждого СтрокаИзмерения Из ТаблицаИзмерений Цикл 
				
				Попытка
					
					ЗначениеИзмерения = ЭлементИсточника[СтрокаИзмерения.ИмяИзмерения];
					
				Исключение
					
					Продолжить;
					
				КонецПопытки;
				
				ТипЗначенияИзмерения = ТипЗнч(ЗначениеИзмерения);
				
				Если ЗначениеЗаполнено(ЗначениеИзмерения) 
					И (Справочники.ТипВсеСсылки().СодержитТип(ТипЗначенияИзмерения) Или Документы.ТипВсеСсылки().СодержитТип(ТипЗначенияИзмерения)) Тогда 
					
					ИмяМетаданного = ЗначениеИзмерения.Метаданные().ПолноеИмя();
					
					Настройка = ТаблицаНастроек.Найти(ИмяМетаданного, "ОбъектКонфигурации");
					
					Если Не Настройка = Неопределено Тогда
						
						Запись					= РегистрыСведений.bitmobile_ИзмененныеДанные.СоздатьМенеджерЗаписи();
						Запись.Ссылка			= ЗначениеИзмерения;
						Запись.Обрабатывается	= Ложь;
						Запись.Порядок			= Настройка.ПозицияВВыгрузке;
						
						Запись.Записать();
						
					КонецЕсли;
					
				КонецЕсли;
				
			КонецЦикла;
			
		КонецЦикла;
		
	КонецЕсли;
	
КонецПроцедуры

Функция НайтиНастройку(Источник)
	
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
	
	Запрос.УстановитьПараметр("ИмяМетаданного", Источник.Метаданные().ПолноеИмя());
	
	Результат = Запрос.Выполнить();
	
	Выборка = Результат.Выбрать();
	
	Если Выборка.Следующий() Тогда 
		
		Возврат Выборка.Ссылка; 	
		
	Иначе 
		
		Возврат Неопределено;		
		
	КонецЕсли;
	
КонецФункции

Функция ИспользуетсяАнглийскийЯзык() Экспорт 
	
	Если Метаданные.ВариантВстроенногоЯзыка = Метаданные.СвойстваОбъектов.ВариантВстроенногоЯзыка.Русский Тогда
		
		Возврат Ложь;
		
	Иначе 
		
		Возврат Истина;
		
	КонецЕсли;
	
КонецФункции

Процедура Синхронизация() Экспорт 
	
	НачатьСинхронизацию = Ложь;
	
	НачатьТранзакцию();
	
	Попытка
		
		// В автоматическом режиме блокировок установка управляемой блокировки вызовет ошибку
		Если Не Метаданные.РежимУправленияБлокировкойДанных = Метаданные.СвойстваОбъектов.РежимУправленияБлокировкойДанныхПоУмолчанию.Автоматический Тогда 
		
			Блокировка = Новый БлокировкаДанных;
			
			ЭлементБлокировки = Блокировка.Добавить("Константа.bitmobile_СинхронизацияЗапущена");
			ЭлементБлокировки.Режим = РежимБлокировкиДанных.Исключительный;
			
			Блокировка.Заблокировать();
			
		КонецЕсли;
		
		// Эмулируем занятость константы на время проверки для исключения повторного входа в синхронизацию
		Константы.bitmobile_СинхронизацияЗапущена.Установить(Константы.bitmobile_СинхронизацияЗапущена.Получить());
		
		Обработки.bitmobile_СинхронизацияИНастройки.ПроверитьСостояниеСинхронизации(НачатьСинхронизацию);
		
	Исключение
		
	КонецПопытки;
	
	Если НачатьСинхронизацию Тогда 
		
		УстановленЗапускСинхронизации = Ложь;
		
		СеансыИБ	= ПолучитьСеансыИнформационнойБазы();
		НомерСеанса	= НомерСеансаИнформационнойБазы();
		
		Для Каждого СеансИБ Из СеансыИБ Цикл 
			
			Если СеансИБ.НомерСеанса = НомерСеанса Тогда 
				
				IDСеанса = Строка(СеансИБ.НомерСеанса) + Строка(СеансИБ.НачалоСеанса);
				
				Попытка
					
					Константы.bitmobile_СинхронизацияЗапущена.Установить(IDСеанса);
					
					УстановленЗапускСинхронизации = Истина;
					
				Исключение
					
				КонецПопытки;
				
			КонецЕсли;
			
		КонецЦикла;
		
		ЗафиксироватьТранзакцию();
		
		Если УстановленЗапускСинхронизации Тогда 
			
			// Блок обработчиков выполняемых перед синхронизацией данных
			
			УстановитьПривилегированныйРежим(Истина);
			
			SyncSuperAgent.SetStatusOfQuestionnaires();
			SyncSuperAgent.SetStatusOfAssortmentMatrix(CurrentDate());
			SyncSuperAgent.ActualizePeriodicity();
			SyncSuperAgent.CheckSRsInQuestionnaire();
			
			УстановитьПривилегированныйРежим(Ложь);
			
			// Конец блока обработчиков выполняемых перед синхронизацией данных
			
			Обработки.bitmobile_СинхронизацияИНастройки.ЗагрузитьДанные();
			
			Обработки.bitmobile_СинхронизацияИНастройки.ВыгрузитьДанные(); 
			
		КонецЕсли;
		
	Иначе 
		
		ЗафиксироватьТранзакцию();
		
	КонецЕсли;
	
КонецПроцедуры

Процедура СинхронизацияФайлов() Экспорт
	
	СинхронизацияЗапущена = Константы.bitmobile_СинхронизацияФайловЗапущена.Получить();
	
	Если Не СинхронизацияЗапущена Тогда 
		
		КонстантаУстановлена = Ложь;	
		
		Попытка
			
			Константы.bitmobile_СинхронизацияФайловЗапущена.Установить(Истина);
			
			КонстантаУстановлена = Истина;
			
		Исключение
			
		КонецПопытки;
		
		Если КонстантаУстановлена Тогда 
			
			Обработки.bitmobile_СинхронизацияИНастройки.СинхронизироватьФайлы();
			
			Константы.bitmobile_СинхронизацияФайловЗапущена.Установить(Ложь);
			
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

Процедура СинхронизацияСУчетнымиСистемами() Экспорт
	
	Для Каждого ПланОбмена Из Метаданные.ПланыОбмена Цикл
		
		ПланОбменаОбработка = ПланыОбмена[ПланОбмена.Имя];
		
		ЭтотУзелОбработка = ПланОбменаОбработка.ЭтотУзел();
		
		УзлыВыборка = ПланОбменаОбработка.Выбрать();
		
		Пока УзлыВыборка.Следующий() Цикл
			
			Если УзлыВыборка.ВариантОбмена = 0 Тогда // Обмен отключен
				
				Продолжить;
				
			КонецЕсли;
			
			ДвоичныеДанные			= УзлыВыборка.ПравилаОбмена.Получить();
			ИмяФайлаПравилОбмена	= ПолучитьИмяВременногоФайла("xml");
			
			ДвоичныеДанные.Записать(ИмяФайлаПравилОбмена);
			
			ОбработкаОбмена							= Обработки.УниверсальныйОбменДаннымиXML.Создать();
			ОбработкаОбмена.ИмяФайлаПравилОбмена	= ИмяФайлаПравилОбмена;
			
			ОбработкаОбмена.ЗагрузитьПравилаОбмена();
			ОбработкаОбмена.Параметры.Вставить("КодУзла", ЭтотУзелОбработка.Код);
			
			Попытка
				
				УдалитьФайлы(ИмяФайлаПравилОбмена);
				
			Исключение
			КонецПопытки;
			
			ОбработкаОбмена.ТипУдаленияРегистрацииИзмененийДляУзловОбменаПослеВыгрузки	= 0;
			ОбработкаОбмена.РежимОбмена													= "Выгрузка";
			
			ЗаписьЖурналаРегистрации("Обмен данными с узлом: " + УзлыВыборка.Код, УровеньЖурналаРегистрации.Информация, ПланОбмена, "Начало обмена");
			
			Если УзлыВыборка.ВариантОбмена = 1 Тогда // Используется сервер bitmobile
				
				СоединениеУстановлено	= Ложь;
				Соединение 				= CommonProcessors.GetConnectionToServer();
				
				Если Не Соединение = Неопределено Тогда
				
					Путь	= Константы.bitmobile_ПутьНаСервере.Получить();
					Путь	= СтрЗаменить(Путь, "admin/", "webdav");
					Порт	= Константы.bitmobile_Порт.Получить();
					
					СоединениеУстановлено = Истина;
					
				Иначе
					
					СоединениеУстановлено = Ложь;
					
					ЗаписьЖурналаРегистрации("Обмен данными с узлом: " + УзлыВыборка.Код, УровеньЖурналаРегистрации.Ошибка, ПланОбмена, "Ошибка установки соединения");
					
				КонецЕсли;
				
				Если СоединениеУстановлено Тогда
					
					ОбработкаОбмена.ИмяФайлаОбмена = ПолучитьИмяВременногоФайла("xml");
					
					ОбработкаОбмена.ВыполнитьВыгрузку();
					
					Соединение.Записать(ОбработкаОбмена.ИмяФайлаОбмена, Путь + "/exchange/msg_" + ЭтотУзелОбработка.Код + "_" + УзлыВыборка.Код + "_" + Формат(ТекущаяДатаСеанса(), "DF=гггг_ММ_дд_чч_мм_сс") + ".xml");
					
					ТаблицаФайловОбмена = Новый ТаблицаЗначений;
					ТаблицаФайловОбмена.Колонки.Добавить("Файл");
					ТаблицаФайловОбмена.Колонки.Добавить("ВремяИзменения");
					
					Попытка
						
						ФайлТаблицыОбменов = ПолучитьИмяВременногоФайла(".txt");
						
						Соединение.Получить(Путь + "/exchange.txt", ФайлТаблицыОбменов);
						
						Результат = Новый ТекстовыйДокумент();
						Результат.Прочитать(ФайлТаблицыОбменов, КодировкаТекста.UTF8);
						
						// Получить маску файла
						МаскаФайла = "msg_" + УзлыВыборка.Код + "_" + ЭтотУзелОбработка.Код + "_";
						
						Для Инд = 1 По Результат.КоличествоСтрок() Цикл 
							
							СтрокаФайла = Результат.ПолучитьСтроку(Инд);
							
							// Получить имя файла
							СтрокаИмениФайла = СокрЛП(Лев(СтрокаФайла, Найти(СтрокаФайла, "|") - 1));
							
							Если Найти(СтрокаИмениФайла, МаскаФайла) > 0 И НРег(Прав(СтрокаИмениФайла, 4)) = ".xml" Тогда
								
								// Получить строку времени файла
								СтрокаФайла			= СтрЗаменить(СтрокаФайла, СтрокаИмениФайла + "|", "");
								СтрокаВремениФайла	= СокрЛП(Лев(СтрокаФайла, Найти(СтрокаФайла, "|") - 1));
								СтрокаВремениФайла	= СтрЗаменить(СтрокаВремениФайла, ".", "");
								СтрокаВремениФайла	= СтрЗаменить(СтрокаВремениФайла, ":", "");
								СтрокаВремениФайла	= СтрЗаменить(СтрокаВремениФайла, " ", "");
								
								// Обработать имя файла
								СтрокаИмениФайла = СтрЗаменить(СтрокаИмениФайла, "\", "/"); 
								СтрокаИмениФайла = Прав(СтрокаИмениФайла, СтрДлина(СтрокаИмениФайла) - 1);
								
								Вставка					= ТаблицаФайловОбмена.Добавить();
								Вставка.Файл			= "/exchange/" + СтрокаИмениФайла;
								Вставка.ВремяИзменения	= Дата(СтрокаВремениФайла);
								
							КонецЕсли;
							
						КонецЦикла;
						
					Исключение
						
						ЗаписьЖурналаРегистрации("Обмен данными с узлом: " + УзлыВыборка.Код, УровеньЖурналаРегистрации.Ошибка, ПланОбмена, "Ошибка получения списка файлов");
						
					КонецПопытки;
					
					ТаблицаФайловОбмена.Сортировать("ВремяИзменения Возр");
					
					Для Каждого СтрокаФайла Из ТаблицаФайловОбмена Цикл
						
						ИмяВременногоФайла = ПолучитьИмяВременногоФайла("xml");
						
						Соединение.Получить(Путь + СтрокаФайла.Файл, ИмяВременногоФайла);
						
						ОбработкаОбмена.РежимОбмена = "Загрузка";
						
						ОбработкаОбмена.ИмяФайлаОбмена = ИмяВременногоФайла;
						
						ОбработкаОбмена.ВыполнитьЗагрузку();
						
						Соединение.Удалить(Путь + СтрокаФайла.Файл);
						
					КонецЦикла;
					
					Соединение = Неопределено;
					
				КонецЕсли;
				
			ИначеЕсли УзлыВыборка.ВариантОбмена = 2 Тогда // Используется FTP сервер
				
				ОбработкаОбмена.ИмяФайлаОбмена = ПолучитьИмяВременногоФайла("xml");
			
				ОбработкаОбмена.ВыполнитьВыгрузку();
				
				ПутьНаFTP = УзлыВыборка.FTP_Путь;
				
				Если Не Прав(ПутьНаFTP, 1) = "/" Тогда
					
					ПутьНаFTP = ПутьНаFTP + "/";
					
				КонецЕсли;
				
				Если Не Лев(ПутьНаFTP, 1) = "/" Тогда
					
					ПутьНаFTP = "/" + ПутьНаFTP;
					
				КонецЕсли;
				
				FTP = Новый FTPСоединение(УзлыВыборка.FTP_Сервер, , УзлыВыборка.FTP_Пользователь, УзлыВыборка.FTP_Пароль, , Истина);
				
				FTP.Записать(ОбработкаОбмена.ИмяФайлаОбмена, ПутьНаFTP + "msg_" + ЭтотУзелОбработка.Код + "_" + УзлыВыборка.Код + "_" + Формат(ТекущаяДатаСеанса(), "DF=гггг_ММ_дд_чч_мм_сс") + ".xml");
				
				ФайлыИзFTP = FTP.НайтиФайлы(ПутьНаFTP, "msg_" + УзлыВыборка.Код + "_" + ЭтотУзелОбработка.Код + "_*.xml");
				
				Если ФайлыИзFTP.Количество() > 0 Тогда
					
					ТаблицаФайловИзFTP = Новый ТаблицаЗначений;
					ТаблицаФайловИзFTP.Колонки.Добавить("Файл");
					ТаблицаФайловИзFTP.Колонки.Добавить("ВремяИзменения");
					
					// Упорядочить файлы по времени создания
					Для Каждого НайденныйФайлFTP Из ФайлыИзFTP Цикл
						
						ВставкаВТаблицу					= ТаблицаФайловИзFTP.Добавить();
						ВставкаВТаблицу.Файл			= НайденныйФайлFTP;
						ВставкаВТаблицу.ВремяИзменения	= НайденныйФайлFTP.ПолучитьВремяИзменения();
						
					КонецЦикла;
					
					ТаблицаФайловИзFTP.Сортировать("ВремяИзменения Возр");
					
					Для Каждого СтрокаФайлаFTP Из ТаблицаФайловИзFTP Цикл
						
						ИмяВременногоФайлаFTP = ПолучитьИмяВременногоФайла("xml");
						
						FTP.Получить(СтрокаФайлаFTP.Файл.ПолноеИмя, ИмяВременногоФайлаFTP);
						
						ОбработкаОбмена.РежимОбмена = "Загрузка";
						
						ОбработкаОбмена.ИмяФайлаОбмена = ИмяВременногоФайлаFTP;
						
						ОбработкаОбмена.ВыполнитьЗагрузку();
						
						FTP.Удалить(СтрокаФайлаFTP.Файл.ПолноеИмя);
						
					КонецЦикла;
					
				КонецЕсли;
				
				FTP = Неопределено;
				
			ИначеЕсли УзлыВыборка.ВариантОбмена = 3 Тогда // Используется директория на диске
				
				ПутьНаДиске = УзлыВыборка.Диск_Каталог;
				
				Если Не Прав(ПутьНаДиске, 1) = "\" Тогда
					
					ПутьНаДиске = ПутьНаДиске + "\";
					
				КонецЕсли;
				
				ОбработкаОбмена.ИмяФайлаОбмена = ПутьНаДиске + "msg_" + ЭтотУзелОбработка.Код + "_" + УзлыВыборка.Код + "_" + Формат(ТекущаяДатаСеанса(), "DF=гггг_ММ_дд_чч_мм_сс") + ".xml";
			
				ОбработкаОбмена.ВыполнитьВыгрузку();
				
				ФайлыИзДиректории = НайтиФайлы(ПутьНаДиске, "msg_" + УзлыВыборка.Код + "_" + ЭтотУзелОбработка.Код + "_*.xml");
				
				Если ФайлыИзДиректории.Количество() > 0 Тогда
					
					ТаблицаФайловИзДиректории = Новый ТаблицаЗначений;
					ТаблицаФайловИзДиректории.Колонки.Добавить("Файл");
					ТаблицаФайловИзДиректории.Колонки.Добавить("ВремяИзменения");
					
					// Упорядочить файлы по времени создания
					Для Каждого НайденныйФайл Из ФайлыИзДиректории Цикл
						
						ВставкаВТаблицу					= ТаблицаФайловИзДиректории.Добавить();
						ВставкаВТаблицу.Файл			= НайденныйФайл;
						ВставкаВТаблицу.ВремяИзменения	= НайденныйФайл.ПолучитьВремяИзменения();
						
					КонецЦикла;
					
					ТаблицаФайловИзДиректории.Сортировать("ВремяИзменения Возр");
					
					Для Каждого СтрокаФайла Из ТаблицаФайловИзДиректории Цикл
						
						ОбработкаОбмена.РежимОбмена = "Загрузка";
						
						ОбработкаОбмена.ИмяФайлаОбмена = СтрокаФайла.Файл.ПолноеИмя;
						
						ОбработкаОбмена.ВыполнитьЗагрузку();
						
						УдалитьФайлы(СтрокаФайла.Файл.ПолноеИмя);
						
					КонецЦикла;
					
				КонецЕсли;
				
			ИначеЕсли УзлыВыборка.ВариантОбмена = 4 Тогда // Используется прямое подключение
				
				ОбработкаОбмена.НепосредственноеЧтениеВИБПриемнике = Истина;
				
				ОбработкаОбмена.ТипИнформационнойБазыДляПодключения							= УзлыВыборка.ПрямоеПодключение_ТипИБ;
				ОбработкаОбмена.ВерсияПлатформыИнформационнойБазыДляПодключения				= УзлыВыборка.ПрямоеПодключение_ВерсияПлатформы;
				
				Если УзлыВыборка.ПрямоеПодключение_ТипИБ Тогда
					
					ОбработкаОбмена.КаталогИнформационнойБазыДляПодключения					= УзлыВыборка.ПрямоеПодключение_Каталог;
					
				Иначе
					
					ОбработкаОбмена.ИмяСервераИнформационнойБазыДляПодключения				= УзлыВыборка.ПрямоеПодключение_ИмяСервера;
					ОбработкаОбмена.ИмяИнформационнойБазыНаСервереДляПодключения			= УзлыВыборка.ПрямоеПодключение_ИБ;
					
				КонецЕсли;
				
				Если УзлыВыборка.ПрямоеПодключение_АутентификацияWindows Тогда
					
					ОбработкаОбмена.АутентификацияWindowsИнформационнойБазыДляПодключения	= Истина;
					ОбработкаОбмена.ПользовательИнформационнойБазыДляПодключения			= "";
					ОбработкаОбмена.ПарольИнформационнойБазыДляПодключения					= "";
					
				Иначе
					
					ОбработкаОбмена.АутентификацияWindowsИнформационнойБазыДляПодключения	= Ложь;
					ОбработкаОбмена.ПользовательИнформационнойБазыДляПодключения			= УзлыВыборка.ПрямоеПодключение_Пользователь;
					ОбработкаОбмена.ПарольИнформационнойБазыДляПодключения					= УзлыВыборка.ПрямоеПодключение_Пароль;
					
				КонецЕсли;
				
				ОбработкаОбмена.ВыполнитьВыгрузку();
				
			КонецЕсли;
			
			ЗаписьЖурналаРегистрации("Обмен данными с узлом: " + УзлыВыборка.Код, УровеньЖурналаРегистрации.Информация, ПланОбмена, "Окончание обмена");
			
		КонецЦикла;
		
	КонецЦикла;
	
КонецПроцедуры

Процедура ОчисткаЖурналаРегистрации() Экспорт
	
	КоличествоДнейХранения = Константы.bitmobile_СрокХраненияЖурналаРегистрации.Получить();
	
	Если Не КоличествоДнейХранения = 0 Тогда
		
		НачалоЭтогоДня = НачалоДня(ТекущаяДата());
		
		Фильтр = Новый Структура("ДатаОкончания", НачалоЭтогоДня - (86400 * КоличествоДнейХранения) - 1);
		
		ОчиститьЖурналРегистрации(Фильтр);
		
	КонецЕсли;
	
КонецПроцедуры
