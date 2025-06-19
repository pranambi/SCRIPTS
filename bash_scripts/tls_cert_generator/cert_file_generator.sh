#!/bin/bash

# ================================ EDIT BELOW WITH FULL HOSTNAMES ================================ #

# Create host file
cat << EOF > hosts
node1.domain.com
node2.domain.com
node3.domain.com
node4.domain.com
EOF

# ====================================== SCRIPT STARTS HERE ====================================== #

# Set common variables
CA_CERT="/root/CA/certs/ca.crt"
CA_KEY="/root/CA/private/ca.key"
PASSWORD="changeit"
EXTENSIONS="[mysection]\nextendedKeyUsage=serverAuth,clientAuth"
EXTFILE="/tmp/extfile.txt"

# Check if CA setup is needed
if [[ ! -f "$CA_CERT" || ! -f "$CA_KEY" ]]; then
    # Install OpenSSL if not already installed
    yum install openssl -y

    # Generate CA key and certificate
    openssl genrsa -out ca.key 8192
    openssl req -new -x509 -days 1826 -extensions v3_ca -key ca.key -out ca.crt -subj "/C=IN/ST=Kerala/L=Wayanad/O=Cloudera/OU=Consulting/CN=Root CA"

    # Move CA files to the appropriate directory
    mkdir -p -m 0700 /root/CA/{certs,crl,newcerts,private}
    mv ca.key /root/CA/private
    mv ca.crt /root/CA/certs
    touch /root/CA/index.txt
    echo 1000 > /root/CA/serial
    chmod 0400 /root/CA/private/ca.key

    # Update OpenSSL configuration
    sed -i 's/dir\s*=\s*\/etc\/pki\/CA/dir = \/root\/CA/' /etc/pki/tls/openssl.cnf
else
    echo "CA certs already exist"
fi

# Loop through hosts
while read -r i; do
    # Generate RSA key
    openssl genrsa -out "$i.key" 2048

    # Generate CSR
    openssl req -new -sha256 -key "$i.key" -out "$i.csr" -subj "/C=IN/ST=KR/L=BLR/O=Cloudera/OU=Consulting/CN=$i"

    # Create the extension file
    echo -e "$EXTENSIONS\nsubjectAltName=DNS:$i" > "$EXTFILE"

    # Generate CRT using the extension file
    openssl x509 -req -CA "$CA_CERT" -CAkey "$CA_KEY" -in "$i.csr" -out "$i.crt" -days 365 -CAcreateserial -extensions mysection -extfile "$EXTFILE"

    # Generate PKCS12
    openssl pkcs12 -export -inkey "$i.key" -in "$i.crt" -certfile "$CA_CERT" -out "$i.pfx" -passout pass:"$PASSWORD"

    # Import into JKS keystore
    keytool -v -importkeystore -srckeystore "$i.pfx" -srcstoretype PKCS12 -destkeystore "$i.jks" -deststoretype JKS -srcalias 1 -destalias "$i" -srcstorepass "$PASSWORD" -deststorepass "$PASSWORD"

    # Wait for 1 seconds before processing the next certificate
    sleep 1
done < "hosts"

# Clean up the temporary extension file
rm -f "$EXTFILE"

# Display Cert genaration completed
echo "CERTIFICATE GERENRATION COMPLETE!!!!!"

# Display Pem certificate information and extract specific fields
for i in `cat hosts` ; do echo "======"; echo "PEM certificate Information for $i:";  openssl x509 -in $i.crt -noout -text | grep -E "Issuer:|Subject:|DNS:|Not"; done


# Display JKS certificate information and extract specific fields
for i in `cat hosts` ; do echo "======"; echo "JKS certificate Information for $i:"; keytool -v -list -keystore $i.jks -storepass changeit| grep -E "Alias name:|Owner:|Issuer:|Valid from:|Auth:|DNSName:"; done
