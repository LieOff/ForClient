

Procedure BeforeWrite(Cancel)
	
	For Each Period In ThisObject.Periods Do
		
		If Period.UUID = New UUID("00000000-0000-0000-0000-000000000000") Then
			
			Period.UUID = New UUID();
			
		EndIf;
		
	EndDo;
	
	DeletedPeriods = New Array;
	
	For Each RefPeriod In ThisObject.Ref.Periods Do
		
		NewPeriod = ThisObject.Periods.Find(RefPeriod.UUID);
		
		If NewPeriod = Undefined Then
			
			DeletedPeriods.Add(RefPeriod);
			
		EndIf;
		
	EndDo;
	
	ThisObject.AdditionalProperties.Insert("DeletedPeriods", DeletedPeriods);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	For Each DeletedPeriod In ThisObject.AdditionalProperties.DeletedPeriods Do
		
		RecordSet = InformationRegisters.AssortmentMatrixOutlets.CreateRecordSet();
		ClearRecordSet(DeletedPeriod, RecordSet);
		
		RecordSet = InformationRegisters.AssortmentMatrixSKUs.CreateRecordSet();
		ClearRecordSet(DeletedPeriod, RecordSet);
		
	EndDo;
	
	If ThisObject.AdditionalProperties.Property("NewOutletsRows") Then
	
		For Each NewRow In ThisObject.AdditionalProperties.NewOutletsRows Do
			
			RecordManager = InformationRegisters.AssortmentMatrixOutlets.CreateRecordManager();
			FillPropertyValues(RecordManager, NewRow, , "UUID");
			RecordManager.AssortmentMatrix = ThisObject.Ref;
			RecordManager.UUID = New UUID(NewRow.UUID);
			RecordManager.Write();
			
		EndDo;
		
	EndIf;
	
	If ThisObject.AdditionalProperties.Property("NewSKUsRows") Then
		
		For Each NewRow In ThisObject.AdditionalProperties.NewSKUsRows Do
			
			RecordManager = InformationRegisters.AssortmentMatrixSKUs.CreateRecordManager();
			FillPropertyValues(RecordManager, NewRow, , "UUID");
			RecordManager.AssortmentMatrix = ThisObject.Ref;
			RecordManager.UUID = New UUID(NewRow.UUID);
			RecordManager.Write();
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ClearRecordSet(DeletedPeriod, RecordSet)
	
	UUIDFilter = RecordSet.Filter.Find("UUID");
	UUIDFilter.Use = True;
	UUIDFilter.Value = DeletedPeriod.UUID;
	
	RecordSet.Read();
	
	RecordSet.Clear();
	
	RecordSet.Write();
	
EndProcedure


