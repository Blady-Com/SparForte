------------------------------------------------------------------------------
-- Memcache Package Parser                                  -               --
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

with pegasoft.gen_list,
    ada.strings.unbounded,
    world,
    symbol_table,
    message_strings,
    value_conversion,
    scanner,
    scanner.communications,
    parser_params,
    pegasock.memcache.highread;
use ada.strings,
    ada.strings.unbounded,
    pegasoft,
    world,
    symbol_table,
    message_strings,
    value_conversion,
    scanner,
    scanner.communications,
    parser_params,
    pegasock,
    pegasock.memcache,
    pegasock.memcache.highread;

package body parser_memcache is

------------------------------------------------------------------------------
-- Memcache package identifiers
------------------------------------------------------------------------------

memcache_cluster_t               : identifier;
memcache_cluster_type_t          : identifier;
memcache_cluster_type_normal_t   : identifier;

memcache_is_valid_memcache_key_t : identifier;
memcache_new_cluster_t           : identifier;
memcache_clear_servers_t         : identifier;
memcache_register_server_t       : identifier;
memcache_set_cluster_name_t      : identifier;
memcache_set_cluster_type_t      : identifier;
memcache_set_t                   : identifier;
memcache_add_t                   : identifier;
memcache_replace_t               : identifier;
memcache_append_t                : identifier;
memcache_prepend_t               : identifier;
memcache_get_t                   : identifier;
memcache_delete_t                : identifier;
memcache_stats_t                 : identifier;
memcache_version_t               : identifier;
memcache_flush_t                 : identifier;

highread_cluster_t               : identifier;

highread_new_cluster_t           : identifier;
highread_clear_servers_t         : identifier;
highread_register_alpha_server_t : identifier;
highread_register_beta_server_t  : identifier;
highread_set_cluster_name_t      : identifier;
highread_set_cluster_type_t      : identifier;
highread_set_t                   : identifier;
highread_add_t                   : identifier;
highread_replace_t               : identifier;
highread_append_t                : identifier;
highread_prepend_t               : identifier;
highread_get_t                   : identifier;
highread_delete_t                : identifier;
highread_stats_t                 : identifier;
highread_version_t               : identifier;
highread_flush_t                 : identifier;

-----------------------------------------------------------------------------
-- UTILITIES: MEMCACHE CLUSTER
-- since HTTP result is private, we'll track them in a linked list
-----------------------------------------------------------------------------


type aMemcacheClusterID is new natural;

type aMemcacheClusterEntry is record
  id      : aMemcacheClusterID := 0;
  cluster : aMemcacheCluster;
end record;

-- Ada 2012
-- Declarations of primitive functions must have a spec before the body since
-- the first primitive body prohibits any more primitives to be declared.

function ">="( left, right : aMemcacheClusterEntry ) return boolean;
function "="( left, right : aMemcacheClusterEntry ) return boolean;

function ">="( left, right : aMemcacheClusterEntry ) return boolean is
begin
   return left.id >= right.id;
end ">=";

function "="( left, right : aMemcacheClusterEntry ) return boolean is
begin
   return left.id = right.id;
end "=";

package memcacheClusterList is new pegasoft.gen_list( aMemcacheClusterEntry, "=", ">=" );

memcacheCluster : memcacheClusterList.List;
memcacheClusterIdTop : aMemcacheClusterID := 1;                   -- id counter


--  GET CLUSTER
--
-- Lookup the cluster record.  If not found, set cluster_id to zero.
-----------------------------------------------------------------------------

procedure GetCluster( cluster_id : aMemcacheClusterID;
   theMemcacheClusterEntry : out aMemcacheClusterEntry;
   clusterIndex : out memcacheClusterList.aListIndex ) is
