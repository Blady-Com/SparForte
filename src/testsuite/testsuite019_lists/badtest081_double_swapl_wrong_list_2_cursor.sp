l1 : doubly_linked_lists.list( integer );
l2 : doubly_linked_lists.list( integer );
c1 : doubly_linked_lists.cursor( integer );
c2 : doubly_linked_lists.cursor( integer );
doubly_linked_lists.append( l1, 1234 );
doubly_linked_lists.append( l1, 2345 );
doubly_linked_lists.append( l1, 3456 );
doubly_linked_lists.append( l2, 1234 );
doubly_linked_lists.first( l1, c1 );
doubly_linked_lists.last( l2, c2 );
doubly_linked_lists.swap_links( l1, c1, c2 ); -- c2 wrong list

