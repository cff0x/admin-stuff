# SSL utilities
## create_cert.sh
*Requires certbot*

This script creates a new SSL certificate using Let's Encrypt. The generated certificate is an ECDSA certificate using the `secp384r1` curve.
You can either set default parameters in the bash script or supply parameters to the script while starting:

`./create_cert.sh <domain> <email> <preferred challenge type>`

Example:

`./create_cert.sh "example.com" "webmaster@example.com" "dns"`

Created certificates will be stored inside the `ssl/` folder. They will also be compressed into a file called `ssl.tar.gz`.
