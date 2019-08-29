#!/usr/bin/env bash
#
# This is the entry point for the playbook bundle. It has a hard dependency on Python. It will try
# to look for an already existing installation of Ansible, and will try to install it if not found.
#
# Then, it will run the playbook.yml locally file using ansible.

main() {
	# You must call this using BASEDIR so it can locate the right path where the temp bundle was
	# extracted. If you don't, it will use the current working dir (cwd).
	export BASEDIR=${BASEDIR:-.}

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

run_playbook() {
	local extra_params=()

	# Add bundled extra-vars parameter if existent
	test -r "$BASEDIR/vars.yml" && extra_params+=("--extra-vars=@$BASEDIR/vars.yml")

	# Then add runtime extra-vars, if passed
	while [ $# -gt 0 ]; do
		case "$1" in
			-e|--extra-vars)
				extra_params+=("--extra-vars" "$2")
				shift 2
				;;
			--extra-vars=*)
				extra_params+=("--extra-vars" "${1#*=}")
				shift 1
				;;
		esac
	done

	# Run the playbook
	ANSIBLE_CONFIG="$BASEDIR/ansible.cfg" ansible-playbook --inventory="localhost," \
		--connection=local "${extra_params[@]}" "$BASEDIR/playbook.yml"
}

main "$@"
