# Коллективная разработка

Перед отправкой изменений в репозиторий необходимо  установить `eclint` и
добавить скрипт на событие `pre-commit` в `git` (файл `.git/hooks/pre-commit`).
См. [образец файла](contrib/pre-commit). Можно добавить его как ссылку:

    chmod +x contrib/pre-commit
    ln -s $(pwd)/contrib/pre-commit $(pwd)/.git/hooks/pre-commit

Программа `eclint` использует настройки, определённые в файле `.editorconfig`,
чтобы обеспечить соблюдение максимальной длины строк кода, размера отступов и
наличие пустой строки в файлах с кодом.

Установка `eclint`:

    sudo chown -R $USER:$(id -gn $USER) ~/.config
    npm install -g eclint
