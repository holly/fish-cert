function __crt_help

    echo "fish-cert $__cert_version (https://github.com/holly/fish-cert/)

Description:

  Show domain remote certificate data function.

Usage:

  crt [options] domain

Options:

  -O                        Write output to a file named as the \$domain.crt
  -t, --text                Same as `openssl x509 -text -noout`
  -h, --help                Show help message and quit
  -H, --humanize            Show humanizable `openssl x509 -text -noout`
  -J, --json                Show json output for humanize mode (require jq command)
  --version                 Show version number and quit

Example:

  # show pem
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

  # output pem to `github.com.crt`
  > crt -O github.com
  > ls -lA github.com.crt
    -rw-r--r-- 1 holly holly 1939 Jun  4 21:05 github.com.crt-

  # output pem to `/path/to/server.crt`
  > crt -o /path/to/server.crt github.com

Copyright (C) 2023, holly.
"
end

function crt -d "Show domain remote certificate data function"

    argparse -n cert -x "O,H,t" \
        "v/version" "h/help" "O" "H/humanize" "t/text"  -- $argv
    or return 1

    if set -lq _flag_version
        echo "fish-cert, version $__cert_version"
        return 0
    end

    if test -n "$_flag_h"
        __crt_help
        return 0
    end

    #set -lq _flag_output or "/dev/stdout"

    set -l domain $argv[1]

    if test -z "$domain"
        set_color red; echo "Usage crt [options] domain."
        return 1
    end

    if not __crt_available_443 $domain
        set_color red; echo "$domain:$__crt_ssl_port is unreachable."
        return 1
    end

    set -l pem (__crt_pem_from_domain $domain | string collect)

    if test -z "$pem"
        set_color red; echo "$domain is parse certificate error."
        return 1
    end

    set -l output
    if test -n "$_flag_O"
        set output "$domain.crt"
    end

    begin
        if test -n "$_flag_humanize"
            set -l dict (__crt_pem2dict $pem)
            __crt_dict_pairs $dict | column -t -s(printf "\011")
        else if test -n "$_flag_text"
            __crt_pem2text $pem
        else
            if string length -- $output >/dev/null
                echo $pem >$output
            else
                echo $pem
            end
        end
    end 
end

function __crt_available_443

    set -l domain $argv[1]
    nc -w $__crt_ssl_connect_timeout -z $domain $__crt_ssl_port
    return $status
end

function __crt_dict_pairs

    set -l last_idx (count $argv)
    for i in (seq 1 2 $last_idx)

        set -l v_idx (math "$i + 1")
        printf "%s\t%s\n" $argv[$i] $argv[$v_idx]
    end
end


function __crt_expiration_days

    set -l enddate $argv[1]
    set -l current_timestamp (date +%s)
    set -l enddate_timestamp (date +%s -d $enddate)
    math "($enddate_timestamp - $current_timestamp) / 60 / 60 / 24" | perl -nle 'print int($_)'
end

function __crt_ssl_client

    set -l domain $argv[1]
    yes | openssl s_client -connect "$domain:$__crt_ssl_port" -tls1_2 -servername $domain 2>/dev/null
end

function __crt_pem2text

    set -l pem $argv[1]
    echo "$pem" | openssl x509 -noout -text
end

function __crt_pem2dict

    set -l pem $argv[1]

    echo "$pem" | openssl x509 -noout -serial -issuer -subject -startdate -enddate | while read line

        if string match -r "^serial=" $line >/dev/null
            echo "serial"
            string replace "serial=" "" $line
        end
        if string match -r "^issuer=" $line >/dev/null
            echo "issuer"
            string replace -ra 'issuer=C = .*, O = (.*), .*' '$1' $line
        end
        if string match -r "^notBefore=" $line >/dev/null
            set -l not_before (string replace 'notBefore=' '' $line)
            echo "start_date"
            date --iso-8601=seconds -d "$not_before"
            echo "start_date_utc"
            date --iso-8601=seconds -u -d "$not_before"
        end
        if string match -r "^notAfter=" $line >/dev/null
            set -l not_after (string replace 'notAfter=' '' $line)
            echo "end_date"
            date --iso-8601=seconds -d "$not_after"
            echo "end_date_utc"
            date --iso-8601=seconds -u -d "$not_after"
            echo "cert_expiration_days"
            __crt_expiration_days "$not_after"
        end
        if string match -r "^subject=" $line >/dev/null
            echo "common_name"
            string replace -ra 'subject=.*CN = (.*).*' '$1' $line
        end
    end

    echo "subject_alternative_names"
    echo "$pem" | openssl x509 -noout -ext subjectAltName | grep -A1 "X509v3 Subject Alternative Name:" | tail -1 | string replace ", " "," | string trim
end

function __crt_pem_from_domain

    set -l domain $argv[1]
    set -l cert_line 0
    __crt_ssl_client $domain | while read line

        if test $line = "-----BEGIN CERTIFICATE-----"
           set cert_line 1
        end
        if test $cert_line -eq 1
            echo $line
        end
        if test $line = "-----END CERTIFICATE-----"
            set cert_line 0
        end
    end
end

