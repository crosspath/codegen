import { ready } from 'lib/dom';

// Добавление файлов с кодом компонентов Svelte. Пример:
// import UserButton from 'components/buttons/user_button.svelte';

// Регистрация тегов для компонентов Svelte.
const COMPONENTS = {
  // Пример:
  // "user-button": UserButton,
};

ready(() => {
  // Все узлы DOM, для которых нужно создать экземпляр компонента Svelte,
  // должны содержать атрибут `svelte` (его значение не важно), чтобы найти их
  // во время загрузки страницы. Если нужно какое-то другое условие поиска
  // узлов, то его можно задать в вызове `querySelectorAll`.
  const elements = document.querySelectorAll('[svelte]');
  for (const el of elements) {
    const tag = el.tagName.toLowerCase();
    const component = COMPONENTS[tag];
    if (component)
      new component({target: el, props: el.dataset});
    else
      console.error(`Unknown Svelte component for ${tag}`);
  }
});
