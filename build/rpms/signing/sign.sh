#!/usr/bin/env expect
set rpmpath [lindex $argv 0]
spawn rpm --resign $rpmpath
expect "Enter pass phrase:"
send "\r"
expect eof
