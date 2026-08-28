/* C interface for the Perl-compatible regular expressions  */
/* library.  Called from Ada.                               */
/* Part of SparForte                                        */

#include <string.h>

#ifdef SPARFORTEPCRE2

#define PCRE2_CODE_UNIT_WIDTH 8

#include <pcre2.h>


/*  C PCRE
 *
 * This is based on the PCRE2 demo program.  The demo does not compile
 * because it is not well-maintained.  Many of the constants and
 * function names do not exist or have different names. */

void C_pcre( const char *regex, const char* str, char *errmsg, size_t errmax,
   int *result ) {
   pcre2_code_8 *regex_ptr;
   char no_error = '\0';
   int errnum = 0;
   size_t erroffset = 0;            // location of error in pattern
   int res = 0;

   *errmsg = no_error;

   /* For Perl-compatible Regular Expressions, there are UTF-8, 16
    * and 32 variants and this may also affect the parameters.
    * for here, this is UTF-8 (even though, at this time,
    * SparForte is Latin-1 only).
    */

  PCRE2_SPTR8 pattern;            // pointer to pattern string
  PCRE2_SPTR8 subject;            // pointer to subject string
  PCRE2_SIZE subject_length;      // number of characters
  pcre2_match_data_8 *match_data; // search results

  *result = 0;

  pattern = (PCRE2_SPTR8)regex;   // make pattern pointer
  subject = (PCRE2_SPTR8)str  ;   // make subject pointer
  subject_length = (PCRE2_SIZE)strlen((char *)subject);

  *errmsg = no_error;

  /* Compile the regular expression */

  regex_ptr = pcre2_compile_8(
     pattern,                    // the pattern
     PCRE2_ZERO_TERMINATED,      // C string pattern
     0,                          // case sens., 0 = sensitive
     &errnum,                    // error number
     &erroffset,                 // where error occurred
     NULL );                     // default context

  if ( regex_ptr != NULL ) {

      // Create a match result

      match_data = pcre2_match_data_create_from_pattern_8(
         regex_ptr,
         NULL
      );

      // Perform one match

      res = pcre2_match_8(
          regex_ptr,            // the compiled pattern
          subject,              // the subject to search
          subject_length,       // the subject length
          0,                    // starting offset
          0,                    // options
          match_data,      // results
          NULL
      );
      if ( res >= 0 ) {
         *result = 1;
      } else if (errmax >0) {
          if ( res == PCRE2_ERROR_NULL ) {
             strncpy( errmsg, "pcre_exec failed: null error", errmax-1 );
          } else if ( res == PCRE2_ERROR_BADOPTION ) {
             strncpy( errmsg, "pcre_exec failed: bad option", errmax-1 );
          } else if ( res == PCRE2_ERROR_BADMAGIC ) {
             strncpy( errmsg, "pcre_exec failed: bad magic number", errmax-1 );
          } else if ( res == PCRE2_ERROR_NOMEMORY ) {
             strncpy( errmsg, "pcre_exec failed: no memory", errmax-1 );
          } else if ( res != PCRE2_ERROR_NOMATCH ) {
             strncpy( errmsg, "pcre_exec failed", errmax-1 );
          }
      }

      pcre2_match_data_free_8( match_data ); // discard results
      pcre2_code_free_8( regex_ptr );        // discard compiled re

   } else if (errmax >0) {
     /* This is taken from PCRE2 demo program */
    pcre2_get_error_message_8(errnum, (PCRE2_UCHAR8*)errmsg, sizeof(errmsg));
    // use something like this to include the offset
    // printf("PCRE2 compilation failed at offset %d: %s\n", (int)erroroffset,
    // buffer);
   }
   // Safety precaution to prevent buffer overruns.
   errmsg[errmax-1] = '\0';
} // end of C_pcre

/* end of c_pcre.c */
#else
/* C interface for the Perl-compatible regular expressions  */
/* library.  Called from Ada.                               */
/* Part of SparForte                                        */

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
#endif

