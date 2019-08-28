#FROM gsai directive is probably the most crucial amongst all others for Dockerfiles. It defines the base image to use to start the build process. It can be any image, including the ones you have created previously.
FROM inmbzp5170.in.dst.ibm.com:5000/ubuntu:69

#One of the commands that can be set anywhere in the file - although it would be better if it was declared on top - is MAINTAINER. This non-executing command declares the author, hence setting the author field of the images. It should come nonetheless after FROM.
##MAINTAINER Ghanshyam<gsaini05@in.ibm.com>

USER root

# Setup useful environment variables
ENV BITBUCKET_HOME     /var/atlassian/bitbucket
ENV BITBUCKET_INSTALL  /opt/atlassian/bitbucket
ENV BITBUCKET_VERSION  4.14.4

# Install Atlassian Bitbucket and helper tools and setup initial home
# directory structure.

# RUN executes command(s) in a new layer and creates a new image. E.g., it is often used for installing software packages.
#RUN set -x \
    && sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
    && apt-get update --quiet \
    && apt-get install --quiet --yes --no-install-recommends git-core xmlstarlet curl \
    #&& apt-get install --quiet --yes --no-install-recommends -t jessie-backports libtcnative-1 \
    && apt-get clean \
    && mkdir -p               "${BITBUCKET_HOME}/lib" \
    && chmod -R 700           "${BITBUCKET_HOME}" \
    && chown -R daemon:daemon "${BITBUCKET_HOME}" \
    && mkdir -p               "${BITBUCKET_INSTALL}" \
    && curl -Ls               "https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz" | tar -zx --directory  "${BITBUCKET_INSTALL}" --strip-components=1 --no-same-owner \
    && curl -Ls                "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz" | tar -xz --directory "${BITBUCKET_INSTALL}/lib" --strip-components=1 --no-same-owner "mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar" \
    && chmod -R 700           "${BITBUCKET_INSTALL}/conf" \
    && chmod -R 700           "${BITBUCKET_INSTALL}/logs" \
    && chmod -R 700           "${BITBUCKET_INSTALL}/temp" \
    && chmod -R 700           "${BITBUCKET_INSTALL}/work" \
    && chown -R daemon:daemon "${BITBUCKET_INSTALL}/conf" \
    && chown -R daemon:daemon "${BITBUCKET_INSTALL}/logs" \
    && chown -R daemon:daemon "${BITBUCKET_INSTALL}/temp" \
    && chown -R daemon:daemon "${BITBUCKET_INSTALL}/work" \
    && ln --symbolic          "/usr/lib/x86_64-linux-gnu/libtcnative-1.so" "${BITBUCKET_INSTALL}/lib/native/libtcnative-1.so" \
    && sed --in-place         's/^# umask 0027$/umask 0027/g' "${BITBUCKET_INSTALL}/bin/setenv.sh" \
    && xmlstarlet             ed --inplace \
        --delete              "Server/Service/Engine/Host/@xmlValidation" \
        --delete              "Server/Service/Engine/Host/@xmlNamespaceAware" \
                              "${BITBUCKET_INSTALL}/conf/server.xml" \
    && touch -d "@0"          "${BITBUCKET_INSTALL}/conf/server.xml"

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.

RUN useradd -d ${BITBUCKET_HOME} -u 1000 -m -s /bin/bash bitbucket
##ADD filebeat-6.2.1-linux-x86_64 /filebeat-6.2.1-linux-x86_64
##ADD node_exporter-0.15.2.linux-amd64 /opt/node_exporter-0.15.2.linux-amd64
RUN mv /opt/node_exporter-0.15.2.linux-amd64 /opt/node_exporter/
##ADD node_exporter.sh /opt/node_exporter/node_exporter.sh
##ADD node_exporter /etc/init.d/node_exporter

# Expose default HTTP and SSH ports.
#connector port 7990 is commented out in server.xml.So,it's not present in the output.
#7999 is the port for git ssh connections
EXPOSE 7990 7999 5044 9100
RUN chmod +x /opt/atlassian/bitbucket
RUN chmod +x /var/atlassian/bitbucket
RUN chmod +x /opt/atlassian
RUN chmod +x /var/atlassian
RUN chown -R bitbucket:bitbucket /opt/atlassian/bitbucket && \
    chown -R bitbucket:bitbucket /var/atlassian/bitbucket && \
    chown -R bitbucket:bitbucket /opt/atlassian && \
    chown -R bitbucket:bitbucket /var/atlassian
RUN chown -R bitbucket:bitbucket /opt/node*
RUN chmod -R 755 /opt/node*
RUN chown -R bitbucket:bitbucket /filebeat-6.2.1-linux-x86_64
RUN chmod -R 755  /filebeat-6.2.1-linux-x86_64
# Set the default working directory as the Bitbucket home directory.
WORKDIR /var/atlassian/bitbucket

#ADD <src> <dest>
#The ADD instruction will copy new files from <src> and add them to the container's filesystem at path <dest>.
##ADD /docker-entrypoint.sh /var/atlassian/bitbucket

RUN chmod +x /var/atlassian/bitbucket/docker-entrypoint.sh
RUN chown -R bitbucket:bitbucket /var/atlassian/bitbucket/docker-entrypoint.sh
USER bitbucket

#ENTRYPOINT configures a container that will run as an executable.
ENTRYPOINT ["/var/atlassian/bitbucket/docker-entrypoint.sh"]

# Run Atlassian Bitbucket as a foreground process by default.
# CMD sets default command and/or parameters, which can be overwritten from command line when docker container runs
CMD ["/opt/atlassian/bitbucket/bin/catalina.sh", "run"]




