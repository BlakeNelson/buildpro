FROM centos:7
LABEL maintainer="smanders"
LABEL org.opencontainers.image.source https://github.com/smanders/buildpro
SHELL ["/bin/bash", "-c"]
USER 0
# yum repositories
RUN yum -y update \
  && yum clean all \
  && yum -y install --setopt=tsflags=nodocs \
     gtk2.x86_64 \
     iproute \
     libSM.x86_64 \
     mesa-libGLU.x86_64 \
     make \
     sudo \
     unixODBC \
     wget \
  && yum clean all
# cmake
RUN export CMK_VER=3.17.5 \
  && export CMK_DL=releases/download/v${CMK_VER}/cmake-${CMK_VER}-Linux-x86_64.tar.gz \
  && wget -qO- "https://github.com/Kitware/CMake/${CMK_DL}" \
  | tar --strip-components=1 -xz -C /usr/local/ \
  && unset CMK_DL && unset CMK_VER
# prompt
COPY git-prompt.sh /etc/profile.d/
# install database connect from yum repo
#  https://dev.mysql.com/doc/refman/8.0/en/linux-installation-yum-repo.html
RUN yum -y update \
  && yum clean all \
  && yum -y install --setopt=tsflags=nodocs \
     https://repo.mysql.com//mysql80-community-release-el7-3.noarch.rpm \
  && yum -y install --enablerepo=mysql80-community --setopt=tsflags=nodocs \
     mysql-connector-odbc \
  && yum clean all \
  && mkdir -p /mnt/mock_midb /mnt/midb /mnt/Plugins \
  && chmod 777 /mnt/mock_midb /mnt/midb /mnt/Plugins
CMD ["/bin/bash"]
