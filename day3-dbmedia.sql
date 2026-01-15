select *
from media
where release_year = 1984
	and media_type = 'movie'
;

select distinct(media_type) from media;

select * from person where name = 'Clint Eastwood';

select * from person where name = 'Steve McQueen';


select 
	m.release_year,
	m.title,
	m.media_type,
	p.id,
	p.name
from 
	person p
	join direct d on p.id = d.director_id
	join media m on d.media_id = m.id
where 
	-- p.name like 'Clint Eastwood'
	-- p.name = 'Clint Eastwood'
	-- p.name ilike 'clint eastwood'
	-- lower(p.name) = 'clint eastwood'
	-- p.name like 'Clint E%'
	p.name like '%Eastwood'
order by p.id, m.release_year desc;

-- index explicite
create index idx_direct_director on direct(director_id); -- default BTREE

-- ok avec predicat : 
--   * where name = 'Clint Eastwood'
--   * where name like 'Clint Eastwood'
create index idx_person_name on person(name);


drop index idx_person_name;

-- index ok avec les predicats :
-- * where lower(p.name) = 'clint eastwood'
-- * where p.name ilike 'clint eastwood'
create index idx_person_name on person(lower(name)); 

create index idx_person_name on person(name text_pattern_ops);  -- si collation ICU
-- index ok avec predicat: where p.name like 'Clint E%' 
-- index ko avec predicat: where  p.name like '%Eastwood'

select * from pg_collation;


select
	count(distinct id)::numeric / count(id)::numeric as selectivity_id, -- 1.0 => unique
	count(distinct name)::numeric / count(name)::numeric as selectivity_name -- 0.76
from person
;

select 
	count(distinct media_type)::numeric / count(media_type)::numeric as selectivity_media_type -- 0.000001016985224961292156
from media;


-- index trigram

-- en dba:
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- retour user media
drop index idx_person_name;

create index idx_person_name on person  using GIST (name gist_trgm_ops);
-- ou: create index idx_person_name on person  using GIN (name gin_trgm_ops);

show search_path;



-- index BRIN pour des tables triées sur l'index utilisé !!!
-- Exemple: table temporelle


select *
from media
where release_year = 1975;

select *
from media
where release_year between 1970 and 1979
order by title desc;

create index idx_media_release_year on media using brin (release_year);

insert into media (id, title, release_year) values (999999999, 'zzz_test brin', 1975);
delete from media where id = 999999999;


-- NB: voir instruction cluster pour retrier une table suivant un index



select 
	m.release_year,
	m.title,
	m.media_type,
	p.id,
	p.name
from 
	media m
	join direct d on d.media_id = m.id
	join person p on p.id = d.director_id
where 
	p.name ilike 'clint eastwood'
order by p.id, m.release_year desc;


-- NB: jointure interne commutative => plan execution flexible

select 
	p.id, p.name,
	pf.name,
	m.release_year, m.title
from 
	person p
	join have_profession hpf on p.id = hpf.person_id
	join profession pf on pf.id = hpf.prof_id
	left join direct d on p.id = d.director_id
	left join media m on m.id = d.media_id
where
	p.name ilike 'steve mcqueen'
	and (m.release_year between 1970 and 1999 or m.id is NULL)
	and pf.name in ('director', 'actor')
order by p.id, m.release_year;

with media_70_90 as (
	select * 
	from media
	where release_year between 1970 and 1999
)
select 
	p.id, p.name,
	pf.name,
	m.release_year, m.title
from 
	person p
	join have_profession hpf on p.id = hpf.person_id
	join profession pf on pf.id = hpf.prof_id
	left join direct d on p.id = d.director_id
	left join media_70_90 m on m.id = d.media_id
where
	p.name ilike 'steve mcqueen'
	and pf.name in ('director', 'actor')
order by p.id, m.release_year;


select 
	p.id, p.name,
	pf.name,
	m.release_year, m.title
from 
	person p
	join have_profession hpf on p.id = hpf.person_id
	join profession pf on pf.id = hpf.prof_id
	left join direct d on p.id = d.director_id
	left join  (
		select * 
		from media
		where release_year between 1970 and 1999
	) m on m.id = d.media_id
where
	p.name ilike 'steve mcqueen'
	and pf.name in ('director', 'actor')
order by p.id, m.release_year;

-- NB: attention la jointure peut multiplier les données .. ou en faire disparaitre (inner join)

-- exemple d'enquete
select * 
from 
	person p
	join have_profession hpf on p.id = hpf.person_id
	join profession pf on pf.id = hpf.prof_id
where 
	pf.name in ('director', 'actor')
	and not exists (
		select * 
		from known_for kf 
		where p.id = kf.person_id
	);

