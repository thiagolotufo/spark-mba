FROM eclipse-temurin:8-jdk-focal
RUN apt-get update -y \
    && export DEBIAN_FRONTEND=noninteractive && apt-get install -y --no-install-recommends \
        sudo \
        curl \
        ssh \
    && apt-get clean
RUN useradd -m hduser && echo "hduser:supergroup" | chpasswd && adduser hduser sudo && echo "hduser     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && cd /usr/bin/ && sudo ln -s python3 python
COPY config/hadoop/ssh_config /etc/ssh/ssh_config

WORKDIR /home/hduser
USER hduser
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys

ENV HADOOP_VERSION=3.2.4
ENV HADOOP_HOME /home/hduser/hadoop-${HADOOP_VERSION}
ENV HADOOP_URL=https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

RUN curl -fsSL ${HADOOP_URL} -o /home/hduser/hadoop-${HADOOP_VERSION}.tar.gz

RUN tar -xzf /home/hduser/hadoop-${HADOOP_VERSION}.tar.gz -C /home/hduser/ \
 && rm -rf /home/hduser/hadoop-${HADOOP_VERSION}/share/doc \
 && mkdir -p /home/hduser/hadoop-${HADOOP_VERSION} \
 && chown -R hduser:hduser /home/hduser/hadoop-${HADOOP_VERSION} \
 && rm /home/hduser/hadoop-${HADOOP_VERSION}.tar.gz

ENV HDFS_NAMENODE_USER hduser
ENV HDFS_DATANODE_USER hduser
ENV HDFS_SECONDARYNAMENODE_USER hduser

ENV YARN_RESOURCEMANAGER_USER hduser
ENV YARN_NODEMANAGER_USER hduser

RUN echo "export JAVA_HOME=/opt/java/openjdk/" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY config/hadoop/core-site.xml $HADOOP_HOME/etc/hadoop/
COPY config/hadoop/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
COPY config/hadoop/yarn-site.xml $HADOOP_HOME/etc/hadoop/

COPY config/hadoop/docker-entrypoint.sh $HADOOP_HOME/etc/hadoop/

ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

EXPOSE 50070 50075 50010 50020 50090 8020 9000 9864 9870 10020 19888 8088 8030 8031 8032 8033 8040 8042 22

WORKDIR /usr/local/bin
RUN sudo ln -s ${HADOOP_HOME}/etc/hadoop/docker-entrypoint.sh .
WORKDIR /home/hduser

ENV YARNSTART 0

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

