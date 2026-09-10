/* Poison header. See scripts/check-windows-native-compat.sh.
   MSVC has no <unistd.h>; mingw-w64 ships one, which would let the Windows
   build path include it here and still fail for a real Windows user. */
#error "POSIX-only header <unistd.h> reached on the Windows build path (see issue #6)"
