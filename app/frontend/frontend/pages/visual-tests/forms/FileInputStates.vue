<script lang="ts">
export default {
  name: "VisualTestsFormsFileInputStates",
};
</script>

<script lang="ts" setup>
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import storeImage from "@/images/fallback/store_image.webp";
import { useForm } from "vee-validate";

/*
 * `previewSrc` is how a value that already exists reaches this control: the
 * component's own comment says the upload that filled it happened elsewhere, so
 * it has no local file to show and renders the preview instead. That is the
 * saved state.
 *
 * The state between the two -- a file dropped here but not yet persisted -- is
 * not reachable from props. `uploadedHere` is set by the upload flow itself, so
 * the only way to see it is to drop a file on the empty control.
 */
const { validate } = useForm({
  validationSchema: { missingAvatar: "required" },
  initialValues: { missingAvatar: null },
});

// Validated up front so the invalid state is visible without interaction,
// the way ErrorStates does it.
onMounted(async () => {
  await validate();
});

const saved = ref<string | null>("stored-blob-id");

const empty = ref<string | null>(null);
</script>

<template>
  <div data-test="file-input-states">
    <div class="row">
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">empty</p>
        <FormFileInput
          v-model="empty"
          name="fileEmpty"
          label="Image"
          :allowed-types="AllowedFileTypes.IMAGE"
          :allowed-size-mb="5"
          clearable
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">saved — a value from elsewhere</p>
        <FormFileInput
          v-model="saved"
          name="fileSaved"
          label="Image"
          :preview-src="storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          :allowed-size-mb="5"
          clearable
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">saved, disabled</p>
        <FormFileInput
          v-model="saved"
          name="fileDisabled"
          label="Image"
          :preview-src="storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          disabled
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">invalid — required, nothing chosen</p>
        <FormFileInput
          name="missingAvatar"
          label="Avatar"
          :allowed-types="AllowedFileTypes.IMAGE"
          :allowed-size-mb="5"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">avatar, empty</p>
        <FormFileInput
          v-model="empty"
          name="fileAvatarEmpty"
          label="Avatar"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
          avatar
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">avatar, saved</p>
        <FormFileInput
          v-model="saved"
          name="fileAvatarSaved"
          label="Avatar"
          :preview-src="storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
          avatar
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">transparent, saved</p>
        <FormFileInput
          v-model="saved"
          name="fileTransparent"
          label="Logo"
          :preview-src="storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          transparent
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">not settable from props</p>
        <p class="text-muted">
          Drop a file on the empty control above to see the state between the
          two: uploaded here, not yet saved. It is driven by
          <code>uploadedHere</code>, which the upload flow sets, so no prop
          reaches it.
        </p>
      </div>
    </div>
  </div>
</template>
