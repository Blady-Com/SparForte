------------------------------------------------------------------------------
-- Scanner Resources                                                        --
--                                                                          --
-- Part of SparForte                                                        --
------------------------------------------------------------------------------
--                                                                          --
--            Copyright (C) 2001-2013 Free Software Foundation              --
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

with ada.text_io, scanner;
use  ada.text_io, scanner;

package body scanner_res is

-- a list of resource handles.  the sort isn't used.

resHandles : resHandleList.List;

function resSort( left, right : resPtr ) return boolean is
begin
  return left.blocklvl < right.blocklvl; -- we don't care
end resSort;

function to_unbounded_string( id : resHandleID ) return unbounded_string is
begin
  return to_unbounded_string( long_float'image( long_float( id ) ) );
end to_unbounded_string;

function to_resource_id( val : unbounded_string ) return resHandleID is
  valAsLongFloat : long_float;
begin
  valAsLongFloat := long_float'value( to_string( val ) );
  return resHandleID( valAsLongFloat  );
end to_resource_id;

------------------------------------------------------------------------------

--  DECLARE RESOURCE
--
-- Allocate a new resource record of the given type.  Record the block level
-- so it will be deallocated when that block is pulled from the scanner's
-- block table.  Returns 0 if the resource could not be allocated.
-----------------------------------------------------------------------------

procedure declareResource( id : out resHandleID; rt : aResourceType; blocklvl : block ) is
  rp : resPtr;
begin
  rp := new resHandle( rt );
  rp.blocklvl := blocklvl;
  begin
    resHandleList.Queue( resHandles, rp );
  exception when storage_error =>
      err( "out of memory" );
      id := 0;
      return;
  end;
  id := resHandleID( resHandleList.length( resHandles ) );
  if trace then
     put_trace( "Declared resource handle #" & id'img & " as a " & rt'img );
     put_trace( "There are" & resHandleList.length( resHandles )'img & " resource handles declared" );
  end if;
  exception when storage_error =>
      err( "out of memory" );
      id := 0;
      return;
end declareResource;

--  FIND RESOURCE
--
-- Search for a resource and return a pointer to it.  For a resource, it's
-- the position in the list indicated by the id number.
-----------------------------------------------------------------------------

procedure findResource( id : resHandleID; rp : out resPtr ) is
begin
  resHandleList.Find( resHandles, resHandleList.aListIndex( id ), rp );
end findResource;

--  SAVE RESOURCE
--
-- Save a resource, replacing the pointer was in the list.  It will not
-- free the memory if the pointer changes
-----------------------------------------------------------------------------

--procedure saveResource( id : resHandleID; rp : in resPtr ) is
--begin
--  resHandleList.Replace( resHandles, id, rp );
--end saveResource;

--  PUT RESOURCE
--
-- Display information about a resource.  For debugging.
-----------------------------------------------------------------------------

procedure putResource( rp : resPtr ) is
begin
  case rp.rt is
  when mysql_connection =>
       put_line( "mysql connection" );
  when mysql_query =>
       put_line( "mysql query" );
  when postgresql_connection =>
       put_line( "postgresql connection" );
  when postgresql_query =>
       put_line( "postgresql query" );
  when memcache_connection =>
       put_line( "memcache connection" );
  when pen_canvas =>
       put_line( "pen canvas" );
  when none =>
       put_line( "undefined resource" );
  when others =>
       put_line( "internal error: unexpected resource" );
  end case;
end putResource;

--procedure declareArray( id : out arrayID; name : unbounded_string;
--  first, last : long_integer;
--  ind : identifier; blocklvl : block ) is
--  b   : bushArray;
--  lastElement : arrayElementID;
--  -- create a new array
--begin
--  b.name := name;
--  b.blocklvl := blocklvl;
--  b.firstIndex := first;
--  b.lastIndex := last;
--  b.indType := ind;
--  if first <= last then
--     b.offset := arrayElementID( stringList.length( arrayElements )+1 );
--  else
--     b.offset := 0;
--  end if;
--  begin
--    arrayList.Queue( bushArrays, b );
--  exception when storage_error =>
--      err( "out of memory" );
--      id := 0;
--      return;
--  end;
--  id := arrayID( arrayList.length( bushArrays ) );
--  for i in 1..last-first+1 loop
--      stringList.Queue( arrayElements, Null_Unbounded_String );
--  end loop;
--  if trace then
--     put_trace( to_string( name ) & " declared as array #" & id'img );
--     put_trace( "There are" & stringList.length( arrayElements )'img & " array elements declared by all arrays" );
--  end if;
--  exception when storage_error =>
--      err( "out of memory" );
--      lastElement := arrayElementID( stringList.length( arrayElements ) );
--      for i in b.offset..lastElement loop
--          stringList.Clear( arrayElements, stringList.AListIndex( i ) );
--      end loop;
--      b.offset := 0;
--      id := 0;
--      return;
--end declareArray;

procedure clearResource( id : resHandleID ) is
  rp : resPtr;
begin
  -- TODO: free handle
  resHandleList.find( resHandles, resHandleList.aListIndex( id ), rp );
  if rp.rt = mysql_connection then
     if APQ.MySQL.Client.is_trace( rp.C ) then
        APQ.MySQL.Client.close_Db_Trace( rp.C );
     end if;
     if APQ.MySQL.Client.is_connected( rp.C ) then
        APQ.MySQL.Client.disconnect( rp.C );
     end if;
  elsif rp.rt = mysql_query then
     Free( rp );
  end if;
  resHandleList.clear( resHandles, long_integer( id ) );
end clearResource;

--procedure clearArray( id : arrayID ) is
---- delete an array and deallocate any memory
--  b : bushArray;
--begin
--  b.offset := arrayElementID'last;
--  arrayList.Find( bushArrays, long_integer( id ), b );
--  if b.offset = arrayElementID'last then
--     err( "internal error: destroyArray: already destroyed or bad id" );
--     return;
--  end if;
--  if not b.isType then
--     if b.lastIndex >= b.firstIndex then
--        for i in reverse b.offset..b.offset+arrayElementID( b.lastIndex-b.firstIndex) loop
--            stringList.Clear( arrayElements, stringList.AListIndex( i ) );
--        end loop;
--     end if;
--  end if;
--  -- Deleting the array record will change the array index numbers since
--  -- we are using linked lists.
--  -- arrayList.clear( bushArrays, long_integer( id ) );
--  if trace then
--     put_trace( "There are" & stringList.length( arrayElements )'img & " remaining array elements declared by all arrays" );
--  end if;
--end clearArray;

procedure pullResourceBlock( blocklvl : block ) is
  rp : resPtr;
begin
  for i in reverse 1..resHandleList.length( resHandles ) loop  -- look thru arrays
      resHandleList.Find( resHandles, i, rp );               -- next array
      exit when rp.blocklvl < blocklvl;                      -- completed block?
      -- TODO: destroy handle
      resHandleList.Clear( resHandles, i );                  -- destroy array rec
      if trace then
         put_trace( "resource handle" & i'img & " deallocated" );
      end if;
  end loop;
  if trace then
     put_trace( "There are" & resHandleList.length( resHandles )'img & " resources allocated" );
  end if;
end pullResourceBlock;

--procedure pullArrayBlock( blocklvl : block ) is
---- called by scanner.pullBlock, discard all arrays and memory declared
---- by them.
--  b : bushArray;
--  best : bushArray;
--  lastElement : arrayElementID;
--begin
--  best.offset := 0;                                        -- assume none
--  for i in reverse 1..arrayList.length( bushArrays ) loop  -- look thru arrays
--      arrayList.Find( bushArrays, i, b );                  -- next array
--      exit when b.blocklvl < blocklvl;                     -- completed block?
--      if b.offset > 0 then                                 -- not a null array?
--         best := b;                                        -- delete this too
--      end if;
--      arrayList.Clear( bushArrays, i );                    -- destroy array rec
--      if trace then
--         put_trace( to_string( b.name ) & " array deallocated" );
--      end if;
--  end loop;
--  if best.offset > 0 then                                  -- dealloc elements
     --put_trace( "Starting with array " & to_string( best.name ) );
     --put_trace( "First element to be discarded is" & best.offset'img );
     --put_trace( "Last element to be discarded is" & stringList.length( arrayElements )'img );
--     lastElement := arrayElementID( stringList.length( arrayElements ) );
--     for e in reverse best.offset..lastElement loop
--         stringList.Clear( arrayElements, stringList.AListIndex( e ) );
--     end loop;
--  end if;
--  if trace then
--     put_trace( "There are" & stringList.length( arrayElements )'img & " array elements declared by all arrays" );
--  end if;
--end pullArrayBlock;

end scanner_res;
