-- user cinema
select 
    datname, 
    pid, usename, 
    client_hostname,
    client_addr,
	application_name,	
    state,
    query -- que les requetes du user current: cinema
from pg_stat_activity
where datname = 'dbcinema';

------------------------------------
-- transaction
begin;

insert into movie (title, year)
values ('dummy movie', 2026);

select * from movie where year = 2026;
-- session annulée par le DBA

---------------------------------------
-- transaction
begin; -- prompt: dbcinema=*>

insert into movie (title, year)
values ('dummy movie', 2026);

select * from movie where year = 2026;

-- incorrect query
insert into moooooviiiieee (title, year)
values ('dummy movie', 2026);
-- ERROR:  relation "moooooviiiieee" does not exist
-- prompt : dbcinema=!>

-- la session est en mode erreur
select * from movie where year = 2026;
-- ERROR:  current transaction is aborted, commands ignored until end of transaction block

-- fin de transaction => fin du mode erreur
rollback;

--------------------------------------------------------------
-- nouvelle transaction : DML : 
-- INSERT, UPDATE, DELETE => lock posé sur le tuple en cours de modif => fin transaction
-- SELECT => lock provisoire le temps de la lecture
begin;
select * from movie where title like 'Avatar%';
update movie set duration = 166 where id = 499549;
select * from movie where id = 499549; -- changement vu dans cette transaction

-- en // autre session
select * from movie where id = 499549; -- ancienne donnée

-- qui suis-je
select session_user, current_user, pg_backend_pid();

-- en // autre session
begin;
select * from movie where id = 499549;
update movie set duration = 199 where id = 499549;
-- attente

-- 1ere session
commit; -- ou rollback;
select * from movie where id = 499549;
-- => debloque 2e session  

-- modif hors transaction (1ere session)
-- la 2e est en cours de modif (transaction)
update movie set duration = 177 where id = 499549;
-- => attente de la 2e session

-- fin de la 2e transaction
commit; -- ou rollback;

-------------------------------------------------------
-- see also: 
--   * select ... for update => attente globale sur pls lignes
--   * lock table => maintenance
--
-- Exemple:
begin;

select * from movie where year = 1984
for update; 
-- * "reserve" les 16 lignes pour update
-- * les autres sessions qui veulent mettre à jour
--   1 de ces films
--   sont mise en attente

update movie set color = 'COLOR' where year = 1984;
-- update 16

commit; -- libere les 16 lignes

-------------------------------------------------
-- deadlock

-- session 1
begin;
update movie set duration = 166 where id = 76759; -- SW IV
   -- synchro avec autre session
update movie set duration = 167 where id = 2488496; -- SW VII locké par session 2
-- NB: detection de deadlock annule l'autre transaction et
--    libere celle-ci
commit; -- ou: rollback;


-- session 2 : Ordre de traitement croisé !!!!
begin;
update movie set duration = 201 where  id = 2488496; -- SW VII
    -- synchro avec autre session
update movie set duration = 202 where  id = 76759; -- SW IV blocké par la session 1
-- => detection live de deadlock
--   1 des 2 sessions est annulée
-- ERROR:  deadlock detected
-- DETAIL:  Process 2562 waits for ShareLock on transaction 1048; blocked by process 2609.
-- Process 2609 waits for ShareLock on transaction 1049; blocked by process 2562.
-- HINT:  See server log for query details.
-- CONTEXT:  while updating tuple (42,2) in relation "movie"
-- dbcinema=!>
        
commit; -- rollback;

------------------------------------
-- sol 1 sans deadlock : reordonner suivant id, timestamp, ....
-- Ex: choix id croissant

-- session 1
begin;
update movie set duration = 166 where id = 76759; -- SW IV
   -- synchro avec autre session
update movie set duration = 167 where id = 2488496; -- SW VII locké par session 2
commit; 

-- session 2
begin;
update movie set duration = 201 where id = 76759; -- SW IV
   -- synchro avec autre session
update movie set duration = 202 where id = 2488496; -- SW VII locké par session 2
commit; 

--------------------------------------------------------------------
-- sol 2 : select for update
--   * NB: si plusieurs tables => se fixer un ordre des tables

-- session 1
begin;
-- reservation des Star Wars
select id, title, year, duration from movie where title like 'Star Wars%' for update;
-- modif dans n'importe quel ordre
update movie set duration = 166 where id = 76759; -- SW IV
update movie set duration = 167 where id = 2488496; -- SW VII
select id, title, year, duration from movie where title like 'Star Wars%';
commit; -- ou: rollback;


-- session 2 : Ordre de traitement croisé  mais avec select ... for update
begin;

