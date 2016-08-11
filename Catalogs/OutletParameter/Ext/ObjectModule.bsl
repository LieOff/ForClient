
Procedure OnWrite(Cancel)
    If ThisObject.DataType=Enums.DataType.ValueList AND ThisObject.ValueList.Count()=0 Then
        Message("en = 'Tabular section couldn''t be empty!'; ru = 'Табличная часть не может быть пустой!'");
        Cancel=True;   
    EndIf; 
EndProcedure
