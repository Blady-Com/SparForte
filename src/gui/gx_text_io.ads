with Ada.Text_IO;
with Gnoga.Gui.Plugin.Ace_Editor.Console_IO;

package GX_Text_IO is

   type File_Type is limited private;

   subtype File_Mode is Ada.Text_IO.File_Mode;
   use all type Ada.Text_IO.File_Mode;

   subtype Count is Ada.Text_IO.Count;
   subtype Positive_Count is Ada.Text_IO.Positive_Count;
   Unbounded : Ada.Text_IO.Count renames Ada.Text_IO.Unbounded;

   subtype Field is Ada.Text_IO.Field;
   subtype Number_Base is Ada.Text_IO.Number_Base;
   subtype Type_Set is Ada.Text_IO.Type_Set;

   ---------------------
   -- File Management --
   ---------------------

   procedure Create (File : in out File_Type; Mode : File_Mode := Out_File; Name : String := ""; Form : String := "");

   procedure Open (File : in out File_Type; Mode : File_Mode; Name : String; Form : String := "");

   procedure Close (File : in out File_Type);
   procedure Delete (File : in out File_Type);
   procedure Reset (File : in out File_Type; Mode : File_Mode);
   procedure Reset (File : in out File_Type);

   function Mode (File : File_Type) return File_Mode;
   function Name (File : File_Type) return String;
   function Form (File : File_Type) return String;

   function Is_Open (File : File_Type) return Boolean;

   ---------------------
   -- GUI Management --
   ---------------------

   procedure Create
     (File : in out File_Type; Console : in Gnoga.Gui.Plugin.Ace_Editor.Console_IO.Pointer_To_Console_IO_Class);

   ------------------------------------------------------
   -- Control of default input, output and error files --
   ------------------------------------------------------

   procedure Set_Input (File : File_Type);
   procedure Set_Output (File : File_Type);
   procedure Set_Error (File : File_Type);

   function Standard_Input return File_Type;
   function Standard_Output return File_Type;
   function Standard_Error return File_Type;

   function Current_Input return File_Type;
   function Current_Output return File_Type;
   function Current_Error return File_Type;

   type File_Access is access constant File_Type;

   function Standard_Input return File_Access;
   function Standard_Output return File_Access;
   function Standard_Error return File_Access;

   function Current_Input return File_Access;
   function Current_Output return File_Access;
   function Current_Error return File_Access;

   --------------------
   -- Buffer control --
   --------------------

   procedure Flush (File : File_Type);
   procedure Flush;

   --------------------------------------------
   -- Specification of line and page lengths --
   --------------------------------------------

   procedure Set_Line_Length (File : File_Type; To : Count);
   procedure Set_Line_Length (To : Count);

   procedure Set_Page_Length (File : File_Type; To : Count);
   procedure Set_Page_Length (To : Count);

   function Line_Length (File : File_Type) return Count;
   function Line_Length return Count;

   function Page_Length (File : File_Type) return Count;
   function Page_Length return Count;

   ------------------------------------
   -- Column, Line, and Page Control --
   ------------------------------------

   procedure New_Line (File : File_Type; Spacing : Positive_Count := 1);
   procedure New_Line (Spacing : Positive_Count := 1);

   procedure Skip_Line (File : File_Type; Spacing : Positive_Count := 1);
   procedure Skip_Line (Spacing : Positive_Count := 1);

   function End_Of_Line (File : File_Type) return Boolean;
   function End_Of_Line return Boolean;

   procedure New_Page (File : File_Type);
   procedure New_Page;

   procedure Skip_Page (File : File_Type);
   procedure Skip_Page;

   function End_Of_Page (File : File_Type) return Boolean;
   function End_Of_Page return Boolean;

   function End_Of_File (File : File_Type) return Boolean;
   function End_Of_File return Boolean;

   procedure Set_Col (File : File_Type; To : Positive_Count);
   procedure Set_Col (To : Positive_Count);

   procedure Set_Line (File : File_Type; To : Positive_Count);
   procedure Set_Line (To : Positive_Count);

   function Col (File : File_Type) return Positive_Count;
   function Col return Positive_Count;

   function Line (File : File_Type) return Positive_Count;
   function Line return Positive_Count;

   function Page (File : File_Type) return Positive_Count;
   function Page return Positive_Count;

   ----------------------------
   -- Character Input-Output --
   ----------------------------

   procedure Get (File : File_Type; Item : out Character);
   procedure Get (Item : out Character);

   procedure Put (File : File_Type; Item : Character);
   procedure Put (Item : Character);

   procedure Look_Ahead (File : File_Type; Item : out Character; End_Of_Line : out Boolean);
   procedure Look_Ahead (Item : out Character; End_Of_Line : out Boolean);

   procedure Get_Immediate (File : File_Type; Item : out Character);
   procedure Get_Immediate (Item : out Character);

   procedure Get_Immediate (File : File_Type; Item : out Character; Available : out Boolean);
   procedure Get_Immediate (Item : out Character; Available : out Boolean);

   -------------------------
   -- String Input-Output --
   -------------------------

   procedure Get (File : File_Type; Item : out String);
   procedure Get (Item : out String);

   procedure Put (File : File_Type; Item : String);
   procedure Put (Item : String);

   procedure Get_Line (File : File_Type; Item : out String; Last : out Natural);
   procedure Get_Line (Item : out String; Last : out Natural);

   function Get_Line (File : File_Type) return String;
   function Get_Line return String;

   procedure Put_Line (File : File_Type; Item : String);
   procedure Put_Line (Item : String);

   ----------------
   -- Exceptions --
   ----------------

   Status_Error : exception renames Ada.Text_IO.Status_Error;
   Mode_Error   : exception renames Ada.Text_IO.Mode_Error;
   Name_Error   : exception renames Ada.Text_IO.Name_Error;
   Use_Error    : exception renames Ada.Text_IO.Use_Error;
   Device_Error : exception renames Ada.Text_IO.Device_Error;
   End_Error    : exception renames Ada.Text_IO.End_Error;
   Data_Error   : exception renames Ada.Text_IO.Data_Error;
   Layout_Error : exception renames Ada.Text_IO.Layout_Error;

private

   type File_Kind is (Reg, Std, Gui);
   -- Reg is for regular file descriptors, Std is for standard IO descriptors, Gui is for graphic interface IO
   -- descriptor
   type Root_File_Type (Kind : File_Kind) is record
      -- The access is constant for standard IO descriptors
      case Kind is
         when Reg =>
            File_IO : Ada.Text_IO.File_Type;
         when Std =>
            Std_IO : Ada.Text_IO.File_Access;
         when Gui =>
            Gui_IO : Gnoga.Gui.Plugin.Ace_Editor.Console_IO.Pointer_To_Console_IO_Class;
      end case;
   end record;
   type File_Type is access Root_File_Type;

end GX_Text_IO;
