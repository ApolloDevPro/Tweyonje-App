# Multi-stage build for Flutter web application
FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Download Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter

# Add Flutter to PATH
ENV PATH="/opt/flutter/bin:${PATH}"
ENV FLUTTER_WEB_AUTO_DETECT=true

# Verify Flutter installation
RUN flutter doctor -v

# Set working directory
WORKDIR /app

# Copy app files
COPY . .

# Install Flutter dependencies
RUN flutter pub get

# Build web application
RUN flutter build web --release

# Use nginx for serving the web application
FROM nginx:alpine
COPY --from=0 /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]