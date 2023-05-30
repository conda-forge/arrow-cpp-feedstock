#!/bin/bash

# for the gdb-wrappers, we need to create a symlink that
# contains the full path of the lib _within_ the installed
# env, which we don't have until the env is created.

# doesn't come with a deactivate script, because the symlink
# is benign and doesn't need to be deleted.

_la_log() {
    if [ "$LIBARROW_ACTIVATE_LOGGING" = "1" ]; then
        echo "DEBUG ${BASH_SOURCE[0]}: $*"
    fi
}

_la_log "Beginning libarrow activation."

# where the GDB wrappers get installed
_la_gdb_prefix="$CONDA_PREFIX/share/gdb/auto-load"

# this needs to be in sync with ARROW_GDB_INSTALL_DIR in build.sh
PLACEHOLDER="replace_this_section_with_absolute_slashed_path_to_CONDA_PREFIX"
# the paths here are intentionally stacked, see #935, resp.
# https://github.com/apache/arrow/blob/master/docs/source/cpp/gdb.rst#manual-loading
WRAPPER_DIR="$_la_gdb_prefix/$CONDA_PREFIX/lib"

_la_log "   _la_gdb_prefix: $_la_gdb_prefix"
_la_log "  PLACEHOLDER: $PLACEHOLDER"
_la_log "  WRAPPER_DIR: $WRAPPER_DIR"

mkdir -p "$WRAPPER_DIR" || true
# If the directory is not writable, nothing can be done
if [ ! -w "$WRAPPER_DIR" ]; then
    _la_log "Wrapper directory '$WRAPPER_DIR' is not writable, aborting."
    return
fi

# there's only one lib in the placeholder folder, but the libname changes
# based on the version so use a loop instead of hardcoding it.
for target in "$_la_gdb_prefix/$PLACEHOLDER/lib/"*.py; do
    if [ ! -e "$target" ]; then
        # If the file doesn't exist, skip this iteration of the loop.
        # (This happens when no files are found, in which case the
        # loop runs with target equal to the pattern itself.)
        _la_log "Skipping extraneous iteration with target as match pattern '$target'"
        continue
    fi
    symlink="$WRAPPER_DIR/$(basename "$target")"
    # Check if symbolic link already exists and points to correct file
    if [ -L "$symlink" ] && [ "$(readlink "$symlink")" = "$target" ]; then
        # Stop if it does
        _la_log "Symlink '$symlink' already exists and points to '$target', skipping."
        continue
    fi
    _la_log "Creating symlink '$symlink' pointing to '$target'"
    ln -sf "$target" "$symlink"
done

_la_log "Libarrow activation complete."

unset _la_log
unset _la_gdb_prefix
