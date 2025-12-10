FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Gerekli paketleri kur
RUN apt-get update && apt-get install -y \
    python3 \
    dpkg-dev \
    debhelper \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kaynak kodları imajın içine kopyala (Volume mount sorununu çözer)
COPY . /app

# Build komutu
CMD ["python3", "tools/build_deb.py", "--arch", "all"]
