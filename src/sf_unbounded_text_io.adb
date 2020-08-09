package body SF_Unbounded_Text_IO is

   ---------
   -- Put --
   ---------

   procedure Put (S : Unbounded_String) is
   begin
      Put (To_String (S));
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (S : Unbounded_String) is
   begin
      Put_Line (To_String (S));
   end Put_Line;

   ---------
   -- Put --
   ---------

   procedure Put (F : File_Type; S : Unbounded_String) is
   begin
      Put (F, To_String (S));
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (F : File_Type; S : Unbounded_String) is
   begin
      Put_Line (F, To_String (S));
   end Put_Line;

end SF_Unbounded_Text_IO;
