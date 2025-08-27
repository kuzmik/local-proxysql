# This is really used anymore since we deploy the stock proxysql image to our clusters,
# but this may be useful for local dev at some point

FROM proxysql/proxysql:3.0.2-debian

# Install additional tools since ProxySQL Docker image is very bare-bones
# Install Ruby (for the probes.rb), dig, etc
RUN apt-get update && apt-get -u upgrade -y && apt-get install -y --no-install-recommends --fix-missing \
  bind9-dnsutils \
  curl \
  jq \
  less \
  lsof \
  procps \
  ruby \
  vim && \
  apt-get autoremove -y && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*

USER proxysql
WORKDIR /tmp

# BUG: Reset entrypoint to override base image.
ENTRYPOINT []

CMD ["proxysql", "-f", "--idle-threads", "--no-version-check"]
