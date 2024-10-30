#!/bin/bash

# Ayarlar
limit=2  # E-posta gönderim sınırı
log_file="/var/log/email_sends.log"  # Günlük dosyası
header_checks_file="/etc/postfix/header_checks"  # Header checks dosyası
postfix_log="/var/log/mail.log"  # Postfix log dosyası

# Günlük dosyasını oluştur
if [ ! -f "$log_file" ]; then
    touch "$log_file"
fi

# Son 1000 satırı oku ve her e-posta gönderiminde from kısmını analiz et
tail -n 1000 "$postfix_log" | grep 'from=<.*>' | awk -F 'from=<' '{print $2}' | awk -F '>' '{print $1}' | sort | uniq -c | while read -r count email; do
    # E-posta adresinin geçerli olup olmadığını kontrol et
    if [[ -n "$email" && "$count" -gt "$limit" && "$email" != "root"* ]]; then
        # Domain kontrolü
        domain=$(echo "$email" | awk -F'@' '{print $2}')

        # Domain'in mevcut olup olmadığını kontrol et
        if ls /home/vmail | grep -q "$domain"; then # Kullanmış olduğunuz sistemde farklı bir yerde olabilir
            # Engelleme kuralı
            pattern="/^From:.*$email/ REJECT"

            # Header checks dosyasına ekle
            if ! grep -q "$pattern" "$header_checks_file"; then
                echo "$pattern" >> "$header_checks_file"
                postmap "$header_checks_file"
                systemctl reload postfix
                echo "E-posta adresi başarıyla engellendi: $email" | tee -a "$log_file"

                # Bildirim e-posta içeriği ve gönderimi
                subject="E-posta Engelleme Bildirimi"
                body="Merhaba,\n\n$email adresiniz  günlük gönderim sınırını aşması  nedeniyle engellenmiştir.\n\nSaygılarımızla."
                echo -e "$body" | mail -s "$subject" "$email"
                echo "Bildirim e-postası gönderildi: $email" | tee -a "$log_file"
            else
                echo "Bu e-posta adresi zaten engellenmiş: $email" | tee -a "$log_file"
            fi
        else
            echo "Bu e-posta adresi engellenmedi (domain mevcut değil): $email" | tee -a "$log_file"
        fi
    else
        echo "Root e-posta adresi engellenmedi veya geçersiz e-posta: $email" | tee -a "$log_file"
    fi
done
