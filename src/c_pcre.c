/* C interface for the Perl-compatible regular expressions  */
/* library.  Called from Ada.                               */
/* Part of SparForte                                        */

#include <string.h>
#include <pcre.h>

void C_pcre( const char *regex, const char* str, char *errmsg, size_t errmax,
   int *result ) {
   pcre *regex_ptr;
   char no_error = '\0';
   const char *errmsg_ptr = &no_error;
   int erroffset = 0;            // location of error in pattern
   int res = 0;

   /* For Perl-compatible Regular Expressions, there are UTF-8, 16
    * and 32 variants and this may also affect the parameters.
    * for here, this is UTF-8 (even though, at this time,
    * SparForte is Latin-1 only).
    */

  *result = 0;
  *errmsg = no_error;

   regex_ptr = pcre_compile(regex, 0, &errmsg_ptr, &erroffset, NULL );
   if ( regex_ptr != NULL ) {
      // This should not typically fail.  It does not return an
      // error message, just a negative error code.
      res = pcre_exec( regex_ptr, NULL, str, strlen(str), 0, 0, NULL, 0);
      if ( res >= 0 ) {
         *result = 1;
      } else if (errmax >0) {
          if ( res == PCRE_ERROR_NULL ) {
             strncpy( errmsg, "pcre_exec failed: null error", errmax-1 );
          } else if ( res == PCRE_ERROR_BADOPTION ) {
             strncpy( errmsg, "pcre_exec failed: bad option", errmax-1 );
          } else if ( res == PCRE_ERROR_BADMAGIC ) {
             strncpy( errmsg, "pcre_exec failed: bad magic number", errmax-1 );
          } else if ( res == PCRE_ERROR_UNKNOWN_NODE ) {
             strncpy( errmsg, "pcre_exec failed: unknown_node", errmax-1 );
          } else if ( res == PCRE_ERROR_NOMEMORY ) {
             strncpy( errmsg, "pcre_exec failed: no memory", errmax-1 );
          } else if ( res != PCRE_ERROR_NOMATCH ) {
             strncpy( errmsg, "pcre_exec failed", errmax-1 );
          }
        }
      pcre_free( regex_ptr );
   } else if (errmax >0) {
      strncpy( errmsg, errmsg_ptr, errmax-1 );
   }
   // Safety precaution to prevent buffer overruns.
   errmsg[errmax-1] = '\0';
}

/* end of c_pcre.c */
