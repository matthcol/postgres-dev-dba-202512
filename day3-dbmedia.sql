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











	












