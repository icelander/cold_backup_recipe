# Mattermost Recipe - Cold Backup Server

## Problem

You want to have a standby server at another location that you can deploy rapidly in the event your live server or cluster goes down.

## Solution

### 1. Set up hot server to talk to cold server

Create the SSH config file on the hot server: `~/.ssh/config`

```
admin@hotserver:~$ mkdir ~/.ssh
admin@hotserver:~$ chmod -R 700 ~/.ssh
admin@hotserver:~$ touch ~/.ssh/config
admin@hotserver:~$ chmod -R 600 ~/.ssh/config
admin@hotserver:~$ vi ~/.ssh/config
```

Put this information into the `~/.ssh/config`, replacing the `User` line and `HostName` line with the appropriate information.

```
Host coldserver
  User admin
  HostName 192.168.2.3
  IdentityFile ~/.ssh/id_rsa
```

Use this command to generate an SSH key for this user:

```
admin@hotserver:~$ ssh-keygen
```

Press `Enter` to accept defaults and create the key without any passphrase. Then copy the ID using this command:

```
admin@hotserver:~$ ssh-copy-id coldserver
```

Enter the password for the `admin` user to copy the ID, and then test it by running this:

```
admin@hotserver:~$ ssh coldserver
```

You should be logged into the cold server without entering your password. Type `exit` to get back to the hot server

Finally, add the admin user to the Mattermost group. Replace `admin` with the appropriate username:

```
root@both_servers # usermod -a -G mattermost admin
```

### 2. Create SQL backups

On both servers, run these commands to create the `sql` directory to store the backups in.

```
root@both_servers # mkdir -p /opt/mattermost/sql
root@both_servers # chown mattermost:mattermost /opt/mattermost/sql
root@both_servers # chmod -R a+rw /opt/mattermost/sql
```

Then run this command to backup the database, making sure to replace `really_secure_password` with the correct password.


**PostgreSQL**

```
admin@hotserver:~ export PGPASSWORD="really_secure_password"
admin@hotserver:~ pg_dump -U mmuser -h localhost --format=c --compress=5 --file=/opt/mattermost/sql/db.sqlc mattermost
```

**MySQL**

```
admin@hotserver:~ mysqldump -u mmuser -p mattermost > /opt/mattermost/sql/mattermost.sql
```

### 3. Backup Files

The only files we want to backup from Mattermost are the config, data, plugins, and logs directories. We can back these up to the remote server with this command:

```
admin@hotserver:~$ rsync -rltvzO --progress --stats /opt/mattermost/{data,config,plugins,logs,sql} coldserver:/opt/mattermost/
```

**Note** This recipe assumes you are hosting the Mattermost on the same server as your database. If you aren't, make sure to remove the `config` directory from the above command so you don't end up erasing your cold server's configuration file.

### 4. Test the backup by restoring the database on the cold server

Use this command on the cold server  to restore the database:

**PostgreSQL**

```
admin@coldserver:~ export PGPASSWORD="really_secure_password"
admin@coldserver:~ pg_restore -U mmuser -h localhost -C -d mattermost /opt/mattermost/sql/db.sqlc
```

**MySQL**

```
admin@coldserver:~ mysql -u mmuser -p < /opt/mattermost/sql/mattermost.sql
```

Then, on the cold server, run:

```
admin@coldserver:~ $ sudo service mattermost start
```

And log in to the cold server by going to its URL. Other than the sessions table not being correct which breaks the images, all your content is there. Now remember to shut it down.:

```
admin@coldserver:~ $ sudo service mattermost stop
```

### 5. Automate it.

Use the `clone_to_cold_server.sh` script to run it every day on the active server.

Copy the file into the home directory for the `admin` user first.

**Note:** *Exporting your database will use signficant resources, so it’s best to run at periods of low usage*

```
admin@hotserver:~ $ crontab -e
```

Then add the line:

```
42 3 * * * /home/admin/clone_to_cold_server.sh > ~/mattermost_cold_backup_log 2>&1
```

## Discussion

This recipe includes a Vagrant system that lets you demonstrate and test this system in a local environment. To do this, Install Vagrant and Virtualbox. Then, `cd` into this directory and run `vagrant up`.

This will create a "hot server" with 31 users and a "cold server" without any users, with the appropriate file permissions from steps 1 and 2 for the `vagrant` user. To access the separate servers, use the following commands:

```
$ vagrant ssh hotserver
```

```
$ vagrant ssh coldserver
```

Because of how Vagrant works, all the files in the directory are available in `/vagrant` on both test servers, so to copy the `clone_to_cold_server.sh` you'd run this:

```
vagrant@hotserver:~/ $ cp /vagrant/clone_to_cold_server.sh ~/
```

Also, this is a very basic backup strategy, designed to provide a failover server and not much more. You can improve upon it by using [rsnapshot](https://github.com/rsnapshot/rsnapshot) and [WAL-E](https://github.com/heroku/WAL-E) or [automysqlbackup](https://github.com/sixhop/AutoMySQLBackup) to create incremental backups of both the filesystem and database. These will reduce the size of backups by only copying changes, and give you the ability to restore from specific points in time.