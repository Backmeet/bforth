#pragma once
#include "std.bf"

// POSIX / common Unix process, file and terminal bindings.
typedef pid_t signed sized 32
typedef mode_t sized 32
typedef ssize_t signed sized 64
typedef off_t signed sized 64

#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR 2
#define O_CREAT 64
#define O_TRUNC 512
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

extern int open(sized 64 path, int flags)
extern int close(int fd)
extern ssize_t read(int fd, sized 64 buffer, size_t count)
extern ssize_t write(int fd, sized 64 buffer, size_t count)
extern off_t lseek(int fd, off_t offset, int whence)
extern int unlink(sized 64 path)
extern int chdir(sized 64 path)
extern pid_t getpid()
extern pid_t fork()
extern int execvp(sized 64 file, sized 64 argv)
extern void _exit(sized 32 status)
extern int isatty(int fd)
extern int mkdir(sized 64 path, mode_t mode)

