#!/usr/bin/env bash


EPOCH_TIME=`date +%s`
KEY_OUTPUT_DIR="/vagrant/output/gpg.$EPOCH_TIME"
mkdir -p $KEY_OUTPUT_DIR

function log() {
	echo "--- $1";
}

#Install deps
log "Installing deps"
sudo apt update -y
sudo apt install scdaemon gnupg2 pcscd pcsc-tools yubikey-manager -y


# Asks user for input. 
# VERIFIED_INPUT is set to input which used supplied.
function get_and_verify_input() {

    TMP_INPUT=""
    TMP_INPUT_VERIFY="123 ${TMP_INPUT}"

    while [ "$TMP_INPUT" != "$TMP_INPUT_VERIFY" ]; do

	echo -n "Type in a $1 (input hidden): "
        read -s TMP_INPUT
        echo ""

	echo -n "Retype $1 to verify (input hidden): " 
        read -s TMP_INPUT_VERIFY
        echo ""

        if  [ "$TMP_INPUT" != "$TMP_INPUT_VERIFY" ]; then
            echo "Input did not match."
        fi
        echo ""
    done
    export "$2=$TMP_INPUT_VERIFY"
}




YUBILINES=`lsusb | grep -i yubico`
FOUNDYUBI=$?

if [[ "$FOUNDYUBI" -ne 0 ]]; then
   log "Yubikey not found. Ensure yubikey is connected to host. If using vagrant, forward usb device to VM, unplug and re-insert yubikey, then try again."
   exit;
fi

YUBICOKEYCOUNT=`echo "$YUBILINES" | wc -l`
if [[ $YUBICOKEYCOUNT -ne 1 ]]; then
  log "Multiple yubikeys are connected to host. Only one yubikey can be configured at a time. Disconnect all but one yubikey and try again."
fi

log "Yubikey detected, contiuning setup."


get_and_verify_input "GPG Master Key Passphrase" "MASTER_PASSPHRASE"
get_and_verify_input "GPG Subkey Key Passphrase" "SUBKEY_PASSPHRASE"
get_and_verify_input "GPG Admin Pin"             "GPG_ADMIN_PIN"
get_and_verify_input "GPG User Pin" "GPG_USER_PIN"
get_and_verify_input "Real Name" "REAL_NAME"
get_and_verify_input "Email Address" "EMAIL"


# Moves key to card
# $1 is key index, $2 is GPG slot for smartcard
# GPG Slot Values: 1 sign 
#                  2 encrypt
#                  3 authenticate
function key_to_card()
{
  {
    echo key "$1"
    echo keytocard 
    echo "$2"
    #echo "y" #overwrite key if it exists
    echo "$MASTER_PASSPHRASE"
    echo "$GPG_ADMIN_PIN" # For some reason, it has to be entered twice sometimes...
    echo "$GPG_ADMIN_PIN"
    echo save
  } | gpg2 --batch --expert --command-fd 0 --pinentry-mode loopback --edit-key "$KEY_ID"
}

function reset_opengp_yubikey() 
{
    echo "y" | ykman openpgp reset
}


#TODO
function enable_touch_policy_for_all_actions() 
{
     echo "y" | ykman openpgp touch sig on --admin-pin "$GPG_ADMIN_PIN"
     echo "y" | ykman openpgp touch enc on --admin-pin "$GPG_ADMIN_PIN"
     echo "y" | ykman openpgp touch aut on --admin-pin "$GPG_ADMIN_PIN"

}

function change_user_pin() {
  OUTPUT=`{
    echo admin
    echo passwd
    echo 1
    echo 123456
    echo $GPG_USER_PIN
    echo $GPG_USER_PIN 
    echo q
  } | gpg  --card-edit --command-fd 0 --pinentry-mode loopback 2>/dev/null`
} 

function change_admin_pin() {
   OUTPUT=`{
    echo admin
    echo passwd
    echo 3
    echo 12345678
    echo "$GPG_ADMIN_PIN"
    echo "$GPG_ADMIN_PIN"
    echo q
  } | gpg --card-edit --command-fd 0 --pinentry-mode loopback 2>/dev/null`
  echo $OUTPUT
}


#TODO ensure yubikey is plugged in 
function check_for_yubikey() {
PCSC_SCAN=''
    until [ $(grep "Yubikey" "$PCSC_SCAN") -eq 0 ]; do
        PCSC_SCAN=`timeout 1s pcsc_scan -r`
    done

}



function generate_master_key() {
OUTPUT=`gpg --batch --passphrase-fd 0 --command-fd=0 --pinentry-mode loopback --gen-key 2>&1  << EOF
%echo Gen key
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Name-Real: $REAL_NAME
Name-Email: $EMAIL
Expire-Date: 0
Passphrase: $MASTER_PASSPHRASE
%commit
EOF`
echo "$OUTPUT"
}

function generate_RSA_4096_sign_sub_key() {
  {
      echo addkey
      echo 4     # RSA (sign only)
      echo 4096  # key length
      echo 0
      echo "$MASTER_PASSPHRASE" # passphrase confirm
      echo "save"
  } | gpg2 --batch --expert  --command-fd 0 --pinentry-mode loopback --edit-key "$KEY_ID"
}

function generate_RSA_4096_encryption_sub_key() {
  {
      echo addkey
      echo 6     # RSA (encrypt only)
      echo 4096  # key length
      echo 0
      echo "$MASTER_PASSPHRASE" # passphrase confirm
      echo "save"
  } | gpg2 --batch --expert  --command-fd 0 --pinentry-mode loopback --edit-key "$KEY_ID"
}


function generate_RSA_4096_authentication_sub_key() {
    {
        echo addkey
        echo 8     # RSA (Set Own Capabilities)
        echo "s"   # disable signing
        echo "e"   # disable encryption
        echo "a"   # enable authentication
        echo "q"   # quit capabilities
        echo 4096  # key length
        echo "0"   # does not expire
        echo "$MASTER_PASSPHRASE" # password confirm
        echo "save"
    } | gpg2 --batch --expert --command-fd 0 --pinentry-mode loopback --edit-key "$KEY_ID"


}


function set_key_prefs() 
{
  {
    echo setpref SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
    echo y
    echo "$MASTER_PASSPHRASE"
    echo save
  } | gpg2 --batch --expert --command-fd 0 --pinentry-mode loopback --edit-key "$KEY_ID"
}


log "Resetting opengpg user and admin pin. No reset code will be set."
reset_opengp_yubikey 2>/dev/null
sleep 2

log "Setting user pin"
change_user_pin 2>&1 >  /dev/null
sleep 2

log "Setting admin pin"
change_admin_pin 2>&1 > /dev/null
