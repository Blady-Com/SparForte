procedure p is

  procedure myproc( myparam : integer; myparam : integer ) is -- name cannot be used twice
  begin
    ? myparam;
  end myproc;

begin
  myproc( 5 );
end p;

