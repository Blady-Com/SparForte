procedure p is

  function myfunc( myparam1 : integer; myparam1 : integer ) return integer is -- dup name cannot be used as param
  begin
    return myparam1;
  end myfunc;

begin
  ? myfunc( 5 );
end p;

