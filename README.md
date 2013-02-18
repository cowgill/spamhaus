## Spamhaus DROP List ##
A shell script that grabs the latest Spamhaus DROP List and adds it to iptables. We use this (among other tools) on our Ubuntu proxy server at [AppThemes](http://www.appthemes.com/) to cut down on spam and other malicious activity.

## Usage ##
Place the script somewhere on your server.

<pre>
# find a nice home
cd /home/YOUR-USERNAME/bin/

# create the file and paste
vim spamhaus.sh

# make it executable
chmod +x spamhaus.sh

# set it loose
sudo ./spamhaus.sh

# confirm the rules have been added
sudo iptables -L Spamhaus -n
</pre>

## Automatic Updating ##
In order for the list to automatically update each day, you'll need to setup a cron job with crontab.
<pre>
# fire up the crontab (no sudo)
crontab -e

# run the script every day at 3am
0 3 * * * /home/YOUR-USERNAME/bin/spamhaus.sh
</pre>


## Troubleshooting ##
If you need to remove all the Spamhaus rules, run the following:
<pre>
sudo iptables -F Spamhaus
</pre>
