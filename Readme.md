# PostgreSQL

## Installation
Exemple : Ubuntu-24
apt search postgresql

- postgresql = postgresql-16 (server)
- postgresql-client = postgresql-client-16 (client)

Exemple : debian trixie
- postgresql = postgresql-17
- postgresql-client = postgresql-client-17

Installation de repo supplémentaire:
```
# Import the repository signing key:
sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Create the repository configuration file:
. /etc/os-release
sudo sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"

# Update the package lists:
sudo apt update

sudo apt install postgresql-18
```

Debian:
```
sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
. /etc/os-release
sudo sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
sudo apt update
```

## Checkup
systemctl start|stop|reload|restart postgresql@18-main
systemctl status postgresql@18-main
    23580 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf

netstat -plantu | grep LISTEN
    tcp        0      0 0.0.0.0:5432            0.0.0.0:*               LISTEN      23580/postgres
    tcp        0      0 127.0.0.1:5442          0.0.0.0:*               LISTEN      3291/postgres

sudo su - postgres      # user OS (no password)
psql                    # authent peer : postgres (OS) <-> postgres (DB)  (both: no password)

## config réseau
postgresql.conf
    listen_addresses = '*'  
    port = 5432 
    max_connections = 100 

pg_hba.conf
    local   all             postgres                                peer
    local   all             all                                     scram-sha-256
    host    all             all             127.0.0.1/32            scram-sha-256
    host    all             all             ::1/128                 scram-sha-256

Donner un mot de passe au user postgres
    alter user postgres password 'password';

## PgAdmin4
```
#
# Setup the repository
#

# Install the public key for the repository (if not done previously):
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

# Create the repository configuration file:
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'

#
# Install pgAdmin
#

# Install for both desktop and web modes:
sudo apt install pgadmin4

# Install for desktop mode only:
sudo apt install pgadmin4-desktop

# Install for web mode only: 
sudo apt install pgadmin4-web
```

Post-install pour la version Web
sudo /usr/pgadmin4/bin/setup-web.sh
    Email address: admin@example.org
    Password: 
    Retype password:

## Gestion de cluster debian family

pg_lsclusters

pg_createcluster 18 main --port=5433
    # NB: délègue à l'outil : initdb
    
    systemctl start postgresql@18-main
    systemctl status postgresql@18-main

pg_ctlcluster 18 main start|stop|restart|reload|status
    # NB: délègue à l'outil : pg_ctl
