with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with SF_Text_IO;            use SF_Text_IO;

package SF_Unbounded_Text_IO is
   procedure Put (S : Unbounded_String);
   procedure Put_Line (S : Unbounded_String);
   procedure Put (F : File_Type; S : Unbounded_String);
   procedure Put_Line (F : File_Type; S : Unbounded_String);
end SF_Unbounded_Text_IO;
