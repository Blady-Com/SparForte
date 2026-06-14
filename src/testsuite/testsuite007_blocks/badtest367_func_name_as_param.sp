procedure p is

  function myfunc( myfunc : integer ) return integer is -- name cannot be used as param
  begin
    return myfunc;
  end myfunc;

begin
  ? myfunc( 5 );
end p;

