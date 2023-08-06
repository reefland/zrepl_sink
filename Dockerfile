FROM ubuntu:22.04

LABEL container.author="Richard Durso <reefland@gmail.com>" \
      container.github="https://github.com/reefland/zrepl_sink" \
      project.url="https://zrepl.github.io" \
      project.github="https://github.com/zrepl/zrepl" \
      project.description="Zrepl zrepl is a one-stop, integrated solution for ZFS replication."

ENV zrepl_apt_key_url=https://zrepl.cschwarz.com/apt/apt-key.asc \
    zrepl_apt_repo_file=/etc/apt/sources.list.d/zrepl.list

RUN apt-get update \
  && apt-get upgrade -y --no-install-recommends \
  && apt-get install -y --no-install-recommends zfsutils-linux curl gnupg lsb-release ca-certificates

# Fetch the zrepl apt key
RUN  curl ${zrepl_apt_key_url} | apt-key add -

# Add the zrepl apt repository
RUN ARCH="$(dpkg --print-architecture)" \
  && CODENAME="$(lsb_release -i -s | tr '[:upper:]' '[:lower:]') $(lsb_release -c -s | tr '[:upper:]' '[:lower:]')" \
  && echo "deb [arch=$ARCH] https://zrepl.cschwarz.com/apt/$CODENAME main" > "${zrepl_apt_repo_file}"

# Install zrepl and cleanup
RUN apt-get update \
  && apt-get install -y --no-install-recommends zrepl \
  && apt-get -y --purge autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /config /var/run/zrepl/stdinserver \
  && chmod -R 0700 /var/run/zrepl

COPY entrypoint.sh /root/

ENTRYPOINT [ "/root/entrypoint.sh" ]
