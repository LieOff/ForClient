
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("Role") Then 
		
		If ValueIsFilled(Parameters.Role) Then 
			
			StandardProcessing = False;
			
			EnabledRoles = New Array;
			
			If Parameters.Role = "SRM" Then 
				
				EnabledRoles.Add("SRM");
				EnabledRoles.Add("SRM_SR");
				
			Else 
				
				EnabledRoles.Add("SR");
				EnabledRoles.Add("SRM_SR");
				
			EndIf;
			
			Query = New Query;
			Query.Text = 
				"SELECT ALLOWED
				|	User.Ref AS User,
				|	User.Code AS Code,
				|	User.Description AS Description,
				|	User.Description,
				|	User.RoleOfUser.Role AS Role
				|FROM
				|	Catalog.User AS User
				|WHERE
				|	User.RoleOfUser.Role IN(&EnabledRoles)
				|	" + ?(Parameters.SearchString = Undefined, "", "AND (User.Description LIKE &Search OR User.Code LIKE &Search)");
			
			Query.SetParameter("EnabledRoles", EnabledRoles);
			
			If Not Parameters.SearchString = Undefined Then 
				
				Query.SetParameter("Search", "%" + Parameters.SearchString + "%");
				
			EndIf;
			
			QueryResult = Query.Execute();
			
			Selection = QueryResult.Select();
			
			ChoiceData = New ValueList;
			
			While Selection.Next() Do
				
				ChoiceData.Add(Selection.User, Selection.Description + " (" + Selection.Code + ")");
				
			EndDo;
		
			
		EndIf;
		
	EndIf;
	
EndProcedure
