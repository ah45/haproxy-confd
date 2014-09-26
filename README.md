ah45/haproxy-confd
==================

A Docker container running HAProxy (exposed on ports 80 and 443) configured
dynamically via confd.

## Runtime overrides

The confd configuration can be overridden by mouting a `/confd-override`
volume at runtime. Files within this volume will overwrite those in the
`/etc/confd` directory (which is a copy of the `resources/confd` directory
in this repository.)

Additionally a `/etc/ssl/private` volume can be provided to supply SSL
certificates for use by HAProxy. If no such volume is provided a dummy
certificate for the `example.com` domain will be used for any HTTPS
requests.

(The SSL certs are loaded by providing the directory name to the HAProxy bind.)

## Default configuration template

The default configuration template included with the container runs confd
with the consul backend connecting to the host `consul` on port 8500
(the expectation being that you will `--link <a container>:consul` when
run.)

HAProxy statistics are enabled _globally_ at the `/haproxy-stats` URI.
Individual frontends and backends are configured via confd with entries
created under a `haproxy` key in the following formats:

### `frontends`

`frontends` should contain sub-keys corresponding to the host names you
wish to serve traffic for with each host having the following configuration:

    haproxy \
        frontends \
            example.com \
                force-ssl: true
                default-backend: my-backend
                locations \
                    blog \
                        path: ^/weblog$
                        backend: my-weblog

**Note that _all_ keys must be present as confd currently lacks the ability to
check for a key without throwing an error.**

Setting `force-ssl` to `true` will cause all HTTP requests for the host to
be redirected HTTPS.

`locations` should contain one or more named locations specifying a path
to match and a backend to send the request to. The location name should
conform to the HAProxy ACL naming restrictions.

All paths are matched via case in-sensitive regular expression comparison.

If `default-backend` is not left empty any requests not matched by the
`locations` will be sent to the specified backend.

Requests are forwarded to the backends _unmanipulated_ save for the addition
of the `X-Forwarded-For` header and a `X-Forwarded-Proto` header (set to either
`http` or `https` depending on the scheme of the request.)

### `backends`

`backends` should contain entries for the backends specified in your
frontend configuration, each containing one or more entries for the
backend servers that are available to handle the requests:

    haproxy \
        backends \
            my-backend \
                web1: 10.0.0.101:49153
                web2: 10.0.0.102:56721
            my-weblog \
                blog1: 10.0.0.150:48101
                blog2: 10.0.0.151:40123

This is effectively a one-to-one mapping with the produced HAProxy
configuration:

    backend my-backend
        server web1 10.0.0.101:49153
        server web2 10.0.0.102:56721

    backend my-weblog
        server blog1 10.0.0.150:48101
        server blog2 10.0.0.151:40123

Note that health checks are _not_ enabled. It is presumed that these are
already being performed via consul and that the key/value entries will
be removed when they fail.

