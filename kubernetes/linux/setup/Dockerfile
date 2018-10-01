FROM ubuntu:16.04

RUN apt-get update -y && apt-get upgrade -y \
	&& apt-get install net-tools gettext locales -y \
	&& locale-gen en_US.UTF-8 de_DE.UTF-8

# Set the locale
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8  

COPY ["scripts/*.sh", "resources/*.xml", "resources/*.cfg", "resources/*.jar", "/tmp/"]
COPY resources/configuration.properties  /root

WORKDIR /tmp/ix-setup

CMD ["/bin/true"]
