package Input_Output is

   type Root_IO_Type is abstract tagged limited private;

   type IO_Element is mod 2**Standard'Storage_Unit;

   type IO_Element_Offset is new Long_Long_Integer;

   subtype IO_Element_Count is IO_Element_Offset range 0 .. IO_Element_Offset'Last;

   type IO_Element_Array is array (IO_Element_Offset range <>) of aliased IO_Element;

   procedure Write (IO : in Root_IO_Type; Item : IO_Element_Array) is abstract;

   procedure Read (IO : in Root_IO_Type; Item : out IO_Element_Array; Last : out IO_Element_Offset) is abstract;

private

   type Root_IO_Type is abstract tagged limited null record;

end Input_Output;
