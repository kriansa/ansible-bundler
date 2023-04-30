class AnsibleBundler < Formula
    include Language::Python::Virtualenv
  
    desc "Ansible Bundler provides the ability to bundle and execute an Ansible Playbook as a binary."
    homepage "https://github.com/cowdogmoo/ansible-bundler"
    url "https://github.com/cowdogmoo/ansible-bundler/archive/refs/heads/master.tar.gz"
    version "2023.04.26"
    sha256 "742f9b70a400a45790bf90e7901635f2686ec339a906edfd8d4fc6afe1e109bb"
    license "BSD 3"
    depends_on "python@3.11"
  
    def install
      bin.install "app/bin/bundle-playbook"
      lib.install Dir["app/lib/*"]
      (etc/"ansible-bundler").install "app/etc/ansible.cfg"

      # Update the bundle-playbook script to use the correct path for the ansible.cfg file and use the correct shell (zsh by default in macOS)
      inreplace "#{bin}/bundle-playbook", /^#!\/usr\/bin\/env bash/, "#!/usr/bin/env zsh"
      # Create the necessary directories and copy the examples
      pkgshare.install "examples"
    end
  
    def caveats
      <<~EOS
        Example usage:

        # Employ the basic playbook example
        bundle-playbook -f #{pkgshare}/examples -o basic
        
        # Run the basic playbook binary and provide an input for the example variable.
        ./basic -e example=VALUE
      EOS
    end

    test do
      # Test your project here
      system "#{bin}/bundle-playbook", "--version"
    end
  end
  