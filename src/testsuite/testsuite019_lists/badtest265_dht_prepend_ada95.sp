t : dynamic_hash_tables.table( string );
dynamic_hash_tables.set( t, "foo", "bar" );
pragma ada_95;
dynamic_hash_tables.prepend( t, "foo", "bar" ); -- not allowed

