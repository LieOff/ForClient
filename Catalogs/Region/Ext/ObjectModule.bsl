
Procedure OnWrite(Cancel)
	
	SetPrivilegedMode(True);
	
	// Удалить все записи связанные с этим регионом
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ManagersOfRegions.ParentRegion,
		|	ManagersOfRegions.Region,
		|	ManagersOfRegions.Manager
		|FROM
		|	InformationRegister.ManagersOfRegions AS ManagersOfRegions
		|WHERE
		|	(ManagersOfRegions.ParentRegion = &Ref
		|			OR ManagersOfRegions.Region = &Ref)";
	
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	ManagerForDeletion = InformationRegisters.ManagersOfRegions.CreateRecordManager();
	
	While Selection.Next() Do
		
		FillPropertyValues(ManagerForDeletion, Selection);
		
		ManagerForDeletion.Read();
		
		If ManagerForDeletion.Selected() Then 
			
			Try
				
				ManagerForDeletion.Delete();
				
			Except
			
			EndTry;
			
		EndIf;
		
	EndDo;
	
	// Записать дочерние регионы
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED DISTINCT
		|	Region.Ref AS Region
		|FROM
		|	Catalog.Region AS Region
		|WHERE
		|	Region.Ref IN HIERARCHY(&Ref)
		|
		|ORDER BY
		|	Region HIERARCHY";
	
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do 
		
		For Each ItemManager In Managers Do 
			
			RecordManager					= InformationRegisters.ManagersOfRegions.CreateRecordManager();
			RecordManager.ParentRegion		= Ref;
			RecordManager.Region			= Selection.Region;
			RecordManager.Manager			= ItemManager.Manager;
			
			RecordManager.Write();
			
		EndDo;
		
	EndDo;
	
	// Перезаписать родительский регион для запуска восстановления дерева регионов
	If ValueIsFilled(Parent) Then 
		
		ParentObject = Parent.GetObject();
		
		ParentObject.Write();
		
	EndIf;
	
EndProcedure




