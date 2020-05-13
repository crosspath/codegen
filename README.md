# Шаблоны проектов на Rails

Создание папки с проектом:

    rails new app_name --rc=minimum.rc
    rails new app_name --rc=default.rc

Применение к существующей папке:

    rails app:template LOCATION=capistrano.rb
    rails app:template LOCATION=redis.rb
    rails app:template LOCATION=svelte.rb
    rails app:template LOCATION=vue.rb
