Certificate Authority
=====================

One of the beauties of DNSSEC validated DANE records is that for many things, a
Certificate Authority is no longer needed. In essense, the DNS system itself
becomes the Certificate Authority, vouching for the validity of the X.509
certificates with much greater confidence than a third party signature could
ever give.

In the case of MX servers, traditional Certificate Authorities do not even work
and never did work. DANE works beautifully for MX servers right now, providing
both confidence that the X.509 is genuine and letting other SMTP servers know
that they should refuse to send the message using any other public key.

For other parts of the e-mail system, Certificate Authorities either will
always be needed or are still presently needed due to lack of DANE support in
e-mail clients. However, the Certificate Authority that is used does not need
to be a third party Certificate Authority. It can *and should* be run at the
corporate level, exclusive to the corporation providing the e-mail service.

SMTP/POP3/IMAP Services
-----------------------

An e-mail client needs to use TLS when connecting to an SMTP server (typically
the submission port 587) or a POP3 server (typically port 110 or 995) or to an
IMAP server (typically port 143 or 993)

In the future, those services will be secured by a DANE `3 0 1` or `3 1 1`
context fingerprint but in the present, e-mail clients do not yet validate DANE
fingerprints, so a Certificate Authority is needed to validate the X.509
certificates used to secure those services.

It is my recommondation that you run this Certificate Authority yourself, and
require e-mail clients to add the root X.509 certificate for your Certificate
Authority to the Certificate Authorities their e-mail client trusts.

It is dangerous for users to import root certificates into web browsers, and as
an end user I personally do not import root certificates into my web browsers.
However it is not dangerous to ask end users to import root certificates into
their e-mail clients.

E-Mail clients are not used for general connections to the a multitude of
Internet servers like web browsers are, they are used for very specific
connections to very specific servers. That is why it is safe to import the root
X.509 certificate that is needed to validate the X.509 certificates used by
those very specific servers it connects to.

In the future, hopefully not too distant future, e-mail clients will properly
support DANE validation and import of a root certificate by a client will no
longer be necessary, but for now, it is safe and is necessary if you do not
use a commercial third party Certificate Authority that clients already trust.

### Self-Signed Certificates

In the present, you can also use a self-signed certificate for SMTP/POP/IMAP
services and ask your users to trust the self-signed certificate.

However it is best practice to change the private key once a year, and that
would require all your clients manually accept a new self-signed key once a
year. I believe it is a bad practice to get users use to accepting self-signed
certificates.

We should wait with using self-signed certificates until clients have the
ability to validate them with DANE.

S/MIME
------

The E-Mail protocol was not designed with security in mind. Messages are not
difficult for a bad actor to either forge or modify in transit.

S/MIME is a mechanism by which a private cryptographic key can either sign an
e-mail message to give the recipient confidence the message is genuine and has
not been altered in transit, or encrypt a message so that only the private key
that belongs to the recipient can decrypt the message.

S/MIME uses X.509 certificates to distribute the public key associated with the
private key, and the will require a Certificate Authority for validation of the
X.509 certificate itself.

Okay technically speaking it is *possible* to completely validated an X.509
certificated used for S/MIME with DANE however there are several severe
drawbacks:

1. Validating each X.509 via DANE requires at least one DNS record for every
   user that has a X.509 S/MIME certificate on your system. This is doable if
   only a few users on your system use S/MIME but it does not scale very well
   to many users. It becomes a maintenance nightmare for your DNS
   administration.
2. It is not uncommon for an end-user device to become compromised. When this
   happens and the private key is compromised, a DNS update would be required
   to invalidate the public X.509 certificate. A solution that requires an
   update to the DNS zone file every time an end-user device is compromised
   does not strike me as a very practical solution.
3. There is a privacy leak. The only way to validate an end-user X.509
   certificate with DANE requires a DNS record that can be used to verify a
   username is valid on a system. Spammers and Scammers will take advantage
   of this when creating lists of users to send their junk mail to.

Those drawbacks make DANE an unsuitable solution for general user X.509
certificate validation. A better solution exists.

Rather than store the fingerprint of each individual end-user X.509 certificate
in DNS, the fingerprint of the intermediary used to sign the end user X.509
certificates should be stored in DNS. This can be done with a DANE `2 0 1` or
`2 1 1` context record.

The validity of the individual end-user certificate can then be checked by
making sure it is was signed by the intermediary with a fingerpring that has
been secured by DANE *and* by checking the OCSP server specified in the X.509
certificate to make sure it has not been revoked since it was signed.

This method does not require a commercial Certificate Authority, the validity
of the intermediary certificate is validated by DANE and only needs to be valid
for the specific e-mail domains it services.

Client Authentication
---------------------

Normally when an e-mail client connects to an SMTP/POP3/IMAP server, it uses a
username and password to authenticate.

In some cases that is not considered secure enough, and a client X.509
certificate is used instead.

At this time, I am not aware of a DANE mechanism by which the servers the
client is connecting to can authenticate the client certificate, and it does
not strike me that such a solution would be very practical.

Usually what happens is the e-mail system administrator creates an intermediary
private key and certificate that is used to sign the client certificates, and
then the server the client is connecting to makes sure the client is connecting
using a X.509 certificate signed by that intermediary that has not been
revoked.

When using this method of client authentication, a commercial Certificate
Authority should not be used. A private Certificate Authority run by the e-mail
system administrator really the only option that is secure.
