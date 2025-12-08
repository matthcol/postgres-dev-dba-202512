# PostgreSQL : day 1

## Installation
### Exemple : Ubuntu-24
```
apt search postgresql
```
- postgresql = postgresql-16 (server)
- postgresql-client = postgresql-client-16 (client)

### Exemple : debian trixie
- postgresql = postgresql-17
- postgresql-client = postgresql-client-17

### Installation de repo supplémentaire (Debian, Ubuntu)
Procédure disponible par distribution Linux sur postgresql.org -> download:
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


### Checkup Installation
```
# Service layer:
systemctl start|stop|reload|restart postgresql@18-main
systemctl status postgresql@18-main
    # Extrait : 23580 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf

# Network layer:
netstat -plantu | grep LISTEN
    # Exemples de résultats:
    # tcp        0      0 0.0.0.0:5432            0.0.0.0:*               LISTEN      23580/postgres
    # tcp        0      0 127.0.0.1:5442          0.0.0.0:*               LISTEN      3291/postgres

# Première connexion:
sudo su - postgres      # user OS (no password)
psql                    # authent peer : postgres (OS) <-> postgres (DB)  (both: no password)
```
## Configuration réseau:
### postgresql.conf
```
listen_addresses = '*'  
port = 5432 
max_connections = 100 
```

### pg_hba.conf
```
local   all             postgres                                peer
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
```

Donner un mot de passe au user postgres
```
alter user postgres password '1_super_mot_de_passe_securisé';
```

## PgAdmin4
### Installation sur Ubuntu/Debian via repository
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
```
sudo /usr/pgadmin4/bin/setup-web.sh
    Email address: admin@example.org
    Password: 
    Retype password:
```

## Gestion de cluster debian family
La distrubution offre un ensemble d'outils dédiés visant à simplifier la gestion de plusieurs serveurs de bdd ou d'instances répliquées :
```
pg_lsclusters

pg_createcluster 18 main --port=5433
    # NB: délègue à l'outil : initdb
    
    systemctl start postgresql@18-main
    systemctl status postgresql@18-main

pg_ctlcluster 18 main start|stop|restart|reload|status
    # NB: délègue à l'outil : pg_ctl
```

NB: l'équivalent RHEL family de pg_createcluster est postgresql-setup

## Installation d'une base métier
### 1 - creer 1 base + 1 user (DBA)

```
psql -U postgres  
    create database dbcinema encoding = 'UTF-8';
    create user cinema with login password 'password';
    \l
    \dg

    select * from pg_roles;
    -- result: tous les user + role

    -- "users" = user/role avec privilege login
    select * from pg_roles where rolcanlogin;
    -- result: postgres + cinema
```

### 2 - tester la connexion
```
psql -U cinema -d dbcinema                  # via socket UNIX
psql -U cinema -d dbcinema -h localhost     # via network
```

### 3 - creer un schema métier (DBA)
```
psql -U postgres -d dbcinema 
    create schema sc_cinema authorization cinema;
    alter schema sc_cinema rename to sccinema;
    \dn                 # liste schema
    \dn+                # idem + privileges
    \dn cinema          # detail schema cinema
    \dn+ cinema         # idem + privilege
```

Privilèges sur les schemas:
- U : Usage (droit de passage)
- C : Create (droit de créer des objets: tables, vues, index, ...)
- CU : All (Usage + Create)

### 4 - installer les tables (et data) métiers
User cinema sur la base dbcinema

```
psql -U cinema -d dbcinema  -h localhost
    show search_path;                -- "$user", public
    set search_path = sccinema;      -- dans cette session  
    show search_path;

    alter user cinema set search_path = sccinema; -- pour toutes les sessions futures (soit en DBA soit le user lui-même)

psql -U cinema -d dbcinema -h localhost -f  00b-import-tables.sql
psql -U cinema -d dbcinema -h localhost
    \d -- table, vue, sequence
    \dt -- uniquement les tables
    \ds -- liste de sequence
    \dv -- liste des vues

    \di -- liste des index : vue pg_indexes


    insert into movie (title, year, duration) values ('Avatar: Fire and Ash', 2025, 195);
            -- declenche: nextval('movie_id_seq')
    select * from movie where year = 2025;
    select currval('movie_id_seq');

    insert into movie (title, year, duration) values ('F1', 2025, 155) returning id;
```

## Gestion des users
Les mots clés USER et ROLE sont confondus dans le DDL de postgresql:
```
select * from pg_roles;
-- result: tous les user + role

-- "users" = user/role avec privilege login
select * from pg_roles where rolcanlogin;
-- result: postgres + cinema

select * from pg_shadow;

set password_encryption = 'md5';
create user usermd5 with login password 'password'; -- WARNING:  setting an MD5-encrypted password
select * from pg_shadow;
set password_encryption = 'scram-sha-256';
alter user usermd5 with password 'password';
select * from pg_shadow;
```

## Docker
Config: docker/dbcinema/docker-compose.yml

```
docker compose up -d
docker compose logs db
docker compose exec -it db bash
    psql -U cinema -d dbcinema
    \d

    apt update
    apt install procps
    ps -aef | grep postgres
```

## Gestion des fichiers de données
Avec user postgres ou cinema
```
select * from pg_indexes
where schemaname = 'sccinema';

select * from pg_tables
where schemaname = 'sccinema';

select * from pg_database;
-- "5"	"postgres"
-- "16388"	"dbcinema"
-- "1"	"template1"
-- "4"	"template0"

select 
	oid, -- immuable = 1er fichier à la création
	relname,
	relnamespace,
	relfilenode, -- nom du 1er fichier, change à chaque VACUUM FULL
	relkind
from pg_class 
where  
	-- relname like 'movie';
	relnamespace = 16390
order by relkind;  -- S : sequence, i : index, r : table
```


Avec user cinema (SQL):
```
select count(*) from play; -- 66547
delete from play where actor_id % 2 = 0; -- DELETE 33584
select count(*) from play; -- 32963
```

Le fichier de data ne bouge pas, seule la cartographie _fsm est revue
```
-rw------- 1 postgres postgres 3.4M Dec  8 16:49 16422
-rw------- 1 postgres postgres  24K Dec  8 16:49 16422_fsm
-rw------- 1 postgres postgres 8.0K Dec  8 16:49 16422_vm
```

SQL:
```
vacuum full play; -- defragmentation par copie

select 
	oid, -- immuable = 1er fichier à la création
	relname,
	relnamespace,
	relfilenode, -- nom du 1er fichier, change à chaque VACUUM FULL
	relkind
from pg_class 
where  
	-- relname like 'movie';
	relnamespace = 16390
order by relkind;  -- S : sequence, i : index, r : table
```

Avec user postgres, defragmentation de la base entiere (SQL):
```
vacuum full; -- toute la base => tous les fichiers de table et index changent

select 
	oid, -- immuable = 1er fichier à la création
	relname,
	relnamespace,
	relfilenode, -- nom du 1er fichier, change à chaque VACUUM FULL
	relkind
from pg_class 
where  
	-- relname like 'movie';
	relnamespace = 16390
order by relkind;
```



