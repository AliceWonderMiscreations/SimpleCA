#!/bin/bash

# RSA 3072-bit 3-year self-signed certificate for mx server

#  Thank you to Viktor Dukhovni for the x.509_3 settings

OPENSSL="/usr/bin/libressl"
if [ ! -x ${OPENSSL} ]; then
  OPENSSL="/usr/bin/openssl"
fi

if [ ! -x ${OPENSSL} ]; then
  echo "Please edit script and define your OpenSSL API implementation (line 7)."
  exit 1
fi

[ "$(id -u)" != "0" ] && exit 1

FQDN="$1"
DATE="`date +%Y%m%d`"
PVT="${FQDN}-MX-${DATE}.key"
CSR="${FQDN}-MX-${DATE}.csr"
X509="${FQDN}-MX-SS-${DATE}.crt"
CFG="${FQDN}-MX.cfg"

if [ "${FQDN}" == "" ]; then
  echo "Host name not provided"
  exit 1
fi
# else validate hostname ???

# generate pvt key
umask 0277
[ ! -d /etc/pki/tls/private ] && mkdir -p /etc/pki/tls/private
pushd /etc/pki/tls/private > /dev/null 2>&1
if [ -f "${PVT}" ]; then
  echo "Private key already exists"
  popd > /dev/null 2>&1
  exit 1
fi
${OPENSSL} genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out "${PVT}"
umask 0022
popd > /dev/null 2>&1

# generate CSR
[ ! -d /etc/pki/tls/csr ] && mkdir /etc/pki/tls/csr
pushd /etc/pki/tls/csr > /dev/null 2>&1

[ -f "${CFG}" ] && rm -f "${CFG}"
[ -f "${CSR}" ] && rm -f "${CSR}"

cat <<EOF > "${CFG}"
[req]
distinguished_name     = dn
prompt                 = no

[dn]
CN                     = ${FQDN}

[ext]
basicConstraints       = critical,CA:FALSE
extendedKeyUsage       = serverAuth,clientAuth
subjectAltName         = @san

[san]
EOF
COUNTER=0
for arg in $@; do
  ((COUNTER++))
  echo "DNS.${COUNTER}                  = ${arg}" >> "${CFG}"
done

${OPENSSL} req -new -key "../private/${PVT}" -out "${CSR}" -config "${CFG}"
if [ $? -ne 0 ]; then
  echo "Problem creating CSR"
  exit 1
fi
popd > /dev/null 2>&1

# generate x509
[ ! -d /etc/pki/tls/certs ] && mkdir /etc/pki/tls/certs
pushd /etc/pki/tls/certs > /dev/null 2>&1

${OPENSSL} req -x509 -days 1096 -config "../csr/${CFG}" -extensions ext -in "../csr/${CSR}" -key "../private/${PVT}" -out "${X509}"

if [ $? -eq 0 ]; then
  rm -f /etc/pki/tls/csr/${CFG}
  # generate DANE
  FINGERPRINT="`${OPENSSL} x509 -noout -fingerprint -sha256 < "${X509}" |tr -d : |cut -d"=" -f2`"
  echo ""
  echo "TLSA from Cert:"
  echo "3 0 1 ${FINGERPRINT}"
  echo ""
  echo "TLSA from PubKey:"
  FINGERPRINT="`${OPENSSL} x509 -in ${X509} -noout -pubkey |${OPENSSL} pkey -pubin -outform DER |${OPENSSL} dgst -sha256 -binary |hexdump -ve '/1 "%02x"'`"
  FINGERPRINT=${FINGERPRINT^^}
  echo "3 1 1 ${FINGERPRINT}"
fi

popd > /dev/null 2>&1

exit 0
