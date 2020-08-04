
--  PEGASOFT SOCKETS
--
-- Linux/*NIX basic operating system file and socket routines.  The purpose
-- of this package is to work around the differences between C and Ada
-- strings, hide the worst C-specific details and to add exception handling.
-----------------------------------------------------------------------------
pragma ada_2005;

with gnat.source_info,
     ada.unchecked_conversion,
     sf_text_io;
use  sf_text_io;

-- system.os_constants is automatically generated by GCC from your various
-- /usr/include C files.  They contain standard constants like O_TRUNC and
-- SOCK_STREAM, error names, etc.  This is a non-standard library and is
-- not supposed to be with'ed but you may try to use it if you can't find
-- values yourself.
--
-- If you comment this out, comment out the asserts in the package
-- initialization block as well.

pragma warnings( off );
with system.os_constants;
pragma warnings( on );

package body pegasock is

-----------------------------------------------------------------------------
-- CONVERSIONS
-----------------------------------------------------------------------------

type double_byte is array( 1..2 ) of character;
for double_byte'size use wide_character'size;
function wide_to_double_byte is new Ada.Unchecked_Conversion( wide_character, double_byte );
function double_byte_to_wide is new Ada.Unchecked_Conversion( double_byte, wide_character );

type quad_byte is array( 1..4 ) of character;
for quad_byte'size use wide_wide_character'size;
function wide_wide_to_quad_byte is new Ada.Unchecked_Conversion( wide_wide_character, quad_byte );
function quad_byte_to_wide_wide is new Ada.Unchecked_Conversion( quad_byte, wide_wide_character );

lastCharForEOL : constant array( anEOLType ) of character := (
  Ada.Characters.Latin_1.NUL,
  Ada.Characters.Latin_1.LF,
  Ada.Characters.Latin_1.LF,
  Ada.Characters.Latin_1.CR,
  Ada.Characters.Latin_1.CR
);

--  FILL READ BUFFER
--
-- Read up to amount characters and store them in the descriptor's read
-- buffer.  May throw data_error or fileutils_wouldblock.
-----------------------------------------------------------------------------
procedure fillReadBuffer( fd : in out aBufferedFile; amount : size_t ) is
  pragma suppress( range_check );
  pragma suppress( index_check );
begin
  <<retry>> read( fd.amountRead, fd.fd, fd.readBuffer(1)'address, amount );
  if fd.amountRead = 0 then
     fd.EOF := true;
     fd.readPos := integer'last;
  elsif fd.amountRead < 0 or fd.amountRead = size_t'last then  -- ada's def'n of
     if C_pegasock_errno = EINTR then                                   -- size_t is
        goto retry;                                            -- unsigned so
     elsif C_pegasock_errno = EAGAIN or C_pegasock_errno = EWOULDBLOCK then      -- -1 = 'last
        raise fileutils_wouldblock with OSError( C_pegasock_errno );
     end if;
     -- Put_Line( Standard_Error, "Read from file failed" & OSError( C_pegasock_errno ) );
     raise data_error with "Read from file failed" & OSError( C_pegasock_errno );
   end if;
-- Read 0?
   fd.readPos := fd.readBuffer'first;
   pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": read" & fd.amountRead'img & " bytes from file descriptor" & fd.fd'img ) );
end fillReadBuffer;

procedure fillReadBuffer( fd : in out aBufferedSocket; amount : size_t ) is
  pragma suppress( range_check );
  pragma suppress( index_check );
begin
  fd.amountRead := 0;
  <<retry>> read( fd.amountRead, aFileDescriptor( fd.fd ), fd.readBuffer(1)'address, amount );
  if fd.amountRead = 0 then
     fd.EOF := true;
     fd.readPos := integer'last;
  elsif fd.amountRead < 0 or fd.amountRead = size_t'last then  -- ada's def'n of
     if C_pegasock_errno = EINTR then                                   -- size_t is
        goto retry;                                            -- unsigned so
     elsif C_pegasock_errno = EAGAIN or C_pegasock_errno = EWOULDBLOCK then      -- -1 = 'last
        raise fileutils_wouldblock with OSError( C_pegasock_errno );
     end if;
     -- Put_Line( Standard_Error, "Read from file failed" & OSError( C_pegasock_errno ) );
     raise data_error with "Read from file failed" & OSError( C_pegasock_errno );
   end if;
   fd.readPos := fd.readBuffer'first;
   pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": read" & fd.amountRead'img & " bytes from file descriptor" & fd.fd'img ) );
end fillReadBuffer;


--  TRIM EOL
--
-- Remove the end-of-line characters from a string based on the EOL type
-- for a file descriptor.  Used by get functions that return a string.
-----------------------------------------------------------------------------

procedure trimEOL( eolType : anEOLType; s : in out unbounded_string ) is
begin
  if length( s ) = 0 then
     return;
  end if;
  case eolType is
  when NUL =>
    if element( s, length( s ) ) = Ada.Characters.Latin_1.Nul then
       Delete( s, length( s ), length( s ) );
    end if;
  when CRLF =>
    if element( s, length( s ) ) = Ada.Characters.Latin_1.LF then
       Delete( s, length( s ), length( s ) );
    end if;
    if element( s, length( s ) ) = Ada.Characters.Latin_1.CR then
       Delete( s, length( s ), length( s ) );
    end if;
  when CR =>
    if element( s, length( s ) ) = Ada.Characters.Latin_1.CR then
       Delete( s, length( s ), length( s ) );
    end if;
  when LFCR =>
    if element( s, length( s ) ) = Ada.Characters.Latin_1.CR then
       Delete( s, length( s ), length( s ) );
    end if;
    if element( s, length( s ) ) = Ada.Characters.Latin_1.LF then
       Delete( s, length( s ), length( s ) );
    end if;
  when others => -- LF
    if element( s, length( s ) ) = Ada.Characters.Latin_1.LF then
       Delete( s, length( s ), length( s ) );
    end if;
  end case;
end trimEOL;


--  APPEND EOL
--
-- Add the end-of-line characters to a string based on the EOL type
-- for a file descriptor.  Used by put_line functions.
-----------------------------------------------------------------------------

function appendEOL( eolType : anEOLType; s : in unbounded_string ) return unbounded_string is
begin
  case eolType is
  when NUL =>
    return s & Ada.Characters.Latin_1.Nul;
  when CRLF =>
    return s & Ada.Characters.Latin_1.CR & Ada.Characters.Latin_1.LF;
  when CR =>
    return  s & Ada.Characters.Latin_1.CR;
  when LFCR =>
    return s & Ada.Characters.Latin_1.LF & Ada.Characters.Latin_1.CR;
  when others => -- LF
    return s & Ada.Characters.Latin_1.LF;
  end case;
end appendEOL;

function appendEOL( eolType : anEOLType; s : in string ) return string is
begin
  case eolType is
  when NUL =>
    return s & Ada.Characters.Latin_1.Nul;
  when CRLF =>
    return s & Ada.Characters.Latin_1.CR & Ada.Characters.Latin_1.LF;
  when CR =>
    return  s & Ada.Characters.Latin_1.CR;
  when LFCR =>
    return s & Ada.Characters.Latin_1.LF & Ada.Characters.Latin_1.CR;
  when others => -- LF
    return s & Ada.Characters.Latin_1.LF;
  end case;
end appendEOL;


-----------------------------------------------------------------------------
-- UTILITIES
-----------------------------------------------------------------------------


--  SET EOL
--
-- Assign a single character to be examimed for the end-of-line when reading
-- strings from a file descriptor.  The default is a line feed.  Different
-- data sources may use different end-of-line characters (like a carriage
-- return).
-----------------------------------------------------------------------------

function getEOL( fd : aBufferedFile ) return anEOLType is
begin
  return fd.eolType;
end getEOL;

procedure setEOL( fd : in out aBufferedFile; eolType : anEOLType ) is
begin
  fd.eolType := eolType;
  fd.EOL := lastCharForEOL( eolType );
end setEOL;

function isOpen( fd : aBufferedFile ) return boolean is
begin
  return fd.fd >= 0;
end isOpen;

function isEOF( fd : aBufferedFile ) return boolean is
begin
  return fd.EOF;
end isEOF;

procedure setReadBufferSize( fd : in out aBufferedFile; size : short_integer ) is
begin
  free( fd.readBuffer );
  if size < 1 then
     fd.readBuffer := new string(1..1);
  else
     fd.readBuffer := new string(1..integer( size ));
  end if;
end setReadBufferSize;

function getEOL( fd : aBufferedSocket ) return anEOLType is
begin
  return fd.eolType;
end getEOL;

procedure setEOL( fd : in out aBufferedSocket; eolType : anEOLType ) is
begin
  fd.eolType := eolType;
  fd.EOL := lastCharForEOL( eolType );
end setEOL;

function isOpen( fd : aBufferedSocket ) return boolean is
begin
  return fd.fd >= 0;
end isOpen;

function isEOF( fd : aBufferedSocket ) return boolean is
begin
  return fd.EOF;
end isEOF;

procedure setReadBufferSize( fd : in out aBufferedSocket; size : short_integer ) is
begin
  free( fd.readBuffer );
  if size < 1 then
     fd.readBuffer := new string(1..1);
  else
     fd.readBuffer := new string(1..integer( size ));
  end if;
end setReadBufferSize;

-----------------------------------------------------------------------------
-- FILES
-----------------------------------------------------------------------------


--  OPEN
--
-- Open a file for reading.  Equivalent of open() with O_RDONLY.  Errors will
-- raise name_error exception.
-----------------------------------------------------------------------------

procedure open( fd : out aBufferedFile; name : string; mode : aFileMode := blocking; perms : aFileAccess := Access_644 ) is
  flags : anOpenFlag := O_RDONLY;
  os_perms : aModeType := 8#644#;
begin
  case mode is
  when nonblocking => flags := flags + O_NONBLOCK;
  when synchronous => flags := flags + O_SYNC;
  when others => null;
  end case;
  case perms is
  when Acesss_666 => os_perms := 8#666#;
  when Access_644 => os_perms := 8#644#;
  when Access_640 => os_perms := 8#640#;
  when Access_600 => os_perms := 8#600#;
  end case;
  fd.fd := open( name & ASCII.NUL, flags, os_perms );
  if fd.fd < 0 then
     --Put_Line( Standard_Error, "Open file failed: " & OSError( C_pegasock_errno ) );
     raise name_error with "Open file failed: " & OSError( C_pegasock_errno );
  end if;
  pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": opened file descriptor" & fd.fd'img ) );
  fd.readPos := integer'last;
  fd.amountRead := 0;
  fd.eof := false;
  fd.name := to_unbounded_string( name );
  fd.mode := mode;
  setEOL( fd, fd.eolType );
end open;


--  OVERWRITE
--
-- Open a file for writing.  Equivalent of open() with O_CREAT + O_WRONLY +
-- O_TRUNC.  Errors will raise name_error exception.
-----------------------------------------------------------------------------

procedure overwrite( fd : out aBufferedFile; name : string; mode : aFileMode := blocking; perms : aFileAccess := Access_644 ) is
  flags : anOpenFlag := O_CREAT+O_WRONLY+O_TRUNC;
  os_perms : aModeType := 8#644#;
begin
  case mode is
  when nonblocking => flags := flags + O_NONBLOCK;
  when synchronous => flags := flags + O_SYNC;
  when others => null;
  end case;
  case perms is
  when Acesss_666 => os_perms := 8#666#;
  when Access_644 => os_perms := 8#644#;
  when Access_640 => os_perms := 8#640#;
  when Access_600 => os_perms := 8#600#;
  end case;
  fd.fd := open( name & ASCII.NUL, flags, os_perms );
  if fd.fd < 0 then
     --Put_Line( Standard_Error, "Open file failed: " & OSError( C_pegasock_errno ) );
     raise name_error with "Open file failed: " & OSError( C_pegasock_errno );
  end if;
  pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": opened file descriptor" & fd.fd'img ) );
  fd.readPos := integer'last;
  fd.amountRead := 0;
  fd.eof := false;
  fd.name := to_unbounded_string( name );
  fd.mode := mode;
  setEOL( fd, fd.eolType );
end overwrite;


--  APPEND
--
-- Open a file for appending.  Equivalent of open() with O_WRONLY+O_APPEND.
-- Errors will raise name_error exception.
-----------------------------------------------------------------------------

procedure append( fd : out aBufferedFile; name : string; mode : aFileMode := blocking; perms : aFileAccess := Access_644 ) is
  flags : anOpenFlag := O_WRONLY+O_APPEND;
  os_perms : aModeType := 8#644#;
begin
  case mode is
  when nonblocking => flags := flags + O_NONBLOCK;
  when synchronous => flags := flags + O_SYNC;
  when others => null;
  end case;
  case perms is
  when Acesss_666 => os_perms := 8#666#;
  when Access_644 => os_perms := 8#644#;
  when Access_640 => os_perms := 8#640#;
  when Access_600 => os_perms := 8#600#;
  end case;
  fd.fd := open( name & ASCII.NUL, flags, os_perms );
  if fd.fd < 0 then
     --Put_Line( Standard_Error, "Open file failed: " & OSError( C_pegasock_errno ) );
     raise name_error with "Open file failed: " & OSError( C_pegasock_errno );
  end if;
  pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": opened file descriptor" & fd.fd'img ) );
  fd.readPos := integer'last;
  fd.amountRead := 0;
  fd.eof := false;
  fd.name := to_unbounded_string( name );
  fd.mode := mode;
  setEOL( fd, fd.eolType );
end append;


--  NAME
--
-- Return the path name of the file. Mainly included for debugging..
-----------------------------------------------------------------------------

function name( fd : aBufferedFile ) return unbounded_string is
begin
  return fd.name;
end name;


--  MODE
--
-- Return the socket mode of the socket. Mainly included for debugging..
-----------------------------------------------------------------------------

function mode( fd : aBufferedFile ) return aFileMode is
begin
  return fd.mode;
end mode;


--  GET
--
-- Read a character.  Errors will raise data_error exception. 
-- fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------

procedure get( fd : in out aBufferedFile; ch : out character ) is
  pragma suppress( range_check );
  pragma suppress( index_check );
begin
  if fd.readPos > integer( fd.amountRead ) then
     fillReadBuffer( fd, 1 );
  end if;
  ch := fd.readBuffer( fd.readPos );
  fd.readpos := fd.readPos + 1;
end get;


--  GET
--
-- Read until an end-of-line is found and return the line.  Since some systems
-- use two characters for EOL, this actually only searches for the final
-- character of the two character sequence so embedding line feeds or carriage
-- returns into the string is not advisable.  The EOL characters will be
-- stripped before the string is returned.
--
-- data_error exception is raised on I/O errors.
-- fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------

procedure get( fd : in out aBufferedFile; s : out unbounded_string ) is
  pragma suppress( range_check );
  pragma suppress( index_check );
  ch         : character;
  newPos     : integer;
begin
  -- newPos is used to try to reduce the amount of unbounded_string concats
  -- to improve performance
  s := null_unbounded_string;
  newPos := fd.readPos;
  loop
    if newPos > integer( fd.amountRead ) then
       if newPos > fd.readPos then
          s := s & fd.readBuffer( fd.readPos..newPos-1 );
       end if;
       fillReadBuffer( fd, 1 );
       newPos := fd.readPos;
    end if;
    ch := fd.readBuffer( newPos );
    exit when ch = fd.EOL;
    newPos := newPos + 1;
  end loop;
  s := s & fd.readBuffer( fd.readPos..newPos );
  fd.readPos := newPos + 1;

  trimEOL( fd.eolType, s );
end get;


--  GET
--
-- Read a specific number of bytes.  Errors will raise data_error
-- exception.  fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------

procedure get( fd : in out aBufferedFile; bytes : positive; s : out unbounded_string ) is
  pragma suppress( range_check );
  pragma suppress( index_check );
  pragma suppress( overflow_check );
  totalRead    : size_t := 0;
  amountToRead : size_t := 0;
begin
  s := null_unbounded_string;
  loop
    if fd.readPos > integer( fd.amountRead ) then
       amountToRead := size_t( bytes ) - totalRead;
       if amountToRead > fd.readBuffer'length then
          amountToRead := fd.readBuffer'length;
       end if;
       fillReadBuffer( fd, amountToRead );
    end if;
    s := s & fd.readBuffer(fd.readPos..integer(fd.amountRead));
    fd.readpos := fd.readPos + integer( fd.amountRead );
    totalRead := totalRead + fd.amountRead;
    exit when totalRead >= size_t( bytes );
  end loop;
end get;

procedure get( fd : in out aBufferedFile; ch : out wide_character ) is
  db : double_byte;
begin
  -- this is not necessarily very fast as we do one character at a time
  get( fd, db(1) );
  get( fd, db(2) );
  ch := double_byte_to_wide( db );
end get;

procedure get( fd : in out aBufferedFile; ch : out wide_wide_character ) is
  qb : quad_byte;
begin
  -- this is not necessarily very fast as we do one character at a time
  get( fd, qb(1) );
  get( fd, qb(2) );
  get( fd, qb(3) );
  get( fd, qb(4) );
  ch := quad_byte_to_wide_wide( qb );
end get;


--  NEW LINE
--
-- Write an end-of-line to the descriptor, based on the descriptor's EOL type
-- exception.  fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------

procedure new_line( fd : in out aBufferedFile ) is
begin
  put( fd, appendEOL( fd.eolType, "" ) );
end new_line;


--  PUT
--
-- Write a string to the descriptor.  Errors will raise data_error
-- exception.  fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------


procedure put( fd : aBufferedFile; c : character ) is
begin
  put( fd, "" & c );
end put;

procedure put( fd : aBufferedFile; s : string ) is
  pragma suppress( range_check );
  pragma suppress( index_check );
  pragma suppress( overflow_check );
  amountWritten : size_t := 0;
  totalWritten  : size_t := 0;
  position      : integer := s'first;
begin
 loop
   <<retry>> write( amountWritten, fd.fd, s( position )'address,
     size_t(s'length) - totalWritten );
     if amountWritten = size_t'last then
        if C_pegasock_errno = EINTR then
           goto retry;
        elsif C_pegasock_errno = EAGAIN or C_pegasock_errno = EWOULDBLOCK then
           raise fileutils_wouldblock;
        end if;
        -- Put_Line( Standard_Error, "Write to file failed" & OSError( C_pegasock_errno ) );
	raise data_error with "Write to file failed: " & OSError( C_pegasock_errno );
      end if;
    pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": wrote" & amountWritten'img & " bytes to file descriptor" & fd.fd'img ) );
    totalWritten := totalWritten + amountWritten;
    position := position + integer( amountWritten );
    exit when totalWritten = s'length;
 end loop;
end put;

procedure put( fd : aBufferedFile; s : unbounded_string ) is
begin
  put( fd, to_string(s) );
end put;

procedure put_line( fd : aBufferedFile; s : string ) is
begin
  put( fd, appendEOL( fd.eolType, s ) );
end put_line;

procedure put_line( fd : aBufferedFile; s : unbounded_string ) is
begin
  put( fd, appendEOL( fd.eolType, s ) );
end put_line;

procedure wide_put( fd : aBufferedFile; s : wide_string ) is
  db : double_byte;
begin
  -- this is not necessarily very fast as we do one character at a time
  for i in 1..s'length loop
      db := wide_to_double_byte( s(i) );
      put( fd, db(1) );
      put( fd, db(2) );
  end loop;
end wide_put;

procedure wide_wide_put( fd : aBufferedFile; s : wide_wide_string ) is
 qb : quad_byte;
begin
  -- this is not necessarily very fast as we do one character at a time
  for i in 1..s'length loop
      qb := wide_wide_to_quad_byte( s(i) );
      put( fd, qb(1) );
      put( fd, qb(2) );
      put( fd, qb(3) );
      put( fd, qb(4) );
  end loop;
end wide_wide_put;

--  FLUSH
--
-- Flush the output by pushing any buffered data to the storage
-- device.
-----------------------------------------------------------------------------

procedure flush( fd : aBufferedFile ) is
  res : int;
begin
  res := fdatasync( fd.fd );
  if res < 0 then
      raise data_error with "File sync failed: " & OSError( C_pegasock_errno );
  end if;
end flush;


--  CLOSE
--
-- Close the file descriptor.  An I/O error will raise a name_error
-- exception.
-----------------------------------------------------------------------------

procedure close( fd : in out aBufferedFile ) is
  res : int;
begin
  if fd.fd < 0 then
     return;
  end if;
  <<retry>> res := close( fd.fd );
  if res < 0 then
     if C_pegasock_errno = EINTR then
        goto retry;
     else
        raise name_error with "Close failed: " & OSError( C_pegasock_errno );
     end if;
  end if;
  pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": closed file descriptor" & fd.fd'img ) );
  fd.fd := -1;
end close;


--  DELETE
--
-- Close an open file and remove it from the storage device.  (Ada Text_IO
-- semantics).  Could raise a name_error exception on an I/O error.  The
-- file should be opened first.
-----------------------------------------------------------------------------
-- I could try to rename Sf_Text_Io.Delete, but then I'd have to import
-- Text_IO.

procedure Delete( fd : in out aBufferedFile ) is
  res : int;
begin
  Close( fd );
  res := unlink( to_string( fd.name ) & ASCII.Nul );
  if res < 0 then
     raise name_error with "Delete failed: " & OSError( C_pegasock_errno );
  end if;
end Delete;


-----------------------------------------------------------------------------
-- SOCKETS
-----------------------------------------------------------------------------


--  ESTABLISH
--
-- Open a TCP/IP socket for reading and writing.  Errors will raise
-- name_error exception.
-----------------------------------------------------------------------------

procedure establish( fd : out aBufferedSocket; host : unbounded_string; port : integer ; mode : aSocketMode := blocking ) is
  use spar_os.HEptrs;
  mySocket    : aBufferedSocket;     -- the socket
  myAddress   : aSocketAddr;   -- where it goes
  myServer    : aHEptr;        -- IP number of server
  myServerPtr : HEptrs.Object_Pointer;
  addrList    : addrListPtrs.Object_Pointer;
  Result      : int;
  flags       : aSocketType := SOCK_STREAM;
  errno       : integer;
begin
  case mode is
  when nonblocking => flags := flags + SOCK_NONBLOCK;  -- linux kernel >=2.6.27
  when others => null;
  end case;

  -- initialize a new TCP/IP socket
  -- 0 for the third param lets the kernel decide

  --Put_Line( "Initializing a TCP/IP socket" );
  --Put_Line( "Socket( " & PF_INET'img & ',' & SOCK_STREAM'img & ", 0 );" );

  mySocket.fd := Socket( PF_INET, flags, 0 );
  if mySocket.fd = -1 then
     -- put_line( standard_error, "error making socket: " & OSError( C_pegasock_errno ) );
     raise name_error with "error making socket: " & OSError( C_pegasock_errno );
  end if;
  --New_Line;

  -- Lookup the IP number for the server

  --Put_Line( "Looking for information on " & to_string( serverName ) );

  myServer := GetHostByName( to_string( host ) & ASCII.NUL );
  myServerPtr := HEptrs.To_Pointer( myServer );
  if myServerPtr = null then
     if C_pegasock_errno = 0 then
        -- put_line( standard_error, "there is no server by this name" );
        raise name_error with "there is no server by this name";
     end if;
     -- put_line( standard_error, "error looking up host: " & OSError( C_pegasock_errno ) );
     raise name_error with "error looking up host: " & OSError( C_pegasock_errno );
  end if;

  --Put_Line( "IP number is" & myServerPtr.h_length'img & " bytes long" );
  addrList := addrlistPtrs.To_Pointer( myServerPtr.h_addr_list );
  --New_Line;

  -- Create the IP, port and protocol information

  --Put_Line( "Preparing connection destination information" );
  myAddress.family := AF_INET;
  myAddress.port   := htons( Interfaces.C.Unsigned_Short( port ) );
  memcpy( myAddress.ip'address, addrlist.all, myServerPtr.h_length );
  --New_Line;

  -- Open a connection to the server

  --Put_Line( "Connect( Result, Socket, Family/Address rec, F/A rec size )" );

  <<retry>> Connect( Result, mySocket.fd, myAddress, myAddress'size/8 );
 --PutIPNum( myAddress.ip );
  --Put(  "," & integer'image( myAddress'size / 8 ) & ")" );
  if Result < 0 then
     errno := C_pegasock_errno; -- close below may change C_pegasock_errno
     if errno = EINTR then
        goto retry;
     elsif errno = EALREADY or errno = EINPROGRESS then
        -- With non-blocking sockets, this indicates that the system is busy
        -- and you need to retry later (because Socket() didn't block)
        -- For best performance should use poll() or select() but these are
        -- tricky to implement directly in Ada
        delay 0.01;
        pragma debug( put_line( Gnat.Source_Info.Source_Location & ": socket busy...retrying to connect..." ) );
        goto retry;
     end if;

     close( mySocket );  -- BUSH missing this

     -- put_line( standard_error, "error connecting to server: " & OSerror( C_pegasock_errno ) );
     raise name_error with "error connecting to server: " & OSerror( errno );
  end if;
  --New_Line;

  pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": opened file descriptor" & mySocket.fd'img ) );
  mySocket.readPos := integer'last;
  mySocket.amountRead := 0;
  mySocket.eof := false;
  mysocket.port := port;
  mysocket.host := host;
  mysocket.mode := mode;
  setEOL( mysocket, mysocket.eolType );

  fd := mySocket;

end establish;


--  HOST
--
-- Return the host name of the socket. Mainly included for debugging.
-----------------------------------------------------------------------------

function host( fd : aBufferedSocket ) return unbounded_string is
begin
  return fd.host;
end host;


--  PORT
--
-- Return the network port of the socket. Mainly included for debugging..
-----------------------------------------------------------------------------

function port( fd : aBufferedSocket ) return integer is
begin
  return fd.port;
end port;


--  MODE
--
-- Return the socket mode of the socket. Mainly included for debugging..
-----------------------------------------------------------------------------

function mode( fd : aBufferedSocket ) return aSocketMode is
begin
  return fd.mode;
end mode;


--  GET
--
-- Read a character.  Errors will raise data_error exception. 
-- fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------

procedure get( fd : in out aBufferedSocket; ch : out character ) is
  pragma suppress( range_check );
  pragma suppress( index_check );
begin
  if fd.readPos > integer( fd.amountRead ) then
     fillReadBuffer( fd, 1 );
  end if;
  ch := fd.readBuffer( fd.readPos );
  fd.readpos := fd.readPos + 1;
end get;


--  GET
--
-- Read until an end-of-line is found and return the line.  Since some systems
-- use two characters for EOL, this actually only searches for the final
-- character of the two character sequence so embedding line feeds or carriage
-- returns into the string is not advisable.  The EOL characters will be
-- stripped before the string is returned.
--
-- data_error exception is raised on I/O errors.
-- fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------

procedure get( fd : in out aBufferedSocket; s : out unbounded_string ) is
  pragma suppress( range_check );
  pragma suppress( index_check );
  ch         : character;
  newPos     : integer;
begin
  -- newPos is used to try to reduce the amount of unbounded_string concats
  -- to improve performance
  s := null_unbounded_string;
  newPos := fd.readPos;
  loop
    if newPos > integer( fd.amountRead ) then
       if newPos > fd.readPos then
          s := s & fd.readBuffer( fd.readPos..newPos-1 );
       end if;
       fillReadBuffer( fd, 1 );
       newPos := fd.readPos;
    end if;
    ch := fd.readBuffer( newPos );
    exit when ch = fd.EOL;
    newPos := newPos + 1;
  end loop;
  s := s & fd.readBuffer( fd.readPos..newPos );
  fd.readPos := newPos + 1;
  trimEOL( fd.eolType, s );

end get;


--  GET
--
-- Read a specific number of bytes.  Errors will raise data_error
-- exception.  fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------

procedure get( fd : in out aBufferedSocket; bytes : positive; s : out unbounded_string ) is
  pragma suppress( range_check );
  pragma suppress( index_check );
  pragma suppress( overflow_check );
  totalRead    : size_t := 0;
  amountToRead : size_t := 0;
begin
  s := null_unbounded_string;
  loop
    if fd.readPos > integer( fd.amountRead ) then
       amountToRead := size_t( bytes ) - totalRead;
       if amountToRead > fd.readBuffer'length then
          amountToRead := fd.readBuffer'length;
       end if;
       fillReadBuffer( fd, amountToRead );
    end if;
    s := s & fd.readBuffer(fd.readPos..integer(fd.amountRead));
    fd.readpos := fd.readPos + integer( fd.amountRead );
    totalRead := totalRead + fd.amountRead;
    exit when totalRead >= size_t( bytes );
  end loop;
end get;

procedure get( fd : in out aBufferedSocket; ch : out wide_character ) is
  db : double_byte;
begin
  -- this is not necessarily very fast as we do one character at a time
  get( fd, db(1) );
  get( fd, db(2) );
  ch := double_byte_to_wide( db );
end get;

procedure get( fd : in out aBufferedSocket; ch : out wide_wide_character ) is
  qb : quad_byte;
begin
  -- this is not necessarily very fast as we do one character at a time
  get( fd, qb(1) );
  get( fd, qb(2) );
  get( fd, qb(3) );
  get( fd, qb(4) );
  ch := quad_byte_to_wide_wide( qb );
end get;


--  NEW LINE
--
-- Write an end-of-line to the descriptor, based on the descriptor's EOL type
-- exception.  fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------

procedure new_line( fd : in out aBufferedSocket ) is
begin
  put( fd, appendEOL( fd.eolType, "" ) );
end new_line;


--  PUT
--
-- Write a string to the descriptor.  Errors will raise fileutils_error
-- exception.  fileutils_wouldblock is raised if writing would cause the
-- process to block a non-blocking descriptor.
-----------------------------------------------------------------------------

procedure put( fd : aBufferedSocket; c : character ) is
begin
  put( fd, "" & c );
end put;

procedure put( fd : aBufferedSocket; s : string ) is
  amountWritten : size_t := 0;
  totalWritten  : size_t := 0;
  position      : integer := s'first;
begin
 loop
   <<retry>> write( amountWritten, aFileDescriptor( fd.fd ), s( position )'address,
      size_t(s'length) - totalWritten );
      if amountWritten = size_t'last then
         if C_pegasock_errno = EINTR then
            goto retry;
         elsif C_pegasock_errno = EAGAIN or C_pegasock_errno = EWOULDBLOCK then
            raise fileutils_wouldblock;
         end if;
         -- Put_Line( Standard_Error, "Write to socket failed" & OSError( C_pegasock_errno ) );
	 raise data_error with "Write to socket failed" & OSError( C_pegasock_errno );
      end if;
     pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": wrote" & amountWritten'img & " bytes to file descriptor" & fd.fd'img ) );
     totalWritten := totalWritten + amountWritten;
     position := position + integer( amountWritten );
     exit when totalWritten = s'length;
 end loop;
end put;

procedure put( fd : aBufferedSocket; s : unbounded_string ) is
begin
  put( fd, to_string(s) );
end put;


procedure put_line( fd : aBufferedSocket; s : string ) is
begin
  put( fd, appendEOL( fd.eolType, s ) );
end put_line;

procedure put_line( fd : aBufferedSocket; s : unbounded_string ) is
begin
  put( fd, appendEOL( fd.eolType, s ) );
end put_line;

procedure wide_put( fd : aBufferedSocket; s : wide_string ) is
  db : double_byte;
begin
  -- this is not necessarily very fast as we do one character at a time
  for i in 1..s'length loop
      db := wide_to_double_byte( s(i) );
      put( fd, db(1) );
      put( fd, db(2) );
  end loop;
end wide_put;

procedure wide_wide_put( fd : aBufferedSocket; s : wide_wide_string ) is
  qb : quad_byte;
begin
  -- this is not necessarily very fast as we do one character at a time
  for i in 1..s'length loop
      qb := wide_wide_to_quad_byte( s(i) );
      put( fd, qb(1) );
      put( fd, qb(2) );
      put( fd, qb(3) );
      put( fd, qb(4) );
  end loop;
end wide_wide_put;


--  FLUSH
--
-- Flush the file descriptor.  An I/O error will raise a data_error
-- exception.
-----------------------------------------------------------------------------

procedure flush( fd : aBufferedSocket ) is
  res : int;
begin
  res := fdatasync( aFileDescriptor( fd.fd ) );
  if res < 0 then
      raise data_error with "Socket sync failed: " & OSError( C_pegasock_errno );
  end if;
end flush;


--  CLOSE
--
-- Close the file descriptor.  An I/O error will raise a name_error
-- exception.
-----------------------------------------------------------------------------

procedure close( fd : in out aBufferedSocket ) is
  res : int;
begin
  if fd.fd >= 0 then
    <<retry>> res := close( aFileDescriptor( fd.fd ) );
    if res < 0 then
       if C_pegasock_errno = EINTR then
          goto retry;
       end if;
       raise name_error with "Close failed: " & OSError( C_pegasock_errno );
    end if;
    pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": closed file descriptor" & fd.fd'img ) );
    fd.fd := -1;
  else
    pragma debug( Put_Line( Gnat.Source_Info.Source_Location & ": cannot close file descriptor" & fd.fd'img ) );
    null;
  end if;
end close;


--  FILE TO SOCKET
--
-- Makes a copy of the file descriptor as a socket descriptor so socket
-- routines may be attempt on a file.  This is dependent on your operating
-- system.  The file descriptor and the returned socket descriptor refer to
-- the same file.
-----------------------------------------------------------------------------

procedure FileToSocket( socket : out aBufferedSocket; file : aBufferedFile ) is
begin
  socket.fd := aSocketFD( file.fd );
  socket.eol := file.eol;
  socket.eolType := file.eolType;
  socket.readBuffer := file.readBuffer;
  socket.readPos := file.readPos;
  socket.amountRead := file.amountRead;
  socket.eof := file.eof;
  socket.host := to_unbounded_string( "unknown" );
  if file.mode = blocking or file.mode = synchronous then
     socket.mode := blocking;
  elsif file.mode = nonblocking then
     socket.mode := nonblocking;
  else
     raise name_error with "incompatible file mode for socket";
  end if;
end FileToSocket;

function OSerror( e : integer ) return string is
-- return an OS error message for error number e
   lastchar : natural := 0;
   ep       : anErrorPtr;
begin
   ep := strerror( e );
   for i in ep.all'range loop
       if ep(i) = ASCII.NUL then
          lastchar := i-1;
          exit;
       end if;
  end loop;
  return string( ep( 1..lastchar ) );
end OSerror;

begin
  -- When initializing this module, validate the O/S constants defined here
  -- against GNAT / GCC Ada's beliefs.  Comment these out if
  -- System.OS_Constants is not available.  These only take effect when
  -- debugging is enabled with the -gnata gnatmake flag.
  pragma assert( EINTR = System.OS_Constants.EINTR );
  pragma assert( EAGAIN = System.OS_Constants.EAGAIN );
  pragma assert( EWOULDBLOCK = System.OS_Constants.EWOULDBLOCK );
  pragma assert( EALREADY = System.OS_Constants.EALREADY );
  -- pragma assert( O_RDONLY = System.OS_Constants.O_RDONLY );
  -- pragma assert( O_WRONLY = System.OS_Constants.O_WRONLY );
  -- pragma assert( O_CREAT = System.OS_Constants.O_CREAT );
  -- pragma assert( O_TRUNC = System.OS_Constants.O_TRUNC );
  -- pragma assert( O_APPEND = System.OS_Constants.O_APPEND );
  -- pragma assert( O_NONBLOCK = System.OS_Constants.O_NONBLOCK );
  pragma assert( AF_INET = System.OS_Constants.AF_INET );
  pragma assert( SOCK_STREAM = System.OS_Constants.SOCK_STREAM );
  pragma assert( IPPROTO_TCP = System.OS_Constants.IPPROTO_TCP );
  null;
end pegasock;
