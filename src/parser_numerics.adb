------------------------------------------------------------------------------
-- Numerics Package Parser                                                  --
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

--with ada.text_io; use ada.text_io;

with ada.numerics.float_random,
    ada.strings,
    interfaces,
    gnat.sha1,
    gnat.sha224,
    gnat.sha256,
    gnat.sha512,
    --pegasoft.user_io,
    pegasoft.numerics,
    symbol_table,
    message_strings,
    value_conversion,
    scanner,
    scanner.communications,
    parser_params,
    parser,
    md5;
use interfaces,
    pegasoft,
    --pegasoft.user_io,
    pegasoft.numerics,
    pegasoft.numerics.elementary_functions,
    pegasoft.numerics.complex_types,
    symbol_table,
    message_strings,
    value_conversion,
    scanner,
    scanner.communications,
    parser_params,
    parser,
    md5;

package body parser_numerics is

serialNumber : numericValue := 0.0;

------------------------------------------------------------------------------
-- Numerics package identifiers
------------------------------------------------------------------------------

numerics_e_t : identifier;  -- numerics constants
numerics_log2_e_t : identifier;
numerics_log10_e_t : identifier;
numerics_ln10_t : identifier;
numerics_ln2_t : identifier;
numerics_pi_t : identifier;
numerics_pi_by_2_t : identifier;
numerics_pi_by_4_t : identifier;
numerics_pi_under_1_t : identifier;
numerics_pi_under_2_t : identifier;
numerics_sqrt_pi_under_2_t : identifier;
numerics_sqrt_2_t : identifier;
numerics_sqrt_2_under_1_t : identifier;

random_t       : identifier;      -- built-in ada.numerics.float_random.random
shift_left_t   : identifier;      -- Interfaces.shift_left
shift_right_t  : identifier;      -- Interfaces.shift_right
rotate_left_t  : identifier;      -- Interfaces.rotate_left
rotate_right_t : identifier;      -- Interfaces.rotate_right
shift_right_arith_t : identifier; -- Interfaces.shift_right_arithmetic
sqrt_t       : identifier; -- ada.numerics.long_elementary_functions
log_t        : identifier;
exp_t        : identifier;
sin_t        : identifier;
cos_t        : identifier;
tan_t        : identifier;
cot_t        : identifier;
arcsin_t     : identifier;
arccos_t     : identifier;
arctan_t     : identifier;
arccot_t     : identifier;
sinh_t       : identifier;
cosh_t       : identifier;
tanh_t       : identifier;
coth_t       : identifier;
arcsinh_t    : identifier;
arccosh_t    : identifier;
arctanh_t    : identifier;
arccoth_t    : identifier;
floor_t      : identifier;  -- numeric attributes
ceiling_t    : identifier;
rounding_t : identifier;
unbiased_rounding_t : identifier;
truncation_t : identifier;
remainder_t  : identifier;
exponent_t   : identifier;
fraction_t   : identifier;
leading_part_t : identifier;
copy_sign_t  : identifier;
max_t        : identifier;
min_t        : identifier;
machine_t    : identifier;
scaling_t    : identifier;
value_t      : identifier;
pos_t        : identifier;
sturges_t    : identifier;    -- other
numerics_md5_t : identifier;
serial_t     : identifier;
rnd_t        : identifier;
odd_t        : identifier;
even_t       : identifier;
numerics_re_t : identifier;
numerics_im_t : identifier;
numerics_set_re_t : identifier;
numerics_set_im_t : identifier;
numerics_argument_t : identifier;
numerics_modulus_t : identifier;
hash_of_t         : identifier;
sdbm_hash_of_t    : identifier;
fnv_hash_of_t     : identifier;
murmur_hash_of_t  : identifier;
sha1_digest_of_t   : identifier;
sha224_digest_of_t : identifier;
sha256_digest_of_t : identifier;
sha512_digest_of_t : identifier;
shannon_entropy_of_t : identifier;



-----------------------------------------------------------------------------

--discard_result : boolean;

-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
--  PARSE NUMERICS RANDOM                                 (built-in function)
--
-- AdaScript Syntax: f := numerics.random
--       Ada Target: Ada.Numerics.Float_Random.Random
--   GNAT Spec File: a-nuflra.ads
--   SparForte Docs: pkg_numerics.html#numerics.random
-----------------------------------------------------------------------------

procedure ParseNumericsRandom( result : out storage; kind : out identifier ) is
  subprogramId : constant identifier := random_t;
begin
  kind := float_t;
  result := nullStorage;
  expect( subprogramId );
  if isExecutingCommand then
     result.value := to_unbounded_string( numericValue( Ada.Numerics.Float_Random.Random(
       random_generator ) ) );
     result.unitMetaTag := noMetaTag;
     result.policyMetaTags := sparMetaTags;
  end if;
end ParseNumericsRandom;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SHIFT LEFT                             (built-in function)
--
-- AdaScript Syntax: i := numerics.shift_left( e, b )
--       Ada Target: Interfaces.Shift_Left
--   GNAT Spec File: interfac.ads
--   SparForte Docs: pkg_numerics.html#numerics.shift_left
-----------------------------------------------------------------------------

procedure ParseNumericsShiftLeft( result : out storage; kind : out identifier ) is
  expr_st   : storage;
  expr_type : identifier;
  amt_st    : storage;
  amt_type  : identifier := eof_t;
  subprogramId : constant identifier := shift_left_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, amt_st, amt_type, natural_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'( to_unbounded_string( numericValue( shift_left(
              unsigned_64( to_numeric( expr_st.value ) ),
              natural( to_numeric( amt_st.value ) )
           ) ) ), noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsShiftLeft;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SHIFT RIGHT                            (built-in function)
--
-- AdaScript Syntax: i := numerics.shift_right( e, b )
--       Ada Target: Interfaces.Shift_Right
--   GNAT Spec File: interfac.ads
--   SparForte Docs: pkg_numerics.html#numerics.shift_right
-----------------------------------------------------------------------------

procedure ParseNumericsShiftRight( result : out storage; kind : out identifier ) is
  expr_st   : storage;
  expr_type : identifier;
  amt_st    : storage;
  amt_type  : identifier := eof_t;
  subprogramId : constant identifier := shift_right_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, amt_st, amt_type, natural_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'( to_unbounded_string( numericValue( shift_right(
              unsigned_64( to_numeric( expr_st.value ) ),
              natural( to_numeric( amt_st.value ) )
           ) ) ), noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsShiftRight;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ROTATE LEFT                            (built-in function)
--
-- AdaScript Syntax: i := numerics.rotate_left( e, b )
--       Ada Target: Interfaces.Rotate_Left
--   GNAT Spec File: interfac.ads
--   SparForte Docs: pkg_numerics.html#numerics.rotate_left
-----------------------------------------------------------------------------

procedure ParseNumericsRotateLeft( result : out storage; kind : out identifier ) is
  expr_st   : storage;
  expr_type : identifier;
  amt_st    : storage;
  amt_type  : identifier := eof_t;
  subprogramId : constant identifier := rotate_left_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, amt_st, amt_type, natural_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'( to_unbounded_string( numericValue( rotate_left(
              unsigned_64( to_numeric( expr_st.value ) ),
              natural( to_numeric( amt_st.value) )
           ) ) ), noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsRotateLeft;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ROTATE RIGHT                           (built-in function)
--
-- AdaScript Syntax: i := numerics.rotate_right( e, b )
--       Ada Target: Interfaces.Rotate_Right
--   GNAT Spec File: interfac.ads
--   SparForte Docs: pkg_numerics.html#numerics.rotate_right
-----------------------------------------------------------------------------

procedure ParseNumericsRotateRight( result : out storage; kind : out identifier ) is
  expr_st   : storage;
  expr_type : identifier;
  amt_st    : storage;
  amt_type  : identifier := eof_t;
  subprogramId : constant identifier := rotate_right_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, amt_st, amt_type, natural_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'( to_unbounded_string( numericValue( rotate_right(
              unsigned_64( to_numeric( expr_st.value ) ),
              natural( to_numeric( amt_st.value) )
           ) ) ), noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsRotateRight;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SHIFT RIGHT ARITHMETIC                 (built-in function)
--
-- AdaScript Syntax: i := numerics.shift_right_arithmetic( x, b )
--       Ada Target: Interfaces.Shift_Right_Arithmetic
--   GNAT Spec File: interfac.ads
--   SparForte Docs: pkg_numerics.html#numerics.shift_right_arithmetic
-----------------------------------------------------------------------------

procedure ParseNumericsASR( result : out storage; kind : out identifier ) is
  -- Syntax: numerics.shift_right_arithmetic( x, b )
  -- Source: Interfaces
  expr_st   : storage;
  expr_type : identifier;
  amt_st    : storage;
  amt_type  : identifier := eof_t;
  subprogramId : constant identifier := shift_right_arith_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, amt_st, amt_type, natural_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'(to_unbounded_string( numericValue( shift_right_arithmetic(
              unsigned_64( to_numeric( expr_st.value ) ),
              natural( to_numeric( amt_st.value ) )
           ) ) ), noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsASR;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SQRT                                   (built-in function)
--
-- AdaScript Syntax: f := numerics.sqrt( e )
--       Ada Target: Ada.Numerics.Long_Elementary_Functions.Sqrt
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.sqrt
-----------------------------------------------------------------------------

