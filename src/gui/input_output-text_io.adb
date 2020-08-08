pragma Ada_2012;
package body Input_Output.Text_IO is

   subtype Text_IO_Class is Text_IO_Type'Class;

   Current_In  : Text_IO_Access;
   Current_Out : Text_IO_Access;
   Current_Err : Text_IO_Access;

   ---------------
   -- Set_Input --
   ---------------

   procedure Set_Input (File : in Text_IO_Type) is
   begin
      Current_In := File.Handle.File;
   end Set_Input;

   ----------------
   -- Set_Output --
   ----------------

   procedure Set_Output (File : in Text_IO_Type) is
   begin
      Current_Out := File.Handle.File;
   end Set_Output;

   ---------------
   -- Set_Error --
   ---------------

   procedure Set_Error (File : in Text_IO_Type) is
   begin
      Current_Err := File.Handle.File;
   end Set_Error;

   -------------------
   -- Current_Input --
   -------------------

   function Current_Input return Text_IO_Access is
   begin
      return Current_In;
   end Current_Input;

--     function Current_Input return File_Access is
--     begin
--        return File_Access(Current_In);
--     end Current_Input;

   --------------------
   -- Current_Output --
   --------------------

   function Current_Output return Text_IO_Access is
   begin
      return Current_Out;
   end Current_Output;

--     function Current_Output return File_Access is
--     begin
--        return File_Access(Current_Out);
--     end Current_Output;

   -------------------
   -- Current_Error --
   -------------------

   function Current_Error return Text_IO_Access is
   begin
      return Current_Err;
   end Current_Error;

--     function Current_Error return File_Access is
--     begin
--        return File_Access(Current_Err);
--     end Current_Error;

   --------------
   -- New_Line --
   --------------

   procedure New_Line (File : in Text_IO_Type; Spacing : in Positive_Count := 1) is
   begin
      for Line in 1 .. Spacing loop
         NLC (Text_IO_Class (File));
      end loop;
   end New_Line;

   --------------
   -- New_Line --
   --------------

   procedure New_Line (Spacing : in Positive_Count := 1) is
   begin
      New_Line (Current_Out.all, Spacing);
   end New_Line;

   ---------------
   -- Skip_Line --
   ---------------

   procedure Skip_Line (File : in Text_IO_Type; Spacing : in Positive_Count := 1) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Skip_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Skip_Line";
   end Skip_Line;

   ---------------
   -- Skip_Line --
   ---------------

   procedure Skip_Line (Spacing : in Positive_Count := 1) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Skip_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Skip_Line";
   end Skip_Line;

   -----------------
   -- End_Of_Line --
   -----------------

   function End_Of_Line (File : in Text_IO_Type) return Boolean is
   begin
      pragma Compile_Time_Warning (Standard.True, "End_Of_Line unimplemented");
      return raise Program_Error with "Unimplemented function End_Of_Line";
   end End_Of_Line;

   -----------------
   -- End_Of_Line --
   -----------------

   function End_Of_Line return Boolean is
   begin
      pragma Compile_Time_Warning (Standard.True, "End_Of_Line unimplemented");
      return raise Program_Error with "Unimplemented function End_Of_Line";
   end End_Of_Line;

   ---------
   -- Get --
   ---------

   procedure Get (File : in Text_IO_Type; Item : out Character) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get unimplemented");
      raise Program_Error with "Unimplemented procedure Get";
   end Get;

   ---------
   -- Get --
   ---------

   procedure Get (Item : out Character) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get unimplemented");
      raise Program_Error with "Unimplemented procedure Get";
   end Get;

   ---------
   -- Put --
   ---------

   procedure Put (File : in Text_IO_Type; Item : in Character) is
   begin
      PutC (Text_IO_Class (File), Item);
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put (Item : in Character) is
   begin
      Put (Current_Out.all, Item);
   end Put;

   ----------------
   -- Look_Ahead --
   ----------------

   procedure Look_Ahead (File : in Text_IO_Type; Item : out Character; End_Of_Line : out Boolean) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Look_Ahead unimplemented");
      raise Program_Error with "Unimplemented procedure Look_Ahead";
   end Look_Ahead;

   ----------------
   -- Look_Ahead --
   ----------------

   procedure Look_Ahead (Item : out Character; End_Of_Line : out Boolean) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Look_Ahead unimplemented");
      raise Program_Error with "Unimplemented procedure Look_Ahead";
   end Look_Ahead;

   -------------------
   -- Get_Immediate --
   -------------------

   procedure Get_Immediate (File : in Text_IO_Type; Item : out Character) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get_Immediate unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Immediate";
   end Get_Immediate;

   -------------------
   -- Get_Immediate --
   -------------------

   procedure Get_Immediate (Item : out Character) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get_Immediate unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Immediate";
   end Get_Immediate;

   -------------------
   -- Get_Immediate --
   -------------------

   procedure Get_Immediate (File : in Text_IO_Type; Item : out Character; Available : out Boolean) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get_Immediate unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Immediate";
   end Get_Immediate;

   -------------------
   -- Get_Immediate --
   -------------------

   procedure Get_Immediate (Item : out Character; Available : out Boolean) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get_Immediate unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Immediate";
   end Get_Immediate;

   ---------
   -- Get --
   ---------

   procedure Get (File : in Text_IO_Type; Item : out String; Length : in Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get unimplemented");
      raise Program_Error with "Unimplemented procedure Get";
   end Get;

   ---------
   -- Get --
   ---------

   procedure Get (Item : out String; Length : in Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get unimplemented");
      raise Program_Error with "Unimplemented procedure Get";
   end Get;

   ---------
   -- Put --
   ---------

   procedure Put (File : in Text_IO_Type; Item : in String) is
   begin
      for C of Item loop
         Put (File, C);
      end loop;
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put (Item : in String) is
   begin
      Put (Current_Out.all, Item);
   end Put;

   --------------
   -- Get_Line --
   --------------

   procedure Get_Line (File : in Text_IO_Type; Item : out String; Last : out Natural) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Line";
   end Get_Line;

   --------------
   -- Get_Line --
   --------------

   procedure Get_Line (Item : out String; Last : out Natural) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Line";
   end Get_Line;

   --------------
   -- Get_Line --
   --------------

   function Get_Line (File : in Text_IO_Type) return String is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get_Line unimplemented");
      return raise Program_Error with "Unimplemented function Get_Line";
   end Get_Line;

   --------------
   -- Get_Line --
   --------------

   function Get_Line return String is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get_Line unimplemented");
      return raise Program_Error with "Unimplemented function Get_Line";
   end Get_Line;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (File : in Text_IO_Type; Item : in String) is
   begin
      Put (File, Item);
      New_Line (File);
   end Put_Line;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (Item : in String) is
   begin
      Put_Line (Current_Out.all, Item);
   end Put_Line;

end Input_Output.Text_IO;
