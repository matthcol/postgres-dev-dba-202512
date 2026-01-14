-- NB: 0.1 (base 10) = 0.00011001100110011001100110011... (base 2)
select 
    0.1::real * 3,
    0.1::numeric * 3
;

-- numeric/decimal meilleur choix pour la finance

-- Attention à la division
select
    5 / 2,
    5 / 2::numeric
;

-- arrondis : ceil(ing), round, floor, trunc

select 
    title || ' (' || year || ')' as title_year,
    concat(title, ' (', year, ')') as title_year2,
    length(title) as title_length,
    octet_length(title) as title_space
from movie
where year = 2025;

select *
from person
where 
    name ~* 'r[eé]n[ée]+'
    or name ~* 'zo[eéë]'
order by name
;

select * from pg_collations;

select *
from person
where 
    name ~* 'r[eé]n[ée]+'
    or name ~* 'zo[eéë]'
order by name collate "fr-FR-x-icu"
;

select *
from person
where 
    name ~* 'r[eé]n[ée]+'
    or name ~* 'zo[eéë]'
order by name collate "en-US-x-icu"
;

select
    convert_to('€', 'UTF-8') as euro_utf8,
    convert_to('€', 'ISO-8859-15') as euro_latin_15,
    convert_to('€', 'win1252') as euro_win1252 
;

-- date/heure system
select
    current_date,
    current_time, -- time with time zone, i.e timetz
    current_timestamp, -- timestamp with time zone, i.e timestamptz
    current_time::time, -- time without time zone, i.e time
    current_timestamp::timestamp, -- timestamp without time zone, i.e timestamp
    current_timestamp at time zone 'Europe/Lisbon',
    current_timestamp at time zone 'America/Los_Angeles',
    current_timestamp at time zone 'Pacific/Auckland'
;
 
-- Dictionnaire des time zones IANA
select * from pg_timezone_names;


select 
    name,
    birthdate,
    current_date - birthdate as age_jours,
    current_date::timestamp - birthdate::timestamp as age_interval,
    age(birthdate) as age, -- 95 years 7 mons 13 days
    extract(year from current_date) - extract(year from birthdate) as age_31dec,
    date_part('year', current_date) - date_part('year', birthdate) as age_31dec_,
    current_date + 3 as date_p3,
    current_date - 3 as date_m3
from person
where 
    name like 'Clint%'
    and birthdate is not null
;

select 
    current_timestamp + '2 days 2 hours 15 minutes' as fin_formation,
    current_timestamp + '2 days 2 hours 15 minutes'::interval as fin_formation2,
    current_timestamp - '1 day 36 hours'::interval as another_moment,
    date_trunc('minute', current_timestamp) as now_mn
;

select 
    '2000-02-29'::date,
    '2028-02-29'::date,
    -- '2100-02-29'::date, -- not a leap year
    '2400-02-29'::date
;

select *
from person
where birthdate between '1930-01-01' and '1930-12-31';

select *
from person
where birthdate between '1930-01-01'::date and '1930-12-31'::date;

-- attention au datestyle pour les dates en FR, EN, ...
show datestyle; -- ISO, MDY
set datestyle = ISO, DMY;

select *
from person
where birthdate between '01/01/1930' and '31/12/1930';

select *
from person
where birthdate = '08/09/1930';

select
    name,
    to_char(birthdate, 'TMday DD TMmonth YYYY')  -- lc_time = C.UTF-8 => saturday 31 may 1930
from person
where name = 'Clint Eastwood'
;

show lc_time; 
-- OS: locale -a

create table movie2 (
    id serial constraint pk_movie2 primary key,
    title varchar(300) not null,
    year int,
    durations int[]
);
\d movie2

insert into movie2 (title, year, durations)
values
    ('The Lord of the Rings: The Fellowship of the Ring', 2001, '{178, 208, 228, 171}'),
    ('The Lord of the Rings: The Two Towers', 2002, '{179, 235, 223, 172}'),
    ('The Lord of the Rings: The Return of the King', 2003, ARRAY[201, 263, 254, 192])
;

-- film de 208 mn
select *
from movie2
where 208 = ANY (durations)
;

select *
from movie2
where ARRAY[208] <@ durations  -- est contenu
;

select *
from movie2
where durations @> ARRAY[208]  -- est contenu
;

-- film de + 230mn
select *
from movie2
where 230 < ANY (durations)
;

select *
from movie2
where 230 < ALL (durations)
; -- aucun

select *
from movie2
where 170 < ALL (durations)
;

-- extensions activées dans la base courante
select * from pg_extension; -- plpgsql

-- extensions disponibles (suivant installation)
select * from pg_available_extensions order by name;

-- Exemple d'installation d'autres extensions
-- OS: apt install postgresql-17-postgis-3

create extension postgis;
\dT  : list Types
\do  : list operators
\df  : list fonctions
\df st_* : list des fonctions commençant par st_


-- Pattern matching

-- * like (CS), ilike (CI)

select title, year
from movie
where title ilike 'star%';

-- * SIMILAR (regexp standard SQL)

-- * Regexp POSIX
-- operator ~* (CI) et ~ (CS)
select title, year
from movie
where title ~* 'star (wars)?.*[IXVLCM]+'
;

select title, year
from movie
where title ~ 'Star (Wars)?.*[IXVLCM]+'
;

select title, year
from movie
where title ~* '^star'
;





