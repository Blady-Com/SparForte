with SF_Text_IO; use SF_Text_IO;

package body user_io.getline is

   procedure getLine
     (line : out Unbounded_String; prompt : Unbounded_String := Null_Unbounded_String; keepHistory : Boolean := False)
   is
   begin
      Put (prompt);
      line := To_Unbounded_String (Get_Line);
   end getLine;

   function has_readline return Boolean is
   begin
      return False;
   end has_readline;

end user_io.getline;
