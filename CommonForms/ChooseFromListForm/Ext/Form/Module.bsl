
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)	
	List = Parameters.List;
	Source = Parameters.Source;
EndProcedure

&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)
	Notify(Source, List.get(SelectedRow));
	Close();
EndProcedure
