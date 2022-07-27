#!/bin/bash

# Папка, в которой работаем, по умолчанию /opt/code-server
export DIR=/opt/code-server
# Репозиторий, откуда клонировать задачи (обязательно)
export REPO=ssh://git@...
# Докер-образ, по умолчанию code-server:local
export IMAGE=code-server:local
# Имя для контейнера, по умолчанию code-server
export CONTAINER=code-server
# Локальный порт для контейнера, по умолчанию 8080
export BIND_PORT=8080
# Локальный адрес для контейнера, по умолчанию 127.0.0.1
# Можно явно указать 0.0.0.0
export BIND_IP=127.0.0.1
# На каком уровне использовать пароль:
# - basic - HTTP Basic авторизация с помощью nginx (по умолчанию)
# - app - пароль на уровне самого приложения code-server
# - none - никакой аутентификации
export PWD_LEVEL=basic
# Пользователь для HTTP Basic авторизации (по умолчанию coder)
export BASIC_USER=coder

# Параметры для генерации ссылки
# Схема: https или http (по умолчанию)
export CODE_SERVER_SCHEME=https
# Домен (по умолчанию 127.0.0.1)
export CODE_SERVER_DOMAIN=code-server.example.com
# Порт (по умолчанию 80 для http и 443 для https). Если не используется nginx, то можно просто продублировать BIND_PORT
export CODE_SERVER_PORT=443
