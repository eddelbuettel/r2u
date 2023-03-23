## Emacs, make this -*- mode: sh; -*-

FROM rocker/r-ubuntu:20.04

LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/eddelbuettel/r2u" \
      maintainer="Dirk Eddelbuettel <edd@debian.org>"

## This was not needed before but we need it now
ENV DEBIAN_FRONTEND noninteractive

RUN apt update -qq \
    && apt upgrade --yes \
    && apt install --yes --no-install-recommends dh-r gpg-agent xvfb \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A 67C2D66C4B1D4339

## Add our repo for R 4.2.0 -- no longer needed
# COPY edd-misc.list /etc/apt/sources.list.d
# RUN apt update -qq && apt upgrade --yes

COPY debBuild.sh /usr/local/bin
COPY cranapt.list /etc/apt/sources.list.d
COPY 99cranapt /etc/apt/preferences.d

CMD ["bash"]
