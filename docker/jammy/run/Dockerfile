## Emacs, make this -*- mode: sh; -*-

FROM rocker/r-bspm:22.04

LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/eddelbuettel/r2u" \
      maintainer="Dirk Eddelbuettel <edd@debian.org>"

## This was not needed before but we need it now
ENV DEBIAN_FRONTEND noninteractive

RUN rm -f /etc/apt/sources.list.save /etc/apt/sources.list.d/{c2d4u*,edd*,*.save} \
    && apt update -qq \
    && apt upgrade --yes

# && apt install --yes --no-install-recommends gpg-agent \
# && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1489FE2AB99A21A

COPY cranapt.list /etc/apt/sources.list.d
COPY 99cranapt /etc/apt/preferences.d
COPY dirk_eddelbuettel_key.asc /etc/apt/trusted.gpg.d/

#    && apt upgrade --yes \
#    && dpkg --purge r-cran-littler littler \

## update, but ignore the littler binary which is (currently at least) bad
RUN apt update -qq \
    && Rscript -e 'bspm::disable(); install.packages("littler", type="source")' \
    && cd /usr/local/bin \
    && ln -s /usr/local/lib/R/site-library/littler/bin/r . \
    && ln -sf /usr/local/lib/R/site-library/littler/examples/install.r . \
    && ln -sf /usr/local/lib/R/site-library/littler/examples/install2.r . \
    && ln -sf /usr/local/lib/R/site-library/littler/examples/installGithub.r . \
    && ln -sf /usr/local/lib/R/site-library/littler/examples/update.r .

CMD ["bash"]
