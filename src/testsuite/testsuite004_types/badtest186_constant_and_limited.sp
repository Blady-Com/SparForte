# This should fail

procedure p is

  type i is new constant limited integer; -- not allowed

  j : i := 1;
  pragma assumption( used, j );
begin
  null;
end p;