procedure ParseNumericsSqrt( result : out storage; kind : out identifier ) is
  expr_st   : storage;
  expr_type : identifier;
  subprogramId : constant identifier := sqrt_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'( to_unbounded_string( sqrt( to_numeric( expr_st.value ) ) ),
              noMetaTag, expr_st.policyMetaTags );
        end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsSqrt;

-----------------------------------------------------------------------------
--  PARSE NUMERICS LOG                                    (built-in function)
--
-- AdaScript Syntax: f := numerics.log( e [,b] )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Log
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.log
-----------------------------------------------------------------------------

procedure ParseNumericsLog( result : out storage; kind : out identifier ) is
  expr_st   : storage;
  expr_type : identifier;
  base_st   : storage;
  base_type : identifier := eof_t;
  subprogramId : constant identifier := log_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  if token = symbol_t and identifiers( token ).store.value = "," then
     ParseLastNumericParameter( subprogramId, base_st, base_type );
  else
     expect( symbol_t, ")" );
  end if;
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           if base_type = eof_t then
              result := storage'( to_unbounded_string( log( to_numeric( expr_st.value ) ) ),
                noMetaTag, expr_st.policyMetaTags );
           else
              result := storage'( to_unbounded_string( log( to_numeric( expr_st.value ),
                to_numeric( base_st.value ) ) ), noMetaTag, expr_st.policyMetaTags );
           end if;
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsLog;

-----------------------------------------------------------------------------
--  PARSE NUMERICS EXP                                    (built-in function)
--
-- AdaScript Syntax: f := numerics.exp( x )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Exp
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.exp
-----------------------------------------------------------------------------

procedure ParseNumericsExp( result : out storage; kind : out identifier ) is
  expr_st   : storage;
  expr_type : identifier;
  subprogramId : constant identifier := exp_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'( to_unbounded_string( exp( to_numeric( expr_st.value) ) ),
              noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when constraint_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the expression value" ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"is out-of-range",
          obstructorNotes => nullMessageStrings
     );
  when others =>
     err_exception_raised;
  end;
end ParseNumericsExp;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SIN                                    (built-in function)
--
-- AdaScript Syntax: f := numerics.sin( e [,cycle] )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Sin
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.sin
-----------------------------------------------------------------------------

procedure ParseNumericsSin( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  cycle_st   : storage;
  cycle_type : identifier := eof_t;
  subprogramId : constant identifier := sin_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  if token = symbol_t and identifiers( token ).store.value = "," then
     ParseLastNumericParameter( subprogramId, cycle_st, cycle_type );
  else
     expect( symbol_t, ")" );
  end if;
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           if cycle_type = eof_t then
              result := storage'(to_unbounded_string( sin( to_numeric( expr_st.value ) ) ),
                 noMetaTag, expr_st.policyMetaTags );
           else
              result := storage'( to_unbounded_string( sin( to_numeric( expr_st.value ),
                to_numeric( cycle_st.value ) ) ), noMetaTag, expr_st.policyMetaTags );
           end if;
        end if;
     end if;
  exception when ada.numerics.argument_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the cycle value" ) & em_value( cycle_st.value ),
          subjectType => cycle_type,
          reason  => +"should be greater than zero because",
          obstructorNotes => pl( "argument error was raised" )
     );
  when others =>
     err_exception_raised;
  end;
end ParseNumericsSin;

-----------------------------------------------------------------------------
--  PARSE NUMERICS COS                                    (built-in function)
--
-- AdaScript Syntax: f := numerics.cos( e [,cycle] )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Cos
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.cos
-----------------------------------------------------------------------------

procedure ParseNumericsCos( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  cycle_st   : storage;
  cycle_type : identifier := eof_t;
  subprogramId : constant identifier := cos_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  if token = symbol_t and identifiers( token ).store.value = "," then
     ParseLastNumericParameter( subprogramId, cycle_st, cycle_type );
  else
     expect( symbol_t, ")" );
  end if;
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          if cycle_type = eof_t then
             result := storage'( to_unbounded_string( cos( to_numeric( expr_st.value ) ) ),
                noMetaTag, expr_st.policyMetaTags );
          else
             result := storage'( to_unbounded_string( cos( to_numeric( expr_st.value ),
                to_numeric( cycle_st.value ) ) ), noMetaTag, expr_st.policyMetaTags );
          end if;
       end if;
    end if;
  exception when ada.numerics.argument_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the cycle value" ) & em_value( cycle_st.value ),
          subjectType => cycle_type,
          reason  => +"should be greater than zero because",
          obstructorNotes => pl( "argument error was raised" )
     );
  when others =>
     err_exception_raised;
  end;
end ParseNumericsCos;

-----------------------------------------------------------------------------
--  PARSE NUMERICS TAN                                    (built-in function)
--
-- AdaScript Syntax: f := numerics.tan( e [,cycle] )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Tan
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.tan
-----------------------------------------------------------------------------

procedure ParseNumericsTan( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  cycle_st   : storage;
  cycle_type : identifier := eof_t;
  subprogramId : constant identifier := tan_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  if token = symbol_t and identifiers( token ).store.value = "," then
     ParseLastNumericParameter( subprogramId, cycle_st, cycle_type );
  else
     expect( symbol_t, ")" );
  end if;
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          if cycle_type = eof_t then
             result := storage'( to_unbounded_string( tan( to_numeric( expr_st.value ) ) ),
                noMetaTag, expr_st.policyMetaTags );
          else
             result := storage'( to_unbounded_string( tan( to_numeric( expr_st.value ),
               to_numeric( cycle_st.value ) ) ), noMetaTag, expr_st.policyMetaTags );
          end if;
       end if;
    end if;
  exception when ada.numerics.argument_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the cycle value" ) & em_value( cycle_st.value ),
          subjectType => cycle_type,
          reason  => +"should be greater than zero because",
          obstructorNotes => pl( "argument error was raised" )
     );
  when constraint_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the expression value" ) & em_value( expr_st.value ),
          subjectType => cycle_type,
          reason  => +"is an odd multiple of the quarter cycle or an overflow occurred because",
          obstructorNotes => pl( "constraint error was raised" )
     );
  when others =>
     err_exception_raised;
  end;
end ParseNumericsTan;

-----------------------------------------------------------------------------
--  PARSE NUMERICS COT                                    (built-in function)
--
-- AdaScript Syntax: f := numerics.cot( e )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Cot
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.cot
-----------------------------------------------------------------------------

procedure ParseNumericsCot( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  cycle_st   : storage;
  cycle_type : identifier := eof_t;
  subprogramId : constant identifier := cot_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  if token = symbol_t and identifiers( token ).store.value = "," then
     ParseLastNumericParameter( subprogramId, cycle_st, cycle_type );
  else
     expect( symbol_t, ")" );
  end if;
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          if cycle_type = eof_t then
             result := storage'( to_unbounded_string( cot( to_numeric( expr_st.value ) ) ),
                noMetaTag, expr_st.policyMetaTags );
          else
             result := storage'( to_unbounded_string( cot( to_numeric( expr_st.value ),
               to_numeric( cycle_st.value ) ) ), noMetaTag, expr_st.policyMetaTags );
          end if;
       end if;
    end if;
  exception when ada.numerics.argument_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the cycle value" ) & em_value( cycle_st.value ),
          subjectType => cycle_type,
          reason  => +"should be greater than zero because",
          obstructorNotes => pl( "argument error was raised" )
     );
  when constraint_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the expression value" ) & em_value( expr_st.value ),
          subjectType => cycle_type,
          reason  => +"is zero or an multiple of the half cycle or an overflow occurred because",
          obstructorNotes => pl( "constraint error was raised" )
     );
  when others =>
     err_exception_raised;
  end;
end ParseNumericsCot;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ARCSIN                                 (built-in function)
--
-- AdaScript Syntax: f := numerics.arcsin( e [,cycle] )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Arcsin
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.arcsin
-----------------------------------------------------------------------------

