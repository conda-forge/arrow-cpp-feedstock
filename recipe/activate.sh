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
_la_placeholder="replace_this_section_with_absolute_slashed_path_to_CONDA_PREFIX"
# the paths here are intentionally stacked, see #935, resp.
# https://github.com/apache/arrow/blob/master/docs/source/cpp/gdb.rst#manual-loading
_la_wrapper_dir="$_la_gdb_prefix/$CONDA_PREFIX/lib"

_la_log "   _la_gdb_prefix: $_la_gdb_prefix"
_la_log "  _la_placeholder: $_la_placeholder"
_la_log "  _la_wrapper_dir: $_la_wrapper_dir"

# there's only one lib in the _la_placeholder folder, but the libname changes
# based on the version so use a loop instead of hardcoding it.
for target in "$_la_gdb_prefix/$_la_placeholder/lib/"*.py; do
    if [ ! -e "$target" ]; then
        # If the file doesn't exist, skip this iteration of the loop.
        # (This happens when no files are found, in which case the
        # loop runs with target equal to the pattern itself.)
        _la_log "Skipping extraneous iteration with target as match pattern '$target'"
        continue
    fi
    _la_symlink="$_la_wrapper_dir/$(basename "$target")"
    if [ -L "$_la_symlink" ] && [ "$(readlink "$_la_symlink")" = "$target" ]; then
        _la_log "symlink '$_la_symlink' already exists and points to '$target', skipping."
        continue
    fi
    _la_log "Creating symlink '$_la_symlink' pointing to '$target'"
    mkdir -p "$_la_wrapper_dir" || true
    # If the directory is not writable, nothing can be done
    if [ ! -w "$_la_wrapper_dir" ]; then
        echo -n "${BASH_SOURCE[0]} ERROR: Wrapper directory '$_la_wrapper_dir' is not "
        echo -n "writable, so we can't create the symlink '$_la_symlink' pointing to "
        echo -n "'$target'."
        echo
        continue
    fi
    ln -sf "$target" "$_la_symlink"
done

_la_log "Libarrow activation complete."

unset _la_log
unset _la_gdb_prefix
unset _la_placeholder
unset _la_wrapper_dir
unset _la_symlink
