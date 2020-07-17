# Шаблоны проектов на Rails

Создание папки с проектом:

    rails new app_name --rc=minimum.rc
    rails new app_name --rc=default.rc

Применение к существующей папке:

    rails app:template LOCATION=capistrano.rb
    rails app:template LOCATION=redis.rb
    rails app:template LOCATION=svelte.rb
    rails app:template LOCATION=vue.rb

## Доступные методы для генератора

1. [Thor::Actions](https://rdoc.info/github/erikhuda/thor/master/Thor/Actions)
2. `gems/railties-*/lib/rails/generators/base.rb`

## Тестирование генератора

Пересоздание папки с кодом проекта, сохраняя `node_modules` и `vendor`
(для папки `app_name`):

    mkdir backup__app_name
    mv app_name/node_modules backup__app_name/node_modules
    mv app_name/vendor backup__app_name/vendor
    rm -rf app_name
    mkdir app_name
    ln -s $(pwd)/backup__app_name/node_modules $(pwd)/app_name/node_modules
    ln -s $(pwd)/backup__app_name/vendor $(pwd)/app_name/vendor
    rails new app_name --rc=codegen/minimum.rc
