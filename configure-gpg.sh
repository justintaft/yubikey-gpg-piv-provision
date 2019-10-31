#!/usr/bin/env bash

source gpg-common.sh

log "Generating RSA 4096 master key."
MASTER_KEY_GEN_OUTPUT=$(generate_master_key)
KEY_ID=$(echo -e "$MASTER_KEY_GEN_OUTPUT" | grep "marked as" | sed 's/ marked as .*$//g' | sed 's/gpg: key //g')

log "Generating RSA 4096 sign sub key."
generate_RSA_4096_sign_sub_key 2> /dev/null

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

log "Moving Subkey to YUBIKEY"
key_to_card "1" "1"
key_to_card "2" "2"
key_to_card "3" "3"


log "Setting touch policy to be required for encryption signature and authentication operations"
enable_touch_policy_for_all_actions
sleep 2

log "Testing encryption and decryption"
log "Generating encrypted message to yourself..."
log "Hello world!" | gpg -a --encrypt --recipient "$EMAIL" > /tmp/message.enc
log "Decrypting message. After typing GPG User Pin, the yubikey should require a physical touch to complete decryption."
gpg --decrypt /tmp/message.enc


log "Setting up ssh-agent to use gpg"
killall ssh-agent
gpg-connect-agent updatestartuptty /bye
