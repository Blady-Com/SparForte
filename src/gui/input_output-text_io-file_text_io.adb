pragma Ada_2012;
package body Input_Output.Text_IO.File_Text_IO is

   toto : Text_IO_File_Access;
   Std_In : aliased File_Type := (Input_Output.Text_IO.Text_IO_Type with Text_IO_File => toto);
   Std_Out : aliased File_Type := (Input_Output.Text_IO.Text_IO_Type with Text_IO_File => toto);
   Std_Err : aliased File_Type := (Input_Output.Text_IO.Text_IO_Type with Text_IO_File => toto);

   ------------
   -- Create --
   ------------

   procedure Create
     (File : in out File_Type; Mode : File_Mode := Out_File;
      Name :        String := ""; Form : String := "")
   is
   begin
      if File.Text_IO_File /= null then
         raise Status_Error with "file already open";
      else
         File.Text_IO_File := new ada.Text_IO.File_Type;
      end if;
      ada.Text_IO.Create (File.Text_IO_File.all, mode, Name, Form);
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

   procedure Reset (File : in out File_Type; Mode : in File_Mode) is
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

   function Mode (File : in File_Type) return File_Mode is
   begin
      pragma Compile_Time_Warning (Standard.True, "Mode unimplemented");
      return raise Program_Error with "Unimplemented function Mode";
   end Mode;

   ----------
   -- Name --
   ----------

   function Name (File : in File_Type) return String is
   begin
      pragma Compile_Time_Warning (Standard.True, "Name unimplemented");
      return raise Program_Error with "Unimplemented function Name";
   end Name;

   ----------
   -- Form --
   ----------

   function Form (File : in File_Type) return String is
   begin
      pragma Compile_Time_Warning (Standard.True, "Form unimplemented");
      return raise Program_Error with "Unimplemented function Form";
   end Form;

   -------------
   -- Is_Open --
   -------------

   function Is_Open (File : in File_Type) return Boolean is
   begin
      pragma Compile_Time_Warning (Standard.True, "Is_Open unimplemented");
      return raise Program_Error with "Unimplemented function Is_Open";
   end Is_Open;

   --------------------
   -- Standard_Input --
   --------------------

   function Standard_Input return File_Type is
   begin
      return (Input_Output.Text_IO.Text_IO_Type with Text_IO_File => toto);
   end Standard_Input;

   ---------------------
   -- Standard_Output --
   ---------------------

   function Standard_Output return File_Type is
   begin
      return (Input_Output.Text_IO.Text_IO_Type with Text_IO_File => toto);
   end Standard_Output;

   --------------------
   -- Standard_Error --
   --------------------

   function Standard_Error return File_Type is
   begin
      return (Input_Output.Text_IO.Text_IO_Type with Text_IO_File => toto);
   end Standard_Error;

   -------------------
   -- Current_Input --
   -------------------

   function Current_Input return File_Type is
   begin
      return (Input_Output.Text_IO.Text_IO_Type with Text_IO_File => File_Type(Input_Output.Text_IO.Current_Input.all).Text_IO_File);
   end Current_Input;

   --------------------
   -- Current_Output --
   --------------------

   function Current_Output return File_Type is
   begin
      return (Input_Output.Text_IO.Text_IO_Type with Text_IO_File => File_Type(Input_Output.Text_IO.Current_Output.all).Text_IO_File);
   end Current_Output;

   -------------------
   -- Current_Error --
   -------------------

   function Current_Error return File_Type is
   begin
      return (Input_Output.Text_IO.Text_IO_Type with Text_IO_File => File_Type(Input_Output.Text_IO.Current_Error.all).Text_IO_File);
   end Current_Error;

   --------------------
   -- Standard_Input --
   --------------------

   function Standard_Input return File_Access is
   begin
      return Std_In'Access;
   end Standard_Input;

   ---------------------
   -- Standard_Output --
   ---------------------

   function Standard_Output return File_Access is
   begin
      return Std_Out'Access;
   end Standard_Output;

   --------------------
   -- Standard_Error --
   --------------------

   function Standard_Error return File_Access is
   begin
      return Std_Err'Access;
   end Standard_Error;

   -------------------
   -- Current_Input --
   -------------------

   function Current_Input return File_Access is
   begin
      return File_Access (Input_Output.Text_IO.Current_Input);
   end Current_Input;

   --------------------
   -- Current_Output --
   --------------------

   function Current_Output return File_Access is
   begin
      return File_Access (Input_Output.Text_IO.Current_Output);
   end Current_Output;

   -------------------
   -- Current_Error --
   -------------------

   function Current_Error return File_Access is
   begin
      return File_Access (Input_Output.Text_IO.Current_Error);
   end Current_Error;

   -----------
   -- Flush --
   -----------

   procedure Flush (File : in File_Type) is
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

   procedure Set_Line_Length (File : in File_Type; To : in Count) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Set_Line_Length unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Line_Length";
   end Set_Line_Length;

   ---------------------
   -- Set_Line_Length --
   ---------------------

   procedure Set_Line_Length (To : in Count) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Set_Line_Length unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Line_Length";
   end Set_Line_Length;

   ---------------------
   -- Set_Page_Length --
   ---------------------

   procedure Set_Page_Length (File : in File_Type; To : in Count) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Set_Page_Length unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Page_Length";
   end Set_Page_Length;

   ---------------------
   -- Set_Page_Length --
   ---------------------

   procedure Set_Page_Length (To : in Count) is
   begin
      pragma Compile_Time_Warning
        (Standard.True, "Set_Page_Length unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Page_Length";
   end Set_Page_Length;

   -----------------
   -- Line_Length --
   -----------------

   function Line_Length (File : in File_Type) return Count is
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

   function Page_Length (File : in File_Type) return Count is
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

   ---------------
   -- Skip_Line --
   ---------------

   procedure Skip_Line (Spacing : in Positive_Count := 1) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Skip_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Skip_Line";
   end Skip_Line;

   --------------
   -- New_Page --
   --------------

   procedure New_Page (File : in File_Type) is
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

   procedure Skip_Page (File : in File_Type) is
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

   function End_Of_Page (File : in File_Type) return Boolean is
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

   function End_Of_File (File : in File_Type) return Boolean is
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

   procedure Set_Col (File : in File_Type; To : in Positive_Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Col unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Col";
   end Set_Col;

   -------------
   -- Set_Col --
   -------------

   procedure Set_Col (To : in Positive_Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Col unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Col";
   end Set_Col;

   --------------
   -- Set_Line --
   --------------

   procedure Set_Line (File : in File_Type; To : in Positive_Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Line";
   end Set_Line;

   --------------
   -- Set_Line --
   --------------

   procedure Set_Line (To : in Positive_Count) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Set_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Set_Line";
   end Set_Line;

   ---------
   -- Col --
   ---------

   function Col (File : in File_Type) return Positive_Count is
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

   function Line (File : in File_Type) return Positive_Count is
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

   function Page (File : in File_Type) return Positive_Count is
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
   -- Put --
   ---------

   procedure Put (S : Unbounded_String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put unimplemented");
      raise Program_Error with "Unimplemented procedure Put";
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (S : Unbounded_String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Put_Line";
   end Put_Line;

   ---------
   -- Put --
   ---------

   procedure Put (F : File_Type; S : Unbounded_String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put unimplemented");
      raise Program_Error with "Unimplemented procedure Put";
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (F : File_Type; S : Unbounded_String) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Put_Line unimplemented");
      raise Program_Error with "Unimplemented procedure Put_Line";
   end Put_Line;

   -----------
   -- Write --
   -----------

   overriding procedure Write (IO : in File_Type; Item : IO_Element_Array) is
   begin
      pragma Compile_Time_Warning (Standard.True, "Write unimplemented");
      raise Program_Error with "Unimplemented procedure Write";
   end Write;

   ----------
   -- Read --
   ----------

   overriding procedure Read
     (IO   : in     File_Type; Item : out IO_Element_Array;
      Last :    out IO_Element_Offset)
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "Read unimplemented");
      raise Program_Error with "Unimplemented procedure Read";
   end Read;

   ----------
   -- GetC --
   ----------

   overriding procedure GetC
     (IO : in File_Type; Ch : out Character; Available : out Boolean)
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "GetC unimplemented");
      raise Program_Error with "Unimplemented procedure GetC";
   end GetC;

   ----------
   -- PutC --
   ----------

   overriding procedure PutC (IO : in File_Type; Item : Character) is
   begin
      Ada.Text_IO.Put (IO.Text_IO_File.all, Item);
   end PutC;

   -----------
   -- LookC --
   -----------

   overriding procedure LookC
     (IO : in File_Type; Ch : out Character; Available : out Boolean)
   is
   begin
      pragma Compile_Time_Warning (Standard.True, "LookC unimplemented");
      raise Program_Error with "Unimplemented procedure LookC";
   end LookC;

   ---------
   -- NLC --
   ---------

   procedure NLC (IO : in File_Type) is
   begin
      pragma Compile_Time_Warning (Standard.True, "NLC unimplemented");
      raise Program_Error with "Unimplemented procedure NLC";
   end NLC;

end Input_Output.Text_IO.File_Text_IO;
