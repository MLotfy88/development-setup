# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set frontend to noninteractive to avoid prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Update, install base tools, SSH, Java PPA tools, Linux dev tools, headless display, ADB
# Combine installs and clean up apt cache
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    unzip \
    git \
    openssh-server \
    nano \
    software-properties-common \
    # xz-utils is needed to extract .tar.xz archives (like Flutter SDK)
    xz-utils \
    # gnupg and dirmngr are needed for add-apt-repository to import keys
    gnupg \
    dirmngr \
    # Linux build dependencies from flutter doctor & build errors
    cmake \
    ninja-build \
    clang \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    # Headless display support
    xvfb \
    # Android Debug Bridge
    adb \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# (Optional) Install Google Chrome for web testing
# If not needed, comment out or remove this RUN block
RUN apt-get update && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -P /tmp && \
    apt-get install -y /tmp/google-chrome-stable_current_amd64.deb && \
    rm /tmp/google-chrome-stable_current_amd64.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Java JDK 17 (required by project)
RUN add-apt-repository ppa:linuxuprising/java -y && apt-get update && \
    apt-get install -y --no-install-recommends openjdk-17-jdk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install Gradle (version 8.10.2)
ENV GRADLE_VERSION=8.10.2
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp && \
    unzip /tmp/gradle-${GRADLE_VERSION}-bin.zip -d /opt && \
    rm /tmp/gradle-${GRADLE_VERSION}-bin.zip
ENV GRADLE_HOME=/opt/gradle-${GRADLE_VERSION}
ENV PATH="$GRADLE_HOME/bin:$PATH"

# Install Flutter SDK (version 3.29.2) using official archive
ENV FLUTTER_VERSION=3.29.2
WORKDIR /opt
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -P /tmp && \
    tar xf /tmp/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /opt && \
    rm /tmp/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
ENV PATH="/opt/flutter/bin:$PATH"
# Add safe directory config for git to avoid ownership errors when running flutter doctor
RUN git config --global --add safe.directory /opt/flutter
# Run flutter doctor as root during build to download Dart SDK, artifacts, and create cache files with root ownership
RUN flutter doctor

# Install Android SDK and NDK in /sdk
ENV ANDROID_SDK_ROOT=/sdk
# Create the base SDK directory
# Download and unzip initial cmdline-tools to get sdkmanager
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/cmd-tools.zip && \
    unzip /tmp/cmd-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    rm /tmp/cmd-tools.zip && \
    # Handle the potential nested 'cmdline-tools' directory and 'latest-2' case
    if [ -d "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" ]; then \
       mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest; \
    elif [ -d "${ANDROID_SDK_ROOT}/cmdline-tools/latest-2" ]; then \
       echo "Found latest-2 directory, renaming to latest." ; \
       rm -rf ${ANDROID_SDK_ROOT}/cmdline-tools/latest && mv ${ANDROID_SDK_ROOT}/cmdline-tools/latest-2 ${ANDROID_SDK_ROOT}/cmdline-tools/latest; \
    elif [ -d "${ANDROID_SDK_ROOT}/cmdline-tools/latest" ]; then \
       echo "Found latest directory already." ; \
    else \
       echo "Warning: Could not find expected cmdline-tools structure. SDK setup might fail." ; \
    fi

# Set Android environment variables
ENV ANDROID_HOME=${ANDROID_SDK_ROOT}
# Update PATH immediately to include the newly unzipped cmdline-tools/latest/bin
ENV PATH="$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin"
# Add platform-tools path as well (sdkmanager will install it later)
ENV PATH="$PATH:${ANDROID_SDK_ROOT}/platform-tools"

# Install required Android SDK packages, accepting licenses
# Running as root, specifying sdk_root explicitly
RUN yes | sdkmanager --licenses --sdk_root=${ANDROID_SDK_ROOT} && \
    sdkmanager --install "platforms;android-35" "build-tools;36.0.0" "ndk;27.0.12077973" "cmdline-tools;latest" "platform-tools" --sdk_root=${ANDROID_SDK_ROOT}
# Ensure correct ownership if a dedicated user was used
# RUN chown -R android-sdk-user:android-sdk ${ANDROID_SDK_ROOT}

# Copy setup scripts and set permissions
COPY setup.sh /root/setup.sh
RUN chmod +x /root/setup.sh
COPY auto_sync.sh /root/auto_sync.sh
RUN chmod +x /root/auto_sync.sh

# Copy SSH server config (ensure PermitRootLogin is yes if running as root)
COPY ssh_config /etc/ssh/sshd_config

# Add all environment variables and paths permanently to root's bashrc
RUN echo '\n# Added paths for Dev Environment' >> /root/.bashrc && \
    echo "export JAVA_HOME=${JAVA_HOME}" >> /root/.bashrc && \
    echo "export GRADLE_HOME=${GRADLE_HOME}" >> /root/.bashrc && \
    echo "export ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}" >> /root/.bashrc && \
    echo "export ANDROID_HOME=${ANDROID_HOME}" >> /root/.bashrc && \
    echo 'export PATH="$PATH:$JAVA_HOME/bin:$GRADLE_HOME/bin:/opt/flutter/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"' >> /root/.bashrc

# Set default working directory
WORKDIR /root/workspace

# Expose SSH and ADB ports (optional, as mapping is done in `docker run`)
# EXPOSE 22 5037

# Run setup script on container start
CMD ["/bin/bash", "/root/setup.sh"]
