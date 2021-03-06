#!/usr/local/bin/spar

procedure isxwindows is

pragma annotate( summary, "isxwindows" )
       @( description, "return status zero if is started under X-Windows" )
       @( description, "Translated from a shell script by Heiner Steven" )
       @( see_also, "http://www.shelldorado.com/scripts/cmds/isxwindows.txt" )
       @( author, "Ken O. Burtch" );
pragma license( unrestricted );

DISPLAY : constant string := "";
pragma unchecked_import( shell, DISPLAY );

WINDOWID : constant string := "";
pragma unchecked_import( shell, WINDOWID );

procedure usage is
begin
  put( "usage: " ) @ (source_info.file);
  put_line ( "return status zero if is started under X-Windows" );
  command_line.set_exit_status( 1 );
end usage;

begin

  if $# /= 0 then
    usage;
    return;
  end if;

  command_line.set_exit_status( 2 );
  if DISPLAY /= "" then
     if WINDOWID /= "" then
        command_line.set_exit_status( 0 );
     elsif strings.head( TERM, 5 ) = "xterm" then
        command_line.set_exit_status( 0 );
     elsif strings.head( TERM, 7 ) = "sum-cmd" then
        command_line.set_exit_status( 0 );
     end if;
  end if;

end isxwindows;

-- VIM editor formatting instructions
-- vim: ft=spar

