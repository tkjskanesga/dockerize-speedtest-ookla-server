FROM debian:bookworm-slim

# Install the dependencies required by OoklaServer (curl, tar, ca-certificates)
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  tar \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Create the 'ookla' group and user for Debian/Ubuntu
RUN groupadd -g 1100 ookla \
  && useradd -u 1100 -g ookla -m -s /bin/sh ookla

WORKDIR /home/ookla

# Download & Install OoklaServer
RUN curl -O http://install.speedtest.net/ooklaserver/ooklaserver.sh \
  && chmod +x ooklaserver.sh \
  && ./ooklaserver.sh install -f \
  && rm ooklaserver.sh \
  && chown -R ookla:ookla /home/ookla

# Switch to a non-root user
USER ookla

# Expose port (TCP & UDP)
EXPOSE 80/tcp
EXPOSE 443/tcp
EXPOSE 8080/tcp 8080/udp
EXPOSE 5060/tcp 5060/udp

# Run OoklaServer
ENTRYPOINT ["/home/ookla/OoklaServer"]
CMD ["start"]