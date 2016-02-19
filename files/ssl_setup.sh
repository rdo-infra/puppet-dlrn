#!/bin/bash

echo
echo "Before continuing, make sure the following files are in place and with"
echo "the right permissions:"
echo
echo "- /etc/pki/tls/certs/trunk_rdoproject_org.crt ,   root:root, permissions 600"
echo "- /etc/pki/tls/certs/DigiCertCA.crt ,             root:root, permissions 600"
echo "- /etc/pki/tls/private/trunk.rdoproject.org.key , root:root, permissions 600"
echo
echo "If this is correct, press ENTER to continue. Otherwise, Ctrl+C to abort"
echo

read dummy

yum -y install mod_ssl
sed -i 's/^SSLCertificateFile.*/SSLCertificateFile\ \/etc\/pki\/tls\/certs\/trunk_rdoproject_org.crt/' /etc/httpd/conf.d/ssl.conf
sed -i 's/^SSLCertificateKeyFile.*/SSLCertificateKeyFile\ \/etc\/pki\/tls\/private\/trunk.rdoproject.org.key/' /etc/httpd/conf.d/ssl.conf
sed -i 's/^#SSLCertificateChainFile.*/SSLCertificateChainFile\ \/etc\/pki\/tls\/certs\/DigiCertCA.crt/' /etc/httpd/conf.d/ssl.conf
sed -i 's/^#SSLHonorCipherOrder.*/SSLHonorCipherOrder on/' /etc/httpd/conf.d/ssl.conf
sed -i 's/^SSLProtocol.*/SSLProtocol all -SSLv2 -SSLv3/' /etc/httpd/conf.d/ssl.conf

systemctl restart httpd
firewall-cmd --add-port=443/tcp
firewall-cmd --add-port=443/tcp --permanent
