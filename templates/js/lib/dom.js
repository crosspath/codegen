export function ready(fn) {
  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', fn);
  else
    fn();
}

export function auth_token_name() {
  return document.querySelector('meta[name="csrf-param"]').content;
}

export function auth_token_value() {
  return document.querySelector('meta[name="csrf-token"]').content;
}