procedure ParseNumericsArcSin( result : out storage; kind : out identifier ) is
  expr_st   : storage;
  expr_type   : identifier;
  cycle_st   : storage;
  cycle_type : identifier := eof_t;
  subprogramId : constant identifier := arcsin_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  if token = symbol_t and identifiers( token ).store.value = "," then
     ParseLastNumericParameter( subprogramId, cycle_st, cycle_type );
  else
     expect( symbol_t, ")" );
  end if;
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          if cycle_type = eof_t then
             result := storage'( to_unbounded_string( arcsin( to_numeric( expr_st.value ) ) ),
                noMetaTag, expr_st.policyMetaTags );
          else
             result := storage'( to_unbounded_string( arcsin( to_numeric( expr_st.value),
               to_numeric( cycle_st.value ) ) ), noMetaTag, expr_st.policyMetaTags );
          end if;
       end if;
    end if;
  exception when ada.numerics.argument_error =>
     if to_numeric( cycle_st.value ) <= 0.0 then
        err( context => subprogramId,
          subjectNotes => pl( "the cycle value" ) & em_value( cycle_st.value ),
          subjectType => cycle_type,
          reason  => +"should be greater than zero because",
          obstructorNotes => pl( "argument error was raised" )
        );
     else
        err( context => subprogramId,
          subjectNotes => pl( "the expression value" ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"should be in the range -1..1 or an overflow occurred because",
          obstructorNotes => pl( "argument error was raised" )
        );
     end if;
  when others =>
     err_exception_raised;
  end;
end ParseNumericsArcSin;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ARCCOS                                 (built-in function)
--
-- AdaScript Syntax: f := numerics.arccos( x [,cycle] )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Arccos
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.arccos
-----------------------------------------------------------------------------

procedure ParseNumericsArcCos( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  cycle_st   : storage;
  cycle_type : identifier := eof_t;
  subprogramId : constant identifier := arccos_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  if token = symbol_t and identifiers( token ).store.value = "," then
     ParseLastNumericParameter( subprogramId, cycle_st, cycle_type );
  else
     expect( symbol_t, ")" );
  end if;
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          if cycle_type = eof_t then
             result := storage'( to_unbounded_string( arccos( to_numeric( expr_st.value ) ) ),
                noMetaTag, expr_st.policyMetaTags );
          else
             result := storage'( to_unbounded_string( arccos( to_numeric( expr_st.value ),
               to_numeric( cycle_st.value ) ) ), noMetaTag, expr_st.policyMetaTags );
          end if;
       end if;
    end if;
  exception when ada.numerics.argument_error =>
     if to_numeric( cycle_st.value ) <= 0.0 then
        err( context => subprogramId,
          subjectNotes => pl( "the cycle value" ) & em_value( cycle_st.value ),
          subjectType => cycle_type,
          reason  => +"should be greater than zero because",
          obstructorNotes => pl( "argument error was raised" )
        );
     else
        err( context => subprogramId,
          subjectNotes => pl( "the expression value" ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"should be in the range -1..1 or an overflow occurred because",
          obstructorNotes => pl( "argument error was raised" )
        );
     end if;
  when others =>
     err_exception_raised;
  end;
end ParseNumericsArcCos;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ARCTAN                                 (built-in function)
--
-- AdaScript Syntax: f := numerics.arctan( x, y [,cycle] )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Arctan
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.arctan
-- note: second parameter is not optional in mine but is in Ada
-----------------------------------------------------------------------------

procedure ParseNumericsArcTan( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  expr2_st   : storage;
  expr2_type : identifier;
  cycle_st   : storage;
  cycle_type : identifier := eof_t;
  subprogramId : constant identifier := arctan_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseNextNumericParameter( subprogramId, expr2_st, expr2_type );
  if token = symbol_t and identifiers( token ).store.value = "," then
     ParseLastNumericParameter( subprogramId, cycle_st, cycle_type );
  else
     expect( symbol_t, ")" );
  end if;
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st, expr2_st ) then
          if cycle_type = eof_t then
             result := storage'( to_unbounded_string( arctan( to_numeric( expr_st.value ),
               to_numeric( expr2_st.value ) ) ),
               noMetaTag,
               resolveEffectiveMetaTags( expr_type, expr_st, expr2_st ) );
          else
             result := storage'( to_unbounded_string( arctan( to_numeric( expr_st.value ),
               to_numeric( expr2_st.value ), to_numeric( cycle_st.value ) ) ),
               noMetaTag,
               resolveEffectiveMetaTags( expr_type, expr_st, expr2_st ) );
          end if;
       end if;
    end if;
  exception when ada.numerics.argument_error =>
        err( context => subprogramId,
          subjectNotes => pl( "the expression value " ) & em_value( expr_st.value ) &
            pl( " and " ) & em_value( expr2_st.value ),
          subjectType => expr_type,
          reason  => +"both cannot be zero because",
          obstructorNotes => pl( "argument_error was raised" )
        );
  when constraint_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the expression value " ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"cannot be 1 or -1 or an overflow occurred because",
          obstructorNotes => pl( "constraint_error was raised" )
     );
  when others =>
     err_exception_raised;
  end;
end ParseNumericsArcTan;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ARCCOT                                 (built-in function)
--
-- AdaScript Syntax: f := numerics.arccot( x, y [,cycle] )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Arccot
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.arccot
--
-- note: second parameter is not optional in mine but is in Ada
-----------------------------------------------------------------------------

procedure ParseNumericsArcCot( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  expr2_st   : storage;
  expr2_type : identifier;
  cycle_st   : storage;
  cycle_type : identifier := eof_t;
  subprogramId : constant identifier := arccot_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseNextNumericParameter( subprogramId, expr2_st, expr2_type );
  if token = symbol_t and identifiers( token ).store.value = "," then
     ParseLastNumericParameter( subprogramId, cycle_st, cycle_type );
  else
     expect( symbol_t, ")" );
  end if;
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st, expr2_st ) then
          if cycle_type = eof_t then
             result := storage'( to_unbounded_string( arccot( to_numeric( expr_st.value ),
               to_numeric( expr2_st.value ) ) ), noMetaTag, resolveEffectiveMetaTags( expr_type, expr_st, expr2_st ) );
          else
             result := storage'( to_unbounded_string( arccot( to_numeric( expr_st.value ),
               to_numeric( expr2_st.value ), to_numeric( cycle_st.value ) ) ),
               noMetaTag, resolveEffectiveMetaTags( expr_type, expr_st, expr2_st ) );
          end if;
       end if;
    end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsArcCot;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SINH                                   (built-in function)
--
-- AdaScript Syntax: f := numerics.sinh( e )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Sinh
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.sinh
-----------------------------------------------------------------------------