select 
	p.id, p.name,
	pf.name,
	md.release_year, md.title,
	mkf.title as title_known_for
from 
	person p
	join have_profession hpf on p.id = hpf.person_id
	join profession pf on pf.id = hpf.prof_id
	left join  (
		select * 
		from 
			media m0
			join direct d on m0.id = d.media_id
		where release_year between 1970 and 1999
	) md on p.id = md.director_id
	left join known_for kf on kf.person_id = p.id
	left join media mkf on kf.media_id = mkf.id
where
	p.name ilike 'steve mcqueen'
	and pf.name in ('director', 'actor')
order by p.id, md.release_year;


select 
	p.id,
	p.name, -- OK car en DF avec la PK p.id
	count(distinct md.id) as count_directed_70_90,
	string_agg(distinct mkf.title, ', ') as known_for_titles
from 
	person p
	join have_profession hpf on p.id = hpf.person_id
	join profession pf on pf.id = hpf.prof_id
	left join  (
		select * 
		from 
			media m0
			join direct d on m0.id = d.media_id
		where release_year between 1970 and 1999
	) md on p.id = md.director_id
	left join known_for kf on kf.person_id = p.id
	left join media mkf on kf.media_id = mkf.id
where
	p.name ilike 'steve mcqueen'
	and pf.name in ('director', 'actor')
group by p.id
order by p.id;

-- statistiques de table (utile pour le plan d'execution)
select * 
from pg_stats
where schemaname = 'sc_media'
order by tablename, attname;

analyze person;

SHOW default_statistics_target; -- 100 i.e. 1%

ALTER TABLE person ALTER COLUMN name SET STATISTICS 1000;
-- Valeurs typiques :
-- Colonnes normales : 100 (défaut)
-- Colonnes importantes : 200-500
-- Colonnes critiques avec haute cardinalité : 1000-2000

-- Autovacuum se déclenche quand :
-- tuples_modifiés > threshold + (scale_factor × nombre_total_tuples)

-- Au niveau d'une table
-- changer les valeurs par défaut des seuils du postgresql.conf
ALTER TABLE person SET (
	autovacuum_vacuum_threshold = 100,
    autovacuum_vacuum_scale_factor = 0.05,    -- 5% au lieu de 20%
    autovacuum_analyze_threshold = 50,
    autovacuum_analyze_scale_factor = 0.02 -- 2% au lieu de 10%
);

analyze person;

-- stats sur les (auto)vacuum et auto(analyze)
SELECT 
    schemaname,
    relname,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_live_tup,
    n_dead_tup  -- utile pour le vacuum full
FROM pg_stat_user_tables
WHERE relname = 'person';

-- occupation disque
SELECT 
    pg_size_pretty(pg_total_relation_size('person')) AS total_size,
    pg_size_pretty(pg_relation_size('person')) AS table_size,
    pg_size_pretty(pg_indexes_size('person')) AS indexes_size,
    pg_size_pretty(pg_total_relation_size('person') - pg_relation_size('person') - pg_indexes_size('person')) AS toast_size
;

SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS indexes_size,
    pg_total_relation_size(schemaname||'.'||tablename) AS total_bytes
FROM pg_tables
WHERE schemaname = 'sc_media'
ORDER BY total_bytes DESC;


select * from pg_extension;
select * from pg_available_extensions where name like '%stat%';

-- en dba:
create extension pg_stat_statements;
select * from pg_extension; 

-- nécessite en + le chargement d'une librairie C++
-- ERROR:  pg_stat_statements must be loaded via "shared_preload_libraries"
--
-- => postgresql.conf add line:
-- shared_preload_libraries = 'pg_stat_statements'         # (change requires restart)
select * 
from pg_stat_statements
order by mean_exec_time desc;

-- en dba: reset la table de collecte des stats (démarrage phase observation)
-- ou donner le droit grant execute on function pg_stat_statements_reset to media;
select pg_stat_statements_reset();

show pg_stat_statements.track;

-- desactiver la collecte de stats
-- en dba
ALTER SYSTEM SET pg_stat_statements.track = none; -- + restart


select to_tsvector('french', 'Le Clown et ses Chiens');

select to_tsvector('french', 'des chevaux et des chèvres'); -- "'cheval':2 'chevr':5"


select *
from aka
where to_tsvector('french', title) @@ to_tsquery('french', 'clown & chien')
	and region = 'FR'
;

create index idx_aka_title_fr on aka using GIN(to_tsvector('french', title))
WHERE region = 'FR';

select *
from aka
where to_tsvector('french', title) @@ to_tsquery('french', 'guerre & paix')
	and region = 'FR'
;











	












