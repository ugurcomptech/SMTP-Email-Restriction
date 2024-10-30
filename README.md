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

Bu script üzerinde belirlenen limit kadar kullanıcıların mail gönderme hakkı bulunmaktadır. Eğer kullanıcılar bu llimitleri geçerse gönderim hakkı otomatik olarak engellenir. Dilerseniz buna bir süre belirleyebilirsiniz.

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

- Engelleme işlemi, belirtilen e-posta adresinden yapılan tüm gönderimleri engelleyecektir.
- `header_checks` dosyasında yapılacak değişikliklerin geçerli olması için Postfix'in yeniden yüklenmesi gerektiğini unutmayın.
- Scriptler üzerine belirtilen dosya yolu sizin kullanmış olduğunuz sistemde farklılık gösterebilir.
- Bu scriptler sadece Postfix üzerinde denenmiş olup farklı SMTP servisleri için herhangi bir test gerçekleştirilmemiş olup çalışma garantisi sunulmmaktadır. 


## Lisans

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Bu projeyi [MIT Lisansı](https://opensource.org/licenses/MIT) altında lisansladık. Lisansın tam açıklamasını burada bulabilirsiniz.
