#!/bin/bash

export PGPASSWORD="really_secure_password"
pg_dump -U mmuser -h localhost --format=c --compress=5 --file=/opt/mattermost/sql/db.sqlc mattermost

rsync -rltvzO --progress --stats /opt/mattermost/{data,config,plugins,logs,sql} coldserver:/opt/mattermost/