FROM ghcr.io/smanders/buildpro/centos7-run:latest
LABEL maintainer="smanders"
LABEL org.opencontainers.image.source https://github.com/smanders/buildpro
SHELL ["/bin/bash", "-c"]
USER 0
VOLUME /scripts
VOLUME /srcdir
# create non-root user, add to sudoers
ARG USERNAME
ARG USERID
RUN adduser --uid ${USERID} ${USERNAME} \
  && echo "" >> /etc/sudoers \
  && echo "## dockerfile adds ${USERNAME} to sudoers" >> /etc/sudoers \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
ENV USER=${USERNAME}
# run container as non-root user from here onwards
# so that build output files have the correct owner
USER ${USERNAME}
# install data source name (DSN)
#  odbcinst: [Action]i:install [Object]s:data_source [Options]h:user_dsn,f:template_file
#  odbcinst creates ~/.odbc.ini
COPY odbc.ini.test /home/${USERNAME}/
RUN odbcinst -i -s -h -f /home/${USERNAME}/odbc.ini.test \
  && rm /home/${USERNAME}/odbc.ini.test
# run bash script and process the input command
ENTRYPOINT ["/bin/bash", "/scripts/entry.sh"]
