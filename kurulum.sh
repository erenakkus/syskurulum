#!/bin/bash

# Renkler
yellow='\033[1;33m'
red='\033[1;31m'
green='\033[1;32m'
blue='\033[1;34m'
cyan='\033[1;36m'
nc='\033[0m' # Renk sıfırla

# Log dosyası
LOGFILE="/var/log/sunucu_kurulum.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Root kontrolü
function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${red}Bu scripti root olarak çalıştırmalısınız!${nc}"
        exit 1
    fi
}

# İşletim sistemi kontrolü
function check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo -e "${red}Bu script yalnızca Debian, Ubuntu, CentOS, AlmaLinux sistemlerinde çalışır.${nc}"
        exit 1
    fi
}

# Paket yöneticisi belirleme
function detect_package_manager() {
    if command -v apt &>/dev/null; then
        PM="apt"
        INSTALL="apt install -y"
        UPDATE="apt update -y"
    elif command -v dnf &>/dev/null; then
        PM="dnf"
        INSTALL="dnf install -y"
        UPDATE="dnf update -y"
    elif command -v yum &>/dev/null; then
        PM="yum"
        INSTALL="yum install -y"
        UPDATE="yum update -y"
    else
        echo -e "${red}Desteklenmeyen bir sistem.${nc}"
        exit 1
    fi
}

# Sistem güncellemesi
function update_system() {
    echo -e "${blue}Sistem güncelleniyor...${nc}"
    $UPDATE
}

# Zaman dilimi ayarla
function set_timezone() {
    echo -e "${blue}Zaman dilimi Europe/Istanbul olarak ayarlanıyor...${nc}"
    timedatectl set-timezone Europe/Istanbul
}

# Web sunucusu kurulumu
function install_web_server() {
    echo -e "${yellow}Web sunucusu seçiniz:${nc}"
    echo "1) Apache"
    echo "2) Nginx"
    read -p "Seçiminiz (1/2): " web_choice

    case $web_choice in
        1)
            web_server="Apache"
            if ! systemctl is-active --quiet apache2 && ! systemctl is-active --quiet httpd; then
                echo -e "${blue}Apache kuruluyor...${nc}"
                $INSTALL apache2 httpd
                systemctl enable apache2 || systemctl enable httpd
                systemctl start apache2 || systemctl start httpd
            else
                echo -e "${yellow}Apache zaten kurulu.${nc}"
            fi
            ;;
        2)
            web_server="Nginx"
            if ! systemctl is-active --quiet nginx; then
                echo -e "${blue}Nginx kuruluyor...${nc}"
                $INSTALL nginx
                systemctl enable nginx
                systemctl start nginx
            else
                echo -e "${yellow}Nginx zaten kurulu.${nc}"
            fi
            ;;
        *)
            echo -e "${red}Geçersiz seçim!${nc}"
            exit 1
            ;;
    esac
}

# PHP kurulumu
function install_php() {
    read -p "PHP kurulumu yapılsın mı? (e/h): " php_choice
    if [[ "$php_choice" =~ ^[Ee]$ ]]; then
        echo -e "${yellow}Kurulacak PHP sürümünü girin (örnek: 7.4, 8.0, 8.1, 8.2):${nc}"
        read -p "PHP Sürümü: " php_version
        php_installed=true

        if [[ "$PM" == "apt" ]]; then
            $INSTALL software-properties-common
            add-apt-repository ppa:ondrej/php -y
            $UPDATE
            $INSTALL php$php_version php$php_version-cli php$php_version-common php$php_version-mysql
        else
            $INSTALL epel-release
            $INSTALL https://rpms.remirepo.net/enterprise/remi-release-8.rpm
            $INSTALL yum-utils
            yum-config-manager --enable remi-php$(${php_version//./})
            $INSTALL php php-cli php-mysqlnd
        fi
    else
        php_installed=false
    fi
}

# Veritabanı kurulumu
function install_database() {
    read -p "Veritabanı kurulumu yapılsın mı? (e/h): " db_choice
    if [[ "$db_choice" =~ ^[Ee]$ ]]; then
        db_installed=true
        echo -e "${yellow}Veritabanı seçin:${nc}"
        echo "1) MySQL"
        echo "2) MariaDB"
        read -p "Seçiminiz (1/2): " db_selection

        case $db_selection in
            1)
                $INSTALL mysql-server
                systemctl enable mysqld
                systemctl start mysqld
                ;;
            2)
                $INSTALL mariadb-server
                systemctl enable mariadb
                systemctl start mariadb
                ;;
            *)
                echo -e "${red}Geçersiz seçim!${nc}"
                exit 1
                ;;
        esac
    else
        db_installed=false
    fi
}

# Güvenlik duvarı kurulumu
function install_firewall() {
    echo -e "${yellow}Güvenlik duvarı seçiniz:${nc}"
    echo "1) UFW"
    echo "2) FirewallD"
    read -p "Seçiminiz (1/2): " fw_choice

    case $fw_choice in
        1)
            $INSTALL ufw
            ufw allow OpenSSH
            if [[ "$web_server" == "Apache" ]]; then
                ufw allow 'Apache Full'
            else
                ufw allow 'Nginx Full'
            fi
            ufw enable
            ;;
        2)
            $INSTALL firewalld
            systemctl enable firewalld
            systemctl start firewalld
            firewall-cmd --permanent --add-service=ssh
            if [[ "$web_server" == "Apache" ]]; then
                firewall-cmd --permanent --add-service=http
                firewall-cmd --permanent --add-service=https
            else
                firewall-cmd --permanent --add-service=http
                firewall-cmd --permanent --add-service=https
            fi
            firewall-cmd --reload
            ;;
        *)
            echo -e "${red}Geçersiz seçim!${nc}"
            exit 1
            ;;
    esac
}

# Kurulum özeti
function show_summary() {
    echo -e "${cyan}\n===== KURULUM ÖZETİ =====${nc}"
    echo -e "Web sunucusu: ${green}$web_server${nc}"
    if [ "$php_installed" = true ]; then
        echo -e "PHP: ${green}$php_version${nc}"
    else
        echo -e "PHP: ${yellow}Kurulmadı${nc}"
    fi
    if [ "$db_installed" = true ]; then
        echo -e "Veritabanı: ${green}Kuruldu${nc}"
    else
        echo -e "Veritabanı: ${yellow}Kurulmadı${nc}"
    fi
    echo -e "Log dosyası: ${blue}$LOGFILE${nc}"
}

# Ana akış
clear
check_root
check_os
detect_package_manager
update_system
set_timezone
install_web_server
install_php
install_database
install_firewall
show_summary
