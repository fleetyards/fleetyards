<script lang="ts">
export default {
  name: "ItemViewsFields",
};
</script>

<script lang="ts" setup>
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { type ItemMedia } from "@/services/fyAdminApi";

// No v-model: each input registers itself with the surrounding form by name,
// so the page's own `useForm` submits these alongside its other fields.
interface Props {
  media?: ItemMedia;
}

defineProps<Props>();

const VIEW_FIELDS = [
  "topView",
  "portView",
  "frontView",
  "angledView",
  "angledRearView",
  "bottomView",
  "rearView",
  "starboardView",
] as const satisfies readonly (keyof ItemMedia)[];
</script>

<template>
  <div class="row">
    <div class="col-12 col-sm-6 col-md-3">
      <FormFileInput
        :file="media?.holo"
        translation-key="model.holo"
        name="holo"
        :allowed-types="AllowedFileTypes.HOLO"
        clearable
      />
    </div>
  </div>
  <div class="row">
    <div
      v-for="field in VIEW_FIELDS"
      :key="field"
      class="col-12 col-sm-6 col-md-3"
    >
      <FormFileInput
        :file="media?.[field]"
        :translation-key="`model.${field}`"
        :name="field"
        :allowed-types="AllowedFileTypes.IMAGE"
        transparent
        clearable
      />
    </div>
  </div>
</template>
