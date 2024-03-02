<template>
  <div
    :class="{ 'has-error has-feedback': errors[0] }"
    class="form-group mb-3"
    @input="updatedValue"
    @input-filter="inputFilter"
  >
    <VueUploadComponent
      ref="upload"
      :value="files"
      name="uploadAvatar"
      :extensions="fileExtensions"
      :accept="acceptedMimeTypes"
      class="avatar-uploader"
      @input="updatedValue"
      @input-filter="inputFilter"
    />
    <Avatar
      :avatar="avatarUrl"
      size="large"
      :editable="true"
      @upload="selectAvatar"
      @destroy="removeAvatar"
    />
  </div>
</template>

<script lang="ts" setup>
import VueUploadComponent from "vue-upload-component";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
</script>

<script lang="ts">
export default {
  name: "FormFileInput",
};
</script>
