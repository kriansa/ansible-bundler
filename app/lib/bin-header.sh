#!/bin/sh
#
# This is a packaged ansible playbook file using Ansible Bundler v$VERSION.
# You can run this with --debug to show more information about the process.

# This is how many lines we need to skip to consider this file a binary tar.gz - this value is
# calculated at build-time, so we just need to keep this placeholder here.
UNCOMPRESS_SKIP=0

main() {
	# Set the DEBUG flag to display debug logs
	test "$1" = "--debug" && export DEBUG=1

	create_tmpfolder
	extract_content
	run_entrypoint
}

create_tmpfolder() {
	tmpdir="$(mktemp -d "/tmp/ansible-bundle.XXXXX")"
	# shellcheck disable=SC2064
	trap "log 'Finished!'; rm -rf '$tmpdir'" EXIT
}

extract_content() {
	log "Extracting bundle contents..."
	tail -n +$UNCOMPRESS_SKIP "$0" | tar xzC "$tmpdir"
}

run_entrypoint() {
	log "Running entrypoint..."
	( cd "$tmpdir" && ./run-playbook.sh )
}

log() {
	test -n "$DEBUG" && echo "$@"
}

# Ensure we run main and exit afterwards, so we don't end up reading garbage
main "$@"
exit

# Below this line is the content of the compressed ansible playbook.
