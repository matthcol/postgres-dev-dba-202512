-- user dba sur : postgres
select * from pg_stat_activity;

-- liste des sessions
select 
    datname, 
    pid, usename, 
    client_hostname,
    client_addr,
    application_name,	
    state
    -- query -- dba voit les requetes de tout le monde
from pg_stat_activity
where datname = 'dbcinema';

--------------------------------------------
-- agir sur une session

-- solution sympa : terminer requete, transaction en cours
 select pg_cancel_backend(2393);

-- solution ultime : terminer la connexion et le processus dédié
select pg_terminate_backend(2393);

-- voir les activités en cours de transaction => résultat:
--  dbcinema | 2420 | cinema  | psql  | idle in transaction
select pg_cancel_backend(2420);
select pg_terminate_backend(2420);

-- voir une activité en mode error
-- dbcinema | 2609 | cinema   | psql  | idle in transaction (aborted)

-- voir les sessions et verrous de transaction en cours
select * from pg_stat_activity;
select * from pg_locks;
select * from pg_class;

select 
    d.datname,
    c.relname,
    a.pid,
    a.usename,
    -- l.mode,
    -- l.granted
    l.*
from 
    pg_locks l
    join pg_stat_activity a on l.pid = a.pid
    join pg_database d  on l.database = d.oid
    join pg_class c on c.oid = l.relation
    join pg_namespace n on n.oid = c.relnamespace
where 
    d.datname = 'dbcinema'
    and n.nspname = 'sc_cinema'
order by a.pid, c.relname, l.mode
;

SHOW transaction_isolation; -- default: read committed
