import { ready } from 'lib/dom';

import Vue from 'vue/dist/vue.esm';

// Добавление файлов с кодом компонентов Vue. Пример:
// import UserButton from 'components/buttons/user_button.vue';

// Регистрация тегов для компонентов Vue. Пример:
// Vue.component('user-button', UserButton);

ready(() => {
  // Все узлы DOM, для которых нужно создать экземпляр компонента Vue,
  // должны содержать атрибут `vue` (его значение не важно), чтобы найти их
  // во время загрузки страницы. Если нужно какое-то другое условие поиска
  // узлов, то его можно задать в вызове `querySelectorAll`.
  const elements = document.querySelectorAll('[vue]');
  for (const el of elements)
    new Vue({el: el});
});
