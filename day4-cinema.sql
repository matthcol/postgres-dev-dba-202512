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
update movie set duration = 167 where id = 2488496; -- SW VII
commit; -- rollback;

-- session 2 : Ordre de traitement croisé !!!!
begin;
update movie set duration = 201 where  id = 2488496; -- SW VII
    -- synchro avec autre session
update movie set duration = 202 where  id = 76759; -- SW IV
commit; -- rollback;

-- => detection live de deadlock
--   1 des 2 sessions est annulée
-- ERROR:  deadlock detected
-- DETAIL:  Process 2562 waits for ShareLock on transaction 1048; blocked by process 2609.
-- Process 2609 waits for ShareLock on transaction 1049; blocked by process 2562.
-- HINT:  See server log for query details.
-- CONTEXT:  while updating tuple (42,2) in relation "movie"
-- dbcinema=!>




