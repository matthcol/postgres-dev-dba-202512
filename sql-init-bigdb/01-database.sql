CREATE DATABASE dbmedia
    TEMPLATE = template0
    LOCALE_PROVIDER = 'icu'
    ICU_LOCALE = 'en-US'
    ENCODING = 'UTF8'
;
create user media with login password 'password'; 

\c dbmedia

create schema sc_media authorization media;

alter user media set search_path = sc_media,public;