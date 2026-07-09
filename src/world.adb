------------------------------------------------------------------------------
-- Common declarations across most of SparForte including command line      --
-- switches and global variables and constants.  This is the lowest-level   --
-- of the SparForte ecosystem and has minimum dependencies.                 --
-- The symbol table used to be here but is now in a separate file.          --
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
-- This is maintained at http://www.pegasoft.ca                             --
--                                                                          --
------------------------------------------------------------------------------
pragma ada_2005;

with ada.text_io,
    gnat.source_info,
    pegasoft.strings,
    pegasoft.user_io;
use ada.text_io,
    pegasoft.strings,
    pegasoft.user_io;

package body world is

-----------------------------------------------------------------------------
--
-- Storage Primitives
--
-- Utilities for storage aggregate types.
--
-----------------------------------------------------------------------------


--  VALUE EQUAL
--
-- True if the value fields of two storage records are equal.
-----------------------------------------------------------------------------

function value_equal( left, right : storage ) return boolean is
begin
  return left.value = right.value;
end value_equal;

--  META TAG SET HASH
--
-- Return the meta tag hash set for e.
-----------------------------------------------------------------------------

function metaTagSetHash( e : metaTagID ) return ada.containers.hash_type is
begin
  return ada.containers.hash_type( e );
end metaTagSetHash;


--  IS EXECUTING COMMAND
--
-- True if OK to execute a statement that does work.
-- That is, the parser isn't skipping the line because of
-- an error or exiting a block.
-----------------------------------------------------------------------------

function isExecutingCommand return boolean is
begin
  return not error_found and not exit_block and not syntax_check;
end isExecutingCommand;

-- The same, but can run during syntax checking.  Used for static
-- expressions.

function isExecutingStaticCommand return boolean is
begin
  return not error_found and not exit_block and not
     (interpreterPhase = executing and syntax_check);
end isExecutingStaticCommand;


-----------------------------------------------------------------------------
--
-- STORAGE CACHE
--
-- Allocating/deallocating memory is a slow operation.
--
-- To make slightly better use of allocated storage memory, instead of
-- freeing the last storage pointer, store it here so it can be reused.
--
-- This is the same technique I used in my single-linked list library.
--
-- Since only arrays currently use storage pointers, this only affects arrays.
-- I didn't see much of a speed improvement.
--
-----------------------------------------------------------------------------

storageCache     : storageGroupPtr := null;
storageCacheMiss : natural := 0;

--  FIND STORAGE
--
-- Allocate storage space (or get it from the cache) and return a
-- pointer to it.  If what is in the cache is missed three times,
-- forcibly discard it.
-----------------------------------------------------------------------------

function findStorage( lbound, ubound : long_integer ) return storageGroupPtr is
  sp : storagegroupPtr;
begin
  if storageCache = null then
     sp := new StorageGroup( lbound..ubound );
     storageCacheMiss := 0;
  else
     if storageCacheMiss >= 3 then
        free( storageCache );
        storageCache := null;
        storageCacheMiss := 0;
     elsif storageCache'first = lbound and
           storageCache'last = ubound then
        sp := storageCache;
        storageCache := null;
        storageCacheMiss := 0;
     else
        sp := new StorageGroup( lbound..ubound );
        storageCacheMiss := storageCacheMiss + 1;
     end if;
  end if;
  return sp;
end findStorage;


-----------------------------------------------------------------------------
--
-- Passing Modes primitives
--
-----------------------------------------------------------------------------


--  TO STRING
--
-- Return the string image of a parameter passing mode enumerated type item.
-- An unexpected mode raises a SPARFORTE_ERROR.
-----------------------------------------------------------------------------

function to_string( mode : aParameterPassingMode ) return string is
begin
  case mode is
     when none =>
        return "none";
     when in_mode =>
        return "in";
     when out_mode =>
        return "out";
     when in_out_mode =>
        return "in out";
     when others =>
         -- at the world level, raise exceptions on errors because there is
         -- no access to error functionality
         raise SPARFORTE_ERROR with Gnat.Source_Info.Source_Location &
          ": internal error: unexpected mode " & mode'img;
  end case;
end to_string;


-----------------------------------------------------------------------------
--
-- Shell Word Primitives
--
-----------------------------------------------------------------------------


function ">"( left, right : aShellWord ) return boolean is
begin
  return left.word > right.word;
end ">";


-----------------------------------------------------------------------------
--
-- Source File Primitives
--
-----------------------------------------------------------------------------


function ">="( left, right : aSourceFile ) return boolean is
begin
  return left.name >= right.name;
end ">=";

function equal( left, right : aSourceFile ) return boolean is
begin
  return left.pos = right.pos;
end equal;

-----------------------------------------------------------------------------
--
-- Memcache Initialization
--
-----------------------------------------------------------------------------