procedure ParseNumericsSinH( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := sinh_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( sinh( to_numeric( expr_st.value ) ) ),
              noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsSinH;

-----------------------------------------------------------------------------
--  PARSE NUMERICS COSH                                   (built-in function)
--
-- AdaScript Syntax: f := numerics.cosh( e )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Cosh
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.cosh
-----------------------------------------------------------------------------

procedure ParseNumericsCosH( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := cosh_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( cosh( to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsCosH;

-----------------------------------------------------------------------------
--  PARSE NUMERICS TANH                                   (built-in function)
--
-- AdaScript Syntax: f := numerics.tanh( e )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Tanh
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.tanh
-----------------------------------------------------------------------------

procedure ParseNumericsTanH( result : out storage; kind : out identifier ) is
  expr_st   : storage;
  expr_type : identifier;
  subprogramId : constant identifier := tanh_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( tanh( to_numeric( expr_st.value) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsTanH;

-----------------------------------------------------------------------------
--  PARSE NUMERICS COTH                                   (built-in function)
--
-- AdaScript Syntax: f := numerics.coth( e )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Coth
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.coth
-----------------------------------------------------------------------------

procedure ParseNumericsCoth( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := coth_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( coth(  to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when constraint_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the expression value " ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"cannot be zero or an overflow occurred because",
          obstructorNotes => pl( "constraint_error was raised" )
     );
  when others =>
    err_exception_raised;
  end;
end ParseNumericsCotH;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ARCSINH                                (built-in function)
--
-- AdaScript Syntax: f := numerics.arcsinh( e )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Arcsinh
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.arcsinh
-----------------------------------------------------------------------------

procedure ParseNumericsArcSinH( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := arcsinh_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( arcsinh( to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsArcSinH;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ARCCOSH                                (built-in function)
--
-- AdaScript Syntax: f := numerics.arccosh( e )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Arccosh
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.arccosh
-----------------------------------------------------------------------------

procedure ParseNumericsArcCosH( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := arccosh_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( arccosh( to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when ada.numerics.argument_error =>
        err( context => subprogramId,
          subjectNotes => pl( "the expression value " ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"is less than one because",
          obstructorNotes => pl( "argument_error was raised" )
        );
  when constraint_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the expression value " ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"cannot be one or an overflow occurred because",
          obstructorNotes => pl( "constraint_error was raised" )
     );
  when others =>
    err_exception_raised;
  end;
end ParseNumericsArcCosH;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ARCTANH                                (built-in function)
--
-- AdaScript Syntax: f := numerics.arctanh( e )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Arctanh
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.arctanh
-----------------------------------------------------------------------------

procedure ParseNumericsArcTanH( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := arctanh_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( arctanh( to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when ada.numerics.argument_error =>
        err( context => subprogramId,
          subjectNotes => pl( "the expression value " ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"should be in the range -1..1 because",
          obstructorNotes => pl( "argument_error was raised" )
        );
  when constraint_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the expression value " ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"cannot be one or an overflow occurred because",
          obstructorNotes => pl( "constraint_error was raised" )
     );
  when others =>
    err_exception_raised;
  end;
end ParseNumericsArcTanH;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ARCCOTH                                (built-in function)
--
-- AdaScript Syntax: f := numerics.arccoth( e )
--       Ada Target: Pegasoft.Numerics.Elementary_Functions.Arccoth
--   GNAT Spec File: a-ngelfu.ads
--   SparForte Docs: pkg_numerics.html#numerics.arccoth
-----------------------------------------------------------------------------

procedure ParseNumericsArcCotH( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := arccoth_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( arccoth( to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when ada.numerics.argument_error =>
        err( context => subprogramId,
          subjectNotes => pl( "the expression value " ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"is less than one because",
          obstructorNotes => pl( "argument_error was raised" )
        );
  when constraint_error =>
     err( context => subprogramId,
          subjectNotes => pl( "the expression value " ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"cannot be one or an overflow occurred because",
          obstructorNotes => pl( "constraint_error was raised" )
     );
  when others =>
    err_exception_raised;
  end;
end ParseNumericsArcCotH;

-----------------------------------------------------------------------------
--  PARSE NUMERICS FLOOR                                  (built-in function)
--
-- AdaScript Syntax: f := numerics.floor( e )
--       Ada Target: 'floor attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.floor
-----------------------------------------------------------------------------

procedure ParseNumericsFloor( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := floor_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( numericValue'floor( to_numeric( expr_st.value ) ) ),
            noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsFloor;

-----------------------------------------------------------------------------
--  PARSE NUMERICS CEILING                                (built-in function)
--
-- AdaScript Syntax: f := numerics.ceiling( e )
--       Ada Target: 'ceiling attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.ceiling
-----------------------------------------------------------------------------

procedure ParseNumericsCeiling( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := ceiling_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( numericValue'ceiling( to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsCeiling;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ROUNDING                               (built-in function)
--
-- AdaScript Syntax: f := numerics.rounding( e )
--       Ada Target: 'rounding attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.rounding
-----------------------------------------------------------------------------

procedure ParseNumericsRounding( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := rounding_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( numericValue'rounding( to_numeric( expr_st.value ) ) ),
          noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsRounding;

-----------------------------------------------------------------------------
--  PARSE NUMERICS UNBIASED ROUNDING                      (built-in function)
--
-- AdaScript Syntax: f := numerics.unbiased_rounding( e )
--       Ada Target: 'unbiased_rounding attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.unbiased_rounding
-----------------------------------------------------------------------------

procedure ParseNumericsUnbiasedRounding( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := unbiased_rounding_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( numericValue'unbiased_rounding( to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsUnbiasedRounding;

-----------------------------------------------------------------------------
--  PARSE NUMERICS TRUNCATION                             (built-in function)
--
-- AdaScript Syntax: f := numerics.truncation( e )
--       Ada Target: 'truncation attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.truncation
-----------------------------------------------------------------------------

procedure ParseNumericsTruncation( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := truncation_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
         result := storage'( to_unbounded_string( numericValue'truncation( to_numeric( expr_st.value ) ) ),
            noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsTruncation;

-----------------------------------------------------------------------------
--  PARSE NUMERICS REMAINDER                              (built-in function)
--
-- AdaScript Syntax: f := numerics.remainder( x, y )
--       Ada Target: 'remainder attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.remainder
-----------------------------------------------------------------------------

procedure ParseNumericsRemainder( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  expr2_st : storage;
  expr2_type : identifier;
  subprogramId : constant identifier := remainder_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type );
  begin
     if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) and metaTagOk( subprogramId, expr2_st )  then
          result := storage'( to_unbounded_string( numericValue'remainder( to_numeric( expr_st.value ),
            to_numeric( expr2_st.value ) ) ), noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsRemainder;

-----------------------------------------------------------------------------
--  PARSE NUMERICS EXPONENT                               (built-in function)
--
-- AdaScript Syntax: f := numerics.exponent( e )
--       Ada Target: 'exponent attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.exponent
-----------------------------------------------------------------------------

procedure ParseNumericsExponent( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := exponent_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( numericValue( numericValue'exponent( to_numeric( expr_st.value ) ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsExponent;

-----------------------------------------------------------------------------
--  PARSE NUMERICS FRACTION                               (built-in function)
--
-- AdaScript Syntax: f := numerics.fraction( e )
--       Ada Target: 'fraction attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.fraction
-----------------------------------------------------------------------------

procedure ParseNumericsFraction( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  subprogramId : constant identifier := fraction_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( numericValue'fraction( to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsFraction;

-----------------------------------------------------------------------------
--  PARSE NUMERICS LEADING PART                           (built-in function)
--
-- AdaScript Syntax: f := numerics.leading_part( x, y )
--       Ada Target: 'leading_part attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.leading_part
-----------------------------------------------------------------------------

procedure ParseNumericsLeadingPart( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  expr2_st : storage;
  expr2_type : identifier;
  subprogramId : constant identifier := leading_part_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type );
  begin
     if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) and metaTagOk( leading_part_t, expr2_st ) then
          result := storage'( to_unbounded_string( numericValue'leading_part( to_numeric( expr_st.value ),
             integer( to_numeric( expr2_st.value ) ) ) ), noMetaTag, expr_st.policyMetaTags );
       end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsLeadingPart;

-----------------------------------------------------------------------------
--  PARSE NUMERICS COPY SIGN                              (built-in function)
--
-- AdaScript Syntax: f := numerics.copy_sign( x, y )
--       Ada Target: 'copy_sign attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.copy_sign
-----------------------------------------------------------------------------

procedure ParseNumericsCopySign( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  expr2_st : storage;
  expr2_type : identifier;
  subprogramId : constant identifier := copy_sign_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type );
  begin
     if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st, expr2_st ) then
          result := storage'( to_unbounded_string( numericValue'copy_sign( to_numeric( expr_st.value ),
            to_numeric( expr2_st.value ) ) ), noMetaTag, resolveEffectiveMetaTags( kind, expr_st, expr2_st ) );
       end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsCopySign;

-----------------------------------------------------------------------------
--  PARSE NUMERICS STURGES                                (built-in function)
--
-- AdaScript Syntax: f := numerics.sturges( l, h, t )
--       Ada Target: N/A
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.sturges
-----------------------------------------------------------------------------

procedure ParseNumericsSturges( result : out storage; kind : out identifier ) is
  lo_st : storage;
  lo_type : identifier;
  hi_st : storage;
  hi_type : identifier;
  total_st : storage;
  total_type : identifier;
  lo, hi, total : numericValue;
  subprogramId : constant identifier := sturges_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, lo_st, lo_type );
  ParseNextNumericParameter( subprogramId, hi_st, hi_type );
  ParseLastNumericParameter( subprogramId, total_st, total_type );
  begin
     if isExecutingCommand then
       if metaTagOk( subprogramId, lo_st, hi_st, total_st ) then
          lo := to_numeric( lo_st.value );
          hi := to_numeric( hi_st.value );
          total := to_numeric( total_st.value );
          result := storage'( to_unbounded_string(
             numericValue'rounding(
                (hi-lo) / ( 1.0+log( total ) )
             )
          ), noMetaTag, resolveEffectiveMetaTags( kind, lo_st, hi_st, total_st ) );
       end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsSturges;

-----------------------------------------------------------------------------
--  PARSE NUMERICS MAX                                    (built-in function)
--
-- AdaScript Syntax: f := numerics.max( x, y )
--       Ada Target: 'max attribute'
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.max
-----------------------------------------------------------------------------

procedure ParseNumericsMax( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  expr2_st : storage;
  expr2_type : identifier;
  subprogramId : constant identifier := max_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type );
  begin
     if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st, expr2_st ) then
          result := storage'( to_unbounded_string( numericValue'max( to_numeric( expr_st.value ),
             to_numeric( expr2_st.value ) ) ), noMetaTag, resolveEffectiveMetaTags(kind, expr_st, expr2_st ) );
       end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsMax;

-----------------------------------------------------------------------------
--  PARSE NUMERICS MIN                                    (built-in function)
--
-- AdaScript Syntax: f := numerics.min( x, y )
--       Ada Target: 'min attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.min
-----------------------------------------------------------------------------

procedure ParseNumericsMin( result : out storage; kind : out identifier ) is
  expr_st : storage;
  expr_type : identifier;
  expr2_st : storage;
  expr2_type : identifier;
  subprogramId : constant identifier := min_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type );
  begin
     if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st, expr2_st ) then
          result := storage'( to_unbounded_string( numericValue'min( to_numeric( expr_st.value ),
             to_numeric( expr2_st.value ) ) ), noMetaTag, resolveEffectiveMetaTags(kind, expr_st, expr2_st ) );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsMin;

-----------------------------------------------------------------------------
--  PARSE NUMERICS MACHINE                                (built-in function)
--
-- AdaScript Syntax: f := numerics.machine( e )
--       Ada Target: 'machine attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.machine
-----------------------------------------------------------------------------

procedure ParseNumericsMachine( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  subprogramId : constant identifier := machine_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
    if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st ) then
          result := storage'( to_unbounded_string( numericValue'machine( to_numeric( expr_st.value ) ) ),
             noMetaTag, expr_st.policyMetaTags );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsMachine;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SCALING                                (built-in function)
--
-- AdaScript Syntax: f := numerics.scaling( x, y )
--       Ada Target: 'scaling attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.scaling
-----------------------------------------------------------------------------

procedure ParseNumericsScaling( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  expr2_st   : storage;
  expr2_type : identifier;
  subprogramId : constant identifier := scaling_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId,  expr_st, expr_type );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type, integer_t );
  begin
     if isExecutingCommand then
       if metaTagOk( subprogramId, expr_st, expr2_st ) then
          result := storage'( to_unbounded_string( numericValue'scaling( to_numeric( expr_st.value ),
            integer( to_numeric( expr2_st.value ) ) ) ),
            noMetaTag, resolveEffectiveMetaTags(kind, expr_st, expr2_st ) );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsScaling;

-----------------------------------------------------------------------------
--  PARSE NUMERICS VALUE                                  (built-in function)
--
-- AdaScript Syntax: f := numerics.value( s )
--       Ada Target: 'value attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.value
-----------------------------------------------------------------------------

procedure ParseNumericsValue( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  subprogramId : constant identifier := value_t;
begin
  kind := uni_numeric_t;
  expect( subprogramId );
  ParseSingleStringParameter( subprogramId, expr_st, expr_type, string_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           --result := trim( storage'( to_unbounded_string( to_numeric( expr_st.value ) ), left );
           result := storage'( to_unbounded_string( to_numeric( expr_st.value ) ),
              noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception
  when constraint_error =>
     err( context => subprogramId,
          subjectNotes => pl( qp( "the string value " ) ) & em_value( expr_st.value ),
          subjectType => expr_type,
          reason  => +"is not a valid number because",
          obstructorNotes => pl( "constraint_error was raised" )
     );
  when storage_error =>
     err( +"storage_error exception raised" );
  when ada.strings.index_error =>
     if expr_st.value = null_unbounded_string then
        err(
          context => subprogramId,
          subjectNotes => pl( qp( "the numeric value" ) ),
          reason => +"cannot be calculated on",
          obstructorNotes => +"an empty string"
        );
     else
        err(
          context => subprogramId,
          subjectNotes => pl( qp( "the numeric value" ) ),
          reason => +"raised a index_error on the string value",
          obstructorNotes => em_value( expr_st.value ),
          obstructortype => expr_type
        );
     end if;
  when others =>
     err_exception_raised;
  end;
end ParseNumericsValue;

-----------------------------------------------------------------------------
--  PARSE NUMERICS POS                                    (built-in function)
--
-- AdaScript Syntax: p := numerics.pos( c )
--       Ada Target: 'pos attribute
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.pos
-----------------------------------------------------------------------------

procedure ParseNumericsPos( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  subprogramId : constant identifier := pos_t;
begin
  kind := positive_t;
  expect( subprogramId );
  ParseSingleStringParameter( subprogramId, expr_st, expr_type, character_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'( to_unbounded_string( character'pos( Element( expr_st.value, 1 ) )'img ),
              noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsPos;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ABS                                    (built-in function)
--
-- AdaScript Syntax: p := abs( e )
--       Ada Target: abs
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#abs
-----------------------------------------------------------------------------

procedure ParseNumericsAbs( result : out storage ) is
  expr_st    : storage;
  expr_type  : identifier;
  subprogramId : constant identifier := abs_t;
begin
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'(
              to_unbounded_string( abs( to_numeric( expr_st.value ) ) ),
              noMetaTag, expr_st.policyMetaTags
           );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsAbs;

-----------------------------------------------------------------------------
--  PARSE NUMERICS MD5                                    (built-in function)
--
-- AdaScript Syntax: r := numerics.md5( s )
--       Ada Target: MD5.Disgest_To_Text
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.md5
-----------------------------------------------------------------------------

procedure ParseNumericsMd5( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  C          : Context;
  FP         : Fingerprint;
  subprogramId : constant identifier := numerics_md5_t;
begin
  kind := string_t;
  expect( subprogramId );
  ParseSingleStringParameter( subprogramId, expr_st, expr_type, string_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           Init( C );
          Update( C, to_string( expr_st.value ) );
          Final( C, FP );
          result := storage'( to_unbounded_string( Digest_To_Text( FP ) ),
             noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsMd5;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SERIAL                                 (built-in function)
--
-- AdaScript Syntax: f := numerics.serial
--       Ada Target: N/A
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.serial
-----------------------------------------------------------------------------

procedure ParseNumericsSerial( result : out storage; kind : out identifier ) is
  subprogramId : constant identifier := serial_t;
begin
  kind := natural_t;
  result := nullStorage;
  expect( subprogramId );
  if isExecutingCommand then
     result.value := to_unbounded_string( serialNumber );
     if serialNumber = maxInteger then
        serialNumber := 0.0;
     else
        serialNumber := serialNumber + 1.0;
     end if;
  end if;
end ParseNumericsSerial;

-----------------------------------------------------------------------------
--  PARSE NUMERICS RND                                    (built-in function)
--
-- AdaScript Syntax: r := numerics.rnd( p )
--       Ada Target: PegaSoft.Numerics.RND
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.rnd
-----------------------------------------------------------------------------

procedure ParseNumericsRnd( result : out storage; kind : out identifier ) is
  expr_st     : storage;
  expr_type   : identifier;
  subprogramId : constant identifier := rnd_t;
begin
  kind := positive_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type, positive_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           -- from pegasoft.numerics
           result := storage'( to_unbounded_string( numericValue( rnd( positive( to_numeric( expr_st.value ) ) ) ) ),
              noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsRnd;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ODD                                    (built-in function)
--
-- AdaScript Syntax: b := numerics.odd( i )
--       Ada Target: N/A
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.odd
-----------------------------------------------------------------------------

procedure ParseNumericsOdd( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  subprogramId : constant identifier := odd_t;
begin
  kind := boolean_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type, integer_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'( to_spar_boolean( integer( to_numeric( expr_st.value ) ) mod 2 = 1 ),
              noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsOdd;

-----------------------------------------------------------------------------
--  PARSE NUMERICS EVEN                                   (built-in function)
--
-- AdaScript Syntax: b := numerics.even( i )
--       Ada Target: N/A
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.even
-----------------------------------------------------------------------------

procedure ParseNumericsEven( result : out storage; kind : out identifier ) is
  expr_st    : storage;
  expr_type  : identifier;
  subprogramId : constant identifier := even_t;
begin
  kind := boolean_t;
  expect( subprogramId );
  ParseSingleNumericParameter( subprogramId, expr_st, expr_type, integer_t );
  begin
     if isExecutingCommand then
        if metaTagOk( subprogramId, expr_st ) then
           result := storage'( to_spar_boolean( integer( to_numeric( expr_st.value ) ) mod 2 = 0 ),
              noMetaTag, expr_st.policyMetaTags );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsEven;

-----------------------------------------------------------------------------
--  PARSE NUMERICS RE                                     (built-in function)
--
-- AdaScript Syntax: b := numerics.re( complex )
--       Ada Target: Pegasoft.Numerics.Complex_Types.Re
--   GNAT Spec File: a-ngcoty.ads
--   SparForte Docs: pkg_numerics.html#numerics.re
-----------------------------------------------------------------------------

procedure ParseNumericsRe( result : out storage; kind : out identifier ) is
  record_id : identifier;
  c : complex;
  real_t      : identifier;
  img_t       : identifier;
  subprogramId : constant identifier := numerics_re_t;
begin
  kind := long_float_t;
  expect( subprogramId );
  expect( symbol_t, "(" );
  ParseIdentifier( record_id );
  if baseTypesOk( identifiers( record_id ).kind, complex_t ) then
     expect( symbol_t, ")" );
  end if;
  begin
     if isExecutingCommand then
       findField( record_id, 1, real_t );
       findField( record_id, 2, img_t );
       if metaTagOk( subprogramId, identifiers( real_t ).store.all ) then
          c.re := to_numeric( identifiers( real_t ).store.value );
          c.im := to_numeric( identifiers( img_t ).store.value );
          result := storage'( to_unbounded_string( numericValue( Re( c ) ) ),
            noMetaTag, identifiers( real_t ).store.policyMetaTags );
       end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsRe;

-----------------------------------------------------------------------------
--  PARSE NUMERICS IM                                     (built-in function)
--
-- AdaScript Syntax: b := numerics.im( complex )
--       Ada Target: Pegasoft.Numerics.Complex_Types.Im
--   GNAT Spec File: a-ngcoty.ads
--   SparForte Docs: pkg_numerics.html#numerics.im
-----------------------------------------------------------------------------

procedure ParseNumericsIm( result : out storage; kind : out identifier ) is
  record_id : identifier;
  c : complex;
  real_t      : identifier;
  img_t       : identifier;
  subprogramId : constant identifier := numerics_im_t;
begin
  kind := long_float_t;
  expect( subprogramId );
  expect( symbol_t, "(" );
  ParseIdentifier( record_id );
  if baseTypesOk( identifiers( record_id ).kind, complex_t ) then
     expect( symbol_t, ")" );
  end if;
  begin
     if isExecutingCommand then
       findField( record_id, 1, real_t );
       findField( record_id, 2, img_t );
       if metaTagOk( subprogramId, identifiers( img_t ).store.all ) then
          c.re := to_numeric( identifiers( real_t ).store.value );
          c.im := to_numeric( identifiers( img_t ).store.value );
          result := storage'( to_unbounded_string( numericValue( Im( c ) ) ),
             noMetaTag, identifiers( img_t ).store.policyMetaTags );
       end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsIm;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SET RE                                (built-in procedure)
--
-- AdaScript Syntax: numerics.set_re( complex, f )
--       Ada Target: Pegasoft.Numerics.Complex_Types.Set_Re
--   GNAT Spec File: a-ngcoty.ads
--   SparForte Docs: Not yet implemented
-----------------------------------------------------------------------------

procedure ParseNumericsSetRe is
  expr_st : storage;
  expr_type : identifier;
  record_id : identifier;
  c : complex;
  real_t      : identifier;
  img_t       : identifier;
  subprogramId : constant identifier := numerics_set_re_t;
begin
  expect( subprogramId );
  expect( symbol_t, "(" );
  ParseIdentifier( record_id );
  if baseTypesOk( identifiers( record_id ).kind, complex_t ) then
     expectParameterComma;
     ParseExpression( expr_st, expr_type );
     if baseTypesOk( expr_type, long_float_t ) then
        expect( symbol_t, ")" );
     end if;
  end if;
  begin
     if isExecutingCommand then
       findField( record_id, 1, real_t );
       findField( record_id, 2, img_t );
       if metaTagOk( subprogramId, identifiers( real_t ).store.all ) and
          metaTagOk( subprogramId, expr_st ) then
          c.re := to_numeric( identifiers( real_t ).store.value );
          c.im := to_numeric( identifiers( img_t ).store.value );
          Set_Re( c, to_numeric( expr_st.value ) );
          identifiers( real_t ).store.value := to_unbounded_string( numericValue( c.re ) );
          identifiers( real_t ).store.unitMetaTag := expr_st.unitMetaTag;
          identifiers( real_t ).store.policyMetaTags := expr_st.policyMetaTags;
       end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsSetRe;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SET IM                                (built-in procedure)
--
-- AdaScript Syntax: numerics.set_im( complex, f )
--       Ada Target: Pegasoft.Numerics.Complex_Types.Set_Im
--   GNAT Spec File: a-ngcoty.ads
--   SparForte Docs: Not yet implemented
-----------------------------------------------------------------------------

procedure ParseNumericsSetIm is
  expr_st     : storage;
  expr_type   : identifier;
  record_id   : identifier;
  real_t      : identifier;
  img_t       : identifier;
  c : complex;
  subprogramId : constant identifier := numerics_set_im_t;
begin
  expect( subprogramId );
  expect( symbol_t, "(" );
  ParseIdentifier( record_id );
  if baseTypesOk( identifiers( record_id ).kind, complex_t ) then
     expectParameterComma;
     ParseExpression( expr_st, expr_type );
     if baseTypesOk( expr_type, long_float_t ) then
        expect( symbol_t, ")" );
     end if;
  end if;
  begin
     if isExecutingCommand then
       findField( record_id, 1, real_t );
       findField( record_id, 2, img_t );
       if metaTagOk( subprogramId, identifiers( img_t ).store.all ) and
          metaTagOk( subprogramId, expr_st ) then
          c.re := to_numeric( identifiers( real_t ).store.value );
          c.im := to_numeric( identifiers( img_t ).store.value );
          Set_Im( c, to_numeric( expr_st.value ) );
          identifiers( img_t ).store.value := to_unbounded_string( numericValue( c.im ) );
          identifiers( img_t ).store.unitMetaTag := expr_st.unitMetaTag;
          identifiers( img_t ).store.policyMetaTags := expr_st.policyMetaTags;
       end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsSetIm;

-- Can't return a new complex expression
--
--procedure ParseNumericsSetComposeFromCartesian( result : out storage ) is
  -- Syntax: r := numerics.compose_from_cartesian( r [, i] );
  -- Source: N/A
  --expr_st   : unbounded_string;
  --expr_type  : identifier;
--begin
  --expect( _t );
  --expect( symbol_t, "(" );
  --ParseExpression( expr_st, expr_type );
  --if baseTypesOk( expr_type, complex_t ) then
     --expect( symbol_t, ")" );
  --end if;
  --begin
     --if isExecutingCommand then
       --result := to_numeric( expr_st.value );
     --end if;
  --exception when others =>
     --err_exception_raised;
  --end;
--end ParseNumericsComposeFromCartisian;

-----------------------------------------------------------------------------
--  PARSE NUMERICS MODULUS                                (built-in function)
--
-- AdaScript Syntax: f := numerics.modulus( complex )
--       Ada Target: Pegasoft.Numerics.Complex_Types.Modulus
--   GNAT Spec File: a-ngcoty.ads
--   SparForte Docs: Not yet implemented
--
-- In Ada, abs is a renaming of modulus
-----------------------------------------------------------------------------

procedure ParseNumericsModulus( result : out storage; kind : out identifier ) is
  record_id   : identifier;
  c : complex;
  real_t      : identifier;
  img_t       : identifier;
  subprogramId : constant identifier := numerics_modulus_t;
begin
  kind := long_float_t;
  expect( subprogramId );
  expect( symbol_t, "(" );
  ParseIdentifier( record_id );
  if baseTypesOk( identifiers( record_id ).kind, complex_t ) then
     expect( symbol_t, ")" );
  end if;
  begin
     if isExecutingCommand then
       findField( record_id, 1, real_t );
       findField( record_id, 2, img_t );
       if metaTagOk( subprogramId, identifiers( real_t ).store.all, identifiers( img_t ).store.all ) then
          c.re := to_numeric( identifiers( real_t ).store.value );
          c.im := to_numeric( identifiers( img_t ).store.value );
          result := storage'( to_unbounded_string( numericValue( Modulus( c ) ) ),
             noMetaTag,
             resolveEffectiveMetaTags(
                long_float_t,
                identifiers( real_t ).store.all,
                identifiers( img_t ).store.all
             )
         );
        end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsModulus;

-----------------------------------------------------------------------------
--  PARSE NUMERICS ARGUMENT                               (built-in function)
--
-- AdaScript Syntax: f := numerics.argument( complex [, cycle] )
--       Ada Target: Pegasoft.Numerics.Complex_Types.Argument
--   GNAT Spec File: a-ngcoty.ads
--   SparForte Docs: Not yet implemented
-----------------------------------------------------------------------------

procedure ParseNumericsArgument( result : out storage; kind : out identifier ) is
  record_id   : identifier;
  cycle_st    : storage;
  cycle_type  : identifier;
  has_cycle   : boolean := false;
  c : complex;
  real_t      : identifier;
  img_t       : identifier;
  subprogramId : constant identifier := numerics_argument_t;
begin
  kind := long_float_t;
  expect( subprogramId );
  expect( symbol_t, "(" );
  ParseIdentifier( record_id );
  if baseTypesOk( identifiers( record_id ).kind, complex_t ) then
     if token = symbol_t and identifiers( token ).store.value = "," then
        getNextToken;
        ParseExpression( cycle_st, cycle_type );
        has_cycle := true;
     end if;
     expect( symbol_t, ")" );
  end if;
  begin
     if isExecutingCommand then
       findField( record_id, 1, real_t );
       findField( record_id, 2, img_t );
       c.re := to_numeric( identifiers( real_t ).store.value );
       c.im := to_numeric( identifiers( img_t ).store.value );
       if metaTagOk( subprogramId, identifiers( real_t ).store.all, identifiers( img_t ).store.all ) then
          if has_cycle then
             result := storage'( to_unbounded_string( numericValue( Argument( c, to_numeric( cycle_st.value ) ) ) ),
                noMetaTag,
                resolveEffectiveMetaTags(
                   long_float_t,
                   identifiers( real_t ).store.all,
                   identifiers( img_t ).store.all
                )
             );
          else
             result := storage'( to_unbounded_string( numericValue( Argument( c ) ) ),
                noMetaTag,
                resolveEffectiveMetaTags(
                   long_float_t,
                   identifiers( real_t ).store.all,
                   identifiers( img_t ).store.all
                )
             );
          end if;
       end if;
     end if;
  exception when others =>
     err_exception_raised;
  end;
end ParseNumericsArgument;

-- Can't return record expressions
--procedure ParseNumericsComposeFromPolar( result : out storage ) is
  -- Syntax: r := numerics.compose_from_polar( n ,a );
  -- Source: N/A
  --expr_st   : unbounded_string;
  --expr_type  : identifier;
--begin
  --expect( _t );
  --expect( symbol_t, "(" );
  --ParseExpression( expr_st, expr_type );
  --if baseTypesOk( expr_type, complex_t ) then
     --expect( symbol_t, ")" );
  --end if;
  --begin
     --if isExecutingCommand then
--       result := to_numeric( expr_st.value );
 --    end if;
  --exception when others =>
   --  err_exception_raised;
  --end;
--end ParseNumericsComposeFromPolar;

-- Can't return a record expression
--procedure ParseNumericsConjugate( result : out storage ) is
  -- Syntax: r := numerics.conjugate( n );
  -- Source: N/A
  --expr_st   : unbounded_string;
  --expr_type  : identifier;
--begin
  --expect( _t );
  --expect( symbol_t, "(" );
  --ParseExpression( expr_st, expr_type );
  --if baseTypesOk( expr_type, complex_t ) then
     --expect( symbol_t, ")" );
  --end if;
  --begin
     --if isExecutingCommand then
       --result := to_numeric( expr_st.value );
     --end if;
  --exception when others =>
     --err_exception_raised;
  --end;
--end ParseNumericsConjugate;

-----------------------------------------------------------------------------
--  PARSE NUMERICS HASH OF                                (built-in function)
--
-- AdaScript Syntax: n := numerics.hash_of( s, l )
--       Ada Target: PegaSoft.Numerics.Hash_Of
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.hash_of
-----------------------------------------------------------------------------

procedure ParseNumericsHashOf( result : out storage; kind : out identifier) is
  expr1_st    : storage;
  expr1_type  : identifier;
  expr2_st    : storage;
  expr2_type  : identifier;
  subprogramId : constant identifier := hash_of_t;
begin
  kind := natural_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr1_st, expr1_type, string_t );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type, natural_t );
  declare
    limit : hash_integer;
  begin
    if isExecutingCommand then
       if metaTagOK( subprogramId, expr1_st, expr2_st ) then
          limit := hash_integer( to_numeric( expr2_st.value ) );
          result := storage'( to_unbounded_string( numericValue( hash_of( expr1_st.value, limit ) ) ),
                noMetaTag,
                resolveEffectiveMetaTags( kind, expr1_st, expr2_st ) );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsHashOf;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SDBM HASH OF                           (built-in function)
--
-- AdaScript Syntax: n := numerics.sdbm_hash_of( s, l )
--       Ada Target: PegaSoft.Numerics.SDBM_Hash_Of
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.sdbm_hash_of
-----------------------------------------------------------------------------

procedure ParseNumericsSdbmHashOf( result : out storage; kind : out identifier ) is
  expr1_st    : storage;
  expr1_type  : identifier;
  expr2_st    : storage;
  expr2_type  : identifier;
  subprogramId : constant identifier := sdbm_hash_of_t;
begin
  kind := natural_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr1_st, expr1_type, string_t );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type, natural_t );
  declare
    limit : hash_integer;
  begin
    if isExecutingCommand then
       if metaTagOK( subprogramId, expr1_st, expr2_st ) then
          limit := hash_integer( to_numeric( expr2_st.value ) );
          result := storage'( to_unbounded_string( numericValue( sdbm_hash_of( expr1_st.value, limit ) ) ),
                noMetaTag,
                resolveEffectiveMetaTags( kind, expr1_st, expr2_st ) );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsSdbmHashOf;

-----------------------------------------------------------------------------
--  PARSE NUMERICS FNV HASH OF                            (built-in function)
--
-- AdaScript Syntax: n := numerics.fnv_hash_of( s, l )
--       Ada Target: PegaSoft.Numerics.FNV_Hash_Of
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.fnv_hash_of
-----------------------------------------------------------------------------

procedure ParseNumericsFnvHashOf( result : out storage; kind : out identifier ) is
  expr1_st    : storage;
  expr1_type  : identifier;
  expr2_st    : storage;
  expr2_type  : identifier;
  subprogramId : constant identifier := fnv_hash_of_t;
begin
  kind := natural_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr1_st, expr1_type, string_t );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type, natural_t );
  declare
    limit  : hash_integer;
  begin
    if isExecutingCommand then
       if metaTagOK( subprogramId, expr1_st, expr2_st ) then
          limit := hash_integer( to_numeric( expr2_st.value ) );
          result := storage'( to_unbounded_string( numericValue( fnv_hash_of( expr1_st.value, limit ) ) ),
             noMetaTag,
             resolveEffectiveMetaTags( kind, expr1_st, expr2_st ) );
       end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsFnvHashOf;

-----------------------------------------------------------------------------
--  PARSE NUMERICS MURMUR HASH OF                         (built-in function)
--
-- AdaScript Syntax: n := numerics.murmur_hash_of( s, l )
--       Ada Target: PegaSoft.Numerics.Murmur_Hash_Of
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.murmur_hash_of
-----------------------------------------------------------------------------

procedure ParseNumericsMurmurHashOf( result : out storage; kind : out identifier ) is
  expr1_st    : storage;
  expr1_type  : identifier;
  expr2_st    : storage;
  expr2_type  : identifier;
  subprogramId : constant identifier := murmur_hash_of_t;
begin
  kind := natural_t;
  expect( subprogramId );
  ParseFirstNumericParameter( subprogramId, expr1_st, expr1_type, string_t );
  ParseLastNumericParameter( subprogramId, expr2_st, expr2_type, natural_t );
  declare
    limit  : hash_integer;
  begin
    if isExecutingCommand then
       if metaTagOK( subprogramId, expr1_st, expr2_st ) then
       limit := hash_integer( to_numeric( expr2_st.value ) );
       result := storage'( to_unbounded_string( numericValue( murmur_hash_of( expr1_st.value, limit ) ) ),
          noMetaTag,
          resolveEffectiveMetaTags( kind, expr1_st, expr2_st ) );
    end if;
    end if;
  exception when others =>
    err_exception_raised;
  end;
end ParseNumericsMurmurHashOf;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SHA1 DIGEST OF                         (built-in function)
--
-- AdaScript Syntax: d := numerics.sha1_digest_of( s )
--       Ada Target: GNAT.SHA1.Digest
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.sha1_digest_of
-----------------------------------------------------------------------------

procedure ParseNumericsSHA1DigestOf( result : out storage; kind : out identifier ) is
  src_st   : storage;
  src_type : identifier;
  subprogramId : constant identifier := sha1_digest_of_t;
begin
  expect( subprogramId );
  ParseSingleStringParameter( subprogramId, src_st, src_type );
  kind := src_type;
  if isExecutingCommand then
     if metaTagOK( subprogramId, src_st ) then
        result := storage'( to_unbounded_string( Gnat.SHA1.Digest( to_string( src_st.value ) ) ),
           noMetaTag,
           src_st.policyMetaTags );
     end if;
  end if;
end ParseNumericsSHA1DigestOf;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SHA224 DIGEST OF                       (built-in function)
--
-- AdaScript Syntax: d := numerics.sha224_digest_of( s )
--       Ada Target: GNAT.SHA224.Digest
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.sha224_digest_of
-----------------------------------------------------------------------------

procedure ParseNumericsSHA224DigestOf( result : out storage; kind : out identifier ) is
  src_st   : storage;
  src_type : identifier;
  subprogramId : constant identifier := sha224_digest_of_t;
begin
  expect( subprogramId );
  ParseSingleStringParameter( subprogramId, src_st, src_type );
  kind := src_type;
  if isExecutingCommand then
     if metaTagOK( subprogramId, src_st ) then
        result := storage'( to_unbounded_string( Gnat.SHA224.Digest( to_string( src_st.value ) ) ),
           noMetaTag,
           src_st.policyMetaTags );
     end if;
  end if;
