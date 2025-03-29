#!/bin/bash
# يقوم هذا السكريبت بتبديل إعدادات Gradle من Groovy إلى Kotlin مؤقتاً
# يُفترض أن ملف build.gradle موجود في الدليل /root/workspace

cd /root/workspace
if [ -f "build.gradle" ]; then
    # تحويل build.gradle إلى build.gradle.kts (مثال بسيط، يجب تعديل الكود حسب الحاجة)
    mv build.gradle build.gradle.bak
    cp build.gradle.bak build.gradle.kts
    echo "تم التبديل إلى Kotlin DSL لتشغيل البناء"
    # تشغيل البناء باستخدام Gradle
    gradle build
    # إعادة الملف إلى Groovy DSL بعد البناء
    mv build.gradle.kts build.gradle
    mv build.gradle.bak build.gradle
    echo "تم إعادة التبديل إلى Groovy DSL"
fi
