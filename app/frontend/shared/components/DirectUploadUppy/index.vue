<script lang="ts">
export default {
  name: "DirectUploadUppy",
};
</script>

<script lang="ts" setup>
import { DashboardModal } from "@uppy/vue";
import Uppy from "@uppy/core";

import "@uppy/core/dist/style.css";
import "@uppy/dashboard/dist/style.css";
import AwsS3, { type AwsBody } from "@uppy/aws-s3";

type Meta = { license: string; key: string };

const uppy = new Uppy<Meta, AwsBody>({
  // restrictions: { maxNumberOfFiles: 1 },
}).use(AwsS3, { endpoint: "" });

const open = ref(false);

const handleClose = () => {
  open.value = false;
};
</script>

<template>
  <button type="button" @click="open = !open">Upload</button>
  <DashboardModal
    :uppy="uppy"
    :open="open"
    :props="{
      onRequestCloseModal: handleClose,
      theme: 'dark',
    }"
  />
</template>

<style lang="scss" scoped>
@import "index";
</style>
