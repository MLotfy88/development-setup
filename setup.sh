#!/bin/bash
# تشغيل SSH داخل الحاوية
service ssh start

# الانتقال إلى مجلد المشروع (سيتم إنشاؤه في /root/workspace)
if [ ! -d "/root/workspace" ]; then
    mkdir /root/workspace
fi

# تحميل أو تحديث كود المشروع
cd /root/workspace
if [ ! -d "project" ]; then
    echo "🚀 استنساخ مستودع المشروع لأول مرة..."
    git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_PROJECT_REPO.git project
else
    echo "✅ المشروع موجود بالفعل، يتم التحديث..."
    cd project && git pull origin main && cd ..
fi

# إنشاء ملف بيانات الاتصال (Credentials)
mkdir -p /root/public
echo "🔐 VPS Credentials 🔐" > /root/public/credentials.txt
echo "-----------------------------------" >> /root/public/credentials.txt
echo "📌 SSH Connection:" >> /root/public/credentials.txt
echo "ssh root@$(hostname -I | awk '{print $1}')" >> /root/public/credentials.txt
echo "" >> /root/public/credentials.txt
echo "📌 VS Code Connection:" >> /root/public/credentials.txt
echo "Remote-SSH: Connect to Host and use:" >> /root/public/credentials.txt
echo "ssh root@$(hostname -I | awk '{print $1}')" >> /root/public/credentials.txt
echo "" >> /root/public/credentials.txt
echo "📌 Trae.ai Connection:" >> /root/public/credentials.txt
echo "Use the same SSH credentials as above." >> /root/public/credentials.txt
echo "-----------------------------------" >> /root/public/credentials.txt

# بدء ADB لتوصيل الهاتف (يمكنك تعديل الأمر إذا كنت تستخدم طريقة اتصال مختلفة)
adb start-server

# إبقاء الحاوية قيد التشغيل
tail -f /dev/null
