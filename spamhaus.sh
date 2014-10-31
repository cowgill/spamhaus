#!/bin/bash

# based off the following two scripts
# http://www.theunsupported.com/2012/07/block-malicious-ip-addresses/
# http://www.cyberciti.biz/tips/block-spamming-scanning-with-iptables.html

# path to iptables
IPTABLES="/sbin/iptables";

# list of known spammers
URL1="http://www.spamhaus.org/drop/drop.lasso";
URL2="http://www.spamhaus.org/drop/edrop.lasso";

# save local copy here
FILE1="/tmp/drop.lasso";
FILE2="/tmp/edrop.lasso";

# iptables custom chain for Bad IPs
CHAIN="Spamhaus";

# iptables custom chain for actions
CHAINACT="SpamhausAct";

# Outbound (egress) filtering is not required but makes your Spamhaus setup
# complete by providing full inbound and outbound packet filtering. You can
# toggle outbound filtering on or off with the EGF variable.
# It is strongly recommended that this option NOT be disabled.
EGF="1"

# check to see if the chain already exists
$IPTABLES -L $CHAIN -n

# check to see if the chain already exists
if [ $? -eq 0 ]; then

    # flush the old rules
    $IPTABLES -F $CHAIN

    echo "Flushed old rules. Applying updated Spamhaus list...."    

else

    # create a new chain set
    $IPTABLES -N $CHAIN

    # tie chain to input rules so it runs
    $IPTABLES -A INPUT -j $CHAIN

    # don't allow this traffic through
    $IPTABLES -A FORWARD -j $CHAIN

    if [ $EGF -ne 0 ]; then
        # don't allow access to bad IPs from us
        $IPTABLES -A OUTPUT -j $CHAIN
    fi

    echo "Chain not detected. Creating new chain and adding Spamhaus list...."

fi;

# create a new action set
$IPTABLES -N $CHAINACT

# flush the old action rules
$IPTABLES -F $CHAINACT

# add the ip address log rule to the action chain
$IPTABLES -A $CHAINACT -p 0 -j LOG --log-prefix "[SPAMHAUS BLOCK]" -m limit --limit 3/min --limit-burst 10

# add the ip address drop rule to the action chain
$IPTABLES -A $CHAINACT -p 0 -j DROP


# get a copy of the spam list
for bl in 1 2
do
    URL="URL${bl}"
    URL="${!URL}"
    FILE="FILE${bl}"
    FILE="${!FILE}"
    wget -qc ${URL} -O ${FILE}

    # iterate through all known spamming hosts
    for IP in $( cat $FILE | egrep -v '^\s*;' | awk '{ print $1}' ); do

        # add the ip address to the chain (source filter)
        $IPTABLES -A $CHAIN -p 0 -s $IP -j $CHAINACT

        if [ $EGF -ne 0 ]; then
            # add the ip address to the chain (destination filter)
            $IPTABLES -A $CHAIN -p 0 -d $IP -j $CHAINACT
        fi
        echo $IP

    done

    # remove the spam list
    unlink ${FILE}
done

echo "Done!"
