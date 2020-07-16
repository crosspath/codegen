<template>
  div
    input(type="hidden" :name="name" :id="input_id" v-model="value")
    trix-editor.trix-content(
      :id="id" :input="input_id"
      data-direct-upload-url="/rails/active_storage/direct_uploads"
      data-blob-url-template="/rails/active_storage/blobs/:signed_id/:filename"
    )
</template>

<script>
  export default {
    data() {
      return {
        input_id: `${this.id}_trix_input`
      };
    },
    props: ['id', 'name', 'value']
  }
</script>
