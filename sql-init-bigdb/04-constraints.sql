-- primary and unique constraints
alter table person add constraint pk_person primary key(id);
alter table media add constraint pk_media primary key(id);
alter table profession add constraint pk_profession primary key (id);
alter table profession add constraint unique_profession unique (name);
alter table have_profession add constraint pk_have_profession primary key(person_id, prof_id);
alter table known_for add constraint pk_known_for primary key(person_id, media_id);
alter table direct add constraint pk_direct primary key(media_id, director_id);
alter table aka add constraint pk_aka primary key(id);

-- foreign keys constraints
alter table play add constraint FK_PLAY_MEDIA 
	FOREIGN KEY (media_id)
	references media(id);
alter table play add constraint FK_PLAY_ACTOR 
	FOREIGN KEY (actor_id)
	references person(id);
alter table have_genre add constraint FK_HAVE_GENRE 
	FOREIGN KEY (media_id)
	references media(id);
alter table have_profession add constraint FK_HAVE_PROF_PERSON
	FOREIGN KEY (person_id)
	references person(id);
alter table have_profession add constraint FK_HAVE_PROF_PROF
	FOREIGN KEY (prof_id)
	references profession(id);
alter table known_for add constraint FK_KNOWN_FOR_PERSON
	FOREIGN KEY (person_id)
	references person(id);
alter table known_for add constraint FK_KNOWN_FOR_MEDIA
	FOREIGN KEY (media_id)
	references media(id);
alter table direct add constraint FK_DIRECT_DIRECTOR
	FOREIGN KEY (director_id)
	references person(id);
alter table direct add constraint FK_DIRECT_MEDIA
	FOREIGN KEY (media_id)
	references media(id);	
alter table have_episode add constraint FK_HAVE_EP_SERIES
	FOREIGN KEY (series_id)
	references media(id);
alter table have_episode add constraint FK_HAVE_EP_EP
	FOREIGN KEY (episode_id)
	references media(id);
alter table aka add constraint FK_AKA_MEDIA
	FOREIGN KEY (media_id)
	references media(id);