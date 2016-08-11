
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If IsNew() Then 
		
		AdditionalProperties.Delete("ЗагрузкаBitmobile");
		
	EndIf;
	
	// Очистить табличную часть параметров от незаполненных
	DeletedRowArray = New Array;
	
	For Each StrParameter In Parameters Do 
		
		If Not ValueIsFilled(StrParameter.Value) OR StrParameter.Value = "—" OR StrParameter.Value = "—??"Then
			
			RemoveProperty = True;
			
			DeletedRowArray.Add(StrParameter);
			
		EndIf;
		
	EndDo;
	
	For Each DeletedRow In DeletedRowArray Do 
		
		Parameters.Delete(DeletedRow);
		
	EndDo;
	
EndProcedure
