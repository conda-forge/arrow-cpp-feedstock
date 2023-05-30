#!/bin/bash

# for the gdb-wrappers, we need to create a symlink that
# contains the full path of the lib _within_ the installed
# env, which we don't have until the env is created.

# doesn't come with a deactivate script, because the symlink
# is benign and doesn't need to be deleted.

# where the GDB wrappers get installed
GDB_PREFIX="$CONDA_PREFIX/share/gdb/auto-load"

# this needs to be in sync with ARROW_GDB_INSTALL_DIR in build.sh
PLACEHOLDER="replace_this_section_with_absolute_slashed_path_to_CONDA_PREFIX"
# the paths here are intentionally stacked, see #935, resp.
# https://github.com/apache/arrow/blob/master/docs/source/cpp/gdb.rst#manual-loading
WRAPPER_DIR="$GDB_PREFIX/$CONDA_PREFIX/lib"

mkdir -p "$WRAPPER_DIR" || true
# If the directory is not writable, nothing can be done
if [ ! -w "$WRAPPER_DIR" ]; then
    return
fi

# there's only one lib in the placeholder folder, but the libname changes
# based on the version so use a loop instead of hardcoding it.
for target in "$GDB_PREFIX/$PLACEHOLDER/lib/"*.py; do
    if [ ! -e "$target" ]; then
        # If the file doesn't exist, skip this iteration of the loop.
        # (This happens when no files are found, in which case the
        # loop runs with target equal to the pattern itself.)
        continue
    fi
    symlink="$WRAPPER_DIR/$(basename "$target")"
    # Check if symbolic link already exists and points to correct file
    if [ -L "$symlink" ] && [ "$(readlink "$symlink")" = "$target" ]; then
        # Stop if it does
        continue
    fi
    ln -sf "$target" "$symlink"
done
