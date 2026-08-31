<script lang="ts">
export default {
  name: "VisualTestsFormsFileInputStates",
};
</script>

<script lang="ts" setup>
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import storeImage from "@/images/fallback/store_image.webp";
import { type MediaFile } from "@/services/fyApi";
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

/*
 * The other way an image reaches this control, and the one that happens in the
 * app: a persisted file, from which the component reads `smallUrl` itself.
 * `previewSrc` above is the shortcut for a caller that already has a URL.
 */
const savedFile: MediaFile = {
  name: "caterpillar.webp",
  contentType: "image/webp",
  size: 84_233,
  url: storeImage,
  smallUrl: storeImage,
  signedId: "stored-blob-id",
  width: 1920,
  height: 1080,
};
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
        <p class="text-muted">saved — a persisted file</p>
        <FormFileInput
          v-model="saved"
          name="fileSavedFile"
          label="Image"
          :file="savedFile"
          :allowed-types="AllowedFileTypes.IMAGE"
          :allowed-size-mb="5"
          clearable
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">disabled, empty</p>
        <FormFileInput
          v-model="empty"
          name="fileDisabledEmpty"
          label="Image"
          :allowed-types="AllowedFileTypes.IMAGE"
          disabled
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">disabled, saved</p>
        <FormFileInput
          v-model="saved"
          name="fileDisabledSaved"
          label="Image"
          :preview-src="storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          disabled
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
        <p class="text-muted">avatar, saved from a file</p>
        <FormFileInput
          v-model="saved"
          name="fileAvatarSaved"
          label="Avatar"
          :file="savedFile"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
          avatar
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">transparent, empty</p>
        <FormFileInput
          v-model="empty"
          name="fileTransparentEmpty"
          label="Logo"
          :allowed-types="AllowedFileTypes.IMAGE"
          transparent
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
    </div>
    <div class="row">
      <div class="col-12 col-md-6 col-lg-3">
        <p class="text-muted">invalid — required, nothing chosen</p>
        <FormFileInput
          name="missingAvatar"
          label="Avatar"
          :allowed-types="AllowedFileTypes.IMAGE"
          :allowed-size-mb="5"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-6">
        <p class="text-muted">two states no prop reaches</p>
        <p class="text-muted">
          Between empty and saved there is
          <em>dropped here, not yet persisted</em>, driven by
          <code>uploadedHere</code>, which the upload flow sets. And a
          <em>failed upload</em> now shows on the control rather than only in a
          toast. Both need an actual file: drop one on the empty control, and
          disconnect to see the failure.
        </p>
      </div>
    </div>
  </div>
</template>
