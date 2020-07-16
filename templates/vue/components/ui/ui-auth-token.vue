<template lang="pug">
  input(type='hidden' :name='name' :value='value')
</template>

<script>
  import { auth_token_name, auth_token_value } from 'common/dom';

  export default {
    data() {
      return {
        name:  auth_token_name(),
        value: auth_token_value(),
      }
    }
  }
</script>
