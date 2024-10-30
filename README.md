# SMTP-Email-Restriction


Bu dökümanda, Postfix SMTP servisi üzerinden belirli bir e-posta adresinin gönderim hakkını engellemek için kullanılan sistemin kurulumu ve kullanımı açıklanmaktadır. Eğer bu sistemin otomatik olarak çalışmasının istiyor iseniz lütfen belgeyi sonuna kadar okuyunuz.

## Gereksinimler

- Postfix SMTP sunucusu kurulu ve yapılandırılmış olmalıdır.
- `header_checks` dosyası ile Postfix'in yapılandırması yapılmalıdır.

## Yapılandırma

### 1. `header_checks` Dosyasının Yapılandırılması

Postfix konfigürasyon dosyasında, `header_checks` ayarını ekleyin:

```bash
header_checks = regexp:/etc/postfix/header_checks
```

### 2. E-posta Adresini Engellemek İçin Kullanılacak Betik

Aşağıdaki bash betiğini kullanarak bir e-posta adresini engelleyebilir veya engelini kaldırabilirsiniz.

```bash
#!/bin/bash

# E-posta adresini al
read -p "Engellenecek E-posta Adresi: " email

# Geçerli bir e-posta adresi kontrolü
if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Geçersiz bir e-posta adresi girdiniz."
    exit 1
fi

# Access dosyasına ekle
access_file="/etc/postfix/access"

# Belirtilen biçimde ekleme yap
pattern="/^From:.*$email/"

if ! grep -q "$pattern" "$access_file"; then
    echo "$pattern REJECT Custom error message: Your email is not allowed to be sent from this address." >> "$access_file"
    # Postfix'i yeniden yükle
    postmap "$access_file"
    systemctl reload postfix
    echo "E-posta adresi başarıyla engellendi: $email"
else
    echo "Bu e-posta adresi zaten engellenmiş."
fi
```

### 3. Betiği Çalıştırma

Betik dosyasına çalıştırılabilir izin verin ve çalıştırın:

```bash
chmod +x your_script.sh
./your_script.sh
```

### 4. Postfix'i Yeniden Yükleme

E-posta adresini engelledikten veya kaldırdıktan sonra Postfix'i yeniden yüklemeniz gerekecek:

```bash
systemctl reload postfix
```

### 5. Test Edelim

Aşağıda engellenmiş olunan bir e-posta hesabı ile kontrol sağlandığında mesajın gönderilmediğini görüyoruz.

```
Oct 30 22:31:54 localhost postfix/cleanup[10313]: 62F26180665: reject: header From: ugur@ugurcomptech.net.tr from localhost[127.0.0.1]; from=<ugur@ugurcomptech.net.tr> to=<ugur@gmail.com> proto=ESMTP helo=<[193.106.196.59]>: 5.7.1 message content rejected
```

# Oto-SMTP-Email-Restriction

Bu script üzerinde belirlenen limit kadar kullanıcıların mail gönderme hakkı bulunmaktadır. Eğer kullanıcılar bu llimitleri geçerse gönderim hakkı otomatik olarak engellenir. Dilerseniz buna bir süre belirleyebilirsiniz. Ek olarak bu scirpt engellediği maile bir bildiri gönderir.

![image](https://github.com/user-attachments/assets/e5bb60a1-ceba-4c3b-830c-1013ddfa08a1)


[Buraya](https://github.com/ugurcomptech/SMTP-Email-Restriction/blob/main/email_monitor.sh) tıklayarak repo üzerindeki scripte erişebilirsiniz.

Scriptin otomatik çalışması için crontab'a ekliyoruz.

```
* * * * * /root/email_monitor.sh
```

Script her bir dakikada çalışacaktır ve kontrol edecektir. Script root adresleri ve o sunucuda olmayan domainleri engellemeyecektir. Kontrol etmek için `tail -f /var/log/email_sends.log` yazabilirsiniz.

```
Root e-posta adresi engellenmedi: droowmpd@amigdala.site
Root e-posta adresi engellenmedi: root
Root e-posta adresi engellenmedi: root@amigdala.site
E-posta adresi başarıyla engellendi: ugurcan@ugurcomptech.net.tr
Bu e-posta adresi engellenmedi (domain mevcut değil): ugur@gmail.com
E-posta adresi başarıyla engellendi: ugur@ugurcomptech.net.tr
```

## Dikkat Edilmesi Gerekenler

- **Engelleme İşlemi**: Engelleme işlemi, belirtilen e-posta adresinden yapılan tüm gönderimleri engelleyecektir. E-posta adresi engellendikten sonra `header_checks` dosyasına kural eklenir ve Postfix yapılandırması yeniden yüklenir.
- **Postfix Yeniden Yükleme**: `header_checks` dosyasındaki değişikliklerin geçerli olması için `postmap` ve `systemctl reload postfix` komutları çalıştırılmaktadır. Sunucuda kritik işlemler yürütülüyorsa, bu komutların çalışma sıklığı sunucu performansı açısından dikkatle ayarlanmalıdır.
- **Kullanıcı ve Domain Kontrolü**: Script, yalnızca `/home/vmail` altında tanımlı alan adlarına ait e-posta adresleri için engelleme sağlar. Bu nedenle, sunucuda tanımlı olmayan dış alan adları engellenmeyecektir.
- **Kök (Root) Kullanıcı İstisnası**: Sunucu işlemlerinde önemli olan `root` kullanıcısından gelen e-postalar, istisna olarak engellenmeyecek şekilde ayarlanmıştır.
- **Script Çalışma Aralığı**: Bu script, 1 dakikalık aralıklarla cron ile çalıştırılabilir. Bu sayede Postfix logları düzenli olarak izlenir ve limit aşımı durumunda hızlıca müdahale edilir.
- **Loglama ve Günlük Dosyaları**: Engellenen e-posta adresleri ve diğer durum mesajları, tanımlı `log_file` (`/var/log/email_sends.log`) dosyasına kaydedilir. Bu dosyanın düzenli olarak gözden geçirilmesi veya temizlenmesi önerilir.
- **Sistem Performansı**: Sürekli log dosyalarını izleme ve güncelleme işlemi yüksek e-posta trafiği olan sunucularda işlemci ve disk kullanımı açısından dikkat gerektirir. Gerektiğinde `tail -n` ile okunan satır sayısı azaltılabilir veya zaman aralığı genişletilebilir.
- **Uyumluluk**: Bu script yalnızca Postfix üzerinde test edilmiştir. Farklı MTA (Mail Transfer Agent) servisleri için uyumluluk garantisi sunulmamaktadır.



## Lisans

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Bu projeyi [MIT Lisansı](https://opensource.org/licenses/MIT) altında lisansladık. Lisansın tam açıklamasını burada bulabilirsiniz.
