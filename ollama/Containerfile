# Use UBI Micro base image
FROM registry.access.redhat.com/ubi8/ubi-minimal

WORKDIR /app/ollama
# Install necessary packages
RUN microdnf  --noplugins install -y findutils curl jq && \
    microdnf --noplugins clean all && \
    curl -fsSL https://ollama.com/install.sh | sh && \
    chmod +x /usr/local/bin/ollama
ADD ollama-entrypoint.sh /app/ollama
#RUN ollama pull llama2
RUN mkdir -p /var/lib/ollama/.ollama/.ollama && \
    chgrp -R 0 /var/lib/ollama/.ollama && chmod -R g=u /var/lib/ollama/.ollama  && \
    chmod +x /app/ollama/ollama-entrypoint.sh && \
    chgrp -R 0 /app/ollama && chmod -R g=u /app/ollama 

# Conditionally pull model if PULL_MODEL_BY_DEFAULT is set to true
ARG PULL_MODEL_BY_DEFAULT=false
ARG MODEL=llama2
RUN if [ "$PULL_MODEL_BY_DEFAULT" = "true" ]; then ollama serve & sleep 50 && ollama pull $MODEL; fi
# Set default command
EXPOSE 11434
USER 1001
ENTRYPOINT ["/app/ollama/ollama-entrypoint.sh"]

