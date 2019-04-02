#!/bin/bash

function greenecho {
    echo "" && echo -e "\e[30;48;5;82m ✔ $1 \e[0m"
}
function orangeecho {
    echo "" && echo -e "\e[30;48;5;208m ⚠ $1 \e[0m"
}

# Get document root path
DOCUMENT_ROOT=$(drush status --fields=root --format=list)
REMOTE_DOCUMENT_ROOT=$(drush @prod status --fields=root --format=list |head -1)

# Git repo root
cd $DOCUMENT_ROOT && cd ..

# Get fresh sources
greenecho "Update sources"
git pull origin master

# Backup database
greenecho "Backup local database"
drush sql-dump > ../backups/project_local_`date +%Y-%m-%d_%H-%M-%S`.sql

# Import dev database
greenecho "Sync local database with prod database"
drush sql-sync -y @prod @local

# Rsync files
greenecho "Sync local files with prod files"
./scripts/fix_local_files_permissions

# Hack with trailing slash
# https://github.com/drush-ops/drush/issues/2529#issuecomment-275350623
# https://github.com/drush-ops/drush/issues/2324
drush -y rsync @prod:%files/ @local:%files
#scp -r root@prod-machine:$REMOTE_DOCUMENT_ROOT/sites/default/files/* $DOCUMENT_ROOT/sites/default/files/

# Update dependencies
greenecho "Install missing dependencies (composer)"
composer install #--no-dev

# Update database
greenecho "Database updates (drush updb)"
drush updb

# Import dev configuration, even if overridden
greenecho "Import configuration changes"
drush @prod config-export -y
drush rsync -y @prod:%config/ @local:%config
drush config-import

# Update entites schema
greenecho "Update entites schema"
drush entup

# Update locales
orangeecho "Don't forget to update translations with \`drush locale-update\`"
# drush locale-update

# Reindex search_api content
greenecho "Re-Index content"
drush search-api:clear default
drush search-api:index default

# Refresh cache
greenecho "Clearing caches"
drush cr

exit 0
