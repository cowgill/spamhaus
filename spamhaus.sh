#!/bin/bash

# based off the following three scripts
# http://www.theunsupported.com/2012/07/block-malicious-ip-addresses/
# http://www.cyberciti.biz/tips/block-spamming-scanning-with-iptables.html
# https://github.com/cowgill/spamhaus/edit/master/spamhaus.sh

# path to iptables
IPTABLES="/sbin/iptables";

# list of known spammers
URL="www.spamhaus.org/drop/drop.lasso";

# save temp local copy here
FILE="/tmp/drop.lasso";

# save permanent local copy here
SAVE="/etc/blacklist/drop.lasso"

# iptables custom chain
CHAIN="spamhaus";

# Runtime flags
# Quiet run for cron usage
if [ "$1" == "-q" ] ; then
        QUIET=1
        shift
else
        QUIET=0
fi

# Allow reload in rc.local without consulting spamhaus
if [ "$1" == "-l" ] ; then
        shift
        LOCAL=1
else
        LOCAL=0
fi

# Download only if requested
if [ $LOCAL -eq 0 ] ; then

    # get a copy of the spam list
    if [ $QUIET -eq 0 ] ; then
        wget -qc $URL -O $FILE
    else
        wget -qqqqqc $URL -O $FILE
    fi

    # Verify we got a file    
    if [ `wc -l $FILE | cut -f1 -d\ ` != "0" ] ; then
            mv "$FILE" "$SAVE"
    else
            unlink $FILE
    fi
fi

# Download from spamhaus without erasing content
if [ "$1" == "-n" ] ;then
    if [ $QUIET -eq 0 ] ; then
        echo "Dry run complete"
        echo "File results are in $SAVE"
    fi
    exit
fi

# At this stage, we have a valid new file or we have the old file still intact
# Loading IPTables now means that if the download failed, we will not leave
# our mail server unprotected while there is no spamhaus update file

# check to see if the chain already exists
if [ $QUIET -eq 0 ] ; then
    $IPTABLES -L $CHAIN -n
else
    $IPTABLES -L $CHAIN -n >/dev/null 2>/dev/null
fi

# check to see if the chain already exists
if [ $? -eq 0 ]; then

    # flush the old rules
    $IPTABLES -F $CHAIN

    if [ $QUIET -eq 0 ] ; then
        echo "Flushed old rules. Applying updated Spamhaus list...."    
    fi

else

    # create a new chain set
    $IPTABLES -N $CHAIN

    # tie chain to input rules so it runs
    $IPTABLES -A INPUT -j $CHAIN

    # don't allow this traffic through
    $IPTABLES -A FORWARD -j $CHAIN
 
    if [ $QUIET -eq 0 ] ; then
        echo "Chain not detected. Creating new chain and adding Spamhaus list...."
    fi
fi;


# iterate through all known spamming hosts
for IP in $( cat $SAVE | egrep -v '^;' | awk '{ print $1}' ); do

    # add the ip address log rule to the chain
    $IPTABLES -A $CHAIN -p 0 -s $IP -j LOG --log-prefix "[SPAMHAUS BLOCK]" -m limit --limit 3/min --limit-burst 10

    # add the ip address to the chain
    $IPTABLES -A $CHAIN -p 0 -s $IP -j DROP

    if [ $QUIET -eq 0 ] ; then
        echo $IP
    fi

done

if [ $QUIET -eq 0 ] ; then
    echo "Done!"
fi

