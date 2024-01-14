// Copyright (c) 2024 Epic Games Tools
// Licensed under the MIT license (https://opensource.org/license/mit/)

#ifndef MAC_H
#define MAC_H

////////////////////////////////
//~ NOTE(allen): Get all these linux includes

#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <limits.h>
#include <time.h>
#include <dirent.h>
#include <pthread.h>
#include <sys/syscall.h>
#include <signal.h>
#include <errno.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
// #include <sys/sysinfo.h>

////////////////////////////////
//~ NOTE(allen): File Iterator

typedef struct MAC_FileIter MAC_FileIter;
struct MAC_FileIter{
  int fd;
  DIR *dir;
};
StaticAssert(sizeof(Member(OS_FileIter, memory)) >= sizeof(MAC_FileIter), file_iter_memory_size);

////////////////////////////////
//~ NOTE(allen): Threading Entities

typedef enum MAC_EntityKind
{
  MAC_EntityKind_Null,
  MAC_EntityKind_Thread,
  MAC_EntityKind_Mutex,
  MAC_EntityKind_ConditionVariable,
}
MAC_EntityKind;

typedef struct MAC_Entity MAC_Entity;
struct MAC_Entity{
  MAC_Entity *next;
  MAC_EntityKind kind;
  volatile U32 reference_mask;
  union{
    struct{
      OS_ThreadFunctionType *func;
      void *ptr;
      pthread_t handle;
    } thread;
    pthread_mutex_t mutex;
    pthread_cond_t cond;
  };
};

////////////////////////////////
//~ NOTE(allen): Safe Call Chain

typedef struct MAC_SafeCallChain MAC_SafeCallChain;
struct MAC_SafeCallChain{
  MAC_SafeCallChain *next;
  OS_ThreadFunctionType *fail_handler;
  void *ptr;
};

////////////////////////////////
//~ NOTE(allen): Helpers

internal B32 mac_write_list_to_file_descriptor(int fd, String8List list);

internal void mac_date_time_from_tm(DateTime *out, struct tm *in, U32 msec);
internal void mac_tm_from_date_time(struct tm *out, DateTime *in);
internal void mac_dense_time_from_timespec(DenseTime *out, struct timespec *in);
internal void mac_file_properties_from_stat(FileProperties *out, struct stat *in);

internal String8 mac_string_from_signal(int signum);
internal String8 mac_string_from_errno(int error_number);

internal MAC_Entity* mac_alloc_entity(MAC_EntityKind kind);
internal void mac_free_entity(MAC_Entity *entity);
internal void* mac_thread_base(void *ptr);

internal void mac_safe_call_sig_handler(int);

#endif //MAC_H
