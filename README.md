SimpleCA
========

With modern TLS communication, the private / public key pair on the server is
only used to indicate the authenticity of the server the TLS client is in
communication with. The actual encrypted communication itself takes place using
an ephemeral secret negotiated between the TLS client and server when they
begin their communication. This is often referred to as Forward Secrecy key
exchange because a private key that becomes compromised is useless for
decrypting previous or future encrypted communications.

For some types of communication, such as an e-mail sent from Alice to Bob using
end to end encryption, Forward Secrecy is not possible for technical reasons.
In those cases, Alice will use the public key provided by Bob to encrypt the
message in such a way that only Bob's private key is capable of decrypting the
message.

Whether it used for authentication of the server to the client or it is used
for encryption, the public key is *usually* transmitted to the client as part
of an [X.509](https://en.wikipedia.org/wiki/X.509) certificate that the client
either chooses to trust as authentic or reject as a possible fraud attempt.

Traditionally, the owner of the private key that generated the public key will
create what is called a CSR - a Certificate Signing Request. The owner of the
private key then finds a *Certificate Authority* that is likely to be trusted
by clients and pay them to create a signed X.509 certificate from the CSR.

If the client trusts the Certificate Authority, then the client will trust a
X.509 certificate signed by the certificate authority. If the client does not
trust the Certificate Authority, then the client will either reject the TLS
communication or ask the user what to do, usually with a very scary warning.

A typical client by default trusts about 200 different Certificate Authorities,
many of which probably should not be trusted, but the client continues to trust
them simply because they do not have a choice. Too many websites would break if
they stopped trusting many of the Certificate Authorities they trust.

To put it bluntly, the system is a broken system centered on profit rather than
on the actual integrity of the certificate.

There is a better way, it is called DANE - DNS-based Authentication of Named
Entities. More information on DANE can be found at the
[IETF charter](https://datatracker.ietf.org/wg/dane/charter/).

Rather than trusting a X.509 certificate is valid because some commercial third
party entity signed it, clients check to see if the fingerprint from the public
key (or the certificate) matches what is in DNSSEC protected DNS for the
service. Trust in a third party is taken out of the equation.

DANE is not limited to any particular protocol, but it seems to be gaining the
fastest adoption in E-Mail. DANE is already enforced by many SMTP servers and
I *suspect* that it will be implemented and enforced by e-mail clients before
web browsers see the light, web browser developers seem to have a resistance to
DNSSEC based technology, I am not quite sure why.

DANE Context Components
-----------------------

With DANE, there are four components to the DNS RDATA section of the response.
The first three give the context of the fingerprint, the fourth is the actual
fingerprint.

The first part of the context will be an integer `0`, `1`, `2`, or `3`.

`0` and `1` requires that the certificate be signed by a Certificate Authority
that the client trusts, `2` and `3` *may* be signed by a Certificate Authority
that the client trusts or may not be.

It is my *personal* opinion that the only reason to ever use a `0` or `1` as
the first part of the context arguments are in an industry where either OV or
EV certificates are mandated by the nature of the business. For example, the
banking industry may wish to use a EV certificate to give additional confidence
to their users, and may wish to use a DANE record that uses a `0` or a `1` as
the first context argument.

For any X.509 certificates that are not either OV or EV certificates, DNSSEC
itself gives more confidence in the validity of the certificate than being
signed by a certificate authority does, so there is no point in using a DANE
context that requires the client trust the Certificate Authority that signed it
to consider the certificate to be valid.

Please look at the DANE documentation for use cases where the first component
is either a `0` or a `1`, I will not cover them here since I do not use them.

When the first context component is a `2` the fingerprint given in DNS is not
of the public key or X.509 certificate itself, but rather, of the intermediary
that signed the X.509 certificate.

When the first context component is a `3` the fingerprint given in DNS is
either of the public key in the certificate or of the certificate itself.

Generally speaking, when a client is connecting to a server providing TLS over
TCP or UDP, the DNS record will be a TLSA record and the first part of the
context should be a `3` so that the client does not need to further validate
the X.509 certificate by checking a revocation list or an OCSP responder.

In some cases, such as S/MIME certificates, it may be preferable to use a `2`
as the first context component for privacy reasons.

In cases like S/MIME, the client will use a hash of the user name in its DNS
query. By using an intermediary, the DNS zone file can be configured with a
wildcard that responds with the intermediary fingerprint regardless of what the
user name is, so that DNS can not be used to confirm the existence of an e-mail
user on the domain. An OCSP responder associated with the intermediary should
then be set up so that when a client has a X.509 certificate signed by the
intermediary, the client can verify the certificate has not been revoked.

The second part of the context will be an integer `0` or `1`.

When it is a `0` it indicates the fingerprint is of the X.509 certificate
itself. When it is a `1` it indicates the fingerprint is of the public key
within the certificate rather than of the certificate itself.

My *personal* preference is to use a `0` when I have had the certificate signed
by a third party Certificate Authority and to use a `1` when I am either using
a self-signed certificate or I signed it with my own Certificate Authority.

That preference is not for technical reasons, but since I personally *never*
use a `0` or `1` for the first context component, it makes it easier for me to
identify which DANE records are from a commercial Certificate Authority signed
certificate and which DANE records are not.

I do not use Let's Encrypt, but if you use Let's Encrypt, that particular
Certificate Authority issues short-lived certificates, so you probably want to
use a `1` as the second context argument and create your fingerprints based on
the public key rather than based on the X.509 certificate.

The third part of the context will be an integer `0`, `1`, or `2`.

A `0` indicates the entire certificate (or public key) is in DNS. Please do not
use that option, it results in incredibly large records. Some people want to
use DNS as a means of distributing the X.509 certificate and I can understand
the appeal in doing so, but please remember that recursive resolvers need to
cache the result of a query. That kind of data really is not what the DNS
system was intended for. It is legal, but I do not recommend doing it.

A `1` indicates the fingerprint is a SHA256 hash. This is by far the most
common means by which DANE is used and is what I personally recommend.

A `2` indicates the fingerprint is a SHA512 hash. While not as bad as putting
the entire X.509 certificate or public key in DNS, I also do not recommend it,
it is a waste of resources.

* * * * *

For a secure web server where clients still largely do not support any kind of
DANE validation, I use a commercial Certificate Authority signed certificate
and `3 0 1` as the context components. That works well with clients that do
DANE validate and also works well with clients that do not know anything about
DANE fingerprint validation.

This project however is about E-Mail services.

For e-mail MX servers, I use a self-signed certificate and `3 1 1` as the
context component. When other SMTP servers connect to my MX servers, they are
not going to bother checking whether or not the X.509 certificate is signed by
a Certificate Authority they trust because TLS over SMTP is opportunistic.

With SMTP to SMTP communication there is not human interaction, nor is there a
standardized list of Certificate Authorities, so it is not appropriate for SMTP
to SMTP communication to use any kind of X.509 validation other than DANE.

For e-mail clients that connect to POP3/IMAP and SMTP servers, I use a X.509
certificate signed by an intermediary I manage and also use `3 1 1` for the
fingerprint context.

Presently e-mail clients do not support DANE validation, so I do import the
root and intermediary certificate into my e-mail clients. That is safe to do
with e-mail clients.

I am anticipating that soon, e-mail clients will DANE validate in order to
support the new DANE S/MIME and OpenPGP standards.

For S/MIME I put the fingerprint for an intermediary certificate in DNS using
a `2 1 1` context for the fingerprint. When other e-mail clients support DANE,
that will allow them to validate the X.509 certificate sent with my messages.
