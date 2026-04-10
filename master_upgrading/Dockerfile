FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Generate en_US.UTF-8 locale (required by initdb)
RUN apt-get update && apt-get install -y locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Add PostgreSQL apt repo and install PG15 + PG16
RUN apt-get update && apt-get install -y curl gnupg lsb-release ca-certificates sudo \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail \
        https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
        https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y \
        postgresql-15 \
        postgresql-16 \
        postgresql-client-15 \
        postgresql-client-16 \
        openssh-server \
        vim \
        net-tools \
        iputils-ping \
        procps \
        less \
        watch \
    && rm -rf /var/lib/apt/lists/*

# SSH: allow root + postgres login with password
RUN mkdir -p /var/run/sshd \
    && echo 'root:postgres' | chpasswd \
    && echo 'postgres:postgres' | chpasswd \
    && sed -i 's|#PermitRootLogin prohibit-password|PermitRootLogin yes|' /etc/ssh/sshd_config \
    && sed -i 's|PermitRootLogin prohibit-password|PermitRootLogin yes|' /etc/ssh/sshd_config \
    && sed -i 's|#PasswordAuthentication yes|PasswordAuthentication yes|' /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Give postgres passwordless sudo (demo only)
RUN echo "postgres ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Path convenience + demo aliases (available to both root and postgres)
RUN echo 'export PATH=/usr/lib/postgresql/15/bin:/usr/lib/postgresql/16/bin:$PATH' >> /etc/bash.bashrc \
    && echo "alias ll='ls -lgh --color=auto'" >> /etc/bash.bashrc \
    && echo "alias check='bash /scripts/check_status.sh'" >> /etc/bash.bashrc \
    && mkdir -p /var/lib/postgresql \
    && echo "alias ll='ls -lgh --color=auto'" >> /var/lib/postgresql/.bashrc \
    && echo "alias check='bash /scripts/check_status.sh'" >> /var/lib/postgresql/.bashrc \
    && chown postgres:postgres /var/lib/postgresql/.bashrc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5432 22

ENTRYPOINT ["/entrypoint.sh"]
