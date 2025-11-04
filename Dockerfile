FROM alpine:latest

RUN apk update && apk add --no-cache \
    wireguard-tools \
    iptables \
    bash \
    curl \
    jq \
    && rm -rf /var/cache/apk/*

# Create directories
RUN mkdir -p /etc/wireguard /wg/keys /wg/configs

# Copy scripts
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Set up WireGuard interface
RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

VOLUME ["/etc/wireguard", "/wg/keys", "/wg/configs"]

EXPOSE 51820/udp

CMD ["/usr/local/bin/start-wg.sh"]
