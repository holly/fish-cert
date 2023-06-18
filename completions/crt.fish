complete -c crt -s O --description "Write output to a file named as the \$domain.crt"
complete -c crt -s t -l text --description "Same as `openssl x509 -text -noout`"
complete -c crt -s H -l humanize --description "Show humanize key/value pairs `openssl x509 -text -noout`"
complete -c crt -s J -l json --description "Show key/value json output"
complete -c crt -s h -x --description "Display help and exit"
complete -c crt -a domain
