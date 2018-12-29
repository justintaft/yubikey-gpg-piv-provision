# Yubikey Auto GPG Config

*WARNING! USE PROJECT AT YOUR OWN RISK! Running the VM will reset the GPG application on the inserted Yubikey, including pins, public keys, and private keys sotred on the YUBIKEY.*

## Description

Easily provision a new yubikey for use.

**Running the project will:**

- Setup user and admin GPG pins for yubikey
- Generate RSA 4096 bit keys for the yubikey (master and sub keys)
- Upload generated keys to USB

**Known issues*:*

- Provsining in a VM is not as secure as a live-distro, which does not have disk access.
- Yubikey USB passthrough must be explicitly done through virtualbox menus 
- Entropy needs to be injected through the system for secure seed generation.
- Keys are exported to ~/ , but user is not notified 
- Revocation certificate not moved to ~/
- Method not provided to restore keys

