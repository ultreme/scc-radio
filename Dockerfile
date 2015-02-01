FROM moul/liquidsoap
MAINTAINER Manfred Touron "m@42.am"

USER root
RUN apt-get -qq -y install python-setuptools && \
    apt-get clean
RUN easy_install supervisor && \
    easy_install supervisor-stdout

RUN mkdir -p /playlists/failures
VOLUME ["/playlists", "/config"]
EXPOSE 5000 5001 5002 5003 5004 5005

ENTRYPOINT ["/start.sh"]
ADD supervisord.conf /etc/supervisord.conf
ADD start.sh /start.sh
ADD config /config
