import std.c.windows.windows;
import core.sys.windows.dll : dll_process_attach, dll_process_detach, dll_thread_attach, dll_thread_detach;

__gshared HINSTANCE g_hInst;

extern (Windows)
BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
    switch (ulReason)
    {
	case DLL_PROCESS_ATTACH:
	    g_hInst = hInstance;
	    dll_process_attach( hInstance, true );
	    break;

	case DLL_PROCESS_DETACH:
	    dll_process_detach( hInstance, true );
	    break;

	case DLL_THREAD_ATTACH:
	    dll_thread_attach( true, true );
	    break;

	case DLL_THREAD_DETACH:
	    dll_thread_detach( true, true );
	    break;

	default:
		break;
    }
    return true;
}
pragma(lib, "kernel32");

// **************************************************************************************

import ae.sys.benchmark;
import common;
