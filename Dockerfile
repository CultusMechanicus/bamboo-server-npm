FROM adoptopenjdk:8-jdk-hotspot-bionic
LABEL maintainer="Not the Atlassian Bamboo Team" \
      description="Unofficial Bamboo Server Docker Image with NPM installed"

ENV BAMBOO_USER bamboo
ENV BAMBOO_GROUP bamboo

ENV BAMBOO_USER_HOME /home/${BAMBOO_USER}
ENV BAMBOO_HOME /var/atlassian/application-data/bamboo
ENV BAMBOO_INSTALL_DIR /opt/atlassian/bamboo

# Expose HTTP and AGENT JMS ports
ENV BAMBOO_JMS_CONNECTION_PORT=54663
EXPOSE 8085
EXPOSE $BAMBOO_JMS_CONNECTION_PORT

RUN set -x && \
     addgroup ${BAMBOO_GROUP} && \
     adduser ${BAMBOO_USER} --home ${BAMBOO_USER_HOME} --ingroup ${BAMBOO_GROUP} --disabled-password

RUN set -x && \
     curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
     apt-get update && \
     apt-get install -y --no-install-recommends \
          curl \
          git \
          bash \
          procps \
          openssl \
          openssh-client \
          libtcnative-1 \
          maven \
          nodejs \
          ruby-sass\
     && \
# create symlink to maven to automate capability detection
     ln -s /usr/share/maven /usr/share/maven3 && \
# create symlink for java home backward compatibility
     mkdir -m 755 -p /usr/lib/jvm && \
     ln -s "${JAVA_HOME}" /usr/lib/jvm/java-8-openjdk-amd64 && \
     rm -rf /var/lib/apt/lists/*

ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ARG BAMBOO_VERSION=7.1.1
ARG DOWNLOAD_URL=https://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz

RUN set -x && \
     mkdir -p ${BAMBOO_INSTALL_DIR}/lib/native && \
     mkdir -p ${BAMBOO_HOME} && \
     ln --symbolic "/usr/lib/x86_64-linux-gnu/libtcnative-1.so" "${BAMBOO_INSTALL_DIR}/lib/native/libtcnative-1.so" && \
     curl --silent -L ${DOWNLOAD_URL} | tar -xz --strip-components=1 -C "$BAMBOO_INSTALL_DIR" && \
     echo "bamboo.home=${BAMBOO_HOME}" > $BAMBOO_INSTALL_DIR/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties && \
     chown -R "${BAMBOO_USER}:${BAMBOO_GROUP}" "${BAMBOO_INSTALL_DIR}" && \
     chown -R "${BAMBOO_USER}:${BAMBOO_GROUP}" "${BAMBOO_HOME}"

ADD https://github.com/SalesforceCommerceCloud/sfcc-ci/releases/download/v2.6.0/sfcc-ci-linux /usr/bin/sfcc-ci
RUN chmod +x /usr/bin/sfcc-ci

VOLUME ["${BAMBOO_HOME}"]
WORKDIR $BAMBOO_HOME

USER ${BAMBOO_USER}
COPY  --chown=bamboo:bamboo entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/tini", "--"]
CMD ["/entrypoint.sh"]
