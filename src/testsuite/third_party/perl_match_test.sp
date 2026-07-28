procedure perl_match_test is
  b : boolean;
begin

  b := strings.perl_match( "hello", "hello" );
  pragma assert( b = true );

  b := strings.perl_match( "ht", "hello" );
  pragma assert( b = false );

end perl_match_test;

