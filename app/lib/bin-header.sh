#!/bin/sh
#
# This is a packaged ansible playbook file using Ansible Bundler v$VERSION.
# You can run this with --debug to show more information about the process.

# This is how many lines we need to skip to consider this file a binary tar.gz - this value is
# calculated at build-time, so we just need to keep this placeholder here.
UNCOMPRESS_SKIP=0

main() {
	# Show debug logs
	test "$1" = "--debug" && shift && DEBUG=1

	# Keep extracted files into the tempfolder. Useful for debugging
	test "$1" = "--keep-temp" && shift && KEEP_TEMP=1

	# Show help page
	if test "$1" = "--help" || test "$1" = "-h"; then 
		help
		exit
	fi

	create_tmpfolder
	extract_content
	run_entrypoint "$@"
}

help() {
	echo "Usage: $0 [OPTIONS]"
	echo
	echo "This is a playbook packaged using Ansible Bundler v$VERSION"
	echo
	echo "Options:"
	echo "  --help            Show this help message and exit"
	echo "  --debug           Run the packaged bundler with verbose logging"
	echo "  --keep-temp       Keep extracted files into the tempfolder after finishing. This is"
	echo "                    useful for debugging purposes"
	echo "  -e <EXTRA_VARS>, --extra-vars=<EXTRA_VARS>"
	echo "                    Set additional variables as key=value or YAML/JSON, or a filename if"
	echo "                    prepended with @. You can pass this parameter multiple times. This will"
	echo "                    take precedence on the variables that have been previously defined on"
	echo "                    the packaged playbook."
}

create_tmpfolder() {
	tmpdir="$(mktemp -d "/tmp/ansible-bundle.XXXXX")"

	if [ -n "$KEEP_TEMP" ]; then
		trap "log 'Done.'" EXIT
	else
		# shellcheck disable=SC2064
		trap "log 'Finished, removing temp content...'; rm -rf '$tmpdir'; log 'Done.'" EXIT
	fi
}

extract_content() {
	log "Extracting bundle contents to ${tmpdir}..."
	tail -n +$UNCOMPRESS_SKIP "$0" | tar xzC "$tmpdir"
}

run_entrypoint() {
	log "Running entrypoint..."
	BASEDIR="$tmpdir" "$tmpdir/run-playbook.sh" "$@"
}

log() {
	test -n "$DEBUG" && echo "[$(date '+%Y-%m-%d %H:%I:%S %Z')]" "$@"
}

# Ensure we run main and exit afterwards, so we don't end up reading garbage
main "$@"
exit

# Below this line is the content of the compressed ansible playbook.
