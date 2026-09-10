/* Poison header. See scripts/check-windows-native-compat.sh.
   MSVC has no <sys/ioctl.h>; mingw-w64 ships one, which would let the Windows
   build path include it here and still fail for a real Windows user. */
#error "POSIX-only header <sys/ioctl.h> reached on the Windows build path (see issue #6)"
