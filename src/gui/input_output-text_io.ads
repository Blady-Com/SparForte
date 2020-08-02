package Input_Output.Text_IO is

   type Text_IO_Type is abstract new Input_Output.Root_IO_Type with private;
   type Text_IO_Access is access all Text_IO_Type'Class;

   type Count is range 0 .. Natural'Last;
   subtype Positive_Count is Count range 1 .. Count'Last;

   -- Control of default input and output files

   procedure Set_Input (File : in Text_IO_Type);
   procedure Set_Output (File : in Text_IO_Type);
   procedure Set_Error (File : in Text_IO_Type);

   function Current_Input return Text_IO_Access;
   function Current_Output return Text_IO_Access;
   function Current_Error return Text_IO_Access;

--     type File_Access is access constant Text_IO_Type;
--
--     function Current_Input return File_Access;
--     function Current_Output return File_Access;
--     function Current_Error return File_Access;

   -- Column, Line, and Page Control

   procedure New_Line (File : in Text_IO_Type; Spacing : in Positive_Count := 1);
   procedure New_Line (Spacing : in Positive_Count := 1);

   procedure Skip_Line (File : in Text_IO_Type; Spacing : in Positive_Count := 1);
   procedure Skip_Line (Spacing : in Positive_Count := 1);

   function End_Of_Line (File : in Text_IO_Type) return Boolean;
   function End_Of_Line return Boolean;

   -- Character Input-Output

   procedure Get (File : in Text_IO_Type; Item : out Character);
   procedure Get (Item : out Character);

   procedure Put (File : in Text_IO_Type; Item : in Character);
   procedure Put (Item : in Character);

   procedure Look_Ahead (File : in Text_IO_Type; Item : out Character; End_Of_Line : out Boolean);
   procedure Look_Ahead (Item : out Character; End_Of_Line : out Boolean);

   procedure Get_Immediate (File : in Text_IO_Type; Item : out Character);
   procedure Get_Immediate (Item : out Character);

   procedure Get_Immediate (File : in Text_IO_Type; Item : out Character; Available : out Boolean);
   procedure Get_Immediate (Item : out Character; Available : out Boolean);

   -- String Input-Output

   procedure Get (File : in Text_IO_Type; Item : out String; Length : in Count);
   procedure Get (Item : out String; Length : in Count);

   procedure Put (File : in Text_IO_Type; Item : in String);
   procedure Put (Item : in String);

   procedure Get_Line (File : in Text_IO_Type; Item : out String; Last : out Natural);
   procedure Get_Line (Item : out String; Last : out Natural);

   function Get_Line (File : in Text_IO_Type) return String;
   function Get_Line return String;

   procedure Put_Line (File : in Text_IO_Type; Item : in String);
   procedure Put_Line (Item : in String);

   procedure GetC (IO : in Text_IO_Type; Item : out Character; Available : out Boolean) is abstract;

   procedure PutC (IO : in Text_IO_Type; Item : Character) is abstract;

   procedure LookC (IO : in Text_IO_Type; Item : out Character; Available : out Boolean) is abstract;

   procedure NLC (IO : in Text_IO_Type) is abstract;

private

   type Handle_Type (File : access Text_IO_Type) is limited null record;
   type Text_IO_Type is abstract new Input_Output.Root_IO_Type with record
      Handle : Handle_Type (Text_IO_Type'Access);
   end record;

end Input_Output.Text_IO;