end ParseNumericsSHA224DigestOf;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SHA256 DIGEST OF                       (built-in function)
--
-- AdaScript Syntax: d := numerics.sha256_digest_of( s )
--       Ada Target: GNAT.SHA256.Digest
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.sha256_digest_of
-----------------------------------------------------------------------------

procedure ParseNumericsSHA256DigestOf( result : out storage; kind : out identifier ) is
  src_st   : storage;
  src_type : identifier;
  subprogramId : constant identifier := sha256_digest_of_t;
begin
  expect( subprogramId );
  ParseSingleStringParameter( subprogramId, src_st, src_type );
  kind := src_type;
  if isExecutingCommand then
     if metaTagOK( subprogramId, src_st ) then
        result := storage'( to_unbounded_string( Gnat.SHA256.Digest( to_string( src_st.value ) ) ),
           noMetaTag,
           src_st.policyMetaTags );
     end if;
  end if;
end ParseNumericsSHA256DigestOf;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SHA512 DIGEST OF                       (built-in function)
--
-- AdaScript Syntax: d := numerics.sha512_digest_of( s )
--       Ada Target: GNAT.SHA512.Digest
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.sha512_digest_of
-----------------------------------------------------------------------------

procedure ParseNumericsSHA512DigestOf( result : out storage; kind : out identifier ) is
  src_st   : storage;
  src_type : identifier;
  subprogramId : constant identifier := sha512_digest_of_t;
