FROM ubuntu:22.04 AS builder
RUN apt-get update && apt-get install -y git curl make bash
WORKDIR /workspace
COPY . .
RUN bash src/build.sh osmosis

CMD ["/bin/bash"]
