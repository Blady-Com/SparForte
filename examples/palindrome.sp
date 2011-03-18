#!/usr/local/bin/bush

pragma annotate( "palindrome" );
pragma annotate( "" );
pragma annotate( "Write at least one function/method (or whatever it is" );
pragma annotate( "called in your preferred language) to check if a" );
pragma annotate( "sequence of characters (or bytes) is a palindrome or" );
pragma annotate( "not. The function must return a boolean value (or" );
pragma annotate( "something that can be used as boolean value, like an" );
pragma annotate( "integer)." );
pragma annotate( "" );
pragma annotate( "http://rosettacode.org/wiki/Palindrome_detection" );
pragma annotate( "by Ken O. Burtch (based on Ada version)" );

pragma restriction( no_external_commands );

procedure palindrome is

  function is_palindrome( text : string ) return boolean is
  begin
    for offset in 0..strings.length( text ) / 2 -1 loop
      if strings.element( text, offset+1) /= strings.element( text, positive( strings.length( text ) - offset ) ) then
         return false;
      end if;
    end loop;
    return true;
  end is_palindrome;

  sentence : string;
  result   : boolean;
begin
  sentence := "this is a test";
  result   := is_palindrome( sentence );
  put(  sentence ) @ ( " : " ) @ ( result );
  new_line;

  sentence := "ablewasiereisawelba";
  result   := is_palindrome( sentence );
  put(  sentence ) @ ( " : " ) @ ( result );
  new_line;
end palindrome;

