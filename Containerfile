# Use UBI Micro base image
FROM registry.access.redhat.com/ubi8/ubi-minimal

WORKDIR /app/spilot
ENV SHELL_PILOT_CONFIG_PATH=/app/spilot

RUN microdnf  install -y findutils ncurses curl jq && \
    microdnf clean all  

COPY . .

RUN chgrp -R 0 /app/spilot && chmod -R g=u /app/spilot && chmod +x /app/spilot/*

# Set default command
USER 1001
CMD ["sleep", "infinity"]
