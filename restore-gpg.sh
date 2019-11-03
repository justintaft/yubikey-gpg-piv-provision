#!/usr/bin/env bash

source support/gpg-common.sh

if [[ $1 == "" ]]; then
	log "ERROR: Provide argument to GPG key backup directory (ex ./$0 output/gpg.1234)"
	exit 1;
fi

GPG_KEY_PATH="$(realpath -s $1)"
GPG_PRIV_KEY_PATH="$GPG_KEY_PATH/all_private_keys"


if [[ ! -d "$GPG_KEY_PATH" || ! -f  "$GPG_PRIV_KEY_PATH" ]]; then
        log "Supplied path does not contain gpg keys."
	exit 1;
fi

init_config
init_yubikey_setup
ask_for_gpg_key_passwords


# Make copy of encrypted keys to temporary directory.
# gpg's import command can be desctructive 
# (ie, modifying original key file and leaving a stub behind).
CLONED_KEY_TEMP_DIR=`mktemp -d`
cp  -R "$GPG_KEY_PATH/." "$CLONED_KEY_TEMP_DIR/"

#Import public keys
#gpg --import "$CLONED_KEY_TEMP_DIR"/public_keys 2>&1 | grep "gpg: key" | head -n1 | sed 's/gpg: key //g' | sed 's/:.*//g'

log "Killing gpg agent before import."
sudo killall gpg-agent

#Import private keys
log "Importing private keys to GPG."

KEY_ID=`gpg --import "$CLONED_KEY_TEMP_DIR"/all_private_keys 2>&1 | grep "gpg: key" | head -n1 | sed 's/gpg: key //g' | sed 's/:.*//g'`

#log "Moving Subkeys to YUBIKEY"
key_to_card "1" "1"
key_to_card "2" "2"
key_to_card "3" "3"


echo "Setting touch policy to be required for encryption signature and authentication operations"
enable_touch_policy_for_all_actions
sleep 2

#Get imported key id. As we clear gnupg at beginning of script, there should
#only be one key.
RECIPIENT=`gpg --list-keys --with-colons | awk -F: '/^pub:/ { print $5 }'`

log "Testing encryption and decryption"
log "Testing encryption and decryption. You should be prompted for PIN.  After typing GPG User Pin, the yubikey should require a physical touch to complete decryption."
echo "Hello world!" | gpg -a --encrypt --recipient "$RECIPIENT" --always-trust | gpg --decrypt 


if [[ $? -ne 0 ]]; then
	log "Failed to decrypt test message. Setup is not successful."
	exit
fi

if echo "DECRYPTEDMSG" | grep "Hello world!"; then
	log "Failed to decrypt test message. Setup is not successful."
	exit
fi

log "Decrypted message successfully."

log "IMPORTANT! If you were asked for a PIN (not a passphrase), and had to touch the yuibkey to decrypt, setup was succesful. Otherwise, an error has occured. Re-insert yubikey and try again."

