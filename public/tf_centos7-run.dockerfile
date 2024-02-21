FROM ghcr.io/smanders/centos:7
LABEL maintainer="bnelson619"
LABEL org.opencontainers.image.source https://github.com/bnelson619/buildpro
SHELL ["/bin/bash", "-c"]
USER 0
VOLUME /bpvol
# yum repositories
RUN yum -y update \
  && yum clean all \
  && yum -y install --setopt=tsflags=nodocs \
     bzip2 `#firefox` \
     ffmpeg `#browser-video` \
     gtk2 `#old-wx` \
     gtk3 `#firefox,wx` \
     iproute \
     libSM \
     libXt `#firefox` \
     mesa-libGLU \
     make \
     sudo \
     wget \
     which \
     xeyes \
     Xvfb \
  && yum clean all
# cmake
RUN export CMK_VER=3.24.2 \
  && export CMK_DL=releases/download/v${CMK_VER}/cmake-${CMK_VER}-$(uname -s)-$(uname -m).tar.gz \
  && wget -qO- "https://github.com/Kitware/CMake/${CMK_DL}" \
  | tar --strip-components=1 -xz -C /usr/local/ \
  && unset CMK_DL && unset CMK_VER
# chrome
RUN export CHR_VER=108.0.5359.98 \
  && export CHR_DL=linux/chrome/rpm/stable/$(uname -m)/google-chrome-stable-${CHR_VER}-1.$(uname -m).rpm \
  && echo "repo_add_once=false" > /etc/default/google-chrome \
  && yum -y update \
  && yum clean all \
  && yum -y install --setopt=tsflags=nodocs \
     https://dl.google.com/${CHR_DL} \
  && yum clean all \
  && unset CHR_DL && unset CHR_VER
# firefox
RUN export FOX_VER=102.6.0esr \
  && export FOX_DL=pub/firefox/releases/${FOX_VER}/linux-$(uname -m)/en-US/firefox-${FOX_VER}.tar.bz2 \
  && wget -qO- "https://ftp.mozilla.org/${FOX_DL}" | tar -xj -C /opt/ \
  && ln -s /opt/firefox/firefox /usr/local/bin/firefox \
  && unset FOX_DL && unset FOX_VER
# copy from local into image
COPY scripts/ /usr/local/bpbin
COPY git-prompt.sh /etc/profile.d/
ENTRYPOINT ["/bin/bash", "/usr/local/bpbin/entry.sh"]
