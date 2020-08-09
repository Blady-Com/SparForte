with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Gnoga.Gui.Plugin.Ace_Editor.Console_IO;

package Input_Output.Text_IO.GUI_Text_IO is

   type Console_Type is new Text_IO_Type with private;

   subtype Count is Input_Output.Text_IO.Count;
   subtype Positive_Count is Input_Output.Text_IO.Positive_Count;

   procedure Create (Console : in out Console_Type);

   procedure Open (Console : in out Console_Type; View : in Gnoga.Gui.Plugin.Ace_Editor.Console_IO.Pointer_To_Console_IO_Class);

   procedure Close (Console : in out Console_Type);
   procedure Delete (Console : in out Console_Type);
   procedure Reset (Console : in out Console_Type);

   function Is_Open (Console : in Console_Type) return Boolean;

   --Buffer control

   procedure Flush (Console : in Console_Type);
   procedure Flush;

   -- Specification of line and page lengths

   procedure Set_Line_Length (Console : in Console_Type; To : in Count);
   procedure Set_Line_Length (To : in Count);

   procedure Set_Page_Length (Console : in Console_Type; To : in Count);
   procedure Set_Page_Length (To : in Count);

   function Line_Length (Console : in Console_Type) return Count;
   function Line_Length return Count;

   function Page_Length (Console : in Console_Type) return Count;
   function Page_Length return Count;

   -- Column, Line, and Page Control

   procedure New_Line (Spacing : in Positive_Count := 1) renames Input_Output.Text_IO.New_Line;

   procedure Skip_Line (Spacing : in Positive_Count := 1);

   function End_Of_Line return Boolean renames Input_Output.Text_IO.End_Of_Line;

   procedure New_Page (Console : in Console_Type);
   procedure New_Page;

   procedure Skip_Page (Console : in Console_Type);
   procedure Skip_Page;

   function End_Of_Page (Console : in Console_Type) return Boolean;
   function End_Of_Page return Boolean;

   function End_Of_File (Console : in Console_Type) return Boolean;
   function End_Of_File return Boolean;

   procedure Set_Col (Console : in Console_Type; To : in Positive_Count);
   procedure Set_Col (To : in Positive_Count);

   procedure Set_Line (Console : in Console_Type; To : in Positive_Count);
   procedure Set_Line (To : in Positive_Count);

   function Col (Console : in Console_Type) return Positive_Count;
   function Col return Positive_Count;

   function Line (Console : in Console_Type) return Positive_Count;
   function Line return Positive_Count;

   function Page (Console : in Console_Type) return Positive_Count;
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
   procedure Put (F : Console_Type; S : Unbounded_String);
   procedure Put_Line (F : Console_Type; S : Unbounded_String);

private
   type Console_Type is new Text_IO_Type with record
      Text_IO_Console : Gnoga.Gui.Plugin.Ace_Editor.Console_IO.Pointer_To_Console_IO_Class;
   end record;

   overriding procedure Write (IO : in Console_Type; Item : IO_Element_Array);
   overriding procedure Read (IO : in Console_Type; Item : out IO_Element_Array; Last : out IO_Element_Offset);
   overriding procedure GetC (IO : in Console_Type; Ch : out Character; Available : out Boolean);
   overriding procedure PutC (IO : in Console_Type; Item : Character);
   overriding procedure LookC (IO : in Console_Type; Ch : out Character; Available : out Boolean);
   overriding procedure NLC (IO : in Console_Type);
   overriding function GetL (IO : in Console_Type) return String;

end Input_Output.Text_IO.GUI_Text_IO;
