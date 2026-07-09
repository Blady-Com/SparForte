procedure t is

   type strlist is new limited doubly_linked_lists.list( string );
   meta red is new meta;
   meta blue is new meta;
   meta darkred is new meta;

   procedure init_list( sl : in out strlist ) is
   begin
     doubly_linked_lists.append( sl, "apple" tagged red );
     doubly_linked_lists.append( sl, "blueberry" tagged blue );
     doubly_linked_lists.append( sl, "cherry" tagged darkred );
   end init_list;

   sl : strlist;
   s : string;
begin
   init_list( sl );
   pragma assert( doubly_linked_lists.length( sl ) = 3 );
   s := doubly_linked_lists.first_element( sl );
   pragma assert( tags.contains_unit( s, red ) );
   pragma assert( s = "apple" tagged red );
   doubly_linked_lists.delete_first( sl );
   s := doubly_linked_lists.first_element( sl );
   pragma assert( tags.contains_unit( s, blue ) );
   pragma assert( s = "blueberry" tagged blue );
   doubly_linked_lists.delete_first( sl );
   s := doubly_linked_lists.first_element( sl );
   pragma assert( tags.contains_unit( s, darkred ) );
   pragma assert( s = "cherry" tagged darkred );
   doubly_linked_lists.clear( sl );
end t;

