package ume.externs.memory;

#if (cpp && windows)
@:headerInclude('windows.h')
@:headerInclude('psapi.h')
#end
#if hl
@:hlNative("WindowsMemoryAPI")
#end
class WinMemoryAPI {
	#if windows
	#if cpp
	@:functionCode('
		PROCESS_MEMORY_COUNTERS pmc;
    	if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc)))
        	return (int)pmc.WorkingSetSize;
	')
	#end
	public static function get_process_memory():Int {
		return 0;
	}
	#end
}
