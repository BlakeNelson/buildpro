ARG BPROTAG
FROM ghcr.io/smanders/buildpro/centos7-pro:${BPROTAG}
LABEL maintainer="bnelson619"
LABEL org.opencontainers.image.source https://github.com/bnelson619/buildpro
SHELL ["/bin/bash", "-c"]
USER 0
# yum repositories
RUN yum -y update \
  && yum clean all \
  && yum -y install --setopt=tsflags=nodocs \
     cppcheck \
     ghostscript `#LaTeX` \
     gperftools \
     graphviz \
     iproute \
     libSM-devel \
     rpm-build \
     unixODBC-devel \
     xeyes \
     Xvfb \
     yum-utils `#yum-config-manager` \
  && yum clean all
# lcov (and LaTeX?) deps
RUN yum -y update \
  && yum clean all \
  && yum -y install --setopt=tsflags=nodocs \
     perl-Digest-MD5 \
     perl-IO-Compress \
     perl-JSON-XS \
     perl-Module-Load-Conditional \
  && yum clean all
# lcov
RUN export LCOV_VER=1.16 \
  && wget -qO- "https://github.com/linux-test-project/lcov/releases/download/v${LCOV_VER}/lcov-${LCOV_VER}.tar.gz" \
  | tar -xz -C /usr/local/src \
  && (cd /usr/local/src/lcov-${LCOV_VER} && make install > /dev/null) \
  && rm -rf /usr/local/src/lcov-${LCOV_VER} \
  && unset LCOV_VER
# git-lfs
RUN export LFS_VER=2.12.1 \
  && mkdir /usr/local/src/lfs \
  && wget -qO- "https://github.com/git-lfs/git-lfs/releases/download/v${LFS_VER}/git-lfs-linux-amd64-v${LFS_VER}.tar.gz" \
  | tar -xz -C /usr/local/src/lfs \
  && /usr/local/src/lfs/install.sh \
  && rm -rf /usr/local/src/lfs/ \
  && unset LFS_VER \
  && git lfs install --system
# doxygen
RUN export DXY_VER=1.8.13 \
  && wget -qO- --no-check-certificate \
  "https://downloads.sourceforge.net/project/doxygen/rel-${DXY_VER}/doxygen-${DXY_VER}.linux.bin.tar.gz" \
  | tar -xz -C /usr/local/ \
  && mv /usr/local/doxygen-${DXY_VER}/bin/doxygen /usr/local/bin/ \
  && rm -rf /usr/local/doxygen-${DXY_VER}/ \
  && unset DXY_VER
# LaTeX
# NOTE: multiple layers, small subset of collection-latexextra to reduce layer sizes
COPY texlive.profile /usr/local/src/
RUN export TEX_VER=2017 \
  && wget -qO- "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${TEX_VER}/tlnet-final/install-tl-unx.tar.gz" \
  | tar -xz -C /usr/local/src/ \
  && /usr/local/src/install-tl-20180303/install-tl -profile /usr/local/src/texlive.profile \
     -repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${TEX_VER}/tlnet-final/archive/ \
  && rm -rf /usr/local/src/install-tl-20180303 /usr/local/src/texlive.profile \
  && unset TEX_VER
RUN  tlmgr install collection-fontsrecommended \
  && tlmgr install collection-latexrecommended \
  && tlmgr install tabu varwidth multirow wrapfig adjustbox collectbox sectsty tocloft `#collection-latexextra` \
  && tlmgr install epstopdf
ENV PATH=$PATH:/usr/local/texlive/2017/bin/x86_64-linux
# CUDA https://developer.nvidia.com/cuda-11-7-1-download-archive
# NOTE: only subset of cuda-libraries-devel to reduce layer sizes
RUN export CUDA_VER=11-7 \
  && export CUDA_DL=https://developer.download.nvidia.com/compute/cuda/repos/rhel7/$(uname -m) \
  && yum-config-manager --add-repo ${CUDA_DL}/cuda-rhel7.repo \
  && yum clean all \
  && wget -O /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA ${CUDA_DL}/D42D0685.pub \
  && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA \
  && yum -y install \
     cuda-compiler-${CUDA_VER} \
     cuda-cudart-devel-${CUDA_VER} \
  `# cuda-libraries-devel` \
     libcublas-devel-${CUDA_VER} \
     libcufft-devel-${CUDA_VER} \
     libcusolver-devel-${CUDA_VER} \
     libcusparse-devel-${CUDA_VER} \
  && yum clean all \
  && unset CUDA_DL && unset CUDA_VER
ENV PATH=$PATH:/usr/local/cuda/bin
# docker
# to see list of available docker versions in the repository:
#  sudo yum list docker-ce --showduplicates | sort -r
# install a specific version so version doesn't randomly change to latest when image is built
RUN export DOCK_VER=24.0.5-1.el7 \
  && yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo \
  && yum clean all \
  && yum -y install \
     docker-ce-${DOCK_VER} \
     docker-ce-cli-${DOCK_VER} \
     containerd.io \
     docker-buildx-plugin \
     docker-compose-plugin \
  && yum clean all \
  && if [ $(getent group docker) ]; then groupdel docker; fi \
  && unset DOCK_VER
