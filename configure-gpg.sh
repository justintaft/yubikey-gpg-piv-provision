#!/usr/bin/env bash

source support/gpg-common.sh

init_config
ask_for_gpg_key_passwords
ask_for_gpg_key_person_info


#Temporary directory
KEY_OUTPUT_DIR="/tmp/gpg.$EPOCH_TIME"

#Final directory key will be moved to if import was successful."
FINAL_KEY_OUTPUT_DIR="/vagrant/output/gpg.$EPOCH_TIME"

mkdir -p $KEY_OUTPUT_DIR



log "Generating RSA 4096 master key."

MASTER_KEY_GEN_OUTPUT=$(generate_master_key)
KEY_ID=$(echo -e "$MASTER_KEY_GEN_OUTPUT" | grep "marked as" | sed 's/ marked as .*$//g' | sed 's/gpg: key //g')


log "Generating RSA 4096 sign sub key."
generate_RSA_4096_sign_sub_key 2>/dev/null

log "Generating RSA 4096 encryption sub key."
generate_RSA_4096_encryption_sub_key  2> /dev/null

log "Generating RSA 4096 authentication sub key."
generate_RSA_4096_authentication_sub_key 2> /dev/null

log "Setting key preferences."
set_key_prefs 2> /dev/null

log "Exporitng public keys."
gpg -a --export >  "$KEY_OUTPUT_DIR/public_keys"

log "Exporting private keys."
echo "$MASTER_PASSPHRASE" | gpg -a --batch --passphrase-fd 0 --export-secret-keys --pinentry-mode loopback > "$KEY_OUTPUT_DIR/all_private_keys"

log "Exporting private subkeys."
echo "$MASTER_PASSPHRASE" | gpg -a --batch --passphrase-fd 0 --export-secret-subkeys --pinentry-mode loopback > "$KEY_OUTPUT_DIR/all_sub_keys"

if  bash ./restore-gpg.sh "$KEY_OUTPUT_DIR"; then 
    mv "$KEY_OUTPUT_DIR" "$FINAL_KEY_OUTPUT_DIR"
    log "Exported keys have been stored in $FINAL_KEY_OUTPUT_DIR"
fi


	


