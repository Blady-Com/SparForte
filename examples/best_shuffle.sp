#!/usr/local/bin/spar

pragma annotate( summary, "best_shuffle" );
pragma annotate( description, "Shuffle the characters of a string in such a" );
pragma annotate( description, "way that as many of the character values are" );
pragma annotate( description, "in a different position as possible. Print" );
pragma annotate( description, "the result as follows: original string," );
pragma annotate( description, "shuffled string, (score). The score gives the" );
pragma annotate( description, "number of positions whose character value" );
pragma annotate( description, "did not change." );
pragma annotate( author, "Ken O. Burtch" );
pragma annotate( see_also, "http://rosettacode.org/wiki/Best_shuffle" );
pragma license( unrestricted );

pragma restriction( no_external_commands );

procedure best_shuffle is

  -- Shuffle the characters in a string.  Do not swap identical characters

  function shuffle( s : string ) return string is
    t : string := s;
    tmp : character;
  begin
    for i in 1..strings.length(s) loop
       for j in 1..strings.length(s) loop
         if i /= j and strings.element( s, i ) /= strings.element( t, j ) and strings.element( s, j ) /= strings.element( t, i ) then
            tmp := strings.element( t, i );
            t := strings.overwrite( t, i, strings.element( t, j ) & "" );
            t := strings.overwrite( t, j, tmp & "" );
         end if;
       end loop;
    end loop;
    return t;
  end shuffle;

  stop : boolean := false;

begin

  while not stop loop
    declare
      original : string := get_line;
      shuffled : string := shuffle( original );
      score : natural := 0;
   begin
      if original = "" then
         stop;
      end if;

      -- determine the score for the shuffled string

      for i in 1..strings.length( original ) loop
         if strings.element( original, i ) = strings.element( shuffled, i ) then
            score := @+1;
         end if;
      end loop;
      put_line( original & ", " & shuffled & ", (" &
          strings.image( score ) & " )" );

   end;
  end loop;

end best_shuffle;

-- VIM editor formatting instructions
-- vim: ft=spar

