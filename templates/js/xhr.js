import axios from 'axios';

import { ready, auth_token_value } from 'lib/dom';

ready(() => {
  axios.defaults.headers.common['X-CSRF-Token'] = auth_token_value();
});
