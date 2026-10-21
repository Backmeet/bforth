#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int ensure_directory(const char *path) {
    if (CreateDirectoryA(path, NULL)) {
        return 1;
    }
    return GetLastError() == ERROR_ALREADY_EXISTS;
}

int get_builder_root(char *buffer, size_t capacity) {
    DWORD length = GetModuleFileNameA(NULL, buffer, (DWORD)capacity);
    if (length == 0 || length >= capacity) {
        return 0;
    }

    // build.exe lives at <project>/builds/exes/build.exe. Strip those three
    // path components so the builder works from any current directory.
    for (int component = 0; component < 3; component++) {
        char *slash = strrchr(buffer, '\\');
        char *forward = strrchr(buffer, '/');
        if (forward != NULL && (slash == NULL || forward > slash)) {
            slash = forward;
        }
        if (slash == NULL) {
            return 0;
        }
        *slash = '\0';
    }
    return 1;
}

int is_canonical_builder(void) {
    char path[MAX_PATH];
    DWORD length = GetModuleFileNameA(NULL, path, MAX_PATH);
    const char *suffix = "\\builds\\exes\\build.exe";
    size_t suffix_length = strlen(suffix);
    if (length == 0 || length >= MAX_PATH || length < suffix_length) {
        return 0;
    }
    for (DWORD i = 0; i < length; i++) {
        if (path[i] == '/') {
            path[i] = '\\';
        }
    }
    return lstrcmpiA(path + length - suffix_length, suffix) == 0;
}

char **get_children(const char *path) {
    DWORD path_length = GetFullPathNameA(path, 0, NULL, NULL);
    if (path_length == 0) {
        return NULL;
    }

    char *absolute_path = malloc(path_length);
    if (absolute_path == NULL) {
        return NULL;
    }

    DWORD result = GetFullPathNameA(path, path_length, absolute_path, NULL);
    if (result == 0 || result >= path_length) {
        free(absolute_path);
        return NULL;
    }

    size_t base_length = strlen(absolute_path);
    int separator = base_length > 0 &&
                    absolute_path[base_length - 1] != '\\' &&
                    absolute_path[base_length - 1] != '/';

    size_t pattern_length = base_length + separator + 2;
    char *pattern = malloc(pattern_length);
    if (pattern == NULL) {
        free(absolute_path);
        return NULL;
    }

    snprintf(pattern, pattern_length, "%s%s*", absolute_path,
             separator ? "\\" : "");

    WIN32_FIND_DATAA data;
    HANDLE handle = FindFirstFileA(pattern, &data);
    free(pattern);

    if (handle == INVALID_HANDLE_VALUE) {
        free(absolute_path);
        return NULL;
    }

    size_t capacity = 16;
    size_t count = 0;
    char **children = malloc(capacity * sizeof(char *));

    if (children == NULL) {
        FindClose(handle);
        free(absolute_path);
        return NULL;
    }

    do {
        if (strcmp(data.cFileName, ".") == 0 ||
            strcmp(data.cFileName, "..") == 0) {
            continue;
        }

        size_t name_length = strlen(data.cFileName);
        size_t full_length = base_length + separator +
                             name_length + 1;

        char *full_path = malloc(full_length);
        if (full_path == NULL) {
            goto error;
        }

        snprintf(full_path, full_length, "%s%s%s", absolute_path,
                 separator ? "\\" : "", data.cFileName);

        if (count + 1 >= capacity) {
            size_t new_capacity = capacity * 2;
            char **new_children = realloc(
                children, new_capacity * sizeof(char *)
            );

            if (new_children == NULL) {
                free(full_path);
                goto error;
            }

            children = new_children;
            capacity = new_capacity;
        }

        children[count++] = full_path;
    } while (FindNextFileA(handle, &data));

    children[count] = NULL;

    FindClose(handle);
    free(absolute_path);

    return children;

error:
    for (size_t i = 0; i < count; i++) {
        free(children[i]);
    }

    free(children);
    FindClose(handle);
    free(absolute_path);

    return NULL;
}

void free_children(char **children) {
    if (children == NULL) {
        return;
    }

    for (size_t i = 0; children[i] != NULL; i++) {
        free(children[i]);
    }

    free(children);
}
