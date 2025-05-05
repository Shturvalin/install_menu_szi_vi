#!/bin/bash
#
# Инсталлятор СЗИ ВИ (полностью исправленная версия)
#

# Цветовые переменные
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функция для проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка выполнения команды!${NC}"
        return 1
    fi
}

install() {
    echo -e "${CYAN}Добро пожаловать в мастер установки СЗИ ВИ ИК5${NC}"
    
    # Автопоиск пакета
    detect_package() {
        local pkg=$(find "$HOME" -type f \( -name "*.rpm" -o -name "*.deb" \) -print -quit 2>/dev/null)
        [[ $pkg =~ \.rpm$ ]] && echo "rpm"
        [[ $pkg =~ \.deb$ ]] && echo "deb"
    }

    # Выбор файла
    if command -v zenity >/dev/null && [ -n "$DISPLAY" ]; then
        path=$(zenity --file-selection --title="Выберите установочный файл (RPM/DEB)" --file-filter="*.rpm *.deb")
    elif command -v dialog >/dev/null; then
        path=$(dialog --title "Выбор файла" --fselect "$HOME/" 15 60 3>&1 1>&2 2>&3)
    else
        read -rp "Укажите полный путь к установочному файлу: " path
    fi

    # Валидация файла
    if [ ! -f "$path" ]; then
        echo -e "${RED}Ошибка: файл не найден!${NC}"
        return 1
    fi

    # Определение формата
    extension="${path##*.}"
    if [[ "$extension" != "rpm" && "$extension" != "deb" ]]; then
        echo -e "${RED}Неподдерживаемый формат файла!${NC}"
        return 1
    fi

    # Установка
    echo -e "${YELLOW}Начало установки...${NC}"
    if [ "$extension" == "rpm" ]; then
        sudo rpm -ivh "$path"
    else
        sudo dpkg -i "$path"
    fi
    check_error || return 1

    # Получение IP
    ip_address=$(hostname -I | awk '{print $1}')
    [ -n "$ip_address" ] && echo -e "\n${GREEN}Установка завершена! Веб-интерфейс: ${CYAN}https://$ip_address:4564${NC}"
}

reset_core() {
    echo -e "${BLUE}Сброс ядра к заводским настройкам${NC}"
    
    # Остановка службы
    echo -e "${YELLOW}Остановка службы...${NC}"
    sudo systemctl stop confident-vicored.service
    check_error || return 1

    # Сброс прав
    echo -e "${YELLOW}Сброс разрешений...${NC}"
    sudo chmod -R 755 /opt/confident
    check_error || return 1

    # Удаление данных
    local dirs=("/opt/confident/db" "/opt/confident/jrn")
    for dir in "${dirs[@]}"; do
        echo -e "${YELLOW}Удаление: $dir...${NC}"
        sudo rm -rf "$dir"
        check_error || return 1
    done

    # Удаление файла активации
    echo -e "${YELLOW}Очистка системных файлов...${NC}"
    sudo rm -f /opt/confident/bin/.6s6Aar0IHK
    check_error || return 1

    # Запуск службы
    echo -e "${YELLOW}Запуск службы...${NC}"
    sudo systemctl start confident-vicored.service
    check_error || return 1
    
    echo -e "${GREEN}Сброс успешно завершен!${NC}"
}

remove() {
    echo -e "${RED}УДАЛЕНИЕ СИСТЕМЫ ЗАЩИТЫ${NC}"
    
    # Определение пакета
    if rpm -q confident-vicored &>/dev/null; then
        sudo rpm -e confident-vicored
    elif dpkg -l confident-vicored &>/dev/null; then
        sudo dpkg -r confident-vicored
    else
        echo -e "${YELLOW}Пакет не обнаружен!${NC}"
        return 1
    fi
    check_error || return 1
    
    echo -e "${GREEN}Удаление завершено!${NC}"
}

log_control() {
    case $1 in
        start)
            echo -e "${YELLOW}Вы уверены, что хотите включить логирование? [y/N]${NC}"
            read -r confirm
            if [[ "$confirm" =~ [yY] ]]; then
                sudo touch /tmp/dlneedlog && {
                    echo -e "${GREEN}Логирование включено! Временный файл создан: /tmp/dlneedlog${NC}"
                    sudo systemctl restart confident-vicored.service
                } || echo -e "${RED}Ошибка создания файла!${NC}"
            else
                echo -e "${YELLOW}Отмена операции${NC}"
            fi
            ;;
        stop)
            sudo rm -f /tmp/dlneedlog
            sudo systemctl restart confident-vicored.service
            echo -e "${GREEN}Логирование отключено!${NC}"
            ;;
    esac
    check_error || return 1
}

view_logs() {
    echo -e "${CYAN}Запуск просмотра логов (Ctrl+C для остановки)...${NC}"
    sudo tail -F /etc/confident/vicored.log
    echo -e "\n${YELLOW}Просмотр логов завершен. Возврат в меню...${NC}"
    sleep 2
}

restart_core() {
    echo -e "${YELLOW}Перезапуск службы...${NC}"
    sudo systemctl restart confident-vicored.service
    check_error || return 1
}

status_core() {
    systemctl status confident-vicored.service
    check_error || return 1
}

show_menu() {
    clear
    echo -e "${GREEN}┌─────────────────────────────────┐"
    echo -e "│   ${RED}СИСТЕМА УПРАВЛЕНИЯ СЗИ ВИ${GREEN}     │"
    echo -e "├─────────────────────────────────┤"
    echo -e "│ 1. Установить СЗИ               │"
    echo -e "│ 2. Сброс к заводским настройкам │"
    echo -e "│ 3. Удалить СЗИ                  │"
    echo -e "│ 4. Включить логирование         │"
    echo -e "│ 5. Отключить логирование        │"
    echo -e "│ 6. Перезапустить службу         │"
    echo -e "│ 7. Статус службы                │"
    echo -e "│ 8. Просмотр логов (реалтайм)    │"
    echo -e "│ 9. Выход                        │"
    echo -e "└─────────────────────────────────┘${NC}"
	echo ""
    echo "dev-v2."
}

while true; do
    show_menu
    read -rp "Выберите действие [1-9]: " choice
    case $choice in
        1) install ;;
        2) reset_core ;;
        3) remove ;;
        4) log_control start ;;
        5) log_control stop ;;
        6) restart_core ;;
        7) status_core ;;
        8) view_logs ;;
        9) exit 0 ;;
        *) echo -e "${RED}Неверный выбор!${NC}"; sleep 1 ;;
    esac
    echo -e "\nНажмите Enter для продолжения..."
    read -s
done