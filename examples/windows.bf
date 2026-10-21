#pragma once
#include "std.bf"

// Core Win32 handles and common constants (Windows x64 ABI).
typedef BOOL signed sized 32
typedef DWORD sized 32
typedef UINT sized 32
typedef WORD sized 16
typedef BYTE sized 8
typedef HANDLE sized 64
typedef HWND sized 64
typedef HINSTANCE sized 64
typedef HMODULE sized 64
typedef HDC sized 64
typedef HKEY sized 64
typedef LPARAM signed sized 64
typedef WPARAM sized 64
typedef LRESULT signed sized 64

#define INVALID_HANDLE_VALUE 0xFFFFFFFFFFFFFFFF
#define GENERIC_READ 0x80000000
#define GENERIC_WRITE 0x40000000
#define OPEN_EXISTING 3
#define CREATE_ALWAYS 2
#define SW_SHOW 5
#define SW_HIDE 0
#define MB_OK 0
#define MB_ICONERROR 0x10

// kernel32.dll
extern HINSTANCE GetModuleHandleA(sized 64 module_name)
extern HANDLE GetStdHandle(sized 32 standard_handle)
extern BOOL CloseHandle(sized 64 handle)
extern HANDLE CreateFileA(sized 64 path, sized 32 access, sized 32 share,
                          sized 64 security, sized 32 creation,
                          sized 32 flags, sized 64 template_file)
extern BOOL ReadFile(sized 64 file, sized 64 buffer, sized 32 count,
                     sized 64 bytes_read, sized 64 overlapped)
extern BOOL WriteFile(sized 64 file, sized 64 buffer, sized 32 count,
                      sized 64 bytes_written, sized 64 overlapped)
extern DWORD GetLastError()
extern void ExitProcess(sized 32 exit_code)
extern BOOL SetConsoleTitleA(sized 64 title)
extern DWORD GetCurrentDirectoryA(sized 32 capacity, sized 64 buffer)
extern BOOL SetCurrentDirectoryA(sized 64 path)
extern BOOL DeleteFileA(sized 64 path)
extern BOOL MoveFileA(sized 64 old_path, sized 64 new_path)
extern BOOL CreateDirectoryA(sized 64 path, sized 64 security)
extern BOOL RemoveDirectoryA(sized 64 path)

// user32.dll
extern int MessageBoxA(sized 64 window, sized 64 text, sized 64 caption,
                       sized 32 flags)
extern BOOL ShowWindow(sized 64 window, sized 32 command)
extern BOOL UpdateWindow(sized 64 window)
extern int GetSystemMetrics(sized 32 index)
extern void PostQuitMessage(sized 32 exit_code)

