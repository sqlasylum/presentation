#!/bin/bash
#make sure to set cron tab to run hourly
# Script to remove old base backups from /mnt/data/backups/base/pg-YYYY-MM-DD
# Should be run on a schedule via cron to remove old backups after a certain number of days.

daystokeep='1'

find /mnt/data/backups/review_rocket/base/pg-2* -maxdepth 0 -type d -mtime +$daystokeep -exec rm -r {} \;
