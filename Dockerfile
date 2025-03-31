# استخدم Ubuntu 22.04 كأساس
FROM ubuntu:22.04

# تحديث النظام وتثبيت الأدوات الأساسية
RUN apt update && apt install -y \
    curl wget unzip git openssh-server nano software-properties-common

# تثبيت Java JDK 17 
RUN add-apt-repository ppa:linuxuprising/java -y && apt update && \
    apt install -y openjdk-17-jdk

# تعيين JDK الافتراضي إلى JDK 17 (لأن إعدادات المشروع تعتمد على Java 17)
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# تثبيت Gradle wrapper أو Gradle الإصدار 8.10.2 (يفضل استخدام الـ wrapper، لكن هنا سنقوم بتنزيله)
RUN wget https://services.gradle.org/distributions/gradle-8.10.2-bin.zip && \
    unzip gradle-8.10.2-bin.zip -d /opt && rm gradle-8.10.2-bin.zip
ENV GRADLE_HOME=/opt/gradle-8.10.2
ENV PATH="$GRADLE_HOME/bin:$PATH"

# تثبيت Flutter (نسخة 3.29.2)
WORKDIR /opt
RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.2-stable.tar.xz && \
    tar xf flutter_linux_3.29.2-stable.tar.xz -C /opt && \
    rm flutter_linux_3.29.2-stable.tar.xz
ENV PATH="/opt/flutter/bin:$PATH"

# تثبيت Android SDK و NDK
WORKDIR /opt/android-sdk

# تنزيل أدوات سطر الأوامر الخاصة بـ Android SDK
RUN mkdir -p /opt/android-sdk/cmdline-tools/latest && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmd-tools.zip && \
    unzip cmd-tools.zip -d /opt/android-sdk/cmdline-tools && \
    rm cmd-tools.zip && \
    mv /opt/android-sdk/cmdline-tools/cmdline-tools/* /opt/android-sdk/cmdline-tools/latest/ && \
    rmdir /opt/android-sdk/cmdline-tools/cmdline-tools && \
    chmod +x /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager

# ضبط متغيرات البيئة للـ Android SDK
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# التأكد من أن sdkmanager يعمل
RUN /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --version

# تثبيت حزم Android SDK المطلوبة
RUN yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses && \
    /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager \
    "platforms;android-35" "build-tools;36.0.0" "ndk;27.0.12077973" "cmdline-tools;latest" "platform-tools"



# تثبيت ADB لدعم AppView على الهاتف
RUN apt install -y adb

# إعداد Gradle لتبديل Groovy <-> Kotlin أثناء التثبيت الأولي
# سيتم تشغيل السكريبت setup-gradle.sh لاحقاً
COPY setup-gradle.sh /root/setup-gradle.sh
RUN chmod +x /root/setup-gradle.sh && /root/setup-gradle.sh

# نسخ سكريبتات الإعداد الأخرى
COPY setup.sh /root/setup.sh
RUN chmod +x /root/setup.sh
COPY auto_sync.sh /root/auto_sync.sh
RUN chmod +x /root/auto_sync.sh

# إعداد SSH: نسخ إعدادات SSH إذا وُجد ملف ssh_config (يمكنك تعديله حسب الحاجة)
COPY ssh_config /etc/ssh/sshd_config

# تشغيل SSH عند بدء تشغيل الحاوية
CMD ["/bin/bash", "-c", "/root/setup.sh"]
