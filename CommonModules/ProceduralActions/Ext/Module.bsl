&AtServer
Procedure UpdateFullTextSearchIndex() Export
	
	UpdateIndex(False);
	
EndProcedure

&AtServer
Procedure JoinFullTextSearchIndex() Export
	
	UpdateIndex(True);
	
EndProcedure

Procedure UpdateIndex(EnableJoining = False)
	
	FullTextSearch.UpdateIndex(EnableJoining);
	
EndProcedure

Procedure ExchangeDataUT11() Export
	
	DataExchanger = DataProcessors.bitmobile_DataExchanger.Create();
	DataExchanger.SendChanges();
	DataExchanger.GetChanges();
	
EndProcedure
