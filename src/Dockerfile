FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y git curl make bash gcc jq

# Copier uniquement les scripts .sh dans /scripts (pas dans /workspace)
COPY src/*.* /scripts/

# Ajouter /scripts au PATH pour tous les shells
ENV PATH="/scripts:${PATH}"

# Dossier de travail par défaut
WORKDIR /workspace

# Par défaut, démarrer bash dans /workspace
CMD ["/bin/bash"]
