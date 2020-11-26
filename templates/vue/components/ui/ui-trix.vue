<template lang="pug">
  div
    input(type='hidden' :name='name' :id='input_id' :value='value')
    trix-editor.trix-content(
      :id='id' :input='input_id' ref='trix'
      data-direct-upload-url='/rails/active_storage/direct_uploads'
      data-blob-url-template='/rails/active_storage/blobs/:signed_id/:filename'
      @trix-change='input'
    )
</template>

<script>
  export default {
    props: ['id', 'name', 'value'],
    emits: ['input'],
    data() {
      return {
        input_id: `${this.id}_trix_input`,
        sync:     true,
      };
    },
    watch: {
      value() {
        if (this.sync) {
          this.$refs.trix.editor.loadHTML(this.value);
          this.sync = false;
        }
      },
    },
    methods: {
      input(event) {
        // Отключить обновление содержимого через `loadHTML`, когда пользователь
        // вводит текст.  Тут используется `bind`, чтобы в инструментах
        // разработчика отображался корректный `this`.
        this.sync = false;
        window.setTimeout(function() {
          this.sync = true;
        }.bind(this), 1);

        this.$emit('input', event.target.value);
      },
    },
  }
</script>
