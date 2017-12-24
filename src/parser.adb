------------------------------------------------------------------------------
-- AdaScript Language Parser                                                --
--                                                                          --
-- Part of SparForte                                                        --
------------------------------------------------------------------------------
--                                                                          --
--            Copyright (C) 2001-2017 Free Software Foundation              --
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
-- This is maintained at http://www.sparforte.com                           --
--                                                                          --
------------------------------------------------------------------------------
pragma ada_2005;

pragma warnings( off ); -- suppress Gnat-specific package warning
with ada.command_line.environment;
pragma warnings( on );
with system,
    ada.text_io,
    ada.command_line,
    ada.strings.unbounded.text_io,
    ada.characters.handling,
    ada.numerics.float_random,
    ada.calendar,
    gnat.regexp,
    gnat.directory_operations,
    gnat.source_info,
    cgi,
    spar_os.exec,
    string_util,
    user_io,
    user_io.getline,
    script_io,
    performance_monitoring,
    reports.test,
    builtins,
    jobs,
    signal_flags,
    compiler,
    scanner,
    scanner.calendar,
    scanner_res,
    scanner_restypes,
    parser_params,
    parser_pragmas,
    parser_tio,
    parser_numerics,
    parser_cal,
    parser_pen,
    interpreter; -- circular relationship for breakout prompt
use ada.text_io,
    ada.command_line,
    ada.strings.unbounded,
    ada.strings.unbounded.text_io,
    ada.characters.handling,
    gnat.regexp,
    gnat.directory_operations,
    spar_os,
    spar_os.exec,
    user_io,
    script_io,
    string_util,
    performance_monitoring,
    reports.test,
    builtins,
    jobs,
    signal_flags,
    compiler,
    scanner,
    scanner.calendar,
    scanner_res,
    scanner_restypes,
    parser_params,
    parser_pragmas,
    parser_tio,
    parser_numerics,
    parser_cal,
    parser_pen,
    interpreter; -- circular relationship for breakout prompt

package body parser is

-- some string literals converted to unbounded strings for efficiency

lowercase_l : unbounded_string := to_unbounded_string( "l" );
uppercase_o : unbounded_string := to_unbounded_string( "O" );

-- NON-MEANINGFUL WORDS
--
-- This is a list of vague, ambiguous words that don't make good variable or
-- function names.  Traditional words like "foobar" are deliberately not in
-- this list because they are often used in examples.  "result" is often
-- used in functions so is not included.

nonmeaningful_words : unbounded_string := to_unbounded_string( " blah amount asset assets const data func proc equals info input output parm param parms params stuff that thing things this whatever whatnot whatsoever value values variable variables " );

-- CONFUSING PROGRAM WORDS
--
-- These are words that, if used as the name of a program, will result in
-- confusion.  This means names that are also Linux/UNIX commands.  "Test"
-- is especially bad since typing "test" (the Linux command) results in
-- no output, making it look like the program didn't run.

confusingprogram_words : unbounded_string := to_unbounded_string( " eval exec read test " );

chain_count_str : unbounded_string := to_unbounded_string( "chain count" );
last_in_chain_str : unbounded_string := to_unbounded_string( "last in chain" );

---------------------------------------------------------
-- START OF ADASCRIPT PARSER
---------------------------------------------------------

procedure ParseBasicShellWord( shell_word : out unbounded_string ) is
  -- Check token for a shell word.  Even though this is called "parse",
  -- don't to getNextToken as the shell word hasn't been expanded yet
  -- and errors have yet to be reported against the token.
begin
  shell_word := null_unbounded_string;
  if identifiers( token ).kind = command_t then   -- handle a command type
      shell_word := identifiers( token ).value.all;
      if syntax_check then
         identifiers( token ).wasReferenced := true;
      end if;
  elsif token = symbol_t then
     shell_word := identifiers( token ).value.all;
  elsif token = word_t then
     if head( identifiers( token ).value.all, 1 ) = "`" then
        err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "backquoted literal" ) );
     else
        shell_word := identifiers( token ).value.all;
     end if;
  elsif token = cd_t then
     shell_word := identifiers( token ).name;
  elsif token = clear_t then
     shell_word := identifiers( token ).name;
  elsif token = env_t then
     shell_word := identifiers( token ).name;
  elsif token = help_t then
     shell_word := identifiers( token ).name;
  elsif token = history_t then
     shell_word := identifiers( token ).name;
  elsif token = jobs_t then
     shell_word := identifiers( token ).name;
  elsif token = pwd_t then
     shell_word := identifiers( token ).name;
  elsif token = trace_t then
     shell_word := identifiers( token ).name;
  elsif token = unset_t then
     shell_word := identifiers( token ).name;
  elsif token = wait_t then
     shell_word := identifiers( token ).name;
  elsif token = alter_t then
     shell_word := identifiers( token ).name;
  elsif token = delete_t then
     shell_word := identifiers( token ).name;
  elsif token = insert_t then
     shell_word := identifiers( token ).name;
  elsif token = select_t then
     shell_word := identifiers( token ).name;
  elsif token = update_t then
     shell_word := identifiers( token ).name;
  elsif identifiers( token ).kind = new_t then
     shell_word := identifiers( token ).name;
     discardUnusedIdentifier( token );
  elsif token = number_t then
     err( optional_bold( "shell word") & " expected, not a " &
          optional_bold( "number" ) );
  elsif token = strlit_t then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "string literal" ) );
  elsif token = charlit_t then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "character literal" ) );
  -- This should be impossible as a backlit would be scanned as a word token
  --elsif token = backlit_t then
  --   err( optional_bold( "shell word" ) & " expected, not a " &
  --        optional_bold( "backquoted literal" ) );
  elsif token = eof_t then
     err( optional_bold( "shell word" ) & " or semi-colon expected. Possibly hidden by an unescaped '--'?" );
  elsif is_keyword( token ) then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "keyword" ) );
  elsif identifiers( token ).field_of /= eof_t then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "field of a record type" ) );
  else
     err( "shell word expected" );
  end if;
  --if identifiers( token ).kind /= new_t then
    --else
      -- err( "shell word expected" );
    --end if;
end ParseBasicShellWord;

procedure ParseFieldIdentifier( record_id : identifier; id : out identifier ) is
  -- Expect a new identifier, or one declared in this scope, but
  -- if one from another scope it will need to be redeclared in
  -- this scope.  Use this for record fields that might possibly
  -- be already declared in a different scope.
  --   The problem is that a field variable has a name of "r.f" not "f" as it
  -- appears in the source code.  When testing for existence, we need to
  -- use the full name of the field variable.
  fieldName : unbounded_string;
  temp_id   : identifier;
begin
  id := eof_t; -- dummy
  if identifiers( token ).kind /= new_t then
     if token = number_t then
        err( optional_bold( "identifier") & " expected, not a " &
             optional_bold( "number" ) );
     elsif token = strlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "string literal" ) );
     elsif token = charlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "character literal" ) );
     elsif token = backlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "backquoted literal" ) );
     elsif token = word_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "(shell immediate) word" ) );
     elsif token = eof_t then
        err( optional_bold( "identifier" ) & " expected" );
     elsif is_keyword( token ) then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "keyword" ) );
     elsif token = symbol_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "symbol" ) );
     elsif identifiers( token ).field_of /= eof_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "field of a record type" ) );
     else
        -- an existing token name
        fieldName := identifiers( record_id ).name & "." & identifiers( token ).name;
        findIdent( fieldName, temp_id );
        if temp_id /= eof_t then
           err( "already declared " &
                optional_bold( to_string( fieldName ) ) );
        else                                                     -- declare it
           declareIdent( id, fieldName, new_t, varClass );
        end if;
     end if;
     getNextToken;
  else
     -- a new token
     fieldName := identifiers( record_id ).name & "." & identifiers( token ).name;
     findIdent( fieldName, temp_id );
     if temp_id /= eof_t then
        err( "already declared " &
             optional_bold( to_string( fieldName ) ) );
     else                                                     -- declare it
        discardUnusedIdentifier( token );
        declareIdent( id, fieldName, new_t, varClass );
     end if;
     getNextToken;
  end if;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
  token := eof_t; -- this exception cannot be handled
  done := true;   -- abort
end ParseFieldIdentifier;

procedure ParseProcedureIdentifier( id : out identifier ) is
  -- Expect a new identifier, or one declared in this scope, but
  -- if one from another scope it will need to be redeclared in
  -- this scope.  Use this for procedure names that might possibly
  -- be declared "forward".
  -- Also used for record field variables where the variables may
  -- be declared in a different scope.
begin
  id := eof_t; -- dummy
  if identifiers( token ).kind /= new_t then
     if token = number_t then
        err( optional_bold( "identifier") & " expected, not a " &
             optional_bold( "number" ) );
     elsif token = strlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "string literal" ) );
     elsif token = charlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "character literal" ) );
     elsif token = backlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "backquoted literal" ) );
     elsif token = word_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "(shell immediate) word" ) );
     elsif token = eof_t then
        err( optional_bold( "identifier" ) & " expected" );
     elsif is_keyword( token ) then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "keyword" ) );
     elsif token = symbol_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "symbol" ) );
     elsif identifiers( token ).field_of /= eof_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "field of a record type" ) );
     -- if old, don't redeclare if it was a forward declaration
     elsif identifiers( token ).class = userProcClass then       -- a proc?
        if isLocal( token ) then                                 -- local?
           if length( identifiers( token ).value.all ) = 0 then      -- forward?
              id := token;                                       -- then it's
           else                                                  -- not fwd?
              err( "already declared " &
                   optional_bold( to_string( identifiers( token ).name ) ) );
           end if;                                               -- not local?
        else                                                     -- declare it
           declareIdent( id, identifiers( token ).name, identifiers( token ).kind,
           identifiers( token ).class);
        end if;                                                  -- otherwise
     elsif isLocal( token ) then
        err( "already declared " &
             optional_bold( to_string( identifiers( token ).name ) ) );
     else
        -- create a new one in this scope
        declareIdent( id, identifiers( token ).name, identifiers( token ).kind,
        identifiers( token ).class);
     end if;
     getNextToken;
  else
     id := token;

     -- Procedure / Function style checks

     if length( identifiers(id).name ) < 3 then
        err( optional_bold( "style issue: " & to_string( identifiers(id).name ) ) & ", a procedure/function name, should contain 3 or more characters" );
     end if;

     getNextToken;

  end if;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
  token := eof_t; -- this exception cannot be handled
  done := true;   -- abort
end ParseProcedureIdentifier;

procedure ParseNewIdentifier( id : out identifier ) is
  -- expect a token that is a new, not previously declared identifier
  -- or one previously declared in a different scope that must be re-declared
  -- in this scope
begin
  id := eof_t; -- dummy
  if identifiers( token ).kind /= new_t then
     if token = number_t then
        err( optional_bold( "identifier") & " expected, not a " &
             optional_bold( "number" ) );
     elsif token = strlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "string literal" ) );
     elsif token = backlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "backquoted literal" ) );
     elsif token = charlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "character literal" ) );
     elsif token = word_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "(shell immediate) word" ) );
     elsif token = eof_t then
        err( optional_bold( "identifier" ) & " expected" );
     elsif is_keyword( token ) and token /= eof_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "keyword" ) );
     elsif token = symbol_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "symbol" ) );
     elsif isLocal( token ) then
        err( "already declared " &
             optional_bold( to_string( identifiers( token ).name ) ) );
     elsif element( identifiers( token ).name,
         length( identifiers( token ).name ) ) = '_' then
            err( "trailing underscores not allowed in identifiers" );
     else
        -- create a new one in this scope
        declareIdent( id, identifiers( token ).name, new_t, varClass );
     end if;
     getNextToken;
  else
     id := token;
     declare
        nameAsLower : unbounded_string := " " & toLower( identifiers(id).name ) & " ";
     begin
        -- if in a script, prohibit "l" and "O" as identifier names
        if inputMode /= interactive and inputMode /= breakout then
           if identifiers( id ).name = lowercase_l then
              err( "style issue: name lowercase " & optional_bold( "l" ) & " can be confused with the number one" );
           elsif identifiers( id ).name = uppercase_o then
              err( "style issue: name uppercase " & optional_bold( "O" ) & " can be confused with the number zero" );
           end if;
        end if;
        if index( nonmeaningful_words, to_string( nameAsLower ) ) > 0 then
           err( "style issue:  name " & optional_bold( to_string( identifiers(id).name ) ) & " may not be descriptive or meaningful" );
        elsif index( reserved_words, to_string( nameAsLower ) ) > 0 then
            err( "style issue: name " & optional_bold( to_string( identifiers(id).name ) ) & " is similar to a reserved keyword" );
        end if;
     end;
     getNextToken;
  end if;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
  token := eof_t; -- this exception cannot be handled
  done := true;   -- abort
end ParseNewIdentifier;

procedure ParseIdentifier( id : out identifier ) is
  -- expect a  previously declared identifier
  recId : identifier;
begin
  id := eof_t; -- assume failure
  if token = number_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "number" ) );
  elsif token = strlit_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "string literal" ) );
  elsif token = backlit_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "backquoted literal" ) );
  elsif token = charlit_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "character literal" ) );
  elsif token = word_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "(shell immediate) word" ) );
  elsif is_keyword( token ) and token /= eof_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "keyword" ) );
  elsif token = symbol_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "symbol" ) );
  elsif identifiers( token ).kind = new_t or identifiers( token ).deleted then
     -- if we're skipping a block, it doesn't matter if the identifier is
     -- declared, but it does if we're executing a block or checking syntax
     if isExecutingCommand or syntax_check then
        for i in identifiers'first..identifiers_top-1 loop
            if i /= token and not identifiers(i).deleted then
               if typoOf( identifiers(i).name, identifiers(token).name ) then
                  discardUnusedIdentifier( token );
                  err( optional_bold( to_string( identifiers(token).name ) ) &
                  " is a possible typo of " &
                  optional_bold( to_string( identifiers(i).name ) ) );
                  exit;
               end if;
           end if;
       end loop;
       if not error_found then
          -- token will be eof_t if error has already occurred
          discardUnusedIdentifier( token );
          -- help for common mistakes
          -- php/shell - checking for echo/print doesn't work since these
          -- are Linux commands anyway and will be found.  Code removed.
          err( optional_bold( to_string( identifiers( token ).name ) ) & " not declared" );
       end if;
     end if;
     -- this only appears if err in typo loop didn't occur
     --if not error_found then
     --   discardUnusedIdentifier( token );
     --end if;
  else
     if syntax_check and then not error_found then
           -- for a record field, mark the record itself as used.
           -- record fields are ignored in the unused identifier checks.
           -- also do this for writing since it is hard to determine if
           -- all record fields have been written to.
           --
           -- rather than eof, precaution against unexpected values
           recId := identifiers( token ).field_of;
           -- TODO: this could be more efficient
           if recId in reserved_top..identifiers'last then
              identifiers( recId ).wasReferenced := true;
           else
              -- mark the value as used because it was referred to
              identifiers( token ).wasReferenced := true;
           end if;
     end if;
     id := token;
  end if;
  getNextToken;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
  token := eof_t; -- this exception cannot be handled
  done := true;   -- abort
end ParseIdentifier;

procedure ParseStaticIdentifier( id : out identifier ) is
  -- expect a previously declared static identifier
begin
  id := eof_t; -- assume failure
  if token = number_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "number" ) );
  elsif token = strlit_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "string literal" ) );
  elsif token = backlit_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "backquoted literal" ) );
  elsif token = charlit_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "character literal" ) );
  elsif token = word_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "(shell immediate) word" ) );
  elsif is_keyword( token ) and token /= eof_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "keyword" ) );
  elsif token = symbol_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "symbol" ) );
  elsif identifiers( token ).kind = new_t or identifiers( token ).deleted then
     -- if we're skipping a block, it doesn't matter if the identifier is
     -- declared, but it does if we're executing a block or checking syntax
     if isExecutingCommand or syntax_check then
        for i in identifiers'first..identifiers_top-1 loop
            if i /= token and not identifiers(i).deleted then
               if typoOf( identifiers(i).name, identifiers(token).name ) then
                  discardUnusedIdentifier( token );
                  err( optional_bold( to_string( identifiers(token).name ) ) &
                  " is a possible typo of " &
                  optional_bold( to_string( identifiers(i).name ) ) );
                  exit;
               end if;
           end if;
       end loop;
       if not error_found then
          -- token will be eof_t if error has already occurred
          discardUnusedIdentifier( token );
          err( optional_bold( to_string( identifiers( token ).name ) ) & " not declared or is not static" );
       end if;
     end if;
     -- this only appears if err in typo loop didn't occur
     --if not error_found then
     --   discardUnusedIdentifier( token );
     --end if;
  else
     if syntax_check then
           -- for declared but not used checking, assign a value of "REF" to
           -- the value (during syntax check only because value is otherwise
           -- unused).  When blocks are pulled, this will be checked.
           identifiers( token ).wasReferenced := true;
     end if;
     id := token;
  end if;
  getNextToken;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
  token := eof_t; -- this exception cannot be handled
  done := true;   -- abort
end ParseStaticIdentifier;

procedure DoUserDefinedFunction( s : unbounded_string; result : out unbounded_string );
-- forward declaration

procedure ParseAcceptBlock;


-- DO CONTRACTS
--
-- Check for and execute a type's accept clauses.  Use recursion to move to
-- the distant ancenstor type, then return, applying the clauses, ending
-- with the clause on the type itself.  If no clause exists, do nothing.
--
-- kind_id is the data type.
-- expr_val is the value to be tested for that type

procedure DoContracts( kind_id : identifier; expr_val : in out unbounded_string ) is
   type_value_id : identifier;

   -- DO CONTRACT1
   --
   -- The inner recursive procedure.

   procedure DoContract1( kind_id : identifier; expr_val : in out unbounded_string ) is
      scriptState : aScriptState;
   begin
      if identifiers( kind_id ).kind /= variable_t then    -- not uni?
         -- Cannot do DoContract1 because type identifier will change
         -- So switched it to DoContracts
         DoContracts( identifiers( kind_id ).kind, expr_val ); -- parents first
      end if;
      if identifiers( kind_id ).contract /= "" then        -- a contract?
         if trace then                                     -- trace message
            put_trace( to_string( identifiers( kind_id ).name ) & " accept clause" );
         end if;
         parseNewCommands( scriptState,
           identifiers( kind_id ).contract,
           fragment => true );                           -- setup byte code
         ParseAcceptBlock;
         expectSemicolon;
         if not done then                                  -- not done?
            expect( eof_t );                               -- should be eof
         end if;
         restoreScript( scriptState );            -- restore original script
      end if;
   end DoContract1;

begin

   -- Create a new block, declaring the data type variable
   -- We don't need to assign the value until we know we're executing.

   pushBlock( newScope => true, newName => "accept clause" );
   declareIdent( type_value_id, identifiers( kind_id ).name, kind_id );

   if isExecutingCommand then
--put_line( "Starting Contract for value " & to_string( expr_val ) ); -- DEBUG
--put_line( "Kind_id = " & kind_id'img ); -- DEBUG
--put_line( to_string( identifiers( type_value_id ).name ) & " = " & type_value_id'img ); -- DEBUG

      -- Disallow undefined or end_of_file tokens as a precaution.
      -- Otherwise, assign the value to the variable and apply contracts.

      if kind_id /= new_t and kind_id /= eof_t then
         identifiers( type_value_id ).value.all := expr_val;
         DoContract1( kind_id, expr_val );
      end if;

      -- If the validation function altered the data, return the new value
      -- for the data.
      -- We can't relay on wasWritten since it only applies to syntax checks.

--put_trace( "end of contract, value is " & to_string( toEscaped( expr_val ) ) ); -- DEBUG
--put_trace( "type_value is " & to_string( identifiers( type_value_id ).value.all ) ); -- DEBUG
--put_trace( "type_value written " & identifiers( type_value_id ).wasWritten'img ); -- DEBUG
      --if identifiers( type_value_id ).wasWritten then

      -- Copying a value is not so easy for an array
      expr_val := identifiers( type_value_id ).value.all;
      if trace then                                     -- trace message
         put_trace( "value after accept clause: " & to_string( toEscaped( expr_val ) ) );
      end if;
      --end if;
   end if;

   -- Tear down accept function block

   pullBlock;
end DoContracts;


-----------------------------------------------------------------------------
-- Expressions
-----------------------------------------------------------------------------

-- These don't seem to help much.
--pragma inline( ParsePowerTermOperator );
--pragma inline( ParseTermOperator );
--pragma inline( ParseSimpleExpressionOperator );
--pragma inline( ParseRelationalOperator );
--pragma inline( ParseExpressionOperator );

procedure ParseFactor( f : out unbounded_string; kind : out identifier ) is
  -- Syntax: factor = (expr) | "strlit" | numeric-lit | identifier | built-in fn
  -- if the identifier is volatile, reload the value from the environment
  castType  : identifier;
  array_id  : identifier;
  -- array_id2 : arrayID;
  arrayIndex: long_integer;
  type aUniOp is ( noOp, doPlus, doMinus, doNot );
  uniOp : aUniOp := noOp;
  t : identifier;

  procedure ParseFactorIdentifier is
  begin
    ParseIdentifier( t );
    if identifiers( t ).volatile then           -- volatile user identifier
       refreshVolatile( t );
       f := identifiers( t ).value.all;
       kind := identifiers( t ).kind;
    end if;
    if identifiers( t ).class = subClass or             -- type cast
       identifiers( t ).class = typeClass then
       -- this will change when arrays can have derived types.
       if identifiers( getBaseType( t ) ).list then
          err( optional_bold( to_string( identifiers( t ).name ) ) & " is an array type" );
       end if;                               -- represent array types
       castType := t;                        -- in expressiosn (yet)
       expect( symbol_t, "(" );
       ParseExpression( f, kind );
       expect( symbol_t, ")" );
       if uniTypesOk( castType, kind ) then
          kind := castType;
          if isExecutingCommand then
             f := castToType( f, kind );
             DoContracts( kind, f );
          end if;
       end if;
    elsif identifiers( t ).usage = limitedUsage then
       err( "limited variables cannot be used in an expression (or you may have spelled a subprogram name incorrectly)" );
       kind := eof_t;
    elsif identifiers( getBaseType( t ) ).list then        -- array(index)?
       array_id := t;                            -- array_id=array variable
       expect( symbol_t, "(" );                  -- parse index part
       ParseExpression( f, kind );               -- kind is the index type
       if getUniType( kind ) = uni_string_t or   -- index must be scalar
          getUniType( kind ) = root_record_t or
          identifiers( getBaseType( kind ) ).list then
          err( "array index must be a scalar type" );
       end if;                                   -- variables are not
       if isExecutingCommand then                -- declared in syntax chk
          arrayIndex := long_integer(to_numeric(f));  -- convert to number
          --array_id2 := arrayID( to_numeric(      -- array_id2=reference
          --   identifiers( array_id ).value ) );  -- to the array table
          --if indexTypeOK( array_id2, kind ) then -- check and access array
          --    if inBounds( array_id2, arrayIndex ) then
          --       f := arrayElement( array_id2, arrayIndex );
          --    end if;
          --end if;
          -- TODO: make a utility function for doing all this.
          -- TODO: probably needs a better error message
          if baseTypesOK( identifiers( array_id ).genKind, kind ) then
             if arrayIndex not in identifiers( array_id ).avalue'range then -- DEBUG
                err( "array index " &  to_string( trim( f, ada.strings.both ) ) & " not in" & identifiers( array_id ).avalue'first'img & " .." & identifiers( array_id ).avalue'last'img );
             end if;
          end if;
          if not error_found then
             begin
               f := identifiers( array_id ).avalue( arrayIndex ); -- NEWARRAY
             exception when CONSTRAINT_ERROR =>
               err( gnat.source_info.source_location &
                ": internal error: constraint_error : index out of range " &
                identifiers( array_id ).avalue'first'img & " .." &
                identifiers( array_id ).avalue'last'img );
             when STORAGE_ERROR =>
               err( gnat.source_info.source_location &
                ": internal error : storage error raised in ParseFactor" );
             end;
          end if;
       elsif syntax_check then
          identifiers( array_id ).wasFactor := true;
       end if;
       expect( symbol_t, ")" );                  -- element type is k's k
       kind := identifiers( identifiers( array_id ).kind ).kind;
    -- regular variable with an array index?
    else
       if identifiers( t ).field_of /= eof_t then
         if identifiers( identifiers( t ).field_of ).usage = limitedUsage then
            err( "limited record variables cannot be used in an expression" );
         end if;
       end if;
       if token = symbol_t and then identifiers( token ).value.all = "(" then
         err( optional_bold( to_string( identifiers( t ).name ) ) &
             " has an array index but is not an array" );
       end if;
       f := identifiers( t ).value.all;
       kind := identifiers( t ).kind;
       -- Mark as used as a factor.  if it is a record field, mark the whole
       -- record as used as a factor for limit type testing purposes.
       if syntax_check then
          if t /= eof_t then
             identifiers( t ).wasFactor := true;
             if identifiers( t ).field_of /= eof_t then
                identifiers( identifiers( t ).field_of ).wasFactor := true;
             end if;
          end if;
       end if;
    end if;
  end parseFactorIdentifier;
  pragma inline( parseFactorIdentifier );

begin
  if Token = symbol_t and identifiers( Token ).value.all = "+" then
     uniOp := doPlus;
     getNextToken;
  elsif Token = symbol_t and identifiers( Token ).value.all = "-" then
     uniOp := doMinus;
     getNextToken;
  elsif Token = not_t then
     uniOp := doNot;
     getNextToken;
  end if;
  if Token = symbol_t and then identifiers( Token ).value.all = "(" then
     expect( symbol_t, "(" );
     ParseExpression( f, kind );
     expect( symbol_t, ")" );
  -- to speed things up, these wide if statements break up tokens into
  -- categories.  If the token isn't in the category, skip the rest.
  elsif token < reserved_top then
     if Token = symbol_t and then identifiers( Token ).value.all = "$?" then
        f := to_unbounded_string( last_status'img );
        kind := uni_numeric_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "$$" then
        f := to_unbounded_string( aPID'image( getpid ) );
        kind := uni_numeric_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "$#" then
        if onlyAda95 then
           err( "$# not allowed with " & optional_bold( "pragma ada_95" ) &
           " -- use command_line package" );
        end if;
        if isExecutingCommand then
           f := to_unbounded_string( integer'image( Argument_Count-optionOffset) );
        end if;
        kind := uni_numeric_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all >= "$1" and then
        identifiers( Token ).value.all <= "$9" then
        -- this could be done a little tighter (ie length check)
        if onlyAda95 then
           err( "$1..$9 not allowed with " & optional_bold( "pragma ada_95" ) &
           " -- use command_line package" );
        end if;
        kind := uni_string_t;
        if isExecutingCommand then
           begin
              f := to_unbounded_string(
                 Argument(
                   integer'value(
                   "" & Element( identifiers( Token ).value.all, 2 ) )+optionOffset ) );
           exception when program_error =>
              err( "program_error exception raised" );
              kind := eof_t;
           when others =>
              err( "no such argument" );
              kind := eof_t;
           end;
        end if;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "$0" then
        if onlyAda95 then
           err( "$0 not allowed with " & optional_bold( "pragma ada_95" ) &
           " -- use command_line package" );
        end if;
        if isExecutingCommand then
           f := to_unbounded_string( Ada.Command_Line.Command_Name );
        end if;
        kind := uni_string_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "@" then
        if onlyAda95 then
           err( "@ is not allowed with " & optional_bold( "pragma ada_95" ) );
           f := null_unbounded_string;
           kind := eof_t;
        elsif itself_type = new_t then
           err( "@ is not defined" );
           f := null_unbounded_string;
           kind := eof_t;
        elsif identifiers( itself_type ).class = procClass then
           err( "@ is not a variable" );
        else
           f := itself;
           kind := itself_type;
        end if;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "%" then
        if onlyAda95 then
           err( "% is not allowed with " & optional_bold( "pragma ada_95" ) );
           f := null_unbounded_string;
           kind := eof_t;
        elsif syntax_check then             -- % depends on run-time
           f := to_unbounded_string( "0" ); -- so just use a dummy
           kind := universal_t;             -- typeless value
        else
           if last_output_type = eof_t then
              err( "there has been no output assigned to %" );
           else
              f := last_output;
           end if;
           kind := last_output_type;
        end if;
        getNextToken;
     elsif token = number_t then                           -- numeric literal
        f := identifiers( token ).value.all;
        kind := identifiers( token ).kind;
        getNextToken;
     elsif token = charlit_t then                          -- character literal
        --if length( identifiers( charlit_t ).value ) > 1 then
        --   err( "character literal more than 1 character" );
        --end if;
        f := identifiers( token ).value.all;
        kind := identifiers( token ).kind;
        getNextToken;
     elsif token = strlit_t then                           -- string literal
        f := identifiers( token ).value.all;
        kind := identifiers( token ).kind;
        getNextToken;
     elsif token = backlit_t then           -- `cmds`
        kind := identifiers( token ).kind;
        CompileRunAndCaptureOutput( identifiers( token ).value.all, f, getLineNo );
        getNextToken;
     elsif token = abs_t then                             -- abs function
        ParseNumericsAbs( f );
        kind := uni_numeric_t;
     else
        f := null_unbounded_string;                -- (always return something)
        kind := eof_t;
        err( "operand expected" );
     end if;
     -- Another board category, is the token a pre-defined idenifier?
  elsif token < predefined_top then
     if identifiers( token ).funcCB /= null then         -- a built-in function?
        identifiers( token ).funcCB.all( f, kind );        -- run it
     elsif token = is_open_t then                         -- is_open function
        ParseIsOpen( t );
        if isExecutingCommand then
           f := identifiers( t ).value.all;
        end if;
        kind := boolean_t;
     elsif token = source_info_symbol_table_size_t then   -- Symbol_Table_Sz
        getNextToken;
        if onlyAda95 then
           err( "symbol_table_size is not allowed with " &
              optional_bold( "pragma ada_95" ) );
           f := null_unbounded_string;
           kind := eof_t;
        else
          f := delete( to_unbounded_string( identifier'image( identifiers_top-1 )), 1, 1 );
          kind := natural_t;
        end if;
     elsif token = source_info_file_t then                -- source_info.file
        f := basename( getSourceFileName );
        kind := string_t;
        getNextToken;
     elsif token = source_info_line_t then                -- source_info.line
        f := to_unbounded_string( getLineNo'img );
        kind := positive_t;
        getNextToken;
     elsif token = source_info_src_loc_t then      -- source_info.source_loc.
        f := to_unbounded_string( getLineNo'img );
        f := basename( getSourceFileName ) & ":" & f;
        kind := string_t;
        getNextToken;
     elsif token = source_info_enc_ent_t then      -- source_info.enclosing.
        if blocks_top > block'First then
           f := getBlockName( block'First );
        else
           f := to_unbounded_string( "script" );
        end if;
        kind := string_t;
        getNextToken;
     else
        -- System package constants, etc.
        ParseFactorIdentifier;
     end if;
  elsif identifiers( token ).class = userFuncClass then  -- a user function?
     declare
       funcToken : identifier := token;
     begin
       DoUserDefinedFunction( identifiers( funcToken ).value.all, f );
       kind := identifiers( funcToken ).kind;
     end;
  elsif identifiers( token ).kind = keyword_t then      -- no keywords
     f := null_unbounded_string;                        -- (always return something)
     kind := universal_t;
     err( "variable, value or expression expected" );
  else                                                  -- a user ident?
     ParseFactorIdentifier;
  end if;
  case uniOp is
  when noOp => null;
  when doPlus =>
       if baseTypesOk( kind, uni_numeric_t ) then
          null;
       end if;
  when doMinus =>
       begin
          if baseTypesOk( kind, uni_numeric_t ) then
             if isExecutingCommand then
                f := to_unbounded_string( -to_numeric( f ) );
             end if;
          end if;
       exception when others =>
          err_exception_raised;
       end;
  when doNot =>
       begin
          if baseTypesOk( kind, boolean_t ) then
             if isExecutingCommand then
                if to_numeric( f ) = 1.0 then
                   f := to_unbounded_string( "0" );
                else
                   f := to_unbounded_string( "1" );
                end if;
             end if;
          end if;
       exception when others =>
          err_exception_raised;
       end;
  when others =>
      f := null_unbounded_string;                -- (always return something)
      kind := eof_t;
      err( "internal error: unexpected uniary operation error" );
  end case;
end ParseFactor;

procedure ParsePowerTermOperator( op : out unbounded_string ) is
-- Syntax: termop = "**"
begin
  -- token value is checked by parseTerm, but not token name
  if Token /= symbol_t then
     err( "operator expected");
  -- This is checked by parseTerm
  --elsif identifiers( Token ).value.all /= "**" then
  --   err( "** operator expected");
  else
     op := identifiers( token ).value.all;
  end if;
  getNextToken;
end ParsePowerTermOperator;

procedure ParsePowerTerm( term : out unbounded_string; term_type : out identifier ) is
  -- Syntax: term = "factor powerterm-op factor"
  factor1  : unbounded_string;
  factor2  : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : unbounded_string;
  operation: identifier;
begin
  ParseFactor( factor1, kind1 );
  term := factor1;
  term_type := kind1;
  while identifiers( Token ).value.all = "**" loop
     ParsePowerTermOperator( operator );
     ParseFactor( factor2, kind2 );
     if baseTypesOk( kind1, kind2 ) then
        term_type := getBaseType( kind1 );
        operation := getUniType( kind1 );
        if operation = universal_t then
           operation := getUniType( kind2 );
        end if;
        if operation = universal_t then
           operation := uni_string_t;
        end if;
        if operation = uni_numeric_t then
           if operator = "**" then
              begin
                 if isExecutingCommand then
                    term := to_unbounded_string(
                         to_numeric( term ) **
                         natural( to_numeric( factor2 ) ) );
                 end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 term := null_unbounded_string;
              when others =>
                 err_exception_raised;
                 term := null_unbounded_string;
              end;
          else
              err( "interal error: unknown power operator" );
          end if;
        else
           err( "operation ** not defined for these types" );
        end if;
     end if;
  end loop;
end ParsePowerTerm;

procedure ParseTermOperator( op : out unbounded_string ) is
  -- Syntax: termop = '*' | '/' | '&'
begin
  -- token value is checked by parseTerm, but not token name
  if Token = mod_t or Token = rem_t then
     op := identifiers( token ).name;
  elsif Token /= symbol_t then
     err( "operator expected");
  elsif identifiers( Token ).value.all /= "*" and identifiers( Token ).value.all /= "/" and identifiers( Token ).value.all /= "&" then
     err( "term operator expected");
  else
     op := identifiers( token ).value.all;
  end if;
  getNextToken;
end ParseTermOperator;

procedure ParseTerm( term : out unbounded_string; term_type : out identifier ) is
  -- Syntax: term = "powerterm term-op powerterm"
  pterm1   : unbounded_string;
  pterm2   : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : unbounded_string;
  operation: identifier;
begin
  ParsePowerTerm( pterm1, kind1 );
  term := pterm1;
  term_type := kind1;
  while identifiers( Token ).value.all = "*" or
        identifiers( Token ).value.all = "/" or
        identifiers( Token ).value.all = "&" or
        Token = mod_t or Token = rem_t loop
     ParseTermOperator( operator );
     ParsePowerTerm( pterm2, kind2 );
     term_type := getBaseType( kind2 );
     operation := getUniType( kind2 );
     if operation = universal_t then
        operation := getUniType( kind1 );
     end if;
     if operation = universal_t then
        operation := uni_string_t;
     end if;
     if operation = uni_numeric_t then
        if baseTypesOk( kind1, kind2 ) then
             if operator = "*" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        to_numeric( term ) *
                        to_numeric( pterm2 ),
                     term_type );
                  end if;
                 exception when program_error =>
                    err( "program_error exception raised" );
                    term := null_unbounded_string;
                 when others =>
                    err_exception_raised;
                    term := null_unbounded_string;
                 end;
             elsif operator = "/" then
                declare
                  t : long_float;
                  p : long_float;
                  z : long_float := 0.0;
                begin
                  if isExecutingCommand then
                     -- GCC Ada 4.7.1 doesn't catch divide by zero (returns
                     -- infinity for the following division:
                     -- term := castToType(
                     --   to_numeric( term ) /
                     --   to_numeric( pterm2 ),
                     --term_type );
                     -- As a kludge, we'll break up this function call into
                     -- its parts and explicitly test for division by zero.
                     -- this could likely be improved.
                     t := to_numeric( term );
                     p := to_numeric( pterm2 );
                     if p = 0.0 then
                        err( "division by zero" );
                     else
                        z := t / p;
                        term := castToType( z, term_type );
                     end if;
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   term := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   term := null_unbounded_string;
                end;
             elsif operator = "mod" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        --long_long_integer'image(
                        long_float(
                        long_long_integer( to_numeric( term ) ) mod
                        long_long_integer( to_numeric( pterm2 ) ) ),
                     term_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   term := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   term := null_unbounded_string;
                end;
             elsif operator = "rem" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        --long_long_integer'image(
                        long_float(
                        long_long_integer( to_numeric( term ) ) rem
                        long_long_integer( to_numeric( pterm2 ) ) ),
                     term_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   term := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   term := null_unbounded_string;
                end;
             else
                err( gnat.source_info.source_location &
                   ": Internal error: unable to handle term operator" );
             end if;
           end if;
        elsif operation = uni_string_t then
           declare
             base1 : identifier := getBaseType( kind1 );
             base2 : identifier := getBaseType( kind2 );
             uni1  : identifier := getUniType( kind1 );
             uni2  : identifier := getUniType( kind2 );
           begin
              if operator = "&" then
                 if base1 = character_t and base2 = character_t then
                    kind1 := string_t;
                    kind2 := string_t;
                    term_type := string_t;
                 elsif base1 = character_t and uni2 = uni_string_t then
                    kind1 := kind2;
                 elsif uni1 = uni_string_t and base2 = character_t then
                    kind2 := kind1;
                    term_type := kind1;
                 end if;
                 if baseTypesOk( kind1, kind2 ) then
                    if isExecutingCommand then
                       term := term & pterm2;
                    end if;
                 end if;
              elsif operator = "*" then
                 if baseTypesOk( kind1, natural_t ) then
                    if baseTypesOk( kind2, uni_string_t ) then
                       if isExecutingCommand then
                          term := natural( to_numeric( term ) ) * pterm2;
                       end if;
                    end if;
                 end if;
              else
                 err( "operation not defined for string types" );
              end if;
           exception when program_error =>
              err( "program_error exception raised" );
              term := null_unbounded_string;
           when others =>
              err_exception_raised;
              term := null_unbounded_string;
           end;
        else
           if operator = "*" then
              err( "operation * not defined for these types" );
           elsif operator = "/" then
              err( "operation / not defined for these types" );
           elsif operator = "&" then
              err( "operation & not defined for these types" );
           end if;
        end if;
  end loop;
end ParseTerm;

procedure ParseSimpleExpressionOperator( op : out unbounded_string ) is
  -- Syntax: simple-expr-op = '+' | '-'
begin
  -- token value is checked by parseTerm, but not token name
  if Token /= symbol_t then
     err( "operator expected");
  elsif identifiers( Token ).value.all /= "+" and identifiers( Token ).value.all /= "-" then
     err( "simple expression operator expected");
  end if;
  op := identifiers( token ).value.all;
  getNextToken;
end ParseSimpleExpressionOperator;

procedure ParseSimpleExpression( se : out unbounded_string; expr_type : out identifier ) is
  -- Syntax: term = "term expr-op term"
  term1    : unbounded_string;
  term2    : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : unbounded_string;
  operation: identifier;
  typesOK  : boolean := false;
begin
  ParseTerm( term1, kind1 );
  se := term1;
  expr_type := kind1;
  while identifiers( Token ).value.all = "+" or identifiers( Token ).value.all = "-" loop
     ParseSimpleExpressionOperator( operator );
     ParseTerm( term2, kind2 );
     -- Special exception for + and -...allow time arithmetic
     if (kind1 = cal_time_t) and then (getBaseType(kind2) = duration_t or kind2 = uni_numeric_t or kind2 = universal_t) then
        typesOK := true;
        expr_type := cal_time_t;
        operation := cal_time_t;
     elsif (kind2 = cal_time_t) and then (getBaseType(kind1) = duration_t or kind1 = uni_numeric_t or kind2 = universal_t) then
        typesOK := true;
        expr_type := cal_time_t;
        operation := variable_t; -- representing time on right
     elsif (kind1 = cal_time_t) and then (getBaseType(kind2) = cal_time_t) then
        if operator = "+" then
           typesOK := true;
           expr_type := cal_time_t;
        else
           typesOK := true;
           expr_type := duration_t;
        end if;
        operation := root_record_t; -- representing time on both side
     end if;
     -- Otherwise check the types normally
     if not typesOK then
        typesOK := baseTypesOk( kind1, kind2 );
        expr_type := getBaseType( kind1 );
        operation := getUniType( kind1 );
     end if;
     if typesOk then
        if operation = universal_t then
           operation := getUniType( kind2 );
        end if;
        if operation = universal_t then
           operation := uni_string_t;
        end if;
        if operation = uni_numeric_t then
             if operator = "+" then
                begin
                  if isExecutingCommand then
                     se := castToType(
                        to_numeric( se ) +
                        to_numeric( term2 ),
                     expr_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   se := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   se := null_unbounded_string;
                end;
             elsif operator = "-" then
                begin
                  if isExecutingCommand then
                     se := castToType(
                        to_numeric( se ) -
                        to_numeric( term2 ),
                     expr_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   se := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   se := null_unbounded_string;
                end;
             end if;
        elsif operation = cal_time_t then -- time +/- duration
           if operator = "+" then
              if isExecutingCommand then
                 declare
                    c : scanner.calendar.time := scanner.calendar.time( to_numeric( se ) );
                 begin
                    c := c + duration( to_numeric( term2 ) );
                    se := to_unbounded_string( long_long_integer'image( long_long_integer( c ) ) );
                 end;
              end if;
           elsif operator = "-" then
              if isExecutingCommand then
                 declare
                    c : scanner.calendar.time := scanner.calendar.time( to_numeric( se ) );
                 begin
                    c := c - duration( to_numeric( term2 ) );
                    se := to_unbounded_string( long_long_integer'image( long_long_integer( c ) ) );
                 end;
              end if;
           end if;
        elsif operation = variable_t then -- duration + time
           if operator = "+" then
              if isExecutingCommand then
                 declare
                    c : scanner.calendar.time := scanner.calendar.time( to_numeric( term2 ) );
                 begin
                    c := duration( to_numeric( se ) ) + c;
                    se := to_unbounded_string( long_long_integer'image( long_long_integer( c ) ) );
                 end;
              end if;
           elsif operator = "-" then
              err( "operation - not defined for these types" );
           end if;
        elsif operation = root_record_t then -- adding times
           if operator = "+" then
              err( "operation + not defined for these types" );
           else
              if isExecutingCommand then
                 declare
                    c : scanner.calendar.time := scanner.calendar.time( to_numeric( se ) );
                    c2: duration;
                 begin
                    c2 := c - scanner.calendar.time( to_numeric( term2 ) );
                    se := to_unbounded_string( duration'image( c2 ) );
                 exception when time_error =>
                    err( "duration value too large or small" );
                 when constraint_error =>
                    err( "constraint error" );
                 end;
              end if;
           end if;
        else
             if operator = "+" then
                err( "operation + not defined for these types" );
             elsif operator = "-" then
                err( "operation - not defined for these types" );
             end if;
        end if;
     end if;
  end loop;
  --put_line( "Simple Expression value = " & to_string( se ) );
end ParseSimpleExpression;

procedure ParseRelationalOperator( op : out unbounded_string ) is
  -- Syntax: rel-op = >, >=, etc.
begin
  -- token value is checked by parseTerm, but not token name
  if Token /= symbol_t and Token /= in_t and Token /= not_t then
     err( "operator expected");
  elsif identifiers( Token ).value.all /= ">=" and
        identifiers( Token ).value.all /= ">" and
        identifiers( Token ).value.all /= "<" and
        identifiers( Token ).value.all /= "<=" and
        identifiers( Token ).value.all /= "=" and
        identifiers( Token ).value.all /= "/=" and
        Token /= in_t and Token /= not_t then
     err( "relational operator expected");
  end if;
  if Token = in_t then
     op := identifiers( token ).name;
  elsif Token = not_t then
     op := to_unbounded_string( "not in" );
     getNextToken;
     if Token /= in_t then
        err( "relational operator expected");
     end if;
  else
     op := identifiers( token ).value.all;
  end if;
  getNextToken;
end ParseRelationalOperator;

procedure ParseRelation( re : out unbounded_string; rel_type : out identifier ) is
  -- Syntax: relation = "simple-expr" =|>|<|... "simple-expr"
  se1      : unbounded_string;
  se2      : unbounded_string;
  se3      : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  kind3    : identifier;
  operator : unbounded_string;
  operation: identifier;
  b        : boolean;
begin
  ParseSimpleExpression( se1, kind1 );
  re := se1;
  rel_type := kind1;
  if identifiers( Token ).value.all = ">=" or
        identifiers( Token ).value.all = ">" or
        identifiers( Token ).value.all = "<" or
        identifiers( Token ).value.all = "<=" or
        identifiers( Token ).value.all = "=" or
        identifiers( Token ).value.all = "/=" or
        Token = in_t or Token = not_t then
     rel_type := boolean_t; -- always
     ParseRelationalOperator( operator );
     if operator = "in" or operator = "not in" then
        ParseFactor( se2, kind2 );
        if baseTypesOk( kind1, kind2 ) then -- redundant below but
           expect( symbol_t, ".." );        -- keeps error messages nice
           ParseFactor( se3, kind3 );       -- should probably restructure
           if baseTypesOk( kind2, kind3 ) then
              null;
           end if;
        end if;
     else
        ParseSimpleExpression( se2, kind2 );
     end if;
     if baseTypesOk( kind1, kind2 ) then
        operation := getUniType( kind1 );
        if operation = universal_t then
           operation := getUniType( kind2 );
        end if;
        if operation = universal_t then
           operation := uni_string_t;
        end if;
        if operation = uni_numeric_t or else operation = root_enumerated_t or else operation = cal_time_t then
             begin
               if operator = ">=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) >= to_numeric( se2 );
                  end if;
               elsif operator = ">" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) > to_numeric( se2 );
                  end if;
               elsif operator = "<" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) < to_numeric( se2 );
                  end if;
               elsif operator = "<=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) <= to_numeric( se2 );
                  end if;
               elsif operator = "=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) = to_numeric( se2 );
                  end if;
               elsif operator = "/=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) /= to_numeric( se2 );
                  end if;
               elsif operator = "in" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) in to_numeric( se2 )..to_numeric( se3 );
                  end if;
               elsif operator = "not in" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) not in to_numeric( se2 )..to_numeric( se3 );
                  end if;
               else
                  err( gnat.source_info.source_location &
                    ": Internal error: couldn't handle relational operator" );
               end if;
               if b then
                  re := to_unbounded_string( "1" );
               else
                  re := to_unbounded_string( "0" );
               end if;
             exception when others =>
               err_exception_raised;
             end;
        elsif operation = uni_string_t then
             if operator = ">=" then
                if isExecutingCommand then
                   b := se1 >= se2;
                end if;
             elsif operator = ">" then
                if isExecutingCommand then
                   b := se1 > se2;
                end if;
             elsif operator = "<" then
                if isExecutingCommand then
                   b := se1 < se2;
                end if;
             elsif operator = "<=" then
                if isExecutingCommand then
                   b := se1 <= se2;
                end if;
             elsif operator = "=" then
                if isExecutingCommand then
                   b := se1 = se2;
                end if;
             elsif operator = "/=" then
                if isExecutingCommand then
                   b := se1 /= se2;
                end if;
             elsif operator = "in" then
                if isExecutingCommand then
                   if length( se1 ) /= 1 or
                      length( se2 ) /= 1 or
                      length( se3 ) /= 1 then
                      err( "scalar type required for range" );
                   else
                      declare
                        c1 : character := element( se1, 1 );
                        c2 : character := element( se2, 1 );
                        c3 : character := element( se3, 1 );
                      begin
                        b := c1 in c2..c3;
                      exception when others =>
                        err_exception_raised;
                      end;
                   end if;
                end if;
             elsif operator = "not in" then
                if isExecutingCommand then
                   if length( se1 ) /= 1 or
                      length( se2 ) /= 1 or
                      length( se3 ) /= 1 then
                      err( "scalar type required for range" );
                   else
                      declare
                        c1 : character := element( se1, 1 );
                        c2 : character := element( se2, 1 );
                        c3 : character := element( se3, 1 );
                      begin
                        b := c1 not in c2..c3;
                      exception when others =>
                        err_exception_raised;
                      end;
                   end if;
                end if;
             else
                err( gnat.source_info.source_location &
                  ": Internal error: couldn't handle relational operator" );
             end if;
             if b then
                re := to_unbounded_string( "1" );
             else
                re := to_unbounded_string( "0" );
             end if;
        else
             err( "relational operation not defined for these types" );
        end if;
     end if;
  end if;
end ParseRelation;

procedure ParseExpressionOperator( op : out identifier ) is
  -- Syntax: expr-op = "and" | "or" | "xor"
begin
  if Token /= and_t and
     Token /= or_t and
     Token /= xor_t then
     err( "boolean operator expected");
  end if;
  op := Token;
  getNextToken;
end ParseExpressionOperator;

procedure ParseExpression( ex : out unbounded_string; expr_type : out identifier ) is
  -- Syntax: expr = "relation" and|or|xor "relation"
  re1      : unbounded_string;
  re2      : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : identifier;
  last_op  : identifier := eof_t;
  b        : boolean;
  type bitwise_number is mod 2**64;
begin
  ParseRelation( re1, kind1 );
  ex := re1;
  expr_type := kind1;
  while Token = and_t or Token = or_t or Token = xor_t loop
     ParseExpressionOperator( operator );
     if onlyAda95 and then last_op /= eof_t and then last_op /= operator then
        err( "mixed boolean operators in expression not allowed with " &
              optional_bold( "pragam ada_95" ) & " - use parantheses" );
     end if;
     ParseRelation( re2, kind2 );
     if baseTypesOk( kind1, kind2 ) then
        if getUniType( kind1 ) = uni_numeric_t then
           expr_type := getBaseType( kind1 );
           if operator = and_t then
              begin
                if isExecutingCommand then
                   re1 := to_unbounded_string(
                      long_float(
                      bitwise_number( to_numeric( re1 ) ) and
                      bitwise_number( to_numeric( re2 ) ) ) );
                end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 re1 := null_unbounded_string;
              when ada.strings.index_error =>
                 err( "variable was not intialized" );
                 re1 := null_unbounded_string;
              when others =>
                 err_exception_raised;
                 re1 := null_unbounded_string;
              end;
           elsif operator = or_t then
              begin
                if isExecutingCommand then
                   re1 := to_unbounded_string(
                      long_float(
                      bitwise_number( to_numeric( re1 ) ) or
                      bitwise_number( to_numeric( re2 ) ) ) );
                end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 re1 := null_unbounded_string;
              when ada.strings.index_error =>
                 err( "variable was not intialized" );
                 re1 := null_unbounded_string;
              when others =>
                 err_exception_raised;
                 re1 := null_unbounded_string;
              end;
           elsif operator = xor_t then
              begin
                if isExecutingCommand then
                   re1 := to_unbounded_string(
                      long_float(
                      bitwise_number( to_numeric( re1 ) ) xor
                      bitwise_number( to_numeric( re2 ) ) ) );
                end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 re1 := null_unbounded_string;
              when ada.strings.index_error =>
                 err( "variable was not intialized" );
                 re1 := null_unbounded_string;
              when others =>
                 err_exception_raised;
                 re1 := null_unbounded_string;
              end;
           end if;
        elsif getBaseType( kind1 ) = boolean_t then
           expr_type := getBaseType( kind1 );
           if operator = and_t then
              if isExecutingCommand then
                 b := re1 = "1" and re2 = "1";
              end if;
           elsif operator= or_t then
              if isExecutingCommand then
                 b := re1 = "1" or re2 = "1";
              end if;
           elsif operator = xor_t then
              if isExecutingCommand then
                 b := re1 = "1" xor re2 = "1";
              end if;
           else
              err( gnat.source_info.source_location &
                ": Internal error: unable to handle boolean operator" );
           end if;
           if b then
              re1 := to_unbounded_string( "1" );
           else
              re1 := to_unbounded_string( "0" );
           end if;
        else
           err( "boolean or number expected" );
        end if;
     end if;
     last_op := operator;
  end loop;
  ex := re1;
  --put_line( "Expression value = " & to_string( ex ) );
end ParseExpression;

-----------------------------------------------------------------------------
-- Static Expressions
-----------------------------------------------------------------------------

procedure ParseStaticFactor( f : out unbounded_string; kind : out identifier ) is
  -- Syntax: factor = (expr) | "strlit" | numeric-lit | identifier | built-in fn
  -- if the identifier is volatile, reload the value from the environment
  castType  : identifier;
  array_id  : identifier;
  -- array_id2 : arrayID;
  arrayIndex: long_integer;
  type aUniOp is ( noOp, doPlus, doMinus, doNot );
  uniOp : aUniOp := noOp;
  t : identifier;
begin
  if Token = symbol_t and identifiers( Token ).value.all = "+" then
     uniOp := doPlus;
     getNextToken;
  elsif Token = symbol_t and identifiers( Token ).value.all = "-" then
     uniOp := doMinus;
     getNextToken;
  elsif Token = not_t then
     uniOp := doNot;
     getNextToken;
  end if;
  if Token = symbol_t and then identifiers( Token ).value.all = "(" then
     expect( symbol_t, "(" );
     ParseStaticExpression( f, kind );
     expect( symbol_t, ")" );
  else
     if Token = symbol_t and then identifiers( Token ).value.all = "$?" then
        f := to_unbounded_string( last_status'img );
        kind := uni_numeric_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "$$" then
        f := to_unbounded_string( aPID'image( getpid ) );
        kind := uni_numeric_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "$#" then
        if onlyAda95 then
           err( "$# not allowed with " & optional_bold( "pragma ada_95" ) &
           " -- use command_line package" );
        end if;
        if isExecutingCommand then
           f := to_unbounded_string( integer'image( Argument_Count-optionOffset) );
        end if;
        kind := uni_numeric_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all >= "$1" and then
        identifiers( Token ).value.all <= "$9" then
        -- this could be done a little tighter (ie length check)
        if onlyAda95 then
           err( "$1..$9 not allowed with " & optional_bold( "pragma ada_95" ) &
           " -- use command_line package" );
        end if;
        kind := uni_string_t;
        if isExecutingCommand then
           begin
              f := to_unbounded_string(
                 Argument(
                   integer'value(
                   "" & Element( identifiers( Token ).value.all, 2 ) )+optionOffset ) );
           exception when program_error =>
              err( "program_error exception raised" );
              kind := eof_t;
           when others =>
              err( "there are only" & integer'image( Argument_Count-optionOffset) & " arguments" );
              kind := eof_t;
           end;
        end if;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "$0" then
        if onlyAda95 then
           err( "$0 not allowed with " & optional_bold( "pragma ada_95" ) &
           " -- use command_line package" );
        end if;
        if isExecutingCommand then
           f := to_unbounded_string( Ada.Command_Line.Command_Name );
        end if;
        kind := uni_string_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "@" then
        if onlyAda95 then
           err( "@ is not allowed with " & optional_bold( "pragma ada_95" ) );
           f := null_unbounded_string;
           kind := eof_t;
        elsif itself_type = new_t then
           err( "@ is not defined" );
           f := null_unbounded_string;
           kind := eof_t;
        elsif identifiers( itself_type ).class = procClass then
           err( "@ is not a variable" );
        else
           f := itself;
           kind := itself_type;
        end if;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value.all = "%" then
        if onlyAda95 then
           err( "% is not allowed with " & optional_bold( "pragma ada_95" ) );
           f := null_unbounded_string;
           kind := eof_t;
        elsif syntax_check then             -- % depends on run-time
           f := to_unbounded_string( "0" ); -- so just use a dummy
           kind := universal_t;             -- typeless value
        else
           if last_output_type = eof_t then
              err( "there has been no output assigned to %" );
           else
              f := last_output;
           end if;
           kind := last_output_type;
        end if;
        getNextToken;
     elsif token = number_t then                           -- numeric literal
        f := identifiers( token ).value.all;
        kind := identifiers( token ).kind;
        getNextToken;
     elsif token = charlit_t then                          -- character literal
        --if length( identifiers( charlit_t ).value ) > 1 then
        --   err( "character literal more than 1 character" );
        --end if;
        f := identifiers( token ).value.all;
        kind := identifiers( token ).kind;
        getNextToken;
     elsif token = strlit_t then                           -- string literal
        f := identifiers( token ).value.all;
        kind := identifiers( token ).kind;
        getNextToken;
     elsif token = backlit_t then           -- `cmds`
        kind := identifiers( token ).kind;
        CompileRunAndCaptureOutput( identifiers( token ).value.all, f, getLineNo );
        getNextToken;
     -- Static expressions must not run built-in functions because they will
     -- accept regular expressions
     elsif identifiers( token ).funcCB /= null then         -- a callback?
        err( "static expressions cannot call functions" );
        -- identifiers( token ).funcCB.all( f, kind );        -- run it
     elsif token = is_open_t then                         -- is_open function
        err( "static expressions cannot call functions" );
        --ParseIsOpen( t );
        --f := identifiers( t ).value.all;
        kind := boolean_t;
     elsif token = abs_t then                             -- abs function
        err( "static expressions cannot call functions" );
        --ParseNumericsAbs( f );
        kind := uni_numeric_t;
     elsif token = source_info_symbol_table_size_t then   -- Symbol_Table_Sz
        getNextToken;
        if onlyAda95 then
           err( "symbol_table_size is not allowed with pragma ada_95" );
           f := null_unbounded_string;
           kind := eof_t;
        else
          f := delete( to_unbounded_string( identifier'image( identifiers_top-1 )), 1, 1 );
          kind := natural_t;
        end if;
     elsif token = source_info_file_t then                -- source_info.file
        f := basename( getSourceFileName );
        kind := string_t;
        getNextToken;
     elsif token = source_info_line_t then                -- source_info.line
        f := to_unbounded_string( getLineNo'img );
        kind := positive_t;
        getNextToken;
     elsif token = source_info_src_loc_t then      -- source_info.source_loc.
        f := to_unbounded_string( getLineNo'img );
        f := basename( getSourceFileName ) & ":" & f;
        kind := string_t;
        getNextToken;
     elsif token = source_info_enc_ent_t then      -- source_info.enclosing.
        if blocks_top > block'First then
           f := getBlockName( block'First );
        else
           f := to_unbounded_string( "script" );
        end if;
        kind := string_t;
        getNextToken;
     -- Static expressions must not run user functions because they will
     -- accept regular expressions
      elsif identifiers( token ).class = userFuncClass then
        err( "static expressions cannot call functions" );
     --    declare
     --      funcToken : identifier := token;
     --    begin
     --      DoUserDefinedFunction( identifiers( funcToken ).value.all, f );
     --      kind := identifiers( funcToken ).kind;
     --    end;
     elsif identifiers( token ).kind = keyword_t then      -- no keywords
        f := null_unbounded_string;                        -- (always return something)
        kind := universal_t;
        err( "variable, value or expression expected" );
     else                                                  -- some kind of user ident?
        ParseStaticIdentifier( t );
        if identifiers( t ).volatile then           -- volatile user identifier
           refreshVolatile( t );
           f := identifiers( t ).value.all;
           kind := identifiers( t ).kind;
        elsif identifiers( t ).class = subClass or             -- type cast
           identifiers( t ).class = typeClass then
           if getUniType( kind ) = uni_string_t or   -- index must be scalar
              getUniType( kind ) = root_record_t or
              identifiers( getBaseType( kind ) ).list then
              err( "array index must be a scalar type" );
           end if;
           castType := t;                        -- in expressiosn (yet)
           expect( symbol_t, "(" );
           ParseExpression( f, kind );
           expect( symbol_t, ")" );
           if uniTypesOk( castType, kind ) then
              kind := castType;
              if isExecutingCommand then
                 --f := castToType( to_numeric( f ), kind );
                 f := castToType( f, kind );
              end if;
           end if;
        elsif identifiers( getBaseType( t ) ).list then        -- array(index)?
           array_id := t;                            -- array_id=array variable
           expect( symbol_t, "(" );                  -- parse index part
           ParseExpression( f, kind );               -- kind is the index type
           if getUniType( kind ) = uni_string_t or   -- index must be scalar
              identifiers( getBaseType( kind ) ).list then
              err( "array index must be a scalar type" );
           end if;                                   -- variables are not
           if isExecutingCommand then                -- declared in syntax chk
              arrayIndex := long_integer(to_numeric(f));  -- convert to number
              --array_id2 := arrayID( to_numeric(      -- array_id2=reference
              --   identifiers( array_id ).value ) );  -- to the array table
              --if indexTypeOK( array_id2, kind ) then -- check and access array
              --    if inBounds( array_id2, arrayIndex ) then
              --       f := arrayElement( array_id2, arrayIndex );
              --    end if;
              --end if;
              -- TODO: make a utility function for doing all this.
              -- TODO: probably needs a better error message
              if baseTypesOK( identifiers( array_id ).genKind, kind ) then
                 if arrayIndex not in identifiers( array_id ).avalue'range then -- DEBUG
                    err( "array index " &  to_string( trim( f, ada.strings.both ) ) & " not in" & identifiers( array_id ).avalue'first'img & " .." & identifiers( array_id ).avalue'last'img );
                 end if;
              end if;
              if not error_found then
                 begin
                   f := identifiers( array_id ).avalue( arrayIndex ); -- NEWARRAY
                 exception when CONSTRAINT_ERROR =>
                   err( gnat.source_info.source_location &
                     ": internal error: constraint_error : index out of range " &
                     identifiers( array_id ).avalue'first'img & " .. " & identifiers( array_id ).avalue'last'img );
                 when STORAGE_ERROR =>
                   err( gnat.source_info.source_location &
                     ": internal error : storage error raised in ParseFactor" );
                 end;
              end if;
           end if;
           expect( symbol_t, ")" );                  -- element type is k's k
           kind := identifiers( identifiers( array_id ).kind ).kind;
        -- regular variable with an array index?
        else
          if token = symbol_t and identifiers( token ).value.all = "(" then
             err( optional_bold( to_string( identifiers( t ).name ) ) &
                 " has an array index but is not an array" );
           end if;
           f := identifiers( t ).value.all;
           kind := identifiers( t ).kind;
        end if;
     end if;
  end if;
  case uniOp is
  when noOp => null;
  when doPlus =>
       if baseTypesOk( kind, uni_numeric_t ) then
          null;
       end if;
  when doMinus =>
       begin
          if baseTypesOk( kind, uni_numeric_t ) then
             if isExecutingCommand then
                f := to_unbounded_string( -to_numeric( f ) );
             end if;
          end if;
       exception when others =>
          err_exception_raised;
       end;
  when doNot =>
       begin
          if baseTypesOk( kind, boolean_t ) then
             if isExecutingCommand then
                if to_numeric( f ) = 1.0 then
                   f := to_unbounded_string( "0" );
                else
                   f := to_unbounded_string( "1" );
                end if;
             end if;
          end if;
       exception when others =>
          err_exception_raised;
       end;
  when others =>
      err( "unexpected uniary operation error" );
  end case;
end ParseStaticFactor;

procedure ParseStaticPowerTermOperator( op : out unbounded_string ) is
-- Syntax: termop = "**"
begin
  -- token value is checked by parseTerm, but not token name
  if Token /= symbol_t then
     err( "operator expected");
  -- This is checked by parseTerm
  --elsif identifiers( Token ).value.all /= "**" then
  --   err( "** operator expected");
  else
     op := identifiers( token ).value.all;
  end if;
  getNextToken;
end ParseStaticPowerTermOperator;

procedure ParseStaticPowerTerm( term : out unbounded_string; term_type : out identifier ) is
  -- Syntax: term = "factor powerterm-op factor"
  factor1  : unbounded_string;
  factor2  : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : unbounded_string;
  operation: identifier;
begin
  ParseStaticFactor( factor1, kind1 );
  term := factor1;
  term_type := kind1;
  while identifiers( Token ).value.all = "**" loop
     ParseStaticPowerTermOperator( operator );
     ParseStaticFactor( factor2, kind2 );
     if baseTypesOk( kind1, kind2 ) then
        term_type := getBaseType( kind1 );
        operation := getUniType( kind1 );
        if operation = universal_t then
           operation := getUniType( kind2 );
        end if;
        if operation = universal_t then
           operation := uni_string_t;
        end if;
        if operation = uni_numeric_t then
           if operator = "**" then
              begin
                 if isExecutingCommand then
                    term := to_unbounded_string(
                         to_numeric( term ) **
                         natural( to_numeric( factor2 ) ) );
                 end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 term := null_unbounded_string;
              when others =>
                 err_exception_raised;
                 term := null_unbounded_string;
              end;
          else
              err( "interal error: unknown power operator" );
          end if;
        else
           err( "operation ** not defined for these types" );
        end if;
     end if;
  end loop;
end ParseStaticPowerTerm;

procedure ParseStaticTermOperator( op : out unbounded_string ) is
  -- Syntax: termop = '*' | '/' | '&'
begin
  -- token value is checked by parseTerm, but not token name
  if Token = mod_t or Token = rem_t then
     op := identifiers( token ).name;
  elsif Token /= symbol_t then
     err( "operator expected");
  elsif identifiers( Token ).value.all /= "*" and identifiers( Token ).value.all /= "/" and identifiers( Token ).value.all /= "&" then
     err( "term operator expected");
  else
     op := identifiers( token ).value.all;
  end if;
  getNextToken;
end ParseStaticTermOperator;

procedure ParseStaticTerm( term : out unbounded_string; term_type : out identifier ) is
  -- Syntax: term = "powerterm term-op powerterm"
  pterm1   : unbounded_string;
  pterm2   : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : unbounded_string;
  operation: identifier;
begin
  ParseStaticPowerTerm( pterm1, kind1 );
  term := pterm1;
  term_type := kind1;
  while identifiers( Token ).value.all = "*" or
        identifiers( Token ).value.all = "/" or
        identifiers( Token ).value.all = "&" or
        Token = mod_t or Token = rem_t loop
     ParseStaticTermOperator( operator );
     ParseStaticPowerTerm( pterm2, kind2 );
     term_type := getBaseType( kind2 );
     operation := getUniType( kind2 );
     if operation = universal_t then
        operation := getUniType( kind1 );
     end if;
     if operation = universal_t then
        operation := uni_string_t;
     end if;
     if operation = uni_numeric_t then
        if baseTypesOk( kind1, kind2 ) then
             if operator = "*" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        to_numeric( term ) *
                        to_numeric( pterm2 ),
                     term_type );
                  end if;
                 exception when program_error =>
                    err( "program_error exception raised" );
                    term := null_unbounded_string;
                 when others =>
                    err_exception_raised;
                    term := null_unbounded_string;
                 end;
             elsif operator = "/" then
                declare
                  t : long_float;
                  p : long_float;
                  z : long_float := 0.0;
                begin
                  if isExecutingCommand then
                     -- GCC Ada 4.7.1 doesn't catch divide by zero (returns
                     -- infinity for the following division:
                     -- term := castToType(
                     --   to_numeric( term ) /
                     --   to_numeric( pterm2 ),
                     --term_type );
                     -- As a kludge, we'll break up this function call into
                     -- its parts and explicitly test for division by zero.
                     -- this could likely be improved.
                     t := to_numeric( term );
                     p := to_numeric( pterm2 );
                     if p = 0.0 then
                        err( "division by zero" );
                     else
                        z := t / p;
                        term := castToType( z, term_type );
                     end if;
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   term := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   term := null_unbounded_string;
                end;
             elsif operator = "mod" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        --long_long_integer'image(
                        long_float(
                        long_long_integer( to_numeric( term ) ) mod
                        long_long_integer( to_numeric( pterm2 ) ) ),
                     term_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   term := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   term := null_unbounded_string;
                end;
             elsif operator = "rem" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        --long_long_integer'image(
                        long_float(
                        long_long_integer( to_numeric( term ) ) rem
                        long_long_integer( to_numeric( pterm2 ) ) ),
                     term_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   term := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   term := null_unbounded_string;
                end;
             else
                err( gnat.source_info.source_location &
                  ": Internal error: unable to handle term operator" );
             end if;
           end if;
        elsif operation = uni_string_t then
           declare
             base1 : identifier := getBaseType( kind1 );
             base2 : identifier := getBaseType( kind2 );
             uni1  : identifier := getUniType( kind1 );
             uni2  : identifier := getUniType( kind2 );
           begin
              if operator = "&" then
                 if base1 = character_t and base2 = character_t then
                    kind1 := string_t;
                    kind2 := string_t;
                    term_type := string_t;
                 elsif base1 = character_t and uni2 = uni_string_t then
                    kind1 := kind2;
                 elsif uni1 = uni_string_t and base2 = character_t then
                    kind2 := kind1;
                    term_type := kind1;
                 end if;
                 if baseTypesOk( kind1, kind2 ) then
                    if isExecutingCommand then
                       term := term & pterm2;
                    end if;
                 end if;
              elsif operator = "*" then
                 if baseTypesOk( kind1, natural_t ) then
                    if baseTypesOk( kind2, uni_string_t ) then
                       if isExecutingCommand then
                          term := natural( to_numeric( term ) ) * pterm2;
                       end if;
                    end if;
                 end if;
              else
                 err( "operation not defined for string types" );
              end if;
           exception when program_error =>
              err( "program_error exception raised" );
              term := null_unbounded_string;
           when others =>
              err_exception_raised;
              term := null_unbounded_string;
           end;
        else
           if operator = "*" then
              err( "operation * not defined for these types" );
           elsif operator = "/" then
              err( "operation / not defined for these types" );
           elsif operator = "&" then
              err( "operation & not defined for these types" );
           end if;
        end if;
  end loop;
end ParseStaticTerm;

procedure ParseStaticSimpleExpressionOperator( op : out unbounded_string ) is
  -- Syntax: simple-expr-op = '+' | '-'
begin
  -- token value is checked by parseTerm, but not token name
  if Token /= symbol_t then
     err( "operator expected");
  elsif identifiers( Token ).value.all /= "+" and identifiers( Token ).value.all /= "-" then
     err( "simple expression operator expected");
  end if;
  op := identifiers( token ).value.all;
  getNextToken;
end ParseStaticSimpleExpressionOperator;

procedure ParseStaticSimpleExpression( se : out unbounded_string; expr_type : out identifier ) is
  -- Syntax: term = "term expr-op term"
  term1    : unbounded_string;
  term2    : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : unbounded_string;
  operation: identifier;
  typesOK  : boolean := false;
begin
  ParseStaticTerm( term1, kind1 );
  se := term1;
  expr_type := kind1;
  while identifiers( Token ).value.all = "+" or identifiers( Token ).value.all = "-" loop
     ParseStaticSimpleExpressionOperator( operator );
     ParseStaticTerm( term2, kind2 );
     -- Special exception for + and -...allow time arithmetic
     if (kind1 = cal_time_t) and then (getBaseType(kind2) = duration_t or kind2 = uni_numeric_t or kind2 = universal_t) then
        typesOK := true;
        expr_type := cal_time_t;
        operation := cal_time_t;
     elsif (kind2 = cal_time_t) and then (getBaseType(kind1) = duration_t or kind1 = uni_numeric_t or kind2 = universal_t) then
        typesOK := true;
        expr_type := cal_time_t;
        operation := variable_t;
     elsif (kind1 = cal_time_t) and then (getBaseType(kind2) = cal_time_t) then
        if operator = "+" then
           typesOK := true;
           expr_type := cal_time_t;
        else
           typesOK := true;
           expr_type := duration_t;
        end if;
        operation := root_record_t; -- representing time on both side
     end if;
     -- Otherwise check the types normally
     if not typesOK then
        typesOK := baseTypesOk( kind1, kind2 );
        expr_type := getBaseType( kind1 );
        operation := getUniType( kind1 );
     end if;
     if typesOk then
        if operation = universal_t then
           operation := getUniType( kind2 );
        end if;
        if operation = universal_t then
           operation := uni_string_t;
        end if;
        if operation = uni_numeric_t then
             if operator = "+" then
                begin
                  if isExecutingCommand then
                     se := castToType(
                        to_numeric( se ) +
                        to_numeric( term2 ),
                     expr_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   se := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   se := null_unbounded_string;
                end;
             elsif operator = "-" then
                begin
                  if isExecutingCommand then
                     se := castToType(
                        to_numeric( se ) -
                        to_numeric( term2 ),
                     expr_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   se := null_unbounded_string;
                when others =>
                   err_exception_raised;
                   se := null_unbounded_string;
                end;
             end if;
        elsif operation = cal_time_t then -- time +/- duration
           if operator = "+" then
              if isExecutingCommand then
                 declare
                    c : scanner.calendar.time := scanner.calendar.time( to_numeric( se ) );
                 begin
                    c := c + duration( to_numeric( term2 ) );
                    se := to_unbounded_string( long_long_integer'image( long_long_integer( c ) ) );
                 end;
              end if;
           elsif operator = "-" then
              if isExecutingCommand then
                 declare
                    c : scanner.calendar.time := scanner.calendar.time( to_numeric( se ) );
                 begin
                    c := c - duration( to_numeric( term2 ) );
                    se := to_unbounded_string( long_long_integer'image( long_long_integer( c ) ) );
                 end;
              end if;
           end if;
        elsif operation = variable_t then -- duration + time
           if operator = "+" then
              if isExecutingCommand then
                 declare
                    c : scanner.calendar.time := scanner.calendar.time( to_numeric( term2 ) );
                 begin
                    c := duration( to_numeric( se ) ) + c;
                    se := to_unbounded_string( long_long_integer'image( long_long_integer( c ) ) );
                 end;
              end if;
           elsif operator = "-" then
              err( "operation - not defined for these types" );
           end if;
        elsif operation = root_record_t then -- adding times
           if operator = "+" then
              err( "operation + not defined for these types" );
           else
              if isExecutingCommand then
                 declare
                    c : scanner.calendar.time := scanner.calendar.time( to_numeric( se ) );
                    c2: duration;
                 begin
                    c2 := c - scanner.calendar.time( to_numeric( term2 ) );
                    se := to_unbounded_string( duration'image( c2 ) );
                 exception when time_error =>
                    err( "duration value too large or small" );
                 when constraint_error =>
                    err( "constraint error" );
                 end;
              end if;
           end if;
        else
             if operator = "+" then
                err( "operation + not defined for these types" );
             elsif operator = "-" then
                err( "operation - not defined for these types" );
             end if;
        end if;
     end if;
  end loop;
  --put_line( "Simple Expression value = " & to_string( se ) );
end ParseStaticSimpleExpression;

procedure ParseStaticRelationalOperator( op : out unbounded_string ) is
  -- Syntax: rel-op = >, >=, etc.
begin
  -- token value is checked by parseTerm, but not token name
  if Token /= symbol_t and Token /= in_t and Token /= not_t then
     err( "operator expected");
  elsif identifiers( Token ).value.all /= ">=" and
        identifiers( Token ).value.all /= ">" and
        identifiers( Token ).value.all /= "<" and
        identifiers( Token ).value.all /= "<=" and
        identifiers( Token ).value.all /= "=" and
        identifiers( Token ).value.all /= "/=" and
        Token /= in_t and Token /= not_t then
     err( "relational operator expected");
  end if;
  if Token = in_t then
     op := identifiers( token ).name;
  elsif Token = not_t then
     op := to_unbounded_string( "not in" );
     getNextToken;
     if Token /= in_t then
        err( "relational operator expected");
     end if;
  else
     op := identifiers( token ).value.all;
  end if;
  getNextToken;
end ParseStaticRelationalOperator;

procedure ParseStaticRelation( re : out unbounded_string; rel_type : out identifier ) is
  -- Syntax: relation = "simple-expr" =|>|<|... "simple-expr"
  se1      : unbounded_string;
  se2      : unbounded_string;
  se3      : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  kind3    : identifier;
  operator : unbounded_string;
  operation: identifier;
  b        : boolean;
begin
  ParseStaticSimpleExpression( se1, kind1 );
  re := se1;
  rel_type := kind1;
  if identifiers( Token ).value.all = ">=" or
        identifiers( Token ).value.all = ">" or
        identifiers( Token ).value.all = "<" or
        identifiers( Token ).value.all = "<=" or
        identifiers( Token ).value.all = "=" or
        identifiers( Token ).value.all = "/=" or
        Token = in_t or Token = not_t then
     rel_type := boolean_t; -- always
     ParseStaticRelationalOperator( operator );
     if operator = "in" or operator = "not in" then
        ParseStaticFactor( se2, kind2 );
        if baseTypesOk( kind1, kind2 ) then -- redundant below but
           expect( symbol_t, ".." );        -- keeps error messages nice
           ParseStaticFactor( se3, kind3 );       -- should probably restructure
           if baseTypesOk( kind2, kind3 ) then
              null;
           end if;
        end if;
     else
        ParseStaticSimpleExpression( se2, kind2 );
     end if;
     if baseTypesOk( kind1, kind2 ) then
        operation := getUniType( kind1 );
        if operation = universal_t then
           operation := getUniType( kind2 );
        end if;
        if operation = universal_t then
           operation := uni_string_t;
        end if;
        if operation = uni_numeric_t or else operation = root_enumerated_t or else operation = cal_time_t then
             begin
               if operator = ">=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) >= to_numeric( se2 );
                  end if;
               elsif operator = ">" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) > to_numeric( se2 );
                  end if;
               elsif operator = "<" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) < to_numeric( se2 );
                  end if;
               elsif operator = "<=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) <= to_numeric( se2 );
                  end if;
               elsif operator = "=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) = to_numeric( se2 );
                  end if;
               elsif operator = "/=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) /= to_numeric( se2 );
                  end if;
               elsif operator = "in" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) in to_numeric( se2 )..to_numeric( se3 );
                  end if;
               elsif operator = "not in" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) not in to_numeric( se2 )..to_numeric( se3 );
                  end if;
               else
                  err( gnat.source_info.source_location &
                    ": Internal error: couldn't handle relational operator" );
               end if;
               if b then
                  re := to_unbounded_string( "1" );
               else
                  re := to_unbounded_string( "0" );
               end if;
             exception when others =>
               err_exception_raised;
             end;
        elsif operation = uni_string_t then
             if operator = ">=" then
                if isExecutingCommand then
                   b := se1 >= se2;
                end if;
             elsif operator = ">" then
                if isExecutingCommand then
                   b := se1 > se2;
                end if;
             elsif operator = "<" then
                if isExecutingCommand then
                   b := se1 < se2;
                end if;
             elsif operator = "<=" then
                if isExecutingCommand then
                   b := se1 <= se2;
                end if;
             elsif operator = "=" then
                if isExecutingCommand then
                   b := se1 = se2;
                end if;
             elsif operator = "/=" then
                if isExecutingCommand then
                   b := se1 /= se2;
                end if;
             elsif operator = "in" then
                if isExecutingCommand then
                   if length( se1 ) /= 1 or
                      length( se2 ) /= 1 or
                      length( se3 ) /= 1 then
                      err( "scalar type required for range" );
                   else
                      declare
                        c1 : character := element( se1, 1 );
                        c2 : character := element( se2, 1 );
                        c3 : character := element( se3, 1 );
                      begin
                        b := c1 in c2..c3;
                      exception when others =>
                        err_exception_raised;
                      end;
                   end if;
                end if;
             elsif operator = "not in" then
                if isExecutingCommand then
                   if length( se1 ) /= 1 or
                      length( se2 ) /= 1 or
                      length( se3 ) /= 1 then
                      err( "scalar type required for range" );
                   else
                      declare
                        c1 : character := element( se1, 1 );
                        c2 : character := element( se2, 1 );
                        c3 : character := element( se3, 1 );
                      begin
                        b := c1 not in c2..c3;
                      exception when others =>
                        err_exception_raised;
                      end;
                   end if;
                end if;
             else
                err( gnat.source_info.source_location &
                   ": Internal error: couldn't handle relational operator" );
             end if;
             if b then
                re := to_unbounded_string( "1" );
             else
                re := to_unbounded_string( "0" );
             end if;
        else
             err( "relational operation not defined for these types" );
        end if;
     end if;
  end if;
end ParseStaticRelation;

procedure ParseStaticExpressionOperator( op : out identifier ) is
  -- Syntax: expr-op = "and" | "or" | "xor"
begin
  if Token /= and_t and
     Token /= or_t and
     Token /= xor_t then
     err( "boolean operator expected");
  end if;
  op := Token;
  getNextToken;
end ParseStaticExpressionOperator;

procedure ParseStaticExpression( ex : out unbounded_string; expr_type : out identifier ) is
  -- Syntax: expr = "relation" and|or|xor "relation"
  re1      : unbounded_string;
  re2      : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : identifier;
  last_op  : identifier := eof_t;
  b        : boolean;
  type bitwise_number is mod 2**64;
begin
  ParseStaticRelation( re1, kind1 );
  ex := re1;
  expr_type := kind1;
  while Token = and_t or Token = or_t or Token = xor_t loop
     ParseStaticExpressionOperator( operator );
     if onlyAda95 and then last_op /= eof_t and then last_op /= operator then
        err( "mixed boolean operators in expression not allowed with " &
              optional_bold( "pragam ada_95" ) & " - use parantheses" );
     end if;
     ParseStaticRelation( re2, kind2 );
     if baseTypesOk( kind1, kind2 ) then
        if getUniType( kind1 ) = uni_numeric_t then
           expr_type := getBaseType( kind1 );
           if operator = and_t then
              begin
                if isExecutingCommand then
                   re1 := to_unbounded_string(
                      long_float(
                      bitwise_number( to_numeric( re1 ) ) and
                      bitwise_number( to_numeric( re2 ) ) ) );
                end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 re1 := null_unbounded_string;
              when ada.strings.index_error =>
                 err( "variable was not intialized" );
                 re1 := null_unbounded_string;
              when others =>
                 err_exception_raised;
                 re1 := null_unbounded_string;
              end;
           elsif operator = or_t then
              begin
                if isExecutingCommand then
                   re1 := to_unbounded_string(
                      long_float(
                      bitwise_number( to_numeric( re1 ) ) or
                      bitwise_number( to_numeric( re2 ) ) ) );
                end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 re1 := null_unbounded_string;
              when ada.strings.index_error =>
                 err( "variable was not intialized" );
                 re1 := null_unbounded_string;
              when others =>
                 err_exception_raised;
                 re1 := null_unbounded_string;
              end;
           elsif operator = xor_t then
              begin
                if isExecutingCommand then
                   re1 := to_unbounded_string(
                      long_float(
                      bitwise_number( to_numeric( re1 ) ) xor
                      bitwise_number( to_numeric( re2 ) ) ) );
                end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 re1 := null_unbounded_string;
              when ada.strings.index_error =>
                 err( "variable was not intialized" );
                 re1 := null_unbounded_string;
              when others =>
                 err_exception_raised;
                 re1 := null_unbounded_string;
              end;
           end if;
        elsif getBaseType( kind1 ) = boolean_t then
           expr_type := getBaseType( kind1 );
           if operator = and_t then
              if isExecutingCommand then
                 b := re1 = "1" and re2 = "1";
              end if;
           elsif operator= or_t then
              if isExecutingCommand then
                 b := re1 = "1" or re2 = "1";
              end if;
           elsif operator = xor_t then
              if isExecutingCommand then
                 b := re1 = "1" xor re2 = "1";
              end if;
           else
              err( gnat.source_info.source_location &
                ": Internal error: unable to handle boolean operator" );
           end if;
           if b then
              re1 := to_unbounded_string( "1" );
           else
              re1 := to_unbounded_string( "0" );
           end if;
        else
           err( "boolean or number expected" );
        end if;
     end if;
     last_op := operator;
  end loop;
  ex := re1;
  --put_line( "Expression value = " & to_string( ex ) );
end ParseStaticExpression;


-----------------------------------------------------------------------------
-- Declarations
-----------------------------------------------------------------------------

procedure ParseTypeUsageQualifiers( newtype_id : identifier ) is
  -- Handle the usage qualifiers that go before a types's parent type
  -- Syntax: [abstract | limited]
begin
   -- abstract types

   if token = abstract_t then
      if onlyAda95 then
        err( "abstract types not allowed with " &
            optional_bold( "pragam ada_95" ) );
      end if;
      identifiers( newtype_id ).usage := abstractUsage; -- vars not allowed
      identifiers( newtype_id ).wasReferenced := true;  -- treat as used
      identifiers( newtype_id ).wasApplied := true;     -- treat as applied
      expect( abstract_t );
      if token = abstract_t or token = limited_t or token = constant_t then
         err( "only one of abstract, limited or constant allowed" );
      end if;

   -- limited types

   elsif token = limited_t then
      if onlyAda95 then
         err( "limited types are not allowed with " & optional_bold( "pragma ada_95" ) );
      end if;
      identifiers( newtype_id ).usage := limitedUsage;  -- assign not allowed
      expect( limited_t );
      if token = abstract_t or token = limited_t or token = constant_t then
         err( "only one of abstract, limited or constant allowed" );
      end if;

   -- constant types

   elsif token = constant_t then
      if onlyAda95 then
         err( "constant types are not allowed with " & optional_bold( "pragma ada_95" ) );
      end if;
      identifiers( newtype_id ).usage := constantUsage;  -- read-only
      expect( constant_t );
      if token = abstract_t or token = limited_t or token = constant_t then
         err( "only one of abstract, limited or constant allowed" );
      end if;
   end if;
end ParseTypeUsageQualifiers;

procedure ParseVarUsageQualifiers( id : identifier; expr_expected : out boolean ) is
  -- Handle the usage qualifiers that go before a variable's type
  -- If a constant, expr_expected is set to true to alert the caller
  -- that a constant declaration may need a value asigned.
  -- Syntax: [constant | limited]
begin
  expr_expected := false;                              -- usually false

  if token = aliased_t then                            -- aliased not supported
     err( "aliased isn't supported" );

  elsif token = constant_t then                        -- handle constant
     identifiers( id ).usage := constantUsage;         -- as a constant and
     expr_expected := true;                            -- must assign value
     expect( constant_t );                             -- by flagging variable
     if token = abstract_t or token = limited_t or token = constant_t then
        err( "only one of abstract, limited or constant allowed" );
     end if;

  elsif token = abstract_t then                        -- abstract only makes sense
     err( optional_bold( "abstract" ) &                -- in type declarations since
        " can only be used in type declarations" );    -- it's a no-use quality.

  elsif token = limited_t then                         -- limited access?
     identifiers( id ).usage := limitedUsage;
     expect( limited_t );
     if token = abstract_t or token = limited_t or token = constant_t then
        err( "only one of abstract, limited or constant allowed" );
     end if;
  end if;
end ParseVarUsageQualifiers;

procedure ParseGenericParametersPart( varId : identifier ) is
-- Syntax: ...( gen1 [,gen2] )
-- SparForte is currently limited to two generic parameters for a built-in
-- type which takes them.
  genKind : identifier;
begin
  if token /= symbol_t or identifiers( token ).svalue /= "(" then
     err( "generic types must have element type parameters" );
  end if;
  expect( symbol_t, "(" );
  ParseIdentifier( genKind );
  if class_ok( genKind, typeClass, subClass ) then
     identifiers( varId ).genKind := genKind;
     if token = symbol_t and identifiers( token ).svalue = "," then
        expect( symbol_t, "," );
        ParseIdentifier( genKind );
        if class_ok( genKind, typeClass, subClass ) then
           identifiers( varId ).genKind2 := genKind;
        end if;
     else
        identifiers( varId ).genKind2 := eof_t;
     end if;
  end if;
  expect( symbol_t, ")" );
end ParseGenericParametersPart;

procedure ParseRenamesPart( canonicalRef : out renamingReference;
  new_id, new_type_id : identifier ) is
  -- Syntax: ... renames ident ...
  -- the caller must setup the value pointer for the renaming
  -- new id / type refers to the renaming variable.
begin
  expect( renames_t );
  canonicalRef.id := token;
  -- To support array element renaming, we need a reference not an identifier.

  ParseRenamingReference( canonicalRef, new_type_id );

  -- only copy attributes if no error because copying attributes will
  -- declare the identifier as a side-effect
  -- if isExecutingCommand then
  if not error_found then
     declare
       oldUsage : aUsageQualifier := identifiers( new_id ).usage;
     begin
       declareRenaming( new_id, canonicalRef );

       -- check to see that the usage qualifier isn't less restrictive
       -- compared to the canonical identifier being renamed

       case identifiers( canonicalRef.id ).usage is
       when fullUsage =>
          null; -- always good
       when constantUsage =>
          if identifiers( new_id ).usage = fullUsage then
             err( "no qualifier is less restrictive than constant" );
          end if;
       when limitedUsage =>
          if identifiers( new_id ).usage = fullUsage then
             err( "no qualifier is less restrictive than limited" );
          elsif identifiers( new_id ).usage = constantUsage then
             err( "constant is less restrictive than limited" );
          end if;
       when abstractUsage =>
          err( "internal error: abstract usage qualifier not expected" );
       when others =>
          err( "internal error: unexpected usage qualifier" );
       end case;
     end;
  end if;
end ParseRenamesPart;

procedure ParseAssignPart( expr_value : out unbounded_string; expr_type : out identifier ) is
  -- Syntax: assign-part = " := default_value_expression"
  -- return value and type for expression
begin
  expect( symbol_t, ":=" );
  ParseExpression( expr_value, expr_type );
end ParseAssignPart;

procedure ParseArrayAssignPart( array_id : identifier ) is
-- procedure ParseArrayAssignPart( array_id : identifier; array_id2: arrayID ) is
  -- Syntax: array-assign-part = " := ( expr, expr, ... )|second-array"
  -- others => and positional assignment not (yet) supported
  -- return value and type for expression
  expr_value : unbounded_string;
  expr_type  : identifier;
  arrayIndex : long_integer;
  lastIndex  : long_integer;
  second_array_id  : identifier;
  -- second_array_id2 : arrayID;
  base_type  : identifier; -- NEWARRAY
begin

  -- Note: Array ID will not be valid at syntax check time

  expect( symbol_t, ":=" );
  if token = symbol_t then                                     -- assign (..)?
     expect( symbol_t, "(" );                                  -- read constant
     if isExecutingCommand then
        base_type := getBaseType( identifiers( array_id ).kind );
        arrayIndex := identifiers( base_type ).firstBound;
        lastIndex := identifiers( base_type ).lastBound;
        -- arrayIndex := firstBound( array_id2 );                 -- low bound
        -- lastIndex  := lastBound( array_id2 );                  -- high bound
     end if;
     loop                                                      -- read values
       ParseExpression( expr_value, expr_type );               -- next element
       if isExecutingCommand then                              -- not on synchk
          --if not inBounds( array_id2, arrayIndex ) then        -- in range? add
          --   err( "the array can only hold" &
          --        optional_bold( lastIndex'img ) & " elements" );
          --else
             -- assignElement( array_id2, arrayIndex, expr_value );
             begin
               identifiers( array_id ).avalue( arrayIndex ) := expr_value; -- NEWARRAY
             exception when CONSTRAINT_ERROR =>
               err( "assigning " & optional_bold( arrayIndex'img ) &
                    " elements but the array is range " &
                    identifiers( array_id ).avalue'first'img & " .." & identifiers( array_id ).avalue'last'img );
             when STORAGE_ERROR =>
               err( gnat.source_info.source_location &
                 ": internal error : storage error raised in ParseAssignment" );
             end;
          --end if;
       end if;
       if arrayIndex = long_integer'last then                  -- shound never
          err( "array is too large" );                         -- happen but
       else                                                    -- check anyway
          arrayIndex := arrayIndex+1;                          -- next element
       end if;                                                 -- stop on err
       exit when error_found or identifiers( token ).value.all /= ","; -- more?
       expect( symbol_t, "," );                                -- continue
     end loop;
     arrayIndex := arrayIndex - 1;                             -- last added
     if trace then
        put_trace(
            to_string( identifiers( array_id ).name ) & " := " &
            arrayIndex'img & "elements" );
     end if;
     if isExecutingCommand then                                -- not on synchk
        if arrayIndex < lastIndex then                         -- check sizes
           err( "assigning only " & optional_bold( arrayIndex'img ) &
                " elements but the array is range " &
                identifiers( array_id ).avalue'first'img & " .." & identifiers( array_id ).avalue'last'img );
        end if;
     end if;
     expect( symbol_t, ")" );
  else                                                         -- copying a
     ParseIdentifier( second_array_id );                       -- second array?
     if isExecutingCommand then
        if not class_ok( second_array_id, varClass ) then    -- must be arr
           null;                                               -- and good type
        elsif baseTypesOK( identifiers( array_id ).kind, identifiers( second_array_id ).kind ) then
           --arrayIndex := firstBound( array_id2 );              -- low bound
           --lastIndex := lastBound( array_id2 );                -- high bound
           --second_array_id2 := arrayID( to_numeric( identifiers( second_array_id ).value ) );
           -- for i in arrayIndex..lastIndex loop                 -- do the copy
           --     expr_value := arrayElement( second_array_id2, i );
           --     assignElement( array_id2, i, expr_value );
           -- end loop;
           begin
             base_type := getBaseType( identifiers( array_id ).kind );
             arrayIndex := identifiers( base_type ).firstBound;
             lastIndex := identifiers( base_type ).lastBound;
-- put_line("C - Copying one array to another"); -- DEBUG NEWARRAY
-- put_line( "first array : " & to_string( identifiers( array_id ).name ) & " " & identifiers( array_id ).avalue'first'img & " .. " & identifiers( array_id ).avalue'last'img );
-- put_line( "second array : " & to_string( identifiers( second_array_id ).name ) & " " & arrayIndex'img & " .. " & lastIndex'img );
-- copying one array to another
              if identifiers( array_id ).avalue = null then
-- put_line( "internal error: target array storage unexpectedly null" );
                 err( gnat.source_info.source_location &
                   ": internal error: target array storage unexpectedly null" );
              elsif identifiers( array_id ).avalue'first /= arrayIndex then
-- put_line( "internal error: target array first bound doesn't match: " & identifiers( array_id ).avalue'first'img & " vs " & arrayIndex'img );
                 err( gnat.source_info.source_location &
                   ": internal error: target array first bound doesn't match: " & identifiers( array_id ).avalue'first'img & " vs " & arrayIndex'img );
              elsif identifiers( array_id ).avalue'last /= lastIndex then
-- put_line( "internal error: target array last bound doesn't match: " & identifiers( array_id ).avalue'last'img & " vs " &  lastIndex'img );
                 err( gnat.source_info.source_location &
                   ": internal error: target array last bound doesn't match: " & identifiers( array_id ).avalue'last'img & " vs " &  lastIndex'img );
              elsif not error_found then
                 identifiers( array_id ).avalue.all := identifiers( second_array_id ).avalue.all;
                 --for i in arrayIndex..lastIndex loop                 -- do the copy
-- put_line( i'img & " for " & arrayIndex'img & " .. " & lastIndex'img ); -- DEBUG NEWARRAY
                 --    expr_value := identifiers( second_array_id ).avalue( i );
                 --    identifiers( array_id ).avalue( i ) := expr_value; -- NEWARRAY
-- put_line( "OK - no exception raised" );
                 --end loop;
              end if;
           exception when CONSTRAINT_ERROR =>
              err( "constraint_error : index out of range " & identifiers( array_id ).avalue'first'img & " .." & identifiers( array_id ).avalue'last'img );
           when STORAGE_ERROR =>
              err( gnat.source_info.source_location &
                 ": internal error : storage error raised when copying arrays" );
           end;
           if trace then
              put_trace(
                to_string( identifiers( array_id ).name ) & " := " &
                to_string( identifiers( second_array_id ).name ) );
           end if;
        end if;
     end if;
  end if;
  -- should have put trace here to show assignment results
end ParseArrayAssignPart;

procedure ParseAnonymousArray( id : identifier; limit : boolean ) is
  -- Syntax: anon-array = " array(expr..expr) of ident [array-assn]
  -- ParseDeclarationPart was getting complicated so this procedure
  -- was declared separatly.
  -- array_id    : arrayID;           -- array table index for array variable
  -- type_id     : arrayID;           -- array table index for anon array type
  ab1         : unbounded_string;  -- first array bound
  kind1       : identifier;        -- type of first array bound
  ab2         : unbounded_string;  -- last array bound
  kind2       : identifier;        -- type of last array bound
  elementType : identifier;        -- array elements type
  elementBaseType : identifier;        -- base type of array elements type
  anonType    : identifier;        -- identifier for anonymous array type
begin
  -- To create an anonymous array, we have to add a fake array type
  -- called "an anonymous array" to the symbol table and array table.

  expect( array_t );
  expect( symbol_t, "(" );
  ParseExpression( ab1, kind1 );                           -- low bound
  -- should really be a constant expression but we can't handle that
  if getUniType( kind1 ) = uni_string_t then                 -- must be scalar
     err( "array indexes cannot be a string or character type like " &
          optional_bold( to_string( identifiers( kind1 ).name ) ) );
  elsif getUniType( kind1 ) = root_record_t then                 -- must be scalar
     err( "array indexes cannot be a record type like " &
          optional_bold( to_string( identifiers( kind1 ).name ) ) );
  elsif identifiers( getBaseType( kind1 ) ).list then
     err( "array indexes cannot be an array type like " &
          optional_bold( to_string( identifiers( kind1 ).name ) ) );
  else
     expect( symbol_t, ".." );
     ParseExpression( ab2, kind2 );                            -- high bound
     if token = symbol_t and identifiers( token ).value.all = "," then
        err( "array of arrays not yet supported" );
     elsif baseTypesOk( kind1, kind2 ) then                    -- indexes good?
        if isExecutingCommand then                             -- not on synchk
           if to_numeric( ab1 ) > to_numeric( ab2 ) then       -- bound backwd?
              if long_integer( to_numeric( ab1 ) ) /= 1 and    -- only 1..0
                 long_integer( to_numeric( ab2 ) ) /= 0 then   -- allowed
                 err( "first array bound is higher than last array bound" );
              end if;
           end if;
        end if;
     end if;
  end if;
  expect( symbol_t, ")" );                                  -- finished ind
  expect( of_t );
  if token = exception_t then
     err( "arrays of exceptions are not allowed" );
  end if;
  ParseIdentifier( elementType );

  -- Declare anonymous type in symbol table and array table
  --
  -- Note: Bounds are expressions and may not be defined during syntax check
  -- (Constant assignments, etc. occur only when actually running a script)

  if not error_found then     -- syntax OK, but if execution failed, no
     elementBaseType := getBaseType( elementType );
     if identifiers( elementBaseType ).list  then
        err( "array of arrays not yet supported" );
     else
        declareIdent( anonType, to_unbounded_string( "an anonymous array" ),
           elementType, typeClass );
        identifiers( anonType ).list := true;
        identifiers( anonType ).wasReferenced := true; -- only referenced when declared
        -- mark as limited, if necessary
        if limit then
           identifiers( anonType ).usage := limitedUsage;
        end if;
        if syntax_check then
           -- treat the anonymous type as applied (i.e. no need to be abstr.)
           -- for an anonymous array, the element type must be applied also
           identifiers( anonType ).wasApplied := true;
           identifiers( elementType ).wasApplied := true;
        end if;
        if class_ok( elementType, typeClass, subClass ) then     -- item type OK?
           --if isExecutingCommand then
           if isExecutingCommand and not syntax_check then
              --declareArrayType( id => type_id,
              --           name => to_unbounded_string( "an anonymous array" ),
              --           first => long_integer( to_numeric( ab1 ) ),
              --           last => long_integer( to_numeric( ab2 ) ),
              --           ind => kind1,
              --           blocklvl => blocks_top );
              -- identifiers( anonType ).value := to_unbounded_string( type_id'img );
              identifiers( anonType ).value.all := null_unbounded_string;
              identifiers( anonType ).firstBound := long_integer( to_numeric( ab1 ) ); -- NEWARRAY
              identifiers( anonType ).lastBound  := long_integer( to_numeric( ab2 ) ); -- NEWARRAY
              identifiers( anonType ).genKind    := kind1;
           end if;
        end if;
     end if;
  end if;

  -- Declare array variable in array table
  --
  -- Note: Bounds are expressions and may not be defined during syntax check
  -- (Constant assignments, etc. occur only when actually running a script)

  if isExecutingCommand then
     --declareArray( id => array_id,
     --              name => identifiers( id ).name,
     --              first => long_integer( to_numeric( ab1 ) ),
     --              last => long_integer( to_numeric( ab2 ) ),
     --              ind => kind1,
     --              blocklvl => blocks_top );
     -- identifiers( id ).value := to_unbounded_string( array_id'img );
     identifiers( id ).value.all := null_unbounded_string;
     identifiers( id ).avalue := findStorage( long_integer( to_numeric( ab1 ) ), long_integer( to_numeric( ab2 ) ) );  -- NEWARRAY
     --identifiers( id ).avalue := new storage( long_integer( to_numeric( ab1 ) ) .. long_integer( to_numeric( ab2 ) ) );  -- NEWARRAY
-- put_line( "parseAnonArray: " & to_string( identifiers( id ).name ) & " is new array " & identifiers( kind1 ).firstBound'img & ".." & identifiers( kind1 ).lastBound'img & " => " & identifiers( id ).avalue'first'img & ".." & identifiers( id ).avalue'first'img );
     identifiers( id ).genKind := kind1; -- NEWARRAY
  end if;

  -- Change variable into an array

  if not error_found then     -- syntax OK, but if execution failed, no
     identifiers( id ).list := true;                           -- var is an array
     identifiers( id ).kind := anonType;
     --identifiers( id ).class:= varClass;
  end if;

  -- Any initial assignment?  Then do it.
  --
  -- Note: Array ID will not be valid at syntax check time

  if token = symbol_t and identifiers( token ).value.all = ":=" then
     --ParseArrayAssignPart( id, array_id );
     ParseArrayAssignPart( id );
  end if;

end ParseAnonymousArray;

procedure ParseArrayDeclaration( id : identifier; arrayType : identifier ) is
  -- Syntax: array-declaration = " := array_assign" | renames oldarray
  -- ParseDeclarationPart was getting complicated so this procedure
  -- was declared separately.
  -- array_id : arrayID;
  -- type_id : arrayID;
  base_type_id : identifier;
  canonicalRef : renamingReference;
begin

  -- Renames clause
  -- if it appears, one can only rename...cannot assign.
  -- Renames part will copy the properties from the canonical array.

  if token = renames_t then
     -- Full array renaming
     ParseRenamesPart( canonicalRef, id, arrayType );
     FixRenamedArray( canonicalRef, id );
  else

     -- ParseDeclarationPart detected an array type, so let's set up the
     -- array variable.
     --
     -- Note: Bounds are expressions and may not be defined during syntax check
     -- (Constant assignments, etc. occur only when actually running a script)

     if isExecutingCommand then
        -- get the base type because this may be a subtype of another type
        -- subtypes are just renamings right now and they have no values/bounds
        if identifiers( arrayType ).class = subClass then
           base_type_id := getBaseType( arrayType );
        else
           base_type_id := arrayType;
        end if;
        -- type id is the array id (e.g. in the old array package )
        -- type_id := arrayID( to_numeric( identifiers( base_type_id ).value ) );
        --declareArray( id => array_id,
        --              name => identifiers( id ).value,
        --              first => firstBound( type_id ),
        --              last => lastBound( type_id ),
        --              ind => indexType( type_id ),
        --              blocklvl => blocks_top );
        -- identifiers( id ).value := to_unbounded_string( array_id'img );
        identifiers( id ).value.all := null_unbounded_string;
        identifiers( id ).avalue := findStorage( identifiers( base_type_id ).firstBound, identifiers( base_type_id ).lastBound );  -- NEWARRAY
        --identifiers( id ).avalue := new storage( identifiers( base_type_id ).firstBound .. identifiers( base_type_id ).lastBound );  -- NEWARRAY
   -- put_line( "parseArrayDecl: " & to_string( identifiers( id ).name ) & " is new array " & identifiers( base_type_id ).firstBound'img & ".." & identifiers( base_type_id ).lastBound'img & " => " & identifiers( id ).avalue'first'img & ".." & identifiers( id ).avalue'last'img ); -- NEWARRAY DEBUG
        -- identifiers( id ).genKind := indexType( type_id ); -- NEWARRAY
        identifiers( id ).genKind := identifiers( base_type_id ).genKind; -- NEWARRAY
     end if;

     -- Change variable into an array

     identifiers( id ).list := true;                           -- var is an array
     identifiers( id ).kind := arrayType;
     --identifiers( id ).class:= varClass;

     -- Any initial assignment?  Then do it.
     --
     -- Note: Array ID will not be valid at syntax check time

     if token = symbol_t and identifiers( token ).value.all = ":=" then
        --ParseArrayAssignPart( id, array_id );
        ParseArrayAssignPart( id );
     elsif token = symbol_t and identifiers( token ).svalue = "(" then
         err( optional_bold( to_string( identifiers( arrayType ).name ) ) & " is not a generic type but has parameters" );
     end if;
  end if;
end ParseArrayDeclaration;

procedure ParseRecordAssignPart( id : identifier; recType : identifier ) is
  field_no : integer;
  expr_value : unbounded_string;
  expr_type  : identifier;
  found      : boolean;
  expected_fields : integer;
  second_record_id : identifier;
begin
  expect( symbol_t, ":=" );
  if token = symbol_t then                                     -- assign (..)?
     expect( symbol_t, "(" );                                  -- read constant
     field_no := 1;
     begin
       expected_fields := integer'value( to_string( identifiers( recType ).value.all ) );
     exception when others =>
       expected_fields := 0;
     end;
     loop                                                      -- read values
       ParseExpression( expr_value, expr_type );               -- next element
       found := false;
       for j in 1..identifiers_top-1 loop
           if identifiers( j ).field_of = recType then
              if integer'value( to_string( identifiers( j ).value.all )) = field_no then
                 found := true;
                 declare
                    fieldName : unbounded_string;
                    field_t : identifier;
                    p : natural;
                 begin
                    fieldName := identifiers( j ).name;
                    -- it is possible to have multiple periods in the name
                    -- search backwards for the field name.
                    p := length( fieldName );
                    while p > 0 loop
                       exit when element( fieldName, p ) = '.';
                       p := p - 1;
                    end loop;
                    if p = 0 then
                       field_t := eof_t;
                    else
                       fieldName := delete( fieldName, 1, p );
                       fieldName := identifiers( id ).name & "." & fieldName;
                    end if;
                    findIdent( fieldName, field_t );
                    if field_t = eof_t then
                       err( "unable to find record field " &
                          optional_bold( to_string( fieldName ) ) );
                    else
                       if baseTypesOK( identifiers( field_t ).kind, expr_type ) then
                          if isExecutingCommand then
                             identifiers( field_t ).value.all := expr_value;
                             if trace then
                                put_trace(
                                  to_string( fieldName ) & " := " &
                                  to_string( expr_value ) );
                             end if;
                          end if;
                       end if;
                    end if;
                 end;
           end if;
       end if;
       end loop; -- for
       if not found then
          err( "assigning" & optional_bold( field_no'img ) &
               " fields but the record has only" & optional_bold( expected_fields'img ) );
       end if;
       exit when error_found or identifiers( token ).value.all /= ","; -- more?
       expect( symbol_t, "," );
       field_no := field_no + 1;
     end loop;
     expect( symbol_t, ")" );
     if expected_fields /= field_no then
        err( "assigning only" & optional_bold( field_no'img ) &
             " fields but the record has" & optional_bold( expected_fields'img ) );
     end if;
  else
     ParseIdentifier( second_record_id );                      -- second rec?
     if isExecutingCommand then
        if not class_ok( second_record_id, varClass ) then     -- must be rec
           null;                                               -- and good type
        elsif baseTypesOK( identifiers( id ).kind, identifiers( second_record_id ).kind ) then
           begin
             expected_fields := integer'value( to_string( identifiers( recType ).value.all ) );
           exception when others =>
             expected_fields := 0;
           end;
           declare
              sourceFieldName : unbounded_string;
              targetFieldName : unbounded_string;
              source_field_t : identifier;
              target_field_t : identifier;
           begin
              for field_no in 1..expected_fields loop
                 for j in 1..identifiers_top-1 loop
                     if identifiers( j ).field_of = recType then
                        if integer'value( to_string( identifiers( j ).value.all )) = field_no then
                           -- find source field
                           sourceFieldName := identifiers( j ).name;
                           sourceFieldName := delete( sourceFieldName, 1, index( sourceFieldName, "." ) );
                           sourceFieldName := identifiers( second_record_id ).name & "." & sourceFieldName;
                           findIdent( sourceFieldName, source_field_t );
                           if source_field_t = eof_t then
                              err( gnat.source_info.source_location &
                                 ": internal error: mismatched source field" );
                              exit;
                           end if;
                           -- find target field
                           targetFieldName := identifiers( j ).name;
                           targetFieldName := delete( targetFieldName, 1, index( targetFieldName, "." ) );
                           targetFieldName := identifiers( id ).name & "." & targetFieldName;
                           findIdent( targetFieldName, target_field_t );
                           if target_field_t = eof_t then
                              err( gnat.source_info.source_location &
                                 ": internal error: mismatched target field" );
                              exit;
                           end if;
                           -- copy it
                           identifiers( target_field_t ).value.all := identifiers( source_field_t ).value.all;
                           if trace then
                             put_trace(
                               to_string( targetFieldName ) & " := " &
                               to_string( identifiers( target_field_t ).value.all ) );
                           end if;
                        end if; -- right number
                     end if; -- field member
                 end loop; -- search loop
              end loop; -- fields
            end;
        end if;
     end if;
  end if;
end ParseRecordAssignPart;

procedure ParseRecordDeclaration( id : identifier; recType : identifier; canAssign : boolean := true ) is
  -- Syntax: rec-declaration = " := record_assign"
  -- Syntax: rec-declaration renames canonical-rec
  canonicalRef : renamingReference;
  numFields    : natural;
  baseRecType  : identifier;
  j            : identifier;
begin
  identifiers( id ).kind := recType;

  -- Declare the record's fields.  This must be done whether syntax checking
  -- or running for real.

  if not error_found then

     -- Determine the number of fields for the record, as stored in the record
     -- type's value.all (that is, svalue).  If recType is a derived type, get
     -- the base type which contains the number of fields because it is not
     -- stored in the value of the derived type.
     --
     -- TODO: perhaps the svalue SHOULD be copied by the declaration...but then
     -- it must also create the field identifiers as well...

     baseRecType := getBaseType( recType );
     begin
       numFields := natural'value( to_string( identifiers( baseRecType ).value.all ) );
     exception when constraint_error =>
       err( gnat.source_info.source_location &
          ": internal error: unable to determine number of fields in record " &
          "type " & optional_bold( to_string( identifiers( recType ).name ) ) &
          " for " & optional_bold( to_string( identifiers( id ).name ) ) );
       numFields := 0;
     end;

  -- Change variable into an record
  -- Fill record value with ASCII.NUL delimited fields
  --
  -- To do this, search for the i-th field in the formal record declaration
  -- (the identifier value for the field has the field number).  The field name
  -- contains the full dot qualified name.  Get the base field name by removing
  -- everything except the name after the final dot.  Then prefix the name of
  -- the record being declared (so that "rec_type.f" becomes "my_rec.f").

     j := baseRecType + 1;
     for i in 1..numFields loop

            -- brutal search was...
            -- for j in 1..identifiers_top-1 loop
            --
            -- As an optimization, the fields are likely located immediately after
            -- the record itself is defined.  Also assumes they are stored
            -- sequentially.  In the future, records will be stored differently.

            while j < identifiers_top loop
              if identifiers( j ).field_of = baseRecType then
                 if integer'value( to_string( identifiers( j ).value.all )) = i then
                    exit;
                 end if;
              end if;
              j := identifier( integer( j ) + 1 );
            end loop;

            -- no more identifiers means we didn't find it.
            if j = identifiers_top then
               err( gnat.source_info.source_location &
                 "internal error: record field not found" );
               exit;
            end if;

            declare
               fieldName   : unbounded_string;
               dont_care_t : identifier;
               dotPos      : natural;
            begin
               -- construct the record field name
               fieldName := identifiers( j ).name;
               dotPos := length( fieldName );
               while dotPos > 1 loop
                  exit when element( fieldName, dotPos ) = '.';
                  dotPos := dotPos - 1;
               end loop;
               fieldName := delete( fieldName, 1, dotPos );
               fieldName := identifiers( id ).name & "." & fieldName;
               -- create the variable
               declareIdent( dont_care_t, fieldName, identifiers( j ).kind, varClass );
               -- fields have not been marked as children of the parent
               -- record.  However, to make sure the record is used, it
               -- is convenient to track the field.
               identifiers( dont_care_t ).field_of := id;
               -- apply abtract and limited
               identifiers( dont_care_t ).usage := identifiers( j ).usage;
               -- at least, for now, don't worry if record fields are
               -- declared but not accessed.  We'll just check the
               -- main record identifier.
               if syntax_check and then not error_found then
                  identifiers( dont_care_t ).wasReferenced := true;
                  identifiers( dont_care_t ).wasWritten := true;
                  identifiers( dont_care_t ).wasFactor := true;
               end if;
            end;
         j := identifier( integer( j ) + 1 );
     end loop;
  end if;

  -- Renames clause
  -- if it appears, one can only rename...cannot assign.

  if token = renames_t then
     -- Full Record Renaming
     ParseRenamesPart( canonicalRef, id, recType );
     FixRenamedRecordFields( canonicalRef, id );
  elsif token = symbol_t and identifiers( token ).value.all = ":=" then
     if canAssign then
        ParseRecordAssignPart( id, recType );
     end if;
  elsif token = symbol_t and identifiers( token ).svalue = "(" then
     err( optional_bold( to_string( identifiers( recType ).name ) ) & " is not a generic type but has parameters" );
  end if;

end ParseRecordDeclaration;

procedure ParseDeclarationPart( id : in out identifier; anon_arrays : boolean; exceptions : boolean ) is
  -- Syntax: declaration = " : [aliased|constant] ident assign-part"
  -- Syntax: declaration = " : anonymous-array
  -- Syntax: declaration = " : array-declaration
  -- Syntax: declaration = " : record-declaration
  -- Syntax: declaration = " : exception [with message use status]
  -- Syntax: declaration = " : renames x
  -- assigns type of identifier and value (if assignment part)
  -- Note: in some cases, the variable id may change.
  -- TODO: this procedure is too long and should be broken down

  -- anon_arrays => actually, any nested structure allowed? for records
  -- exceptions => exceptions not allowed in records

  type_token    : identifier;
  expr_value    : unbounded_string;
  expr_type     : identifier := eof_t;
  right_type    : identifier;
  expr_expected : boolean := false;
  canonicalRef : renamingReference;
begin
  expect( symbol_t, ":" );

  -- Overriding

  --if syntax_check then
  --   if token /= overriding_t then
  --      if identifiers( id ).kind /= new_t then
  --         err( optional_bold( "overriding" ) &
  --              " expected because " &
  --              optional_bold( to_string( identifiers( id ).name ) ) &
  --              " exists at a different scope" );
  --      end if;
  --   else
  --      if identifiers( id ).kind = new_t then
  --         err( optional_bold( "overriding" ) &
  --              " not expected because " &
  --              optional_bold( to_string( identifiers( id ).name ) ) &
  --              " does not exist at a different scope" );
  --      end if;
  --   end if;
  --end if;
  --if token = overriding_t then
  --   getNextToken;
  --end if;

  -- Exceptions

  if token = exception_t then                          -- handle exception
     expect( exception_t );
     if not exceptions then                            --  not permitted?
        err( "exceptions are not allowed" );
     else
       declare
         var_name : unbounded_string;
         default_message : unbounded_string;
         exception_status : unbounded_string;
         exception_status_code : anExceptionStatusCode := 1;
         messageType : identifier;
         statusType  : identifier;
       begin
          var_name := identifiers( id ).name;                 -- remember name
          discardUnusedIdentifier( id );                      -- discard variable
          if token = with_t then
             if onlyAda95 then
                err( "exception with not allowed with " &
                   optional_bold( "pragam ada_95" ) );
             end if;
             expect( with_t );
             if token = use_t then
                err( "with message missing" );
             end if;
             ParseExpression( default_message, messageType );
             if uniTypesOK( messageType, uni_string_t ) then
                expect( use_t );
                ParseExpression( exception_status, statusType );
                if baseTypesOK( statusType, natural_t ) then
                   null;
                end if;
             end if;
             -- expression value has no meaning except as run-time
             if isExecutingCommand then
                begin
                  exception_status_code := anExceptionStatusCode'value( to_string( exception_status ) );
                exception when others =>
                  err( "exception status code " & optional_bold( to_string( trim( exception_status, ada.strings.both ) ) ) & " is out-of-range 0..255" );
                end;
             end if;
          elsif token = renames_t then
             err( "exceptions cannot be renamed" );
          elsif token /= symbol_t and identifiers( token ).value.all /= ";" then
             err( "with or ';' expected" );
          end if;
          --if not error_found then -- TODO: this doesn't look right. commenting out
             findException( var_name, id );
             if id = eof_t then
                declareException( id, var_name, default_message, exception_status_code ); -- declare var
             else
                err( "exception " & optional_bold( to_string( var_name ) ) &
                     " already exists in a greater scope" );
             end if;
          --end if;
       end;
     end if;
     return; -- done
  end if;

  -- Check for constant, limited qualifiers

  ParseVarUsageQualifiers( id, expr_expected );

  -- Anonymous Array?  Handled elsewhere.

  -- TODO: sort out limit...is it on types, variables or both.  use it
  -- consistently.

  if token = array_t then                              -- anonymous array?
     if not anon_arrays then
        err( "anonymous arrays are not allowed" );
     end if;
     ParseAnonymousArray( id, identifiers( id ).usage = limitedUsage );  -- handle it
     return;                                           --  and nothing more
  end if;

  --  Get the type.

  ParseIdentifier( type_token );                            -- identify type
  if syntax_check then                                 -- mark that type was
     identifiers( type_token ).wasApplied := true;     -- used
  end if;

  -- Variable vs. Type Qualifiers
  --
  -- If the variable has an explicit qualifier, it will have been applied
  -- above.  So if it's full usage, check the type and inherit any qualifier
  -- from the type.  The variable is allowed to be more constrained than
  -- the type, but it must not reduce constraint.

  case identifiers( id ).usage is
  when fullUsage =>
        case identifiers( type_token ).usage is
        when fullUsage =>
           null;
        when constantUsage =>
           identifiers( id ).usage := constantUsage;
        when limitedUsage =>
           identifiers( id ).usage := limitedUsage;
        when abstractUsage =>
           err( "internal error: variables should not have abstract types" );
        when others =>
           err( "internal error: unknown var qualifier" );
        end case;
  when constantUsage =>
       if identifiers( type_token ).usage = limitedUsage then
          err( "constant is less restrictive than " & optional_bold( "limited" ) );
       end if;
  when limitedUsage =>
       null; -- this is the most constrained
  when abstractUsage =>
       err( "variables cannot be declared as type " &
         optional_bold( to_string( identifiers( type_token ).name ) ) &
         " because it is " & optional_bold( "abstract" ) );
  when others =>
      err( "internal error: unknown var qualifier" );
  end case;

  if token = private_t then                             -- private access?
     err( "not yet implemented" );
  end if;


  -- Array type?  Handled elsewhere.

  if identifiers( getBaseType( type_token ) ).list then       -- array type?
     if not anon_arrays then
        err( "nested arrays not yet supported" );
     --elsif identifiers( type_token ).usage = abstractUsage then
     --   err( "constants and variables cannot be declared as " &
     --     optional_bold( to_string( identifiers( type_token ).name ) ) &
     --     " because it is " & optional_bold( "abstract" ) );
     else
        ParseArrayDeclaration( id, type_token );                -- handle it
     end if;
     return;                                            --  and nothing more
  end if;

  -- Record type?  Handled elsewhere.

  if identifiers( getBaseType( type_token ) ).kind = root_record_t then  -- record type?
     if not anon_arrays then
        err( "nested records not yet supported" );
     --elsif identifiers( type_token ).usage = abstractUsage then
     --   err( "constants and variables cannot be declared as " &
     --     optional_bold( to_string( identifiers( type_token ).name ) ) &
     --     " because it is " & optional_bold( "abstract" ) );
     else
        ParseRecordDeclaration( id, type_token );          -- handle it
     end if;
     return;                                           --  and nothing more
  end if;

  -- Not an array or record?
  -- Verify that the type token is a type and check for types
  -- not allowed with certain pragmas.

  if not class_ok( type_token, typeClass, subClass, genericTypeClass ) then
     null;
  elsif onlyAda95 and (type_token = uni_string_t or type_token =
     uni_numeric_t or type_token = universal_t) then
     err( "universal/typeless types not allowed with " &
          optional_bold( "pragam ada_95" ) );
  elsif getBaseType( type_token ) = command_t then
     if onlyAda95 then
        err( "command types not allowed with " & optional_bold( "pragma ada_95" ) );
     -- Special case: command type qualifiers
     elsif identifiers( id ).usage /= limitedUsage and
        identifiers( id ).usage /= constantUsage then
        err( "command variables must be " & optional_bold( "limited" ) & " or " & optional_bold( "constant" ) );
        expr_expected := true;
     end if;
  end if;

  -- Abstract Types
  --
  -- These cannot be declared.

  --if identifiers( type_token ).usage = abstractUsage then
  --   err( "constants and variables cannot be declared as " &
  --        optional_bold( to_string( identifiers( type_token ).name ) ) &
  --        " because it is " & optional_bold( "abstract" ) );
  --end if;

  -- Generic Parameters
  --
  -- These only apply to built-in types and they are not arrays or records.
  -- It excludes assignment and renaming (only because renaming requires
  -- modification to check the generic parameters).

  if identifiers( type_token ).class = genericTypeClass then
     ParseGenericParametersPart( id  );
     if isExecutingCommand then
        -- create and attach a resource to the variable
        --
        -- TODO: As a temporary situation, the generic type checks are hard-
        -- coded here.  There is no field in an identifier to set the number
        -- of expected parameters to a generic type.
        --
        -- TODO: I am permitting subtypes of generic types, but there's no
        -- function currently in the scanner to track down type derived type of
        -- generic type.  If I allowed new types from a generic type, the
        -- hard-coded functionality will break.
        declare
           baseType  : identifier := getBaseType( type_token );
           resId     : resHandleId;
           genKindId : identifier;
        begin
           if baseType = doubly_list_t then
              if identifiers( id ).genKind2 /= eof_t then
                 err( optional_bold( to_string( identifiers( type_token ).name ) ) & " should have one element type" );
              else
                 genKindId := identifiers( id ).genKind;
                 if class_ok( genKindId, typeClass, subClass ) then
                    if identifiers( genKindId ).list then
                       err( "element type should be a scalar type" );
                    elsif identifiers( getBaseType( genKindId ) ).kind = root_record_t then
                       err( "element type should be a scalar type" );
                    end if;
                 end if;
              end if;
              if not error_found then
                 declareResource( resId, doubly_linked_string_list, getIdentifierBlock( id ) );
              end if;
           elsif baseType = doubly_cursor_t then
              if identifiers( id ).genKind2 /= eof_t then
                 err( optional_bold( to_string( identifiers( type_token ).name ) ) & " should have one element type" );
              else
                 declareResource( resId, doubly_linked_string_list_cursor, getIdentifierBlock( id ) );
              end if;
           elsif baseType = btree_file_t then
              if identifiers( id ).genKind2 /= eof_t then
                 err( optional_bold( to_string( identifiers( type_token ).name ) ) & " should have one element type" );
              else
                 declareResource( resId, btree_file, getIdentifierBlock( id ) );
              end if;
           elsif baseType = btree_cursor_t then
              if identifiers( id ).genKind2 /= eof_t then
                 err( optional_bold( to_string( identifiers( type_token ).name ) ) & " should have one element type" );
              else
                 declareResource( resId, btree_cursor, getIdentifierBlock( id ) );
              end if;
           elsif baseType = hash_file_t then
              if identifiers( id ).genKind2 /= eof_t then
                 err( optional_bold( to_string( identifiers( type_token ).name ) ) & " should have one element type" );
              else
                 declareResource( resId, hash_file, getIdentifierBlock( id ) );
              end if;
           elsif baseType = hash_cursor_t then
              if identifiers( id ).genKind2 /= eof_t then
                 err( optional_bold( to_string( identifiers( type_token ).name ) ) & " should have one element type" );
              else
                 declareResource( resId, hash_cursor, getIdentifierBlock( id ) );
              end if;
           elsif baseType = dht_table_t then
              genKindId := identifiers( id ).genKind;
              if class_ok( genKindId, typeClass, subClass ) then
                 if identifiers( genKindId ).list then
                    err( "element type should be a scalar type" );
                 elsif identifiers( getBaseType( genKindId ) ).kind = root_record_t then
                    err( "element type should be a scalar type" );
                 end if;
              end if;
              if not error_found then
                 declareResource( resId, dynamic_string_hash_table, getIdentifierBlock( id ) );
              end if;
           else
              -- TODO: implement generic types
              err( "expected a generic type" );
           end if;
           if isExecutingCommand then
              identifiers( id ).svalue := to_unbounded_string( resId );
              identifiers( id ).value := identifiers( id ).svalue'access;
              identifiers( id ).resource := true;
           end if;
        end;
     end if;
     identifiers( id ).kind := type_token;
  elsif token = symbol_t and identifiers( token ).svalue = "(" then
     err( optional_bold( to_string( identifiers( type_token ).name ) ) & " is not a generic type but has parameters" );

  -- Renames clause
  -- if it appears, one can only rename...cannot assign.

  elsif token = renames_t then

     declare
        -- the class will change when parsing the rename
        --originalClass : anIdentifierClass := identifiers( id ).class;
        originalFieldOf : identifier := identifiers( id ).field_of;
        -- TODO: refactor these booleans
        wasLimited : boolean := identifiers( id ).usage = limitedUsage;
        wasConstant : boolean := identifiers( id ).usage = constantUsage;
     begin
        -- Variable or Constant renaming
        ParseRenamesPart( canonicalRef, id, type_token );
        -- Prevent a constant from being turned into a variable by a renaming
        -- It must be renamed as a constant or a limited.
        if identifiers( canonicalRef.id).usage = constantUsage and
           not wasConstant and not wasLimited then
           err( "a " & optional_bold( "constant" ) & " must be renamed by a constant or a limited" );
        elsif identifiers( canonicalRef.id ).class = enumClass then
           -- TODO: I could probably get this to work but it's a weird edge
           -- case.
           err( "enumerated items cannot be renamed" );
        elsif identifiers( canonicalRef.id ).usage = limitedUsage and not wasLimited then
           err( "a " & optional_bold( "limited" ) & " must be renamed by a limited" );
        elsif identifiers( canonicalRef.id ).field_of /= eof_t then
           if identifiers( identifiers( canonicalRef.id ).field_of ).usage = limitedUsage and not wasLimited then
              err( "limited record fields must be renamed by a limited identifier" );
           end if;
        end if;
        -- If the identifier is a record field, it must refer to the
        -- renaming record, not the canonical record.
        identifiers( id ).field_of := originalFieldOf;
        if wasLimited then
           identifiers( id ).usage := limitedUsage;
        end if;
     end;

     -- Complete the declaration
     identifiers( id ).kind := type_token;

     if identifiers( canonicalRef.id ).list then
        if canonicalRef.hasIndex then
           -- don't do this on an error or an excepion may be thrown
           if isExecutingCommand then
              begin
                 identifiers( id ).value := identifiers( canonicalRef.id ).avalue( canonicalRef.index )'access;
              exception when storage_error =>
                 err( gnat.source_info.source_location &
                    ": internal error: storage_error exception raised" );
              when others =>
                 err( gnat.source_info.source_location &
                    ": internal error: exception raised" );
              end;
           end if;
        end if;
     end if;

  -- Check for optional assignment

  elsif (token = symbol_t and identifiers( token ).value.all = ":=") or -- assign part?
     expr_expected then

     --if identifiers( type_token ).limit then
     --   err( "limited type variables cannot be assigned a value" );
     --end if;

     -- Tricky bit: what about "i : integer := i"?
     --   Dropping the top of the stack temporarily isn't good enough: if
     -- the assignment contains backquotes, the name of the command will
     -- overwrite the hidden variable.  The variable must be deleted and
     -- redeclared later.

     declare
        is_constant : boolean := false;
        var_name    : unbounded_string;
        wasLimited  : boolean := identifiers( id ).usage = limitedUsage;
     begin

       -- Temporarily destroy identifer so that i : integer := i isn't circular

       var_name := identifiers( id ).name;                 -- remember name
       if identifiers( id ).usage = constantUsage then     -- a constant?
          is_constant := true;                             -- remember it
       end if;
       discardUnusedIdentifier( id );                      -- discard variable

       -- Calculate the assignment (ie. using any previous variable i)

       ParseAssignPart( expr_value, right_type );          -- do := part

       -- Redeclare temporarily destroyed identifier (ie. declare new i)
       -- and assign its type

       declareIdent( id, var_name, type_token, varClass );  -- declare var
       -- TODO: refactor this
       if is_constant then                                  -- a constant?
          identifiers( id ).usage := constantUsage;
       end if;
       if wasLimited then
          identifiers( id ).usage := limitedUsage;
       end if;
     end;

    -- exceptions are a special case because they are a keyword

    if right_type = exception_t then
       err( "exceptions cannot be assigned" );

    -- command types have special limitations

    elsif getBaseType( type_token ) = command_t then
       if baseTypesOk( uni_string_t, right_type ) then
          type_token := uni_string_t; -- pretend it's a string
          if not C_is_executable_file( to_string( expr_value ) & ASCII.NUL ) then
             err( '"' & to_string( expr_value) & '"' &
                " is not an executable command" );
          end if;
       end if;

     elsif baseTypesOk( type_token, right_type ) then
        null;
     end if;

     -- perform assignment

     if isExecutingCommand then
        --if getUniType( type_token ) = uni_numeric_t then
        --   -- numeric test.  universal typelesses could result
        --   -- in a non-numeric expression that baseTypesOk
        --   -- doesn't catch.
        --   declare
        --      lf : long_float;
        --   begin
        --      lf := to_numeric( expr_value );
        --      -- handle integer types
        --      expr_value := castToType( lf, type_token );
        --   exception when program_error =>
        --      err( "program_error exception raised" );
        --   when others =>
        --      err( "exception raised" );
        --   end;
        --end if;
        expr_value := castToType( expr_value, type_token );
        DoContracts( identifiers( id ).kind, expr_value );
        identifiers( id ).value.all := expr_value;
        if trace then
            put_trace(
               to_string( identifiers( id ).name ) & " := """ &
               to_string( ToEscaped( expr_value ) ) & """" );
        end if;
     end if;
  elsif (token = symbol_t and identifiers( token ).value.all = ";") then
     identifiers( id ).kind := type_token;
  else
     -- neither an ending ; or a :=?  destory the variable.  A syntax
     -- error will occur when expect semi-colon runs
     identifiers( id ).kind := new_t;
     discardUnusedIdentifier( id );
  end if;
  -- failed somewhere to set a real type?
  -- blow away half-declared variable
  if error_found then
     identifiers( id ).kind := new_t;
     discardUnusedIdentifier( id );
  end if;
end ParseDeclarationPart;

procedure ParseRecordFields( record_id : identifier; field_no : in out integer ) is
-- Syntax: field = declaration [; declaration ... ]
   field_id : identifier;
   b : boolean;
begin
  -- ParseNewIdentifier( field_id );
  ParseFieldIdentifier( record_id, field_id );
  ParseDeclarationPart( field_id, anon_arrays => false, exceptions => false );
  identifiers( field_id ).class := subClass;        -- it is a subtype
  identifiers( field_id ).field_of := record_id;    -- it is a field
  identifiers( field_id ).value.all := to_unbounded_string( field_no'img );
  if syntax_check then
     identifiers( field_id ).wasReferenced := true;
  end if;
  expectSemicolon;
  if not error_found and  token /= eof_t and token /= end_t then
     field_no := field_no + 1;
     ParseRecordFields( record_id, field_no );
     -- the symbol table will overflow before field_no does
  end if;
  if error_found then
     b := deleteIdent( field_id );
  end if;
end ParseRecordFields;

procedure ParseRecordTypePart( newtype_id : identifier ) is
   -- Syntax: type = "record f1 : t1; ... end record"
   field_no : integer := 1;
   b : boolean;
begin
   ParseTypeUsageQualifiers( newtype_id );
   expect( record_t );
   ParseRecordFields( newtype_id, field_no );
   expect( end_t );
   expect( record_t );
   -- if isExecutingCommand then
   if not error_found then
      identifiers( newtype_id ).kind := root_record_t;      -- a record
      identifiers( newtype_id ).list := false;              -- it isn't an array
      identifiers( newtype_id ).field_of := eof_t;          -- it isn't a field
      identifiers( newtype_id ).class := typeClass;         -- it is a type
      identifiers( newtype_id ).import := false;            -- never import
      identifiers( newtype_id ).export := false;            -- never export
      identifiers( newtype_id ).value.all := to_unbounded_string( field_no'img );
      -- number of fields in a record variable
   else                                                     -- otherwise
     b := deleteIdent( newtype_id );                        -- discard bad type
   end if;
end ParseRecordTypePart;

procedure ParseArrayTypePart( newtype_id : identifier ) is
   -- Syntax: type = "array(exp1..exp2) of element-type"
   --type_id     : arrayID;
   ab1         : unbounded_string; -- low array bound
   kind1       : identifier;
   ab2         : unbounded_string; -- high array bound
   kind2       : identifier;
   elementType : identifier;
   elementBaseType : identifier;        -- base type of array elements type
   b           : boolean;
begin
   ParseTypeUsageQualifiers( newtype_id );

   -- Check the Array Declaration

   expect( array_t );
   expect( symbol_t, "(" );
   ParseExpression( ab1, kind1 );
   -- should be constant expression but we can't handle those yet
   if getUniType( kind1 ) = uni_string_t or
      identifiers( kind1 ).list then
       err( "array indexes must be scalar types" );
   end if;
   expect( symbol_t, ".." );
   ParseExpression( ab2, kind2 );
   if token = symbol_t and identifiers( token ).value.all = "," then
      err( "array of arrays not yet supported" );
   elsif baseTypesOk(kind1, kind2 ) then
      if isExecutingCommand and not syntax_check then  -- ab1/2 undef on synchk
         if to_numeric( ab1 ) > to_numeric( ab2 ) then
            if long_integer( to_numeric( ab1 ) ) /= 1 and
               long_integer( to_numeric( ab2 ) ) /= 0 then
               err( "first array bound is higher than last array bound" );
            end if;
         end if;
      end if;
   end if;
   expect( symbol_t, ")" );
   expect( of_t );
   if token = exception_t then
      err( "arrays of exceptions are not allowed" );
   end if;
   ParseIdentifier( elementType );                       -- parent type name

   -- Finish declaring the array
   --
   -- Note: Bounds are expressions and may not be defined during syntax check
  -- (Constant assignments, etc. occur only when actually running a script)

   elementBaseType := getBaseType( elementType );
   if token = symbol_t and identifiers( token ).value.all = ":=" then
      err( "assignment not allowed in an array type declaration" );
      b := deleteIdent( newtype_id );                       -- discard bad type
   elsif identifiers( elementBaseType ).list  then
      err( "array of arrays not yet supported" );
      b := deleteIdent( newtype_id );                       -- discard bad type
   elsif class_ok( elementType, typeClass, subClass ) then  -- item type OK?
      if isExecutingCommand and not syntax_check then       -- not on synchk
         --declareArrayType( id => type_id,
         --           name => identifiers( newtype_id ).name,
         --           first => long_integer( to_numeric( ab1 ) ),
         --           last => long_integer( to_numeric( ab2 ) ),
         --           ind => kind1,
         --           blocklvl => blocks_top );
         -- identifiers( newtype_id ).value := to_unbounded_string( type_id'img );
         identifiers( newtype_id ).firstBound := long_integer( to_numeric( ab1 ) ); -- NEWARRAY
         identifiers( newtype_id ).lastBound := long_integer( to_numeric( ab2 ) ); -- NEWARRAY
      end if;
      identifiers( newtype_id ).kind := elementType;        -- element type
      identifiers( newtype_id ).genKind := kind1;           -- index type
      identifiers( newtype_id ).list := true;               -- it is an array
      identifiers( newtype_id ).class := typeClass;         -- it is a type
      identifiers( newtype_id ).import := false;            -- never import
      identifiers( newtype_id ).export := false;            -- never export
   else                                                     -- otherwise
     b := deleteIdent( newtype_id );                        -- discard bad type
   end if;

end ParseArrayTypePart;

procedure ParseExceptionHandler( errorOnEntry : boolean );
--forward


procedure ParseAcceptBlock is
   -- Syntax: accept ... begin ... end accept;
  --errorOnEntry : boolean := error_found;
begin
   -- Verify context
   expect( accept_t );
   ParseBlock;
   -- I decided not to have an exception handler since the purpose of the
   -- accept block is to raise exceptions.
   --if token = exception_t then
   --   ParseExceptionHandler( errorOnEntry );
   --end if;
   expect( end_t );
   expect( accept_t );
end ParseAcceptBlock;

procedure ParseAcceptClause( newtype_id : identifier ) is
   -- Setup an accept block
   type_value_id : identifier;
   blockStart    : natural;
   blockEnd      : natural;
   save_syntax_check : boolean := syntax_check;
begin
   -- To execute a contract, we cannot use a function since we cannot
   -- define one without knowing the data type of type_value.
   -- TODO: handle backquoted accept clause

   -- declare type_value
   if onlyAda95 then
      err( "accept clauses are not allowed with " & optional_bold( "pragma ada_95" ) );
   else
      pushBlock( newScope => true, newName => "accept function" );
      declareIdent( type_value_id, identifiers( newtype_id ).name, newtype_id );
      blockStart := firstPos;
      syntax_check := true;

      ParseAcceptBlock;

      syntax_check := save_syntax_check;
      blockEnd := lastPos+1; -- include EOL ASCII.NUL
      if not syntax_check then
         -- TODO: copyByteCodeLines to be fixed
         identifiers( newtype_id ).contract := to_unbounded_string( copyByteCodeLines( blockStart, blockEnd ) );
      end if;
      pullBlock;
   end if;
end ParseAcceptClause;

procedure ParseType is
   -- Syntax: type = "type newtype is new [qualifier] oldtype [accept fn]"
   --         type = "type arraytype is array-type-part"
   -- NOTE: enumerateds aren't overloadable (yet)
   newtype_id  : identifier;
   parent_id   : identifier;
   enum_index  : integer := 0;
   contract_id : identifier := eof_t;
   b : boolean;
begin

   expect( type_t );                                       -- "type"
   ParseNewIdentifier( newtype_id );                       -- typename
   expect( is_t );                                         -- is

   if Token = symbol_t and identifiers( token ).value.all = "(" then

      -- enumerated
      --
      -- If an error happens during the parsing, some enumerated items
      -- may be left declared.  Should use recursion for parsing the
      -- items so they can be properly "rolled back".

      identifiers( newtype_id ).kind := root_enumerated_t; -- the parent is
      identifiers( newtype_id ).class := typeClass;        -- type based on
      identifiers( newtype_id ).wasApplied := true;        -- can't be abstract
      parent_id := newtype_id;                             -- root enumerated
      -- The enum type name may not be referenced as much
      -- as items are mentioned.  (e.g. draco_ii doesn't
      -- use the type name anywhere).
      if syntax_check and not restriction_no_unused_identifiers then
         identifiers( parent_id ).wasReferenced := true;
      end if;
      expect( symbol_t, "(" );                             -- "("
      while token /= eof_t loop                            -- name [,name]
         ParseNewIdentifier( newtype_id );                 -- enumerated item
         -- always execute declarations when syntax checking
         -- because they are needed to test types and interpret
         -- other statements
         if isExecutingCommand or syntax_check then        -- OK to do it?
            -- identifiers( newtype_id ).class := constClass; -- it's a type
            identifiers( newtype_id ).class := enumClass;  -- it's a type
            -- normally, treat them as values and thus we don't care
            -- if they are used or not.  Unless user explicitly requests
            -- that they are tested.
            if syntax_check and not restriction_no_unused_identifiers then
               identifiers( newtype_id ).wasReferenced := true;
            end if;
            declare
              s : string := enum_index'img;
            begin
              -- drop leading space
              --identifiers( newtype_id ).value := to_unbounded_string( s(2..s'last) );
              identifiers( newtype_id ).value.all := to_unbounded_string( s );
            end;
            identifiers( newtype_id ).kind := parent_id;   -- based on parent
         else                                              -- otherwise
            b := deleteIdent( newtype_id );                -- discard item
         end if;
         enum_index := enum_index + 1;                     -- next item number
         exit when error_found or identifiers( token ).value.all /= ",";      -- quit when no ","
         expect( symbol_t, "," );                          -- ","
      end loop;
      expect( symbol_t, ")" );                             -- closing ")"
      if error_found or exit_block then                    -- problems?
         b := deleteIdent( parent_id );                    -- discard parent
     end if;

   -- "abstract" appears before record or array, but after "new"
   -- so there's extra logic to handle abstract and non-abstract
   -- cases.
   --
   -- type ... abstract record... or abstract array...

   elsif token = abstract_t or token = limited_t or token = constant_t then
      ParseTypeUsageQualifiers( newtype_id );
      if token = array_t then
         ParseArrayTypePart( newtype_id );
         --identifiers( newtype_id ).wasReferenced := true;  -- treat as used
         --identifiers( newtype_id ).wasApplied := true;     -- treat as applied
      elsif token = record_t then
         ParseRecordTypePart( newtype_id );
         --identifiers( newtype_id ).wasReferenced := true;  -- treat as used
         --identifiers( newtype_id ).wasApplied := true;     -- treat as applied
      elsif token = new_t then
        err( optional_bold( "abstract" ) & " or " &
             optional_bold( "constant" ) & " or " &
             optional_bold( "limited" ) &  " goes after " &
             optional_bold( "new" ) );
      else
        err( "record or array expected" );
      end if;

   -- type ... is array...

   elsif token = array_t then
      ParseArrayTypePart( newtype_id );
      -- for now, assignment is with a scalar so we don't have an accept
      -- block for an array.

   -- type ... is record...

   elsif token = record_t then
      ParseRecordTypePart( newtype_id );
      -- for now, assignment is with a scalar so we don't have an accept
      -- block for a record.
   else

     -- type ... is new [abstract] ...

     expect( new_t );                                      -- "new"

     ParseTypeUsageQualifiers( newtype_id );

     -- Standard Ada syntax, but if we could extend arrays or records, would
     -- "new" be appropriate?

     if token = array_t then
        err( "omit " & optional_bold( "new" ) & " since array is not derived from another type" );
     elsif token = record_t then
        err( "omit " & optional_bold( "new" ) & " since record is not derived from another type" );
     end if;

     ParseIdentifier( parent_id );                         -- parent type name
     if class_ok( parent_id, typeClass, subClass ) then    -- not a type?
        if identifiers( getBaseType( parent_id ) ).kind = root_record_t then
           -- TODO: we would have to generate all the field identifiers
           -- for the record, renamed for the new type, which is not done
           -- yet.  I will need this for objects later.
           err( "new types based on records not supported yet" );
        end if;
        if isExecutingCommand then                         -- OK to do it?
           identifiers( newtype_id ).kind := parent_id;    -- define the type
           identifiers( newtype_id ).class := typeClass;
           identifiers( newtype_id ).genKind :=            -- copy index type
             identifiers( parent_id ).genKind;             -- / generic type
           if identifiers( parent_id ).list then           -- an array?
              identifiers( newtype_id ).list := true;      -- this also array
              identifiers( newtype_id ).firstBound :=      -- copy first bnd
                 identifiers( parent_id ).firstBound;
              identifiers( newtype_id ).lastBound :=       -- copy last bnd
                 identifiers( parent_id ).lastBound;
           end if;
        elsif syntax_check then                            -- syntax check?
           identifiers( newtype_id ).kind := parent_id;    -- assign subtype
           identifiers( newtype_id ).class := typeClass;   -- subtype class
           if identifiers( parent_id ).list then           -- an array?
              identifiers( newtype_id ).list := true;      -- this also array
           end if;
        else                                               -- otherwise
          b := deleteIdent( newtype_id );                  -- discard new type
        end if;
     end if;

     -- Programming-by-contract (accept function)

     if token = accept_t then
        ParseAcceptClause( newtype_id );
     elsif token /= symbol_t and identifiers( token ).value.all /= ";" then
        err( "accept or ';' expected" );
     end if;
   end if;
end ParseType;

procedure ParseSubtype is
   -- Syntax: type = "subtype newtype is [abstract|limited] oldtype [accept clause]"
   newtype_id : identifier;
   parent_id : identifier;
   b : boolean;
begin
   expect( subtype_t );                                    -- "subtype"
   ParseNewIdentifier( newtype_id );                       -- type name
   expect( is_t );                                         -- "is"
   ParseTypeUsageQualifiers( newtype_id );                 -- limited, etc.
   ParseIdentifier( parent_id );                           -- old type

   if class_ok( parent_id, genericTypeClass, typeClass,
               subClass ) then                             -- not a type?
      if isExecutingCommand then                           -- OK to execute?
         identifiers( newtype_id ).kind := parent_id;      -- assign subtype
         identifiers( newtype_id ).class := subClass;      -- subtype class
         identifiers( newtype_id ).genKind :=              -- copy index type
             identifiers( parent_id ).genKind;             -- / generic type
         if identifiers( parent_id ).list then             -- an array?
            identifiers( newtype_id ).list := true;        -- this also array
            identifiers( newtype_id ).firstBound :=        -- copy first bnd
               identifiers( parent_id ).firstBound;
            identifiers( newtype_id ).lastBound :=         -- copy last bnd
               identifiers( parent_id ).lastBound;
         end if;
      elsif syntax_check then                              -- syntax check?
         identifiers( newtype_id ).kind := parent_id;      -- assign subtype
         identifiers( newtype_id ).class := subClass;      -- subtype class
         if identifiers( parent_id ).list then             -- an array?
            identifiers( newtype_id ).list := true;        -- this also array
         end if;
      else                                                 -- otherwise
         b := deleteIdent( newtype_id );                   -- discard subtype
      end if;

      -- Programming-by-contract (accept function)
      if token = accept_t then
         ParseAcceptClause( newtype_id );
      elsif token /= symbol_t and identifiers( token ).value.all /= ";" then
         err( "accept or ';' expected" );
      end if;
   end if;
end ParseSubtype;

procedure ParseIfBlock is
-- Syntax: if-block = "if"... "elsif"..."else"..."end if"
  expr_val  : unbounded_string;
  expr_type : identifier;
  b : boolean := false;
  handled : boolean := false;
  backup_sc : boolean;
begin

  -- The handling of an if block is very tricky because the blocks
  -- do not only include what is between the parts of the if, but
  -- the expressions themselves.  Plus there's the problem of exiting
  -- gracefully if an exit statement is encountered.  All of this
  -- makes handling this statement more complicated than you might
  -- think.

  -- if expr then statements

  expect( if_t );                                          -- "if"
  if token = if_t then                                     -- this error is
     err( "redundant " & optional_bold( "if" ) );          -- from GNAT
  end if;
  ParseExpression( expr_val, expr_type );                  -- expression
  if not baseTypesOk( boolean_t, expr_type ) then          -- not a bool result?
     err( "boolean expression expected" );
  else                                                     -- else convert bool
     b := expr_val = "1";                                  -- to real boolean
  end if;
  expect( then_t );                                        -- "then"
  if token = then_t then                                   -- this error is
     err( "redundant " & optional_bold( "then" ) );        -- from GNAT
  end if;
  if b then                                                -- was true?
     ParseBlock( elsif_t, else_t );                        -- handle if block
     handled := true;                                      -- remember we did it
                                                           -- even elsifs and else line
  else                                                     -- otherwise
     SkipBlock( elsif_t, else_t );                         -- skip if block
  end if;

  -- elsif expr then statements

  -- temporarily switch to syntax check mode when required to skip expression

  while token = elsif_t loop                               -- a(nother) elsif?
     if handled then                                       -- already handled?
        backup_sc := syntax_check;                         -- don't exec elsif
        syntax_check := true;                              -- expression
     end if;
     expect( elsif_t );                                    -- "elsif"
     if token = elsif_t then                               -- this error is
        err( "redundant " & optional_bold( "elsif" ) );    -- from GNAT
     end if;
     ParseExpression( expr_val, expr_type );               -- expression
     if not baseTypesOk( boolean_t, expr_type ) then       -- not bool result?
        err( "boolean expression expected" );
     else                                                  -- else convert bool
        b := expr_val = "1";                               -- to real boolean
     end if;
     if handled then                                       -- already handled?
        syntax_check := backup_sc;                         -- restore flag
     end if;                                               -- for SkipBlock
     expect( then_t );                                     -- "then"
     if token = then_t then                                -- this is from
        err( "redundant " & optional_bold( "then" ) );     -- GNAT
     end if;
     if b and not handled then                             -- true (and not previously done)
        ParseBlock( elsif_t, else_t );                     -- handle the elsif block
        handled := true;                                   -- remember we did it
     else                                                  -- otherwise
        SkipBlock( elsif_t, else_t );                      -- skip elsif block
     end if;
  end loop;

  -- by this point syntax check mode should be restored (if it was altered)

  -- else statements

  if token = else_t then                                   -- else part?
     if handled then                                       -- already handled?
        backup_sc := syntax_check;                         -- don't exec else
        syntax_check := true;                              -- for --trace
     end if;
     expect( else_t );                                     -- "else"
     if handled then                                       -- already handled?
        syntax_check := backup_sc;                         -- restore flag
     end if;                                               -- for SkipBlock
     if token = else_t then                                -- this is from
        err( "redundant " & optional_bold( "else" ) );     -- GNAT
     end if;
     if not handled then                                   -- nothing handled yet?
        ParseBlock;                                        -- handle else block
     else                                                  -- otherwise
        SkipBlock;                                         -- skip else block
     end if;
  end if;

  -- end if

  expect( end_t );                                         -- "end if"
  expect( if_t );

end ParseIfBlock;


-----------------------------------------------------------------------------
--  STATIC BLOCK
--
-- Conditionally run code based on a static expression.  Part of static if.
-- Only pragmas, static if's or case's allowed.
-----------------------------------------------------------------------------

procedure ParseStaticBlock( termid1, termid2 : identifier := keyword_t ) is
  -- Syntax: block = "general-stmt [general-stmt...] termid1 | termid2"
begin
  if token = end_t or token = eof_t or token = termid1 or token = termid2 then
     err( "missing statement or command" );
  end if;
  while token /= end_t and token /= eof_t and token /= termid1 and token /= termid2 loop
     if token = pragma_t then
        ParsePragma;
        expectSemicolon;
     elsif token = if_t then
        ParseStaticIfBlock;
        expectSemicolon;
     elsif token = case_t then
        ParseStaticCaseBlock;
        expectSemicolon;
     elsif token = null_t then
        expect( null_t );
        expectSemicolon;
     end if;
  end loop;
end ParseStaticBlock;


-----------------------------------------------------------------------------
--  SKIP STATIC BLOCK
--
-- Conditionally skip code based on a static expression.  Part of static if.
-----------------------------------------------------------------------------

procedure SkipStaticBlock( termid1, termid2 : identifier := keyword_t ) is
  old_error : boolean;
  old_skipping : boolean;
begin
  if token = end_t or token = eof_t or token = termid1 or token = termid2 then
     err( "missing statement or command" );
  end if;
  if syntax_check then               -- if we're checking syntax
     ParseStaticBlock( termid1, termid2 ); -- must process the block to look
     return;                         -- for syntax errors
  end if;
  old_error := syntax_check;
  old_skipping := skipping_block;
  syntax_check := true;
  skipping_block := true;
  -- if an error happens in the block, we were skipping it anyway...
  while token /= end_t and token /= eof_t and token /= termid1 and token /= termid2 loop
      ParseGeneralStatement;         -- step through context
  end loop;
  syntax_check := old_error;
  skipping_block := old_skipping;
end SkipStaticBlock;


-----------------------------------------------------------------------------
-- STATIC IF BLOCK
--
-- Conditionally execute or skip blocks of code based on a static expression.
-- This is tied to parsePolicy: blocks may only contain policy block
-- statements.
-----------------------------------------------------------------------------

procedure ParseStaticIfBlock is
-- Syntax: if-block = "if"... "elsif"..."else"..."end if"
  expr_val  : unbounded_string;
  expr_type : identifier;
  b : boolean := false;
  handled : boolean := false;
  backup_sc : boolean;
begin

  -- The handling of an if block is very tricky because the blocks
  -- do not only include what is between the parts of the if, but
  -- the expressions themselves.  Plus there's the problem of exiting
  -- gracefully if an exit statement is encountered.  All of this
  -- makes handling this statement more complicated than you might
  -- think.

  -- if expr then statements

  expect( if_t );                                          -- "if"
  if token = if_t then                                     -- this error is
     err( "redundant " & optional_bold( "if" ) );          -- from GNAT
  end if;
  ParseStaticExpression( expr_val, expr_type );            -- expression
  if not baseTypesOk( boolean_t, expr_type ) then          -- not a bool result?
     err( "boolean expression expected" );
  else                                                     -- else convert bool
     b := expr_val = "1";                                  -- to real boolean
  end if;
  expect( then_t );                                        -- "then"
  if token = then_t then                                   -- this error is
     err( "redundant " & optional_bold( "then" ) );        -- from GNAT
  end if;
  if b then                                                -- was true?
     ParseStaticBlock( elsif_t, else_t );                  -- handle if block
     handled := true;                                      -- remember we did it
                                                           -- even elsifs and else line
  else                                                     -- otherwise
     SkipStaticBlock( elsif_t, else_t );                   -- skip if block
  end if;

  -- elsif expr then statements

  -- temporarily switch to syntax check mode when required to skip expression

  while token = elsif_t loop                               -- a(nother) elsif?
     if handled then                                       -- already handled?
        backup_sc := syntax_check;                         -- don't exec elsif
        syntax_check := true;                              -- expression
     end if;
     expect( elsif_t );                                    -- "elsif"
     if token = elsif_t then                               -- this error is
        err( "redundant " & optional_bold( "elsif" ) );    -- from GNAT
     end if;
     ParseStaticExpression( expr_val, expr_type );         -- expression
     if not baseTypesOk( boolean_t, expr_type ) then       -- not bool result?
        err( "boolean expression expected" );
     else                                                  -- else convert bool
        b := expr_val = "1";                               -- to real boolean
     end if;
     if handled then                                       -- already handled?
        syntax_check := backup_sc;                         -- restore flag
     end if;                                               -- for SkipBlock
     expect( then_t );                                     -- "then"
     if token = then_t then                                -- this is from
        err( "redundant " & optional_bold( "then" ) );     -- GNAT
     end if;
     if b and not handled then                             -- true (and not previously done)
        ParseStaticBlock( elsif_t, else_t );               -- handle the elsif block
        handled := true;                                   -- remember we did it
     else                                                  -- otherwise
        SkipStaticBlock( elsif_t, else_t );                -- skip elsif block
     end if;
  end loop;

  -- by this point syntax check mode should be restored (if it was altered)

  -- else statements

  if token = else_t then                                   -- else part?
     if handled then                                       -- already handled?
        backup_sc := syntax_check;                         -- don't exec else
        syntax_check := true;                              -- for --trace
     end if;
     expect( else_t );                                     -- "else"
     if handled then                                       -- already handled?
        syntax_check := backup_sc;                         -- restore flag
     end if;                                               -- for SkipBlock
     if token = else_t then                                -- this is from
        err( "redundant " & optional_bold( "else" ) );     -- GNAT
     end if;
     if not handled then                                   -- nothing handled yet?
        ParseStaticBlock;                                  -- handle else block
     else                                                  -- otherwise
        SkipStaticBlock;                                   -- skip else block
     end if;
  end if;

  -- end if

  expect( end_t );                                         -- "end if"
  expect( if_t );

end ParseStaticIfBlock;


procedure ParseCaseBlock is
-- Syntax: case-block = "case" ident "is" "when" const-ident ["|"...] "=>" ...
-- "when others =>" ..."end case"
  test_id : identifier;
  case_id : identifier;
  handled : boolean := false;
  b       : boolean := false;
begin

  -- case id is

  expect( case_t );                                        -- "case"
  ParseIdentifier( test_id );                              -- identifier to test
  -- we allow const because parameters are consts in Bush 1.x.
  --if class_ok( test_id, constClass, varClass ) then
  if class_ok( test_id, varClass ) then
     expect( is_t );                                       -- "is"
  end if;

  -- when const-id =>

  if token /= when_t then                                 -- first when missing?
     expect( when_t );                                    -- force error
  end if;
  while token = when_t loop
     expect( when_t );                                    -- "when"
     exit when error_found or token = others_t;
     -- this should be ParseConstantIdentifier
     b := false;                                          -- assume case fails
     loop
        if token = strlit_t then                          -- strlit allowed
           if baseTypesOk( identifiers( test_id ).kind, string_t ) then
              case_id := token;
              getNextToken;
           end if;
        elsif token = charlit_t then                      -- charlit allowed
           if baseTypesOk( identifiers( test_id ).kind, character_t ) then
              case_id := token;
              getNextToken;
           end if;
        elsif token = number_t then                       -- num lit allowed
           if uniTypesOk( identifiers( test_id ).kind, uni_numeric_t ) then
              case_id := token;
              getNextToken;
           end if;
        else                                             -- constant allowed
           ParseIdentifier( case_id );                         -- get the case
           if identifiers( case_id ).usage /= constantUsage    -- is constant
              and identifiers( case_id ).class /= enumClass then -- or enum?
              err( "variable not allowed as a case" );         -- error if not
           elsif baseTypesOk( identifiers( test_id ).kind,
                 identifiers( case_id ).kind ) then            -- types good?
              null;
           end if;
        end if;
        if not error_found then                         -- OK? check case
           b := b or                                    -- against test var
             Ada.Strings.Unbounded.trim( identifiers( test_id ).value.all, Ada.Strings.left ) = Ada.Strings.Unbounded.trim( identifiers( case_id ).value.all, Ada.Strings.left );
        end if;
        exit when error_found or token /= symbol_t or identifiers( token ).value.all /= "|";
        expect( symbol_t, "|" );                        -- expect alternate
     end loop;
     expect( symbol_t, "=>" );                             -- "=>"
     if b and not handled and not exit_block then          -- handled yet?
        ParseBlock( when_t );                              -- if not, handle
        handled := true;                                   -- and remember done
     else
        SkipBlock( when_t );                               -- else skip case
     end if;
  end loop;

  -- others part

  if token /= others_t then                                -- a little clearer
     err( "when others expected" );                        -- if pointing at
  end if;                                                  -- end case
  expect( others_t );                                      -- "others"
  expect( symbol_t, "=>" );                                -- "=>"
  if not handled and not exit_block then                   -- not handled yet?
     ParseBlock;                                           -- handle now
  else                                                     -- else just
     SkipBlock;                                            -- skip
  end if;

  -- end case

  expect( end_t );                                         -- "end case"
  expect( case_t );

end ParseCaseBlock;

-----------------------------------------------------------------------------
-- STATIC CASE BLOCK
--
-- Conditionally execute code based on a static expression value.  This is
-- tied to parsePolicy: only policy block statements allowed in the code.
-----------------------------------------------------------------------------

procedure ParseStaticCaseBlock is
-- Syntax: case-block = "case" ident "is" "when" const-ident ["|"...] "=>" ...
-- "when others =>" ..."end case"
-- constants only
  test_id : identifier;
  case_id : identifier;
  handled : boolean := false;
  b       : boolean := false;
begin

  -- case id is

  expect( case_t );                                        -- "case"
  ParseStaticIdentifier( test_id );                        -- identifier to test
  -- we allow const because parameters are consts in Bush 1.x.
  if class_ok( test_id, varClass ) then
     if identifiers( test_id ).usage /= constantUsage then
        err( "constant expected" );
     end if;
     expect( is_t );                                       -- "is"
  end if;

  -- when const-id =>

  if token /= when_t then                                 -- first when missing?
     expect( when_t );                                    -- force error
  end if;
  while token = when_t loop
     expect( when_t );                                    -- "when"
     exit when error_found or token = others_t;
     -- this should be ParseConstantIdentifier
     b := false;                                          -- assume case fails
     loop
        if token = strlit_t then                          -- strlit allowed
           if baseTypesOk( identifiers( test_id ).kind, string_t ) then
              case_id := token;
              getNextToken;
           end if;
        elsif token = charlit_t then                      -- charlit allowed
           if baseTypesOk( identifiers( test_id ).kind, character_t ) then
              case_id := token;
              getNextToken;
           end if;
        elsif token = number_t then                       -- num lit allowed
           if uniTypesOk( identifiers( test_id ).kind, uni_numeric_t ) then
              case_id := token;
              getNextToken;
           end if;
        else                                             -- constant allowed
           ParseIdentifier( case_id );                         -- get the case
           if identifiers( case_id ).usage /= constantUsage    -- is constant
              and identifiers( case_id ).class /= enumClass then -- or enum?
              err( "variable not allowed as a case" );         -- error if not
           elsif baseTypesOk( identifiers( test_id ).kind,
                 identifiers( case_id ).kind ) then            -- types good?
              null;
           end if;
        end if;
        if not error_found then                         -- OK? check case
           b := b or                                    -- against test var
             identifiers( test_id ).value.all = identifiers( case_id ).value.all;
        end if;
        exit when error_found or token /= symbol_t or identifiers( token ).value.all /= "|";
        expect( symbol_t, "|" );                        -- expect alternate
     end loop;
     expect( symbol_t, "=>" );                             -- "=>"
     if b and not handled and not exit_block then          -- handled yet?
        ParseStaticBlock( when_t );                        -- if not, handle
        handled := true;                                   -- and remember done
     else
        SkipStaticBlock( when_t );                         -- else skip case
     end if;
  end loop;

  -- others part

  if token /= others_t then                                -- a little clearer
     err( "when others expected" );                        -- if pointing at
  end if;                                                  -- end case
  expect( others_t );                                      -- "others"
  expect( symbol_t, "=>" );                                -- "=>"
  if not handled and not exit_block then                   -- not handled yet?
     ParseBlock;                                           -- handle now
  else                                                     -- else just
     SkipBlock;                                            -- skip
  end if;

  -- end case

  expect( end_t );                                         -- "end case"
  expect( case_t );

end ParseStaticCaseBlock;


-----------------------------------------------------------------------------
-- LOOPS
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- LOOP
-----------------------------------------------------------------------------

procedure ParseLoopBlock is
  -- Syntax: loop-block = "loop" ... "end loop"
  exit_on_entry : boolean := exit_block;
begin

  pushBlock( newScope => false, newName => "loop loop" );  -- start new scope

  if syntax_check or exit_block then
     expect( loop_t );                                     -- "loop"
     ParseBlock;                                           -- check loop block
     goto loop_done;
  end if;

  loop
     expect( loop_t );                                     -- "loop"
     ParseBlock;                                           -- handle loop block
     exit when exit_block or error_found or token = eof_t;
     topOfBlock;                                           -- jump to top of block
  end loop;

<<loop_done>>
  pullBlock;                                               -- end of while scope
  if not syntax_check and not exit_on_entry then           -- ignore exit when checking
     if exit_block and not done then                       -- exiting and not returning?
        if trace then
           Put_trace( "exited loop" );
        end if;
        exit_block := false;                               -- we handled exit_block
     end if;
  end if;

  expect( end_t );                                         -- "end loop"
  expect( loop_t );
end ParseLoopBlock;


-----------------------------------------------------------------------------
-- WHILE
-----------------------------------------------------------------------------

procedure ParseWhileBlock is
  -- Syntax: while-block = "while" bool-expr "loop" ... "end loop"
  expr_val  : unbounded_string;
  expr_type : identifier;
  b : boolean := false;
  exiting : boolean := false;
  exit_on_entry : boolean := exit_block;
begin
  pushBlock( newScope => false, newName => "while loop" ); -- start new scope

  if syntax_check or exit_block then
     expect( while_t );                                    -- "while"
     if token = while_t then                               -- this is from
        err( "redundant " & optional_bold( "while" ) );    -- GNAT
     end if;
     ParseExpression( expr_val, expr_type );               -- expression
     if not baseTypesOk( boolean_t, expr_type ) then       -- not boolean?
        err( "boolean expression expected" );
     end if;
     expect( loop_t );                                     --- "loop"
     ParseBlock;                                           -- check while block
     goto loop_done;
  end if;

  loop
     expect( while_t );                                    -- "while"
     ParseExpression( expr_val, expr_type );               -- expression
     if not baseTypesOk( boolean_t, expr_type ) then       -- not boolean?
        err( "boolean expression expected" );
        exit;
     elsif expr_val /= "1" or error_found or exit_block then -- skipping?
        expect( loop_t );                                  -- "loop"
        SkipBlock;                                         -- skip while block
        exit;                                              -- and quit
     end if;                                               -- otherwise do loop
     if trace then
        put_trace( "expression is true" );
     end if;
     expect( loop_t );                                     -- "loop"
     ParseBlock;                                           -- handle while block
     exit when exit_block or error_found or token = eof_t;
     topOfBlock;                                           -- jump to top of block
  end loop;

<<loop_done>>
  pullBlock;                                               -- end of while scope
  if not syntax_check and not exit_on_entry then           -- ignore exit when checking
     if exit_block and not done then                          -- exiting and not returning?
        if trace then
           Put_trace( "exited while loop" );
        end if;
        exit_block := false;                                  -- we handled exit_block
     end if;
  end if;

  expect( end_t );                                         -- "end loop"
  expect( loop_t );
end ParseWhileBlock;


-----------------------------------------------------------------------------
-- FOR
-----------------------------------------------------------------------------

procedure ParseForBlock is
  -- Syntax: for-block = "for" local-var "in" expr ".." expr "loop" ... "end loop"
  expr1_val  : unbounded_string;
  expr1_type : identifier;
  expr2_val  : unbounded_string;
  expr2_type : identifier;
  expr2_num  : long_float;
  b : boolean := false;
  test1 : boolean := false;
  test2 : boolean := false;
  exiting : boolean := false;
  for_var   : identifier;
  firstTime : boolean := true;
  isReverse   : boolean := false;
  exit_on_entry : boolean := exit_block;
  for_name : unbounded_string;
begin

  pushBlock( newScope => true, newName => "for loop" );  -- start new scope
  -- well, not strictly a new scope, but we'll need to do this
  -- to implement automatic declaration of the index variable

  if syntax_check or exit_block then
     -- this is complicated enough it should be in it's own nested procedure
     expect( for_t );                                   -- "for"
     for_name := identifiers( token ).name;             -- save var name
     if token = number_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "number" ) );
     elsif token = strlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "string literal" ) );
     elsif token = backlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "backquoted literal" ) );
     elsif token = charlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "character literal" ) );
     elsif is_keyword( token ) and token /= eof_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "keyword" ) );
     elsif token = symbol_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "symbol" ) );
     elsif identifiers( token ).kind = new_t then          -- for var
        discardUnusedIdentifier( token );               -- brand new? toss it
     end if;                                            -- we'll declare it
     getNextToken;                                      -- declare after range
     expect( in_t );                                    -- "in"
     if token = reverse_t then                          -- "reverse"?
        isReverse := true;
        expect( reverse_t );
     end if;
     ParseExpression( expr1_val, expr1_type );          -- low range
     expect( symbol_t, ".." );                          -- ".."
     ParseExpression( expr2_val, expr2_type );          -- high range
     -- declare for var down here in case older var with same name
     -- used in for loop range (so that for k in k..k+1 is legit)
     declareIdent( for_var, for_name, uni_numeric_t);   -- declare for var
     -- the for index is not covered by unused identifiers because it
     -- might not be used within the loop...might just be a repeat loop
     if syntax_check and then not error_found then
        identifiers( for_var ).wasReferenced := true;
        identifiers( for_var ).wasWritten := true;
        identifiers( for_var ).wasFactor := true;
     end if;
     if baseTypesOk( expr1_type, expr2_type ) then      -- check types
        if getUniType( expr1_type ) = uni_numeric_t then
           null;
       elsif getUniType( expr1_type ) = root_enumerated_t then
           null;
       end if;
       if not error_found then
          if isReverse then
             identifiers( for_var ).kind := expr2_type;     -- this type
          else
             identifiers( for_var ).kind := expr1_type;     -- this type
           end if;
        end if;
     end if;
     expect( loop_t );
     ParseBlock;                                           -- check for block
     goto abort_loop;
  end if;

  loop
     expect( for_t );                                      -- "for"
     if firstTime then
        if identifiers( token ).kind = new_t then          -- for var
           for_var := token;                               -- brand new? ok
        else                                               -- else declare locally
           declareIdent( for_var,                          -- will be const below
              identifiers( token ).name,
              uni_numeric_t );
           -- This variable is written to by the for command itself.  So
           -- mark that for later identifier usage tests.
        end if;
        getNextToken;
        expect( in_t );                                    -- "in"
        if token = reverse_t then                          -- "reverse"?
           isReverse := true;
           expect( reverse_t );
        end if;
        ParseExpression( expr1_val, expr1_type );          -- low range
        expect( symbol_t, ".." );                          -- ".."
        ParseExpression( expr2_val, expr2_type );          -- high range
        if verboseOpt then
           put_trace( "in " & to_string( expr1_val ) & ".." & to_string( expr2_val ) );
        end if;

        --if error_found then                              -- errors?
        --    goto abort_loop;                             -- go no further
        --end if;
        if baseTypesOk( expr1_type, expr2_type ) then      -- check types
           if getUniType( expr1_type ) = uni_numeric_t then
              null;
           elsif getUniType( expr1_type ) = root_enumerated_t then
              null;
           else
              err( "numeric or enumerated type expected" );
              -- should be err_previous but haven't exported it yet
           end if;
           if not error_found then
              if isReverse then
                 identifiers( for_var ).value.all := expr2_val; -- for var is
                 identifiers( for_var ).kind := expr2_type;     -- this type
                 identifiers( for_var ).class := varClass;      -- make const
                 identifiers( for_var ).usage := constantUsage;
                 if isExecutingCommand then
                    expr2_num := to_numeric( expr1_val );
                 end if;
              else
                 identifiers( for_var ).value.all := expr1_val; -- for var is
                 identifiers( for_var ).kind := expr1_type;     -- this type
                 identifiers( for_var ).class := varClass;      -- make const
                 identifiers( for_var ).usage := constantUsage;
                 if isExecutingCommand then
                    expr2_num := to_numeric( expr2_val );
                 end if;
              end if;
           end if;
        end if;
        expect( loop_t );                                  -- "loop"
        firstTime := false;                                -- don't do this again
     else
        -- don't interpret for line after first time
-- is this necessary any more?
        while token /= loop_t loop                         -- skip to
           getNextToken;                                 -- "loop"
        end loop;
        expect( loop_t );
        if isReverse then
           if isExecutingCommand then
              identifiers( for_var ).value.all := to_unbounded_string(
                  long_float( to_numeric( identifiers( for_var ).value.all ) - 1.0 ) );
           end if;
        else
           if isExecutingCommand then
              identifiers( for_var ).value.all := to_unbounded_string(
                  long_float( to_numeric( identifiers( for_var ).value.all ) + 1.0 ) );
           end if;
        end if;
     end if;
     if not isExecutingCommand then -- includes errors or exiting
        skipBlock;
        exit;
     elsif isReverse then
        if to_numeric( identifiers( for_var ).value.all ) < expr2_num then
           skipBlock;
           exit;
        end if;
     elsif to_numeric( identifiers( for_var ).value.all ) > expr2_num then
         skipBlock;
         exit;
     end if;
     if trace then
        put_trace(
            to_string( identifiers( for_var ).name ) & " := '" &
            to_string( identifiers( for_var ).value.all ) & "'" );
     end if;
     ParseBlock;                                           -- handle for block
     exit when exit_block or error_found or token = eof_t;
     topOfBlock;                                           -- jump to top of block
  end loop;

<<abort_loop>>
  pullBlock;                                               -- end of while scope
  if not syntax_check and not exit_on_entry then           -- ignore exit when checking
     if exit_block and not done then                          -- exiting and not returning?
        if trace then
           Put_trace( "exited for loop" );
        end if;
        exit_block := false;                                  -- we handled exit_block
     end if;
  end if;

  expect( end_t );                                         -- "end loop"
  expect( loop_t );

end ParseForBlock;

-----------------------------------------------------------------------------
-- Other statements
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- DELAY
-----------------------------------------------------------------------------

procedure ParseDelay is
  -- Syntax: delay expression
  -- Source: Ada built-in
  expr_val  : unbounded_string;
  expr_type : identifier;
begin
  expect( delay_t );
  ParseExpression( expr_val, expr_type );
  if baseTypesOk( expr_type, duration_t ) then
     if isExecutingCommand then
        begin
          delay duration( to_numeric( expr_val ) );
        exception when others =>
          err_exception_raised;
        end;
        if trace then
           put_trace( "duration := " & to_string( expr_val ) );
        end if;
     end if;
  end if;
end ParseDelay;


-----------------------------------------------------------------------------
-- TYPESET
-----------------------------------------------------------------------------

procedure ParseTypeset is
  -- Syntax: typeset identifier is type
  -- Source: BUSH built-in
  -- TODO: this should be converted to a build-in shell command
  id     : identifier;
  typeid : identifier := eof_t;
  b      : boolean;
begin
   expect( typeset_t );
   if onlyAda95 then
      discardUnusedIdentifier( token );
      err( "typeset is not allowed with " & optional_bold( "pragma ada_95" ) );
      return;
   elsif inputMode /= interactive and inputMode /= breakout then
      discardUnusedIdentifier( token );
      err( "typeset only allowed in an interactive session" );
      return;
   end if;
   if identifiers( token ).kind = new_t then
      ParseNewIdentifier( id );
   else
      ParseIdentifier( id );
   end if;
   if token = is_t then
      expect( is_t );
      if token = exception_t then
         err( "types cannot be changed to an exception" );
      else
         ParseIdentifier( typeid );
      end if;
   end if;
   if isExecutingCommand then
      if identifiers( id ).kind = exception_t then
         err( "exception types cannot be changed to another type" );
      elsif typeid = eof_t then
         identifiers( id ).kind := universal_t;
      elsif identifiers( id ).list then
         err( "typeset with array types not yet implemented" );
      elsif identifiers( typeid ).list then
         err( "typeset with array types not yet implemented" );
      elsif identifiers( id ).renamed_count > 0 then
         err_renaming( id );
      elsif identifiers( id ).renaming_of /= identifiers'first then
         err( "cannot change the type of a renaming" );
      else
         begin
            identifiers( id ).value.all := castToType(
               identifiers( id ).value.all, typeid );
            identifiers( id ).kind := typeid;
         exception when others =>
            err_exception_raised;
         end;
      end if;
   else
      b := deleteIdent( id );
   end if;
end ParseTypeset;


-----------------------------------------------------------------------------
--  PARSE SHELL WORD
--
-- Parse and expand a shell word argument.  Return a shellWordList containing
-- the original pattern, the expanded words and their types.  If the first is
-- true, the word should be the first word.  If there is already shell words
-- in the list, any new words will be appended to the list.  The caller is
-- responsible for clearing (deallocating) the list.
--   Expansion is the process of performing substitutions on a shell word.
--
-- Bourne shell expansions include:
--   TYPE                  PATTERN        EX. WORDS        STATUS
--   Brace expansion       a{.txt,.dat}   a.txt a.dat      not implemented
--   Tilde expansion       ~/a.txt        /home/ken/a.txt  OK
--   Variable expansion    $HOME/a.txt    /home/ken/a.txt  no special $
--   Command substituion   `echo a.txt`   a.txt            no $(...)
--   Arithmetic expansion  -              -                not implemented
--   Word splitting        a\ word        "a word"         OK
--   Pathname expansion    *.txt          a.txt b.txt      OK
--
-- Since BUSH has to interpret the shell words as part of the byte code
-- compilation, word splitting before pathname expansion.  This means that
-- certain rare expansions will have different results in BUSH than in a
-- standard Bourne shell.  (Some might call this an improvement over the
-- standard.)  Otherwise, BUSH conforms to the Bourne shell standard.
--
-- UsedEscape is true if the shell word was escaped
--
-- The wordType is used to differentiate between words like "|" (a string)
-- and | (the pipe operator) which look the same once quotes are removed.
-----------------------------------------------------------------------------

procedure ParseShellWord( wordList : in out shellWordList.List; First : boolean := false ) is

-- these should be global
semicolon_string : constant unbounded_string := to_unbounded_string( ";" );
--   semi-colon, as an unbounded string

verticalbar_string : constant unbounded_string := to_unbounded_string( "|" );
--   vertical bar, as an unbounded string

ampersand_string : constant unbounded_string := to_unbounded_string( "&" );
--   ampersand, as an unbounded string

redirectIn_string : constant unbounded_string := to_unbounded_string( "<" );
--   less than, as an unbounded string

redirectOut_string : constant unbounded_string := to_unbounded_string( ">" );
--   greater than, as an unbounded string

redirectAppend_string : constant unbounded_string := to_unbounded_string( ">>" );
--   double greater than, as an unbounded string

redirectErrOut_string : constant unbounded_string := to_unbounded_string( "2>" );
--   '2' + greater than, as an unbounded string

redirectErrAppend_string : constant unbounded_string := to_unbounded_string( "2>>" );
--   '2' + double greater than, as an unbounded string

redirectErr2Out_string : constant unbounded_string := to_unbounded_string( "2>&1" );
--   '2' + greater than + ampersand and '1', as an unbounded string

itself_string : constant unbounded_string := to_unbounded_string( "@" );
--   itself, as an unbounded string

  ch          : character;
  inSQuote    : boolean := false;                      -- in single quoted part
  inDQuote    : boolean := false;                      -- in double quoted part
  inBQuote    : boolean := false;                      -- in double quoted part
  inBackslash : boolean := false;                      -- in backquoted part
  inDollar    : boolean := false;                      -- $ expansion
  wasSQuote   : boolean := false;                      -- is $ expan in sin qu
  wasDQuote   : boolean := false;                      -- is $ expan in dbl qu
  expansionVar: unbounded_string;                      -- the $ name
  escapeGlobs : boolean := false;                      -- escaping glob chars
  ignoreTerminatingWhitespace : boolean := false;                 -- SQL word has whitespace in it (do not use whitespace as a word terminator)
  expandInSingleQuotes : boolean := false;  -- SQL words allow $ expansion for single quotes (for PostgreSQL)
  stripQuoteMarks : boolean := true; -- SQL words require quotes words left in the word
  startOfBQuote : integer;

  addExpansionSQuote : boolean := false;               -- SQL, add ' after exp
  addExpansionDQuote : boolean := false;               -- SQL, add " after exp
  temp_id     : identifier;                            -- for ~ processing
  shell_word  : unbounded_string;

  word        : unbounded_string;
  wordLen     : integer;
  pattern     : unbounded_string;
  wordType    : aShellWordType;

  procedure dollarExpansion is
     -- perform a dollar expansion by appending a variable's value to the
     -- shell word.
-- NOTE: what about $?, $#, $1, etc?  These need to be handed specially here?
-- NOTE: special $ expansion, including ${...} should be handled here
     id      : identifier;
     subword : unbounded_string;
     ch      : character;
  begin
    --put_line( "dollarExpansion for var """ & expansionVar & """" ); -- DEBUG
    -- Handle Special Substitutions ($#, $? $$, $0...$9 )
    if expansionVar = "#" then
       if isExecutingCommand then
          subword := to_unbounded_string( integer'image( Argument_Count-optionOffset) );
          delete( subword, 1, 1 );
       end if;
    elsif expansionVar = "?" then
       if isExecutingCommand then
          subword := to_unbounded_string( last_status'img );
          delete( subword, 1, 1 );
       end if;
    elsif expansionVar = "$" then
       if isExecutingCommand then
          subword := to_unbounded_string( aPID'image( getpid ) );
          delete( subword, 1, 1 );
       end if;
    elsif expansionVar = "0" then
       if isExecutingCommand then
          subword := to_unbounded_string( Ada.Command_Line.Command_Name );
       end if;
    elsif length( expansionVar ) = 1 and (expansionVar >= "1" and expansionVar <= "9" ) then
       if syntax_check and then not suppress_word_quoting and then not inDQuote then
          err( "style issue: expected double quoted word parameters in shell or SQL command to stop word splitting" );
       end if;
       if isExecutingCommand then
          begin
             subword := to_unbounded_string(
                 Argument(
                   integer'value(
                     to_string( " " & expansionVar ) )+optionOffset ) );
          exception when program_error =>
             err( "program_error exception raised" );
          when others =>
             err( "no such argument" );
          end;
       end if;
    else
       if syntax_check and then not suppress_word_quoting and then not inDQuote then
          err( "style issue: expected double quoted word parameters in shell or SQL command to prevent word splitting" );
       end if;
       -- Regular variable substitution
       findIdent( expansionVar, id );
       if id = eof_t then
          -- TODO: this check takes place after the token is read, so token
          -- following the one in question is highlighted
          err( optional_bold( to_string( expansionVar ) ) & " not declared" );
       else
          if syntax_check then
             identifiers( id ).wasReferenced := true;
             subword := to_unbounded_string( "undefined" );
          else
             subword := identifiers( id ).value.all;       -- word to substit.
             if not inDQuote then                          -- strip spaces
                subword := Ada.Strings.Unbounded.Trim(     -- unless double
                   subword, Ada.Strings.Both );            -- quotes;
             elsif getUniType( id ) = uni_numeric_t then   -- a number?
                if length( subword ) > 0 then              -- something there?
                   if element( subword, 1 ) = ' ' then     -- leading space
                      delete( subword, 1, 1 );             -- we don't want it
                   end if;
                end if;
             end if;
          end if;
       end if;
    end if;
    -- escapeGlobs affects the variable substitution
    for i in 1..length( subword ) loop                  -- each letter
        ch := element( subword, i );                    -- get it
        if escapeGlobs and not inBackslash then         -- esc glob chars?
           case ch is                                   -- is a glob char?
           when '*' => pattern := pattern & "\";        -- escape *
           when '[' => pattern := pattern & "\";        -- escape [
           when '\' => pattern := pattern & "\";        -- escape \
           when '?' => pattern := pattern & "\";        -- escape *
           when others => null;                         -- others? no esc
           end case;
        end if;
        pattern := pattern & ch;                        -- add the letter
        word := word & ch;                              -- add the letter
    end loop;
    inDollar := false;
  -- SQL words require the quote marks to be left intact in the word.
  -- Unfortunately, this has to be checked after the quote character has
  -- been processed.  This checks for the flag variables to attach a quote
  -- mark retroactively.
    if addExpansionSQuote then
        word := word & "'";
        addExpansionSQuote := false;
    end if;
    if addExpansionDQuote then
        word := word & ASCII.Quotation;
        addExpansionDQuote := false;
    end if;
  end dollarExpansion;

  -- parseShellWord: pathnameExpansion
  --
  -- Perform shell pathname expansion by using the shell word as a glob
  -- pattern and searching the current directory.  Return a list of shell
  -- words created by the expansion.
  --
  -- Note: file name length is limited to 256 characters.

  procedure pathnameExpansion( word, pattern : unbounded_string; list : in out shellWordList.List ) is
    globCriteria : regexp;
    currentDir   : Dir_Type;
    fileName     : string(1..256);
    fileNameLen  : natural;
    found        : boolean := false;
    noPWD        : boolean := false;
    dirpath      : string := to_string( dirname( word ) );
    globexpr     : string := to_string( basename( pattern ) );
    noDir        : boolean;
    isOpen       : boolean := false;
  begin
    --put_line( "pathnameExpansion for original pattern """ & pattern & """" ); -- DEBUG
    --put_line( "pathnameExpansion for expanded word """ & word & """" ); -- DEBUG
    --put_line( "wasDQuote: " & wasDQuote'img ); -- DEBUG
    -- In the case of a syntax check, return the word as-is as a place holder.
    -- Don't try to glob it.
    if syntax_check then
       shellWordList.Queue( wordList, aShellWord'( normalWord, pattern, shell_word ) );
       return;
    end if;
    -- word is an empty string? it still counts: param is a null string
    if length( pattern ) = 0 or length( word ) = 0 then
       shellWordList.Queue( list, aShellWord'( normalWord, pattern, null_unbounded_string ) );
       return;
    end if;
    -- otherwise, prepare to glob the current directory
    noDir := globexpr = pattern;
    globCriteria := Compile( globexpr, Glob => true, Case_Sensitive => true );
    begin
      open( currentDir, dirpath );
      isOpen := true;
    exception when others =>
      noPWD := true;
    end;
    -- is the current directory invalid? then param is just the word
    if noPWD then
       shellWordList.Queue( list, aShellWord'( normalWord, pattern, word ) );
       return;
    end if;
    -- Linux/UNIX: skip "." and ".." directory entries
    --read( currentDir, fileName, fileNameLen );
    --read( currentDir, fileName, fileNameLen );
    -- search the directory, adding files that match the glob pattern
    loop
      read( currentDir, fileName, fileNameLen );
      -- KB: 12/02/18 - no longer returns "." and "..".  Commented out reads
      -- but as a safety precaution check the filename here.
      exit when fileNameLen = 0;
      if filename( 1..fileNameLen ) = "." then
         null;
      elsif filename( 1..fileNameLen ) = ".." then
         null;
      elsif Match( fileName(1..fileNameLen ) , globCriteria ) then
         if noDir then
            shellWordList.Queue( list, aShellWord'(
               normalWord,
               pattern,
               to_unbounded_string( fileName( 1..fileNameLen ) ) ) );
         else
            -- root directory?  no need to add directory delimiter
            if dirpath'length = 1 and dirpath(1) = directory_delimiter then
               shellWordList.Queue( list, aShellWord'(
                  normalWord,
                  pattern,
                  to_unbounded_string( dirpath & fileName( 1..fileNameLen ) ) ) );
            else
               shellWordList.Queue( list, aShellWord'(
                  normalWord,
                  pattern,
                  to_unbounded_string( dirpath & directory_delimiter & fileName( 1..fileNameLen ) ) ) );
            end if;
         end if;
         found := true;
      end if;
    end loop;
    -- there are no matches? word still counts: the param is just the word
    if not found then
       shellWordList.Queue( list, aShellWord'( normalWord, pattern, word ) );
    end if;
    if isOpen then
       close( currentDir );
    end if;
  exception when ERROR_IN_REGEXP =>
    -- The globbing expression may be bad.  For example,
    -- '/</{ :loop s/<[^>]*>//g /</{ N b loop } }'
    -- will be split into ... / globExpr = { N b loop } }
    -- which will fail with this exception.  There's no way to know if the
    -- expression produced by basename will be glob-able.  So this is not
    -- an error...there's just nothing to glob.
    --
    -- Was:
    -- err( "error in globbing expression """ & globExpr & """" );
    --
    -- Now, queue the shell word as the word just counts as-is.
    shellWordList.Queue( list, aShellWord'( normalWord, pattern, word ) );
    if isOpen then
       close( currentDir );
    end if;
  when DIRECTORY_ERROR =>
    err( "directory error on directory " & dirPath );
  end pathnameExpansion;

  -- Breakup barewords into subwords and do pathname expansion.
  -- Quoted words pathname expanded as-is
  -- TODO: is this too high?  Probably goes lower in the logic. What about the pattern?

  procedure pathnameExpansionWithIFS( word, pattern : unbounded_string; list : in out shellWordList.List ) is
    subword    : unbounded_string;
    subpattern : unbounded_string;
    ch         : character;
    word_pos   : natural := 1;
    pattern_pos: natural := 1;
  begin
    --put_line( "pathnameExpansionWithIFS for original pattern """ & pattern & """" ); -- DEBUG
    --put_line( "pathnameExpansionWithIFS for expanded word """ & word & """" ); -- DEBUG
    --put_line( "wasDQuote: " & wasDQuote'img ); -- DEBUG
    -- if in double quotes, then no IFS handling
    if wasDQuote then
       pathnameExpansion( word, pattern, list );
    elsif wasSQuote then
       shellWordList.Queue( list, aShellWord'( normalWord, pattern, word ) );
    elsif length( pattern ) = 0 or length( word ) = 0 then
       pathnameExpansion( word, pattern, list );
    else
       -- If this is a bareword, break up each piece separated by whitespace
       -- into separate worders to be handled individually.
       while word_pos <= length( word ) loop
          -- break up the word
          while word_pos <= length( word ) loop
             ch := element( word, word_pos );
             exit when ch /= ASCII.HT and ch /= ' ';
             word_pos := word_pos + 1;
          end loop;
          while word_pos <= length( word ) loop
             ch := element( word, word_pos );
             exit when ch = ASCII.HT or ch = ' ';
             subword := subword & ch;
             word_pos := word_pos + 1;
          end loop;
          -- break up the pattern
          while pattern_pos <= length( pattern ) loop
             ch := element( pattern, pattern_pos );
             exit when ch /= ASCII.HT and ch /= ' ';
             pattern_pos := pattern_pos + 1;
          end loop;
          while pattern_pos <= length( pattern ) loop
             ch := element( pattern, pattern_pos );
             --exit when not is_graphic( ch );
             exit when ch = ASCII.HT or ch = ' ';
             subpattern := subpattern & ch;
             pattern_pos := pattern_pos + 1;
          end loop;
          -- expand the whitespace delinated subword
          pathnameExpansion( subword, subpattern, list );
          subword := null_unbounded_string;
          subpattern := null_unbounded_string;
          word_pos := word_pos + 1;
          pattern_pos := pattern_pos + 1;
       end loop;
    end if;
  end pathnameExpansionWithIFS;

begin

  word := null_unbounded_string;
  pattern := null_unbounded_string;
  wordType := normalWord;

  -- Get the next unexpanded word.  A SQL command is a special case: never
  -- expand it.  We don't want the * in "select *" to be replaced with a list
  -- of files.

  -- ignoreTerminatingWhitespace is a workaround and should be redone.  We
  -- need one word but expand the items in the word (for SQL).

  if token = sql_word_t then
     shell_word := identifiers( token ).value.all;
     ignoreTerminatingWhitespace := true;                -- word contains space
     expandInSingleQuotes := true;
     stripQuoteMarks := false;
  else
     -- Otherwise, get a non-SQL shell word
     ParseBasicShellWord( shell_word );
  end if;

  wordLen := length( shell_word ); -- we refer a lot to the length

  -- Null string shell word?  Then nothing to do.

  if wordLen = 0 then
     word := null_unbounded_string;
     pattern := null_unbounded_string;
     wordType := normalWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     getNextToken;
     return;
  end if;

  -- Special Cases
  --
  -- The special shell words are always unescaped and never expand.  We handle
  -- them as special cases before beginning the expansion process.

  ch := Element( shell_word, 1 );                      -- next character

  if ch = ';' then                                     -- semicolon?
     word := semicolon_string;                         -- type
     pattern := semicolon_string;
     wordType := semicolonWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     getNextToken;
     return;

  elsif ch = '|' then                                  -- vertical bar?
     word := verticalbar_string;
     pattern := verticalbar_string;
     wordType := pipeWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     getNextToken;
     return;

  elsif ch = '&' then                                  -- ampersand?
     word := ampersand_string;                         -- type
     pattern := ampersand_string;
     wordType := ampersandWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     getNextToken;
     return;

  elsif ch = '<' then                                  -- less than?
     word := redirectIn_string;                        -- type
     pattern := redirectIn_string;
     wordType := redirectInWord;
     shellWordList.Queue( wordList, aShellWord'( wordtype, pattern, word ) );
     getNextToken;
     return;

  elsif ch = '>' then                                  -- greater than?

     if wordLen > 1 and then Element(shell_word, 2 ) = '>' then -- double greater than?
        word := redirectAppend_string;                 -- type
        pattern := redirectAppend_string;
        wordType := redirectAppendWord;
        shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
        getNextToken;
        return;
     end if;
     word := redirectOut_string;                       -- it's redirectOut
     pattern := redirectOut_string;
     wordType := redirectOutWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     getNextToken;
     return;

  elsif ch = '2' and then wordLen > 1 and then Element(shell_word, 2 ) = '>' then -- 2+greater than?
     if wordLen > 2 and then Element( shell_word, 3  ) = '&' then            -- fold error into out?
        if wordLen > 3 and then Element( shell_word, 4 ) = '1' then
           word := redirectErr2Out_string;              -- type
           pattern := redirectErr2Out_string;
           wordType := redirectErr2OutWord;
           shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
           getNextToken;
           return;
        end if;
     elsif wordLen > 2 and then Element( shell_word, 3 ) = '>' then -- double greater than?
        word := redirectErrAppend_string;               -- it's redirectErrApp
        pattern := redirectErrAppend_string;
        wordType := redirectErrAppendWord;
        shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
        getNextToken;
        return;
     end if;
     word := redirectErrOut_string;                     -- it's redirectErrOut
     pattern := redirectErrOut_string;
     wordType := redirectErrOutWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     getNextToken;
     return;

  elsif ch = '@' then                                   -- itself?
     word := itself_string;                             -- it's an itself type
     pattern := itself_string;
     wordType := itselfWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     getNextToken;
     return;

  end if;

  -- There are times when we don't want to expand the word.  In the case of
  -- a syntax check, return the word as-is as a place holder (not sure if
  -- it's necessary but "> $path" becomes ">" with no path otherwise...at
  -- least, it's easier for the programmer to debug.
  --  However, to trace whether variables are referenced.

  if error_found then                                 -- error:
     getNextToken;
     return;                                          -- no expansions
  --elsif syntax_check then                             -- chk?
  --   shellWordList.Queue( wordList, aShellWord'( normalWord, pattern, shell_word ) );
  --   return;                                          -- just the word
  end if;                                             -- as a place holder

  ---------------------------------------------------------------------------
  -- We have a word.  Perform the expansion: process quotes and other escape
  -- characters, possibly creating multiple words from one original pattern.
  ---------------------------------------------------------------------------

  temp_id := eof_t; -- for tilde expansion

  -- Expand any quotes quotes and handle shell variable substitutions

  for i in 1..length( shell_word ) loop
    ch := Element( shell_word, i );                          -- next character

    -- tilde expansion must only occur in an unescaped word and not within a
    -- dollar expansion.  The tilde expansion is only valid for the first
    -- character in the word

    if ch = '~' and i = 1 and not inSQuote and not inDQuote and not inBackslash then
       if temp_id = eof_t then
          findIdent( to_unbounded_string( "HOME" ), temp_id ); -- find HOME var
       end if;
       word := word & to_string( identifiers( temp_id ).value.all );  -- replace w/HOME
       pattern := pattern & ch;  -- TODO: verify this should be ch


       -- Double Quote?  If not escaped by a backslash or single quote,
       -- we're in a new double quote escape.  If we were in a dollar expansion,
       -- perform the expansion.

    --elsif ch = '"' and not inSQuote and not inBackslash then    -- unescaped "?
    elsif ch = '"' and not inSQuote and not inBackslash then    -- unescaped "?
       if inDollar then                                      -- was doing $?
          dollarExpansion;                                    -- complete it
       end if;
       wasDQuote := inDQuote;                                -- remember
       inDQuote := not inDQuote;                             -- toggle " flag
       if not stripQuoteMarks then                           -- SQL word?
          if inDollar then                                   -- in an exp?
             addExpansionDQuote := true;                     -- add after exp
          else                                               -- else
             word := word & """";                            -- add quote now
          end if;
       end if;
       escapeGlobs := inDQuote;                              -- inside? do esc

       -- Single Quote?  If not escaped by a backslash or double quote,
       -- we're in a new single quote escape.  If we were in a dollar expansion,
       -- perform the expansion.

    elsif ch = ''' and not inDQuote and not inBackslash then -- unescaped '?
       if inDollar then                                      -- was doing $?
          dollarExpansion;                                   -- complete it
       end if;
       wasSQuote := inSQuote;                                -- remember
       inSQuote := not inSQuote;                             -- toggle ' flag
       if not stripQuoteMarks then                           -- SQL word?
          if inDollar then                                   -- in an exp?
             addExpansionSQuote := true;                     -- add after exp
          else                                               -- else
             word := word & "'";                             -- add quote now
          end if;
       end if;
       escapeGlobs := inSQuote;                              -- inside? do esc

       -- Back Quote?  If not escaped by a backslash or single quote,
       -- we're in a new back quote escape.  If we were in a dollar expansion,
       -- perform the expansion before executing the back quote.

    elsif ch = '`' and not inSQuote and not inBackslash then -- unescaped `?
       inBQuote := not inBQuote;                             -- toggle ` flag
       if inBQuote and inDollar then                         -- doing $ ere `?
          dollarExpansion;                                   -- complete it
       end if;
       if inBQuote then                                      -- starting?
          startOfBQuote := length( word );                   -- offset to start
       else                                                  -- ending?
          if inDollar then                                   -- in a $?
             dollarExpansion;                                -- finish it
          end if;
--put_line( "PSW: " & word );
--put_line( "PSW: " & startOfBQuote'img );
--put_line( "PSW: " & length( word )'img );
--put_line( "PSW: " & slice( word, startOfBQuote+1, length( word ) ) );
         declare
            -- to run this backquoted shell word, we need to save the current
            -- script, compile the command into byte code, and run the commands
            -- while capturing the output.  Substitute the results into the
            -- shell word and restore the original script.
            tempStr : unbounded_string := to_unbounded_string( slice( word, startOfBQuote+1, length( word ) ) );
            result : unbounded_string;
         begin
            delete( word, startOfBQuote+1, length( tempStr ) );
            CompileRunAndCaptureOutput( tempStr, result );
            word := word & result;
         end;
       end if;
       escapeGlobs := inBQuote;                            -- inside? do esc

       -- Backslash?  If not escaped by another backslash or single quote,
       -- we're in a new backslash escape.  If we were in a dollar expansion,
       -- perform the expansion.  Keep the backslashes for pathname expansion
       -- but not for SQL words.

    elsif ch = '\' and not inSQuote and not inBackslash then -- unescaped \?
       inBackslash := true;                                -- \ escape
       if inDollar then                                    -- in a $?
          dollarExpansion;                                 -- complete it
       end if;

       pattern := pattern & "\";                           -- an escaping \

       -- Dollar sign?  Then begin collecting the letters to the substitution
       -- variable.

    elsif ch = '$' and not (inSQuote and not expandInSingleQuotes) and not inBackslash then
       if inDollar then                                    -- in a $?
          if length( expansionVar ) = 0 then               -- $$ is special
             expansionVar := expansionVar & ch;            -- var is $
             dollarExpansion;                              -- expand it
          else                                             -- otherwise
             dollarExpansion;                              -- complete it
             inDollar := true;                             -- start new one
          end if;
       else                                                -- not in one?
          inDollar := true;                                -- start new one
       end if;
       expansionVar := null_unbounded_string;

    else

       -- End of quote handling...now we have a character, handle it

       -- if name is greater than 1 char, dollarExpansion ends when
       -- non-alpha/digit/underscore is read.  Pass through to allow the
       -- character to otherwise be treated normally.

       if inDollar then
          if ch /= '_' and ch not in 'A'..'Z'  and ch not in 'a'..'z'
             and ch not in '0'..'9' then
             if length( expansionVar ) > 0 then
                dollarExpansion;
             end if;
          end if;
       end if;

       -- Terminating characters (whitespace or semi-colon)
       exit when (ch = ' ' or ch = ASCII.HT or ch = ';' or ch = '|' )
          and not inDQuote and not inSQuote and not inBQuote and not inBackslash and not ignoreTerminatingWhitespace;
       -- Looking at a $ expansion?  Then collect the letters of the variable
       -- to substitute but don't add them to the shell word.  Apply dollar
       -- expansions to both word and pattern.
       if inDollar then                                    -- in a $?
          expansionVar := expansionVar & ch;               -- collect $ name
       else                                                -- not in $?
          -- When escaping characters that affect globbing, this is only done
          -- for the pattern to be used for globbing.  Do not escape the
          -- characters in the word...this will be the fallback word used if
          -- globbing fails to match any files.
          -- backslash => user already escaped it
          if escapeGlobs and not inBackslash then          -- esc glob chars?
             case ch is                                    -- is a glob char?
             when '*' => pattern := pattern & "\";         -- escape *
             when '[' => pattern := pattern & "\";         -- escape [
             when ']' => pattern := pattern & "\";         -- escape ]
             when '\' => pattern := pattern & "\";         -- escape \
             when '?' => pattern := pattern & "\";         -- escape *
             when others => null;                          -- others? no esc
             end case;
          end if;
          pattern := pattern & ch;                         -- add the char
          word := word & ch;                               -- original word
          if inBackslash then                              -- \ escaping?
             inBackslash := false;                         -- not anymore
          end if;
       end if;
    end if;
  end loop;                                                -- expansions done

  if inDollar then                                         -- last $ not done ?
     dollarExpansion;                                      -- finish it
  end if;

  -- These should never occur because of the tokenizing process, but
  -- to be safe there should be no open quotes.

  if inSQuote then
     err( gnat.source_info.source_location & ": Internal error: missing single quote mark" );
  elsif inDQuote then
     err( gnat.source_info.source_location & ": Internal error: missing double quote mark" );
  end if;

  -- process special characters

  --for i in 1..length( word ) loop
      --if Element( word, i ) = '~' then                      -- leading tilda?
  if length( word ) > 0 then
     if Element( word, 1 ) = '~' then                      -- leading tilda?
        findIdent( to_unbounded_string( "HOME" ), temp_id ); -- find HOME var
        pattern := identifiers( temp_id ).value.all;       -- replace w/HOME
     end if;
  end if;

  --end loop;

  -- Perform pathname expansion.  This also queues the words in the word
  -- list.  If a syntax check, we don't want to actually scan the disk
  -- and expand paths--instead, a dummy word will be queued and no other
  -- action is taken.

  pathnameExpansionWithIFS( word, pattern, wordList );

  if isExecutingCommand then

     if trace then
        declare
          theWord : aShellWord;
        begin
          if ignoreTerminatingWhitespace then
             put_trace( "SQL word '" & to_string( toEscaped( pattern ) ) &
                "' expands to:" );
          else
             put_trace( "shell word '" & to_string( toEscaped( pattern ) ) &
                "' expands to:" );
          end if;
          for i in 1..shellWordList.length( wordList ) loop
              shellWordList.Find( wordList, i, theWord );
              put_trace( to_string( toEscaped( theWord.word ) ) );
          end loop;
        end;
     end if;
  end if;
  getNextToken;

end ParseShellWord;


-----------------------------------------------------------------------------
--  PARSE ONE SHELL WORD
--
-- Parse and expand one shell word arguments.  Return the resulting pattern,
-- the expanded word, and the type of word.  First should be true if the word
-- can be a command.  An error occurs if the word can expand into more than
-- one word.
-----------------------------------------------------------------------------

procedure ParseOneShellWord( wordType : out aShellWordType;
   pattern, word : in out unbounded_string; First : boolean := false ) is
   wordList : shellWordList.List;
   theWord  : aShellWord;
begin
   ParseShellWord( wordList, First );
   if shellWordList.Length( wordList ) > 1 then
      err( "one shell word expected but it expanded to multiple words.  (SparForte requires commands that expand to one shell word.)" );
   else
      shellWordList.Find( wordList, 1, theWord );
      wordType := theWord.wordType;
      pattern  := theWord.pattern;
      word     := theWord.word;
   end if;
   shellWordList.Clear( wordList );
end ParseOneShellWord;


-----------------------------------------------------------------------------
--  PARSE SHELL WORDS
--
-- Parse and expand zero or more shell word arguments.  Return the results
-- as a shellWordList.  First should be true if the first word is a command.
--
-- A list of shell words ends with either a semi-colon (the end of a general
-- statement) or when a pipe or @ is read in as a parameter.  Do not include
-- a semi-colon in the parameters.
-----------------------------------------------------------------------------

procedure ParseShellWords( wordList : in out shellWordList.List; First : boolean := false ) is
   theWord  : aShellWord;
   theFirst : boolean := First;
begin
   loop
     exit when token = symbol_t and identifiers( token ).value.all = ";";
     ParseShellWord( wordList, theFirst );
     theFirst := false;
     shellWordList.Find( wordList, shellWordList.Length( wordList ), theWord );
     exit when theWord.wordType = pipeWord;       -- pipe always ends a command
     exit when theWord.wordType = itselfWord;     -- itself always ends a command
     exit when error_found;
   end loop;
end ParseShellWords;

procedure ParseVm is
-- THIS IS NOT USED AT THIS TIME.
-- vm regtype, regnum
  regtype_val  : unbounded_string;
  regtype_kind : identifier;
  regnum_val   : unbounded_string;
  regnum_kind  : identifier;
begin
  ParseExpression( regtype_val, regtype_kind );
  if baseTypesOK( regtype_kind, string_t ) then
     expect( symbol_t, "," );
     ParseExpression( regnum_val, regnum_kind );
     if baseTypesOK( regnum_kind, integer_t ) then
        null;
     end if;
  end if;
  builtins.vm( regtype_val, regnum_val );
end ParseVm;

procedure ParseProcedureBlock;
procedure ParseFunctionBlock;

procedure ParseWith is
  -- Syntax: with separate "file";
  include_file : unbounded_string;
begin
  -- is this true?
  --if inputMode = interactive or inputMode = breakout then
  --   err( "with can only be used in a script" );
  --end if;
  expect( with_t );
  expect( separate_t );
  if token = strlit_t then
     if syntax_check then
        if rshOpt then
           err( "subscripts are not allowed in a " & optional_bold( "restricted shell" ) );
        else
           insertInclude( identifiers( token ).value.all );
        end if;
     end if;
  end if;
  expect( strlit_t );
  expectSemicolon;
  -- That was the end of the with separate statement.  However, remember that
  -- the subscript is embedded in the main script so we have to read the
  -- subscript header.  Only pragmas allowed before separate keyword.
  while token = pragma_t loop
      ParsePragma;
      expectSemicolon;
  end loop;
  expect( separate_t );
  expectSemicolon;
end ParseWith;

procedure ParseDeclarations is
  -- Syntax: declaration = "new-ident decl-part"
  var_id : identifier;
  save_syntax_check : boolean;
begin
  while token /= begin_t and token /= end_t and token /= eof_t loop
     if token = pragma_t then
        ParsePragma;
        expectSemicolon;
     elsif token = type_t then
        ParseType;
        expectSemicolon;
     elsif token = subtype_t then
        ParseSubtype;
        expectSemicolon;
     elsif Token = with_t then
        -- When parsing a procedure declaration, we never want to run it.
        save_syntax_check := syntax_check;
        syntax_check := true;
        ParseWith;
        syntax_check := save_syntax_check;
     elsif Token = procedure_t then
        -- When parsing a procedure declaration, we never want to run it.
        save_syntax_check := syntax_check;
        syntax_check := true;
        ParseProcedureBlock;
        syntax_check := save_syntax_check;
     elsif Token = function_t then
        -- When parsing a function declaration, we never want to run it.
        save_syntax_check := syntax_check;
        syntax_check := true;
        ParseFunctionBlock;
        syntax_check := save_syntax_check;
     else
        ParseNewIdentifier( var_id );
        ParseDeclarationPart( var_id, anon_arrays => true, exceptions => true ); -- var id may change...
        expectSemicolon;
     end if;
  end loop;
end ParseDeclarations;

procedure ParseWhenClause( when_true : out boolean ) is
  -- Syntax: ... when condition
  -- True is returned if the when clause is true
  expr_val    : unbounded_string;
  expr_type   : identifier;
begin
  expect( when_t );
  ParseExpression( expr_val, expr_type );
  if baseTypesOk( boolean_t, expr_type ) then
     if isExecutingCommand then
        when_true :=  expr_val = "1";
        if trace then
           if when_true then
              put_trace( "when condition is true" );
           else
              put_trace( "when condition is false" );
           end if;
        end if;
     end if;
  end if;
end ParseWhenClause;

-- Raise an exception outside of an exception block
-- TODO: inside a block

procedure ParseRaise is
-- Syntax: raise [when...] | raise e [with s] [when...]
  id : identifier;
  with_text : unbounded_string;
  withTextType : identifier;
  mustRaise : boolean := true;
begin
  expect( raise_t );

  -- re-raise?  restore the exception occurrence and announce an error
  -- It is only valid in an exception handler (as flagged in the block).

  if token = symbol_t and identifiers( token ).value.all = to_unbounded_string( ";" ) then
     -- exceptions only exist at run-time
     if not syntax_check then
        if not inExceptionHandler then
           err( "re-raise is not in an exception handler" );
        else
           getBlockException( err_exception, err_message, last_status );
           -- Be careful to fix svalue pointer
           err_exception.value := err_exception.svalue'access;
        end if;
     end if;
     --expectSemicolon;
     -- Also check for obviously unreachable code.  Otherwise, restore the
     -- exception by setting the error flag.
     --if syntax_check then
     --   if token /= end_t and token /= exception_t and token /= when_t and token /= else_t and token /= elsif_t then
     --      err( "unreachable code" );
     --   end if;
     --elsif isExecutingCommand then
     if token = when_t or token = if_t then
        ParseWhenClause( mustRaise );
     end if;
     if isExecutingCommand then
        if mustRaise then
           error_found := true;
        end if;
     end if;
  else

     -- Normal raise of an explicit exception

     if identifiers( token ).class /= exceptionClass then
        err( optional_bold( to_string( identifiers( token ).name ) ) & " is a " & getIdentifierClassImage( identifiers( token ).class ) & " not an exception" );
     else
        ParseIdentifier( id );
        if token = with_t then
           if onlyAda95 then
              err( "with not allowed with " & optional_bold( "pragma ada_95" ) );
           end if;
           expect( with_t );
           ParseExpression( with_text, withTextType );
           if uniTypesOK( withTextType, uni_string_t ) then
              null;
           end if;
           if token = use_t then
              err( optional_bold( "use" ) & " may only be used in exception declaration" );
           end if;
        elsif token /= when_t and token /= symbol_t and identifiers( token ).value.all /= ";" then
           err( "when, with or ';' expected" );
        end if;
        if token = when_t then
           ParseWhenClause( mustRaise );
        end if;
     end if;
     if isExecutingCommand then
        if mustRaise then
           -- if no message, check for and use the default message
           if length( with_text ) = 0 then
              if length( identifiers( id ).value.all ) > 1 then
                 with_text := unbounded_slice( identifiers( id ).value.all, 2, length( identifiers( id ).value.all ) );
              end if;
           end if;
           -- Record the exception id
           -- Pull the declaration out of the symbol table.  Mark as not deleted.
           -- Redirect storage pointer to point to local storage, not to the
           -- symbol table svalue which could get disappear when a block is
           -- deallocated.
           err_exception := identifiers( id );
           err_exception.deleted := false;
           err_exception.value := err_exception.svalue'access;
           if length( with_text ) > 0 then
              raise_exception( "raised " &
                   optional_bold( to_string( identifiers( id ).name ) ) &
                   ": " &
                   to_string( with_text )
              );
           else
              raise_exception( "raised " &
                   optional_bold( to_string( identifiers( id ).name ) )
              );
           end if;
           -- set the exit status
           last_status := character'pos( element( identifiers( id ).value.all, 1 ) );
        end if;
     end if;
  end if;
end ParseRaise;

-- skip a block of code

procedure SkipBlock( termid1, termid2 : identifier := keyword_t ) is
  old_error : boolean;
  old_skipping : boolean;
begin
  if token = end_t or token = eof_t or token = exception_t or token = termid1 or token = termid2 then
     err( "missing statement or command" );
  end if;
  if syntax_check then               -- if we're checking syntax
     ParseBlock( termid1, termid2 ); -- must process the block to look
     return;                         -- for syntax errors
  end if;
  --old_error := error_found;          -- save error code
  --error_found := true;               -- skip by setting error flag
  old_error := syntax_check;
  old_skipping := skipping_block;
  syntax_check := true;
  skipping_block := true;
  -- if an error happens in the block, we were skipping it anyway...
  while token /= end_t and token /= eof_t and token /= exception_t and token /= termid1 and token /= termid2 loop
      ParseGeneralStatement;         -- step through context
  end loop;
  --error_found := old_error;          -- ignore any error while skipping
  syntax_check := old_error;
  skipping_block := old_skipping;
end SkipBlock;

-- execute a block of code

procedure ParseBlock( termid1, termid2 : identifier := keyword_t ) is
  -- Syntax: block = "general-stmt [general-stmt...] termid1 | termid2"
begin
  if token = end_t or token = eof_t or token = exception_t or token = termid1 or token = termid2 then
     err( "missing statement or command" );
  end if;
  while token /= end_t and token /= eof_t and token /= exception_t and token /= termid1 and token /= termid2 loop
     ParseGeneralStatement;
  end loop;
end ParseBlock;

-- parse an exception block

--procedure ParseExceptionBlock( termid1, termid2 : identifier := keyword_t ) is
procedure ParseExceptionBlock( occurrence_exception : declaration;
  occurrence_message      : unbounded_string;
  occurrence_status       : aStatusCode ) is
  -- Same as ParseBlock except raise is permitted
begin
  if token = end_t or token = eof_t or token = when_t then
     err( "missing statement or command" );
  end if;
  while token /= end_t and token /= eof_t and token /= exception_t and token /= when_t  loop
     -- TODO: Really ParseBlockStatement but I haven't written it yet.
     ParseGeneralStatement;
  end loop;

  --   -- Re-eaise is a special case.  It must be handled here, in the
  --   -- exception block
  --   if token = raise_t then
  --      expect( raise_t );
  --      -- re-raise?  restore the exception occurrence
  --      if token = symbol_t and identifiers( token ).value.all = to_unbounded_string( ";" ) then
  --         err_exception := occurrence_exception;
  --         err_message := occurrence_message;
  --         last_status := occurrence_status;
  --         expectSemicolon;
  --         if syntax_check then
  --           if token /= end_t and token /= exception_t and token /= when_t and token /= else_t and token /= elsif_t then
  --              err( "unreachable code" );
  --           end if;
  --         elsif isExecutingCommand then
  --           error_found := true;
  --         end if;
  --     else
  --        ParseRestOfRaise;
  --        expectSemicolon;
  --        if syntax_check then
  --          if token /= end_t and token /= exception_t and token /= when_t and token /= else_t and token /= elsif_t then
  --             err( "unreachable code" );
  --          end if;
  --        end if;
  --     end if;
  --   else
  --      ParseGeneralStatement;
  --   end if;
  --end loop;

  if token = exception_t then
     err( "already in an exception handler" );
  end if;
end ParseExceptionBlock;

procedure SkipExceptionBlock is
  -- Same as SkipBlock except raise is permitted
  pragma warnings( off );
  null_declaration : declaration;
  pragma warnings( on );
  old_error : boolean;
  old_skipping : boolean;
begin
  if token = end_t or token = eof_t or token = when_t then
     err( "missing statement or command" );
  end if;
  if syntax_check then               -- if we're checking syntax
     ParseExceptionBlock( null_declaration, null_unbounded_string, 1 ); -- must process the block to look
     return;                         -- for syntax errors
  end if;
  old_error := syntax_check;
  old_skipping := skipping_block;
  syntax_check := true;
  skipping_block := true;
  -- if an error happens in the block, we were skipping it anyway...
  while token /= end_t and token /= eof_t and token /= exception_t and token /= when_t loop
      ParseGeneralStatement;         -- step through context
      -- if token = raise_t then -- TODO: wrong
      --    expect( raise_t );
      --    expectSemicolon;
     --elsif token = exception_t then
      -- else
      --    ParseGeneralStatement;         -- step through context
      -- end if;
  end loop;
  syntax_check := old_error;
  skipping_block := old_skipping;
end SkipExceptionBlock;

procedure ParseExceptionHandler( errorOnEntry : boolean ) is
  -- syntax: exception when others => (block)
  -- errorOnEntry - true if there was already an error when the block
  -- this handler was attached to was started (thus, this handler does
  -- not apply)
  found_exception     : boolean := false;
  formal_exception_id : identifier;
  handling_exceptions : boolean;
  handled_exception   : boolean := false;

  occurrence_exception : declaration;
  occurrence_message   : unbounded_string;
  occurrence_status    : aStatusCode;
  occurrence_full      : unbounded_string;
begin
  handling_exceptions := (error_found and not done and not syntax_check and not errorOnEntry);

  -- for trace purposes, turn off errors as soon as possible.  Also, save
  -- the information about the exception for re-raising.

  if handling_exceptions then
     if trace then
        put_trace( "exception handler running" );
     end if;
     error_found := false;
     -- save the exception id
     occurrence_exception := err_exception;
     -- because value is a pointer now we must be careful with the value
     occurrence_exception.value := occurrence_exception.svalue'unchecked_access;
     -- TODO: an exception may be progated out of the declaration scope, leaving
-- the position in the symbol table undefined
     occurrence_message := err_message;
     occurrence_status := last_status;
     occurrence_full := fullErrorMessage;
     startExceptionHandler( occurrence_exception, occurrence_message,
        occurrence_status, occurrence_full );
  end if;

  -- parse the exception block and see if there's a matching case for this
  -- exception.  If there's an others clause, it matches if nothing else did

  expect( exception_t );
  loop
    expect( when_t );
    -- if we have a case that matches, match will not be eof_t
    if token /= others_t then
       if identifiers( token ).class = exceptionClass then
          ParseIdentifier( formal_exception_id );
          -- TODO: a propogated exception that propogates but a new exception overlooks it.  The
          -- exception name must be unique
          found_exception := identifiers( formal_exception_id ).name = occurrence_exception.name;
          if found_exception then
             if trace then
                put_trace( "exception handler applying case " & to_string( identifiers( formal_exception_id ).name ) );
             end if;
          end if;
       else
          err( optional_bold( to_string( identifiers( token ).name ) ) & " is a " & getIdentifierClassImage( identifiers( token ).class ) & " not an exception" );
          exit;
       end if;
    else
       -- if we haven't found a case that matches, others always matches
       expect( others_t );
       if handling_exceptions then
          if not handled_exception then
             found_exception := true;
             if trace then
                put_trace( "exception handler applying default case for '" &
                   to_string( occurrence_exception.name ) & "'" );
             end if;
          end if;
       end if;
    end if;
    expect( symbol_t, "=>" );
    -- this case matches and we're handling exceptions? then handle it.
    -- otherwise, skip the exception handler block
    if handling_exceptions and not error_found then
       if found_exception then
          ParseExceptionBlock( occurrence_exception, occurrence_message, occurrence_status );
          found_exception := false;                          -- clear found flag
          handled_exception := true;                 -- we handled the exception
          if error_found and err_exception.deleted then     -- non-except error?
             if trace then
                put_trace( "an error occurred while handling the exception" );
             end if;
          elsif not error_found then                             -- no re-raise?
             err_exception.deleted := true;                      -- mark handled
             last_status := 0;                          -- and clear status code
                                                      -- exception already clear
             err_message := null_unbounded_string;                  -- clear any
             fullErrorMessage := null_unbounded_string;              -- messages
             if trace then
                put_trace( "cleared exception occurrence" );
             end if;
          end if;
       else
          SkipExceptionBlock;
       end if;
    else
       SkipExceptionBlock;
    end if;
    exit when token = eof_t or token = end_t;
  end loop;
  -- no handler found?  restore the error flag
  -- if another error happened in the handler, it takes precidence
  if handling_exceptions then                       -- not syntax check, etc.?
     if not handled_exception then                        -- no handler found?
        if error_found then                                 -- error occurred?
           null;                                       -- then can't propogate
        else                                                      -- otherwise
           if trace then                                            -- explain
              put_trace( "no appropriate handler was found" );
           end if;
           -- propogate the exception
           -- restore the exception unless a new exception or an error occurred.
           -- do the messages just to be safe.
           err_exception := occurrence_exception;
           -- because value is a pointer now we must be careful with the value
           copyValue( err_exception, occurrence_exception );
           err_message := occurrence_message;
           last_status := occurrence_status;
           fullErrorMessage := occurrence_full;
           error_found := true;
        end if;
     end if;
  end if;
end ParseExceptionHandler;

procedure ParseDeclareBlock is
  errorOnEntry : boolean := error_found;
begin
  pushBlock( newScope => true, newName => "declare block" );
  expect( declare_t );
  ParseDeclarations;
  expect( begin_t );
  ParseBlock;
  if token = exception_t then
     ParseExceptionHandler( errorOnEntry );
  end if;
  expect( end_t );
  pullBlock;
end ParseDeclareBlock;

procedure ParseBeginBlock is
  errorOnEntry : boolean := error_found;
begin
  pushBlock( newScope => true, newName => "begin block" );
  expect( begin_t );
  ParseBlock;
  if token = exception_t then
     ParseExceptionHandler( errorOnEntry );
  end if;
  expect( end_t );
  pullBlock;
end ParseBeginBlock;

procedure ParseFormalParameters( proc_id : identifier; param_no : in out integer; abstract_parameter : in out identifier; is_function : boolean := false ) is
-- Syntax: (field = declaration [; declaration ... ] )
-- Fields are implemented using records
   formal_param_id : identifier;
   b : boolean;
   paramName    : unbounded_string;
   type_token   : identifier;
   passingMode  : aParameterPassingMode;
begin
  param_no := param_no + 1;
  ParseNewIdentifier( formal_param_id );
  expect( symbol_t, ":" );

  -- Check the parameter mode

  if token = out_t then
     expect( out_t );
     passingMode := out_mode;
     -- err( "out parameters not yet supported" );
  elsif token = in_t then
     -- TODO: deny in (just use default)?  Or require in?
     passingMode := in_mode;
     expect( in_t );
     if token = out_t then
        expect( out_t );
        passingMode := in_out_mode;
        -- DEBUG
        -- err( "in out parameters not yet supported" );
     end if;
  elsif token = access_t then
     err( "access parameters not yet supported" );
  else
     passingMode := in_mode;
  end if;

  -- Check for anonymous array

  if token = array_t then
     err( "anonymous array parameters not yet supported" );
  end if;

  -- The name of the type
  --
  -- If it's an abstract type, record it because the subproram must be
  -- abstract also.

  ParseIdentifier( type_token );
  if identifiers( type_token ).usage = abstractUsage then
     if abstract_parameter = eof_t then
        abstract_parameter := type_token;
     end if;
  end if;

  -- Check type
  --
  -- in mode for aggregates not yet written.

   if passingMode = out_mode then
      if is_function then
         err( "out mode parameters not allowed in functions" );
     end if;
   end if;
   if passingMode = in_out_mode then
      if is_function and onlyAda95 then
         err( "in out mode parameters not allowed in functions with " &
             optional_bold( "pragma ada_95" ) );
      end if;
   end if;
  if passingMode = in_mode then
     if identifiers( getBaseType( type_token ) ).list then
         err( "array parameters not yet supported" );
     elsif identifiers( getBaseType( type_token ) ).kind = root_record_t then
        err( "records not yet supported" );
     end if;
  end if;
  --elsif identifiers( getBaseType( type_token ) ).kind = root_record_t then
  if getBaseType( type_token ) = command_t then
     err( "commands not yet supported" );
  end if;

  -- Check for default value

  if token = symbol_t and identifiers( token ).value.all = ":=" then
     err( "default values are not yet supported" );
  end if;

  -- Create the parameter, associating it to the procedure/function

  if syntax_check then
     identifiers( formal_param_id ).wasReferenced := true;
     identifiers( type_token ).wasApplied := true;
  end if;

  updateFormalParameter( formal_param_id, type_token, proc_id, param_no,
    passingMode );

  -- Check for further parameters

  if not error_found and token /= eof_t and not (token = symbol_t and identifiers( token ).value.all = ")" ) then
     expectSemicolon;
     ParseFormalParameters( proc_id, param_no, abstract_parameter );
     -- the symbol table will overflow before field_no does
  end if;

  -- Blow away on error

  if error_found then
     b := deleteIdent( formal_param_id );
  end if;
end ParseFormalParameters;

procedure ParseFunctionReturnPart( func_id : identifier; abstract_return : in out identifier ) is
-- Syntax: (field = declaration [; declaration ... ] )
-- Fields are implemented using records
   formal_param_id : identifier;
   b : boolean;
   paramName : unbounded_string;
   type_token    : identifier;
begin
  expect( return_t );

  -- The name of the type

  ParseIdentifier( type_token );
  identifiers( func_id ).kind := type_token;
  if syntax_check then
     identifiers( type_token ).wasApplied := true; -- type was used
     if identifiers( type_token ).usage = abstractUsage then
        abstract_return := type_token;
     end if;
  end if;

  -- Check type

  if identifiers( getBaseType( type_token ) ).list then
     err( "array parameters not yet supported" );
  elsif identifiers( getBaseType( type_token ) ).kind = root_record_t then
     err( "records not yet supported" );
  elsif getBaseType( type_token ) = command_t then
     err( "commands not yet supported" );
  end if;

  -- Create the parameter

  declareIdent( formal_param_id, return_value_str, type_token, varClass );
  if syntax_check then
     identifiers( formal_param_id ).wasReferenced := true;
  end if;
  updateFormalParameter( formal_param_id, type_token, func_id, 0, none );

  -- Blow away on error

  if error_found then
     b := deleteIdent( formal_param_id );
  end if;
end ParseFunctionReturnPart;

procedure DeclareActualParameters( proc_id : identifier ) is
-- This function declare fake actual parameters for parsing the formal
-- definition of a procedure or function.  It doesn't create the parameters
-- used when a procedure or function is called (that's ParseActualParameters).
  actual_param_t : identifier;
  param_no : natural;
  startAt : identifier;
  recordBaseTypeId : identifier;
begin
  if not error_found then
     -- unlike arrays, user-defined functions and procedures do not have
     -- a total number of parameters stored in their value field

     -- functions have an extra, hidden actual parameter for the function
     -- result (parameter zero).

     if identifiers( proc_id ).class = userFuncClass then
         declareReturnResult(
            actual_param_t,
            proc_id );
         if syntax_check then
            identifiers( actual_param_t ).wasReferenced := true;
            identifiers(
              identifiers( actual_param_t ).kind
              ).wasApplied := true; -- type was used
         end if;
     end if;

     startAt := identifiers_top-1;

     -- this declares the actual parameters but does not set the value
     -- or implement the passing mode.

     param_no := 1;
     loop
         declareUsableFormalParameter(
            actual_param_t,
            proc_id,
            param_no,
            null_unbounded_string,
            startAt );
         exit when actual_param_t = eof_t;
         -- if a record, we need fields
         recordBaseTypeId := getBaseType( identifiers( actual_param_t ).kind );
         if identifiers( recordBaseTypeId ).kind = root_record_t then  -- record type?
            -- if identifiers( actual_param_t ).kind = root_record_t then  -- record type?
            declareRecordFields( actual_param_t, recordBaseTypeId );
         end if;
         -- search for the next one starting one later
         param_no := param_no + 1;
     end loop;
  end if;
end DeclareActualParameters;

procedure ParseSeparateProcHeader( proc_id : identifier; procStart : out natural ) is
  -- Syntax: separate( parent ); procedure p [(param1...)] is
  -- Note: forward declaration handling not yet written so minimal parameter
  -- checking in the header.
  separate_proc_id : identifier;
  parent_id        : identifier;
  b : boolean;
  pu : unbounded_string;
  i : integer;
  ch : character;
begin
   -- getFullParentUnitName( pu );
   -- separate
   expectSemicolon;
   expect( separate_t );
   expect( symbol_t, "(");
   ParseIdentifier( parent_id );
   pu := identifiers( parent_id ).name;
   -- NOTE: the identifier token returned has the prefix stripped!  This needs
   -- to be fixed so I cannot check to see if it was full path before stripping.
   i := length( pu );
   while i > 0 loop
     ch := element( pu, i );
     if ch = '.' then
        delete( pu, 1, i );
        exit;
     end if;
     i := i - 1;
   end loop;
   if identifiers( parent_id ).class /= userProcClass and identifiers( parent_id ).class /= userFuncClass and identifiers( parent_id ).class /= mainProgramClass then
         err( "parent unit should be a subprogram" );
   elsif identifiers( parent_id ).name /= pu then
         err( "expected parent unit " & optional_bold( to_string( pu ) ) );
   end if;
   expect( symbol_t, ")");
   expectSemicolon;
   -- separate's procedure header
   procStart := firstPos;
   expect( procedure_t );
   -- could do ParseIdentifier since it should exist but want a more meaningful
   -- message error for a mismatch
   ParseProcedureIdentifier( separate_proc_id );
   if identifiers( separate_proc_id ).value.all = identifiers( proc_id ).value.all then
      -- names match?  OK, discard.  proc is stored under original ident
      b := deleteIdent( separate_proc_id );
   else
      err( optional_bold( to_string( identifiers( separate_proc_id ).name ) ) & " is different from parent file's " & optional_bold( to_string( identifiers( proc_id  ).name ) ) );
   end if;
   -- check for forward declarations not yet written so minimal checking here
   -- flush this out if i have time to walk the identifiers list if available
   if token = symbol_t and identifiers( token ).value.all = "(" then
      expect( symbol_t, "(" );
      while token /= symbol_t and identifiers( token ).value.all /= ")" and token /= eof_t loop
         getNextToken;
      end loop;
      expect( symbol_t, ")" );
   end if;
   expect( is_t );
end ParseSeparateProcHeader;

procedure ParseProcedureBlock is
  -- Syntax: procedure [abstract] p [(param1...)] OR procedure [abstract] p [(param1...)] is block
  -- end p;
  -- Handle procedure declarations, including forward declarations.
  -- Note: DoUserDefinedProcedure executes a user-defined procedure created by
  -- this routine.
  proc_id   : identifier;
  procStart : natural;
  procEnd   : natural;
  no_params   : integer;
  errorOnEntry : boolean := error_found;
  abstract_parameter : identifier := eof_t;
begin
  procStart := firstPos;
  expect( procedure_t );
  ParseProcedureIdentifier( proc_id );
  -- A forward declaration?
  if token /= is_t and not (token = symbol_t and identifiers( token ).value.all = "(" ) then
     -- the following is only true for a forward declaration
     -- (otherwise PPI will return varClass)
     if identifiers( proc_id ).class = userProcClass then
        err( "already forward declared " & optional_bold( to_string( identifiers( proc_id ).name ) ) );
     end if;
     identifiers( proc_id ).class := userProcClass;
     identifiers( proc_id ).kind := procedure_t;
     -- otherwise, nothing special for a forward declaration
  else
     identifiers( proc_id ).class := userProcClass;
     identifiers( proc_id ).kind := procedure_t;
     if token = symbol_t and identifiers( token ).value.all = "(" then
        expect( symbol_t, "(" );
        no_params := 0;
        ParseFormalParameters( proc_id, no_params, abstract_parameter );
        expect( symbol_t, ")" );
        --identifiers( proc_id ).value := to_unbounded_string( no_params );
     end if;
     pushBlock( newScope => true,
       newName => to_string (identifiers( proc_id ).name ) );
     DeclareActualParameters( proc_id );
     expect( is_t );
     if token = null_t then                               -- null abstract
        expect( null_t );
        expect( abstract_t );
        identifiers( proc_id ).usage := abstractUsage;
        if syntax_check then
           identifiers( proc_id ).wasReferenced := true;
        end if;
        pullBlock;
     else
        if token = separate_t then
           if rshOpt then
              err( "subunits are not allowed in a " & optional_bold( "restricted shell" ) );
           end if;
           expect( separate_t );
           -- "is separate" is effectively an include
           -- only insert include on a syntax check
           if syntax_check then
              insertInclude( identifiers( proc_id ).name & ".sp" );
           end if;
           ParseSeparateProcHeader( proc_id, procStart );
        elsif token = abstract_t then
           expect( abstract_t );
           identifiers( proc_id ).usage := abstractUsage;
           if syntax_check then
              identifiers( proc_id ).wasReferenced := true;
           end if;
        elsif abstract_parameter /= eof_t then
           err( "procedure must be abstract because parameter type " &
              optional_bold( to_string( identifiers( abstract_parameter ).name ) ) &
              " is abstract" );
        end if;
        ParseDeclarations;
        expect( begin_t );
        skipBlock;                                       -- never execute now
        if token = exception_t then
           ParseExceptionHandler( errorOnEntry );
        end if;
        pullBlock;
        expect( end_t );
        expect( proc_id );
        procEnd := lastPos+1; -- include EOL ASCII.NUL
        identifiers( proc_id ).value.all := to_unbounded_string( copyByteCodeLines( procStart, procEnd ) );
        -- fake initial indent of 1 for byte code (SOH)
        -- we don't know what the initial indent is (if any) since it may
        -- not be the first token on the line (though it usually is)
     end if;
  end if;
  expectSemicolon;
end ParseProcedureBlock;

procedure ParseActualParameters( proc_id : identifier;
  declareParams : boolean := true ) is
-- Syntax: (param : declaration [; declaration ... ] )
--
-- declareparams is true, then the parameters will be created (e.g. this is
--   false on a syntax check)
-- is_function is true when this is called to setup a function's parameters
--   (false is a procedure)
--
-- For a call proc( x, y, z ), this procedure parses x, y, z and
-- creates the equivalent parameters for running proc.  There are three
-- kind of parameters involved:
--
-- * x is an actual parameter, the parameter passed into proc
-- * proc.p1 is a formal parameter, the proc definition parameter
-- * p1 is the usuable identifier created from the template of proc.p1.
--   p1's value is filled in (on in-mode) or p1 renames x (in an out or
--   in out mode)

------------------------------------------------------------------------------
-- Usable Parameter Helper Functions
--
-- Handles arrays, array elements and records.
-- TODO: refactor to make this more general, place in world.adb?
------------------------------------------------------------------------------

procedure UpdateRenamedArrayElementParameter( actualParamRef : renamingReference;
  usableParamId : identifier ) is
begin
  if isExecutingCommand then                      -- no value change
     identifiers( usableParamId ).value :=
        identifiers( actualParamRef.id ).avalue(
        actualParamRef.index )'access;
  end if;
  exception when storage_error =>              -- prob freed mem
       err( gnat.source_info.source_location &
         ": internal error: storage_error exception raised" );
     when others =>
       err( gnat.source_info.source_location &
          ": internal error: exception raised" );
end UpdateRenamedArrayElementParameter;

-- For a full array, mark it as an array and fix the value pointer

procedure UpdateRenamedFullArrayParameter( actualParamRef : renamingReference;
  usableParamId : identifier ) is
begin
  identifiers( usableParamId ).list := true;
  FixRenamedArray( actualParamRef, usableParamId );
end UpdateRenamedFullArrayParameter;

-- Records are a complex case.  They must match the formal parmaeters but
-- the values rename the actual parameters.

procedure UpdateRenamedRecordParameter( actualRecordRef : renamingReference;
   formalRecordParamId, usableRecordParamId : identifier ) is
   numFields : natural;
   fieldName     : unbounded_string;
   usableFieldId : identifier;
   dotPos        : natural;
   recordTypeFieldId : identifier;
begin
     -- TODO: use this above with formal parameters?

  -- Always a risk of an exception thrown here
  begin
    numFields := natural( to_numeric( identifiers( identifiers(
        actualRecordRef.id ).kind ).value.all ) );
  exception when storage_error =>
    numFields := 0;
    err( gnat.source_info.source_location &
         "internal error: storage_error: unable to determine the number of fields" );
  when constraint_error =>
    numFields := 0;
    err( gnat.source_info.source_location &
         "internal error: constraint_error: unable to determine the number of fields" );
  end;

  recordTypeFieldId := identifiers( formalRecordParamId ).kind + 1;

  for fieldNumber in 1..numFields loop

      -- brutal search...we can do better than...
      --  for recordTypeFieldId in reverse keywords_top..identifiers_top-1 loop
      --
      -- As an optimization, the fields are likely located immediately after
      -- the record itself is defined.  Also assumes they are stored
      -- sequentially.  In the future, records will be stored differently.

      while recordTypeFieldId < identifiers_top loop
        if identifiers( recordTypeFieldId ).field_of = identifiers( formalRecordParamId ).kind then
           if integer'value( to_string( identifiers( recordTypeFieldId ).value.all )) = fieldNumber then
               exit;
            end if;
         end if;
         recordTypeFieldId := identifier( integer( recordTypeFieldId ) + 1 );
      end loop;

     -- no more identifiers means we didn't find it.
     if recordTypeFieldId = identifiers_top then
        err( gnat.source_info.source_location &
           "internal error: record field not found" );
        exit;
     end if;

    -- TODO: should this be the base record type?  subtypes may break it
    fieldName := identifiers( recordTypeFieldId ).name;
    dotPos := length( fieldName );
    while dotPos > 1 loop
       exit when element( fieldName, dotPos ) = '.';
       dotPos := dotPos - 1;
    end loop;
    fieldName := delete( fieldName, 1, dotPos );
    fieldName := identifiers( usableRecordParamId ).name & "." & fieldName;
--put_line( "field name = " & to_string( fieldName ) );
    declareIdent( usableFieldId, fieldName, identifiers(
        recordTypeFieldId ).kind, varClass );
    -- fields have not been marked as children of the parent
    -- record.  However, to make sure the record is used, it
    -- is convenient to track the field.
    identifiers( usableFieldId ).field_of := usableRecordParamId;
    -- at least, for now, don't worry if record fields are
    -- declared but not accessed.  We'll just check the
    -- main record identifier.
    if syntax_check then
       identifiers( usableFieldId ).wasReferenced := true;
       identifiers(
         identifiers( recordTypeFieldId ).kind
         ).wasApplied := true;
     end if;
     recordTypeFieldId := identifier( integer( recordTypeFieldId ) + 1 );
  end loop; -- for

  -- We have to do another search for the actual parameter fields and
  -- link them to the usable parameter fields
  FixRenamedRecordFields( actualRecordRef, usableRecordParamId );

end updateRenamedRecordParameter;

------------------------------------------------------------------------------
-- Parameter Modes
--
-- Create usable parameters based on the parameter mode
------------------------------------------------------------------------------

-- For an in mode parameter, expect an expression
-- Create a constant containing the value.

procedure parseUsableInModeParameter( formalParamId : identifier; paramName : unbounded_string ) is
   expr_value : unbounded_string;
   expr_type : identifier;
   usableParamId : identifier;
   typesOK : boolean;
begin
  ParseExpression( expr_value, expr_type );
  typesOK := baseTypesOK( identifiers( formalParamId ).kind, expr_type );
  if typesOK and then declareParams then
     declareIdent(
         usableParamId,
         to_string( paramName ),
         identifiers( formalParamId ).kind
     );
     -- For an in-mode parameter, downgrade full usage to constant
     -- limited, abstract already cannot be assigned to.
     if identifiers( usableParamId ).usage = fullUsage then
        identifiers( usableParamId ).usage := constantUsage;
     end if;
     -- Originally, made a constant but constant is now a usage qualifier
     --declareStandardConstant( usableParamId,
     --   to_string( paramName ),
     --   identifiers( formalParamId ).kind,
     --   to_string( expr_value ) );
     if isExecutingCommand then
        DoContracts( identifiers( formalParamId ).kind, expr_value );
        identifiers( usableParamId ).value.all := expr_value;
        if trace then
           put_trace(
              to_string( identifiers( usableParamId ).name ) & " := " &
              to_string( expr_value ) );
        end if;
     end if;
  end if;
end parseUsableInModeParameter;

procedure parseUsableInoutModeParameter( formalParamId : identifier; paramName : unbounded_string ) is
   actual_param_ref : renamingReference;
   usableParamId : identifier;
begin
  -- the reference is the actual parameter, the thing being passed...
  ParseRenamingReference(
    actual_param_ref,
    identifiers( formalParamId ).kind
  );
  -- parameters may not be constants or enumerated items
  if identifiers( actual_param_ref.id ).usage = constantUsage then
     err( "a constant cannot be used as an in out or out mode parameter" );
  elsif identifiers( actual_param_ref.id ).class = enumClass then
     -- TODO: I could probably get this to work for out parameters but
     -- not yet implemented
     err( "enumerated items cannot be used as an in out or out mode parameter" );
  end if;
  -- whether declaring the params or not, during a syntax check, the actual
  -- parameter must be marked as "written" to avoid an error over not being
  -- a constant
  if syntax_check and then not error_found then
     if identifiers( actual_param_ref.id ).field_of /= eof_t then
        identifiers( identifiers( actual_param_ref.id ).field_of ).wasWritten := true;
     else
        identifiers( actual_param_ref.id ).wasWritten := true;
        identifiers( actual_param_ref.id ).wasFactor := true;
     end if;
  end if;
  if declareParams then
       -- the actual parameter will be the canonical identifier for
       -- the renaming
       declareIdent(
          usableParamId,
          to_string( paramName ),
          identifiers( formalParamId ).kind
       );
        -- TODO: actually, an update not a declaration.  But can it be
        -- combined with declareIdent?
        declareRenaming( usableParamId, actual_param_ref ); -- basic renaming
        -- Usuable parameter was "written"
        if syntax_check and then not error_found then
           identifiers( usableParamId ).wasWritten := true;
        end if;
        -- An array?  make it happen.
        if identifiers( actual_param_ref.id).list then        -- array/element?
           if actual_param_ref.hasIndex then                  -- element?
              updateRenamedArrayElementParameter( actual_param_ref, usableParamId );
           else
              updateRenamedFullArrayParameter( actual_param_ref, usableParamId );
           end if;
        elsif identifiers( getBaseType( actual_param_ref.kind ) ).kind = root_record_t then  -- record type?
-- TODO: a function for this
           UpdateRenamedRecordParameter( actual_param_ref, formalParamId,
   usableParamId );
        end if;
  end if; -- declareParams
end parseUsableInoutModeParameter;

-- For an out mode parameter, expect an identifier.
-- declare a variable as a renaming for the
-- identifier.  Technically the value is
-- undefined.
--
-- For now, it's treated the same as an in out mode parameter

procedure parseUsableOutModeParameter( formalParamId : identifier; paramName : unbounded_string ) is
begin
   parseUsableInoutModeParameter( formalParamId, paramName );
end parseUsableOutModeParameter;

   parameterNumber : integer;
   paramName : unbounded_string;
   formalParamId : identifier;
   seenBracket : boolean := false;

begin

    -- In a syntax check, the formal parameters aren't created so there's
    -- no reason to look them up.  We're just reading through the parameters
    -- for the procedure call...

  -- Less brutal search than the old one:
  -- for i in 1..identifiers_top-1 loop
  --
  -- As an optimization, the params are likely located immediately after
  -- the proc itself is defined.  params are assumed to be stored sequentially
  -- In the future, params could be stored differently.
  --
  -- TODO: modify to handle namespaces

  formalParamId := proc_id + 1;
  parameterNumber := 1;
  -- put_line( "--- Searching from" ); -- DEBUG
  -- put_line( to_string( identifiers( proc_id-2 ).name ) ); -- DEBUG
  -- put_line( to_string( identifiers( proc_id-1 ).name ) ); -- DEBUG
  -- put_line( to_string( identifiers( proc_id ).name ) & " proc" ); -- DEBUG
  -- put_line( to_string( identifiers( proc_id+1 ).name ) ); -- DEBUG
  -- put_line( to_string( identifiers( proc_id+2 ).name ) ); -- DEBUG

  -- if there are no parameters and this is a function, you will run into the function's return
  -- value, which does not count as a parameter...abort the parameter search if it exists.
  if identifiers( formalParamId ).name = "return value" then
     formalParamId := identifiers_top; -- abort search
  end if;

  loop
      while formalParamId < identifiers_top loop
        if identifiers( formalParamId ).field_of = proc_id then
           if integer'value( to_string( identifiers( formalParamId ).value.all )) = parameterNumber then
              exit;
           end if;
        end if;
        formalParamId := identifier( integer( formalParamId ) + 1 );
      end loop;

    exit when formalParamId = identifiers_top;

    paramName := identifiers( formalParamId ).name;
    paramName := delete( paramName, 1, index( paramName, "." ) );

    -- On the first parameter, we expect the parameter to be in bracketed
    -- list.

    if not seenBracket then
       if token = symbol_t and identifiers( token ).value.all = "(" then
          expect( symbol_t, "(" );
          seenBracket := true;
       else
          err( "too few parameters" );
       end if;
    end if;

    -- Parse the parameter based on the passing mode (in, out, in out)

    case identifiers( formalParamId ).passingMode is

         when in_mode =>
              parseUsableInModeParameter( formalParamId, paramName );

         when out_mode =>
              parseUsableOutModeParameter( formalParamId, paramName );

         when in_out_mode =>
              parseUsableInoutModeParameter( formalParamId, paramName );

         when others =>
              err( gnat.source_info.source_location &
                   ": internal error: formal parameter" &
                   formalParamId'img &
                   "/" & to_string( identifiers( formalParamId ).name ) &
                   " has unsupported parameter passing mode" );
     end case;

     -- Not sure we need to exit on an error here - KB: 17/10/15
     --exit when error_found or identifiers( token ).value.all /= ","; -- more?
     exit when identifiers( token ).value.all /= ","; -- more?
     expect( symbol_t, "," );
     parameterNumber := parameterNumber + 1;
     formalParamId := identifier( integer( formalParamId ) + 1 );
  end loop;

  -- if the parameter is not found, we don't know if it misnamed
  -- or if there were too many given.
  -- This only applies if there were parameters.
  -- TODO: distinguish these error messages

  if formalParamId = identifiers_top and seenBracket then
     err( "parameter not found or too many parameters" );

  -- Check for too few formal parameters
  --
  -- If there are no actual parameters at all, this whole function
  -- doesn't run.  So this check does not help.

  elsif formalParamId < identifiers_top then
     parameterNumber := parameterNumber + 1;
     formalParamId := identifier( integer( formalParamId ) + 1 );
     while formalParamId < identifiers_top loop
        if identifiers( formalParamId ).field_of = proc_id then
           -- return value is end of function's parameters
           exit when identifiers( formalParamId ).name = "return value";
           if integer'value( to_string( identifiers( formalParamId ).value.all )) = parameterNumber then
              err( "too few parameters" );
              exit;
           end if;
        end if;
        formalParamId := identifier( integer( formalParamId ) + 1 );
     end loop;
  end if;

  -- If an open bracket, we need a closing bracket

  if seenBracket then
     expect( symbol_t, ")" );
  end if;
end ParseActualParameters;

procedure ParseSeparateFuncHeader( func_id : identifier; funcStart : out natural ) is
  -- Syntax: separate( parent ); function p [(param1...)] return type is
  -- Note: forward declaration handling not yet written so minimal parameter
  -- checking in the header.
  separate_func_id : identifier;
  type_token       : identifier;
  parent_id        : identifier;
  b : boolean;
  pu : unbounded_string;
  i : integer;
  ch : character;
begin
   -- separate
   expectSemicolon;
   expect( separate_t );
   expect( symbol_t, "(");
   ParseIdentifier( parent_id );
   pu := identifiers( parent_id ).name;
   -- NOTE: the identifier token returned has the prefix stripped!  This needs
   -- to be fixed so I cannot check to see if it was full path before stripping.
   i := length( pu );
   while i > 0 loop
     ch := element( pu, i );
     if ch = '.' then
        delete( pu, 1, i );
        exit;
     end if;
     i := i - 1;
   end loop;
   if identifiers( parent_id ).class /= userProcClass and identifiers( parent_id ).class /= userFuncClass and identifiers( parent_id ).class /= mainProgramClass then
         err( "parent should be a subprogram" );
   elsif identifiers( parent_id ).name /= pu then
         err( "expected parent unit " & optional_bold( to_string( pu ) ) );
   end if;
   expect( symbol_t, ")");
   expectSemicolon;
   -- separate's procedure header
   funcStart := firstPos;
   expect( function_t );
   -- could do ParseIdentifier since it should exist but want a more meaningful
   -- message error for a mismatch
   ParseProcedureIdentifier( separate_func_id );
   if identifiers( separate_func_id ).value.all = identifiers( func_id ).value.all then
      -- names match?  OK, discard.  proc is stored under original ident
      b := deleteIdent( separate_func_id );
   else
      err( optional_bold( to_string( identifiers( separate_func_id ).name ) ) & " is different from parent file's " & optional_bold( to_string( identifiers( func_id  ).name ) ) );
   end if;
   -- check for forward declarations not yet written so minimal checking here
   -- flush this out if i have time to walk the identifiers list if available
   if token = symbol_t and identifiers( token ).value.all = "(" then
      expect( symbol_t, "(" );
      while token /= symbol_t and identifiers( token ).value.all /= ")" and token /= eof_t loop
         getNextToken;
      end loop;
      expect( symbol_t, ")" );
   end if;
   expect( return_t );
   ParseIdentifier( type_token ); -- don't really care
   if identifiers( func_id ).kind /= type_token then
      err( optional_bold( to_string( identifiers( type_token ).name ) ) & " is different from parent file's " & optional_bold( to_string( identifiers( identifiers( func_id ).kind  ).name ) ) );
   end if;
   expect( is_t );
end ParseSeparateFuncHeader;

procedure ParseFunctionBlock is
  -- Syntax: function [abstract] f OR function [abstract] p return t is block end p;
  -- Handle procedure declarations, including forward declarations.
  -- Note: DoUserDefinedFunction executes a user-defined function created by
  -- this routine.
  func_id   : identifier;
  funcStart : natural;
  funcEnd   : natural;
  no_params   : integer;
  errorOnEntry : boolean := error_found;
  abstract_parameter : identifier := eof_t;
  abstract_return    : identifier := eof_t;
begin
  funcStart := firstPos;
  expect( function_t );
  ParseProcedureIdentifier( func_id );
  identifiers( func_id ).class := userFuncClass;
  identifiers( func_id ).kind := new_t;
  if token = is_t then -- common error
     expect( return_t );
  elsif token /= return_t and not (token = symbol_t and identifiers( token ).value.all = "(" ) then
     -- the following is only true for a forward declaration
     -- (otherwise PPI will return varClass)
     if identifiers( func_id ).class = userFuncClass then
        err( "already forward declared " & optional_bold( to_string( identifiers( func_id ).name ) ) );
     end if;
     -- otherwise, nothing special for a forward declaration
  else
     if token = symbol_t and identifiers( token ).value.all = "(" then
        expect( symbol_t, "(" );
        no_params := 0;
        ParseFormalParameters( func_id, no_params, abstract_parameter, is_function => true );
        expect( symbol_t, ")" );
     end if;
     ParseFunctionReturnPart( func_id, abstract_return );
     pushBlock( newScope => true,
       newName => to_string (identifiers( func_id ).name ) );
     DeclareActualParameters( func_id );
     expect( is_t );

     if token = null_t then                               -- null abstract
        expect( null_t );
        expect( abstract_t );
        identifiers( func_id ).usage := abstractUsage;
        if syntax_check then
           identifiers( func_id ).wasReferenced := true;
        end if;
        pullBlock;
     else
        if token = separate_t then
           if rshOpt then
              err( "subunits are not allowed in a " & optional_bold( "restricted shell" ) );
           end if;
            expect( separate_t );
           -- "is separate" is effectively an include
           -- only insert include on a syntax check
           if syntax_check then
              insertInclude( identifiers( func_id ).name & ".sf" );
           end if;
           ParseSeparateFuncHeader( func_id, funcStart );
        elsif token = abstract_t then
           expect( abstract_t );
           identifiers( func_id ).usage := abstractUsage;
           if syntax_check then
              identifiers( func_id ).wasReferenced := true;
           end if;
        elsif abstract_parameter /= eof_t then
           err( "function must be abstract because parameter type " &
              optional_bold( to_string( identifiers( abstract_parameter ).name ) ) &
              " is abstract" );
        elsif abstract_return /= eof_t then
           err( "function must be abstract because return type " &
              optional_bold( to_string( identifiers( abstract_return ).name ) ) &
              " is abstract" );
        end if;
        ParseDeclarations;
        expect( begin_t );
        SkipBlock;                                       -- never execute
        if syntax_check then
           if not blockHasReturn then
              err( "function has no return value statement" );
           end if;
        end if;
        if token = exception_t then
           ParseExceptionHandler( errorOnEntry );
        end if;
        pullBlock;
        expect( end_t );
        expect( func_id );
        funcEnd := lastPos+1; -- include EOL ASCII.NUL
        identifiers( func_id ).value.all := to_unbounded_string( copyByteCodeLines( funcStart, funcEnd ) );
        -- fake initial indent of 1 for byte code (SOH)
        -- we don't know what the initial indent is (if any) since it may
        -- not be the first token on the line (though it usually is)
     end if;
  end if;
  expectSemicolon;
end ParseFunctionBlock;

procedure DoUserDefinedProcedure( s : unbounded_string ) is
  -- Execute a user-defined procedure.  Based on interpretScript.
  -- procedure_name [(param1 [,param2...])]
  -- Note: ParseProcedureBlock compiles / creates the user-defined procedure.
  -- This routines runs the previously compiled procedure.
  scriptState : aScriptState;
  command     : unbounded_string := s;
  resultName  : unbounded_string;
  results     : unbounded_string;
  proc_id     : identifier;

  -- chain contexts
  chain_count_id   : identifier := eof_t;
  last_in_chain_id : identifier := eof_t;
  in_chain     : boolean := false;
  has_context  : boolean := false;
  last_in_chain: boolean := false;
  contextName  : unbounded_string;
  errorOnEntry : boolean := error_found;
  exitBlockOnEntry : boolean := exit_block;
begin
  proc_id := token;
  if syntax_check then
     -- for declared but not used checking
     --When blocks are pulled, this will be checked.
     identifiers( proc_id ).wasReferenced := true;
     if identifiers( proc_id ).usage = abstractUsage then
        err( optional_bold( to_string( identifiers( proc_id ).name ) ) &
          " is abstract and cannot be run" );
     end if;
  end if;
  getNextToken;

  -- TODO: check for pre-existing chain context
  -- TODO: destroy chain context

  -- To check for a chain, the parameters must be read and the @ located
  -- (if it exists).  This must be done in syntax check mode since we
  -- don't want anything actually declared.  Then return to the start of
  -- the parameters and create a chain context block _prior_ to creating
  -- the procedure block.
  declare
    old_syntax_check : boolean := syntax_check;
    paramStart   : aScannerState;
  begin
    -- do we have a chain context?  Then we must be in a chain.
    contextName := identifiers( proc_id ).name & " chain";
    -- if we already have a context block, don't create another
    if blocks_top > 1 then
       has_context := ( getBlockName( blocks_top-1 ) = contextName );
       in_chain := has_context;
    end if;

    -- check for itself.  If it exists, we must be in a chain
    markScanner( paramStart );
    syntax_check := true;
    ParseActualParameters( proc_id, declareParams => false );
    if ( token = symbol_t or token = word_t ) and identifiers( token ).value.all = "@" then
       in_chain := true;
    end if;
    if has_context then
       if ( token = symbol_t or token = word_t ) and identifiers( token ).value.all = ";" then
          if trace then
             put_trace( "Last call in chain" );
          end if;
          last_in_chain := true;
       end if;
    end if;
    resumeScanning( paramStart );
    syntax_check := old_syntax_check;

    if in_chain then
       -- if we have a context?  then update the content of the context
       if has_context then
--put_line( "DEBUG: has context " );
          findIdent( chain_count_str, chain_count_id );
          if chain_count_id = eof_t then
             err( gnat.source_info.source_location &
                ": internal error: chain count not found" );
          else
             if isExecutingCommand then
                -- values only exist if not syntax check
                identifiers( chain_count_id ).value.all :=
                  to_unbounded_string(
                    to_numeric( identifiers( chain_count_id ).value.all ) + 1.0
                  );
                  findIdent( last_in_chain_str, last_in_chain_id );
                  if last_in_chain_id = eof_t then
                     err( gnat.source_info.source_location &
                        ": internal error: last in chain not found" );
                  end if;
                identifiers( last_in_chain_id ).value.all := to_bush_boolean( last_in_chain );
             end if;
--put_line( "DEBUG: chain count: " & to_string( identifiers( chain_count_id ).value )  );
--put_line( "DEBUG: last in cha: " & to_string( identifiers( last_in_chain_id ).value )  );
          end if;
       -- no context?  then we have to create a new context
       else
--put_line( "DEBUG: new context " );
          if trace then
             put_trace( "Creating chain context " & to_string( contextName ) );
          end if;
          pushBlock( newScope => true, newName => to_string( contextName ) );
          declareIdent( chain_count_id, chain_count_str, natural_t, varClass );
          declareIdent( last_in_chain_id, last_in_chain_str, boolean_t, varClass );
          if syntax_check then
             identifiers( chain_count_id ).wasReferenced := true;
             identifiers( chain_count_id ).wasWritten := true;
             identifiers( chain_count_id ).wasFactor := true;
             identifiers( last_in_chain_id ).wasReferenced := true;
             identifiers( last_in_chain_id ).wasWritten := true;
             identifiers( last_in_chain_id ).wasFactor := true;
          else
             if isExecutingCommand then
                -- values only exist if not syntax check
                identifiers( chain_count_id ).value.all := to_unbounded_string( " 1" );
                identifiers( last_in_chain_id ).value.all := to_bush_boolean( last_in_chain );
                -- TODO: we only want to export these if we are the current chain.
                -- Otherwise, they will always be exported even if the chain was further
                -- down the block stack
                --identifiers( chain_count_id ).export := true;
                --identifiers( last_in_chain_id ).export := true;
--put_line( "DEBUG: chain count: " & to_string( identifiers( chain_count_id ).value ) );
--put_line( "DEBUG: last in cha: " & to_string( identifiers( last_in_chain_id ).value ) );
             end if;
          end if;
       end if;
    end if;
    -- put_all_identifiers; -- DEBUG
  end;

  pushBlock( newScope => true,
     newName => to_string (identifiers( proc_id ).name ) );
  -- token will be @ here if in a chain but the final ; may or may not
  -- indicate a chain
  -- declareIdent( formal_param_id, to_unbounded_string( "chain count" ), type_token, varClass );
  -- if syntax_check then
  --    identifiers( formal_param_id ).wasReferenced := true;
  -- end if;
  if isExecutingCommand then
  -- Notice nothing gets executed during syntax check.  Any variables/parameters
  -- will have wasReferenced as false.
  -- TODO: perhaps using syntax_check inside PAP would fix this.
     --if token = symbol_t and identifiers( token ).value.all = "(" then
     ParseActualParameters( proc_id );
     --end if;
     parseNewCommands( scriptState, s );
     results := null_unbounded_string;        -- no results (yet)
     expect( procedure_t );
     if token = abstract_t then
        expect( abstract_t );
     end if;
     ParseIdentifier( proc_id );
     -- we already know the parameter syntax is good so skip to "is"
     while token /= is_t loop
        getNextToken;
     end loop;
     expect( is_t );
     ParseDeclarations;
     expect( begin_t );
     ParseBlock;
     if token = exception_t then
        ParseExceptionHandler( errorOnEntry );
     end if;
     -- Check to see if we're return-ing early
     -- TODO: Not pretty, but will work.  This should be improved.
     if exit_block and done_sub and not error_found and not syntax_check then
        done_sub := false;
        exit_block := exitBlockOnEntry;  -- is this right?
        done := false;
     end if;
     expect( end_t );
     expect( proc_id );
     expectSemicolon;
     if not done then                     -- not exiting?
         expect( eof_t );                  -- should be nothing else
     end if;
     restoreScript( scriptState );               -- restore original script
  elsif syntax_check or exit_block then
     -- at this point, we are still looking at call
     if length( s ) = 0 then
        err( "(forward) procedure declaration not completed" );
     else
        -- because nothing executes during a syntax check, we still need
        -- to parse the parameters to check for errors, but don't declare
        -- anything because wasReferenced will be false.
        ParseActualParameters( proc_id, declareParams => false );
     end if;
  end if;
  pullBlock;

  if last_in_chain and has_context then
     if trace then
        put_trace( "Destroying chain context " & to_string( contextName ) );
     end if;
     pullBlock;
  end if;
end DoUserDefinedProcedure;

procedure DoUserDefinedFunction( s : unbounded_string; result : out unbounded_string ) is
  -- Execute a user-defined function.  Based on interpretScript.  Return value
  -- for function is result parameter.
  -- function_name [(param1 [,param2...])]
  -- Note: ParseFunctionBlock compiles / creates the user-defined function.
  -- This routines runs the previously compiled function.
  scriptState : aScriptState;
  command     : unbounded_string := s;
  func_id     : identifier;
  return_id   : identifier;
  resultName  : unbounded_string;
  results     : unbounded_string;
  errorOnEntry : boolean := error_found;
  exitBlockOnEntry : boolean := exit_block;
begin
  -- Get the name of the function being called
  func_id := token;
  if syntax_check then
     -- for declared but not used checking
     --When blocks are pulled, this will be checked.
     identifiers( func_id ).wasReferenced := true;
     if identifiers( func_id ).usage = abstractUsage then
        err( optional_bold( to_string( identifiers( func_id ).name ) ) &
          " is abstract and cannot be run" );
     end if;
  end if;
  getNextToken;
  -- Parameters will be in the new scope block
  pushBlock( newScope => true,
     newName => to_string (identifiers( func_id ).name ) );
  -- Parameters?  Create storage space in the symbol table
  if isExecutingCommand then
     --if token = symbol_t and identifiers( token ).value.all = "(" then
     ParseActualParameters( func_id );
     --end if;
     -- Prepare to execute.  This should probably be a utility function.
     parseNewCommands( scriptState, s );
     results := null_unbounded_string;        -- no results (yet)
     expect( function_t );                    -- function
     if token = abstract_t then
        expect( abstract_t );
     end if;
     ParseIdentifier( func_id );              -- function name
     while token /= is_t loop                 -- skip header - syntax is good
        getNextToken;                         -- and params are declared
     end loop;
     expect( is_t );                          -- is
     ParseDeclarations;                       -- declaration block
     expect( begin_t );                       -- begin
     ParseBlock;                              -- executable block
     if token = exception_t then
        ParseExceptionHandler( errorOnEntry );
     end if;
     -- Check to see if we're return-ing early
     -- TODO: Not pretty, but will work.  This should be improved.
     if exit_block and done_sub and not error_found and not syntax_check then
        done_sub := false;
        exit_block := exitBlockOnEntry;
        done := false;
     end if;
     expect( end_t );                         -- end
     expect( func_id );                       -- function_name
     expectSemicolon;
     if not done then                         -- not exiting?
         expect( eof_t );                     -- should be nothing else
     end if;
     -- return value is top-most variable called "return value"
     findIdent( to_unbounded_string( "return value" ), return_id );
     result := identifiers( return_id ).value.all;
     restoreScript( scriptState );            -- restore original script
  elsif syntax_check or exit_block then
     -- at this point, we are still looking at call
     if length( s ) = 0 then
        err( "(forward) function declaration not completed" );
     else
        -- because nothing executes during a syntax check, we still need
        -- to parse the parameters to check for errors, but don't declare
        -- anything because wasReferenced will be false.
        ParseActualParameters( func_id, declareParams => false );
     end if;
  end if;
  pullBlock;                                  -- discard locals
end DoUserDefinedFunction;

procedure ParseShellCommand is
  -- Syntax: command-word ( expr [,expr...] )
  -- Syntax: command-word param-word [param-word...]
  cmdNameToken : identifier;
  cmdName    : unbounded_string;
  expr_val   : unbounded_string;
  expr_type  : identifier;
  ap         : argumentListPtr;          -- list of parameters to the cmd
  paramCnt   : natural;                  -- number of parameters in ap
  firstParam : aScannerState;
  Success    : boolean;
  exportList : argumentListPtr;          -- exported C-string variables
  exportCnt  : natural := 0;             -- number of exported variables

  procedure exportVariables is
  -- Search for all exported variables and export them to the
  -- environment so that the program we're running can see them.
  -- The search must start at the bottom of the symbol table so
  -- that, in the case of two exported variables with the same
  -- name, the most recent scope will supercede the older
  -- declaration.
  --  The variables exported are stored in exportList/exportCnt.
  -- Under UNIX/Linux, the application is responsible for storing
  -- the exported variables as C-strings.  The list must be cleared
  -- afterward.
  -- Note: this is not very efficient.
    exportPos  : positive := 1;        -- position in exportList
    tempStr    : unbounded_string;
  begin
    -- count the number of exportable variables
    for id in 1..identifiers_top-1 loop
        if identifiers( id ).export and not identifiers( id ).deleted then
           exportCnt := exportCnt+1;
        end if;
    end loop;
    -- if there are exportable variables, export them and place them
    -- in exportList.
    if exportCnt > 0 then
       exportList := new argumentList( 1..positive( exportCnt ) );
       for id in 1..identifiers_top-1 loop
           if identifiers( id ).export and not identifiers( id ).deleted then
              -- a regular export means exporting the variable's value.  If
              -- it's a json export, then we have to convert the value to
              -- a json string (especially if it is a complex type)
              tempStr := identifiers( id ).value.all;
              if identifiers( id ).mapping = json then
                 if getUniType( identifiers( id ).kind ) = uni_string_t then
                    tempStr := DoStringToJson( tempStr );
                 elsif identifiers( id ).list then
                    DoArrayToJSON( tempStr, id );
                 elsif  identifiers( getBaseType( identifiers( id ).kind ) ).kind  = root_record_t then
                    DoRecordToJSON( tempStr, id );
                 elsif getUniType( identifiers( id ).kind ) = uni_numeric_t then
                    null; -- for numbers, JSON is as-is
                 else
                    err( "json export not yet written for this type" );
                 end if;
              end if;
              tempStr := identifiers( id ).name & "=" & tempStr;
              if trace then
                 put_trace( "exporting '" & to_string( tempStr ) & "'" );
              end if;
              exportList( exportPos ) := new string( 1..length( tempStr )+1 );
              exportList( exportPos ).all := to_string( tempStr ) & ASCII.NUL;
              if putenv( exportList( exportPos ).all ) /= 0 then
                 err( "unable to export " & optional_bold( to_string( identifiers( id ).name) ) );
              end if;
              exportPos := exportPos + 1;
           end if;
       end loop;
    end if;
  end exportVariables;

  procedure clearExportedVariables is
    -- Clear the strings allocated in exportVariables
    -- should individual strings be deallocated?  If so, need to declare
    -- free?  Also, ap list?
    equalsPos : natural;
    result    : integer;
  begin
    if exportCnt > 0 then
       -- Remove exported items from environment O/S environment
       for i in exportList'range loop
           for j in exportList(i).all'range loop
               if exportList(i)(j) = '=' then
                  equalsPos := j;
                  exit;
               end if;
           end loop;
           C_reset_errno; -- freebsd bug: doesn't return result properly
           result := unsetenv( exportList( i )( 1..equalsPos-1 ) & ASCII.NUL );
           if result /= 0 and C_errno /= 0 then
              err( "unable to remove " &
                   optional_bold( exportList( i )( 1..equalsPos-1 ) ) &
                   "from the O/S environment" );
           end if;
       end loop;
       -- Deallocate memory
       for i in exportList'range loop
           free( exportList( i ) );
       end loop;
       free( exportList ); -- deallocate memory
       exportCnt := 0;
    end if;
  end clearExportedVariables;

  procedure clearParamList is
  begin
    for i in ap'range loop
        free( ap( i ) );
    end loop;
    free( ap );
  end clearParamList;

  function isParenthesis return boolean is
  -- check for a paranthesis, skipping any white space in front.
  begin
     skipWhiteSpace;
     return token = symbol_t and identifiers( token ).value.all = "(";
     -- return script( cmdpos ) = '(';
  end isParenthesis;

  -- Word parsing and Parameter counting

  word         : unbounded_string;
  pattern      : unbounded_string;
  inBackground : boolean;
  wordType     : aShellWordType;

  -- Pipeline parsing

  pipe2Next    : boolean := false;
  pipeFromLast : boolean := false;

  -- I/O Redirection parsing

  expectRedirectInFile        : boolean := false;     -- encountered <
  expectRedirectOutFile       : boolean := false;     -- encountered >
  expectRedirectAppendFile    : boolean := false;     -- encountered >>
  expectRedirectErrOutFile    : boolean := false;     -- encountered 2>
  expectRedirectErrAppendFile : boolean := false;     -- encountered 2>>

  redirectedInputFd           : aFileDescriptor := 0; -- input fd (if not 0)
  redirectedOutputFd          : aFileDescriptor := 0; -- output fd (if not 0)
  redirectedAppendFd          : aFileDescriptor := 0; -- output fd (if not 0)
  redirectedErrOutputFd       : aFileDescriptor := 0; -- err out fd (if not 0)
  redirectedErrAppendFd       : aFileDescriptor := 0; -- err out fd (if not 0)

  result                      : aFileDescriptor;
  closeResult                 : int;

    procedure externalCommandParameters( ap : out argumentListPtr; list : in out shellWordList.List ) is
     len  : positive;
     theWord : aShellWord;
  begin
     if shellWordList.Length( list ) = 0 then
        ap := new argumentList( 1..0 );
        return;
     end if;
     len := positive( shellWordList.Length( list ) );
     ap := new argumentList( 1..len );
     for i in 1..len loop
         shellWordList.Find( list, long_integer( i ), theWord );
         ap( i ) := new string( 1..positive( length( theWord.word ) + 1 ) );
         ap( i ).all := to_string( theWord.word ) & ASCII.NUL;
     end loop;
  end externalCommandParameters;

  procedure checkRedirectFile is
    -- Check for a missing file for a redirection operator.  If a file
    -- was expected (according to the flags) but has not appeared, show
    -- an appropriate error message.
  begin
     if expectRedirectOutFile then
        err( "expected > file" );
     elsif expectRedirectInFile then
        err( "expected < file" );
     elsif expectRedirectAppendFile then
        err( "expected >> file" );
     end if;
  end checkRedirectFile;

  wordList   : shellWordList.List;
  shellWord  : aShellWord;

  itselfNext : boolean := false;  -- true if a @ was encountered

begin

  -- ParseGeneralStatement just did a resumeScanning.  The token should
  -- still be set to the value of the first word.

   -- Loop for all commands in a pipeline.

<<next_in_pipeline>>
  -- Reset parsing variables related to a single command

   -- shellWordList.Clear( wordList );                          -- discard params

  -- ParseGeneralStatement has rolled back the scanner after checking for :=.
  -- Reload the next token.

  -- getNextToken;

  -- Expand command variable (if any).  Otherwise, parse the first shell
  -- word.
  --
  -- Basically, we can't have a bareword expansion because of this: if the
  -- command is AdaScript syntax, the tokens need to be read from the script.
  -- It can't read tokens from the shell word list.  (e.g. if $cmd = "ls (",
  -- a $cmd bareword will put the paranthesis in the word list, not in the
  -- command line, after parsing.)
  --
  -- So, for now, I require the first shell word not to be a bareword with
  -- multiple subwords after expansion.  However, some of this could be
  -- improved in the future.

     cmdNameToken := token;                       -- avoid prob below w/discard
     ParseOneShellWord( wordType, pattern, cmdName, First => true );
     itself := cmdName;                                    -- this is new @

  -- AdaScript Syntax: count the number of parameters, generate an argument
  -- list of the correct length, interpret the parameters "for real".

<<restart_with_itself>>

  inBackground := false;                                 -- assume fg command
  paramCnt := 0;                                         -- params unknown

  if isParenthesis then                                  -- parenthesis?
     -- getNextToken;                                       -- AdaScript syntax
     expect( symbol_t, "(" );                            -- skip paraenthesis
     markScanner( firstParam );                          -- save position
     while not error_found and token /= eof_t loop       -- count parameters
        ParseExpression( expr_val, expr_type );
        shellWordList.Queue( wordList, aShellWord'( normalWord, expr_val, expr_val ) );
        paramCnt := paramCnt + 1;
        if Token = symbol_t and then identifiers( Token ).value.all = "," then
           getNextToken;
        else
           exit;
        end if;
     end loop;
     expect( symbol_t, ")" );
     if token = symbol_t and identifiers( token ).value.all = "|" then
        pipe2Next := true;
        getNextToken;
     end if;
     if pipe2Next and onlyAda95 then
        err( "pipelines are not allowed with " & optional_bold( "pragma ada_95" ) );
     end if;
     if token = symbol_t and identifiers(token).value.all = "&" then
        inbackground := true;
        expect( symbol_t, "&" );
        if pipe2Next then
           err( "no & - piped commands are automatically run in the background" );
        elsif pipeFromLast then
           err( "no & - final piped command always runs in the foreground" );
        end if;
     end if;

  else

    -- Bourne shell parameters

     -- discardUnusedIdentifier( token );
    -- Shell-style parameters.  Read a series of "words", counting the params.
    -- Generate an argument list of the correct length and repeat "for real".

     -- count loop
     -- markScanner( firstParam );
     word := null_unbounded_string;

     -- Some arguments, | or @ ? go get them...
     if token /= symbol_t or else identifiers( token ).value.all /= ";" then
        ParseShellWords( wordList, First => false );
     end if;
     for i in 1..shellWordList.Length( wordList ) loop
        shellWordList.Find( wordList, i, shellWord );
        if shellWord.wordType = semicolonWord then
           shellWordList.Clear( wordList, i );
           exit;
        elsif shellWord.wordType = pipeWord then
           shellWordList.Clear( wordList, i );
           pipe2Next := true;
           exit;
        elsif shellWord.wordType = itselfWord then
           shellWordList.Clear( wordList, i );
           itselfNext := true;
        elsif error_found then
           exit;
        end if;
        if shellWord.wordType = redirectOutWord or
           shellWord.wordType = redirectInWord or
           shellWord.wordType = redirectAppendWord or
           shellWord.wordType = redirectErrOutWord or
           shellWord.wordType = redirectErrAppendWord then
           if onlyAda95 then
              err( "command line redirection not allowed with " &
                   optional_bold( "ada_95" ) & ".  Use set_output / set_input instead" );
           end if;
           expectRedirectOutFile := true;
        elsif expectRedirectOutFile then           -- redirect filenames
           expectRedirectOutFile := false;         -- not in param list
        elsif wordType = redirectErr2OutWord then
           null;                                   -- no file needed
        end if;
     end loop;
     if pipe2Next and onlyAda95 then
        err( "pipelines not allowed with " & optional_bold( "pragma ada_95" ) );
     end if;
     if shellWordList.length( wordList ) > 0 and onlyAda95 then
        err( "Bourne shell parameters not allowed with " &
             optional_bold( "pragma ada_95" ) );
     end if;

     -- create loop
     --resumeScanning( firstParam );

     -- at this point, the token is the first "word".  Discard it if it is
     -- an unused identifier.

     -- At this point, wordList contains a list of shell word parameters for
     -- the command.  This includes redirections, &, and so forth.  Next,
     -- examine all shell arguments, interpreting them and removing
     -- them from the list.  Set up all I/O redirections as required.  When
     -- this loop is finished, only the command parameters should remain the
     -- word list.

     paramCnt := 1;
     while long_integer( paramCnt ) <= shellWordList.Length( wordList ) loop
        shellWordList.Find( wordList, long_integer( ParamCnt ), shellWord );
-- put_line( "  processing = " & paramCnt'img & " - " & shellWord.pattern & " / " & shellWord.word & "/" & shellWord.wordType'img );

        -- There is no check for multiple filenames after redirections.
        -- This behaviour is the same as BASH: "echo > t.t t2.t" will
        -- write t2.t to the file t.t in both BASH and BUSH.

        if expectRedirectOutFile then             -- expecting > file?
           expectRedirectOutFile := false;
           if redirectedAppendFD > 0 then
              err( "cannot redirect using both > and >>" );
           elsif rshOpt then
              err( "cannot redirect > in a " & optional_bold( "restricted shell" ) );
           elsif pipe2Next then
              err( "> file should only be after the last pipeline command" );
           elsif isExecutingCommand then
<<retry1>> redirectedOutputFd := open( to_string( shellWord.word ) & ASCII.NUL,
                 O_WRONLY+O_TRUNC+O_CREAT, 8#644# );
              if redirectedOutputFd < 0 then
                 if C_errno = EINTR then
                    goto retry1;
                 end if;
                 err( "Unable to open > file: " & OSerror( C_errno ) );
              else
<<retry2>>       result := dup2( redirectedOutputFd, stdout );
                 if result < 0 then
                    if C_errno = EINTR then
                       goto retry2;
                    end if;
                    err( "unable to set output: " & OSerror( C_errno ) );
                    closeResult := close( redirectedOutputFd );
                    -- close EINTR is a diagnostic message.  Do not handle.
                    redirectedOutputFd := 0;
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif expectRedirectInFile then
           expectRedirectInFile := false;         -- expecting < file?
           if pipeFromLast then
              err( "< file should only be after the first pipeline command" );
           elsif isExecutingCommand then
<<retry4>>    redirectedInputFd := open( to_string( shellWord.word ) & ASCII.NUL, O_RDONLY, 8#644# );
              if redirectedInputFd < 0 then
                 if C_errno = EINTR then
                    goto retry4;
                 end if;
                 err( "Unable to open < file: " & OSerror( C_errno ) );
              else
<<retry5>>       result := dup2( redirectedInputFd, stdin );
                 if result < 0 then
                    if C_errno = EINTR then
                       goto retry5;
                    end if;
                    err( "unable to redirect input: " & OSerror( C_errno ) );
                    closeResult := close( redirectedInputFd );
                    -- close EINTR is a diagnostic message.  Do not handle.
                    redirectedInputFd := 0;
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif expectRedirectAppendFile then
           expectRedirectAppendFile := false;
           if redirectedOutputFD > 0 then
              err( "cannot redirect using both > and >>" );
           elsif pipe2Next then
              err( ">> file should only be after the last pipeline command" );
           elsif isExecutingCommand then
<<retry7>>    redirectedAppendFd := open( to_string( shellWord.word ) & ASCII.NUL, O_WRONLY+O_APPEND, 8#644# );
              if redirectedAppendFd < 0 then
                 if C_errno = EINTR then
                    goto retry7;
                 end if;
                 err( "Unable to open >> file: " & OSerror( C_errno ) );
              else
<<retry8>>       result := dup2( redirectedAppendFd, stdout );
                 if result < 0 then
                    if C_errno = EINTR then
                       goto retry8;
                    end if;
                    err( "unable to append output: " & OSerror( C_errno ) );
                    closeResult := close( redirectedAppendFd );
                    -- close EINTR is a diagnostic message.  Do not handle.
                    redirectedAppendFd := 0;
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif expectRedirectErrOutFile then             -- expecting 2> file?
           expectRedirectErrOutFile := false;
           if redirectedErrAppendFD > 0 then
<<retry10>>   result := dup2( currentStandardError, stderr );  -- restore stderr
              if result < 0 then                              -- check for error
                 if C_errno = EINTR then
                    goto retry10;
                 end if;
                 err( "unable to restore current error output: " & OSerror( C_errno ) );
              end if;
              closeResult := close( redirectedErrOutputFd );        -- done with file
              -- close EINTR is a diagnostic message.  Do not handle.
              redirectedErrOutputFD := 0;
              err( "cannot redirect using both 2> and 2>>" );
           elsif pipe2Next then
              err( "2> file should only be after the last pipeline command" );
           elsif isExecutingCommand then
<<retry12>>   redirectedErrOutputFd := open( to_string( shellWord.word ) & ASCII.NUL,
                 O_WRONLY+O_TRUNC+O_CREAT, 8#644# );
              if redirectedErrOutputFd < 0 then
                 if C_errno = EINTR then
                    goto retry12;
                 end if;
                 err( "Unable to open 2> file: " & OSerror( C_errno ) );
              elsif rshOpt then
                 err( "cannot redirect 2> in a " & optional_bold( "restricted shell" ) );
              else
<<retry13>>      result := dup2( redirectedErrOutputFd, stderr );
                 if result < 0 then
                    if C_errno = EINTR then
                       goto retry13;
                    end if;
                    err( "unable to set error output: " & OSerror( C_errno ) );
                    closeResult := close( redirectedErrOutputFd );
                    -- close EINTR is a diagnostic message.  Do not handle.
                    redirectedErrOutputFd := 0;
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif expectRedirectErrAppendFile then
           expectRedirectErrAppendFile := false;
           if redirectedErrOutputFD > 0 then
<<retry15>>   result := dup2( currentStandardError, stderr );  -- restore stderr
              if result < 0 then                              -- check for error
                 if C_errno = EINTR then
                    goto retry15;
                 end if;
                 err( "unable to restore current error output: " & OSerror( C_errno ) );
              end if;
              closeResult := close( redirectedErrOutputFd );           -- done with file
              -- close EINTR is a diagnostic message.  Do not handle.
              redirectedErrOutputFD := 0;
              err( "cannot redirect using both 2> and 2>>" );
           elsif pipe2Next then
              err( "2>> file should only be after the last pipeline command" );
           elsif isExecutingCommand then
<<retry17>>   redirectedErrAppendFd := open( to_string( shellWord.word ) & ASCII.NUL, O_WRONLY+O_APPEND, 8#644# );
              if redirectedErrAppendFd < 0 then
                 if C_errno = EINTR then
                    goto retry17;
                 end if;
                 err( "Unable to open 2>> file: " & OSerror( C_errno ) );
              else
<<retry18>>      result := dup2( redirectedErrAppendFd, stderr );
                 if result < 0 then
                    if C_errno = EINTR then
                       goto retry18;
                    end if;
                    err( "unable to append error output: " & OSerror( C_errno ) );
                    closeResult := close( redirectedErrAppendFd );
                    -- close EINTR is a diagnostic message.  Do not handle.
                    redirectedErrAppendFd := 0;
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectOutWord then     -- >? expect a file?
           checkRedirectFile;                     -- check for missing file
           expectRedirectOutFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectInWord then      -- < ? expect a file
           checkRedirectFile;                     -- check for missing file
           expectRedirectInFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectAppendWord then  -- >> ? expect a file
           checkRedirectFile;                     -- check for missing file
           expectRedirectAppendFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectErrOutWord then  -- 2> ? expect a file
           checkRedirectFile;                     -- check for missing file
           expectRedirectErrOutFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectErrAppendWord then  -- 2>> ? expect a file
           checkRedirectFile;                     -- check for missing file
           expectRedirectErrAppendFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectErr2OutWord then  -- expecting 2>&1 file?
           if redirectedErrOutputFD > 0 then       -- no file for this one
<<retry20>>   result := dup2( currentStandardError, stderr );  -- restore stderr
              if result < 0 then                              -- check for error
                 if C_errno = EINTR then
                    goto retry20;
                 end if;
                 err( "unable to restore current error output: " & OSerror( C_errno ) );
              end if;
              closeResult := close( redirectedErrOutputFd );          -- done with file
              -- close EINTR is a diagnostic message.  Do not handle.
              redirectedErrOutputFD := 0;
              err( "cannot redirect using two of 2>, 2>> and 2>&1" );
           elsif redirectedErrAppendFD > 0 then       -- no file for this one
<<retry22>>   result := dup2( currentStandardError, stderr );  -- restore stderr
              if result < 0 then                               -- check for error
                 if C_errno = EINTR then
                    goto retry22;
                 end if;
                 err( "unable to restore current error output: " & OSerror( C_errno ) );
              end if;
              closeResult := close( redirectedErrAppendFd );   -- done with file
              -- close EINTR is a diagnostic message.  Do not handle.
              redirectedErrAppendFD := 0;
              err( "cannot redirect using two of 2>, 2>> and 2>&1" );
           elsif pipe2Next then
              err( "2>&1 file should only be after the last pipeline command" );
           else
<<retry24>>   redirectedErrOutputFd := dup2( currentStandardOutput, stderr );
              if redirectedErrOutputFd < 0 then
                 if C_errno = EINTR then
                    goto retry24;
                 end if;
                 redirectedErrOutputFd := 0;
                 err( "unable to set error output: " & OSerror( C_errno ) );
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = ampersandWord then       -- & ?
           if shellWordList.aListIndex( paramCnt ) /= shellWordList.Length( wordList ) then
              err( "unexpected arguments after &" );
           end if;
           inbackground := true;
           if pipe2Next then
              err( "no & - piped commands are automatically run in the background" );
           elsif pipeFromLast then
              err( "no & - final piped command always runs in the foreground" );
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        end if;
        paramCnt := paramCnt+1;
     end loop;
     checkRedirectFile;                               -- check for missing file

  end if;

  -- End of Parameter Parsing

  -- At this point, only the command parameters should remain the word list.
  -- The input/output redirection are in place.  Declare the parameters and
  -- execute the command.

  if isExecutingCommand then                                -- no problems?
     exportVariables;                                       -- make environment

     -- Create a list of C-strings for the parameters

     externalCommandParameters( ap, wordList );

     if boolean(rshOpt) and then Element( cmdName, 1 ) = '/' then -- rsh & cmd path
        err( "absolute paths to commands not allowed in " &
             optional_bold( "restricted shells" ) );
     elsif not pipeFromLast and pipe2next then              -- first in pipeln?
        run_inpipe( cmdName, cmdNameToken, ap, Success,     -- pipe output
           background => true,
           cache => inputMode /= interactive );
     elsif pipeFromLast and not pipe2next then              -- last in pipeln?
        run_frompipe( cmdName, cmdNameToken, ap, Success,   -- pipe input
           background => false,
           cache => inputMode /= interactive );
        closePipeline;
        -- certain cmds (like "less") need to be cleaned up
        -- with wait4children.  Others are OK.  Why?
        -- wait4children                                    -- (child cleanup)
        -- wait4LastJob?
     elsif pipeFromLast and pipe2next then                  -- inside pipeline?
        run_bothpipe( cmdName, cmdNameToken, ap, Success,   -- pipe in & out
           background => true,
           cache => inputMode /= interactive );
     else                                                   -- no pipeline?
        run( cmdName, cmdNameToken, ap, Success,            -- just run it
           background => inBackground,
           cache => inputMode /= interactive );             -- run the command
     end if;
     clearExportedVariables;                                -- clear environ
     discardUnusedIdentifier( cmdNameToken );               -- drop if not ident
  else                                                      -- cmd failure?

     -- If a pipeline command fails, then commands running in the
     -- background that accept user input will conflict with the
     -- command prompt.  We've got to wait until the final successful
     -- pipe command is finished before returning to the command prompt.
     --   For example, "cat | grep "h" < t.t" will fail because "<" must
     -- be on the first command.  However, cat will already be running
     -- in the background when the error occurs.  BUSH will wait until
     -- ctrl-d is pressed, at which time the user is presented with the
     -- command prompt.  (This is the same behaviour as BASH.)
     --   Background commands do not require special handling.

     if pipeFromLast or pipe2next then                      -- in a pipeline?
        wait4LastJob;                                       -- (child cleanup)
     end if;

  end if;                                                   -- then discard it

  -- If there was command-line redirection, restore standard input/
  -- output to the original destinations.  The original files will
  -- be saved in currentStandardInput/Output.  The redirect flags
  -- should be set properly even if a parsing error occurred.

  if redirectedOutputFd > 0 then                            -- output redirect?
<<retry24b>> result := dup2( currentStandardOutput, stdout );       -- restore output
     if result < 0 then                                     -- check for error
        if C_errno = EINTR then
           goto retry24b;
        end if;
        err( "unable to restore current output: " & OSerror( C_errno ) );
     end if;
     closeResult := close( redirectedOutputFd );     -- done with file
     -- close EINTR is a diagnostic message.  Do not handle.
  elsif redirectedInputFd > 0 then                          -- input redirect?
<<retry25b>> result := dup2( currentStandardInput, stdout );-- restore input
     if result < 0 then                                     -- check for error
        if C_errno = EINTR then
           goto retry25b;
        end if;
        err( "unable to restore current input: " & OSerror( C_errno ) );
     end if;
     closeResult := close( redirectedInputFd );      -- done with file
     -- close EINTR is a diagnostic message.  Do not handle.
  elsif redirectedAppendFd > 0 then                         -- append redirect?
<<retry26b>> result := dup2( currentStandardOutput, stdout );-- restore output
     if result < 0 then                                     -- check for error
        if C_errno = EINTR then
           goto retry26b;
        end if;
        err( "unable to restore current output: " & OSerror( C_errno ) );
     end if;
     closeResult := close( redirectedAppendFd );     -- done with file
     -- close EINTR is a diagnostic message.  Do not handle.
  elsif redirectedErrOutputFd > 0 then                      -- errout redirect?
<<retry27b>> result := dup2( currentStandardError, stderr );-- restore stderr
     if result < 0 then                                     -- check for error
        if C_errno = EINTR then
           goto retry27b;
        end if;
        err( "unable to restore current error output: " & OSerror( C_errno ) );
     end if;
     closeResult := close( redirectedErrOutputFd );  -- done with file
     -- close EINTR is a diagnostic message.  Do not handle.
  elsif redirectedErrAppendFd > 0 then                      -- append redirect?
<<retry28b>>result := dup2( currentStandardError, stderr ); -- restore stderr
     if result < 0 then                                     -- check for error
        if C_errno = EINTR then
           goto retry28b;
        end if;
        err( "unable to restore current error output: " & OSerror( C_errno ) );
     end if;
     closeResult := close( redirectedErrAppendFd );  -- done with file
     -- close EINTR is a diagnostic message.  Do not handle.
  end if;

  -- restore the semi-colon we threw away at the beginning
  -- by this point, Token is eof_t, so we'll have to force it to a ';'
  -- since once Token is eof_t, it's always eof_t in the scanner

  if ap /= null then                                        -- parameter list?
     clearParamList;                                        -- discard it
     shellWordList.Clear( wordList );
  end if;

  -- Comand complete.  Look for next in pipeline (if any).

  pipeFromLast := pipe2Next;                                -- input from out
  if pipeFromLast and not error_found and not done then     -- OK so far?
     pipe2Next := false;                                    -- reset pipe flag
     if not error_found then                                -- found it?
        goto next_in_pipeline;                              -- next piped cmd
     end if;
  end if;

  -- Command ended with @?  Re-run with new parameters...

  if itselfNext then
     itselfNext := false;
     goto restart_with_itself;
  end if;
end ParseShellCommand;


-----------------------------------------------------------------------------
--  COMPILE AND RUN
--
-- Compile and run the byte code.  Do not capture the output.
-- Set fragmement to false if the byte code is a complete script rather than
-- extracted from as a subscript.  You usually want to use
-- CompileRunAndCaptureOutput.  The only thing that uses this procedure
--  directly is the pragma debug because we don't want to capture the output.
-----------------------------------------------------------------------------

procedure CompileAndRun( commands : unbounded_string; firstLineNo : natural := 1; fragment : boolean := true ) is
  scriptState : aScriptState;
  --command     : unbounded_string := s;
  resultName  : unbounded_string;
  byteCode    : unbounded_string;
begin
-- TODO: set the line number from the enclosing script
  saveScript( scriptState );                            -- save current script
  compileCommand( commands, firstLineNo );              -- compile subscript
  byteCode := to_unbounded_string( script.all );        -- grab the byte code
  restoreScript( scriptState );                         -- restore original script
  if not error_found then                               -- no errors?
     if isExecutingCommand or Syntax_Check then            -- for real or check
        parseNewCommands( scriptState, byteCode, fragment ); -- setup byte code
        loop                                               -- run commands
           ParseGeneralStatement;                          -- general stmts
        exit when done or error_found or token = eof_t;    -- until done, error
        end loop;                                          --  or reached eof
        if not done then                                   -- not done?
           expect( eof_t );                                -- should be eof
       end if;
       restoreScript( scriptState );                 -- restore original script
     end if;
  end if;
end CompileAndRun;

-----------------------------------------------------------------------------
-- RUN AND CAPTURE OUTPUT
--
-- Run the byte code and return the results.  Set fragmement to false if the
-- byte code is a complete script rather than extracted from as a subscript.
-- You usually want to use CompileRunAndCaptureOutput.  The only thing that
-- uses this procedure directly is the prompt script because the byte code
-- is saved.
--
-- TODO: SHOULD BE REWRITTEN TO USE PIPES INSTEAD OF TEMP FILE
-- based on interpretScript
-----------------------------------------------------------------------------

procedure RunAndCaptureOutput( s : unbounded_string; results : out
  unbounded_string; fragment : boolean := true ) is
  scriptState : aScriptState;
  --command     : unbounded_string := s;
  oldStandardOutput : aFileDescriptor;
  resultFile  : aFileDescriptor := -1;
  resultName  : unbounded_string;
  result      : aFileDescriptor;
  closeResult : int;
  unlinkResult : int;
  ch          : character := ASCII.NUL;
  chars       : size_t;
begin
  -- saveScript( scriptState );                  -- save current script
-- put_token; -- DEBUG
  results := null_unbounded_string;
  if isExecutingCommand then                               -- only for real
     makeTempFile( resultName );                           -- results filename
     resultFile := open( to_string( resultName ) & ASCII.NUL, -- open results
        O_WRONLY+O_TRUNC, 8#644# );                        -- for writing
     if resultFile < 0 then                                -- failed?
        err( "RunAndCaptureOutput: unable to open file: "&
           OSerror( C_errno ));
     elsif trace then                                      -- trace on?
        put_trace( "results will be captured from file descriptor" &
          resultFile'img );
     end if;
  end if;
  if isExecutingCommand or Syntax_Check then               -- for real or check
     parseNewCommands( scriptState, s, fragment );         -- install cmds
  end if;
  if isExecutingCommand and resultFile > 0 then            -- only for real
     oldStandardOutput := currentStandardOutput;           -- save old stdout
     result := dup2( resultFile, stdout );                 -- redirect stdout
     if result < 0 then                                    -- error?
        err( "unable to set output: " & OSerror( C_errno ) );
     elsif not error_found then                            -- no error?
        currentStandardOutput := resultFile;               -- track fd
     end if;
  end if;
  if isExecutingCommand or Syntax_Check then               -- for real or check
     loop                                                  -- run commands
        ParseGeneralStatement;                             -- general stmts
        exit when done or error_found or token = eof_t;    -- until done, error
      end loop;                                            --  or reached eof
      if not done then                                     -- not done?
         expect( eof_t );                                  -- should be eof
     end if;
  end if;
  -- Read the results.  Don't worry if a syntax check or not.  If we were
  -- redirecting for any reason, get the results and restore standard output
  -- if commands contain a pipeline, there may have been a fork
  -- If this is one of the pipeline commands, we'll be exiting
  -- so check to see that we are still executing something.
  if not done and resultFile > 0 then                   -- redirecting?
     result := dup2( oldStandardOutput, stdout );       -- to original
     if result < 0 then                                 -- error?
        err( "unable to restore stdout: " & OSerror( C_errno ) );
     else                                               -- no error?
        currentStandardOutput := oldStandardOutput;     -- track fd
     end if;
     closeResult := close( resultFile );           -- reopen results
     -- close EINTR is a diagnostic message.  Do not handle.
     resultFile := open( to_string(resultName) & ASCII.NUL, O_RDONLY,
         8#644# );
     if resultFile < 0 then                                -- error?
        err( "unable to open temp file for reading: " &
           OSError( C_errno ));
     else
        loop                                               -- for all results
<<reread>>
          readchar( chars, resultFile, ch, 1 );            -- slow (one char)
          if chars = 0 then                                -- read none?
             exit;                                         --   done
 -- KB: 2012/02/15: see spar_os-tty for an explaination of this kludge
          elsif chars not in 0..Interfaces.C.size_t'Last-1 then
             if C_errno = EAGAIN or C_errno = EINTR then   -- retry?
                goto reread;                               -- do so
             end if;                                       -- other error?
             err( "unable to read results: " & OSError( C_errno ) );
             exit;                                         --  and bail
          end if;
          results := results & ch;                         -- add to results
        end loop;
        closeResult := close( resultFile );            -- close and delete
        -- close EINTR is a diagnostic message.  Do not handle.
     end if;
     unlinkResult := unlink( to_string( resultName ) & ASCII.NUL );
     if unlinkResult < 0 then                              -- unable to delete?
        err( "unable to unlink temp file: " & OSError( C_errno ) );
     end if;
     if length( results ) > 0 then                         -- discard last EOL
        if element( results, length( results ) ) = ASCII.LF then
           delete( results, length( results ), length( results ) );
           if length( results ) > 0 then  -- MS-DOS
              if element( results, length( results ) ) = ASCII.CR then
                 delete( results, length( results ), length( results ) );
              end if;
           end if;
        end if;
     end if;
  -- elsif not syntax_check then                              --
  --    close( resultFile );
  end if;                                                  -- still executing
  restoreScript( scriptState );                            -- original script
end RunAndCaptureOutput;

-----------------------------------------------------------------------------
-- COMPILE RUN AND CAPTURE OUTPUT
--
-- Compile commands, run the commands and return the results.  If first
-- line number is supplied, it will be used for the first line number of
-- the commands (as opposed to line 1).
-----------------------------------------------------------------------------

procedure CompileRunAndCaptureOutput( commands : unbounded_string; results : out
  unbounded_string; firstLineNo : natural := 1  ) is
  byteCode : unbounded_string;
  scriptState : aScriptState;
begin
  saveScript( scriptState );               -- save current script
  compileCommand( commands, firstLineNo );
  byteCode := to_unbounded_string( script.all );
  if not error_found then
     RunAndCaptureOutput( byteCode, results, fragment => false );
  end if;
  restoreScript( scriptState );            -- restore original script
end CompileRunAndCaptureOutput;

procedure ParseStep is
-- debugger: step one instruction forward.  Do this by activating SIGINT
begin
  expect( step_t );
  if inputMode /= breakout then
     err( "step can only be used when you break out of a script" );
  else
     done := true;
     breakoutContinue := true;
     stepFlag1 := true;
     put_trace( "stepping" );
  end if;
end ParseStep;

procedure ParseReturn is
  -- Syntax: return [function-result-expr]
  -- Return from a subprogram or quit interactive session or resume from a
  -- breakout.
  expr_val    : unbounded_string;
  expr_type   : identifier;
  return_id   : identifier;
  must_return : boolean;
  has_when    : boolean := false;
begin
  -- Return has a special meaning in interactive modes
  if inputMode = breakout then
     expect( return_t );
     expectSemicolon;
     done := true;
     breakoutContinue := true;
     syntax_check := true;
     put_trace( "returning to script" );
  elsif inputMode = interactive then
     if isLoginShell then
        err( "warning: This is a login shell.  Use " &
             optional_bold( "logout" ) & " to quit." );
     else
        expect( return_t );
        expectSemicolon;
        if isExecutingCommand then
           DoQuit;
        end if;
     end if;
  else

     -- Return statement in a procedure or function

     expect( return_t );

     if token /= eof_t and token /= when_t and not (token = symbol_t and identifiers( token ).value.all = ";") and not (token = symbol_t and identifiers( token ).value.all = "|" ) then

        -- Handle a function return value
        --
        -- The return value gets assigned even if an optional when clause
        -- follows and indicates the return does not happen.

        if isExecutingCommand then
           -- return value only exists at run-time.  There are better ways to
           -- do this.
           findIdent( to_unbounded_string( "return value" ), return_id );
           if return_id = eof_t then
              err( "procedures cannot return a value" );
           else
           -- at this point, we don't know the function id.  Maybe we can
           -- check the block name and derrive it that way.  Until we do,
           -- no type checking on the function result!
              ParseExpression( expr_val, expr_type );
              identifiers( return_id ).value.all := expr_val;
              if trace then
                 put_trace( "returning """ & to_string( expr_val ) & """" );
              end if;
           end if;
        else
              -- for syntax checking, we need to walk the expression
              ParseExpression( expr_val, expr_type );
        end if;
     end if;

     -- Handle option when expression.

     if token = when_t or token = if_t then     -- if to give "expected when"
        has_when := true;
        ParseWhenClause( must_return );
     else
         must_return := true;
     end if;

     -- Check for semi-colon and

     expectSemicolon;
     if syntax_check then
        -- this marks a function return has having been seen for checks on
        -- a function with no return.
        sawReturn;
        -- look for unreachable code only during syntax check
        -- does not apply if there's a when clause
        if not has_when then
           -- these are block ending tokens
           if token /= eof_t and token /= end_t and token /= elsif_t and
              token /= else_t and token /= when_t and token /= others_t and
              token /= exception_t then
                 err( "unreachable code" );
           end if;
        end if;
     end if;

     -- Execute a return.  Trigger skipping block and exiting.

     if isExecutingCommand then
        if must_return then
           DoReturn;
        end if;
     end if;
  end if;
end ParseReturn;

procedure ParseAssignment is
  -- Basic variable assignment
  -- Syntax: var := expression or array(index) := expr
  var_id     : identifier;
  var_kind   : identifier;
  expr_value : unbounded_string;
  right_type : identifier;
  index_value: unbounded_string;
  index_kind : identifier;
  -- array_id   : arrayID;
  arrayIndex : long_integer;
begin
  -- Get the variable to assign to.  If interactive, consider
  -- auto-declarations.
  if inputMode = interactive or inputMode = breakout then
    if identifiers( token ).kind = new_t and not onlyAda95 and not restriction_no_auto_declarations then
       ParseNewIdentifier( var_id );
       if token = symbol_t and identifiers( token ).value.all = "(" then
          err( "cannot automatically declare new arrays" );
          discardUnusedIdentifier( var_id );
          var_id := eof_t;
       end if;
    else
       ParseIdentifier( var_id );
    end if;
  else
    ParseIdentifier( var_id );
  end if;

  -- Copy the type for convenience

  var_kind := identifiers( var_id ).kind;

  -- Setup itself

  itself := identifiers( var_id ).value.all;
  itself_type := var_kind;

  -- Handle usage qualifiers (record fields)
  --
  -- At a debug breakout prompt, constant and limited assignment is permitted
  -- with a warning to the user.
  --
  -- Record fields are a little complicated.  As record are collections of
  -- variables, check both the parent record of the file and that record's
  -- type to see if it is constant or limited.  If so, treat the field as
  -- constant or limited.

  if class_ok( var_id, varClass ) then

     -- field of a record?

     if identifiers( var_id ).field_of /= eof_t then

        -- check the usage qualifier of the parent

        case identifiers( identifiers( var_id ).field_of ).usage is
        when abstractUsage =>
           err( "internal error: variables should not have abstract types" );
        when limitedUsage =>
           if inputMode = breakout then
              put_trace( "Warning: assigning a new value to a limited record field" );
           else
              err( "limited record fields cannot be assigned a value" );
           end if;
        when constantUsage =>
           if inputMode = breakout then
              put_trace( "Warning: assigning a new value to a constant record field" );
           else
              err( "constant record fields cannot be assigned a value" );
           end if;
        when fullUsage =>

        -- check the usage qualifier of the parent's type

           case identifiers(
                 identifiers (
                     identifiers( var_id ).field_of
                 ).kind
              ).usage is
           when abstractUsage =>
              null; -- don't bother checking
           when limitedUsage =>
              if inputMode = breakout then
                 put_trace( "Warning: assigning a new value to a limited record field" );
              else
                 err( "limited record fields cannot be assigned a value" );
              end if;
           when constantUsage =>
              if inputMode = breakout then
                 put_trace( "Warning: assigning a new value to a constant record field" );
              else
                 err( "constant record fields cannot be assigned a value" );
              end if;
           when fullUsage =>
              null;
           when others =>
              err( "internal error: unexpected usage qualifier" );
           end case;

        when others =>
           err( "internal error: unexpected usage qualifier " &
              identifiers( identifiers( var_id ).field_of ).usage'img );
        end case;

     end if;

     -- Handle usage qualifiers
     --
     -- Check everything here. Including record fields that passed the parent
     -- record tests.

     case identifiers( var_id ).usage is

     when abstractUsage =>
        err( "internal error: variables should not be abstract" );

     when limitedUsage =>
        if inputMode = breakout then
           put_trace( "Warning: assigning a new value to a limited variable" );
        else
           err( "limited variables cannot be assigned a value" );
        end if;

     when constantUsage =>
        if inputMode = breakout then
           put_trace( "Warning: assigning a new value to a constant variable" );
        else
           err( "constant variables cannot be assigned a value" );
        end if;

     when fullUsage =>
        null;

     when others =>
        err( "internal error: unexpected usage qualifier " & identifiers( var_id ).usage'img );
     end case;
  end if;

  -- Handle aggregate type assignment checks
  -- TODO: this will break when we can create derived record types

  if var_kind = root_record_t then
     err( "cannot assign to an entire record" );
  -- Array element
  elsif identifiers( var_id ).list then
     expect( symbol_t, "(" );
     ParseExpression( index_value, index_kind );
     if getUniType( index_kind ) = uni_string_t or identifiers( index_kind ).list then
        err( "scalar expression expected" );
     end if;

     expect( symbol_t, ")" );

     if isExecutingCommand then
        arrayIndex := long_integer( to_numeric( index_value ) );
        if identifiers( var_id ).avalue = null then
           err( gnat.source_info.source_location & ": internal error: target array storage unexpectedly null" );
        elsif identifiers( var_id ).avalue'first > arrayIndex then -- DEBUG
           err( "array index " & to_string( trim( index_value, ada.strings.both ) ) & " not in" & identifiers( var_id ).avalue'first'img & " .." & identifiers( var_id ).avalue'last'img );
        elsif identifiers( var_id ).avalue'last < arrayIndex then
           err( "array index " &  to_string( trim( index_value, ada.strings.both ) ) & " not in" & identifiers( var_id ).avalue'first'img & " .." & identifiers( var_id ).avalue'last'img );
        end if;
     end if;
     var_kind := identifiers( var_kind ).kind; -- array of what?
  end if;

  ParseAssignPart( expr_value, right_type );

  if inputMode = interactive or inputMode = breakout then
     if identifiers( var_id ).kind = new_t and not onlyAda95 and not restriction_no_auto_declarations and not error_found then
        if index( identifiers( var_id ).name, "." ) /= 0 then
           err( "Identifier not declared.  Cannot auto-declare a record field" );
        else
           var_kind := right_type;
           identifiers( var_id ).kind := right_type;
           identifiers( var_id ).class := varClass;
           put_trace( "Assuming " & to_string( identifiers( var_id ).name ) &
              " is a new " & to_string( identifiers( right_type ).name ) &
              " variable" );
        end if;
      end if;
  end if;

  -- Type testing and casting

  -- try to assign an exception to a universal type.  We need to flag that as
  -- a special case
  if right_type = exception_t then
     err( "exceptions cannot be assigned" );
  elsif baseTypesOk( var_kind, right_type ) then
     if isExecutingCommand then
        expr_value := castToType( expr_value, var_kind );
     end if;
  end if;

  -- Before assignment, remember that this identifier was written to
  -- by the assignment for later identifier usage checks.  If this is
  -- the field of the record, mark the whole record as being written
  -- to.  Otherwise, mark just the identifier.
  -- Check for error in case var_id is eof_t.
  --
  -- A variable that is assigned a value cannot be limited, so
  -- treat it as if it was a factor.

  if syntax_check and then not error_found then
     if identifiers( var_id ).field_of /= eof_t then
        identifiers( identifiers( var_id ).field_of ).wasWritten := true;
        identifiers( identifiers( var_id ).field_of ).wasFactor := true;
     else
        identifiers( var_id ).wasWritten := true;
        identifiers( var_id ).wasFactor := true;
     end if;
  end if;

  if isExecutingCommand then

     -- Programming-by-contract

     DoContracts( identifiers( var_id ).kind, expr_value );

     if identifiers( var_id ).list then
        --mem_id := long_integer( to_numeric( identifiers( var_id ).value ) );
        --arrayIndex := long_integer( to_numeric( index_value ) );
        --if not inBounds( array_id, arrayIndex ) then
        --   err( "exception raised" );
        --else
           -- assignElement( array_id, arrayIndex, expr_value );
        begin
           -- KB: 16/10/02: these appear to be checked above
           --if identifiers( var_id ).avalue = null then
           --   err( gnat.source_info.source_location & ": internal error: target array storage unexpectedly null" );
           --elsif identifiers( var_id ).avalue'first > arrayIndex then -- DEBUG, this should never happen, checked above
           --   err( gnat.source_info.source_location & ": internal error: array index out of bounds " & identifiers( var_id ).avalue'first'img & " .. " & identifiers( var_id ).avalue'last'img );
           --elsif identifiers( var_id ).avalue'last < arrayIndex then
           --   err( gnat.source_info.source_location & ": internal error: array index out of bounds " & identifiers( var_id ).avalue'first'img & " .. " & identifiers( var_id ).avalue'last'img );
           --elsif not error_found then
           identifiers( var_id ).avalue( arrayIndex ) := expr_value; -- NEWARRAY
           --end if;
        exception when CONSTRAINT_ERROR =>
          err( "constraint_error : index out of range " & identifiers( var_id ).avalue'first'img & " .." & identifiers( var_id ).avalue'last'img );
        when STORAGE_ERROR =>
          err( gnat.source_info.source_location & ": internal error : storage error raised in ParseAssignment" );
        end;
        if trace then
           put_trace(
              to_string( identifiers( var_id ).name ) &
              "(" &
              to_string( index_value ) &
              ")" &
              " := """ &
              to_string( ToEscaped( expr_value ) ) &
                 """" );
        end if;
     else
        identifiers( var_id ).value.all := expr_value;
        if trace then
           -- builtins.env( ident ) would be better if a value is
           -- returned
           put_trace(
              to_string( identifiers( var_id ).name ) &
              " := """ &
              to_string( ToEscaped( expr_value ) ) &
              """" );
        end if;
    end if;
  end if;
  itself_type := new_t;
end ParseAssignment;

procedure ParseVarDeclaration is
  -- Basic variable declaration
  -- Syntax: var [,var2 ...] declaration_part
  -- Array variables can only be declared one-at-a-time
  var_id  : identifier;
  var2_id : identifier;
  name    : unbounded_string;
  multi   : boolean := false;
  b       : boolean;
begin
   ParseNewIdentifier( var_id );
   if token = symbol_t and identifiers( token ).value.all = "," then
      expect( symbol_t, "," );
      var2_id := token;
      pragma warnings( off ); -- hide infinite recursion warning
      ParseVarDeclaration;
      multi := true;
      pragma warnings( on );
      if error_found then
         discardUnusedIdentifier( var_id );
      else
         if identifiers( var2_id ).list then
            err( "multiple arrays cannot be declared in one declaration" );
            -- because only the array is assigned values with :=
            -- unless I want to copy all the array elements everytime.
            -- Also, can't overwrite array ident value field.
            b := deleteIdent( var2_id );
         else
            -- OK so far? copy declaration leftward through variable list

            name := identifiers( var_id ).name;
            -- Because var is now a pointer, we cannot simply assign
            -- identifiers to each other...the pointers will be wrong.
            -- identifiers( var_id ) := identifiers( var2_id );
            -- identifiers( var_id ).name := name;
            copyValue( var_id, var2_id );

            -- Record type?  Must create fields.

            if identifiers( getBaseType( identifiers( var_id ).kind ) ).kind = root_record_t then  -- record type?
-- put_line( "Recursing for " & identifiers( var_id ).name );
-- put_token;
               ParseRecordDeclaration( var_id, identifiers( var_id ).kind, canAssign => false );
               -- copy values for fields
               declare
                 numFields : natural;
                 source_id, target_id : identifier;
               begin
                 numFields := natural( to_numeric( identifiers( identifiers( var_id ).kind ).value.all ) );
-- put_line( "Copying " & numFields'img );
                 for i in 1..numFields loop
                     findField( var_id, i, source_id );
                     findField( var2_id, i, target_id );
                     identifiers( source_id ).value.all := identifiers( target_id ).value.all;
                 end loop;
               end;
           end if;

         end if;
      end if;
      return;
   end if;
   ParseDeclarationPart( var_id, anon_arrays => true, exceptions => true ); -- var id may change...won't effect next stmt
   if error_found then
      discardUnusedIdentifier( var_id );
   end if;
end ParseVarDeclaration;

procedure ParseGeneralStatement is
  -- Syntax: env-cmd | clear-cmd | ...
  expr_value : unbounded_string;
  --expr_type  : identifier;
  cmdStart   : aScannerState;
  must_exit  : boolean;
  eof_flag   : boolean := false;
  term_id    : identifier;
  startToken : identifier;
  itself_question : boolean;
begin

  -- mark start of line (prior to breakout test which will change token
  -- to eof )

  startToken := Token;
  markScanner( cmdStart );

  -- interrupt handling

  if stepFlag1 then
     stepFlag1 := false;
     stepFlag2 := true;
  elsif stepFlag2 then
     stepFlag2 := false;
     wasSIGINT := true;
  end if;
  if wasSIGINT then                                      -- control-c?
     if inputMode = interactive or inputMode = breakout then -- interactive?
        wasSIGINT := false;                              -- just ignore
     elsif not breakoutOpt then                          -- no breakouts?
        wasSIGINT := false;                              -- clear flag
        DoQuit;                                          -- stop BUSH
     else                                                -- running script?
        for i in 1..identifiers_top-1 loop
            if identifiers( i ).inspect then
               Put_Identifier( i );
            end if;
        end loop;
        err( optional_inverse( "Break: return to continue, logout to quit" ) ); -- show stop posn
     end if;
  elsif wasSIGWINCH then                                 -- window change?
     findIdent( to_unbounded_string( "TERM" ), term_id );
     checkDisplay( identifiers( term_id ).value.all );       -- adjust size
     wasSIGWINCH := false;
  end if;

  -- Parse the general statement
  --
  -- built-in?

  itself := identifiers( token ).value.all;
  itself_type := token;
  itself_question := false;

-- put( "PGS: " ); -- DEBUG
-- put_token; -- DEBUG

  if Token = command_t then
     err( "Bourne shell command command not implemented" );
     --getNextToken;
     --ParseShellCommand;
  elsif identifiers( token ).procCB /= null then  -- built-in proc w/cb?
     identifiers( token ).procCB.all;             -- call the callback
  elsif Token = typeset_t then
     ParseTypeSet;
  elsif Token = pragma_t then
     ParsePragma;
  elsif Token = type_t then
     ParseType;
  elsif Token = null_t then
     getNextToken;
  elsif Token = subtype_t then
     ParseSubtype;
  elsif Token = if_t then
     ParseIfBlock;
  elsif Token = case_t then
     ParseCaseBlock;
  elsif Token = while_t then
     ParseWhileBlock;
  elsif Token = for_t then
     ParseForBlock;
  elsif Token = loop_t then
     ParseLoopBlock;
  elsif Token = return_t then
     ParseReturn;
     return;
  elsif Token = step_t then
     ParseStep;
  elsif token = logout_t then
     --if not isLoginShell and inputMode /= interactive and inputMode /= breakout then
     -- ^--not as restrictive
     if not isLoginShell and inputMode /= breakout then
        err( "warning: this is not a login shell: use " & optional_bold( "return" ) &
             " to quit" );
     end if;
     getNextToken;
     expectSemicolon;
     if not error_found or inputMode = breakout then
        DoQuit;
     end if;
     return;
  elsif Token = create_t then
     ParseOpen( create => true );
  elsif Token = open_t then
     ParseOpen;
  --elsif Token = close_t then
  --   ParseClose;
  --elsif Token = put_line_t then
  --   ParsePutLine;
  elsif token = symbol_t and identifiers( token ).value.all = "?" then
     -- To implement "itself" with the "?" is difficult because
     -- "?" is a symbol and "@" is a symbol, so trying to look
     -- up the symbol value to determine if is "?" is not possible.
     -- So we flag this as a special case.
     itself_question := true;
     ParseQuestion;
  elsif Token = reset_t then
     ParseReset;
  elsif Token = delete_t then                     -- special case
     getNextToken;                                -- with possibilities
     if token = symbol_t and identifiers( token ).value.all = "(" then
        resumeScanning( cmdStart );
        ParseDelete;                              -- delete file
     else
        discardUnusedIdentifier( token );
        resumeScanning( cmdStart );
        ParseShellCommand;                        -- SQL delete
     end if;
  elsif Token = delay_t then
     ParseDelay;
  elsif token = pen_set_font_t then                -- Pen.Set_Font
     ParsePenSetFont;
  elsif token = pen_put_t then                     -- Pen.Put
     ParsePenPut;
  elsif Token = else_t then
     err( "else without if" );
  elsif Token = elsif_t then
     err( "elsif without if" );
  elsif Token = with_t then
     err( "with only allowed in declaration section or before main program" );
  elsif Token = use_t then
     err( "use not implemented" );
  elsif Token = task_t then
     err( "tasks not implemented" );
  elsif Token = protected_t then
     err( "protected types not implemented" );
  elsif Token = package_t then
     err( "packages not implemented" );
  elsif Token = raise_t then
     ParseRaise;
     if syntax_check then
        -- this is a bit slow but it's only during a syntax check
        declare
          atSemicolon : aScannerState;
        begin
          markScanner( atSemicolon );
          getNextToken; -- skip semicolon
          -- eof_t because a raise might be the last line in a simple script
          if token /= end_t and token /= exception_t and token /= when_t and token /= else_t and token /= elsif_t and token /= eof_t then
             err( "unreachable code" );
          end if;
          resumeScanning( atSemicolon ); -- restore original position
        end;
     end if;
  elsif Token = exit_t then
     if blocks_top = block'first then           -- not complete. should check
         err( "no enclosing loop to exit" );    -- not just for no blocks
     end if;                                    -- but the block type isn't easily checked
     expect( exit_t );
     if token = when_t or token = if_t then     -- if to give "expected when"
        ParseWhenClause( must_exit );
     else
        -- check for unreachable code on a stand-alone exit
        if syntax_check then
           if token = symbol_t and identifiers( token ).value.all = ";" then
              -- we need to advance one to hilight the right token
              getNextToken;
              -- these are block ending tokens
              if token /= eof_t and token /= end_t and token /= elsif_t and
                 token /= else_t and token /= when_t and token /= others_t and
                 token /= exception_t then
                 err( "unreachable code" );
              end if;
              resumeScanning( cmdStart ); -- restore original position
              getNextToken;
           end if;
        end if;
        must_exit := true;
     end if;
     if isExecutingCommand and must_exit then
        exit_block := true;
        if trace then
           put_trace( "exiting" );
        end if;
     end if;
  elsif Token = declare_t then
     ParseDeclareBlock;
  elsif Token = begin_t then
     ParseBeginBlock;
  elsif token = word_t then
     -- discardUnusedIdentifier( token );
     resumeScanning( cmdStart );
     ParseShellCommand;
  elsif token = backlit_t then
     err( "unexpected backquote literal" );
  elsif token = procedure_t then
     err( "declare procedures in declaration sections" );
  elsif token = function_t then
     err( "declare functions in declaration sections" );
  elsif Token = eof_t then
     eof_flag := true;
     -- a script could be a single comment without a ;
  elsif Token = symbol_t and identifiers( token ).value.all = "@" then
     err( "unexpeced @.  Itself can appear after a command or pragma (and no preceding semi-colon) or in an assignment expression" );
           getNextToken;
  elsif Token = symbol_t and identifiers( token ).value.all = ";" then
     err( "statement expected" );
  elsif not identifiers( Token ).deleted and identifiers( Token ).list then     -- array variable
     resumeScanning( cmdStart );           -- assume array assignment
     ParseAssignment;                      -- looks like a AdaScript command
     itself_type := new_t;                 -- except for token type...
  elsif not identifiers( Token ).deleted and identifiers( token ).class = userProcClass then
     DoUserDefinedProcedure( identifiers( token ).value.all );
  else

     -- we need to check the next token then back up
     -- should really change scanner to double symbol look ahead?

     getNextToken;

     -- declarations

     if Token = symbol_t and
        (to_string( identifiers( token ).value.all ) = ":" or
        to_string( identifiers( token ).value.all ) = ",") then
        resumeScanning( cmdStart );
        ParseVarDeclaration;
     else

        -- assignments
        --
        -- for =, will be treated as a command if we don't force an error
        -- here for missing :=, since it was probably intended as an assignment

        if Token = symbol_t and to_string( identifiers( token ).value.all ) = "=" then
           expect( symbol_t, ":=" );
        elsif Token = symbol_t and to_string( identifiers( token ).value.all ) = ":=" then
           resumeScanning( cmdStart );
           ParseAssignment;
           itself_type := new_t;

        -- Boolean true shortcut (boolean assertions)
        -- new_t check because a command will produce an varClass with no type
        elsif identifiers( startToken ).class = varClass and then identifiers( startToken ).kind /= new_t and then getBaseType( identifiers( startToken ).kind ) = boolean_t and then not identifiers( startToken ).deleted then
           if onlyAda95 then
              err( "use " & optional_bold( ":= true " ) & " with " & optional_bold( "pragma ada_95" ) );
           end if;
           if syntax_check and then not error_found then
              identifiers( startToken ).wasWritten := true;
           end if;
           if isExecutingCommand then
              identifiers( startToken ).value.all := to_unbounded_string( "1" );
           end if;
           --if Token = symbol_t and to_string( identifiers( token ).value ) = ";" then
           --end if;
        else

           -- assume it's a shell command and run it
           -- current token is first "token" of parameter.  Blow it away
           -- if able (ie. "ls file", current token is file but we don't
           -- need that in our identifier list.)

           discardUnusedIdentifier( token );
           resumeScanning( cmdStart );
           ParseShellCommand;
        end if;
     end if;
  end if;

  if not eof_flag then
     -- itself?
     -- procedure with no parameters can be interpreted as shell words by the
     -- compiler because it doesn't know if something is a procedure or an
     -- external command at compile time.
     if ( token = symbol_t or token = word_t ) and identifiers( token ).value.all = "@" then
        if onlyAda95 then
           err( "@ is not allowed with " & optional_bold( "pragma ada_95" ) );
           -- move to next token or inifinite loop if done = true
           getNextToken;
        elsif itself_type = new_t then
           err( "@ is not defined" );
           getNextToken;
        -- shell commands have no class so we can't do this (without
        -- changes, anyway...)
        --elsif class_ok( itself_type, procClass ) then -- lift this?
        else
           token := itself_type;
           -- question is a special case.  See ParseQuestion call above.
           if itself_question then
              itself_question := false;
              identifiers( token ).value.all := to_unbounded_string( "?" );
           end if;
           if identifiers( token ).class = varClass then
              -- not a procedure or keyword? restore value
              identifiers( token ).value.all := itself;
           end if;
        end if;
     else
        itself_type := new_t;
        -- interactive?
        if inputMode = interactive or inputMode = breakout then
           if token = eof_t then
              err( "';' expected. Possibly hidden by a comment or unescaped '--'" );
           end if;
        end if;
        expectSemicolon;
     end if;
  end if;

  -- breakout handling
  --
  -- Breakout to a prompt if there was an error and --break is used.
  -- Don't break out if syntax checking or the error was caused while
  -- in the break out command prompt.

  if error_found and then boolean(breakoutOpt) then
     if not syntax_check and inputMode /= breakout then
     declare                                          -- we need to save
        saveMode    : anInputMode := inputMode;       -- BUSH's state
        scriptState : aScriptState;                   -- current script
     begin
        wasSIGINT := false;                            -- clear sig flag
        saveScript( scriptState );                     -- save position
        error_found := false;                          -- not a real error
        script := null;                                -- no script to run
        inputMode := breakout;                         -- now interactive
        interactiveSession;                            -- command prompt
        restoreScript( scriptState );                  -- restore original script
        if breakoutContinue then                       -- continuing execution?
           resumeScanning( cmdStart );                 -- start of command
           err( optional_inverse( "resuming here" ) ); -- redisplay line
           done := false;                              --   clear logout flag
           error_found := false;                       -- not a real error
           exit_block := false;                        --   and don't exit
           syntax_check := false;
           breakoutContinue := false;                  --   we handled it
        end if;
        inputMode := saveMode;                         -- restore BUSH's
        resumeScanning( cmdStart );                    --   overwrite EOF token
     end;
     end if;
  end if;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
  token := eof_t; -- this exception cannot be handled
  done := true;   -- abort
when block_table_overflow =>
  err( optional_inverse( "too many nested statements/blocks (block table overflow)" ) );
  token := eof_t; -- this exception cannot be handled
  done := true;
end ParseGeneralStatement;


------------------------------------------------------------------------------
-- PARSE POLICY
--
-- Parse a policy block.  This contains pragmas, static if, static case or
-- null.
-- Ada: N/A
-- Syntax: policy p is .. end c;
------------------------------------------------------------------------------

procedure parsePolicy is
  policy_id : identifier;
begin
  expect( policy_t );
  ParseNewIdentifier( policy_id );
  if identifiers( policy_id ).kind = new_t then
     identifiers( policy_id ).class := policyClass;
     identifiers( policy_id ).kind := policy_t;
  end if;
  expect( is_t );
  while (not error_found and not done) loop
     if token = pragma_t then
        ParsePragma;
        expectSemicolon;
     elsif token = if_t then
        ParseStaticIfBlock;
        expectSemicolon;
     elsif token = case_t then
        ParseStaticCaseBlock;
        expectSemicolon;
     elsif token = null_t then
        expect( null_t );
        expectSemicolon;
     else
        exit;
     end if;
  end loop;
  expect( end_t );
  expect( policy_id );
end parsePolicy;


------------------------------------------------------------------------------
-- PARSE CONFIG
--
-- Parse a configuration block.  The block contains declarations only.
-- Ada: N/A
-- Syntax: configuration c is .. end c;
------------------------------------------------------------------------------

procedure parseConfig is
  config_id : identifier;
begin
  expect( configuration_t );
  ParseNewIdentifier( config_id );
  if identifiers( config_id ).kind = new_t then
     identifiers( config_id ).class := configurationClass;
     identifiers( config_id ).kind := configuration_t;
  end if;
  expect( is_t );
  if not error_found and not done then -- this if is probably redundant
     ParseDeclarations;
  end if;
  expect( end_t );
  expect( config_id );
end parseConfig;


------------------------------------------------------------------------------
-- PARSE MAIN PROGRAM
------------------------------------------------------------------------------

procedure ParseMainProgram is
  program_id : identifier;
begin
  expect( procedure_t );
  ParseNewIdentifier( program_id );
  -- style check: no dangerous program names
  if syntax_check then
     if index( confusingprogram_words, to_string( " " & identifiers( program_id ).name & " " ) ) > 0 then
        err( "style issue: " & optional_bold( to_string( identifiers( program_id ).name ) ) & " is a built-in command in some shells" );
     end if;
  end if;
  identifiers( program_id ).kind := identifiers'first;
  identifiers( program_id ).class := mainProgramClass;
  if syntax_check then
     identifiers( program_id ).wasReferenced := true;
  end if;
  pushBlock( newScope => true,
    newName => to_string (identifiers( program_id ).name ) );
  -- Note: pushBlock must be before "is" (single symbol look-ahead)
  expect( is_t );
  ParseDeclarations;
  expect( begin_t );
  ParseBlock;

  if token = exception_t then
     ParseExceptionHandler( false );
  end if;
  -- If we are processing a web template, we can't pull the block because it
  -- would destroy the global variables used by the template.
  if not hasTemplate then
     pullBlock;
  end if;
  expect( end_t );
  expect( program_id );
end ParseMainProgram;

------------------------------------------------------------------------------
-- PARSE
--
-- Initiate parsing a compiled set of AdaScript commands.  The commands should
-- have been compiled by interpretCommands or interpretScript.  This subprogram
-- doesn't compile byte code.  error_found will be true if the commands failed
-- because of errors.
------------------------------------------------------------------------------

procedure parse is
begin
  if not error_found then
     cmdpos := firstScriptCommandOffset;
     token := identifiers'first;                -- dummy, replaced by g_n_t
     getNextToken;                              -- load first token

     -- Expect some actual source code, at least token, for running.

     if token = eof_t then
        err( "there were no commands to run" );
     end if;

     -- Prior to a main program (or a simple script), a script may have
     -- pragmas, policies, configurations, withs, trace.  A procedure
     -- is a main program.  Otherwise, skip all this and drop down to the
     -- simple script handling.

     while (not error_found and not done) and (
       token = procedure_t or
       token = pragma_t or
       token = policy_t or
       token = with_t or
       token = configuration_t or
       token = trace_t ) loop
        if token = pragma_t then
           ParsePragma;
           expectSemicolon;
        elsif token = policy_t then
           ParsePolicy;
           expectSemicolon;
        elsif token = configuration_t then
           ParseConfig;
           expectSemicolon;
        elsif token = procedure_t then
           ParseMainProgram;
           expectSemicolon;
           expect( eof_t );                        -- should be nothing else
           exit;
        elsif token = with_t then                  -- with before main pgm
           -- load the include file, parse the header
           ParseWith;
        elsif token = trace_t then
           ParseShellCommand;
           expectSemicolon;
        end if;
     end loop;

     -- If we're not done, then there's no main program and it's a simple
     -- script with general statements.
     --
     -- If there was a main program, we should be at EOF so this section
     -- should not run

     -- TODO: if there was a main program, none of this is done
     -- so I should clean this up to make that obvious.  This also allows
     -- simple scripts to follow the main program??
     --if not done or token = eof_t then
     if not done and token /= eof_t then
        loop
          ParseGeneralStatement;                   -- process the first statement
          exit when done or token = eof_t;         -- continue until done
        end loop;                                  --  or eof hit
        if not done then                           -- not exiting?
           expect( eof_t );                        -- should be nothing else
        end if;
        -- no blocks to pull, but we can still check requirements
        if syntax_check then
           checkIdentifiersForSimpleScripts;
           completeSoftwareModelRequirements;
        end if;
     end if;
  end if;
end parse;


------------------------------------------------------------------------------
-- PARSE NEW COMMANDS
--
-- Switch to a new set of commands.  This is used for user-defined procedures,
-- functions and back quoted commands.  It is up to the caller to restore the
-- scanner state.
------------------------------------------------------------------------------

procedure parseNewCommands( scriptState : out aScriptState; byteCode : unbounded_string; fragment : boolean := true ) is
begin
  saveScript( scriptState );                -- save current script
  if fragment then                          -- a fragment of byte code?
     replaceScriptWithFragment( byteCode ); -- install proc as script
  else                                      -- otherwise a complete script?
     replaceScript( byteCode );             -- install proc as script
  end if;
  --put_line( toEscaped( to_unbounded_string( script.all ) ) ); -- DEBUG
  inputMode := fromScriptFile;             -- running a script
  error_found := false;                    -- no error found
  exit_block := false;                     -- not exit-ing a block
  cmdpos := firstScriptCommandOffset;      -- start at first char
  token := identifiers'first;              -- dummy, replaced by g_n_t
  getNextToken;                            -- load first token
end parseNewCommands;


---------------------------------------------------------
-- END OF ADASCRIPT PARSER
---------------------------------------------------------


------------------------------------------------------------------------------
-- Housekeeping
------------------------------------------------------------------------------


--  START PARSER
--
-- Startup this package, performing any set up tasks.  In this case, none.
------------------------------------------------------------------------------

procedure startParser is
begin
  null;
end startParser;


--  SHUTDOWN PARSER
--
-- Shut down this package, performing any cleanup tasks.  In this case, none.
------------------------------------------------------------------------------

procedure shutdownParser is
begin
  null;
end shutdownParser;

end parser;