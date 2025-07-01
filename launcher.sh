#!/bin/sh
# we need ( two scripts) ( ./sub/urls.txt )
## makes dir called sub if not present already
mkdir sub -p
## runs subdomain making script ./sub/subfinder.sh that output hosts.txt
./sub/subfinder.sh -i ./sub/urls.txt
## runs the graphql on that ./sub/hosts.txt 
./graphql_checker.sh -i ./sub/hosts.txt
