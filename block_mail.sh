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
    echo "$pattern REJECT" >> "$access_file"
    # Postfix'i yeniden yükle
    postmap "$access_file"
    systemctl reload postfix
    echo "E-posta adresi başarıyla engellendi: $email"
else
    echo "Bu e-posta adresi zaten engellenmiş."
fi
