#
# Nutch
# meabed/debian-jdk
# docker build -t meabed/nutch:latest .
#

FROM meabed/debian-jdk
MAINTAINER Mohamed Meabed "mo.meabed@gmail.com"

USER root
ENV DEBIAN_FRONTEND noninteractive

ENV NUTCH_VERSION 2.2.1

#ant
RUN apt-get install -y ant

#Download nutch

RUN mkdir -p /opt/downloads && cd /opt/downloads && curl -SsfLO "http://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/nutch/2.2.1/apache-nutch-$NUTCH_VERSION-src.tar.gz"
RUN cd /opt && tar xvfz /opt/downloads/apache-nutch-$NUTCH_VERSION-src.tar.gz
#WORKDIR /opt/apache-nutch-$NUTCH_VERSION
ENV NUTCH_ROOT /opt/apache-nutch-$NUTCH_VERSION
ENV HOME /root

#Nutch-default
RUN sed -i '/^  <name>http.agent.name<\/name>$/{$!{N;s/^  <name>http.agent.name<\/name>\n  <value><\/value>$/  <name>http.agent.name<\/name>\n  <value>Data Bot<\/value>/;ty;P;D;:y}}' $NUTCH_ROOT/conf/nutch-default.xml

RUN sed -i '/^  <name>http.robots.agents<\/name>$/{$!{N;s/^  <name>http.robots.agents<\/name>\n  <value><\/value>$/  <name>http.robots.agents<\/name>\n  <value>Data Bot<\/value>/;ty;P;D;:y}}' $NUTCH_ROOT/conf/nutch-default.xml

RUN sed -i '/^  <name>http.agent.description<\/name>$/{$!{N;s/^  <name>http.agent.description<\/name>\n  <value><\/value>$/  <name>http.agent.description<\/name>\n  <value>Data Bot<\/value>/;ty;P;D;:y}}' $NUTCH_ROOT/conf/nutch-default.xml

RUN sed -i '/^  <name>http.agent.url<\/name>$/{$!{N;s/^  <name>http.agent.url<\/name>\n  <value><\/value>$/  <name>http.agent.url<\/name>\n  <value>http:\/\/www.google.com<\/value>/;ty;P;D;:y}}' $NUTCH_ROOT/conf/nutch-default.xml

RUN sed -i '/^  <name>http.agent.email<\/name>$/{$!{N;s/^  <name>http.agent.email<\/name>\n  <value><\/value>$/  <name>http.agent.email<\/name>\n  <value>mo.meabed@gmail.com<\/value>/;ty;P;D;:y}}' $NUTCH_ROOT/conf/nutch-default.xml

RUN sed -i '/^  <name>storage.data.store.class<\/name>$/{$!{N;s/^  <name>storage.data.store.class<\/name>\n  <value>org.apache.gora.memory.store.MemStore<\/value>$/  <name>storage.data.store.class<\/name>\n  <value>org.apache.gora.cassandra.store.CassandraStore<\/value>/;ty;P;D;:y}}' $NUTCH_ROOT/conf/nutch-default.xml

RUN vim -c 'g/name="gora-cassandra"/+1d' -c 'x' $NUTCH_ROOT/ivy/ivy.xml
RUN vim -c 'g/name="gora-cassandra"/-1d' -c 'x' $NUTCH_ROOT/ivy/ivy.xml


RUN cassandra_env="$CASSANDRA_NODE_NAME"_PORT_9160_TCP_ADDR
RUN cassandra_ip=$(printenv $cassandra_env)
RUN echo "gora.datastore.default=org.apache.gora.cassandra.store.CassandraStore" >> $NUTCH_ROOT/conf/gora.properties
RUN echo "gora.cassandrastore.servers=$cassandra_ip:9160" >> $NUTCH_ROOT/conf/gora.properties


RUN cd $NUTCH_ROOT && ant runtime

RUN ln -s /opt/apache-nutch-$NUTCH_VERSION/runtime/local /opt/nutch

ENV NUTCH_HOME /opt/nutch

#RUN cd $NUTCH_HOME && ls -al

#RUN mkdir -p /opt/nutch/urls && cd /opt/crawl

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

VOLUME ["/data"]

CMD ["/etc/bootstrap.sh", "-d"]




