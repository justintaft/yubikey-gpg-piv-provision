# Yubikey GPG and PIV Provision

Easily provision a new yubikey for PIV and GPG use.

*WARNING! USE PROJECT AT YOUR OWN RISK! Running the VM will reset the inserted Yubikey's GPG and PIV application, including pins, public keys, and private keys stored on the YUBIKEY.*



## Known issues

- Provsining in a VM is not as secure as a live-distro, which does not have disk access.
- Entropy needs to be injected into the VM for secure seed generation.
- Revocation certificate is not exported for gpg
- PIV keys are NOT encrypted on export
- Method not provided to restore PIV keys

## Provision GPG


A 4096 bit RSA private keys for signing, authenticating, and encrypting will be generated and installed on yubikey.
Exported public key, master key, and sub key will be stored in the output/gpg directory.
The master and sub keys will be encrypted.
*Revocation certificate is NOT exported.*
*ENSURE TO BACKUP KEYS IN A SAFE PLACE.*


Run the following commands, and follow the output.

~~~
vagrant up
vagrant ssh
cd /vagrant
bash configure-gpg.sh
~~~

To use YUBIKEY key outside of VM, remove yubikey USB association with VM, remove and re-insert yuibkey from USB port, and run the following command:

~~~
gpg2 --import output/gpg*/public_keys
~~~


*WARNING: DO NOT use GPG's key to card functionality on any keys under the output directory. GPG modifies private key files and leaves the stubs behind, rendering the backed up private key useless.*


## Restore GPG key to yubikey created by `configure-gpg.sh`

To copy a backed up key exported by gpg, run the following command. Replace "gpg0.1234" with the directory containing the exported key.

~~~
vagrant up
vagrant ssh
cd /vagrant
bash restore-gpg.sh output/gpg.01234
~~~

## Provision PIV

Authentication, signing, and encryption ECC secp256r1 keys will be generated and uploaded to yubikey.
Public and private keys will be exported to output/piv directory.
*Private keys are NOT encrypted on export.*
*ENSURE TO BACKUP KEYS IN A SAFE PLACE.*

Run the following commands, and follow the output.

~~~
vagrant up
vagrant ssh
cd /vagrant
bash configure-piv.sh
~~~


