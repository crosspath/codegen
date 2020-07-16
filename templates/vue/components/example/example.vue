<template lang="pug">
  FormFor(:post-url='Routes.root' :put-url='Routes.root' v-model='record')
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

  import FormFor from 'components/ui/ui-form-for';

  export default {
    i18n: {
      sharedMessages: SharedMessages,
      messages:       FormMessages,
    },
    components: { FormFor },
    data() {
      return {
        Routes: Routes,
        record: this.exampleObject,
      };
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
  }
</script>
