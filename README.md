# :package: Ansible Bundler

Ansible Bundler embeds together a full playbook and its dependencies so you can run it it from a
single binary on _any*_ computer, having just Python as a host dependency - you don't even need
Ansible! Think of it as [`makeself`](https://makeself.io/) for Ansible playbooks.

The closest that Ansible provides natively for this is `ansible-pull`, but it requires the host to
have Ansible properly installed, and you need to manage the playbook location yourself.

While playbooks were never meant to be used as standalone packages, Ansible offers tools to help on
more complex deployments, such as [Tower](https://www.ansible.com/products/tower) and
[AWX](https://github.com/ansible/awx) _(Tower's open-source upstream project)_.

<sub>* Well, we currently only support Unix based OSes.</sub>

## Use case

Ansible is awesome. It's so powerful and flexible that we can use from server provisioning to
automating mundane tasks such as bootstraping [your own](https://github.com/kriansa/dotfiles)
computer. 

One thing that it lacks though is the ability to be used for simple auto scaling deployments where
you just want to pull a playbook and run it easily. Currently, you need to setup Ansible, ensure you
have a repository to download the files, manage the right permissions to it and then run
`ansible-pull`. This can get harder when you have more complex playbooks with several dependencies.

Ansible Bundler makes these steps easier by having a single binary that takes care of setting up
Ansible on the host and executing the playbook without having to do anything globally (such as
installing ansible). You can simply pull the playbook binary and execute it right away.

## Installation

Currently you can download and install it using the pre-built packages that are available in RPM and
DEB formats on [Github releases](https://github.com/kriansa/ansible-bundler/releases). They should
work on most RHEL-based distros (CentOS, Fedora, Amazon Linux, etc) as well as on Debian-based
distros (Ubuntu, Mint, etc). There's also a [AUR
available](https://aur.archlinux.org/packages/ansible-bundler/) if you're using Arch.

You can also install it using homebrew if you're on macOS:

```shell
$ brew install kriansa/tap/ansible-bundler

```

If your distro is not compatible with the prebuilt packages, please refer to [Building](#building)
below.

## Usage

##### Generate a new self-contained playbook:

```shell
$ bundle-playbook -f playbook.yml
```

##### Run it on the host:

```shell
$ ./playbook.run
```

> You will need Python on the host in order to run the final executable. :+1:

##### Advanced build

```shell
$ bundle-playbook --playbook-file=playbook.yml \
  --requirements-file=requirements.yml \
  --vars-file=vars.yml \
  --ansible-version=2.8.0 \
  --python-package=boto3 \
  --extra-deps=files
```

> By default, all files on `roles` folder in the same path as the playbook.yml are automatically
> included. If you need more dependent files, you can specify them using `--extra-deps` (short
> `-d`).

Run `bundle-playbook --help` to get a list of all possible parameters.

#### Binary interface

The built playbook binary has a few options that you can use at runtime. Here are the options you
can currently use:

```
--help            Show this help message and exit
--debug           Run the packaged bundler with verbose logging
--keep-temp       Keep extracted files into the tempfolder after finishing. This is 
                  useful for debugging purposes
-e <EXTRA_VARS>, --extra-vars=<EXTRA_VARS>
                  Set additional variables as key=value or YAML/JSON, or a filename if
                  prepended with @. You can pass this parameter multiple times. This will
                  take precedence on the variables that have been previously defined on
                  the packaged playbook.
```

---

## Development

This section should be read by anyone planning to contribute to this project.

### Building

You will need Docker installed on your machine. When you have it installed, you can proceed
installing the dependencies with:

```shell
$ make deps
```

This is only required once. After that you're good to go. You can currently build the package in a
directory structure that you can later copy to your root filesystem. This is very useful as a base
for building OS packages for most package managers such as RPM or DEB.

```shell
$ make
```

> The output will be at `build/pkg`

Additionally, we offer support for building `deb` and `rpm` artifacts out of the box:

```shell
$ make deb rpm
```

### Running local build

```shell
# Starting from the root of this repository, run this command:
cd build/pkg/usr/bin 

# Employ the basic playbook example
./bundle-playbook -f ../../../../examples/basic.yaml

# Run the playbook
../../../../examples/basic.run -e example=VALUE
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would
like to change.

Please make sure to update tests as appropriate. For more information, please refer to
[Contributing](CONTRIBUTING.md).

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE.md](LICENSE.md) file for
details.
