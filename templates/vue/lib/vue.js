import { ready } from 'lib/dom';

import 'lib/formulate';
import components from 'lib/vue-components';

import Vue from 'vue/dist/vue.esm';
import VueI18n from 'vue-i18n';

Vue.use(VueI18n);

const vue_i18n = new VueI18n({locale: 'ru'});

for (const key in components)
  Vue.component(key, components[key]);

ready(() => {
  // Все узлы DOM, для которых нужно создать экземпляр компонента Vue,
  // должны содержать атрибут `vue` (его значение не важно), чтобы найти их
  // во время загрузки страницы. Если нужно какое-то другое условие поиска
  // узлов, то его можно задать в вызове `querySelectorAll`.
  const elements = document.querySelectorAll('[vue]');
  for (const el of elements)
    new Vue({el: el, i18n: vue_i18n});
});
