-- en postgres sur la base de maintenance postgres
create database dbcinema encoding = 'UTF-8';
create user cinema with login password 'password'; -- scram-sha-256

-- changement de base
\c dbcinema

-- creation du schema sc_cinema appartenant à cinema
create schema sc_cinema authorization cinema;

alter user cinema set search_path = sc_cinema,public;