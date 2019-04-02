#!/bin/bash

function greenecho {
    echo "" && echo -e "\e[30;48;5;82m ✔ $1 \e[0m"
}
function orangeecho {
    echo "" && echo -e "\e[30;48;5;208m ⚠ $1 \e[0m"
}

# Get document root path
DOCUMENT_ROOT=$(drush status --fields=root --format=list)

# Git repo root
cd $DOCUMENT_ROOT && cd ..

# Maintenance mode
greenecho "Entering maintenance mode"
drush state-set system.maintenance_mode 1

# Get fresh sources
greenecho "Update sources"
git pull origin master
drush cr

# Backup database
greenecho "Backup database"
drush sql-dump > /tmp/projectname_`date +%Y-%m-%d_%H-%M-%S`.sql
echo "Database backup in /tmp/projectname_`date +%Y-%m-%d_%H-%M-%S`.sql"

# Update dependencies
greenecho "Update dependencies (composer install --no-dev)"
composer install --no-dev

# Update database
greenecho "Update database"
drush updb -y

# Import new configuration
greenecho "Import configuration changes"
drush config-import -y

# Update entites schema
# greenecho "Update entites schema"
# drush entup

# Refresh cache
greenecho "Refresh caches"
drush cr

# Maintenance mode
greenecho "Exiting maintenance mode"
drush state-set system.maintenance_mode 0

# Update locales
greenecho "Update translations"
drush locale-update

# Reindex search_api content
greenecho "Re-Index content"
drush search-api:clear default
drush search-api:index default

# Refresh cache
greenecho "Refresh caches"
drush cr
