
select 'person' as "table",  count(*) as nb_row  from person
UNION
select 'media' as "table",  count(*) as nb_row  from media
UNION
select 'profession' as "table",  count(*) as nb_row  from profession
UNION
select 'have_profession' as "table",  count(*) as nb_row  from have_profession
UNION
select 'known_for' as "table",  count(*) as nb_row  from known_for
UNION
select 'direct' as "table",  count(*) as nb_row  from direct
UNION
select 'have_genre' as "table",  count(*) as nb_row  from have_genre
UNION
select 'play' as "table",  count(*) as nb_row  from play
UNION
select 'have_episode' as "table",  count(*) as nb_row  from have_episode
UNION
select 'aka' as "table",  count(*) as nb_row  from aka;
;