--  Memcache Initialization flags
--
-- These are flags to ensure that the shared Memcache clusters only initialize
-- once.

localMemcacheClusterInitialized : boolean := false;
distributedMemcacheClusterInitialized : boolean := false;

--  CHECK AND INITIALIZE LOCAL MEMCACHE CLUSTER
--
-- If a shared local memcache cluster is not initialized, initialize it.
-- The default is for a memcache running on localhost.
-----------------------------------------------------------------------------

procedure checkAndInitializeLocalMemcacheCluster is
begin
  if not localMemcacheClusterInitialized then
     localMemcacheClusterInitialized := true;
     RegisterServer( localMemcacheCluster, DEFAULT_MEMCACHE_HOST, DEFAULT_MEMCACHE_PORT );
     SetClusterName( localMemcacheCluster, to_unbounded_string( "Local Memcache" ) );
     SetClusterType( localMemcacheCluster, normal );
  end if;
end checkAndInitializeLocalMemcacheCluster;

--  CHECK AND INITIALIZE DISTRIBUTED MEMCACHE CLUSTER
--
-- If a shared distributed memcache cluster is not initialized, initialize it
-----------------------------------------------------------------------------

procedure checkAndInitializeDistributedMemcacheCluster is
begin
  if not distributedMemcacheClusterInitialized then
     distributedMemcacheClusterInitialized := true;
     SetClusterName( distributedMemcacheCluster, to_unbounded_string( "Distributed Memcache" ) );
     SetClusterType( distributedMemcacheCluster, normal );
  end if;
end checkAndInitializeDistributedMemcacheCluster;


-----------------------------------------------------------------------------
--
-- Identifier Class primitives
--
-----------------------------------------------------------------------------


--  GET IDENTIFIER CLASS NAME
--
-- Return an image string description of the class enumerated item
-----------------------------------------------------------------------------

function getIdentifierClassImage( c : anIdentifierClass ) return string is
begin
  case c is
  when subClass         => return "subtype";
  when typeClass        => return "type";
  when funcClass        => return "built-in function";
  when userFuncClass    => return "user-defined function";
  when procClass        => return "built-in procedure";
  when userProcClass    => return "user-defined procedure";
  when taskClass        => return "task";
  when mainProgramClass => return "main program";
  when exceptionClass   => return "exception";
  when varClass         => return "variable";
  when namespaceClass   => return "namespace";
  when enumClass        => return "enumerated item";
  when policyClass      => return "policy block";
  when configurationClass => return "configuration block";
  when genericTypeClass => return "generic type";
  when formalParamClass => return "formal parameter";
  when userCaseProcClass => return "user-defined case procedure";
  when unitMetaClass     => return "unit-of-measure value meta label";
  when policyMetaClass   => return "policy value meta label";
  when otherClass       => return "other class";
  end case;
end getIdentifierClassImage;


-----------------------------------------------------------------------------
--
-- Template Primitives
--
-----------------------------------------------------------------------------


--  PUT TEMPLATE HEADER
--
-- Output the template header.  Mark it as sent so it isn't sent
-- twice.  This will likely be replaced in the future.
--
-- A bad status results in HTTP 500.  A bad content type results in text.
-- In both cases, a message is written to standard error.
--
-- An unknown template type raises SPARFORTE_ERROR.
-----------------------------------------------------------------------------

procedure putTemplateHeader( header : in out templateHeaders ) is
  s : unbounded_string;
