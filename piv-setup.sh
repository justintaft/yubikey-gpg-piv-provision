#!/usr/bin/bash

#CHANGE ME
export CERT_CN="test"
export CERT_OU="test"
export CERT_O="example.com"

function gen_and_install_key() {
  SLOT=$1
  CURVE_TYPE=$2
  KEY_TYPE=$3

  #Generate ECC Private Key
  openssl ecparam -name "$CURVE_TYPE" -genkey -noout -out "piv-${CURVE_TYPE}-${KEY_TYPE}-key.pem"
  
  #import key 
  cat "piv-${CURVE_TYPE}-${KEY_TYPE}-key.pem" | yubico-piv-tool -a import-key -s "$SLOT" --touch-policy always

  #Create Certificate Certificate
  openssl ec -in "piv-${CURVE_TYPE}-${KEY_TYPE}-key.pem" -pubout -out "piv-${CURVE_TYPE}-${KEY_TYPE}-pubkey.pem"

  #Self-sign certificate
  echo "Touch yubikey to self sign certificate."
  CERT=`echo "$PIN" | yubico-piv-tool -s"${SLOT}" -S'/CN='"$CERT_CN"'/OU='"$CERT_OU"'/O='"$CERT_O"'/' -averify -aselfsign -i "piv-${CURVE_TYPE}-${KEY_TYPE}-pubkey.pem" -P "123456"`

  echo "Done"

  ##Import self-signed cert
  yubico-piv-tool -s"${SLOT}" -a import-certificate -i <(echo "$CERT")

}

#Reset piv
echo y | ykman piv reset


#MacOS requires 256r1 for encryption key for some reason...
gen_and_install_key 9a secp256r1 authentication
gen_and_install_key 9c secp256r1 signing
gen_and_install_key 9d secp256r1 encryption

#Set a random Cardholder Capability Container
yubico-piv-tool -a set-ccc 

#Set a random CHUID
yubico-piv-tool -a set-chuid

MGM_KEY=`dd if=/dev/urandom bs=1 count=24 2>/dev/null | hexdump -v -e '/1 "%02X"'`
yubico-piv-tool -a set-mgm-key -n "$MGM_KEY"

#Set Pin
yubico-piv-tool -a change-pin -P 123456

#PUK
yubico-piv-tool -a change-puk -P 12345678
