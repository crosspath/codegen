import axios from 'axios';
import rest  from 'axios-rest-client';

import { ready, auth_token_value } from 'lib/dom';

ready(() => {
  axios.defaults.headers.common['X-CSRF-Token'] = auth_token_value();
});

// @see https://github.com/eldomagan/axios-rest
export const api = rest({
  // Общая часть URL для всех запросов к API
  baseUrl: '/api'
});

// Список ресурсов. Каждый ресурс представлен пятью маршрутами. Пример:
// 1. `all()`           — GET /users
// 2. `find(1)`         — GET /users/1
// 3. `create(data)`    — POST /users [data]
// 4. `update(1, data)` — PUT /users/1 [data]
// 5. `delete(1)`       — DELETE /users/1

api.endpoints({
  // users: 'users',          // ресурс `/users`
  // posts: 'post-resources'  // ресурс `/post-resources`
});

// Не обязательно регистрировать ресурсы. При первом обращении к ресурсу он
// будет зарегистрирован с адресом, соответствующем названию ресурса, пример:
// api.articles — ресурс `/articles`

// Можно добавить маршруты не по REST. Пример:
// api.users.request_invitation = function(...) { ... }
