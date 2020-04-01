#!/bin/sh
#
# This is a packaged ansible playbook file using Ansible Bundler v$VERSION.
# You can run this with --debug to show more information about the process.

# This is how many lines we need to skip to consider this file a binary tar.gz - this value is
# calculated at build-time, so we just need to keep this placeholder here.
UNCOMPRESS_SKIP=0

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

main() {
	args=""

	while [ $# -gt 0 ]; do
		case "$1" in
			# Show debug logs
			--debug) DEBUG=1 && shift ;;

			# Keep extracted files into the tempfolder. Useful for debugging
			--keep-temp) KEEP_TEMP=1 && shift ;;

			# Passthrough directly to the run-playbook.sh
			-e|--extra-vars)
				args="$args --extra-vars \"$(escape_quotes "$2")\""
				shift 2
				;;
			--extra-vars=*)
				args="$args --extra-vars \"$(escape_quotes "${1#*=}")\""
				shift 1
				;;

			# Show help message
			--help|-h) help && exit ;;

			# Ignore all other parameters
			*) invalid_parameter_error "$1" && exit 1 ;;
		esac
	done

	# Trick to get the params parsed correctly on POSIX shell. I would much love not to have this kind
	# of sorcery in the code and just use Bash arrays, but then it would be hard to be compatible with
	# BSD. Anyway, what this does is that it will set the positional arguments ($1, $2, $3, etc) to
	# the ones set in $extra_params using the escaped variables that we got from CLI. The function
	# escape_quotes plays an essential role here, because it will ensure that double quotes coming
	# from user input will be escaped properly. Then, we will use the $@ below with the parameters
	# correctly assigned as ansible-playbook args.
	eval "set -- $args"

	create_tmpfolder
	extract_content
	run_entrypoint "$@"
}

# Escapes any double quotes with backslashes
escape_quotes() {
	printf '%s' "$1" | sed -E 's/"/\\"/g'
}

invalid_parameter_error() {
	param=$1

	echo "Invalid parameter $param"
	echo "Please use $0 --help to see all available options."
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

	# Ensure we are compatible with both bsd and GNU tar
	extra_params=""
	tar --version | grep 'GNU tar' > /dev/null 2>&1 && extra_params="--warning=no-timestamp"

	tail -n +$UNCOMPRESS_SKIP "$0" | tar xzC "$tmpdir" $extra_params
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
