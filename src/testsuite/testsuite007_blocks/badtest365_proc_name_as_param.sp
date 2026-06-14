procedure p is

  procedure myproc( myproc : integer ) is -- name cannot be used as param
  begin
    ? myproc;
  end myproc;

begin
  myproc( 5 );
end p;

