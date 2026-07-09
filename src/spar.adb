------------------------------------------------------------------------------
-- Main Program                                                             --
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

with ada.text_io,
     ada.strings.unbounded,
     ada.command_line,
     ada.exceptions,
     spar_os.exec,
     world.splashes,
     world.deps,
     symbol_table,
     compiler,
     scanner.communications,
     pegasoft.user_io,
     pegasoft.strings,
     parser,
     interpreter,
     signal_flags;

use ada.text_io,
    ada.strings.unbounded,
    ada.command_line,
    ada.exceptions,
    spar_os.exec,
    world,
    world.splashes,
    world.deps,
    symbol_table,
    compiler,
    scanner,
    scanner.communications,
    pegasoft.user_io,
    pegasoft.strings,
    parser,
    interpreter,
    signal_flags;

--with string_util; use string_util;

--with spar_interface;

-- pragma Optimize( space );

procedure spar is
  term_id         : identifier;        -- index of TERM environment identifier
  libraryPathNext : boolean := false;  -- true if -L directory is a separate argument
  wasCoding       : boolean := false;  -- true if we're in the development phase of SDLC
  wasDesign       : boolean := false;  -- true if we're in the design phase of SDLC
  wasMaintenance  : boolean := false;  -- true if we're in the maintenance phase of SDLC
  wasTest         : boolean := false;  -- true if we're in the testing phase of SDLC
  i               : positive := 1;     -- command line argument index

  -- POSIX process exit status codes
  -- 0 to 191 = the standard POSIX error number (defined in spar_os.ads)
  -- 192 = a custom SparForte error

  EXIT_STATUS_OK : constant Ada.Command_Line.Exit_Status := 0;
  EXIT_STATUS_FAILED : constant Ada.Command_Line.Exit_Status := 192;

  procedure showSBOM is
  begin
    for i in sparBuildDependencies'range loop
        put( i'img & ": " );
        put( "Name: " & ASCII.Quotation & to_string( sparBuildDependencies( i ).names ) & ASCII.Quotation & ", " );
        put( "Version: " & ASCII.Quotation & to_string( sparBuildDependencies( i ).version ) & ASCII.Quotation & ", " );
        put( "Kind: " & ASCII.Quotation & to_string( sparBuildDependencies( i ).kind ) & ASCII.Quotation & ", " );
        put( "Files: " & ASCII.Quotation & to_string( sparBuildDependencies( i ).files ) & ASCII.Quotation & ", " );
        put( "License: " & ASCII.Quotation & to_string( sparBuildDependencies( i ).license ) & ASCII.Quotation  );
        new_line;
    end loop;
    put_line( "There are" & sparBuildDependencies'length'img & " build dependencies." );
  end showSBOM;

begin
  startSignalFlags;

  -- set scanner variable to reflect whether or not this is a login
  -- shell

  isLoginShell := Command_Name(1) = '-';

  -- test phase mode is now the default

  testOpt := true;

  -- collect command line options

  if Argument_Count = 1 then
     if Argument(1) = "-h" or Argument( 1 ) = "--help" then
        displayCommandLineUsageHelp;
        Set_Exit_Status( EXIT_STATUS_OK );
        return;
     elsif Argument(1) = "-V" or Argument( 1 ) = "--version" then
        displayVersionSplash;
        Set_Exit_Status( EXIT_STATUS_OK );
        return;
     elsif Argument(1) = "-B" or Argument( 1 ) = "--sbom" then
        showSBOM;
        return;
     end if;
  end if;
  if Argument_Count > 0 then
     -- optionOffset is the command line argument index.  Start with the first argument.
     optionOffset := 1;
     -- LibraryPathNext is true when a directory argument is expected for the library
     -- search path.  This only happens after a -L argument where there is a space between
     -- the option and the library name, producing two arguments, which is permitted by
     -- POSIX.
     libraryPathNext := false;

     -- for i in 1..Argument_Count loop
     while i <= Argument_Count loop
         if libraryPathNext then
            if Argument(i)'length = 0 then
               Put_Line( standard_error, Command_Name & ": missing argument for -L" );
               Set_Exit_Status( EXIT_STATUS_OK );
               return;
            end if;
            if length( libraryPath ) > 0 then
               libraryPath := libraryPath & ":";
            end if;
            libraryPath := libraryPath & to_unbounded_string( Argument(i) );
            libraryPathNext := false;

         -- Interpret Long (--) Arguments

         elsif Argument(i) = "--break" then
            breakoutOpt := true;
         elsif Argument(i) = "--check" then
            syntaxOpt := true;
         elsif Argument(i) = "--coding" then
            testOpt := false;
            codingOpt := true;
            wasCoding := true;
         elsif Argument(i) = "--color" then
            colourOpt := true;
         elsif Argument(i) = "--colour" then
            colourOpt := true;
         elsif Argument(i) = "--debug" then
            debugOpt := true;
         elsif Argument(i) = "--design" then
            testOpt   := false;
            designOpt := true;
            wasDesign := true;
         elsif Argument(i) = "--exec" then
            execOpt := true;
         elsif Argument(i) = "--gcc-errors" then
            gccOpt := true;
         elsif Argument(i) = "--help" then
            Put_Line( standard_error, Command_Name & ": --help should appear by itself" );
            Set_Exit_Status( EXIT_STATUS_FAILED );
            return;
         elsif Argument(i) = "--import-all" then
            importOpt := true;
         elsif Argument(i) = "--login" then
            isLoginShell := true;
         elsif Argument(i) = "--maintenance" then
            testOpt   := false;
            maintenanceOpt := true;
            wasMaintenance := true;
         elsif Argument(i) = "--perf" then
             -- enable performance profiling and show a report at the end of execution
             perfOpt := true;
         elsif Argument(i) = "--profile" then
             -- read the user's shell profile even if it would not be read
             profileOpt := true;
         elsif Argument(i) = "--quiet" then
            quietOpt := true;
         elsif Argument(i) = "--restricted" then
            rshOpt := true;
         elsif Argument(i) = "--sbom" then
            Put_Line( standard_error, Command_Name & ": --sbom should appear by itself" );
            Set_Exit_Status( EXIT_STATUS_FAILED );
            return;
         elsif Argument(i) = "--test" then
            testOpt := true;
            wasTest := true;
         elsif Argument(i) = "--session" then
            -- For the session, we need a session name
            if i < Argument_Count then
               optionOffset := optionOffset + 1;
               i := i + 1;
               if sessionName /= "" then
                  Put_Line( standard_error, Command_Name & ": --session was used more than once" );
                  Set_Exit_Status( EXIT_STATUS_FAILED );
                  return;
               elsif not Is_Alphanumeric(to_unbounded_string( Argument(i) ) ) then
                  -- While the session name needs error checking, requiring only alphanumeric
                  -- characters may interfere with future support for UTF-8.
                  Put_Line( standard_error, Command_Name & ": --session name is not alphanumeric" );
                  Set_Exit_Status( EXIT_STATUS_FAILED );
                  return;
              else
                  sessionName := to_unbounded_string( Argument(i) );
              end if;
            else
               Put_Line( standard_error, Command_Name & ": --session should have a name" );
               Set_Exit_Status( EXIT_STATUS_FAILED );
               return;
            end if;
         elsif Argument(i) = "--trace" then
            traceOpt := true;
         --elsif Argument(i) = "--tabsize" then
         --   tabsizeOpt := true;
         elsif Argument(i) = "--verbose" then
            verboseOpt := true;
         elsif Argument(i) = "--version" then
            Put_Line( standard_error, Command_Name & ": --version should appear by itself" );
            Set_Exit_Status( EXIT_STATUS_FAILED );
            return;
         elsif Argument(i) = "--" then
            optionOffset := optionOffset + 1;
            exit;
         elsif Argument(i)'length = 0 then
            if execOpt then
               Put_Line( standard_error, Command_Name & ": empty script string" );
            else
               Put_Line( standard_error, Command_Name & ": empty script name" );
            end if;
            Set_Exit_Status( EXIT_STATUS_FAILED );
            return;
         elsif Argument(i)(1) = '-' then

            -- Interpret 1 or More Individual Characters

            declare
               Args : constant string := Argument(i);
            begin
               if Args'length < 2 then
                  Put_Line( standard_error, Command_Name & ": missing options: " & Argument(i) );
                  Set_Exit_Status( EXIT_STATUS_FAILED );
                  return;
               end if;
               -- -L has a weird format: the directory is immediately attached
               -- to the "L" but the directory may optionally be a second parameter.

               if Args(2) = 'L' then
                   if Args'length = 2 then
                      libraryPathNext := true;
                   else
                      if length( libraryPath ) > 0 then
                         libraryPath := libraryPath & ":";
                      end if;
                   end if;
                   libraryPath := libraryPath & to_unbounded_string( Args(3..Args'last) );
               else
               for letter in 2..Args'last loop
                   if Args(letter) = 'b' then
                      breakoutOpt := true;
                   elsif Args(letter) = 'B' then
                      Put_Line( standard_error, Command_Name & ": -B should appear by itself" );
                      Set_Exit_Status( EXIT_STATUS_FAILED );
                      return;
                   elsif Args(letter) = 'c' then
                      syntaxOpt := true;
                   elsif Args(letter) = 'C' then
                      testOpt := false;
                      codingOpt := true;
                      wasCoding := true;
                   elsif Args(letter) = 'd' then
                      debugOpt := true;
                   elsif Args(letter) = 'D' then
                      testOpt   := false;
                      designOpt := true;
                      wasDesign := true;
                   elsif Args(letter) = 'e' then
                      execOpt := true;
                   elsif Args(letter) = 'h' then
                      Put_Line( standard_error, Command_Name & ": -h should appear by itself" );
                      Set_Exit_Status( EXIT_STATUS_FAILED );
                      return;
                   elsif Args(letter) = 'i' then
                      importOpt := true;
                   elsif Args(letter) = 'l' then
                      isLoginShell := true;
                   elsif Args(letter) = 'm' then
                      testOpt   := false;
                      maintenanceOpt := true;
                      wasMaintenance := true;
                   elsif Args(letter) = 'p' then
                      perfOpt := true;
                   elsif Args(letter) = 'P' then
                      profileOpt := true;
                   elsif Args(letter) = 'q' then
                      quietOpt := true;
                   elsif Args(letter) = 'g' then
                      gccOpt := true;
                   elsif Args(letter) = 'r' then
                      rshOpt := true;
                   elsif Args(letter) = 't' then
                      testOpt   := false;
                      testOpt := true;
                      wasTest := true;
                   elsif Args(letter) = 'v' then
                      verboseOpt := true;
                   elsif Argument(i) = "-V" then
                      Put_Line( standard_error, Command_Name & ": -V should appear by itself" );
                      Set_Exit_Status( EXIT_STATUS_FAILED );
                      return;
                   elsif Args(letter) = 'x' then
                      traceOpt := true;
                   else
                      Put_Line( standard_error, Command_Name & ": unknown option: " & Argument(i) );
                      Set_Exit_Status( EXIT_STATUS_FAILED );
                      return;
                   end if;
               end loop;
            end if;
            end;
         else
            exit;
         end if;
         optionOffset := optionOffset + 1;
         i := i + 1;
     end loop;
  end if;

  -- Missing arguments / commands

  if libraryPathNext then
     -- if all arguments have been read but a library path is expected, then it is missing
     Put_Line( standard_error, Command_Name & ": missing argument for -L" );
     Set_Exit_Status( EXIT_STATUS_FAILED );
     return;
  end if;
  if boolean(syntaxOpt) and
     optionOffset > Argument_Count then
     Put_Line( standard_error, Command_Name & ": missing command name" );
     Set_Exit_Status( EXIT_STATUS_FAILED );
     return;
  end if;
  if optionOffset > Argument_Count then
     optionOffset := 0;
  end if;

  -- Illegal option switch combinations

  if (wasDesign and wasCoding) or (wasDesign and wasMaintenance) or (wasDesign and wasTest) or (wasCoding and wasMaintenance) or (wasCoding and wasTest) or (wasMaintenance and wasTest) then
     Put_Line( standard_error, Command_Name & ": only one of --design, --maintenance or --test is allowed" );
     Set_Exit_Status( EXIT_STATUS_FAILED );
     return;
  end if;
  if isLoginShell and boolean( profileOpt ) then
     Put_Line( standard_error, Command_Name & ": only one of --login and --profile is allowed" );
     Set_Exit_Status( EXIT_STATUS_FAILED );
     return;
  end if;

  -- Initialize
  --
  -- Start the byte code compiler, scanner.  Setup the display.  Start the
  -- parser.

  startCommunications;
  startCompiler;
  startScanner;
  findIdent( to_unbounded_string( "TERM" ), term_id );
  checkDisplay( identifiers( term_id ).store.value );
  startParser;
  startInterpreter;

  -- replace initialization message with copyright notice (if on
  -- a terminal and not running a script)

  if optionOffset = 0 then
     displayCopyrightSplash;
  end if;

  -- Run the SparForte interpreter: load profiles, run a script or start command line session

  interpret;

  -- Shut down the interpreter main layers cleanly.

  shutdownInterpreter;
  shutdownParser;
  shutdownScanner;
  shutdownCompiler;
  shutdownSignalFlags;
  shutdownCommunications;

exception when EXEC_CHILD_ERROR =>
   -- when exec() family of calls fail (for example, the bang path is
   -- wrong, the child process must die.  There's no need for a SparForte
   -- bug report.
   null;
 when msg : others =>
  -- When handling any uncaught exception raised to the main program, produce a custom bug
  -- report for the user.  Include the SparForte version, build date and exception message.
  -- Fall back to writing to standard_error because the interpreter's state and normal
  -- error functions may be unreliable.

  put_line( standard_error, "SparForte Bug" );
  new_line( standard_error );
  put_line( standard_error, "SparForte " & version & "(BUILD ID " & buildId & ")" );
  put_line( standard_error, "Built by " & builder );
  put_line( standard_error, "An unexpected exception was raised to the main program:" );
  put_line( standard_error, Exception_Message( msg ) ) ;
  new_line( standard_error );
  put_line( standard_error, "To report bugs, please read 'Reporting Bugs' at" );
  put_line( standard_error, "in the Preface of the SparForte documentation" );

  -- After reporting the unexpected exception, shut down the interpreter main layers cleanly.

  shutdownInterpreter;
  shutdownParser;
  shutdownScanner;
  shutdownCompiler;
  shutdownSignalFlags;
  shutdownCommunications;

  -- Finally, Ada will process the uncaught exception normally.  The SparForte
  -- tests will fail when they detect an Ada exception.

  raise;
end spar;
