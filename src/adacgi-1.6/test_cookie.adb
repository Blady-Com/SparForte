-- This is a short program to test getting cookie values.

with Sf_Text_Io; use Sf_Text_Io;
with Ada.Integer_Text_Io; use Ada.Integer_Text_IO;
with CGI; use CGI;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

procedure Test_Cookie is 
  Temp: Unbounded_String;
begin
  Put("Number of cookies=");
  Put(Cookie_Count);
  New_Line;

  if Cookie_Count > 0 then
    Temp := Cookie_Value(1);
    Put("Value of first cookie: ");
    Put_Line(To_String(Temp));
  end if;

  Temp := Cookie_Value("problem");
  Put("Value of cookie ""problem"": "); 
  Put(To_String(Temp));
end Test_Cookie;

