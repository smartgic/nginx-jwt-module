[![Alpine version](https://img.shields.io/badge/Alpine-Edge-green.svg?style=flat&logoColor=FFFFFF&color=87567)](https://alpinelinux.org/)
[![Nginx version](https://img.shields.io/badge/Nginx-1.21.6-green.svg?style=flat&logoColor=FFFFFF&color=87567)](https://nginx.org/en/)
[![Docker pulls](https://img.shields.io/docker/pulls/smartgic/nginx-jwt-module.svg?style=flat&logo=docker&logoColor=FFFFFF&color=87567)](https://hub.docker.com/r/smartgic/mnginx-jwt-module)
[![Discord](https://img.shields.io/discord/809074036733902888)](https://discord.gg/sHM3Duz5d3) 

# Nginx JWT authentication module

This is an NGINX module to check for a valid JWT.

Inspired by [TeslaGov](https://github.com/TeslaGov/ngx-http-auth-jwt-module) and [max-lt](https://github.com/max-lt/nginx-jwt-module) repositories.

 - Docker image based on the [official nginx Dockerfile](https://github.com/nginxinc/docker-nginx) _(Alpine)_.
 - Light image _(~10MB compressed)_.

## Supported architectures and tags

| Architecture | Information                                        |
| ---          | ---                                                |
| `amd64`      | Such as AMD and Intel processors                   |
| `arm/v6`     | Such as Raspberry Pi 1                             |
| `arm/v7`     | Such as Raspberry Pi 2/3/4                         |
| `arm64`      | Such as Raspberry Pi 4 64-bit                      |

*These are examples, many other boards use these CPU architectures.*

## NGINX Directives

This module requires several new `nginx.conf` directives, which can be specified in on the `main`, `server` or `location` level.

```nginx
auth_jwt_key "646f6e2774207472792c206974277320612066616b6520736563726574203a29"; # see docs below for format based on algorithm
auth_jwt_loginurl "https://yourdomain.com/loginpage";
auth_jwt_enabled on;
auth_jwt_algorithm HS256; # or RS256
auth_jwt_validate_email on;  # or off
auth_jwt_use_keyfile off; # or on
auth_jwt_keyfile_path "/app/pub_key";
```

The default algorithm is `HS256`, for symmetric key validation. When using `HS256`, the value for `auth_jwt_key` should be specified in `hex` format. It is recommended to use at least 256-bits of data _(32 pairs of hex characters or 64 characters in total)_ as in the example above. Note that using more than 512-bits will not increase the security. For key guidelines please see NIST Special Publication 800-107 Recommendation for Applications Using Approved Hash Algorithms, Section 5.3.2 The HMAC Key.

The configuration also supports the `auth_jwt_algorithm` `RS256`, for RSA 256-bit public key validation. If using `auth_jwt_algorithm RS256;`, then the `auth_jwt_key` field must be set to your public key **OR** `auth_jwt_use_keyfile` should be set to `on` with the `auth_jwt_keyfile_path` set to the public key path _(Nginx won't start if the `auth_jwt_use_keyfile` is set to `on` without a keyfile)_.

That is the public key, rather than a PEM certificate. I.e.:

```nginx
auth_jwt_key "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0aPPpS7ufs0bGbW9+OFQ
RvJwb58fhi2BuHMd7Ys6m8D1jHW/AhDYrYVZtUnA60lxwSJ/ZKreYOQMlNyZfdqA
rhYyyUkedDn8e0WsDvH+ocY0cMcxCCN5jItCwhIbIkTO6WEGrDgWTY57UfWDqbMZ
4lMn42f77OKFoxsOA6CVvpsvrprBPIRPa25H2bJHODHEtDr/H519Y681/eCyeQE/
1ibKL2cMN49O7nRAAaUNoFcO89Uc+GKofcad1TTwtTIwmSMbCLVkzGeExBCrBTQo
wO6AxLijfWV/JnVxNMUiobiKGc/PP6T5PI70Uv67Y4FzzWTuhqmREb3/BlcbPwtM
oQIDAQAB
-----END PUBLIC KEY-----";
```

**OR**

```nginx
auth_jwt_use_keyfile on;
auth_jwt_keyfile_path "/etc/nginx/pub_key.pem";
```

A typical use would be to specify the key and loginurl on the main level and then only turn on the locations that you want to secure _(not the login page)_.
Unauthorized requests are given `302 "Moved Temporarily"` responses with a location of the specified `loginurl`.

```nginx
auth_jwt_redirect off;
```

If you prefer to return `401 Unauthorized`, you may turn `auth_jwt_redirect` to `off`.

```nginx
auth_jwt_validation_type AUTHORIZATION;
auth_jwt_validation_type COOKIE=rampartjwt;
```

By default the authorization header is used to provide a JWT for validation. However, you may use the `auth_jwt_validation_type` configuration to specify the name of a cookie that provides the JWT.

```nginx
auth_jwt_validate_email off;
```

By default, the module will attempt to validate the email address field of the JWT, then set the x-email header of the session, and will log an error if it isn't found.  To disable this behavior, for instance if you are using a different user identifier property such as `sub`, set `auth_jwt_validate_email` to the value `off`.

## Example

In this example, the route `/` from `push.smartgic.io` listening on port `80` is protected by a JWT authentication. If the JWT is valid then, the request is redirected to https://pushgateway.appdomain.cloud. Only the `POST` is allowed.

```nginx
server {
    listen 80;
    server_name push.smartgic.io;

    location / {
        if ($request_method ~ ^(GET|PATCH|PUT|DELETE|OPTIONS|HEAD)$) {
            return 403;
        }

        auth_jwt_key "646f6e2774207472792c206974277320612066616b6520736563726574203a29";
        auth_jwt_enabled on;

        proxy_set_header Host pushgateway.appdomain.cloud;
        proxy_pass       https://pushgateway.appdomain.cloud;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Host $remote_addr;
        proxy_buffering  off;
    }
}
```

There is a complete example of JWT and TLS _(via Let's Encrypt)_ in the `examples` directory.

## Encode a `string` to `hex` using Python.

```python
key = "don't try, it's a fake secret :)".encode("utf-8")
print(key.hex())
646f6e2774207472792c206974277320612066616b6520736563726574203a29
```