<script lang="ts">
export default {
  name: "HangarImportModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import DirectUpload, {
  type FileUpload,
} from "@/shared/components/DirectUpload/index.vue";
import HangarGroupsSelect from "@/frontend/components/base/HangarGroupsSelect/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useRouter } from "vue-router";
import { useHangarImport } from "@/services/fyApi";

const { t } = useI18n();

const comlink = useComlink();

const router = useRouter();

const { displayAlert, displayInfo } = useAppNotifications();

const hangarGroupId = ref<string | undefined>(undefined);

const submitting = ref(false);

const directUpload = ref<InstanceType<typeof DirectUpload>>();

const { mutateAsync } = useHangarImport();

const selectFile = () => {
  directUpload.value?.$el.querySelector("input[type=file]")?.click();
};

const onUploadDone = async (files: FileUpload[]) => {
  if (!files.length || !files[0].blob) {
    return;
  }

  submitting.value = true;

  try {
    await mutateAsync({
      data: {
        import: files[0].blob.signed_id,
        hangarGroupId: hangarGroupId.value,
      },
    });

    comlink.emit("close-modal");

    // The import is a background job now, so there is no result to show here.
    // The history view is where it reports what it did.
    displayInfo({ text: t("messages.hangarImport.queued") });

    await router.push({ name: "hangar-imports" });
  } catch (error) {
    console.error(error);

    displayAlert({ text: t("messages.hangarImport.failure") });
  } finally {
    directUpload.value?.clear();
    submitting.value = false;
  }
};
</script>

<template>
  <Modal :title="t('headlines.hangar.import')">
    <p class="hint">
      <i class="fa-light fa-info-circle" />
      {{ t("labels.imports.formatHint") }}
    </p>

    <ul class="import-formats">
      <li>
        {{ t("labels.imports.formats.fleetyards") }}
      </li>
      <li>
        {{ t("labels.imports.formats.hangarXplor") }}
        <a href="/examples/hangar-xplor-example.json" download>
          <i class="fa-light fa-download" />
          {{ t("actions.imports.downloadExample") }}
        </a>
      </li>
    </ul>

    <p class="hint">
      <i class="fa-light fa-info-circle" />
      {{ t("labels.imports.targetGroupHint") }}
    </p>

    <HangarGroupsSelect
      v-model="hangarGroupId"
      name="hangarGroupId"
      :multiple="false"
      :no-label="false"
    />

    <DirectUpload
      ref="directUpload"
      class="hangar-importer"
      :multiple="false"
      :allowed-types="['application/json']"
      :direct-upload="true"
      :input-only="true"
      @upload:done="onUploadDone"
    />

    <template #footer>
      <div class="modal-actions">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LG"
          data-test="hangar-import-select-file"
          @click="selectFile"
        >
          {{ t("actions.selectFile") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.import-formats {
  margin: 0 0 1rem;
  padding-left: 1.25rem;
  color: var(--text-muted);

  li + li {
    margin-top: 0.25rem;
  }

  a {
    margin-left: 0.5rem;
    white-space: nowrap;
  }
}
</style>
