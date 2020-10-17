<template lang="pug">
  FormulateForm(v-model='record' @submit='submit_form')
    h2(v-t='"example.header"')
    FormulateInput(
      type='text' name='name' validation='required' :label='$t("name")'
    )
    FormulateInput(
      type='submit' :label='submit_text' class='formulate-input--primary'
    )
</template>

<script>
  import SharedMessages from 'lib/i18n';
  import FormMessages from './example-i18n';

  import Routes from 'lib/routes';

  export default {
    i18n: {
      sharedMessages: SharedMessages,
      messages:       FormMessages,
    },
    props: {
      exampleObject: Object, // {id: ..., name: ..., ...}
    },
    computed: {
      submit_text: function() {
        const key = this.record.id == null ? 'button.add' : 'button.save';
        return this.$t(key);
      },
    },
    data() {
      return {
        record: this.exampleObject,
      };
    },
    methods: {
      submit_form(object) {
        Routes.root(object).then(() => {
          console.log('Success!');
        }).catch((...args) => {
          console.error('Error!', args);
        })
      },
    },
  }
</script>
