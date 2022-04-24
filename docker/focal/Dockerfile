## Emacs, make this -*- mode: sh; -*-

FROM rocker/r-ubuntu:20.04

LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/eddelbuettel/r2u" \
      maintainer="Dirk Eddelbuettel <edd@debian.org>"

## This was not needed before but we need it now
ENV DEBIAN_FRONTEND noninteractive

# RUN add-apt-repository --yes "ppa:edd/r-4.0" \
# 	&& apt-get install -y --no-install-recommends \
#                 sudo \
#                 r-cran-bspm \
#         && echo "bspm::enable()" >> /etc/R/Rprofile.site \
#         && echo "options(bspm.sudo=TRUE)" >> /etc/R/Rprofile.site \
#         && echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/90local-no-recommends \
#         && echo "docker ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/local-docker-user \
#         && chmod 0440 /etc/sudoers.d/local-docker-user \
#         && chgrp 1000 /usr/local/lib/R/site-library \
#         && install.r remotes


RUN apt update -qq \
    && apt upgrade --yes \
    && apt install --yes --no-install-recommends dh-r gpg-agent \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A 67C2D66C4B1D4339

## Add our repo for R 4.2.0
COPY edd-misc.list /etc/apt/sources.list.d

RUN apt update -qq && apt upgrade --yes

COPY debBuild.sh /usr/local/bin
COPY cranapt.list /etc/apt/sources.list.d

CMD ["bash"]
