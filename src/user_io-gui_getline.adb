with world;
with SparGUI.View;
with Ada.Strings.Unbounded;

package body user_io.getline is

   procedure getLine( line : out unbounded_string; prompt : unbounded_string := null_unbounded_string; keepHistory : boolean := false ) is
      use type SparGUI.View.Default_View_Access;
   begin
      if world.GUI_View /= null then
         world.GUI_View.Console.Put (Ada.Strings.Unbounded.To_String (prompt));
         line := Ada.Strings.Unbounded.To_Unbounded_String (world.GUI_View.Console.Get_Line);
      else
         put_bold ("Error: GUI not actovated.");
      end if;
end;

function has_readline return boolean is
begin
  return false;
end has_readline;

end user_io.getline;
