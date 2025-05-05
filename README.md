# Sunucu Kurulum Asistanı (Bash)

Bu Bash scripti, root yetkisiyle çalışan bir Linux sunucusunda (Ubuntu/Debian tabanlı) hızlı ve etkileşimli bir şekilde web sunucusu, PHP, veritabanı ve güvenlik duvarı kurulumu yapmanıza yardımcı olur.

## 🚀 Özellikler

- Root yetkisi kontrolü
- Sistem güncelleme ve saat dilimi ayarı
- Apache veya Nginx seçimi ve kurulumu
- PHP kurulumu (sürüm seçimi: 7.4 - 8.2 arası)
- MySQL veya MariaDB seçimi ile veritabanı kurulumu
- UFW veya FirewallD güvenlik duvarı seçimi ve yapılandırması
- Kurulum özeti ve log dosyasına kayıt

## 🧰 Gereksinimler

- Root yetkisi (sudo/root)
- Ubuntu veya Debian tabanlı sistem

## 🛠️ Kurulum

1. Script dosyasını indirin:

```bash
wget https://github.com/erenakkus/syskurulum/blob/main/kurulum.sh -O sunucu-kurulum.sh
```
2. Çalıştırılabilir  Hale Getirin

```bash
chmod +x sunucu-kurulum.sh
```
3. Scripti Çalıştırın

```bash
sudo ./sunucu-kurulum.sh
```

4. Log Dosyaları

Aşağıdaki dizinde görebilirsiniz.
/var/log/sunucu_kurulum.log


# 👨‍💻 Geliştirici
Hazırlayan: Eren Akkuş

Herhangi bir öneri veya katkı için iletişime geçebilirsiniz.
