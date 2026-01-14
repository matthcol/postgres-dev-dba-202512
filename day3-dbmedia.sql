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
	p.name
from 
	person p
	join direct d on p.id = d.director_id
	join media m on d.media_id = m.id
where 
	p.name = 'Clint Eastwood'
order by m.release_year desc;