begin
  expect( subprogramId );
  ParseSingleStringParameter( subprogramId, src_st, src_type );
  kind := src_type;
  if isExecutingCommand then
     if metaTagOK( subprogramId, src_st ) then
        result := storage'( to_unbounded_string( Gnat.SHA512.Digest( to_string( src_st.value ) ) ),
           noMetaTag,
           src_st.policyMetaTags );
     end if;
  end if;
end ParseNumericsSHA512DigestOf;

-----------------------------------------------------------------------------
--  PARSE NUMERICS SHANNON ENTROPY OF                     (built-in function)
--
-- AdaScript Syntax: f := numerics.shannon_entropy_of( s )
--       Ada Target: PegaSoft.Numerics.Shannon_Entropy_Of
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_numerics.html#numerics.shannon_entropy_of
-----------------------------------------------------------------------------

procedure ParseNumericsShannonEntropyOf( result : out storage; kind : out identifier ) is
  src_st   : storage;
  src_type : identifier;
  subprogramId : constant identifier := shannon_entropy_of_t;
begin
  expect( subprogramId );
  ParseSingleStringParameter( subprogramId, src_st, src_type );
  kind := long_float_t;
  if isExecutingCommand then
     if metaTagOK( subprogramId, src_st ) then
        result := storage'( to_unbounded_string( shannon_entropy_of( src_st.value ) ),
           noMetaTag,
           src_st.policyMetaTags );
     end if;
  end if;
