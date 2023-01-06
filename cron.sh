#!/usr/bin/env bash

crontab -l > additional_cron
sed -i -E 's/(.*customer_shipment_done)/#\1/' additional_cron

echo "" >> additional_cron
echo "#DDNS" >> additional_cron
echo "*/5 * * * * /etc/ddns.sh" >> additional_cron

#install new cron file
crontab additional_cron
rm additional_cron