begin
  clusterIndex := 0; --to suppress compiler warning
  theMemcacheClusterEntry.id := cluster_id;
  memcacheClusterList.Find( memcacheCluster, theMemcacheClusterEntry, 1, clusterIndex );
  if clusterIndex = 0 then
     err( pl( "cluster id " & cluster_id'img & " not found" ) );
  else
     memcacheClusterList.Find( memcacheCluster, clusterIndex, theMemcacheClusterEntry );
  end if;
end GetCluster;


-----------------------------------------------------------------------------
-- UTILITIES: MEMCACHE HIGHREAD CLUSTER
-- since HTTP result is private, we'll track them in a linked list
-----------------------------------------------------------------------------


type aMemcacheDualClusterID is new natural;

type aMemcacheDualClusterEntry is record
  id      : aMemcacheDualClusterID := 0;
  cluster : aMemcacheDualCluster;
end record;

-- Ada 2012
-- Declarations of primitive functions must have a spec before the body since
-- the first primitive body prohibits any more primitives to be declared.

function ">="( left, right : aMemcacheDualClusterEntry ) return boolean;
function "="( left, right : aMemcacheDualClusterEntry ) return boolean;

function ">="( left, right : aMemcacheDualClusterEntry ) return boolean is
begin
   return left.id >= right.id;
end ">=";

function "="( left, right : aMemcacheDualClusterEntry ) return boolean is
begin
   return left.id = right.id;
end "=";

-- TODO: KB: 17/02/12: rewrite to use resources

package memcacheDualClusterList is new pegasoft.gen_list( aMemcacheDualClusterEntry, "=", ">=" );

memcacheDualCluster : memcacheDualClusterList.List;
memcacheDualClusterIdTop : aMemcacheDualClusterID := 1;          -- id counter


--  GET CLUSTER
--
-- Lookup the cluster record.  If not found, set cluster_id to zero.
-----------------------------------------------------------------------------

procedure GetCluster( cluster_id : aMemcacheDualClusterID;
   theMemcacheClusterEntry : out aMemcacheDualClusterEntry;
   clusterIndex : out memcacheDualClusterList.aListIndex ) is
begin
  clusterIndex := 0; --to suppress compiler warning
  theMemcacheClusterEntry.id := cluster_id;
  memcacheDualClusterList.Find( memcacheDualCluster, theMemcacheClusterEntry, 1, clusterIndex );
  if clusterIndex = 0 then
     err( pl( "cluster id " & cluster_id'img & " not found" ) );
  else
     memcacheDualClusterList.Find( memcacheDualCluster, clusterIndex, theMemcacheClusterEntry );
  end if;
end GetCluster;

procedure checkMemcacheRestriction is
begin
  if restriction_no_memcache then
     err( +"not allowed with " & em( "pragma restriction( no_memcache )" ) );
  end if;
end checkMemcacheRestriction;


----------------------------------------------------------------------------
-- PARSE THE MEMCACHE PACKAGE
----------------------------------------------------------------------------


-----------------------------------------------------------------------------
--  PARSE MEMCACHE IS VALID MEMCACHE KEY                  (built-in function)
--
-- AdaScript Syntax: b := memcache.is_valid_memcache_key( k )
--       Ada Target: PegaSock.Memcache.isValidMemcacheKey
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.is_valid_memcache_key
-----------------------------------------------------------------------------

procedure ParseMemcacheIsValidMemcacheKey( result : out storage; kind : out identifier ) is
  expr : storage;
  expr_type : identifier;
  subprogramId : constant identifier := memcache_is_valid_memcache_key_t;
begin
  kind := boolean_t;
  expect( subprogramId );
  ParseSingleStringParameter( subprogramId, expr, expr_type );
  checkMemcacheRestriction;
  if isExecutingCommand then
     if metaTagOk( subprogramId, expr ) then
        begin
          result := storage'( to_spar_boolean( isValidMemcacheKey( expr.value ) ),
             noMetaTag, expr.policyMetaTags );
        exception when others =>
          err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheIsValidMemcacheKey;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE NEW CLUSTER                            (built-in function)
--
-- AdaScript Syntax: cl := memcache.new_cluster( k )
--       Ada Target: N/A
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.new_cluster
-----------------------------------------------------------------------------

procedure ParseMemcacheNewCluster( result : out storage; kind : out identifier ) is
  cluster_entry : aMemcacheClusterEntry;
  cluster_id_value : aMemcacheClusterID;
  subprogramId : constant identifier := memcache_new_cluster_t;
begin
  kind := memcache_cluster_t;
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  checkMemcacheRestriction;
  if isExecutingCommand then
     begin
        cluster_id_value := memcacheClusterIdTop;
        memcacheClusterIdTop := memcacheClusterIdTop + 1;
        cluster_entry.id := cluster_id_value;
        memcacheClusterList.Queue( memcacheCluster, cluster_entry );
        result := storage'( to_unbounded_string( numericValue( cluster_id_value ) ),
           noMetaTag, sparMetaTags );
     exception when others =>
        err_exception_raised;
     end;
  end if;
end ParseMemcacheNewCluster;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE REGISTER SERVER                       (built-in procedure)
--
-- AdaScript Syntax: memcache.register_server( cl, h, p )
--       Ada Target: PegaSock.Memcache.RegisterServer
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.register_server
-----------------------------------------------------------------------------

procedure ParseMemcacheRegisterServer is
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_register_server_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( memcache_register_server_t );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastNumericParameter( subprogramId, expr2, expr_type2, natural_t );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
        if metaTagOk( subprogramId, cluster, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           port : constant natural := natural( to_numeric( expr2.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              RegisterServer( cluster_entry.cluster, expr.value, port );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheRegisterServer;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE CLEAR SERVERS                         (built-in procedure)
--
-- AdaScript Syntax: memcache.clear_servers( cl )
--       Ada Target: PegaSock.Memcache.ClearServers
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.clear_servers
-----------------------------------------------------------------------------

procedure ParseMemcacheClearServers is
  cluster_entry : aMemcacheClusterEntry;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_clear_servers_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseSingleInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              ClearServers( cluster_entry.cluster );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheClearServers;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE SET CLUSTER NAME                      (built-in procedure)
--
-- AdaScript Syntax: memcache.set_cluster_name( cl, s )
--       Ada Target: PegaSock.Memcache.SetClusterName
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.set_cluster_name
-----------------------------------------------------------------------------

procedure ParseMemcacheSetClusterName is
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_set_cluster_name_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseLastStringParameter( subprogramId, expr, expr_type, string_t );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster, expr ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              SetClusterName( cluster_entry.cluster, expr.value );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheSetClusterName;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE SET CLUSTER TYPE                      (built-in procedure)
--
-- AdaScript Syntax: memcache.set_cluster_type( cl, e )
--       Ada Target: PegaSock.Memcache.SetClusterType
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.set_cluster_type
--          Example: memcache.set_cluster_type( c, memcache.memcache_cluster_type.normal )
-----------------------------------------------------------------------------

procedure ParseMemcacheSetClusterType is
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  clusterRef : reference;
  cluster    : storage;
  mct : aMemcacheClusterType;
  subprogramId : constant identifier := memcache_set_cluster_type_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseLastEnumParameter( subprogramId, expr, expr_type, memcache_cluster_type_t );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster, expr ) then
        begin
           mct := aMemcacheClusterType'val( natural( to_numeric( expr.value ) ) );
        exception when constraint_error =>
           err( +"constraint error" );
        when others =>
           err_exception_raised;
        end;
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              SetClusterType( cluster_entry.cluster, mct );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheSetClusterType;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE SET                                   (built-in procedure)
--
-- AdaScript Syntax: memcache.set( cl, k, v )
--       Ada Target: PegaSock.Memcache.Set
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.set
-----------------------------------------------------------------------------

procedure ParseMemcacheSet is
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_set_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Set( cluster_entry.cluster, expr.value, expr2.value );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheSet;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE ADD                                   (built-in procedure)
--
-- AdaScript Syntax: memcache.add( cl, k, v )
--       Ada Target: PegaSock.Memcache.Add
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.add
-----------------------------------------------------------------------------

procedure ParseMemcacheAdd is
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_add_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Add( cluster_entry.cluster, expr.value, expr2.value );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheAdd;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE REPLACE                               (built-in procedure)
--
-- AdaScript Syntax: memcache.replace( cl, k, v )
--       Ada Target: PegaSock.Memcache.Replace
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.replace
-----------------------------------------------------------------------------

procedure ParseMemcacheReplace is
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_replace_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     -- The data in memcache has no data meta label so we cannot check the existing
     -- data against new data's meta label
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Replace( cluster_entry.cluster, expr.value, expr2.value );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheReplace;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE REPLACE                               (built-in procedure)
--
-- AdaScript Syntax: memcache.append( cl, k, v )
--       Ada Target: PegaSock.Memcache.Append
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.append
-----------------------------------------------------------------------------

procedure ParseMemcacheAppend is
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_append_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Append( cluster_entry.cluster, expr.value, expr2.value );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheAppend;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE PREPEND                               (built-in procedure)
--
-- AdaScript Syntax: memcache.prepend( cl, k, v )
--       Ada Target: PegaSock.Memcache.Prepend
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.prepend
-----------------------------------------------------------------------------

procedure ParseMemcachePrepend is
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_prepend_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Prepend( cluster_entry.cluster, expr.value, expr2.value );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcachePrepend;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE GET                                    (built-in function)
--
-- AdaScript Syntax: v := get( cl, k )
--       Ada Target: PegaSock.Memcache.Get
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.get
-----------------------------------------------------------------------------

procedure ParseMemcacheGet( result : out storage; kind : out identifier ) is
-- Syntax: value := get( cluster, key )
-- Source: pegasock.memcache.get
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_get_t;
begin
  kind := string_t;
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseLastStringParameter( subprogramId, expr, expr_type );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              result := nullStorage;
              Get( cluster_entry.cluster, expr.value, result.value );
              result.policyMetaTags := sparMetaTags;
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheGet;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE DELETE                                (built-in procedure)
--
-- AdaScript Syntax: memcache.delete( cl, k )
--       Ada Target: PegaSock.Memcache.Delete
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.delete
-----------------------------------------------------------------------------

procedure ParseMemcacheDelete is
  cluster_entry : aMemcacheClusterEntry;
  expr : storage;
  expr_type : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_delete_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  ParseLastStringParameter( subprogramId, expr, expr_type );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Delete( cluster_entry.cluster, expr.value );
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheDelete;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE STATS                                  (built-in function)
--
-- AdaScript Syntax: s := memcache.stats( cl )
--       Ada Target: PegaSock.Memcache.Stats
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.stats
-----------------------------------------------------------------------------

procedure ParseMemcacheStats( result : out storage; kind : out identifier ) is
  cluster_entry : aMemcacheClusterEntry;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_stats_t;
begin
  kind := string_t;
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseSingleInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster )then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Stats( cluster_entry.cluster, result.value );
              result.unitMetaTag := noMetaTag;
              result.policyMetaTags := cluster.policyMetaTags;
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheStats;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE STATS                                  (built-in function)
--
-- AdaScript Syntax: s := version( cl )
--       Ada Target: PegaSock.Memcache.Version
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.version
-----------------------------------------------------------------------------

procedure ParseMemcacheVersion( result : out storage; kind : out identifier ) is
  cluster_entry : aMemcacheClusterEntry;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_version_t;
begin
  kind := string_t;
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseSingleInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster )then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              result := nullStorage;
              pegasock.memcache.Version( cluster_entry.cluster, result.value );
              result.policyMetaTags := cluster.policyMetaTags;
              memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheVersion;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE FLUSH                                 (built-in procedure)
--
-- AdaScript Syntax: flush( cl )
--       Ada Target: PegaSock.Memcache.Flush
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#flush
-----------------------------------------------------------------------------

procedure ParseMemcacheFlush is
-- Syntax: flush( cluster )
-- Source: pegasock.memcache.flush
  cluster_entry : aMemcacheClusterEntry;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := memcache_flush_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseSingleInOutParameter( subprogramId, clusterRef, memcache_cluster_t  );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster )then
        declare
           theCluster : constant aMemcacheClusterID := aMemcacheClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Flush( cluster_entry.cluster );
             memcacheClusterList.Replace( memcacheCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseMemcacheFlush;


----------------------------------------------------------------------------
-- PARSE THE MEMCACHE HIGHREAD PACKAGE
----------------------------------------------------------------------------


-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD NEW CLUSTER                   (built-in function)
--
-- AdaScript Syntax: cl := new_cluster
--       Ada Target: N/A
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.new_cluster
-----------------------------------------------------------------------------

procedure ParseHighreadNewCluster( result : out storage; kind : out identifier ) is
  cluster_entry : aMemcacheDualClusterEntry;
  cluster_id_value : aMemcacheDualClusterID;
  subprogramId : constant identifier := highread_new_cluster_t;
begin
  kind := highread_cluster_t;
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  checkMemcacheRestriction;
  if isExecutingCommand then
     begin
        cluster_id_value := memcacheDualClusterIdTop;
        memcacheDualClusterIdTop := memcacheDualClusterIdTop + 1;
        cluster_entry.id := cluster_id_value;
        memcacheDualClusterList.Queue( memcacheDualCluster, cluster_entry );
        result := storage'( to_unbounded_string( numericValue( cluster_id_value ) ), noMetaTag, sparMetaTags );
     exception when others =>
        err_exception_raised;
     end;
  end if;
end ParseHighreadNewCluster;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD REGISTER ALPHA SERVER        (built-in procedure)
--
-- AdaScript Syntax: register_alpha_server( cl, h, p )
--       Ada Target: PegaSock.Memcache.Highread.RegisterAlphaServer
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.register_alpha_server
-----------------------------------------------------------------------------

procedure ParseHighreadRegisterAlphaServer is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_register_alpha_server_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastNumericParameter( subprogramId, expr2, expr_type2, natural_t );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           port : constant natural := natural( to_numeric( expr2.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              RegisterAlphaServer( cluster_entry.cluster, expr.value, port );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadRegisterAlphaServer;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD REGISTER BETA SERVER         (built-in procedure)
--
-- AdaScript Syntax: register_beta_server( cl, h, p )
--       Ada Target: PegaSock.Memcache.Highread.RegisterBetaServer
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.register_beta_server
-----------------------------------------------------------------------------

procedure ParseHighreadRegisterBetaServer is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_register_beta_server_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastNumericParameter( subprogramId, expr2, expr_type2, natural_t );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           port : constant natural := natural( to_numeric( expr2.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              RegisterBetaServer( cluster_entry.cluster, expr.value, port );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadRegisterBetaServer;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD CLEAR SERVERS                (built-in procedure)
--
-- AdaScript Syntax: clear_server( cl, h, p )
--       Ada Target: PegaSock.Memcache.Highread.ClearServers
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.clear_servers
-----------------------------------------------------------------------------

procedure ParseHighreadClearServers is
  cluster_entry : aMemcacheDualClusterEntry;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_clear_servers_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseSingleInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              ClearServers( cluster_entry.cluster );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadClearServers;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD SET CLUSTER NAME             (built-in procedure)
--
-- AdaScript Syntax: set_cluster_name( cl, s )
--       Ada Target: PegaSock.Memcache.Highread.SetClusterName
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.set_cluster_name
-----------------------------------------------------------------------------

procedure ParseHighreadSetClusterName is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_set_cluster_name_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseLastStringParameter( subprogramId, expr, expr_type, string_t );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster, expr ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              SetClusterName( cluster_entry.cluster, expr.value );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadSetClusterName;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD SET CLUSTER TYPE             (built-in procedure)
--
-- AdaScript Syntax: set_cluster_type( cl, e )
--       Ada Target: PegaSock.Memcache.Highread.SetClusterType
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.set_cluster_type
--          Example: memcache.highread.set_cluster_type( c, memcache.memcache_cluster_type.normal )
-----------------------------------------------------------------------------

procedure ParseHighreadSetClusterType is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  clusterRef : reference;
  cluster    : storage;
  mct : aMemcacheClusterType;
  subprogramId : constant identifier := highread_set_cluster_type_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseLastEnumParameter( subprogramId, expr, expr_type, memcache_cluster_type_t );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster, expr ) then
        begin
           mct := aMemcacheClusterType'val( natural( to_numeric( expr.value ) ) );
        exception when constraint_error =>
           err( +"constraint error" );
        when others =>
           err_exception_raised;
        end;
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              SetClusterType( cluster_entry.cluster, mct );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadSetClusterType;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD SET                          (built-in procedure)
--
-- AdaScript Syntax: set( cl, k, v )
--       Ada Target: PegaSock.Memcache.Highread.Set
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.set
-----------------------------------------------------------------------------

procedure ParseHighreadSet is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_set_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Set( cluster_entry.cluster, expr.value, expr2.value );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadSet;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD SET                          (built-in procedure)
--
-- AdaScript Syntax: add( cl, k, v )
--       Ada Target: PegaSock.Memcache.Highread.Add
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.add
-----------------------------------------------------------------------------

procedure ParseHighreadAdd is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_add_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Add( cluster_entry.cluster, expr.value, expr2.value );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadAdd;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD REPLACE                      (built-in procedure)
--
-- AdaScript Syntax: replace( cl, k, v )
--       Ada Target: PegaSock.Memcache.Highread.Replace
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.replace
-----------------------------------------------------------------------------

procedure ParseHighreadReplace is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_replace_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Replace( cluster_entry.cluster, expr.value, expr2.value );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadReplace;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD APPEND                       (built-in procedure)
--
-- AdaScript Syntax: append( cl, k, v )
--       Ada Target: PegaSock.Memcache.Highread.Append
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.append
-----------------------------------------------------------------------------

procedure ParseHighreadAppend is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_append_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Append( cluster_entry.cluster, expr.value, expr2.value );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadAppend;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD PREPEND                      (built-in procedure)
--
-- AdaScript Syntax: prepend( cl, k, v )
--       Ada Target: PegaSock.Memcache.Highread.Prepend
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.prepend
-----------------------------------------------------------------------------

procedure ParseHighreadPrepend is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  expr2 : storage;
  expr_type2 : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_prepend_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseNextStringParameter( subprogramId, expr, expr_type );
  ParseLastStringParameter( subprogramId, expr2, expr_type2 );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) and metaTagOk( subprogramId, cluster, expr2 ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Prepend( cluster_entry.cluster, expr.value, expr2.value );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadPrepend;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD GET                           (built-in function)
--
-- AdaScript Syntax: v := get( cl, k )
--       Ada Target: PegaSock.Memcache.Highread.Get
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.get
-----------------------------------------------------------------------------

procedure ParseHighreadGet( result : out storage; kind : out identifier ) is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_get_t;
begin
  kind := string_t;
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseLastStringParameter( subprogramId, expr, expr_type );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              result := nullStorage;
              Get( cluster_entry.cluster, expr.value, result.value );
              result.policyMetaTags := sparMetaTags;
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadGet;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD DELETE                       (built-in procedure)
--
-- AdaScript Syntax: delete( cl, k )
--       Ada Target: PegaSock.Memcache.Highread.Delete
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.delete
-----------------------------------------------------------------------------

procedure ParseHighreadDelete is
  cluster_entry : aMemcacheDualClusterEntry;
  expr : storage;
  expr_type : identifier;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_delete_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseFirstInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  ParseLastStringParameter( subprogramId, expr, expr_type );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster ) and metaTagOk( subprogramId, expr ) then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Delete( cluster_entry.cluster, expr.value );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadDelete;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD STATS                         (built-in function)
--
-- AdaScript Syntax: s := stats( cl )
--       Ada Target: PegaSock.Memcache.Highread.Stats
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.stats
-----------------------------------------------------------------------------

procedure ParseHighreadStats( result : out storage; kind : out identifier ) is
  cluster_entry : aMemcacheDualClusterEntry;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_stats_t;
begin
  kind := string_t;
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseSingleInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster )then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              result := nullStorage;
              Stats( cluster_entry.cluster, result.value);
              result.policyMetaTags := cluster.policyMetaTags;
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadStats;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD VERSION                       (built-in function)
--
-- AdaScript Syntax: s := version( cl )
--       Ada Target: PegaSock.Memcache.Highread.Version
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.version
-----------------------------------------------------------------------------

procedure ParseHighreadVersion( result : out storage; kind : out identifier ) is
  cluster_entry : aMemcacheDualClusterEntry;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_version_t;
begin
  kind := string_t;
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseSingleInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster )then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              result := nullStorage;
              pegasock.memcache.highread.Version( cluster_entry.cluster, result.value );
              result.policyMetaTags := cluster.policyMetaTags;
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when constraint_error =>
           err( +"no memcache servers registered" );
        when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadVersion;

-----------------------------------------------------------------------------
--  PARSE MEMCACHE HIGHREAD FLUSH                        (built-in procedure)
--
-- AdaScript Syntax: flush( cl )
--       Ada Target: PegaSock.Memcache.Highread.Flush
--   GNAT Spec File: N/A
--   SparForte Docs: pkg_memcache.html#memcache.highread.flush
-----------------------------------------------------------------------------

procedure ParseHighreadFlush is
  cluster_entry : aMemcacheDualClusterEntry;
  clusterRef : reference;
  cluster    : storage;
  subprogramId : constant identifier := highread_flush_t;
begin
  expectNonRestrictedShell( subprogramId );
  expect( subprogramId );
  ParseSingleInOutParameter( subprogramId, clusterRef, highread_cluster_t  );
  checkMemcacheRestriction;
  if isExecutingCommand then
     getParameterValue( clusterRef, cluster );
     if metaTagOk( subprogramId, cluster )then
        declare
           theCluster : constant aMemcacheDualClusterID := aMemcacheDualClusterID( to_numeric( cluster.value ) );
           clusterIndex : memcacheDualClusterList.aListIndex;
        begin
           GetCluster( theCluster, cluster_entry, clusterIndex );
           if clusterIndex /= 0 then
              Flush( cluster_entry.cluster );
              memcacheDualClusterList.Replace( memcacheDualCluster, clusterIndex, cluster_entry );
           end if;
        exception when others =>
           err_exception_raised;
        end;
     end if;
  end if;
end ParseHighreadFlush;


-----------------------------------------------------------------------------
-- HOUSEKEEPING
-----------------------------------------------------------------------------


procedure StartupMemcache is
begin
  -- Memcache Package identifiers
  declareNamespace( "memcache" );
  declareIdent( memcache_cluster_t, "memcache.memcache_cluster", long_integer_t, typeClass );
  -- identifiers( memcache_cluster_t ).usage := limitedUsage;
  -- identifiers( memcache_cluster_t ).resource := true;
  declareIdent( memcache_cluster_type_t, "memcache.memcache_cluster_type", root_enumerated_t, typeClass );
  declareStandardConstant( memcache_cluster_type_normal_t, "memcache.memcache_cluster_type.normal", memcache_cluster_type_t, "0" );

  declareFunction(  memcache_is_valid_memcache_key_t, "memcache.is_valid_memcache_key", ParseMemcacheIsValidMemcacheKey'access );
  declareFunction( memcache_new_cluster_t, "memcache.new_cluster", ParseMemcacheNewCluster'access  );
  declareProcedure( memcache_register_server_t, "memcache.register_server", ParseMemcacheRegisterServer'access );
  declareProcedure( memcache_clear_servers_t, "memcache.clear_servers", ParseMemcacheClearServers'access );
  declareProcedure( memcache_set_cluster_name_t, "memcache.set_cluster_name", ParseMemcacheSetClusterName'access );
  declareProcedure( memcache_set_cluster_type_t, "memcache.set_cluster_type", ParseMemcacheSetClusterType'access );
  declareProcedure( memcache_set_t, "memcache.set", ParseMemcacheSet'access );
  declareProcedure( memcache_add_t, "memcache.add", ParseMemcacheAdd'access );
  declareProcedure( memcache_replace_t, "memcache.replace", ParseMemcacheReplace'access );
  declareProcedure( memcache_append_t, "memcache.append", ParseMemcacheAppend'access );
  declareProcedure( memcache_prepend_t, "memcache.prepend", ParseMemcachePrepend'access );
  declareFunction(  memcache_get_t, "memcache.get", ParseMemcacheGet'access );
  declareProcedure( memcache_delete_t, "memcache.delete", ParseMemcacheDelete'access );
  declareFunction(  memcache_stats_t, "memcache.stats", ParseMemcacheStats'access );
  declareFunction(  memcache_version_t, "memcache.version", ParseMemcacheVersion'access );
  declareProcedure( memcache_flush_t, "memcache.flush", ParseMemcacheFlush'access );

  declareIdent( highread_cluster_t, "memcache.highread.memcache_dual_cluster", long_integer_t, typeClass );
  -- identifiers( highread_cluster_t ).usage := limitedUsage;
  -- identifiers( highread_cluster_t ).resource := true;

  declareFunction(  highread_new_cluster_t, "memcache.highread.new_cluster", ParseHighreadNewCluster'access );
  declareProcedure( highread_register_alpha_server_t, "memcache.highread.register_alpha_server", ParseHighreadRegisterAlphaServer'access );
  declareProcedure( highread_register_beta_server_t, "memcache.highread.register_beta_server", ParseHighreadRegisterBetaServer'access );
  declareProcedure( highread_clear_servers_t, "memcache.highread.clear_servers", ParseHighreadClearServers'access );
  declareProcedure( highread_set_cluster_name_t, "memcache.highread.set_cluster_name", ParseHighreadSetClusterName'access );
  declareProcedure( highread_set_cluster_type_t, "memcache.highread.set_cluster_type", ParseHighreadSetClusterType'access );
  -- TODO: Nested namespaces have not been tested.
  -- declareNamespace( "memcache.highread" );
  declareProcedure( highread_set_t, "memcache.highread.set", ParseHighreadSet'access );
  declareProcedure( highread_add_t, "memcache.highread.add", ParseHighreadAdd'access );
  declareProcedure( highread_replace_t, "memcache.highread.replace", ParseHighreadReplace'access );
  declareProcedure( highread_append_t, "memcache.highread.append", ParseHighreadAppend'access );
  declareProcedure( highread_prepend_t, "memcache.highread.prepend", ParseHighreadPrepend'access );
  declareFunction(  highread_get_t, "memcache.highread.get", ParseHighreadGet'access );
  declareProcedure( highread_delete_t, "memcache.highread.delete", ParseHighreadDelete'access );
  declareFunction(  highread_stats_t, "memcache.highread.stats", ParseHighreadStats'access );
  declareFunction(  highread_version_t, "memcache.highread.version", ParseHighreadVersion'access );
  declareProcedure( highread_flush_t, "memcache.highread.flush", ParseHighreadFlush'access );
  -- declareNamespaceClosed( "memcache.highread" );
  declareNamespaceClosed( "memcache" );
end StartupMemcache;

procedure ShutdownMemcache is
begin

  -- Deallocate memory for all memcache clusters

  declare
    clusterEntry : aMemcacheClusterEntry;
  begin
    while not memcacheClusterList.isEmpty( memcacheCluster ) loop
      memcacheClusterList.Pull( memcacheCluster, clusterEntry );
      ClearServers( clusterEntry.cluster );
    end loop;
  end;

  -- Deallocate memory for all memcache highread dual clusters

  declare
    clusterEntry : aMemcacheDualClusterEntry;
  begin
    while not memcacheDualClusterList.isEmpty( memcacheDualCluster ) loop
      memcacheDualClusterList.Pull( memcacheDualCluster, clusterEntry );
      ClearServers( clusterEntry.cluster );
    end loop;
  end;

end ShutdownMemcache;

end parser_memcache;
