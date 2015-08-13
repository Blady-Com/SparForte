 #include <stdio.h>
 #include <db.h>
 #include <errno.h>
 
 int main() {
 
 printf( "with interfaces.c;\n" );
 printf( "\n" );
 printf( "package bdb_constants is\n" );
 printf( "-- this is autogenerated\n" );
 printf( "\n" );
 printf( "-- Berkeley DB uses a lot of unsigned 32-bit integers\n" );
 printf( "\n" );
 printf( "type u_int32_t is new interfaces.C.unsigned;\n" );
 printf( " for u_int32_t'size use 32;\n" );
 printf( "\n" );
 printf( "-- Berekeley DB record numbers\n" );
 printf( "-- record numbers start at 1 (that is, they are positive)\n" );
 printf( "\n" );
 printf( "subtype db_recno_t is u_int32_t range 1..u_int32_t'last;\n" );
 printf( "\n" );
 printf( "-- Berkerely DB page sizes\n" );
 printf( "\n" );
 printf( "type aPageSize is new interfaces.C.unsigned;\n" );
 printf( "for aPageSize'size use 32;\n" );
 printf( "\n" ); 
 printf( "type db_error  is new interfaces.C.int;\n" );
 printf( "DB_OK                : constant db_error := 0;\n" );
 printf( "ENOENT               : constant db_error := %d; -- file not found\n", ENOENT );
 printf( "DB_BUFFER_SMALL      : constant db_error := %d; -- User memory too small for return.\n", DB_BUFFER_SMALL );
 printf( "DB_DONOTINDEX        : constant db_error := %d; -- 'Null' return from 2ndary callbk.\n", DB_DONOTINDEX );
 printf( "DB_FOREIGN_CONFLICT  : constant db_error := %d; -- A foreign db constraint triggered.\n", DB_FOREIGN_CONFLICT );
 printf( "DB_KEYEMPTY          : constant db_error := %d; -- Key/data deleted or never created.\n", DB_KEYEMPTY );
 printf( "DB_KEYEXIST          : constant db_error := %d; -- The key/data pair already exists.\n", DB_KEYEXIST );
 printf( "DB_LOCK_DEADLOCK     : constant db_error := %d; -- Deadlock.\n", DB_LOCK_DEADLOCK );
 printf( "DB_LOCK_NOTGRANTED   : constant db_error := %d; -- Lock unavailable.\n", DB_LOCK_NOTGRANTED );
 printf( "DB_LOG_BUFFER_FULL   : constant db_error := %d; -- In-memory log buffer full.\n", DB_LOG_BUFFER_FULL );
 printf( "DB_NOSERVER          : constant db_error := %d; -- Server panic return.\n", DB_NOSERVER );
 #ifdef DB_NOSERVER_HOME
 printf( "DB_NOSERVER_HOME     : constant db_error := %d; -- Bad home sent to server.\n", DB_NOSERVER_HOME );
 #endif
 #ifdef DB_NOSERVER_ID
 printf( "DB_NOSERVER_ID       : constant db_error := %d; -- Bad ID sent to server.\n", DB_NOSERVER_ID );
 #endif
 printf( "DB_NOTFOUND          : constant db_error := %d; -- Key/data pair not found (EOF).\n", DB_NOTFOUND );
 printf( "DB_OLD_VERSION       : constant db_error := %d; -- Out-of-date version.\n", DB_OLD_VERSION );
 printf( "DB_PAGE_NOTFOUND     : constant db_error := %d; -- Requested page not found.\n", DB_PAGE_NOTFOUND );
 printf( "DB_REP_DUPMASTER     : constant db_error := %d; -- There are two masters.\n", DB_REP_DUPMASTER );
 printf( "DB_REP_HANDLE_DEAD   : constant db_error := %d; -- Rolled back a commit.\n", DB_REP_HANDLE_DEAD );
 printf( "DB_REP_HOLDELECTION  : constant db_error := %d; -- Time to hold an election.\n", DB_REP_HOLDELECTION );
 printf( "DB_REP_IGNORE        : constant db_error := %d; -- This msg should be ignored.\n", DB_REP_IGNORE );
 printf( "DB_REP_ISPERM        : constant db_error := %d; -- Cached not written perm written.\n", DB_REP_ISPERM );
 printf( "DB_REP_JOIN_FAILURE  : constant db_error := %d; -- Unable to join replication group.\n", DB_REP_JOIN_FAILURE );
 printf( "DB_REP_LEASE_EXPIRED : constant db_error := %d; -- Master lease has expired.\n", DB_REP_LEASE_EXPIRED );
 printf( "DB_REP_LOCKOUT       : constant db_error := %d; -- API/Replication lockout now.\n", DB_REP_LOCKOUT );
 printf( "DB_REP_NEWSITE       : constant db_error := %d; -- New site entered system.\n", DB_REP_NEWSITE );
 printf( "DB_REP_NOTPERM       : constant db_error := %d; -- Permanent log record not written.\n", DB_REP_NOTPERM );
 printf( "DB_REP_UNAVAIL       : constant db_error := %d; -- Site cannot currently be reached.\n", DB_REP_UNAVAIL );
 printf( "DB_RUNRECOVERY       : constant db_error := %d; -- Panic return.\n", DB_RUNRECOVERY );
 printf( "DB_SECONDARY_BAD     : constant db_error := %d; -- Secondary index corrupt.\n", DB_SECONDARY_BAD );
 printf( "DB_VERIFY_BAD        : constant db_error := %d; -- Verify failed; bad format.\n", DB_VERIFY_BAD );
 printf( "DB_VERSION_MISMATCH  : constant db_error := %d; -- Environment version mismatch.\n", DB_VERSION_MISMATCH );
 printf( "\n" );
 printf( "-- Berekely Database Storage Methods\n" );
 printf( "\n" );
 printf( "type db_type is new interfaces.C.int;\n" );
 printf( "DB_BTREE   : constant db_type := 1;\n" );
 printf( "DB_HASH    : constant db_type := 2;\n" );
 printf( "DB_RECNO   : constant db_type := 3;\n" );
 printf( "DB_QUEUE   : constant db_type := 4;\n" );
 printf( "DB_UNKNOWN : constant db_type := 5;\n" );
 printf( "\n" );
 printf( "-- FLAGS\n" );
 printf( "--\n" );
 printf( "-- Berkeley DB relies heavily on integer flags.  These flags are auto-\n" );
 printf( "-- generated (according to the C files) C preprocessor values which makes\n" );
 printf( "-- them awkward to load into Ada.\n" );
 printf( "--\n" );
 printf( "-- Which flags are available depends on the version of Berkeley DB.\n" );
 printf( "-- Not all flags may be supported by this Ada implementation (i.e. multiple\n" );
 printf( "-- gets).\n" );
 printf( "--\n" );
 printf( "-- They are hard-coded here, and given unique types to make debugging easier.\n" );
 printf( "-- This also means the flags have been renamed in most cases to include the\n" );
 printf( "-- commands they refer to.\n" );
 printf( "--\n" );
 printf( "-- TODO: can this be more elegant?  This would be easy with Ada 2012\n" );
 printf( "-- constraints.  I decided not to use enumerated types because it would not\n" );
 printf( "-- be supported by SparForte.\n" );
 printf( "--\n" );
 printf( "--https://web.stanford.edu/class/cs276a/projects/docs/berkeleydb/api_c/c_index.html\n" );
 printf( "-- http://docs.oracle.com/cd/E17076_04/html/gsg_txn/C/envopen.html\n" );
 printf( "\n" );
 printf( "subtype flags is u_int32_t;\n" );
 printf( "\n" );
 printf( "type open_flags is new flags;\n" );
 printf( " DB_OPEN_AUTO_COMMIT          : constant open_flags := %d;\n", DB_AUTO_COMMIT );
 printf( " DB_OPEN_CREATE               : constant open_flags := %d;\n", DB_CREATE );
 printf( " DB_OPEN_EXCL                 : constant open_flags := %d;\n", DB_EXCL );
 printf( " DB_OPEN_MULTIVERSION         : constant open_flags := %d;\n", DB_MULTIVERSION );
 printf( " DB_OPEN_NOMMAP               : constant open_flags := %d;\n", DB_NOMMAP );
 printf( " DB_OPEN_READ_UNCOMMITTED     : constant open_flags := %d;\n", DB_READ_UNCOMMITTED );
 printf( " DB_OPEN_THREAD               : constant open_flags := %d;\n", DB_THREAD );
 printf( " DB_OPEN_TRUNCATE             : constant open_flags := %d;\n", DB_TRUNCATE );
 printf( "\n" );
 printf( "type put_flags is new flags;\n" );
 printf( " DB_PUT_APPEND           : constant put_flags := %d; -- append to end of db\n", DB_APPEND );
 printf( " DB_PUT_NODUPDATA        : constant put_flags := %d; -- key must not exist\n", DB_NODUPDATA );
 printf( " DB_PUT_NOOVERWRITE      : constant put_flags := %d; -- primary key must not exist\n", DB_NOOVERWRITE );
 printf( " DB_PUT_MULTIPLE         : constant put_flags := %d; -- bulk update\n", DB_MULTIPLE );
 printf( " DB_PUT_MULTIPLE_KEY     : constant put_flags := %d; -- bulk update\n", DB_MULTIPLE_KEY );
 printf( " DB_PUT_OVERWRITE_DUP    : constant put_flags := %d; -- ignore dups in sorted db\n", DB_OVERWRITE_DUP );
 printf( "\n" );
 printf( "type get_flags is new flags;\n" );
 printf( " DB_GET_CONSUME           : constant get_flags := %d;\n", DB_CONSUME );
 printf( " DB_GET_CONSUME_WAIT      : constant get_flags := %d;\n", DB_CONSUME_WAIT );
 printf( " DB_GET_GET_BOTH          : constant get_flags := %d;\n", DB_GET_BOTH);
 printf( " DB_GET_GET_BOTH_RANGE    : constant get_flags := %d;\n", DB_GET_BOTH_RANGE );
 printf( " DB_SET_RECNO             : constant get_flags := %d;\n", DB_RECNO );
 printf( " DB_GET_DIRTY_READ        : constant get_flags := %d;\n", DB_DIRTY_READ );
 printf( " DB_GET_MULTIPLE          : constant get_flags := %d;\n", DB_MULTIPLE );
 printf( " DB_GET_RMW               : constant get_flags := %d;\n", DB_RMW );
 printf( "\n" );
 printf( "type exists_flags is new flags;\n" );
 printf( " DB_EXISTS_READ_COMMITTED   : constant exists_flags := %d;\n", DB_READ_COMMITTED );
 printf( " DB_EXISTS_READ_UNCOMMITTED : constant exists_flags := %d;\n", DB_READ_UNCOMMITTED );
 printf( " DB_EXISTS_RMW              : constant exists_flags := %d;\n", DB_RMW );
 printf( "\n" );
 printf( "type delete_flags is new flags;\n" );
 printf( " DB_DELETE_CONSUME           : constant delete_flags := %d; -- queue head\n", DB_CONSUME );
 printf( " DB_DELETE_GET_MULTIPLE      : constant delete_flags := %d; -- bulk update\n", DB_MULTIPLE );
 printf( " DB_DELETE_GET_MULTIPLE_KEY  : constant delete_flags := %d; -- bulk update\n", DB_MULTIPLE_KEY );
 printf( "\n" );
 printf( "type env_flags is new flags;\n" );
 printf( " DB_ENV_AUTO_COMMIT     : constant env_flags := %d; -- DB_AUTO_COMMIT\n", DB_AUTO_COMMIT );
 printf( " DB_ENV_CDB_ALLDB       : constant env_flags := %d; -- CDB environment wide locking\n", DB_CDB_ALLDB );
 printf( " DB_ENV_FAILCHK         : constant env_flags := %d; -- Failchk is running\n", DB_FAILCHK );
 printf( " DB_ENV_DIRECT_DB       : constant env_flags := %d; -- DB_DIRECT_DB set\n", DB_DIRECT_DB );
 printf( " DB_ENV_DSYNC_DB        : constant env_flags := %d; -- DB_DSYNC_DB set\n", DB_DSYNC_DB );
 printf( " DB_ENV_MULTIVERSION    : constant env_flags := %d; -- DB_MULTIVERSION set\n", DB_MULTIVERSION );
 printf( " DB_ENV_NOLOCKING       : constant env_flags := %d; -- DB_NOLOCKING set\n", DB_NOLOCKING );
 printf( " DB_ENV_NOMMAP          : constant env_flags := %d; -- DB_NOMMAP set\n", DB_NOMMAP );
 printf( " DB_ENV_NOPANIC         : constant env_flags := %d; -- Okay if panic set\n", DB_NOPANIC );
 printf( " DB_ENV_OVERWRITE       : constant env_flags := %d; -- DB_OVERWRITE set\n", DB_OVERWRITE );
 printf( " DB_ENV_REGION_INIT     : constant env_flags := %d; -- DB_REGION_INIT set\n", DB_REGION_INIT );
 #ifdef DB_RPCCLIENT
 printf( " DB_ENV_RPCCLIENT       : constant env_flags := %d; -- DB_RPCCLIENT set\n", DB_RPCCLIENT );
 #endif
 #ifdef DB_RPCCLIENT_GIVEN
 printf( " DB_ENV_RPCCLIENT_GIVEN : constant env_flags := %d; -- User-supplied RPC client struct\n", DB_RPCCLIENT_GIVEN );
 #endif
 printf( " DB_ENV_TIME_NOTGRANTED : constant env_flags := %d; -- DB_TIME_NOTGRANTED set\n", DB_TIME_NOTGRANTED );
 printf( " DB_ENV_TXN_NOSYNC      : constant env_flags := %d; -- DB_TXN_NOSYNC set\n", DB_TXN_NOSYNC );
 printf( " DB_ENV_TXN_NOWAIT      : constant env_flags := %d; -- DB_TXN_NOWAIT set\n", DB_TXN_NOWAIT );
 printf( " DB_ENV_TXN_SNAPSHOT    : constant env_flags := %d; -- DB_TXN_SNAPSHOT set\n", DB_TXN_SNAPSHOT );
 printf( " DB_ENV_TXN_WRITE_NOSYNC : constant env_flags := %d; -- DB_TXN_WRITE_NOSYNC set\n", DB_TXN_WRITE_NOSYNC );
 printf( " DB_ENV_YIELDCPU        : constant env_flags := %d; -- DB_YIELDCPU set\n", DB_YIELDCPU );
 printf( "\n" );
 printf( "-- TODO: enum\n" );
 printf( "\n" );
 printf( "type config_flags is new flags; -- db_set_flags\n" );
 printf( " DB_CONFIG_CHKSUM     : constant config_flags := %d;\n", DB_CHKSUM );
 printf( " DB_CONFIG_DUP        : constant config_flags := %d;\n", DB_DUP );
 printf( " DB_CONFIG_DUPSORT    : constant config_flags := %d;\n", DB_DUPSORT );
 printf( " DB_CONFIG_ENCRYPT    : constant config_flags := %d;\n", DB_ENCRYPT );
 printf( " DB_CONFIG_INORDER    : constant config_flags := %d;\n", DB_INORDER );
 printf( " DB_CONFIG_RECNUM     : constant config_flags := %d;\n", DB_RECNUM );
 printf( " DB_CONFIG_RENUMBER   : constant config_flags := %d;\n", DB_RENUMBER );
 printf( " DB_CONFIG_REVSPLITOFF : constant config_flags := %d;\n", DB_REVSPLITOFF );
 printf( " DB_CONFIG_SNAPSHOT   : constant config_flags := %d;\n", DB_SNAPSHOT );
 printf( " DB_CONFIG_TXN_NOT_DURABLE : constant config_flags := %d;\n", DB_TXN_NOT_DURABLE );
 printf( "\n" );
 printf( "type sync_flags is new flags;\n" );
 printf( "\n" );
 printf( "type key_range_flags is new flags;\n" );
 printf( "-- none exist in BDB v4\n" );
 printf( "\n" );
 printf( "type cursor_flags is new flags;\n" );
 printf( " DB_CURSOR_CURSOR_BULK      : constant cursor_flags := %d;\n", DB_CURSOR_BULK );
 printf( " DB_CURSOR_READ_COMMITTED   : constant cursor_flags := %d;\n", DB_READ_COMMITTED );
 printf( " DB_CURSOR_READ_UNCOMMITTED : constant cursor_flags := %d;\n", DB_READ_UNCOMMITTED );
 printf( " DB_CURSOR_WRITECURSOR      : constant cursor_flags := %d;\n", DB_WRITECURSOR );
 printf( " DB_CURSOR_TXN_SNAPSHOT     : constant cursor_flags := %d;\n", DB_TXN_SNAPSHOT );
 printf( "\n" );
 printf( "type c_get_flags is new flags;\n" );
 printf( " DB_C_GET_CONSUME           : constant c_get_flags := %d;\n", DB_CONSUME );
 printf( " DB_C_GET_CONSUME_WAIT      : constant c_get_flags := %d;\n", DB_CONSUME_WAIT );
 printf( " DB_C_GET_CURRENT           : constant c_get_flags := %d;\n", DB_CURRENT );
 printf( " DB_C_GET_FIRST             : constant c_get_flags := %d;\n", DB_FIRST );
 printf( " DB_C_GET_LAST              : constant c_get_flags := %d;\n", DB_LAST );
 printf( " DB_C_GET_GET_BOTH          : constant c_get_flags := %d;\n", DB_GET_BOTH );
 printf( " DB_C_GET_GET_BOTH_RANGE    : constant c_get_flags := %d;\n", DB_GET_BOTH_RANGE );
 printf( " DB_C_GET_GET_RECNO         : constant c_get_flags := %d;\n", DB_GET_RECNO );
 printf( " DB_C_GET_JOIN_ITEM         : constant c_get_flags := %d;\n", DB_JOIN_ITEM );
 printf( " DB_C_GET_NEXT              : constant c_get_flags := %d;\n", DB_NEXT );
 printf( " DB_C_GET_PREV              : constant c_get_flags := %d;\n", DB_PREV );
 printf( " DB_C_GET_NEXT_DUP          : constant c_get_flags := %d;\n", DB_NEXT_DUP );
 printf( " DB_C_GET_NEXT_NODUP        : constant c_get_flags := %d;\n", DB_NEXT_NODUP );
 printf( " DB_C_GET_PREV_DUP          : constant c_get_flags := %d;\n", DB_PREV_DUP );
 printf( " DB_C_GET_PREV_NODUP        : constant c_get_flags := %d;\n", DB_PREV_NODUP );
 printf( " DB_C_GET_SET               : constant c_get_flags := %d;\n", DB_SET );
 printf( " DB_C_GET_SET_RANGE         : constant c_get_flags := %d;\n", DB_SET_RANGE );
 printf( " DB_C_GET_SET_RECNO         : constant c_get_flags := %d;\n", DB_SET_RECNO );
 printf( " DB_C_GET_DIRTY_READ        : constant c_get_flags := %d;\n", DB_DIRTY_READ );
 printf( " DB_C_GET_MULTIPLE          : constant c_get_flags := %d;\n", DB_MULTIPLE );
 printf( " DB_C_GET_MULTIPLE_KEY      : constant c_get_flags := %d;\n", DB_MULTIPLE_KEY );
 printf( " DB_C_GET_RMW               : constant c_get_flags := %d;\n", DB_RMW );
 printf( "\n" );
 printf( "type c_put_flags is new flags;\n" );
 printf( " DB_C_PUT_AFTER             : constant c_put_flags := %d;\n", DB_AFTER );
 printf( " DB_C_PUT_BEFORE            : constant c_put_flags := %d;\n", DB_BEFORE );
 printf( " DB_C_PUT_CURRENT           : constant c_put_flags := %d;\n", DB_CURRENT );
 printf( " DB_C_PUT_KEYFIRST          : constant c_put_flags := %d;\n", DB_KEYFIRST );
 printf( " DB_C_PUT_KEYLAST           : constant c_put_flags := %d;\n", DB_KEYLAST );
 printf( " DB_C_PUT_NODUPDATA         : constant c_put_flags := %d;\n", DB_NODUPDATA );
 printf( " DB_C_PUT_OVERWRITE_DUP     : constant c_put_flags := %d;\n", DB_OVERWRITE_DUP );
 printf( "\n" );
 printf( "type c_dup_flags is new flags;\n" );
 printf( " DB_C_DUP_POSITION          : constant c_dup_flags := %d;\n", DB_POSITION );
 printf( "\n" );
 printf( "type e_open_flags is new flags;\n" );
 printf( " DB_E_OPEN_CREATE           : constant e_open_flags := %d;\n", DB_CREATE );
 printf( " DB_E_OPEN_JOINENV          : constant e_open_flags := %d;\n", DB_JOINENV );
 printf( " DB_E_OPEN_INIT_CDB         : constant e_open_flags := %d;\n", DB_INIT_CDB );
 printf( " DB_E_OPEN_INIT_LOCK        : constant e_open_flags := %d;\n", DB_INIT_LOCK );
 printf( " DB_E_OPEN_INIT_LOG         : constant e_open_flags := %d;\n", DB_INIT_LOG );
 printf( " DB_E_OPEN_INIT_MPOOL       : constant e_open_flags := %d;\n", DB_INIT_MPOOL );
 printf( " DB_E_OPEN_INIT_TXN         : constant e_open_flags := %d;\n", DB_INIT_TXN );
 printf( " DB_E_OPEN_RECOVER          : constant e_open_flags := %d;\n", DB_RECOVER );
 printf( " DB_E_OPEN_RECOVER_FATAL    : constant e_open_flags := %d;\n", DB_RECOVER_FATAL );
 printf( " DB_E_OPEN_USE_ENVIRON      : constant e_open_flags := %d;\n", DB_USE_ENVIRON );
 printf( " DB_E_OPEN_USE_ENVIRON_ROOT : constant e_open_flags := %d;\n", DB_USE_ENVIRON_ROOT );
 printf( " DB_E_OPEN_LOCKDOWN         : constant e_open_flags := %d;\n", DB_LOCKDOWN );
 printf( " DB_E_OPEN_PRIVATE          : constant e_open_flags := %d;\n", DB_PRIVATE );
 printf( " DB_E_OPEN_SYSTEM_MEM       : constant e_open_flags := %d;\n", DB_SYSTEM_MEM );
 printf( " DB_E_OPEN_THREAD           : constant e_open_flags := %d;\n", DB_THREAD );
 printf( "\n" );
 printf( "type e_dbremove_flags is new flags;\n" );
 printf( " DB_E_REMOVE_AUTOCOMMIT     : constant e_dbremove_flags := %d;\n", DB_AUTO_COMMIT );
 printf( "\n" );
 printf( "type e_dbrename_flags is new flags;\n" );
 printf( " DB_E_RENAME_AUTOCOMMIT     : constant e_dbrename_flags := %d;\n", DB_AUTO_COMMIT );
 printf( "\n" );
 printf( "type e_encrypt_flags is new flags;\n" );
 printf( " DB_E_ENCRYPT_AES          : constant e_encrypt_flags := %d;\n", DB_ENCRYPT_AES );
 printf( "\n" );
 printf( "type e_set_flags is new flags;\n" );
 printf( " DB_E_SET_AUTO_COMMIT      : constant e_set_flags := %d;\n", DB_AUTO_COMMIT );
 printf( " DB_E_SET_CDB_ALLDB        : constant e_set_flags := %d;\n", DB_CDB_ALLDB );
 printf( " DB_E_SET_DIRECT_DB        : constant e_set_flags := %d;\n", DB_DIRECT_DB );
 printf( " DB_E_SET_NOLOCKING        : constant e_set_flags := %d;\n", DB_NOLOCKING );
 printf( " DB_E_SET_NOMMAP           : constant e_set_flags := %d;\n", DB_NOMMAP );
 printf( " DB_E_SET_NOPANIC          : constant e_set_flags := %d;\n", DB_NOPANIC );
 printf( " DB_E_SET_OVERWRITE        : constant e_set_flags := %d;\n", DB_OVERWRITE );
 printf( " DB_E_SET_PANIC_ENVIRONMENT: constant e_set_flags := %d;\n", DB_PANIC_ENVIRONMENT );
 printf( " DB_E_SET_REGION_INIT      : constant e_set_flags := %d;\n", DB_REGION_INIT );
 printf( " DB_E_SET_TXN_NOSYNC       : constant e_set_flags := %d;\n", DB_TXN_NOSYNC );
 printf( " DB_E_SET_TXN_WRITE_NOSYNC : constant e_set_flags := %d;\n", DB_TXN_WRITE_NOSYNC );
 printf( " DB_E_SET_YIELDCPU         : constant e_set_flags := %d;\n", DB_YIELDCPU );
 printf( "\n" );
 printf( "type e_set_timeout_flags is new flags;\n" );
 printf( " DB_E_SET_LOCK_TIMEOUT     : constant e_set_timeout_flags := %d;\n", DB_SET_LOCK_TIMEOUT );
 printf( " DB_E_SET_TXN_TIMEOUT      : constant e_set_timeout_flags := %d;\n", DB_SET_TXN_TIMEOUT );
 printf( "\n" );
 printf( "type e_verbose_flags is new flags;\n" );
 #ifdef DB_VERB_BACKUP
 printf( " DB_VERB_BACKUP          : constant e_verbose_flags := %d;\n", DB_VERB_BACKUP );
 #endif
 printf( " DB_VERB_DEADLOCK        : constant e_verbose_flags := %d;\n", DB_VERB_DEADLOCK );
 printf( " DB_VERB_FILEOPS         : constant e_verbose_flags := %d;\n", DB_VERB_FILEOPS );
 printf( " DB_VERB_FILEOPS_ALL     : constant e_verbose_flags := %d;\n", DB_VERB_FILEOPS_ALL );
 printf( " DB_VERB_RECOVERY        : constant e_verbose_flags := %d;\n", DB_VERB_RECOVERY );
 printf( " DB_VERB_REGISTER        : constant e_verbose_flags := %d;\n", DB_VERB_REGISTER );
 printf( " DB_VERB_REPLICATION     : constant e_verbose_flags := %d;\n", DB_VERB_REPLICATION );
 printf( " DB_VERB_REPMGR_CONNFAIL : constant e_verbose_flags := %d;\n", DB_VERB_REPMGR_CONNFAIL );
 printf( " DB_VERB_REPMGR_MISC     : constant e_verbose_flags := %d;\n", DB_VERB_REPMGR_MISC );
 printf( " DB_VERB_REP_ELECT       : constant e_verbose_flags := %d;\n", DB_VERB_REP_ELECT );
 printf( " DB_VERB_REP_LEASE       : constant e_verbose_flags := %d;\n", DB_VERB_REP_LEASE );
 printf( " DB_VERB_REP_MISC        : constant e_verbose_flags := %d;\n", DB_VERB_REP_MISC );
 printf( " DB_VERB_REP_MSGS        : constant e_verbose_flags := %d;\n", DB_VERB_REP_MSGS );
 printf( " DB_VERB_REP_SYNC        : constant e_verbose_flags := %d;\n", DB_VERB_REP_SYNC );
 #ifdef DB_VERB_REP_SYSTEM
 printf( " DB_VERB_REP_SYSTEM      : constant e_verbose_flags := %d;\n", DB_VERB_REP_SYSTEM );
 #endif
 printf( " DB_VERB_REP_TEST        : constant e_verbose_flags := %d;\n", DB_VERB_REP_TEST );
 printf( " DB_VERB_WAITSFOR        : constant e_verbose_flags := %d;\n", DB_VERB_WAITSFOR );
 printf( " -- TODO: not sure all these apply\n" );
 printf( "\n" );
 printf( "type e_begin_flags is new flags;\n" );
 printf( "\n" );
 printf( " DB_BEGIN_TXN_NOSYNC     : constant e_begin_flags := %d;\n", DB_TXN_NOSYNC );
 printf( " DB_BEGIN_TXN_SYNC       : constant e_begin_flags := %d;\n", DB_TXN_SYNC );
 printf( " DB_BEGIN_TXN_NOWAIT     : constant e_begin_flags := %d;\n", DB_TXN_NOWAIT );
 printf( " DB_BEGIN_DIRTY_READ     : constant e_begin_flags := %d;\n", DB_DIRTY_READ );
 printf( "\n" );
 printf( "type e_commit_flags is new flags;\n" );
 printf( "\n" );
 printf( " DB_COMMIT_TXN_NOSYNC    : constant e_commit_flags := %d;\n", DB_TXN_NOSYNC );
 printf( " DB_COMMIT_TXN_SYNC      : constant e_commit_flags := %d;\n", DB_TXN_SYNC );
 printf( "\n" );
 printf( "type deadlock_detection_modes is new u_int32_t;\n" );
 printf( "\n" );
 printf( " DB_LOCK_NORUN    : constant deadlock_detection_modes := %d;\n", DB_LOCK_NORUN );
 printf( " DB_LOCK_DEFAULT  : constant deadlock_detection_modes := %d; -- Default policy\n", DB_LOCK_DEFAULT );
 printf( " DB_LOCK_EXPIRE   : constant deadlock_detection_modes := %d; -- Only expire locks, no detection\n", DB_LOCK_EXPIRE );
 printf( " DB_LOCK_MAXLOCKS : constant deadlock_detection_modes := %d; -- Select locker with max locks\n", DB_LOCK_MAXLOCKS );
 printf( " DB_LOCK_MAXWRITE : constant deadlock_detection_modes := %d; -- Select locker with max writelocks\n", DB_LOCK_MAXWRITE );
 printf( " DB_LOCK_MINLOCKS : constant deadlock_detection_modes := %d; -- Select locker with min locks\n", DB_LOCK_MINLOCKS );
 printf( " DB_LOCK_MINWRITE : constant deadlock_detection_modes := %d; -- Select locker with min writelocks\n", DB_LOCK_MINWRITE );
 printf( " DB_LOCK_OLDEST   : constant deadlock_detection_modes := %d; -- Select oldest locker\n", DB_LOCK_OLDEST );
 printf( " DB_LOCK_RANDOM   : constant deadlock_detection_modes := %d; -- Select random locker\n", DB_LOCK_RANDOM );
 printf( " DB_LOCK_YOUNGEST : constant deadlock_detection_modes := %d; -- Select youngest locker\n", DB_LOCK_YOUNGEST );
 printf( "\n" );
 printf( "end bdb_constants;" );
 printf( "\n" );

return 0;

}
