# Установка

1. Установить Ruby, PostegreSQL, Redis, Yarn.
2. Установить foreman или forego.
3. Установить libxml2 и libxslt1.1.
4. Создать базу данных и пользователя для неё.
5. Выполнить `bin/configs`, сохранить в созданных файлах параметры подключения к базе данных.
6. Выполнить `bin/setup`.

На сервере для `production` необходимо установить переменные среды, указанные
в файлах `.env` или `.env.production`.

## Решение возможных проблем

Если в MacOS 10.15 не удаётся установить `node` или `node-sass`: [node-gyp][1]

[1]: https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md
