Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-18.10"
  config.vm.provision :shell, path: "bootstrap.sh"

  config.trigger.before [:up] do |trigger|

    config.vm.provider "virtualbox" do |vb|
      vb.customize ['modifyvm', :id, '--usb', 'on']
      vb.customize ['modifyvm', :id, '--usbehci', 'on']

      val = `VBoxManage list usbhost | perl -e '$in = join("",<STDIN>); $in =~ /(UUID.*?Yubico.*?)Current State/s; print $1';`
      
      vendorId = /VendorId:.*? (0x[^\s]*)/.match(val)[1]
      productId = /ProductId:.*? (0x[^\s]*)/.match(val)[1]

      vb.customize ['usbfilter', 'add', '0', '--target', :id, '--name', 'YubiKey', '--vendorid', vendorId, '--productid', productId]

    end

  end
end


