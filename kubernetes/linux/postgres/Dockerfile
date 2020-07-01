FROM postgres:12

ENV POSTGRES_DB=ixcloud
ENV POSTGRES_PASSWORD=mysecretpassword

ADD ixcloudapp.sql /docker-entrypoint-initdb.d
