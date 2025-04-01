# استخدم Ubuntu 22.04 كأساس
FROM ubuntu:22.04

# تحديث النظام وتثبيت الأدوات الأساسية والحزم المطلوبة لتطوير Linux وتشغيل Flutter في بيئة headless
RUN apt update && apt install -y \
    curl wget unzip git openssh-server nano software-properties-common \
        cmake ninja-build clang pkg-config libgtk-3-dev liblzma-dev xvfb

        # تثبيت Google Chrome (إذا كان التطوير على الويب مطلوباً؛ إن لم يكن يمكن حذف السطر)
        RUN apt update && apt install -y google-chrome-stable

        # تثبيت Java JDK 17 فقط (حذف openjdk-23-jdk لتفادي مشاكل المكتبات)
        RUN add-apt-repository ppa:linuxuprising/java -y && apt update && \
            apt install -y openjdk-17-jdk
            ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
            ENV PATH="$JAVA_HOME/bin:$PATH"

            # تثبيت Gradle (نسخة 8.10.2)
            RUN wget https://services.gradle.org/distributions/gradle-8.10.2-bin.zip && \
                unzip gradle-8.10.2-bin.zip -d /opt && rm gradle-8.10.2-bin.zip
                ENV GRADLE_HOME=/opt/gradle-8.10.2
                ENV PATH="$GRADLE_HOME/bin:$PATH"

                # تثبيت Flutter (نسخة 3.29.2) وتحديث الـ cache تلقائياً
                WORKDIR /opt
                RUN git clone --branch 3.29.2-stable https://github.com/flutter/flutter.git
                ENV PATH="/opt/flutter/bin:$PATH"
                RUN flutter precache

                # تثبيت Android SDK وNDK:
                WORKDIR /opt/android-sdk
                RUN mkdir -p /opt/android-sdk/cmdline-tools && \
                    cd /opt/android-sdk && \
                        wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmd-tools.zip && \
                            unzip cmd-tools.zip -d /opt/android-sdk && \
                                rm cmd-tools.zip && \
                                    \
                                        # إذا كان هناك أكثر من مجلد داخل cmdline-tools (مثل "latest" و "latest-2")، نستخدم الإصدار الأحدث:
                                            if [ -d "cmdline-tools/latest-2" ]; then \
                                                     rm -rf cmdline-tools/latest && mv cmdline-tools/latest-2 cmdline-tools/latest; \
                                                         fi

                                                         # ضبط متغيرات البيئة الخاصة بالأندرويد
                                                         ENV ANDROID_HOME=/opt/android-sdk
                                                         ENV ANDROID_SDK_ROOT=/opt/android-sdk
                                                         ENV PATH="$PATH:/opt/android-sdk/platform-tools:/opt/android-sdk/cmdline-tools/latest/bin"

                                                         # تثبيت حزم Android SDK المطلوبة مع تجاوز تأكيدات التثبيت
                                                         RUN yes | sdkmanager --licenses && sdkmanager \
                                                             "platforms;android-35" "build-tools;36.0.0" "ndk;27.0.12077973" "cmdline-tools;latest" "platform-tools"

                                                             # تثبيت ADB لتوصيل الهاتف
                                                             RUN apt install -y adb

                                                             # إعداد سكريبت تبديل إعدادات Gradle (setup-gradle.sh) لتبديل DSL مؤقتاً أثناء البناء
                                                             COPY setup-gradle.sh /root/setup-gradle.sh
                                                             RUN chmod +x /root/setup-gradle.sh && /root/setup-gradle.sh

                                                             # نسخ سكريبتات الإعداد الأخرى (setup.sh و auto_sync.sh) وضبط التصاريح
                                                             COPY setup.sh /root/setup.sh
                                                             RUN chmod +x /root/setup.sh
                                                             COPY auto_sync.sh /root/auto_sync.sh
                                                             RUN chmod +x /root/auto_sync.sh

                                                             # (اختياري) نسخ ملف إعداد SSH إذا وُجد لتعديل إعدادات SSH داخل الحاوية
                                                             COPY ssh_config /etc/ssh/sshd_config

                                                             # ضبط PATH الدائم لجميع الأدوات (Flutter، Android SDK) عبر إضافة الأسطر إلى /root/.bashrc
                                                             RUN echo 'export PATH="$PATH:/opt/flutter/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/cmdline-tools/latest/bin"' >> /root/.bashrc

                                                             # عند بدء تشغيل الحاوية، يتم تشغيل سكريبت setup.sh الذي يقوم بتشغيل SSH واستنساخ المشروع وغيرها من الإعدادات
                                                             CMD ["/bin/bash", "-c", "/root/setup.sh"]
