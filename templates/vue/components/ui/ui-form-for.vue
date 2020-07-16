<template lang="pug">
  FormulateForm(
    method='post' :action='form_url' ref='formElement'
    :formulate-value='value' @input='updateValue' @submit='submitForm'
  )
    input(
      v-if="!new_record"
      type='hidden' name='_method' value='put'
    )
    AuthToken

    slot
</template>

<script>
  import AuthToken from 'components/ui/ui-auth-token';

  export default {
    components: { AuthToken },
    props: {
      postUrl: Function, // () -> String
      putUrl:  Function, // (id) -> String
      value:   Object,   // {id: ..., ...}
    },
    data() {
      return {
        record: this.value
      };
    },
    computed: {
      new_record() {
        return this.value?.id == null;
      },
      form_url() {
        return this.new_record ? this.postUrl() : this.putUrl(this.value.id);
      },
    },
    methods: {
      updateValue(object) {
        this.$emit('input', object);
      },

      // Если добавлен обработчик `submit`, то передать ему полученный объект,
      // иначе отправить форму обычным способом.
      //
      submitForm(object) {
        if (this.$listeners.submit)
          this.$emit('submit', object);
        else
          this.$refs.formElement.$el.submit();
      }
    },
  }
</script>