# dotnet
RUN rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm \
  && yum -y update \
  && yum clean all \
  && yum -y install --setopt=tsflags=nodocs \
     dotnet-sdk-3.1 \
  && yum clean all
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true
# minimum chrome
RUN export CHR_VER=108.0.5359.98 \
  && export CHR_DL=linux/chrome/rpm/stable/$(uname -m)/google-chrome-stable-${CHR_VER}-1.$(uname -m).rpm \
  && echo "repo_add_once=false" > /etc/default/google-chrome \
  && yum -y update \
  && yum clean all \
  && yum -y install --setopt=tsflags=nodocs \
     https://dl.google.com/${CHR_DL} \
  && yum clean all \
  && unset CHR_DL && unset CHR_VER
# minimum firefox
RUN export FOX_VER=102.6.0esr \
  && export FOX_DL=pub/firefox/releases/${FOX_VER}/linux-$(uname -m)/en-US/firefox-${FOX_VER}.tar.bz2 \
  && wget -qO- "https://ftp.mozilla.org/${FOX_DL}" | tar -xj -C /opt/ \
  && ln -s /opt/firefox/firefox /usr/local/bin/firefox \
  && unset FOX_DL && unset FOX_VER
# externpro
ENV XP_VER=23.03
ENV EXTERNPRO_PATH=${EXTERN_DIR}/externpro-${XP_VER}-${GCC_VER}-64-Linux
RUN mkdir -p ${EXTERN_DIR} \
  && export XP_DL=releases/download/${XP_VER}/externpro-${XP_VER}-${GCC_VER}-64-$(uname -s).tar.xz \
  && wget -qO- "https://github.com/smanders/externpro/${XP_DL}" | tar -xJ -C ${EXTERN_DIR} \
  && unset XP_DL
# Latest Python 
RUN wget -qO- https://ftp.openssl.org/source/openssl-1.1.1k.tar.gz | tar -xz -C /tmp/ \ 
    && cd /tmp/openssl-1.1.1k \ 
    && ./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib no-shared zlib-dynamic \
    && make -j16 \
    && make install \
    && cd \
    && rm -rf /tmp/openssl-1.1.1k 
RUN yum -y install libffi-devel \
    && yum -y install sqlite-devel \
    && wget -qO- https://www.python.org/ftp/python/3.11.0/Python-3.11.0.tgz | tar -xz -C /tmp \
    && cd /tmp/Python-3.11.0 \
    && ./configure --enable-optimizations \
    && make -j12 \
    && make install \
    && cd \
    && rm -rf /tmp/Python-3.11.0 \
    && pip3 install --upgrade pip
# Tensorflow binaries
RUN mkdir -p /opt/extern/tf \ 
    && wget -qO- https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-gpu-linux-x86_64-2.14.0.tar.gz | tar -xz -C /opt/extern/tf \
    && mkdir -p /opt/extern/cudnn \
    && wget -qO- https://isrhub.usurf.usu.edu/bnelson/MLBinaries/raw/master/cudnn-linux-x86_64-8.9.5.29_cuda11-archive.tar.xz | tar -xJ -C /opt/extern/cudnn \ 
    && cp /opt/extern/cudnn/cudnn-linux-x86_64-8.9.5.29_cuda11-archive/include/cudnn*.h /usr/local/cuda/include \ 
    && cp -P /opt/extern/cudnn/cudnn-linux-x86_64-8.9.5.29_cuda11-archive/lib/libcudnn* /usr/local/cuda/lib64 \ 
    && chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn* \
    && wget -P /usr/local/cuda/lib64 https://isrhub.usurf.usu.edu/bnelson/MLBinaries/raw/master/libcurand.so.10.2.10.50 \
    && wget -P /usr/local/cuda/lib64 https://isrhub.usurf.usu.edu/bnelson/MLBinaries/raw/master/libcurand.so \
    && wget -P /usr/local/cuda/lib64 https://isrhub.usurf.usu.edu/bnelson/MLBinaries/raw/master/libcurand.so.10 \
    && wget -P /usr/local/cuda/lib64 https://isrhub.usurf.usu.edu/bnelson/MLBinaries/raw/master/libcurand.so.10.2.10.50 \
    && wget -P /usr/local/cuda/lib64 https://isrhub.usurf.usu.edu/bnelson/MLBinaries/raw/master/libcurand_static.a 
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
# Tensorflow python
RUN yum -y install rh-python36-python-tkinter.x86_64 \
    && pip3 install tensorflow tensorflow-datasets \
    && pip3 install matplotlib \
    && pip3 install visualkeras \
    && pip3 install pydot \
    && pip3 install scipy \
    && pip3 install ipympl \
    && pip3 install jupyter \
    && pip3 install jupyterlab \
    && pip3 install ipyflow \
    && pip3 install ipykernel \
    && pip3 install dvc 
COPY scripts/ /usr/local/bpbin
COPY git-prompt.sh /etc/profile.d/
# && sudo pip install tensorflow[and-cuda] tensorflow-datasets matplotlib visualkeras pydot"
#TENSORFLOWPIP1="sudo pip install scipy ipympl jupyter jupyterlab papermill ipyflow ipykernel && sudo pip install dvc"
# externpro
ENTRYPOINT ["/bin/bash", "/usr/local/bpbin/entry.sh"]
