#!/bin/bash
#
# Инсталлятор СЗИ ВИ
#
# Объявляем функцию установки
install() {
    echo "Добро пожаловать в мастер установки СЗИ ВИ ИК5"
    echo "Укажите путь расположения установочного файла"
    read path
    echo "Укажите расширение установочного файла RPM или DEB"
    read extension
    echo "Начинаем процедуру установки"
    if [ "$extension" == "rpm" ]; then
        echo "Установка пакета .RPM"
        cd "$path" || { echo "Неверный путь"; exit 1; }
        sudo rpm -i confident-vicored.rpm
    else
        echo "Установка пакета .DEB"
        cd "$path" || { echo "Неверный путь"; exit 1; }
        sudo dpkg -i confident-vicored.deb
    fi
}

# Объявляем функцию сброса ядра
reset_core() {
    echo -e "\033[104m Начинаем процедуру сброса ядра ЦУ СЗИ ВИ к заводским настройкам \033[0m"
    sleep 1
    echo -e "\033[32m Останавливаем службу ядра \033[0m"
    sudo systemctl stop confident-vicored.service
    if [ $? -eq 0 ]; then
        sleep 1
        echo -e "\033[42m Служба остановлена! \033[0m"
    else
        echo -e "\033[41m Ошибка остановки службы ядра \033[0m"
        return
    fi 
    sleep 1
    echo -e "\033[32m Сбрасываем права на папку с ядром \033[0m"
    chmod -R 777 /opt/confident
    if [ $? -eq 0 ]; then
        sleep 1
        echo -e "\033[42m Успешно! \033[0m"
    else
        echo -e "\033[41m Ошибка сброса прав, нет доступа \033[0m"
        return
    fi

    sleep 1
    echo -e "\033[32m Удаляем папку с базой /db/ \033[0m"
    rm -rf /opt/confident/db
    if [ $? -eq 0 ]; then
        sleep 1
        echo -e "\033[42m Успешно! \033[0m"
    else
        echo -e "\033[41m Ошибка удаления папки \033[0m"
        return
    fi

    sleep 1
    echo -e "\033[32m Удаляем папку с журналами /jrn/ \033[0m"
    rm -rf /opt/confident/jrn
    if [ $? -eq 0 ]; then
        sleep 1
        echo -e "\033[42m Успешно! \033[0m"
    else
        echo -e "\033[41m Ошибка удаления папки \033[0m"
        return
    fi

    sleep 1
    echo -e "\033[32m Переходим в каталог с ядром /opt/bin \033[0m"
    cd /opt/confident/bin
    if [ $? -eq 0 ]; then
        sleep 1
        echo -e "\033[42m Успешно! \033[0m"
    else
        echo -e "\033[41m Не могу перейти \033[0m"
        return
    fi

    sleep 1
    echo -e "\033[32m Удаляем файл первого запуска \033[0m"
    rm -rf .6s6Aar0IHK
    if [ $? -eq 0 ]; then
        sleep 1
        echo -e "\033[42m Успешно! \033[0m"
    else
        echo -e "\033[41m Ошибка удаления \033[0m"
        return
    fi

    sleep 1
    echo -e "\033[32m Стартуем ядро \033[0m"
    systemctl start confident-vicored.service
    if [ $? -eq 0 ]; then
        sleep 1
        echo -e "\033[41m Служба ядра успешно запущена! \033[0m"
    else
        echo -e "\033[31m Ошибка запуска службы ядра \033[0m"
        return
    fi

    sleep 1
    echo -e "\033[31m Скрипт завершил свою работу! \033[0m"
}

# Объявляем функцию удаления
remove() {
    echo "Укажите расширение установленного файла RPM или DEB"
    read extension
    echo "Начинаем процедуру удаления"
    if [ "$extension" == "rpm" ]; then
        echo "Удаление пакета .RPM"
        sudo rpm -e confident-vicored
    else
        echo "Удаление пакета .DEB"
        sudo dpkg -r confident-vicored
    fi
}

# Объявляем фцнкцию включения логов
log_start() {
    echo "Добро пожаловать в мастер включения логов ядра ЦУ СЗИ ВИ"
    echo "Создаем файл для включения логгирования"
    touch /tmp/dlneedlog
    if [ $? -eq 0 ]; then
        echo "Успешно создали файл dlneedlog в директории /tmp/"
    else
        echo "Нет доступа, невозможно создать файл dlneedlog для включения логов"
        return
    fi
    echo "Для начала сбора логов необходимо перезапустить службу ядра"
    sudo systemctl restart confident-vicored.service
    if [ $? -eq 0 ]; then
        echo "Служба успешно перезапущена"
    else
        echo "Ошибка остановки службы ядра"
        return
    fi
}

# Объявляем функцию отключения логов
log_stop() {
    echo "Удаляем временный файл dlneedlog"
    rm /tmp/dlneedlog
    if [ $? -eq 0 ]; then
        echo "Успешно удалили файл"
    else
        echo "Нет доступа, невозможно удалить файл dlneedlog"
    echo "Перезапускаем ядро"
    sudo systemctl restart confident-vicored.service
    if [ $? -eq 0 ]; then
        echo "Успешно перезапустили ядро"
    else
        echo "Ошибка остановки службы ядра"
        return
    fi 
}

echo "Выберите, что вы хотите сделать:"
echo "1 - Установить ядро защиты СЗИ ВИ"
echo "2 - Сбросить настройки ядра (вернуть к заводским настройкам)"
echo "3 - Удалить ядро"
echo "4 - Включить логгирование ядра"
echo "5 - Выключить логгирование ядра"
read -r choice

if [[ $choice -eq 1 ]]; then
    install
elif [[ $choice -eq 2 ]]; then
    reset_core
elif [[ $choice -eq 3 ]]; then
    remove
elif [[ $choice -eq 4 ]]; then
    log_start
elif [[ $choice -eq 5 ]]; then
    log_stop
else
    echo "Неправильный выбор"
fi