end ParseNumericsShannonEntropyOf;


-----------------------------------------------------------------------------
-- HOUSEKEEPING
-----------------------------------------------------------------------------

procedure StartupNumerics is
begin

  declareNamespace( "numerics" );

  -- Numerics Package identifiers

  declareFunction( random_t, "numerics.random", ParseNumericsRandom'access );
  declareFunction( shift_left_t, "numerics.shift_left", ParseNumericsShiftLeft'access );
  declareFunction( shift_right_t, "numerics.shift_right", ParseNumericsShiftRight'access );
  declareFunction( rotate_left_t, "numerics.rotate_left", ParseNumericsRotateLeft'access );
  declareFunction( rotate_right_t, "numerics.rotate_right", ParseNumericsRotateRight'access );
  declareFunction( shift_right_arith_t, "numerics.shift_right_arithmetic", ParseNumericsASR'access );
  declareFunction( sqrt_t, "numerics.sqrt", ParseNumericsSqrt'access );
  declareFunction( log_t, "numerics.log", ParseNumericsLog'access );
  declareFunction( exp_t, "numerics.exp", ParseNumericsExp'access );
  declareFunction( sin_t, "numerics.sin", ParseNumericsSin'access );
  declareFunction( cos_t, "numerics.cos", ParseNumericsCos'access );
  declareFunction( tan_t, "numerics.tan", ParseNumericsTan'access );
  declareFunction( cot_t, "numerics.cot", ParseNumericsCot'access );
  declareFunction( arcsin_t, "numerics.arcsin", ParseNumericsArcSin'access );
  declareFunction( arccos_t, "numerics.arccos", ParseNumericsArcCos'access );
  declareFunction( arctan_t, "numerics.arctan", ParseNumericsArcTan'access );
  declareFunction( arccot_t, "numerics.arccot", ParseNumericsArcCot'access );
  declareFunction( sinh_t, "numerics.sinh", ParseNumericsSinH'access );
  declareFunction( cosh_t, "numerics.cosh", ParseNumericsCosH'access );
  declareFunction( tanh_t, "numerics.tanh", ParseNumericsTanH'access );
  declareFunction( coth_t, "numerics.coth", ParseNumericsCotH'access );
  declareFunction( arcsinh_t, "numerics.arcsinh", ParseNumericsArcSinH'access );
  declareFunction( arccosh_t, "numerics.arccosh", ParseNumericsArcCosH'access );
  declareFunction( arctanh_t, "numerics.arctanh", ParseNumericsArcTanH'access );
  declareFunction( arccoth_t, "numerics.arccoth", ParseNumericsArcCotH'access );
  declareFunction( floor_t, "numerics.floor", ParseNumericsFloor'access );
  declareFunction( ceiling_t, "numerics.ceiling", ParseNumericsCeiling'access );
  declareFunction( rounding_t, "numerics.rounding", ParseNumericsRounding'access );
  declareFunction( unbiased_rounding_t, "numerics.unbiased_rounding", ParseNumericsUnbiasedRounding'access );
  declareFunction( truncation_t, "numerics.truncation", ParseNumericsTruncation'access );
  declareFunction( remainder_t, "numerics.remainder", ParseNumericsRemainder'access );
  declareFunction( exponent_t, "numerics.exponent", ParseNumericsExponent'access );
  declareFunction( fraction_t, "numerics.fraction", ParseNumericsFraction'access );
  declareFunction( leading_part_t, "numerics.leading_part", ParseNumericsLeadingPart'access );
  declareFunction( copy_sign_t, "numerics.copy_sign", ParseNumericsCopySign'access );
  declareFunction( sturges_t, "numerics.sturges", ParseNumericsSturges'access );
  declareFunction( max_t, "numerics.max", ParseNumericsMax'access );
  declareFunction( min_t, "numerics.min", ParseNumericsMin'access );
  declareFunction( machine_t, "numerics.machine", ParseNumericsMachine'access );
  declareFunction( scaling_t, "numerics.scaling", ParseNumericsScaling'access );
  declareFunction( value_t, "numerics.value", ParseNumericsValue'access );
  declareFunction( pos_t, "numerics.pos", ParseNumericsPos'access );
  declareFunction( numerics_md5_t, "numerics.md5", ParseNumericsMd5'access );
  declareFunction( serial_t, "numerics.serial", ParseNumericsSerial'access );
  declareFunction( rnd_t, "numerics.rnd", ParseNumericsRnd'access );
  declareFunction( odd_t, "numerics.odd", ParseNumericsOdd'access );
  declareFunction( even_t, "numerics.even", ParseNumericsEven'access );
  declareFunction( numerics_re_t, "numerics.re", ParseNumericsRe'access );
  declareFunction( numerics_im_t, "numerics.im", ParseNumericsIm'access );
  declareProcedure( numerics_set_re_t, "numerics.set_re", ParseNumericsSetRe'access );
  declareProcedure( numerics_set_im_t, "numerics.set_im", ParseNumericsSetIm'access );
  declareFunction( numerics_argument_t, "numerics.argument", ParseNumericsArgument'access );
  declareFunction( numerics_modulus_t, "numerics.modulus", ParseNumericsModulus'access );
  declareFunction( hash_of_t, "numerics.hash_of", ParseNumericsHashOf'access );
  declareFunction( sdbm_hash_of_t, "numerics.sdbm_hash_of", ParseNumericsSdbmHashOf'access );
  declareFunction( fnv_hash_of_t, "numerics.fnv_hash_of", ParseNumericsFnvHashOf'access );
  declareFunction( murmur_hash_of_t, "numerics.murmur_hash_of", ParseNumericsMurmurHashOf'access );
  declareFunction( sha1_digest_of_t,  "numerics.sha1_digest_of", ParseNumericsSHA1DigestOf'access );
  declareFunction( sha224_digest_of_t,  "numerics.sha224_digest_of", ParseNumericsSHA224DigestOf'access );
  declareFunction( sha256_digest_of_t,  "numerics.sha256_digest_of", ParseNumericsSHA256DigestOf'access );
  declareFunction( sha512_digest_of_t,  "numerics.sha512_digest_of", ParseNumericsSHA512DigestOf'access );
  declareFunction( shannon_entropy_of_t,  "numerics.shannon_entropy_of", ParseNumericsShannonEntropyOf'access );

  -- Numerics package constants
  -- There's are derived from the GNU standard C library math constants

  declareStandardConstant( numerics_e_t, "numerics.e", long_float_t,
      "2.7182818284590452354" );
  declareStandardConstant( numerics_log2_e_t, "numerics.log2_e", long_float_t,
      "1.4426950408889634074" );
  declareStandardConstant( numerics_log10_e_t, "numerics.log10_e", long_float_t,
      "0.43429448190325182765" );
  declareStandardConstant( numerics_ln2_t, "numerics.ln2", long_float_t,
      "0.69314718055994530942" );
  declareStandardConstant( numerics_ln10_t, "numerics.ln10", long_float_t,
      "2.30258509299404568402" );
  declareStandardConstant( numerics_pi_t, "numerics.pi", long_float_t,
      "3.14159265358979323846" );
  declareStandardConstant( numerics_pi_by_2_t, "numerics.pi_by_2", long_float_t,
      "1.57079632679489661923" );
  declareStandardConstant( numerics_pi_by_4_t, "numerics.pi_by_4", long_float_t,
      "0.78539816339744830962" );
  declareStandardConstant( numerics_pi_under_1_t, "numerics.pi_under_1", long_float_t,
      "0.31830988618379067154" );
  declareStandardConstant( numerics_pi_under_2_t, "numerics.pi_under_2", long_float_t,
      "0.63661977236758134308" );
  declareStandardConstant( numerics_sqrt_pi_under_2_t, "numerics.sqrt_pi_under_2",
      long_float_t, "1.12837916709551257390" );
  declareStandardConstant( numerics_sqrt_2_t, "numerics.sqrt_2", long_float_t,
      "1.4142135623730950488" );
  declareStandardConstant( numerics_sqrt_2_under_1_t, "numerics.sqrt_2_under_1", long_float_t,
      "0.70710678118654752440" );

  -- For future reference these are the same values as above but double
  -- precision
  --declareStandardConstant( numerics_e_t, "numerics.e", long_float_t,
  --    "2.718281828459045235360287471352662498" );
  --declareStandardConstant( numerics_log2_e_t, "numerics.log2_e", long_float_t,
  --    "1.442695040888963407359924681001892137" );
  --declareStandardConstant( numerics_log10_e_t, "numerics.log10_e", long_float_t,
  --    "0.434294481903251827651128918916605082" );
  --declareStandardConstant( numerics_ln2_t, "numerics.ln1", long_float_t,
  --    "0.693147180559945309417232121458176568" );
  --declareStandardConstant( numerics_ln10_t, "numerics.ln10", long_float_t,
  --    "2.302585092994045684017991454684364208" );
  --declareStandardConstant( numerics_pi_t, "numerics.pi", long_float_t,
  --    "3.141592653589793238462643383279502884" );
  --declareStandardConstant( numerics_pi_by_2_t, "numerics.pi_by_2", long_float_t,
  --    "1.570796326794896619231321691639751442" );
  --declareStandardConstant( numerics_pi_by_4_t, "numerics.pi_by_4", long_float_t,
  --    "0.785398163397448309615660845819875721" );
  --declareStandardConstant( numerics_pi_under_1_t, "numerics.pi_under_1", long_float_t,
  --    "0.318309886183790671537767526745028724" );
  --declareStandardConstant( numerics_pi_under_2_t, "numerics.pi_under_2", long_float_t,
  --    "0.636619772367581343075535053490057448" );
  --declareStandardConstant( numerics_sqrt_pi_under_2_t, "numerics.sqrt_pi_under_2",
  --    long_float_t, "1.128379167095512573896158903121545172" );
  --declareStandardConstant( numerics_sqrt_2_t, "numerics.sqrt_2", long_float_t,
  --    "1.414213562373095048801688724209698079" );
  --declareStandardConstant( numerics_sqrt_2_under_1_t, "numerics.sqrt_2_under_1", long_float_t,
  --    "0.707106781186547524400844362104849039" );

  declareNamespaceClosed( "numerics" );
end StartupNumerics;

procedure ShutdownNumerics is
begin
  null;
end ShutdownNumerics;

end parser_numerics;
