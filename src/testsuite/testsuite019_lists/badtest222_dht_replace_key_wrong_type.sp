t : dynamic_hash_tables.table( string );
dynamic_hash_tables.set( t, "foo", "bar" );
dynamic_hash_tables.replace( t, 1234, "bar" ); -- should be string

