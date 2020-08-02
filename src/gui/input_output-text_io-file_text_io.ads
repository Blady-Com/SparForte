with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Input_Output.Text_IO.File_Text_IO is

   type File_Type is new Text_IO_Type with private;
   subtype File_Mode is Ada.Text_IO.File_Mode;
   use all type Ada.Text_IO.File_Mode;

   subtype Count is Input_Output.Text_IO.Count;
   subtype Positive_Count is Input_Output.Text_IO.Positive_Count;
   Unbounded : Ada.Text_IO.Count renames Ada.Text_IO.Unbounded;

   subtype Field is Ada.Text_IO.Field;
   subtype Number_Base is Ada.Text_IO.Number_Base;
   subtype Type_Set is Ada.Text_IO.Type_Set;

   procedure Create (File : in out File_Type; Mode : File_Mode := Out_File; Name : String := ""; Form : String := "");

   procedure Open (File : in out File_Type; Mode : File_Mode; Name : String; Form : String := "");

   procedure Close (File : in out File_Type);
   procedure Delete (File : in out File_Type);
   procedure Reset (File : in out File_Type; Mode : in File_Mode);
   procedure Reset (File : in out File_Type);

   function Mode (File : in File_Type) return File_Mode;
   function Name (File : in File_Type) return String;
   function Form (File : in File_Type) return String;

   function Is_Open (File : in File_Type) return Boolean;

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

   --Buffer control

   procedure Flush (File : in File_Type);
   procedure Flush;

   -- Specification of line and page lengths

   procedure Set_Line_Length (File : in File_Type; To : in Count);
   procedure Set_Line_Length (To : in Count);

   procedure Set_Page_Length (File : in File_Type; To : in Count);
   procedure Set_Page_Length (To : in Count);

   function Line_Length (File : in File_Type) return Count;
   function Line_Length return Count;

   function Page_Length (File : in File_Type) return Count;
   function Page_Length return Count;

   -- Column, Line, and Page Control

   procedure New_Line (Spacing : in Positive_Count := 1) renames Input_Output.Text_IO.New_Line;

   procedure Skip_Line (Spacing : in Positive_Count := 1);

   function End_Of_Line return Boolean renames Input_Output.Text_IO.End_Of_Line;

   procedure New_Page (File : in File_Type);
   procedure New_Page;

   procedure Skip_Page (File : in File_Type);
   procedure Skip_Page;

   function End_Of_Page (File : in File_Type) return Boolean;
   function End_Of_Page return Boolean;

   function End_Of_File (File : in File_Type) return Boolean;
   function End_Of_File return Boolean;

   procedure Set_Col (File : in File_Type; To : in Positive_Count);
   procedure Set_Col (To : in Positive_Count);

   procedure Set_Line (File : in File_Type; To : in Positive_Count);
   procedure Set_Line (To : in Positive_Count);

   function Col (File : in File_Type) return Positive_Count;
   function Col return Positive_Count;

   function Line (File : in File_Type) return Positive_Count;
   function Line return Positive_Count;

   function Page (File : in File_Type) return Positive_Count;
   function Page return Positive_Count;

   -- Character Input-Output

   procedure Get (Item : out Character) renames Input_Output.Text_IO.Get;

   procedure Put (Item : in Character) renames Input_Output.Text_IO.Put;

   procedure Look_Ahead (Item : out Character; End_Of_Line : out Boolean) renames Input_Output.Text_IO.Look_Ahead;

   procedure Get_Immediate (Item : out Character) renames Input_Output.Text_IO.Get_Immediate;

   procedure Get_Immediate (Item : out Character; Available : out Boolean) renames Input_Output.Text_IO.Get_Immediate;

   -- String Input-Output

   procedure Get (Item : out String; Length : in Count) renames Input_Output.Text_IO.Get;

   procedure Put (Item : in String) renames Input_Output.Text_IO.Put;

   procedure Get_Line (Item : out String; Last : out Natural) renames Input_Output.Text_IO.Get_Line;

   function Get_Line return String renames Input_Output.Text_IO.Get_Line;

   procedure Put_Line (Item : in String) renames Input_Output.Text_IO.Put_Line;

   procedure Put (S : Unbounded_String);
   procedure Put_Line (S : Unbounded_String);
   procedure Put (F : File_Type; S : Unbounded_String);
   procedure Put_Line (F : File_Type; S : Unbounded_String);

   Status_Error : exception renames Ada.Text_IO.Status_Error;
   Mode_Error   : exception renames Ada.Text_IO.Mode_Error;
   Name_Error   : exception renames Ada.Text_IO.Name_Error;
   Use_Error    : exception renames Ada.Text_IO.Use_Error;
   Device_Error : exception renames Ada.Text_IO.Device_Error;
   End_Error    : exception renames Ada.Text_IO.End_Error;
   Data_Error   : exception renames Ada.Text_IO.Data_Error;
   Layout_Error : exception renames Ada.Text_IO.Layout_Error;

private
   type Text_IO_File_Access is access Ada.Text_IO.File_Type;
   type File_Type is new Text_IO_Type with record
      Text_IO_File : Text_IO_File_Access;
   end record;

   overriding procedure Write (IO : in File_Type; Item : IO_Element_Array);
   overriding procedure Read (IO : in File_Type; Item : out IO_Element_Array; Last : out IO_Element_Offset);
   overriding procedure GetC (IO : in File_Type; Ch : out Character; Available : out Boolean);
   overriding procedure PutC (IO : in File_Type; Item : Character);
   overriding procedure LookC (IO : in File_Type; Ch : out Character; Available : out Boolean);
   procedure NLC (IO : in File_Type);

end Input_Output.Text_IO.File_Text_IO;
