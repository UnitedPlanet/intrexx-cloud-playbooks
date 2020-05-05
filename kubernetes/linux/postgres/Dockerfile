FROM postgres:11

ENV POSTGRES_DB=ixcloud
ENV POSTGRES_PASSWORD=mysecretpassword

ADD ixcloudapp.sql /docker-entrypoint-initdb.d
