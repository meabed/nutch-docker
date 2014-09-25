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
# RUN sed -i '/^  <name>http.agent.name<\/name>$/{$!{N;s/^  <name>http.agent.name<\/name>\n  <value><\/value>$/  <name>http.agent.name<\/name>\n  <value>iData Bot<\/value>/;ty;P;D;:y}}' $NUTCH_ROOT/conf/nutch-default.xml

RUN vim -c 'g/name="gora-cassandra"/+1d' -c 'x' $NUTCH_ROOT/ivy/ivy.xml
RUN vim -c 'g/name="gora-cassandra"/-1d' -c 'x' $NUTCH_ROOT/ivy/ivy.xml

RUN vim -c '%s/name="elasticsearch" rev=.*/name="elasticsearch" rev="1.3.2"/g' -c 'x' $NUTCH_ROOT/ivy/ivy.xml
RUN vim -c '%s/item.failed()/item.isFailed()/g' -c 'x' $NUTCH_ROOT/src/java/org/apache/nutch/indexer/elastic/ElasticWriter.java

RUN cd $NUTCH_ROOT && ant runtime

RUN ln -s /opt/apache-nutch-$NUTCH_VERSION/runtime/local /opt/nutch

ENV NUTCH_HOME /opt/nutch

#native libs
RUN rm  $NUTCH_HOME/lib/native/*
RUN curl -Ls http://dl.bintray.com/meabed/hadoop-debian/hadoop-native-64-2.5.1.tar|tar -x -C $NUTCH_HOME/lib/native/




RUN rm $NUTCH_HOME/conf/nutch-site.xml

COPY config/nutch-site.xml $NUTCH_HOME/conf/nutch-site.xml

RUN sed  -i '/^SOLRURL=".*/ s/.*/#&\nESNODE="$3"/' $NUTCH_HOME/bin/crawl

RUN sed  -i '/^if \[ "$SOLRURL".*/ s/.*/if \[ "$ESNODE" = "" \]; then\n    echo "Missing Elasticsearch Node Name : crawl <seedDir> <crawlID> <esNODE> <numberOfRounds>"\n    exit -1;\nfi\n\n\n&/' $NUTCH_HOME/bin/crawl
RUN sed  -i '/on SOLR index .*/ s/.*/  echo "Indexing $CRAWL_ID on Elasticsearch Node -> $ESNODE"\n  $bin\/nutch elasticindex $commonOptions $ESNODE -all -crawlId $CRAWL_ID\n\n\n&/' $NUTCH_HOME/bin/crawl

RUN vim -c 'g/SOLR dedup/-1,+5d' -c 'x' $NUTCH_HOME/bin/crawl
RUN vim -c 'g/"$SOLRURL" =/-1,+4d' -c 'x' $NUTCH_HOME/bin/crawl

RUN vim -c 'g/on SOLR index /-1,+2d' -c 'x' $NUTCH_HOME/bin/crawl
RUN vim -c '%s/<solrURL>/<esNODE>/' -c 'x' $NUTCH_HOME/bin/crawl


RUN mkdir $NUTCH_HOME/urls

#RUN cd $NUTCH_HOME && ls -al

#RUN mkdir -p /opt/nutch/urls && cd /opt/crawl

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

VOLUME ["/data"]

CMD ["/etc/bootstrap.sh", "-d"]




