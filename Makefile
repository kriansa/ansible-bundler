.PHONY =: clean package rpm deb deps release
.DEFAULT_GOAL := package
.SILENT : clean package rpm deb deps release

# Temporary paths for building the artifacts
build_dir=build/pkg
dist_dir=build/dist

# Variables that are replaced in build time
bin_path=.
lib_path=../lib/ansible-bundler
etc_path=../../etc/ansible-bundler
version=$(shell cat VERSION)

# Package variables
package_name=ansible-bundler
package_license=3-Clause BSD
package_vendor=Daniel Pereira
package_maintainer=<daniel@garajau.com.br>
package_url=https://github.com/kriansa/ansible-bundler

deps:
	docker pull docker.io/skandyla/fpm

clean:
	rm -rf $(build_dir) $(dist_dir)
	rmdir $(shell dirname $(build_dir)) 2> /dev/null || true

package:
	@test -d $(build_dir) && echo "Build dir already exists! Run make clean before." && exit 1 || true
	mkdir -p $(build_dir)/{etc,usr/lib}
	cp -r app/bin $(build_dir)/usr
	cp -r app/etc $(build_dir)/etc/ansible-bundler
	cp -r app/lib $(build_dir)/usr/lib/ansible-bundler
	UNAME=$$(uname); \
	if [ "$$UNAME" == 'Darwin' ]; then \
		SED_BINARY=$$(which gsed); \
	else \
		SED_BINARY=$$(which sed); \
	fi; \
	$$SED_BINARY -i'' \
		-e 's#LIB_PATH=.*#LIB_PATH=$(lib_path)#' \
		-e 's#ETC_PATH=.*#ETC_PATH=$(etc_path)#' \
		-e 's#VERSION=.*#VERSION=$(version)#' \
		-e 's/%VERSION%/$(version)/' \
		$(build_dir)/usr/bin/bundle-playbook
	echo "Built package v$(version) on directory '$(build_dir)'"

deb:
	test -d $(dist_dir) || mkdir -p $(dist_dir)
	docker run -it --rm -v "$(shell pwd):/mnt" --entrypoint '' skandyla/fpm \
		/bin/bash -c 'fpm -n "$(package_name)" -s dir -t deb -v $(version) \
		--config-files /etc/ansible-bundler/ansible.cfg --deb-no-default-config-files \
		--license "$(package_license)" --vendor "$(package_vendor)" \
		--maintainer "$(package_maintainer)" --url "$(package_url)" \
		-p /mnt/$(dist_dir) -C /mnt/$(build_dir) . > /dev/null \
		&& chown $(shell id -u):$(shell id -g) /mnt/$(dist_dir)/*.deb'
	echo "DEB package build successfully into $(dist_dir)"

rpm:
	test -d $(dist_dir) || mkdir -p $(dist_dir)
	docker run -it --rm -v "$(shell pwd):/mnt" --entrypoint '' skandyla/fpm \
		/bin/bash -c 'fpm -n "$(package_name)" -s dir -t rpm -v $(version) \
		--config-files /etc/ansible-bundler/ansible.cfg \
		--license "$(package_license)" --vendor "$(package_vendor)" \
		--maintainer "$(package_maintainer)" --url "$(package_url)" \
		-p /mnt/$(dist_dir) -C /mnt/$(build_dir) . > /dev/null \
		&& chown $(shell id -u):$(shell id -g) /mnt/$(dist_dir)/*.rpm'
	echo "RPM package build successfully into $(dist_dir)"

release:
	# Get only the artifacts for this release version
	$(eval rpm_package := $(shell ls $(dist_dir)/ansible-bundler-$(version)*.rpm))
	$(eval deb_package := $(shell ls $(dist_dir)/ansible-bundler_$(version)*.deb))

	# This task uses my own release helper, available here:
	# https://github.com/kriansa/dotfiles/blob/master/plugins/git/bin/git-release
	git release $(version) --sign --use-version-file --artifact="$(rpm_package)" --artifact="$(deb_package)"
