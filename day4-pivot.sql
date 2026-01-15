-- avec extension :
-- create extension tablefunc;

SELECT *
FROM crosstab(
    'SELECT media_type, release_year, COUNT(*)::int
     FROM media
     WHERE release_year BETWEEN 1980 AND 1989
     GROUP BY media_type, release_year
     ORDER BY media_type, release_year',
    'SELECT generate_series(1980, 1989)'
) AS ct(
    media_type TEXT,
    "1980" INT,
    "1981" INT,
    "1982" INT,
    "1983" INT,
    "1984" INT,
    "1985" INT,
    "1986" INT,
    "1987" INT,
    "1988" INT,
    "1989" INT
);