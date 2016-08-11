
#Region CommonProcedureAndFunctions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillFileTable();
	
	FillQuestionsTree(Enums.QuestionGroupTypes.RegularQuestions);
	
	FillSKUs();
	
	If Not SKUs.Count() = 0 Then 
		
		FillQuestionsTree(Enums.QuestionGroupTypes.SKUQuestions);
		
	EndIf;
	
	ThisForm.Title = NStr("en='Result for ""';ru='Результат для ""';cz='Vэsledek pro ""'") + String(Record.Questionnaire) + """";
	
EndProcedure

#Region Files

&AtServer
Procedure FillFileNameArray(FileNameArray, Table)

	For Each Element In Table Do 
		
		If ItsPicture(Element.Question) Then 
			
			Try
				
				SnapShotUUID = New UUID(Element.Answer);
				
			Except
				
				SnapShotUUID = Undefined;	
				
			EndTry;
				
			If Not SnapShotUUID = Undefined Then 
		
				FileNameArray.Add(SnapShotUUID);	
				
			EndIf;
			
		EndIf;	
		
	EndDo; 
		
EndProcedure

&AtServer
Procedure FillFileTable()
	
	ThumbnailSize = Constants.SizeOfThumbnailPhotos.Get();
	
	Connection = CommonProcessors.GetConnectionToServer();
	
	Path = CommonProcessors.GetWebDAVPathOnServer();
	
	FileNameArray = New Array; 
	
	FillFileNameArray(FileNameArray, Record.Visit.Questions);
	
	FillFileNameArray(FileNameArray, Record.Visit.SKUs);
		
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	bitmobile_ХранилищеФайлов.Объект,
		|	bitmobile_ХранилищеФайлов.НаправлениеСинхронизации,
		|	bitmobile_ХранилищеФайлов.Действие,
		|	bitmobile_ХранилищеФайлов.ИмяФайла,
		|	bitmobile_ХранилищеФайлов.ПолноеИмяФайла,
		|	bitmobile_ХранилищеФайлов.Расширение,
		|	bitmobile_ХранилищеФайлов.Хранилище
		|FROM
		|	InformationRegister.bitmobile_ХранилищеФайлов AS bitmobile_ХранилищеФайлов
		|WHERE
		|	bitmobile_ХранилищеФайлов.ИмяФайла IN(&FileNameArray)";
	
	Query.SetParameter("FileNameArray", FileNameArray);
	
	FileTableRegister = Query.Execute().Unload();
	
	For Each Str In FileTableRegister Do  
	
 		BinaryDataOfFile = Str.Хранилище.Get();
		
		If ValueIsFilled(BinaryDataOfFile) Then 
			
			Ins					= FileTable.Add();
			Ins.FileName		= Str.ИмяФайла;
			Ins.StorageAddress	= PutToTempStorage(BinaryDataOfFile, ThisForm.UUID);
			Ins.Extension		= Str.Расширение;
			
		Else 
			
			If Not Connection = Undefined Then 
			
				Try
					
					WebDAVFile = GetTempFileName(Str.Расширение);
					
					If ThumbnailSize > 0 Then 
						
						Connection.Get(Path + Lower(Str.ПолноеИмяФайла) + "?size=" + Format(ThumbnailSize, "NG=0"), WebDAVFile);
						
					Else 
						
						Connection.Get(Path + Lower(Str.ПолноеИмяФайла), WebDAVFile);
						
					EndIf;
					
					BinaryDataOfFile = New BinaryData(WebDAVFile);
					
					Ins					= FileTable.Add();
					Ins.FileName		= Str.ИмяФайла;
					Ins.StorageAddress	= PutToTempStorage(BinaryDataOfFile, ThisForm.UUID);
					Ins.Extension		= Str.Расширение;
					
				Except
				EndTry;
				
			EndIf;	
			
		EndIf;	
				
	EndDo;
				
EndProcedure

&AtServer
Procedure SetPicture(SnapShotUUID)
	
	FindStructure = New Structure("FileName");
	FindStructure.FileName = SnapShotUUID;
	
	FoundRows = FileTable.FindRows(FindStructure);
	
	If Not FoundRows.Count() = 0 Then 
		
		PictureAddress 		= FoundRows[0].StorageAddress;
		PictureExtension	= FoundRows[0].Extension;
				
	EndIf;
				
EndProcedure

&AtServer
Function ItsPicture(Question)
	
	If Question.AnswerType = Enums.DataType.Snapshot Then 
		
		Return True;
		
	Else 
		
		Return False;
		
	EndIf;
			
EndFunction

&AtServer
Function PictureExists(SnapShotUUID)
	
	FindStructure = New Structure("FileName");
	FindStructure.FileName = SnapShotUUID;
	
	FoundRows = FileTable.FindRows(FindStructure);
	
	If Not FoundRows.Count() = 0 Then 
		
		Return True;
		
	Else
		
		Return False;
				
	EndIf;

EndFunction

#EndRegion

#Region Questions

&AtServer
Procedure FillQuestionsTree(GroupType)
	
	If GroupType = Enums.QuestionGroupTypes.RegularQuestions Then 
			
		Tree = Questions;
			
	Else 
			
		Tree = SKUQuestions;
			
	EndIf;	
			
	If ValueIsFilled(Record.Questionnaire) Then 
	
		// Заполнить список вопросов
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	QuestionsInQuestionnairesSliceLast.Period,
			|	QuestionsInQuestionnairesSliceLast.Questionnaire,
			|	QuestionsInQuestionnairesSliceLast.ParentQuestion,
			|	QuestionsInQuestionnairesSliceLast.ChildQuestion,
			|	QuestionsInQuestionnairesSliceLast.QuestionType,
			|	QuestionsInQuestionnairesSliceLast.Obligatoriness,
			|	QuestionsInQuestionnairesSliceLast.Status,
			|	QuestionsInQuestionnairesSliceLast.Order
			|FROM
			|	InformationRegister.QuestionsInQuestionnaires.SliceLast AS QuestionsInQuestionnairesSliceLast
			|WHERE
			|	NOT QuestionsInQuestionnairesSliceLast.Status = VALUE(Enum.ValueTableRowStatuses.Deleted)
			|	AND QuestionsInQuestionnairesSliceLast.Questionnaire = &Questionnaire
			|	AND QuestionsInQuestionnairesSliceLast.QuestionType = &GroupType";

		Query.SetParameter("Questionnaire", Record.Questionnaire);
		Query.SetParameter("GroupType", GroupType);
			
		QuestionsTable = Query.Execute().Unload();

		ParentQuestionsTable = QuestionsTable.Copy(New Structure("ParentQuestion", Catalogs.Question.EmptyRef()));
		
		ParentQuestionsTable.Sort("Order Asc");
		
		For Each ParentQuestionRow In ParentQuestionsTable Do 
			
			ParentRow 					= Tree.GetItems().Add();
			ParentRow.Question       	= ParentQuestionRow.ChildQuestion;
			ParentRow.Obligatoriness    = ParentQuestionRow.Obligatoriness;
			ParentRow.AnswerType        = ParentQuestionRow.ChildQuestion.AnswerType;
			
			If GroupType = Enums.QuestionGroupTypes.RegularQuestions Then 
				
				FoundStructure = New Structure("Questionnaire, Question", Record.Questionnaire, ParentRow.Question);
				
				FoundedAnswers = Record.Visit.Questions.FindRows(FoundStructure);
				
				If Not FoundedAnswers.Count() = 0 Then 
				
					If ItsPicture(ParentRow.Question) Then
					
						Try
							
							SnapShotUUID = New UUID(FoundedAnswers[0].Answer);
							
							If PictureExists(SnapShotUUID) Then
							
				            	ParentRow.Answer 			= NStr("en='Snapshot';ru='Фотоснимок';cz='Foto'");
				            	ParentRow.SnapShotUUID 		= FoundedAnswers[0].Answer;
								
							Else
								
								ParentRow.Answer = NStr("en='Snapshot not found on server';ru='Фотоснимок не найден на сервере';cz='Foto nebylo nalezeno na serveru'");
													
							EndIf;
							
						Except
							
							ParentRow.Answer = NStr("en='Error getting snapshot';ru='Ошибка при получении фотоснимка';cz='Chyba během pořízení foto'");
							
						EndTry;
						
					Else 
	            
			            ParentRow.Answer = FoundedAnswers[0].Answer;
			            
					EndIf;
					
				EndIf;	
					
			EndIf;
			
			ChildQuestionsTable = QuestionsTable.Copy(New Structure("ParentQuestion", ParentQuestionRow.ChildQuestion));
			
			ChildQuestionsTable.Sort("Order Asc");
			
			For Each ChildQuestionRow In ChildQuestionsTable Do 
				
				ChildRow 				= ParentRow.GetItems().Add();
				ChildRow.Question       = ChildQuestionRow.ChildQuestion;
				ChildRow.Obligatoriness	= ChildQuestionRow.Obligatoriness;
				ChildRow.AnswerType     = ChildQuestionRow.ChildQuestion.AnswerType;
				
				If GroupType = Enums.QuestionGroupTypes.RegularQuestions Then 
					
					FoundStructure = New Structure("Questionnaire, Question", Record.Questionnaire, ChildRow.Question);
					
					FoundedAnswers = Record.Visit.Questions.FindRows(FoundStructure);
					
					If Not FoundedAnswers.Count() = 0 Then 
					
						If ItsPicture(ChildRow.Question) Then
						
							Try
								
								SnapShotUUID = New UUID(FoundedAnswers[0].Answer);
								
								If PictureExists(SnapShotUUID) Then
								
					            	ChildRow.Answer 			= NStr("en='Snapshot';ru='Фотоснимок';cz='Foto'");
					            	ChildRow.SnapShotUUID 		= FoundedAnswers[0].Answer;
									
								Else
									
									ChildRow.Answer = NStr("en='Snapshot not found on server';ru='Фотоснимок не найден на сервере';cz='Foto nebylo nalezeno na serveru'");
														
								EndIf;
								
							Except
								
								ChildRow.Answer = NStr("en='Error getting snapshot';ru='Ошибка при получении фотоснимка';cz='Chyba během pořízení foto'");
								
							EndTry;
							
						Else 
		            
				            ChildRow.Answer = FoundedAnswers[0].Answer;
				            
						EndIf;
						
					EndIf;	
						
				EndIf;
				
			EndDo;
						
		EndDo;
				
	EndIf;
		
EndProcedure

&AtServer
Procedure LoadSKUAnswers(SKU)
	
	For Each ParentQuestionElement In SKUQuestions.GetItems() Do 
		
		ParentQuestionElement.Answer 			= "";
		ParentQuestionElement.SKUSnapShotUUID 	= "";
		
		FoundedAnswers = Record.Visit.SKUs.FindRows(New Structure("Questionnaire, Question, SKU", Record.Questionnaire, ParentQuestionElement.Question, SKU));       
		
		If Not FoundedAnswers.Count() = 0 Then 
		
			If ItsPicture(ParentQuestionElement.Question) Then
			
				Try
					
					SnapShotUUID = New UUID(FoundedAnswers[0].Answer);
					
					If PictureExists(SnapShotUUID) Then
						
						ParentQuestionElement.Answer 			= NStr("en='Snapshot';ru='Фотоснимок';cz='Foto'");
						ParentQuestionElement.SKUSnapShotUUID 	= FoundedAnswers[0].Answer;
						
					Else
						
						ParentQuestionElement.Answer = NStr("en='Snapshot not found on server';ru='Фотоснимок не найден на сервере';cz='Foto nebylo nalezeno na serveru'");
						
					EndIf;
					
				Except
					
					ParentQuestionElement.Answer = NStr("en='Error getting snapshot';ru='Ошибка при получении фотоснимка';cz='Chyba během pořízení foto'");
					
				EndTry;
				
			Else 
				
				ParentQuestionElement.Answer = FoundedAnswers[0].Answer;
				
			EndIf;
			
		EndIf;
		
		ChildQuestionsTable = ParentQuestionElement.GetItems();
		
		For Each ChildQuestionElement In ChildQuestionsTable Do 
			
			ChildQuestionElement.Answer 			= "";
			ChildQuestionElement.SKUSnapShotUUID 	= "";
		
			FoundedAnswers = Record.Visit.SKUs.FindRows(New Structure("Questionnaire, Question, SKU", Record.Questionnaire, ChildQuestionElement.Question, SKU));       
		
			If Not FoundedAnswers.Count() = 0 Then 
			
				If ItsPicture(ChildQuestionElement.Question) Then
				
					Try
						
						SnapShotUUID = New UUID(FoundedAnswers[0].Answer);
						
						If PictureExists(SnapShotUUID) Then
						
			            	ChildQuestionElement.Answer 			= NStr("en='Snapshot';ru='Фотоснимок';cz='Foto'");
			            	ChildQuestionElement.SKUSnapShotUUID 	= FoundedAnswers[0].Answer;
							
						Else
							
							ChildQuestionElement.Answer = NStr("en='Snapshot not found on server';ru='Фотоснимок не найден на сервере';cz='Foto nebylo nalezeno na serveru'");
												
						EndIf;
						
					Except
						
						ChildQuestionElement.Answer = NStr("en='Error getting snapshot';ru='Ошибка при получении фотоснимка';cz='Chyba během pořízení foto'");
						
					EndTry;
					
				Else 
            
		            ChildQuestionElement.Answer = FoundedAnswers[0].Answer;
		            
				EndIf;
				
			EndIf;
			
		EndDo;
					
	EndDo; 
		
EndProcedure

#EndRegion

#Region SKUs

&AtServer
Procedure FillSKUs()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SKUsInQuestionnairesSliceLast.SKU
		|FROM
		|	InformationRegister.SKUsInQuestionnaires.SliceLast(, Questionnaire = &Questionnaire) AS SKUsInQuestionnairesSliceLast
		|WHERE
		|	SKUsInQuestionnairesSliceLast.Status = VALUE(Enum.ValueTableRowStatuses.Added)
		|	AND SKUsInQuestionnairesSliceLast.SKU IN(&SKUArray)
		|
		|GROUP BY
		|	SKUsInQuestionnairesSliceLast.SKU";
	
	Query.SetParameter("Questionnaire", Record.Questionnaire);
	Query.SetParameter("SKUArray", Record.Visit.SKUs.UnloadColumn("SKU"));
	
	SKUs.Load(Query.Execute().Unload());
	
EndProcedure	

#EndRegion

#EndRegion

#Region UserInterface

&AtClient
Procedure OpenPicture(Command)
	
	If Items.GroupPages.CurrentPage = Items.GroupQuestions Then 
		
		If Not Items.Questions.CurrentData = Undefined Then
			
			If ValueIsFilled(Items.Questions.CurrentData.SnapShotUUID) Then 
				
				SnapshotStructure = CommonProcessors.GetSnapshot(Items.Questions.CurrentData.SnapShotUUID, ThisForm.UUID, String(Record.Outlet));
				
				If Not SnapshotStructure = Undefined Then 
				 
					GetFile(SnapshotStructure.SnapshotAddress, SnapshotStructure.SnapshotName, True);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	ElsIf Items.GroupPages.CurrentPage = Items.GroupSKUQuestions Then
		
		If Not Items.SKUQuestions.CurrentData = Undefined Then
			
			If ValueIsFilled(Items.SKUQuestions.CurrentData.SKUSnapShotUUID) Then 
		
				SnapshotStructure = CommonProcessors.GetSnapshot(Items.SKUQuestions.CurrentData.SKUSnapShotUUID, ThisForm.UUID, String(Record.Outlet));
				
				If Not SnapshotStructure = Undefined Then 
				 
					GetFile(SnapshotStructure.SnapshotAddress, SnapshotStructure.SnapshotName, True);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionsOnActivateRow(Item)
	
	If Items.GroupPages.CurrentPage = Items.GroupQuestions Then
	
		If Not Item.CurrentRow = Undefined Then	
		
			If ItsPicture(Item.CurrentData.Question) Then 
				
				Try
					
					SnapShotUUID = New UUID(Item.CurrentData.SnapShotUUID);
					
					SetPicture(SnapShotUUID);
					
				Except
					
					PictureAddress		= Undefined;
					PictureExtension    = Undefined;
					
				EndTry;	
				
			Else 
				
				PictureAddress		= Undefined;
				PictureExtension    = Undefined;
			
			EndIf;
			
		Else
			
			PictureAddress		= Undefined;
			PictureExtension    = Undefined;

		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SKUsOnActivateRow(Item)
	
	If Not Item.CurrentRow = Undefined Then
	
		LoadSKUAnswers(Item.CurrentData.SKU);	
		
	EndIf;	
		
EndProcedure

&AtClient
Procedure SKUQuestionsOnActivateRow(Item)
	
	If Items.GroupPages.CurrentPage = Items.GroupSKUQuestions Then
	
	    If Not Item.CurrentRow = Undefined  Then	        
			
			If ItsPicture(Item.CurrentData.Question) Then            
				
				Try
					
					SnapShotUUID = New UUID(Item.CurrentData.SKUSnapShotUUID);
					
					SetPicture(SnapShotUUID);
					
				Except
					
					PictureAddress		= Undefined;
					PictureExtension    = Undefined;
					
				EndTry;
				
			Else            
				
				PictureAddress		= Undefined;
	            PictureExtension    = Undefined;                       
				
			EndIf;                
			
		Else        
			
			PictureAddress		= Undefined;
	        PictureExtension    = Undefined;        
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.GroupQuestions Then
		
		SKUsOnActivateRow(Items.SKUs);
		QuestionsOnActivateRow(Items.Questions);
        
    ElsIf CurrentPage = Items.GroupSKUQuestions Then
        
        SKUQuestionsOnActivateRow(Items.SKUQuestions);
		
	Else 
		
		PictureAddress = Undefined;
		PictureExtension = Undefined;
        
	EndIf;
	
EndProcedure

#EndRegion








