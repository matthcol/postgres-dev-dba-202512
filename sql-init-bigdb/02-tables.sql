
create table person (
	id serial,
	name varchar(150) not null,
	birthdate date null,
	birth_year smallint null,
	death_year smallint null
);

create table media (
	id serial,
	title varchar(500) null,
	original_title varchar(500) null,
	media_type varchar(15) null,
	release_year smallint null,
	end_year smallint null,
	duration_mn int null
);

create table have_genre(
	media_id int not null,
	genre varchar(20) not null
);

create table profession (
	id serial,
	name varchar(150) not null
);

create table have_profession(
	person_id int not null,
	prof_id int not null
);

create table known_for(
	person_id int not null,
	media_id int not null
);

create table direct(
	media_id int not null,
	director_id int not null
);

create table play(
	media_id int not null,
	actor_id int not null,
	ordering int null,
	character varchar(500)
);

create table have_episode(
	series_id int not null,
	episode_id int not null,
	season_number int,
	episode_number int
);

create table aka(
	id serial,
	media_id int not null,
	ordering int,
	title varchar(900) not null,
	region varchar(4),
	language varchar(4),
	aka_types varchar(100),
	aka_attributes varchar(100),
	is_original boolean
);
