
Procedure BeforeWrite(Cancel)
	
	ThisObject.AdditionalProperties.Insert("OldStatus", ThisObject.Ref.OutletStatus);
	
	RemoveProperty = False;
	
	If IsNew() Then 
		
		RemoveProperty = True;
		
	EndIf;
	
	// Очистить табличную часть параметров от незаполненных
	DeletedRowArray = New Array;
	
	For Each StrParameter In Parameters Do 
		
		If Not ValueIsFilled(StrParameter.Value) OR StrParameter.Value = "—" OR StrParameter.Value = "—??"  Then
			
			RemoveProperty = True;
			
			DeletedRowArray.Add(StrParameter);
			
		EndIf;
		
	EndDo;
	
	For Each DeletedRow In DeletedRowArray Do 
		
		Parameters.Delete(DeletedRow);
		
	EndDo;
	
	// Очистить табличную часть изображений от незаполненных
	DeletedRowArray = New Array;
	
	For Each StrSnapshot In Snapshots Do 
		
		If StrSnapshot.Deleted Then
			
			RemoveProperty = True;
			
			DeletedRowArray.Add(StrSnapshot);
			
		EndIf;
		
	EndDo;
	
	For Each DeletedRow In DeletedRowArray Do 
		
		Snapshots.Delete(DeletedRow);
		
	EndDo;
	
	If RemoveProperty Then 
		
		AdditionalProperties.Delete("ЗагрузкаBitmobile");
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	OldStatus = ThisObject.AdditionalProperties.OldStatus;
	NewStatus = ThisObject.OutletStatus;
	
	StatusChanged = Not OldStatus = NewStatus;
	
	If StatusChanged Then
		
		Record = InformationRegisters.OutletStatusHistory.CreateRecordManager();
		Record.Outlet = ThisObject.Ref;
		Record.Status = ThisObject.OutletStatus;
		Record.Period = CurrentDate();
		Record.Write();
		
	EndIf;
	
EndProcedure

