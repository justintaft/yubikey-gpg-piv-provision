Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-18.10"
  config.vm.provision :shell, path: "bootstrap.sh"
  config.vm.provider "virtualbox" do |vb|
    vb.customize ['modifyvm', :id, '--usb', 'on']
    vb.customize ['modifyvm', :id, '--usbehci', 'on']
  end

end

