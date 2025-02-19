# ========================================================
# Stage: Builder
# ========================================================
FROM --platform=linux/amd64 golang:1.20.4-alpine AS builder
WORKDIR /app
ARG TARGETARCH
ENV CGO_ENABLED=1

RUN apk --no-cache --update add \
  build-base \
  gcc \
  wget \
  unzip

COPY . .

RUN go build -o build/x-ui main.go
RUN ./DockerInit.sh "amd64"

# ========================================================
# Stage: Final Image of 3x-ui
# ========================================================
FROM alpine
ENV TZ=Asia/Tehran
WORKDIR /app

RUN apk add --no-cache --update \
  ca-certificates \
  tzdata \
  fail2ban

COPY --from=builder  /app/build/ /app/
COPY --from=builder  /app/DockerEntrypoint.sh /app/
COPY --from=builder  /app/x-ui.sh /usr/bin/x-ui

# Configure fail2ban
RUN rm -f /etc/fail2ban/jail.d/alpine-ssh.conf \
  && cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local \
  && sed -i "s/^\[ssh\]$/&\nenabled = false/" /etc/fail2ban/jail.local

RUN chmod +x \
  /app/DockerEntrypoint.sh \
  /app/x-ui \
  /usr/bin/x-ui

VOLUME [ "/etc/x-ui" ]
EXPOSE 2053
ENTRYPOINT [ "/app/DockerEntrypoint.sh" ]
