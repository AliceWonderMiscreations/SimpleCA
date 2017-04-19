MX Server and TLS
=================

Your MX server(s) should run on TCP Port 25 and should only accept connections
from other SMTP servers, they should *not* accept connections from e-mail
clients.

SMTP to SMTP communication uses something called *opportunistic TLS* where the
communication falls back to plain text if both servers can not agree upon a TLS
protocol and cipher suite to use.

With opportunistic TLS, all an attacker needs to do is strip the plain text
`STARTTLS` command from the initial communication and the two servers will talk
to each other in plain text without encryption.

For this reason, the majority of SMTP servers do not bother to validate X.509
certificates when talking to other SMTP servers. It ordinarily does not make
sense for them to do so, since the alternative to just accepting the X.509
certificate is to send the message in plain text.

The only way to know for sure that an SMTP to SMTP communication will use
encryption is if the receiving SMTP server is on a zone protected by DNSSEC
*and* has a TLSA record for TCP port 25, and the sending SMTP server enforces
[RFC 7672](https://tools.ietf.org/html/rfc7672). If both of those conditions
are not met then it is possible for a MITM attack to take place and use of a
trusted Certificate Authority will not help.

For this reason, you will find that even MX servers run by large well-known
companies often used X.509 certificates that are self-signed, expired, or for
which the host name does not match the certificate.

The point is whether or not you are using DNSSEC and DANE, it is just as safe
to use a self-signed X.509 TLS certificate with MX servers as it is to use one
signed by a "trusted" Certificate Authority. There is absolutely no advantage
to using a "trusted" Certificate Authority for your MX server, it does not add
any additional security.

The *only* way to add confidence to the validity of a MX X.509 certificate is
through DNSSEC with DANE in accordance with RFC 7672 and that does not benefit
from the use of a Certificate Authority.

keyGenMX_Dane.sh
----------------

The bash shell script `keyGenMX_Dane.sh` will produce a valid X.509v3 self-
signed certificate suitable for use on an MX server.

As scripted, it will create a 3072-bit RSA X.509 certificate. If you would
prefer 2048-bit or 4096-bit you can modify line 41 to suit your preferences.

It is also possible to modify the script to produce an ECDSA certificate but at
this point in time, I do not recommend ECDSA for e-mail servers.

As scripted, it will create a X.509 certificate that is valid for 1096 days
(three years). If you would prefer a longer period of time, modify line 84 in
the script.

It is my personal opinion that when the private key needs to be installed on a
public facing server, as is the case with MX servers, that you should generate
a fresh private key once a year.

I like to make the certificate valid for three years just to avoid issues where
life gets in the way resulting in an expired certificate being used. That is an
awful lot of breathing room, but it does not reduce security to have that extra
breathing room.

The first argument to the script needs to be the fully qualified domain name
that is in the MX record the SMTP server is responsible for. Additional
arguements may be given to specify other host names the certificate is valid
for. For example:

    sh keyGenMX_Dane.sh mx1.example.net example.net

That will produce a self-signed certificate that is valid when used with both
the hostname `mx1.example.net` or with `example.net`.

It is up to you, the system administrator, to configure your SMTP server to use
the private key and certificate.

The private key will be placed in the directory `/etc/pki/tls/private` and the
X.509 certificate will be placed in the directory `/etc/pki/tls/certs` and both
will contain the domain name and a YYYYMMDD time stamp as part of the filename.

### DANE Record

After running the script, it will output both a `3 0 1` and a `3 1 1` context
DANE fingerprint.

Which you use, if either of them, in your DNS zone is completely up to you.

Your zone *must* be protected by DNSSEC to use DANE. If your zone is not
protected by DNSSEC then it is pointless creating any DANE records, other SMTP
servers will just ignore them.

### Rotating Private / Public Key Pairs

Even though the shell script creates a X.509 TLS certificate that is valid for
three years, I recommend you generate a fresh private key and X.509 certificate
about once a year. When you do use DNSSEC with DANE, this needs to be carefully
done or there could be a temporary loss of service.

First use this script to create the new private key and public X.509
certificate. Create a new TLSA record for TCP Port 25 containing the new
fingerprint, but leave the old TLSA record in place. For a time, you will be
serving two TLSA records with DANE fingerprints.

Once at least twice the TTL you use for the TLSA record has passed, then you
may put the new private key / public X.509 certificate into service.

Personally however I recommend waiting for twice the TTL plus a calendar week.
Waiting for an additional week gives plenty of time for caching recursive
resolvers that do not precisely follow the rules to properly update their
cached values for the TLSA records. It is then safe to switch your SMTP server
software to start using the new private key and public X.509 TLS certificate.

Once your SMTP server software has been updated to use the new private key and
X.509 certificate, you can immediately remove the old TLSA record that has the
old fingerprint. The old private / public key has now been taken out of
service.

### Encryption Note

A private / public key pair on an SMTP server does *not* provide end to end
encryption, it only provides for hop to hop encryption and then only for the
hop going from the SMTP server sending the message to your MX server and then
only *sometimes*.

If your MX server is not protected by DNSSEC plus DANE according to RFC 7672
then it is possible for malicious third party actors to force the connection to
downgrade to plain text.

If the SMTP server sending a message to your MX server does not enforce RFC
7672 then it is possible for a malicious third party actor to force the
connection to downgrade to plain text.

When your users need to communicate through e-mail with the expectation of end-
to-end encryption, your users should use either S/MIME or OpenPGP to achieve
that goal.

### OCSP Note

The self-signed certificate produced by the shell script here does not support
any time of certificate revokation.

SMTP servers do not usually check for certificate revocation.

If the private key is ever compromised, the proper way to revoke the X.509
certificate is to replace the DANE TLSA record.