select id, title, year, duration from movie 
where 
    title like 'Star Wars%' 
    or title like '%Terminator%'
for update;

update movie set duration = 200 where  id = 103064; -- T2
update movie set duration = 201 where  id = 2488496; -- SW VII
update movie set duration = 202 where  id = 76759; -- SW IV 
        
select id, title, year, duration from movie 
where 
    title like 'Star Wars%' 
    or title like '%Terminator%';
commit; 


---------------------------------------
-- vue en écriture
create or replace view v_movie80 as
select * 
from movie
where year between 1980 and 1989
with check option;

select id, title, year from v_movie80 order by year, title;
insert into v_movie80 (title, year) values ('super film 80', 1980)
returning id; -- OK : id = 8079256

select id, title, year from v_movie80 order by year, title;

insert into v_movie80 (title, year) values ('super film 90', 1990)
returning id; -- KO
-- Error: new row violates check option for view "v_movie80"

update v_movie80 set duration = 120 where id = 8079256; --OK
select id, title, year, duration from v_movie80 where id = 8079256;
update v_movie80 set year = 1990 where id = 8079256; -- ko
-- ERROR:  new row violates check option for view "v_movie80"

delete from v_movie80 where id = 99077; -- film de 1990 
-- DELETE 0 (pas vu)

delete from v_movie80 where id = 8079256; -- film de 1980
-- DELETE 1 (vu)

-- NB : si vue sur plusieurs tables ou autre raison qui bloque la modif
-- => rules ou trigger instead of

create table movie_p (
	id serial,
	title varchar(300) not null,
	year smallint not null,
	duration smallint null,
	synopsis text null,
	poster_uri varchar(300) null,
	color varchar(20) null,
	pg varchar(15) null,
	director_id int null,
    constraint pk_movie_p primary key(year, id)
) partition by range(year);

insert into movie_p (title, year) values ('The Terminator', 1984);
-- ERROR:  no partition of relation "movie_p" found for row
-- DETAIL:  Partition key of the failing row contains (year) = (1984).

-- créer les partitions nécessaires
create table movie_p_1980s
partition of movie_p
for values from (1980) to (1990);

insert into movie_p (title, year) values ('The Terminator', 1984); -- ok

create table movie_p_1990s
partition of movie_p
for values from (1990) to (2000);

create table movie_p_2000s
partition of movie_p
for values from (2000) to (2010);

\d movie_p -- Number of partitions: 3
\d+ movie_p 
-- Partitions: movie_p_1980s FOR VALUES FROM ('1980') TO ('1990'),
--             movie_p_1990s FOR VALUES FROM ('1990') TO ('2000'),
--             movie_p_2000s FOR VALUES FROM ('2000') TO ('2010')

insert into movie_p (title, year) values ('Terminator 2', 1992); -- ok
insert into movie_p (title, year) values ('Terminator 3', 2003); -- ok

select * from movie_p where title ilike '%terminator%';
select * from movie_p_1980s where title ilike '%terminator%';

select * from movie_p where year = 1992; -- utilise l'index movie_p_1990s_pkey
select * from movie_p where year >= 1992 order by year;


insert into movie_p (title, year, duration)
select title, year, duration from movie
where year between 1980 and 2009;

select year, title from movie_p where year >= 1992 order by year;

-- dump partition only vs table
-- * DDL + Data partition:
-- pg_dump -U cinema -d dbcinema -p 5434 -h localhost -t movie_p_1980s -f movie_p_1980s_dump.sql
-- * DDL table globale (pas de data directement dedans)
-- pg_dump -U cinema -d dbcinema -p 5434 -h localhost -t movie_p -f movie_p_dump.sql

-- suppression 1 partition apres sauvegarde
drop table movie_p_1980s;

-- * restore :
-- psql -U cinema -d dbcinema -h localhost -p 5434 -f movie_p_1980s_dump.sql 

select * from movie_p where year = 1984; 
select * from pg_indexes where schemaname = 'sc_cinema' order by tablename;

select * from pg_stats where tablename like 'movie_p%' order by tablename;



SELECT 
    year,
    duration,
    title,
    RANK() OVER (PARTITION BY year ORDER BY duration desc) AS rank_duration,
    COUNT(*) OVER (PARTITION BY year) AS total_per_year
FROM movie_p
WHERE year BETWEEN 1980 AND 1989
ORDER BY year, rank_duration;


SELECT 
    year,
    COUNT(*) AS count_year,
    AVG(COUNT(*)) OVER (
        ORDER BY year
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS moving_avg_3
FROM movie
WHERE year BETWEEN 1980 AND 1989
GROUP BY year
ORDER BY year;














