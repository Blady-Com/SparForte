package body GX_Text_IO is

   ------------
   -- Create --
   ------------

   procedure Create
     (File : in out File_Type; Mode : File_Mode := Out_File;
      Name :        String := ""; Form : String := "")
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "Create unimplemented");
      raise Program_Error with "Unimplemented procedure Create";
   end Create;

   ----------
   -- Open --
   ----------

   procedure Open
     (File : in out File_Type; Mode : File_Mode; Name : String;
      Form :        String := "")
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "Open unimplemented");
      raise Program_Error with "Unimplemented procedure Open";
   end Open;

   -----------
   -- Close --
   -----------

   procedure Close (File : in out File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Close unimplemented");
      raise Program_Error with "Unimplemented procedure Close";
   end Close;

   ------------
   -- Delete --
   ------------

   procedure Delete (File : in out File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Delete unimplemented");
      raise Program_Error with "Unimplemented procedure Delete";
   end Delete;

   -----------
   -- Reset --
   -----------

   procedure Reset (File : in out File_Type; Mode : File_Mode) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Reset unimplemented");
      raise Program_Error with "Unimplemented procedure Reset";
   end Reset;

   -----------
   -- Reset --
   -----------

   procedure Reset (File : in out File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Reset unimplemented");
      raise Program_Error with "Unimplemented procedure Reset";
   end Reset;

   ----------
   -- Mode --
   ----------

   function Mode (File : File_Type) return File_Mode is
   begin
      pragma Compile_Time_Warning (Standard.True, "Mode unimplemented");
      return raise Program_Error with "Unimplemented function Mode";
   end Mode;

   ----------
   -- Name --
   ----------

   function Name (File : File_Type) return String is
   begin
      pragma Compile_Time_Warning (Standard.True, "Name unimplemented");
      return raise Program_Error with "Unimplemented function Name";
   end Name;

   ----------
   -- Form --
   ----------

   function Form (File : File_Type) return String is
   begin
      pragma Compile_Time_Warning (Standard.True, "Form unimplemented");
      return raise Program_Error with "Unimplemented function Form";
   end Form;

   -------------
   -- Is_Open --
   -------------

   function Is_Open (File : File_Type) return Boolean is
   begin
      pragma Compile_Time_Warning (Standard.True, "Is_Open unimplemented");
      return raise Program_Error with "Unimplemented function Is_Open";
   end Is_Open;

   ------------
   -- Create --
   ------------

   procedure Create
     (File    : in out File_Type;
      Console : in     Gnoga.Gui.Plugin.Ace_Editor.Console_IO
        .Pointer_To_Console_IO_Class;
      ID : in String := "")
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "Create unimplemented");
      raise Program_Error with "Unimplemented procedure Create";
   end Create;

   ---------------
   -- Set_Input --
   ---------------

   procedure Set_Input (File : File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Input unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Input";
   end Set_Input;

   ----------------
   -- Set_Output --
   ----------------

   procedure Set_Output (File : File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Output unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Output";
   end Set_Output;

   ---------------
   -- Set_Error --
   ---------------

   procedure Set_Error (File : File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Error unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Error";
   end Set_Error;

   --------------------
   -- Standard_Input --
   --------------------

   function Standard_Input return File_Type is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Standard_Input unimplemented");
      return raise Program_Error with "Unimplemented function Standard_Input";
   end Standard_Input;

   ---------------------
   -- Standard_Output --
   ---------------------

   function Standard_Output return File_Type is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Standard_Output unimplemented");
      return raise Program_Error with "Unimplemented function Standard_Output";
   end Standard_Output;

   --------------------
   -- Standard_Error --
   --------------------

   function Standard_Error return File_Type is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Standard_Error unimplemented");
      return raise Program_Error with "Unimplemented function Standard_Error";
   end Standard_Error;

   -------------------
   -- Current_Input --
   -------------------

   function Current_Input return File_Type is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Current_Input unimplemented");
      return raise Program_Error with "Unimplemented function Current_Input";
   end Current_Input;

   --------------------
   -- Current_Output --
   --------------------

   function Current_Output return File_Type is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Current_Output unimplemented");
      return raise Program_Error with "Unimplemented function Current_Output";
   end Current_Output;

   -------------------
   -- Current_Error --
   -------------------

   function Current_Error return File_Type is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Current_Error unimplemented");
      return raise Program_Error with "Unimplemented function Current_Error";
   end Current_Error;

   --------------------
   -- Standard_Input --
   --------------------

   function Standard_Input return File_Access is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Standard_Input unimplemented");
      return raise Program_Error with "Unimplemented function Standard_Input";
   end Standard_Input;

   ---------------------
   -- Standard_Output --
   ---------------------

   function Standard_Output return File_Access is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Standard_Output unimplemented");
      return raise Program_Error with "Unimplemented function Standard_Output";
   end Standard_Output;

   --------------------
   -- Standard_Error --
   --------------------

   function Standard_Error return File_Access is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Standard_Error unimplemented");
      return raise Program_Error with "Unimplemented function Standard_Error";
   end Standard_Error;

   -------------------
   -- Current_Input --
   -------------------

   function Current_Input return File_Access is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Current_Input unimplemented");
      return raise Program_Error with "Unimplemented function Current_Input";
   end Current_Input;

   --------------------
   -- Current_Output --
   --------------------

   function Current_Output return File_Access is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Current_Output unimplemented");
      return raise Program_Error with "Unimplemented function Current_Output";
   end Current_Output;

   -------------------
   -- Current_Error --
   -------------------

   function Current_Error return File_Access is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Current_Error unimplemented");
      return raise Program_Error with "Unimplemented function Current_Error";
   end Current_Error;

   -----------
   -- Flush --
   -----------

   procedure Flush (File : File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Flush unimplemented");
      raise Program_Error with "Unimplemented procedure Flush";
   end Flush;

   -----------
   -- Flush --
   -----------

   procedure Flush is
   begin
      pragma Compile_Time_Warning (Standard.True, "Flush unimplemented");
      raise Program_Error with "Unimplemented procedure Flush";
   end Flush;

   ---------------------
   -- Set_Line_Length --
   ---------------------

   procedure Set_Line_Length (File : File_Type; To : Count) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Set_Line_Length unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Line_Length";
   end Set_Line_Length;

   ---------------------
   -- Set_Line_Length --
   ---------------------

   procedure Set_Line_Length (To : Count) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Set_Line_Length unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Line_Length";
   end Set_Line_Length;

   ---------------------
   -- Set_Page_Length --
   ---------------------

   procedure Set_Page_Length (File : File_Type; To : Count) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Set_Page_Length unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Page_Length";
   end Set_Page_Length;

   ---------------------
   -- Set_Page_Length --
   ---------------------

   procedure Set_Page_Length (To : Count) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Set_Page_Length unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Page_Length";
   end Set_Page_Length;

   -----------------
   -- Line_Length --
   -----------------

   function Line_Length (File : File_Type) return Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Line_Length unimplemented");
      return raise Program_Error with "Unimplemented function Line_Length";
   end Line_Length;

   -----------------
   -- Line_Length --
   -----------------

   function Line_Length return Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Line_Length unimplemented");
      return raise Program_Error with "Unimplemented function Line_Length";
   end Line_Length;

   -----------------
   -- Page_Length --
   -----------------

   function Page_Length (File : File_Type) return Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Page_Length unimplemented");
      return raise Program_Error with "Unimplemented function Page_Length";
   end Page_Length;

   -----------------
   -- Page_Length --
   -----------------

   function Page_Length return Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Page_Length unimplemented");
      return raise Program_Error with "Unimplemented function Page_Length";
   end Page_Length;

   --------------
   -- New_Line --
   --------------

   procedure New_Line (File : File_Type; Spacing : Positive_Count := 1) is
   begin
      pragma Compile_Time_Warning (Standard.True, "New_Line unimplemented");
      raise Program_Error with "Unimplemented procedure New_Line";
   end New_Line;

   --------------
   -- New_Line --
   --------------

   procedure New_Line (Spacing : Positive_Count := 1) is
   begin
      pragma Compile_Time_Warning (Standard.True, "New_Line unimplemented");
      raise Program_Error with "Unimplemented procedure New_Line";
   end New_Line;

   ---------------
   -- Skip_Line --
   ---------------

   procedure Skip_Line (File : File_Type; Spacing : Positive_Count := 1) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Skip_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Skip_Line";
   end Skip_Line;

   ---------------
   -- Skip_Line --
   ---------------

   procedure Skip_Line (Spacing : Positive_Count := 1) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Skip_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Skip_Line";
   end Skip_Line;

   -----------------
   -- End_Of_Line --
   -----------------

   function End_Of_Line (File : File_Type) return Boolean is
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

   --------------
   -- New_Page --
   --------------

   procedure New_Page (File : File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "New_Page unimplemented");
      raise Program_Error with "Unimplemented procedure New_Page";
   end New_Page;

   --------------
   -- New_Page --
   --------------

   procedure New_Page is
   begin
      pragma Compile_Time_Warning (Standard.True, "New_Page unimplemented");
      raise Program_Error with "Unimplemented procedure New_Page";
   end New_Page;

   ---------------
   -- Skip_Page --
   ---------------

   procedure Skip_Page (File : File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Skip_Page unimplemented");
      raise Program_Error with "Unimplemented procedure Skip_Page";
   end Skip_Page;

   ---------------
   -- Skip_Page --
   ---------------

   procedure Skip_Page is
   begin
      pragma Compile_Time_Warning (Standard.True, "Skip_Page unimplemented");
      raise Program_Error with "Unimplemented procedure Skip_Page";
   end Skip_Page;

   -----------------
   -- End_Of_Page --
   -----------------

   function End_Of_Page (File : File_Type) return Boolean is
   begin
      pragma Compile_Time_Warning (Standard.True, "End_Of_Page unimplemented");
      return raise Program_Error with "Unimplemented function End_Of_Page";
   end End_Of_Page;

   -----------------
   -- End_Of_Page --
   -----------------

   function End_Of_Page return Boolean is
   begin
      pragma Compile_Time_Warning (Standard.True, "End_Of_Page unimplemented");
      return raise Program_Error with "Unimplemented function End_Of_Page";
   end End_Of_Page;

   -----------------
   -- End_Of_File --
   -----------------

   function End_Of_File (File : File_Type) return Boolean is
   begin
      pragma Compile_Time_Warning (Standard.True, "End_Of_File unimplemented");
      return raise Program_Error with "Unimplemented function End_Of_File";
   end End_Of_File;

   -----------------
   -- End_Of_File --
   -----------------

   function End_Of_File return Boolean is
   begin
      pragma Compile_Time_Warning (Standard.True, "End_Of_File unimplemented");
      return raise Program_Error with "Unimplemented function End_Of_File";
   end End_Of_File;

   -------------
   -- Set_Col --
   -------------

   procedure Set_Col (File : File_Type; To : Positive_Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Col unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Col";
   end Set_Col;

   -------------
   -- Set_Col --
   -------------

   procedure Set_Col (To : Positive_Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Col unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Col";
   end Set_Col;

   --------------
   -- Set_Line --
   --------------

   procedure Set_Line (File : File_Type; To : Positive_Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Line";
   end Set_Line;

   --------------
   -- Set_Line --
   --------------

   procedure Set_Line (To : Positive_Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Line";
   end Set_Line;

   ---------
   -- Col --
   ---------

   function Col (File : File_Type) return Positive_Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Col unimplemented");
      return raise Program_Error with "Unimplemented function Col";
   end Col;

   ---------
   -- Col --
   ---------

   function Col return Positive_Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Col unimplemented");
      return raise Program_Error with "Unimplemented function Col";
   end Col;

   ----------
   -- Line --
   ----------

   function Line (File : File_Type) return Positive_Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Line unimplemented");
      return raise Program_Error with "Unimplemented function Line";
   end Line;

   ----------
   -- Line --
   ----------

   function Line return Positive_Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Line unimplemented");
      return raise Program_Error with "Unimplemented function Line";
   end Line;

   ----------
   -- Page --
   ----------

   function Page (File : File_Type) return Positive_Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Page unimplemented");
      return raise Program_Error with "Unimplemented function Page";
   end Page;

   ----------
   -- Page --
   ----------

   function Page return Positive_Count is
   begin
      pragma Compile_Time_Warning (Standard.True, "Page unimplemented");
      return raise Program_Error with "Unimplemented function Page";
   end Page;

   ---------
   -- Get --
   ---------

   procedure Get (File : File_Type; Item : out Character) is
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

   procedure Put (File : File_Type; Item : Character) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put unimplemented");
      raise Program_Error with "Unimplemented procedure Put";
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put (Item : Character) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put unimplemented");
      raise Program_Error with "Unimplemented procedure Put";
   end Put;

   ----------------
   -- Look_Ahead --
   ----------------

   procedure Look_Ahead
     (File : File_Type; Item : out Character; End_Of_Line : out Boolean)
   is
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

   procedure Get_Immediate (File : File_Type; Item : out Character) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Get_Immediate unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Immediate";
   end Get_Immediate;

   -------------------
   -- Get_Immediate --
   -------------------

   procedure Get_Immediate (Item : out Character) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Get_Immediate unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Immediate";
   end Get_Immediate;

   -------------------
   -- Get_Immediate --
   -------------------

   procedure Get_Immediate
     (File : File_Type; Item : out Character; Available : out Boolean)
   is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Get_Immediate unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Immediate";
   end Get_Immediate;

   -------------------
   -- Get_Immediate --
   -------------------

   procedure Get_Immediate (Item : out Character; Available : out Boolean) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Get_Immediate unimplemented");
      raise Program_Error with "Unimplemented procedure Get_Immediate";
   end Get_Immediate;

   ---------
   -- Get --
   ---------

   procedure Get (File : File_Type; Item : out String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get unimplemented");
      raise Program_Error with "Unimplemented procedure Get";
   end Get;

   ---------
   -- Get --
   ---------

   procedure Get (Item : out String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Get unimplemented");
      raise Program_Error with "Unimplemented procedure Get";
   end Get;

   ---------
   -- Put --
   ---------

   procedure Put (File : File_Type; Item : String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put unimplemented");
      raise Program_Error with "Unimplemented procedure Put";
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put (Item : String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put unimplemented");
      raise Program_Error with "Unimplemented procedure Put";
   end Put;

   --------------
   -- Get_Line --
   --------------

   procedure Get_Line (File : File_Type; Item : out String; Last : out Natural)
   is
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

   function Get_Line (File : File_Type) return String is
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

   procedure Put_Line (File : File_Type; Item : String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Put_Line";
   end Put_Line;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (Item : String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Put_Line";
   end Put_Line;

end GX_Text_IO;
