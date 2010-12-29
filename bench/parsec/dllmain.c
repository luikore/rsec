#include <windows.h>
#include <Rts.h>
extern void __stginit_Arithmetic(void);
static char* args[] = { "ghcDll", NULL };
BOOL APIENTRY DllMain(HANDLE hModule, DWORD reason, void* reserved)
{
  if (reason == DLL_PROCESS_ATTACH) {
    startupHaskell(1, args, __stginit_Arithmetic);
    return TRUE;
  }
  return TRUE;
}

