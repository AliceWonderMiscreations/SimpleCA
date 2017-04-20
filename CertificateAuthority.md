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
2. It is not uncommon for an end-user device to become compromised.
