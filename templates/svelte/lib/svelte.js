import { ready } from 'lib/dom';

import components from 'lib/svelte-components';

function props(element) {
  return Object.fromEntries(
    Object.values(element.attributes).map(v => [v.name, v.value])
  );
}

ready(() => {
  // Все узлы DOM, для которых нужно создать экземпляр компонента Svelte,
  // должны содержать атрибут `svelte` (его значение не важно), чтобы найти их
  // во время загрузки страницы. Если нужно какое-то другое условие поиска
  // узлов, то его можно задать в вызове `querySelectorAll`.
  const elements = document.querySelectorAll('[svelte]');
  for (const el of elements) {
    const tag = el.tagName.toLowerCase();
    const component = components[tag];
    if (component)
      new component({target: el, props: props(el)});
    else
      console.error(`Unknown Svelte component for ${tag}`);
  }
});
