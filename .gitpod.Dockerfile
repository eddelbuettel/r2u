FROM eddelbuettel/r2u:focal
RUN apt update -qq \
    && apt install --yes --no-install-recommends git
