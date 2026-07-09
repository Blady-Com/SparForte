------------------------------------------------------------------------------
-- Splashes are displays of mostly static text                              --
--                                                                          --
-- Part of SparForte                                                        --
------------------------------------------------------------------------------
--                                                                          --
--            Copyright (C) 2001-2026 Free Software Foundation              --
--                                                                          --
-- This is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  This is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with this;  see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- This is maintained at http://www.pegasoft.ca                             --
--                                                                          --
------------------------------------------------------------------------------

with ada.text_io;
use  ada.text_io;

package body world.splashes is

-----------------------------------------------------------------------------
--  DISPLAY VERSION SPLASH
--
-- Display version message when the user types "spar --version".
-----------------------------------------------------------------------------

procedure displayVersionSplash is
begin
  if isatty( stdout ) = 1 then
     Put( "SparForte version " );
     if released then
        Put_Line( version );
     else
        Put_Line( version & " (Build ID " & buildId & ')' );
     end if;
     Put_Line( "Built by " & builder );
     Put_Line( copyright );
     Put_Line( "This is free software; see the source for copying conditions." );
     Put_Line( "There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE." );
  end if;
end displayVersionSplash;


-----------------------------------------------------------------------------
--  DISPLAY COPYRIGHT SPLASH
--
-- Display copyright message.  This is located here because it
-- uses term attributes.  Suppress the message on a login shell
-- or if there is no tty.
-- Some of this message is now defined in the world.ads file.
-----------------------------------------------------------------------------

procedure displayCopyrightSplash is
begin
  if isatty( stdout ) = 1 and not isLoginShell then
     Put_Line( "Type ""help"" for help" );
  end if;
end displayCopyrightSplash;


-----------------------------------------------------------------------------
--  DISPLAY COMMAND LINE USAGE HELP
--
-- Display the help message for running SparForte on the command line, using
-- GNU/Linux formatting.
-----------------------------------------------------------------------------

procedure displayCommandLineUsageHelp is
begin
  Put_Line( "SparForte usage" );
  Put_Line( "spar [-BbcCdDeghilLmprtvVx] [-Ld|-L d] [--break][--builddeps][--check][--debug][--exec][--gcc-errors][--login][--verbose][--version][--perf][--restricted][--session s][--sbom][--coding|--design|--maintenance|--test][--trace][--] [script [param1 ...] ]" );
  Put_Line( "  --break or -b       - enable breakout debugging prompt" );
  Put_Line( "  --check or -c       - syntax check the script but do not run" );
  Put_Line( "  --coding or -C      - development phase mode" );
  Put_Line( "  --color or --colour - enable coloured messages and UTF-8 icons" );
  Put_Line( "  --debug or -d       - enable pragma assert and pragma debug" );
  Put_Line( "  --design or -D      - design phase mode" );
  Put_Line( "  --exec or -e        - script is a string containing SparForte commands" );
  Put_Line( "  --gcc-errors or -g  - simple GCC-style errors (good for IDEs)" );
  Put_Line( "  --help or -h        - show this help" );
  Put_Line( "  --import-all or -i  - import all environment variables" );
  Put_Line( "  -Ld or -L d         - add directory d to the separate files search list" );
  Put_Line( "                        (may be repeated)" );
  Put_Line( "  --login or -l       - simulate a login shell" );
  Put_Line( "  --maintenance or -m - maintenance phase mode" );
  Put_Line( "  --profile or -P     - run the profile script when not logging in" );
  Put_Line( "  --pref or -p        - show performance stats" );
  Put_Line( "  --quiet or -q       - brief error messages" );
  Put_Line( "  --restricted or -r  - restricted shell mode" );
  Put_Line( "  --sbom or -B        - list build dependencies (SBOM)" );
  Put_Line( "  --session s         - start a session with the name s" );
  Put_Line( "  --test or -t        - test phase mode (default)" );
  Put_Line( "  --trace or -x       - show script lines as they run" );
  Put_Line( "  --verbose or -v     - show shell activity" );
  Put_Line( "  --version or -V     - show version" );
  Put_Line( "  --                  - explicitly end shell options" );
end displayCommandLineUsageHelp;

end world.splashes;

