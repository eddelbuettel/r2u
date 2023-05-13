FROM rocker/r2u:jammy
RUN apt update -qq \
    && apt install --yes --no-install-recommends git sudo \
    && useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod \
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers
## cf https://github.com/kevinhq/gitpod-debian/blob/master/.gitpod.Dockerfile for sudo config