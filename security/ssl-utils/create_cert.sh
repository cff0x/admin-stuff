#!/bin/bash

# ACME server used to request the certificate
ACME_SERVER="https://acme-v02.api.letsencrypt.org/directory"

# preferred ACME challenge type
ACME_TYPE=${3:-dns}

# domain and contact email address for our cert
CERT_DOMAIN=${1:-example.com}
CERT_EMAIL=${2:-webmaster@example.com}

# path to openssl config generated by this script
OPENSSL_CONFIG_FILE="$(pwd)/config/openssl-${CERT_DOMAIN}.conf"

# private key file parameters
PRIVKEY_FILE="$(pwd)/ssl/private/${CERT_DOMAIN}/privkey.pem"
PRIVKEY_CURVE="secp384r1"

# certificate signing requests parameters
CSR_FILE="$(pwd)/ssl/private/${CERT_DOMAIN}/csr.pem"
CSR_HASH="sha512"

# certificate output paths
CERT_FILE="$(pwd)/ssl/certs/${CERT_DOMAIN}/cert.pem"
CHAIN_FILE="$(pwd)/ssl/certs/${CERT_DOMAIN}/chain.pem"
FULLCHAIN_FILE="$(pwd)/ssl/certs/${CERT_DMAIN}/fullchain.pem"

# certbot working directories
CONFIG_DIR="$(pwd)/config"
WORK_DIR="$(pwd)/work"
LOGS_DIR=$(pwd)/logs

# create folders
echo "Creating folders if not existing..."
mkdir -p {ssl,config,work,logs}
mkdir -p ./ssl/{certs,private}/${CERT_DOMAIN}

# args: [privkey_file]
function check_privkey_file() {
  echo "Checking private key file..."

  if [ -f $1 ]; then
    read -p "Private key file already exists, overwrite (y/n)?" choice
    case "$choice" in
      y|Y ) return 1;;
      n|N ) return 0;;
      * ) echo "Invalid input"; check_privkey_file $1;;
    esac
  fi

  return 1
}

# args: [privkey_file, privkey_curve]
function generate_privkey() {
  check_privkey_file $1
  local result=$?

  if [ $result -eq 1 ]; then
    echo "Generating new private key file with curve $2"
    openssl ecparam -genkey -name $2 -out $1 -outform pem
  fi
}

#args: [cert_domain, cert_email, csr_hash, openssl_config_file]
function create_openssl_config() {
  echo "Creating OpenSSL config file..."

  tmp_config="[req]\nprompt=no\nencrypt_key=no\ndefault_md=$3\
              \ndistinguished_name=dname\nreq_extensions=reqext\n\
              \n[dname]\nCN=$1\nemailAddress=$2\n\
              \n[reqext]\nsubjectAltName=DNS:$1,DNS:*.$1"

  echo -e $tmp_config > $4
}

# args: [config_file, privkey_file, csr_file]
function generate_csr() {
  echo "Generating certificate signing request using config file $1..."
  openssl req -new -config $1 -key $2 -out $3
}

# args: [acme_type, acme_server, cert_domain, cert_email, csr_file, config_dir,
#        work_dir, log_dir, cert_file, chain_file, fullchain_file]
function request_cert() {
  certbot certonly\
          --manual --agree-tos --preferred-challenges $1 --server "$2"\
          -d "$3,*.$3" -m $4 --csr $5 --config-dir $6 --work-dir $7\
          --logs-dir $8 --cert-path $9 --chain-path $10 --fullchain-path $11
}

generate_privkey      $PRIVKEY_FILE $PRIVKEY_CURVE
create_openssl_config $CERT_DOMAIN $CERT_EMAIL $CSR_HASH $OPENSSL_CONFIG_FILE
generate_csr          $OPENSSL_CONFIG_FILE $PRIVKEY_FILE $CSR_FILE
request_cert          $ACME_TYPE $ACME_SERVER $CERT_DOMAIN $CERT_EMAIL\
                      $CSR_FILE $CONFIG_DIR $WORK_DIR $LOGS_DIR $CERT_FILE\
                      $CHAIN_FILE $FULLCHAIN_FILE

echo "Compressing output folder..."
tar cfz ssl.tar.gz ./ssl

echo "Done!"