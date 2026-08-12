------------------------------------------------------------------------------
-- GNAT CRC32 Package Parser                                                --
--                                                                          --
-- Part of SparForte                                                        --
------------------------------------------------------------------------------
--                                                                          --
--              Copyright (C) 2001-2026 Free Software Foundation            --
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

-- with ada.text_io; use ada.text_io;

with interfaces,
    gnat.crc32,
    ada.strings.unbounded,
    pegasoft,
    world,
    symbol_table,
    scanner,
    scanner.communications,
    parser,
    parser_params;
use ada.strings.unbounded,
    pegasoft,
    world,
    symbol_table,
    scanner,
    scanner.communications,
    parser,
    parser_params;

package body parser_gnat_crc is

------------------------------------------------------------------------------
-- GNAT CRC32 package identifiers
------------------------------------------------------------------------------

gnat_crc32_crc32_t : identifier;

gnat_crc32_initialize_t : identifier;
gnat_crc32_update_t : identifier;
gnat_crc32_get_value_t : identifier;

------------------------------------------------------------------------------
-- PARSE THE GNAT CRC32 PACKAGE
------------------------------------------------------------------------------

-----------------------------------------------------------------------------
--  PARSE GNAT CRC32 INITIALIZE                          (built-in procedure)
--
-- AdaScript Syntax: gnat.crc32.initialize( crc32 )
--       Ada Target: GNAT.CRC32.Initialize
--   GNAT Spec File: g-crc32.ads
--   SparForte Docs: doc/pkg_gnat_crc.html#gnat.crc32.initialize
-----------------------------------------------------------------------------

procedure ParseGnatCRC32Initialize is
  record_ref : reference;
  subprogramId : constant identifier := gnat_crc32_initialize_t;
begin
  expect( subprogramId );
  ParseSingleOutParameter( subprogramId, record_ref, gnat_crc32_crc32_t );

  if isExecutingCommand then
     declare
       c : Gnat.CRC32.CRC32;
     begin
       Gnat.CRC32.Initialize( C );
       AssignParameter( record_ref,
          storage'( to_unbounded_string( numericValue( C ) ), noMetaTag, sparMetaTags )
       );
     exception when others =>
       err_exception_raised;
     end;
  end if;
end ParseGnatCRC32Initialize;

-----------------------------------------------------------------------------
--  PARSE GNAT CRC32 UPDATE                              (built-in procedure)
--
-- AdaScript Syntax: gnat.crc32.update( crc32 )
--       Ada Target: GNAT.CRC32.Initialize
--   GNAT Spec File: g-crc32.ads
--   SparForte Docs: doc/pkg_gnat_crc.html#gnat.crc32.initialize
-----------------------------------------------------------------------------

procedure ParseGnatCRC32Update is
  --var_id  : identifier;
  expr  : storage;
  expr_type : identifier;
  crc_ref : reference;
  crc     : storage;
  subprogramId : constant identifier := gnat_crc32_update_t;
begin
  expect( subprogramId );
  expect( symbol_t, "(" );
  ParseInOutParameter( subprogramId, crc_ref, gnat_crc32_crc32_t );
  expectParameterComma;
  ParseExpression( expr, expr_type );
  if uniTypesOk( expr_type, uni_string_t ) then
     expect( symbol_t, ")" );
  end if;

  if isExecutingCommand then
     getParameterValue( crc_ref, crc );
     if metaTagOk( gnat_crc32_update_t, crc ) then
        declare
          c : Gnat.CRC32.CRC32 := Gnat.CRC32.CRC32'value( to_string(
              crc.value ) );
        begin
          Gnat.CRC32.Update( C, to_string( expr.value ) );
          AssignParameter( crc_ref,
             storage'( to_unbounded_string( numericValue( C ) ), noMetaTag, sparMetaTags )
          );
        exception when others =>
          err_exception_raised;
        end;
     end if;
  end if;
end ParseGnatCRC32Update;

-----------------------------------------------------------------------------
--  PARSE GNAT CRC32 GET VALUE                            (built-in function)
--
-- AdaScript Syntax: integer := gnat.crc32.get_value( crc32 )
--       Ada Target: GNAT.CRC32.Get_Value
--   GNAT Spec File: g-crc32.ads
--   SparForte Docs: doc/pkg_gnat_crc.html#gnat.crc32.initialize
--
-- Ada uses an unsigned integer but in SparForte we're using a signed integer.
-- The Ada documentation is unclear as it states that the crc
-- parameter does not get changed by get value.
-----------------------------------------------------------------------------

procedure ParseGnatCRC32GetValue( result : out storage; kind : out identifier ) is
  crc_ref : reference;
  crc     : storage;
  tmp     : Interfaces.Unsigned_32;
  subprogramId : constant identifier := gnat_crc32_get_value_t;
begin
  kind := integer_t;
  expect( subprogramId );
  expect( symbol_t, "(" );
  ParseInOutParameter( subprogramId, crc_ref, gnat_crc32_crc32_t );
  expect( symbol_t, ")" );

  if isExecutingCommand then
     getParameterValue( crc_ref, crc );
     if metaTagOk( subprogramId, crc ) then
        declare
          c : Gnat.CRC32.CRC32 := Gnat.CRC32.CRC32'value( to_string(
              crc.value ) );
        begin
          tmp := GNAT.CRC32.Get_Value( c );
          result := storage'( to_unbounded_string( numericValue( tmp ) ), crc.unitMetaTag, crc.policyMetaTags );
        exception when others =>
          err_exception_raised;
        end;
     end if;
  end if;
end ParseGnatCRC32GetValue;


------------------------------------------------------------------------------
-- HOUSEKEEPING
------------------------------------------------------------------------------

procedure StartupGnatCRC is
begin
  declareNamespace( "gnat.crc32" );
  declareIdent( gnat_crc32_crc32_t, "gnat.crc32.crc32", uni_numeric_t, typeClass );
  identifiers( gnat_crc32_crc32_t ).usage := limitedUsage;
  declareProcedure( gnat_crc32_initialize_t, "gnat.crc32.initialize", ParseGnatCRC32Initialize'access );
  declareProcedure( gnat_crc32_update_t, "gnat.crc32.update", ParseGnatCRC32Update'access );
  declareFunction( gnat_crc32_get_value_t, "gnat.crc32.get_value",ParseGnatCRC32GetValue'access );
  declareNamespaceClosed( "gnat.crc32" );
end StartupGnatCRC;

procedure ShutdownGnatCRC is
begin
  null;
end ShutdownGnatCRC;

end parser_gnat_crc;
