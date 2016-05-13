Running puppet-dlrn without https

If you want to configure a dlrn server without https set parameter enable_https
to false in dlrn class before executing the manifest. 

SSL support for Apache needs some manual steps before running puppet:

1- Download the SSL certificate, public key and CA chain certificate,
   and place it in the following locations

   - /etc/pki/tls/certs/trunk_rdoproject_org.crt ,   root:root, permissions 600
   - /etc/pki/tls/certs/DigiCertCA.crt ,             root:root, permissions 600
   - /etc/pki/tls/private/trunk.rdoproject.org.key , root:root, permissions 600

2- Then, you can run dlrn puppet manifest making sure that enable_https is set
to true (default option).
