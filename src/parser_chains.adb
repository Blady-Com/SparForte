------------------------------------------------------------------------------
-- Chains Package Parser                                                    --
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
-- This is maintained at http://www.sparforte.com                           --
--                                                                          --
------------------------------------------------------------------------------

--with text_io;use text_io;

with
    ada.strings.unbounded,
    gnat.source_info,
    world,
    symbol_table,
    message_strings,
    value_conversion,
    scanner,
    scanner.communications,
    chain_util;
use
    ada.strings.unbounded,
    world,
    symbol_table,
    message_strings,
    value_conversion,
    scanner,
    scanner.communications,
    chain_util;

package body parser_chains is

------------------------------------------------------------------------------
-- chain package identifiers
------------------------------------------------------------------------------

chain_context_t         : identifier;
chains_context_first_t  : identifier;
chains_context_middle_t : identifier;
chains_context_last_t   : identifier;
chains_context_not_in_chain_t : identifier;

chains_in_chain_t       : identifier;
chains_chain_context_t  : identifier;
chains_chain_count_t    : identifier;

-----------------------------------------------------------------------------
--  PARSE IN CHAIN                                        (built-in function)
--
-- AdaScript Syntax: s := chains.in_chain
--       Ada Target: N/A
--   GNAT Spec File: N/A
--   SparForte Docs: doc/pkg_chains#in_chain
-----------------------------------------------------------------------------

procedure ParseChainsInChain( result : out storage; kind : out identifier ) is
begin
  kind := boolean_t;
  expect( chains_in_chain_t );
  if isExecutingCommand then
     result := storage'( to_spar_boolean( in_chain /= none ), noMetaTag, sparMetaTags );
  end if;
end ParseChainsInChain;

-----------------------------------------------------------------------------
--  PARSE CHAIN CONTEXT                                   (built-in function)
--
-- AdaScript Syntax: s := chains.chain_context
--       Ada Target: N/A
--   GNAT Spec File: N/A
--   SparForte Docs: doc/pkg_chains#chain_context
-----------------------------------------------------------------------------

procedure ParseChainsChainContext( result : out storage; kind : out identifier ) is
  subprogramId : identifier := chains_chain_context_t;
begin
  kind := chain_context_t;
  expect( chains_chain_context_t );
  if isExecutingCommand then
     if in_chain = none then
        result := storage'( to_unbounded_string( "3" ), noMetaTag, sparMetaTags );
     else
        case chain_context is
        when first =>
           result := storage'( to_unbounded_string( "0" ), noMetaTag, sparMetaTags );
        when middle =>
            result := storage'( to_unbounded_string( "1" ), noMetaTag, sparMetaTags );
        when last =>
           result := storage'( to_unbounded_string( "2" ), noMetaTag, sparMetaTags );
        when others =>
          err( contextNotes => pl( "At " & gnat.source_info.source_location &
                                   " while in " ) &
                                   em( to_string( identifiers( subprogramId ).name ) ),
               subjectNotes => subjectInterpreter,
               reason => +"had an internal error because ",
               obstructorNotes => em( "an unexpected chain context " & chain_context'img )
             );
        end case;
     end if;
  end if;
end ParseChainsChainContext;

-----------------------------------------------------------------------------
--  PARSE CHAIN COUNT                                     (built-in function)
--
-- AdaScript Syntax: s := chains.chain_count
--       Ada Target: N/A
--   GNAT Spec File: N/A
--   SparForte Docs: doc/pkg_chains#chain_context
-----------------------------------------------------------------------------

procedure ParseChainsChainCount( result : out storage; kind : out identifier ) is
  chain_count_id : identifier;
  subprogramId : identifier := chains_chain_count_t;
begin
  kind := positive_t;
  result := storage'( to_unbounded_string( "0" ), noMetaTag, sparMetaTags );
  expect( subprogramId );
  if isExecutingCommand then
     if in_chain = none then
       err(
            context=> subprogramId,
            subjectNotes => subjectProgram,
            reason => +"is not in a chain",
            obstructorNotes => nullMessageStrings
          );
     else
       findIdent( chain_count_str, chain_count_id );
       if chain_count_id /= eof_t then -- this should never happen
          result.value := identifiers( chain_count_id ).store.value;
       end if;
     end if;
  end if;
end ParseChainsChainCount;


------------------------------------------------------------------------------
-- Housekeeping
------------------------------------------------------------------------------


procedure StartupChains is
begin
  declareNamespace( "chains" );
  declareIdent( chain_context_t, "chains.context", root_enumerated_t, typeClass );
  declareStandardConstant( chains_context_first_t, "chains.context_first", chain_context_t, "0" );
  declareStandardConstant( chains_context_middle_t, "chains.context_middle", chain_context_t, "1" );
  declareStandardConstant( chains_context_last_t, "chains.context_last", chain_context_t, "2" );
  declareStandardConstant( chains_context_not_in_chain_t, "chains.not_in_chain", chain_context_t, "3" );

  declareFunction( chains_in_chain_t, "chains.in_chain", ParseChainsInChain'access );
  declareFunction( chains_chain_context_t, "chains.chain_context", ParseChainsChainContext'access );
  declareFunction( chains_chain_count_t, "chains.chain_count", ParseChainsChainCount'access );
  declareNamespaceClosed( "chains" );
end StartupChains;

procedure ShutdownChains is
begin
  null;
end ShutdownChains;

end parser_chains;
