## Emacs, make this -*- mode: sh; -*-

## NB: one may need to add '--security-opt seccomp=unconfined' to the docker invocation

FROM rocker/r-bspm:20.04

LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/eddelbuettel/r2u" \
      maintainer="Dirk Eddelbuettel <edd@debian.org>"

## This was not needed before but we need it now
ENV DEBIAN_FRONTEND noninteractive

RUN rm -f /etc/apt/sources.list.save /etc/apt/sources.list.d/{c2d4u*,edd*,*.save} \
    && apt update -qq \
    && apt upgrade --yes \
    && apt install --yes --no-install-recommends gpg-agent \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A

COPY cranapt.list /etc/apt/sources.list.d
COPY 99cranapt /etc/apt/preferences.d

#    && Rscript -e 'bspm::disable(); install.packages("littler", type="source")' \

## update, but ignore the littler binary which is (currently at least) bad
RUN apt update -qq \
    && apt upgrade --yes \
    && dpkg --purge r-cran-littler littler \
    && Rscript -e 'bspm::disable(); remotes::install_github("eddelbuettel/littler")' \
    && cd /usr/local/bin \
    && ln -s /usr/local/lib/R/site-library/littler/bin/r . \
    && ln -sf /usr/local/lib/R/site-library/littler/examples/install.r . \
    && ln -sf /usr/local/lib/R/site-library/littler/examples/install2.r . \
    && ln -sf /usr/local/lib/R/site-library/littler/examples/installGithub.r . \
    && ln -sf /usr/local/lib/R/site-library/littler/examples/installRub.r . \
    && ln -sf /usr/local/lib/R/site-library/littler/examples/update.r .

CMD ["bash"]
