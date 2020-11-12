# Установка

1. Установить Ruby, PostegreSQL, Redis, Yarn.
2. Установить foreman или forego.
3. Установить libxml2 и libxslt1.1.
4. Создать базу данных и пользователя для неё.
5. Выполнить `bin/configs`, сохранить в созданных файлах параметры подключения
   к базе данных.
6. Выполнить `bundle config --global path vendor/bundle && bin/setup`.
7. Добавить тестовые данные: `rails db:seed`.

На сервере для `production` необходимо установить переменные среды, указанные
в файле `.env.production`.
