SSL support for Apache needs some manual steps. Please do the following:

1- Download the SSL certificate, public key and CA chain certificate,
   and place it in the following locations

   - /etc/pki/tls/certs/trunk_rdoproject_org.crt ,   root:root, permissions 600
   - /etc/pki/tls/certs/DigiCertCA.crt ,             root:root, permissions 600
   - /etc/pki/tls/private/trunk.rdoproject.org.key , root:root, permissions 600

2- Then, as root, execute /root/ssl_setup.sh