begin

  -- If the HTTP header has already been written, do not write another one.

  if header.templateHeaderSent then
     return;
  end if;
  header.templateHeaderSent := true;

  -- CGI programs cannot directly return HTTP 404.  e.g. this is bad:
  -- s := to_unbounded_string( "HTTP/1.1" & header.status'img & " " );
  --
  -- Fill in the HTTP response header Status field.  Add a standard
  -- HTTP status string based on the HTTP status number.

  s := to_unbounded_string( "Status:" & header.status'img & " " );
  case header.status is
  when 100 => s := s & "Continue";
  when 200 => s := s & "OK";
  when 201 => s := s & "Created";
  when 202 => s := s & "Accepted";
  when 203 => s := s & "Non-Authoritative";
  when 204 => s := s & "No Content";
  when 205 => s := s & "Reset Content";
  when 206 => s := s & "Partial Content";
  when 300 => s := s & "Multiple Choices";
  when 301 => s := s & "Moved Permanently";
  when 302 => s := s & "Found";
  when 303 => s := s & "See Other";
  when 304 => s := s & "Not Modified";
  when 305 => s := s & "Use Proxy";
  when 307 => s := s & "Temporary Redirect";
  when 400 => s := s & "Bad Request";
  when 401 => s := s & "Unauthorized";
  when 403 => s := s & "Forbidden";
  when 404 => s := s & "Not Found";
  when 405 => s := s & "Method Not Allowed";
  when 406 => s := s & "Not Acceptable";
  when 407 => s := s & "Proxy Authentication Required";
  when 408 => s := s & "Request Timeout";
  when 409 => s := s & "Conflict";
  when 410 => s := s & "Gone";
  when 411 => s := s & "Length Required";
  when 412 => s := s & "Precondition Failed";
  when 413 => s := s & "Request Entity Too Large";
  when 414 => s := s & "Request-URI Too Long";
  when 415 => s := s & "Unsupported Media Type";
  when 416 => s := s & "Requested Range Not Satisfiable";
  when 417 => s := s & "Expectation Failed";
  when 500 => s := s & "Internal Server Error";
  when 501 => s := s & "Not Implemented";
  when 502 => s := s & "Bad Gateway";
  when 503 => s := s & "Service Unavailable";
  when 504 => s := s & "Gateway Timeout";
  when 505 => s := s & "HTTP Version Not Supported";
  when others =>
    -- at the world level, raise exceptions on errors because there is
    -- no access to error functionality
    raise SPARFORTE_ERROR with Gnat.Source_Info.Source_Location &
      ": Internal error: unknown HTTP status" & header.status'img;
  end case;
  s := s & ASCII.CR & ASCII.LF;

  -- Create the HTTP Content-type response header field based on the type of
  -- template

  s := s & to_unbounded_string( "Content-type: " );
  case header.templateType is
  when htmlTemplate => s := s & "text/html";
  when cssTemplate  => s := s & "text/css";
  when jsTemplate   => s := s & "application/x-javascript";
  when jsonTemplate => s := s & "application/json";
  when textTemplate => s := s & "text/plain";
  when xmlTemplate  => s := s & "text/xml";
  when wmlTemplate  => s := s & "text/vnd.wap.wml";
  when yamlTemplate => s := s & "text/yaml";
  when tomlTemplate => s := s & "text/toml"; -- no offical type
  when others => -- includes placeholder template type noTemplate
    -- at the world level, raise exceptions on errors because there is
    -- no access to error functionality
     raise SPARFORTE_ERROR with Gnat.Source_Info.Source_Location &
       ": internal error: unknown template type " &
       header.templateType'img;
  end case;
  s := s & ASCII.CR & ASCII.LF;

  -- Other HTTP response fields (to be filled in later)

  if length( header.contentLength ) > 0 then
     s := s & "Content-length: " & header.contentLength & ASCII.CR & ASCII.LF;
  end if;

  if length( header.expires ) > 0 then
     s := s & "Expires: " & header.expires & ASCII.CR & ASCII.LF;
  end if;

  if length( header.location ) > 0 then
     s := s & "Location: " & header.location & ASCII.CR & ASCII.LF;
  end if;

  if length( header.pragmaString ) > 0 then
     s := s & "Pragma: " & header.pragmaString & ASCII.CR & ASCII.LF;
  end if;

  if length( header.cookieString ) > 0 then
     s := s & "Set-Cookie: " & header.pragmaString & ASCII.CR & ASCII.LF;
  end if;

  -- The HTTP header ends with a blank line

  put_retry( s & ASCII.CR & ASCII.LF );

end putTemplateHeader;


-----------------------------------------------------------------------------
--
-- Misc. Output Functions
--
-----------------------------------------------------------------------------


--  PUT TRACE
--
-- Display an escaped message to standard error in the format used when
-- "trace true" is used.  This does not check the tracing flag: the caller
-- should do this if necessary.  Coloured output and an optional UTF-8 icon
-- is supported if --colour/-color option is used.
-----------------------------------------------------------------------------

procedure put_trace( msg : string; icon : string := "" ) is
begin
  if icon /= "" and boolean( colourOpt ) then
     put_line_retry( standard_error, adorn_green( to_string( "=> (" & icon & " " & toCtrlEscaped( to_unbounded_string( msg ) ) ) & ")", boolean( colourOpt ) ) );
  else
     put_line_retry( standard_error, adorn_green( to_string( "=> (" & toCtrlEscaped( to_unbounded_string( msg ) ) ) & ")", boolean( colourOpt ) ) );
  end if;
end put_trace;


--  OS ERROR
--
-- Return an OS error message for POSIX error number e.  The return value is
-- an Ada string converted from the NUL terminated C string at ep.
-----------------------------------------------------------------------------

function OSerror( e : integer ) return string is
  lastchar : natural := 0;
  ep       : anErrorPtr;
begin
  ep := strerror( e );
  -- POSIX requires strerror() does not return null.  Check anyway in case
  -- other operating systems do not have this behaviour.
  if ep /= null then
     for i in ep.all'range loop
         if ep(i) = ASCII.NUL then
            lastchar := i-1;
            exit;
         end if;
     end loop;
     return string( ep( 1..lastchar ) );
  end if;
  return "Unknown error";
end OSerror;

end world;
