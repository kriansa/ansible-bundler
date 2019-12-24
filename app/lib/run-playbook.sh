#!/bin/sh
#
# This is the entry point for the playbook bundle. It has a hard dependency on Python. It will try
# to look for an already existing installation of Ansible, and will try to install it if not found.
#
# Then, it will run the playbook.yml locally file using ansible.

main() {
	# You must call this using BASEDIR so it can locate the right path where the temp bundle was
	# extracted. If you don't, it will use the current working dir (cwd).
	export BASEDIR=${BASEDIR:-.}

	# Ensure we have HOME defined, otherwise set it manually
	test -z "$HOME" && export HOME; HOME="$(getent passwd "$(id -un)" | cut -d: -f6)"

	export PIP_ROOT_PATH; PIP_ROOT_PATH="$(realpath "${BASEDIR}/python-deps")"
	export PATH="${PIP_ROOT_PATH}/usr/bin:${PIP_ROOT_PATH}${HOME}/.local/bin:${PATH}"

	ensure_python_is_installed
	install_ansible

	# Export the right paths so we can run python binaries installed on non-default paths
	export PYTHONPATH; PYTHONPATH=$(find "$PIP_ROOT_PATH" -type d -name site-packages | head -1)

	run_playbook "$@"
}

ensure_python_is_installed() {
	if ! command -v python > /dev/null 2>&1 && ! command -v python3 > /dev/null 2>&1; then
		echo "Error: Python is not installed!"
		exit 1
	fi

	if ! command -v pip > /dev/null 2>&1 && ! command -v pip3 > /dev/null 2>&1; then
		echo "Error: Python pip is not found!"
		exit 1
	fi
}

pip() {
	if command -v pip3 > /dev/null 2>&1; then
		command pip3 "$@"
	else
		command pip "$@"
	fi
}

# Install ansible if needed
install_ansible() {
	echo "Installing playbook Python dependencies..."

	# We need to pass the absolute path to --root because there's a weird bug on PIP prevent
	# installing the bin directory when you just pass the relative path.
	#
	# Uses --no-cache-dir because in some memory constrained environments, pip tries to use too much
	# memory for the cache, which causes a MemoryError.
	# See: https://stackoverflow.com/questions/29466663/memory-error-while-using-pip-install-matplotlib
	pip install --requirement="$BASEDIR/requirements.txt" --no-cache-dir \
		--user --root="$PIP_ROOT_PATH"; status=$?

	if [ $status -ne 0 ]; then
		echo "Error: Python dependencies could not be installed."
		exit 1
	fi
}

# Escapes any double quotes with backslashes
escape_quotes() {
	printf '%s' "$1" | sed -E 's/"/\\"/g'
}

run_playbook() {
	extra_params=""

	# Add bundled extra-vars parameter if existent
	test -r "$BASEDIR/vars.yml" && extra_params="--extra-vars=@$BASEDIR/vars.yml"

	# Then add runtime extra-vars, if passed
	while [ $# -gt 0 ]; do
		case "$1" in
			-e|--extra-vars)
				extra_params="$extra_params --extra-vars \"$(escape_quotes "$2")\""
				shift 2
				;;
			--extra-vars=*)
				extra_params="$extra_params --extra-vars \"$(escape_quotes "${1#*=}")\""
				shift 1
				;;
			*) shift ;;
		esac
	done

	# Trick to get the params parsed correctly on POSIX shell. I would much love not to have this kind
	# of sorcery in the code and just use Bash arrays, but then it would be hard to be compatible with
	# BSD. Anyway, what this does is that it will set the positional arguments ($1, $2, $3, etc) to
	# the ones set in $extra_params using the escaped variables that we got from CLI. The function
	# escape_quotes plays an essential role here, because it will ensure that double quotes coming
	# from user input will be escaped properly. Then, we will use the $@ below with the parameters
	# correctly assigned as ansible-playbook args.
	eval "set -- $extra_params"

	# Run the playbook
	# shellcheck disable=SC2086
	ANSIBLE_CONFIG="$BASEDIR/ansible.cfg" ansible-playbook --inventory="localhost," \
		--connection=local "$@" "$BASEDIR/playbook.yml"
}

main "$@"
