#include "utils.h"

char* create_cstring_from_rstring(VALUE rstring) {
  char* dest;

  dest = malloc(sizeof(char) * (RSTRING_LEN(rstring) + 1));
  memcpy(dest, RSTRING_PTR(rstring), RSTRING_LEN(rstring) * sizeof(char));
  dest[RSTRING_LEN(rstring)] = 0;
  return dest;
}
