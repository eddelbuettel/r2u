FROM eddelbuettel/r2u:jammy
RUN apt update -qq \
    && apt install --yes --no-install-recommends git
