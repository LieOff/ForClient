
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	TextField = Parameters.Text;
	Source = Parameters.Source;
EndProcedure

&AtClient
Procedure ОK(Command)
	Notify(Source, "Ok");
	Close();
EndProcedure

&AtClient
Procedure Cancel(Command)
	Notify(Source, "Cancel");
	Close();
EndProcedure


