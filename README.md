# fish-cert
website domain cert show/output function (openssl s_client and x509 wrapper)

# Install

## Using fisher

```
fisher install holly/fish-cert
```

## Update

```
fisher update holly/fish-cert
```

# Usage

```
Usage:
  crt [options] domain

Options:

  -O                        Write output to a file named as the $domain.crt
  -t, --text                Same as `openssl x509 -text -noout`
  -h, --help                Show help message and quit
  -H, --humanize            Show humanize key/value pairs `openssl x509 -text -noout`
  -J, --json                Show key/value json output
  --version                 Show version number and quit
```

# Example

## Show pem string

```
> crt github.com
-----BEGIN CERTIFICATE-----
MIIFajCCBPGgAwIBAgIQDNCovsYyz+ZF7KCpsIT7HDAKBggqhkjOPQQDAzBWMQsw
CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMTAwLgYDVQQDEydEaWdp
       .
       .
       .
3jSZCpwfqOHBdlxi9ASgKTU+wg0qw3FqtfQ31OwLYFdxh0MlNk/HwkjRSWgCMFbQ
vMkXEPvNvv4t30K6xtpG26qmZ+6OiISBIIXMljWnsiYR1gyZnTzIg3AQSw4Vmw==
-----END CERTIFICATE-----
```

## Output pem to `github.com.crt`

```
> crt -O github.com
> ls -lA github.com.crt
  -rw-r--r-- 1 holly holly 1939 Jun  4 21:05 github.com.crt
```

## Show openssl text information

Same as `openssl x509 -text -noout`

```
> crt --text github.com
  Certificate:
      Data:
          Version: 3 (0x2)
          Serial Number:
             0c:d0:a8:be:c6:32:cf:e6:45:ec:a0:a9:b0:84:fb:1c
          Signature Algorithm: ecdsa-with-SHA384
          Issuer: C = US, O = DigiCert Inc, CN = DigiCert TLS Hybrid ECC SHA384 2020 CA1
       .
       .
       .
        30:64:02:30:04:dc:0d:d4:de:34:99:0a:9c:1f:a8:e1:c1:76:
        5c:62:f4:04:a0:29:35:3e:c2:0d:2a:c3:71:6a:b5:f4:37:d4:
```

## Show humanize key/value pairs

```
> crt --humanize github.com
serial                     0CD0A8BEC632CFE645ECA0A9B084FB1C
issuer                     DigiCert Inc
common_name                github.com
start_date                 2023-02-14T09:00:00+09:00
start_date_utc             2023-02-14T00:00:00+00:00
end_date                   2024-03-15T08:59:59+09:00
end_date_utc               2024-03-14T23:59:59+00:00
cert_expiration_days       284
subject_alternative_names  DNS:github.com,DNS:www.github.com
```

### Original Field

|  Field  |  Description  |
| ---- | ---- |
|  start_date  | `openssl x509 -noout -startdate` converted local timezone date string  |
|  end_date  | `openssl x509 -noout -enddate` converted local timezone date string  |
|  start_date_utc  | `openssl x509 -noout -startdate` converted utc date string (original gmt date string)  |
|  end_date_utc  | `openssl x509 -noout -enddate` converted utc date string (original gmt date string) |
|  cert_expiration_days  |  remaining days (end_date - now)  |

## Show json key/value pairs 

```
> crt --json github.com | jq "."
{
  "serial": "0CD0A8BEC632CFE645ECA0A9B084FB1C",
  "issuer": "DigiCert Inc",
  "common_name": "github.com",
  "start_date": "2023-02-14T09:00:00+09:00",
  "start_date_utc": "2023-02-14T00:00:00+00:00",
  "end_date": "2024-03-15T08:59:59+09:00",
  "end_date_utc": "2024-03-14T23:59:59+00:00",
  "cert_expiration_days": "270",
  "subject_alternative_names": [
    "DNS:github.com",
    "DNS:www.github.com"
  ]
}
```

# License

This project is licensed under the MIT LICENSE - see the LICENSE file for details.
