function __cert_help

    echo "fish-cert $__cert_version (https://github.com/holly/fish-cert/)

Description:

  aaa

Usage:

  cert [options] domain

Options:

 -A        exclude uppercase alphabets
 -0        exclude numbers
 -y        include symbols
 -B        exclude similar words (0,1,2,9,l,q,z,I,O,Z)

Example:

  # default. length:12 number:45.  password composed of alphabets and numbers
  > pwgen
    ZXC6eFXKrmNhAao8        ZRYecI456CBxwDWT        9pxlOzR9oU1zz7GX        gLLrmWwnC7F3RvFZ        0Ajfn48z581o1dK2        TOb7PhsoeowW92ve
    ytH789LpipKpAEeK        Iamy9WnjWyuYS7vP        1Xfti15drAo1NPG5        3uoy4712mRd4HJV9        ubYe1Vcgly7dmGj5        mCI1u9i3omZyEMSB
    p6sItkZ40za3uDgj        6O4SSZSZztGJvUrG        IDv7sAO5gPJ2k9XZ        9CM1JEstjDJ4AMwG        XRGF72vB5khopmzi        VzNDcXi1UfMEY5rX
    4hsAaoZ6uE9BX4KN        pcrdOSc1baDvwKy0        5UMOh4mStYGMTe3u        DMuf0lht2TvifCCP        yF301bnxLRxejsp4        Ub4H2AjTXVY2wDzG
    lHZ6mmVEXlYUACKp        alVMT3cKcYXdWVgY        KjMMRyGKJA5etcRi        ptbM9Mdl4cOAfSsn        uSh9k2vp69ffNmWu        rc8lbMZjstwnBuRH
    DbrjLeek1mglcWCP        tth0mYYkkaC10heM        hEhLSXv2ko84PIWN        nOyHsyRzBIHojXY2        pMsCkZv5Fo9p86z8        vlmXnhlKUssE2WI5
    0ekFW5OuGUOtIsEZ        NYSY5Y6vnjiOmtiv        RieS8M9DPAvd9WSN        rj1a8HMCMrhRMfLY        iGx3tYNTsmb9H4rO        0s2JDGvJlGitePpf

  # length:16 number:4 with symbols
  > pwgen -y 16 4
    jUPow8_j{ZX{1Mv.    LWkCN9Oos}!AYoV{    0Pa^W3S!a7>J5WSF    AjPp{M9+v;4wXkn6 

Copyright (C) 2023, holly.
"
end

function cert

    argparse -n cert -x "o,O,i,t" \
        "v/version" "h/help" "O" "i/info" "t/text" "o/output="  -- $argv
    or return 1

    if set -lq _flag_version
        echo "fish-cert, version $__cert_version"
        return 0
    end

    if test -n "$_flag_h"
        __cert_help
        return 0
    end

    set -lq _flag_output or "/dev/stdout"

    set -l domain $argv[1]

    if test -z "$domain"
        set_color red; echo "Usage cert [options] domain."
        return 1
    end

    if not __cert_available_443 $domain
        set_color red; echo "$domain:$__cert_ssl_port is unreachable."
        return 1
    end

    set -l pem (__cert_pem_from_domain $domain | string collect)

    if test -z "$pem"
        set_color red; echo "$domain is parse certificate error."
        return 1
    end

    if test -n "$_flag_O"
        set  _flag_output "$domain.crt"
    end

    if string match -rq '^\-$' "$_flag_output" 
       or test -z "$_flag_output"
        set  _flag_output "/dev/stdout"
    end

    begin
        if test -n "$_flag_info"
            set -l dict (__cert_pem2dict $pem)
        else if test -n "$_flag_text"
            __cert_pem2text $pem
        else
            echo $pem
        end
    end > $_flag_output
    #__cert_pem2dict $pem
end

function __cert_available_443

    set -l domain $argv[1]
    nc -w $__cert_ssl_connect_timeout -z $domain $__cert_ssl_port
    return $status
end


function __cert_expiration_days

    set -l enddate $argv[1]
    set -l current_timestamp (date +%s)
    set -l enddate_timestamp (date +%s -d $enddate)
    math "($enddate_timestamp - $current_timestamp) / 60 / 60 / 24" | perl -nle 'print int($_)'
end

function __cert_ssl_client

    set -l domain $argv[1]
    yes | openssl s_client -connect "$domain:$__cert_ssl_port" -tls1_2 -servername $domain 2>/dev/null
end

function __cert_pem2text

    set -l pem $argv[1]
    echo "$pem" | openssl x509 -noout -text
end

function __cert_pem2dict

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
            echo "start_date"
            set -l not_before (string replace 'notBefore=' '' $line)
            date --iso-8601=seconds -d "$not_before"
            echo "start_date_utc"
            date --iso-8601=seconds -u -d "$not_before"
        end
        if string match -r "^notAfter=" $line >/dev/null
            echo "end_date"
            set -l not_after (string replace 'notAfter=' '' $line)
            date --iso-8601=seconds -d "$not_after"
            echo "end_date_utc"
            date --iso-8601=seconds -u -d "$not_after"
            echo "cert_expiration_days"
            __cert_expiration_days "$not_after"
        end
        if string match -r "^subject=" $line >/dev/null
            echo "common_name"
            string replace -ra 'subject=.*CN = (.*).*' '$1' $line
        end
    end

    echo "subject_alternative_names"
    echo "$pem" | openssl x509 -noout -ext subjectAltName | grep -A1 "X509v3 Subject Alternative Name:" | tail -1 | string replace ", " "," | string trim
end

function __cert_pem_from_domain

    set -l domain $argv[1]
    set -l cert_line 0
    __cert_ssl_client $domain | while read line

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

