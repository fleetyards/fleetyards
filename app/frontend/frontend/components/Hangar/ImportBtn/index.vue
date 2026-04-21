<script lang="ts">
export default {
  name: "HangarImportBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import DirectUpload, {
  type FileUpload,
} from "@/shared/components/DirectUpload/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { hangarImport } from "@/services/fyApi";

type Props = {
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
};

withDefaults(defineProps<Props>(), {
  variant: BtnVariantsEnum.DEFAULT,
  size: BtnSizesEnum.DEFAULT,
});

const { t } = useI18n();

const { displayWarning, displayAlert, displaySuccess, displayConfirm } =
  useAppNotifications();

const disabled = ref(false);

const directUpload = ref<InstanceType<typeof DirectUpload>>();

const selectFile = () => {
  disabled.value = true;

  displayConfirm({
    text: t("messages.confirm.hangar.import"),
    onConfirm: async () => {
      directUpload.value?.$el.querySelector("input[type=file]")?.click();
    },
    onClose: () => {
      disabled.value = false;
    },
  });
};

const emit = defineEmits(["finished"]);

const onUploadDone = async (files: FileUpload[]) => {
  if (!files.length || !files[0].blob) {
    disabled.value = false;
    return;
  }

  try {
    const result = await hangarImport({
      import: files[0].blob.signed_id,
    });

    if (result.missing.length) {
      displayWarning({
        text: t("messages.hangarImport.partialSuccess", {
          missing: `- ${result.missing.join("<br>- ")}`,
        }),
        timeout: false,
      });
    } else {
      displaySuccess({
        text: t("messages.hangarImport.success"),
      });
      emit("finished");
    }
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.hangarImport.failure"),
    });
  }

  directUpload.value?.clear();
  disabled.value = false;
};
</script>

<template>
  <Btn
    :size="size"
    :variant="variant"
    :aria-label="t('actions.import')"
    :disabled="disabled"
    @click="selectFile"
  >
    <i class="fa-light fa-upload" />
    <span>
      {{ t("actions.import") }}
      <DirectUpload
        ref="directUpload"
        class="hangar-importer"
        :multiple="false"
        :allowed-types="['application/json']"
        :direct-upload="true"
        :input-only="true"
        @upload:done="onUploadDone"
      />
    </span>
  </Btn>
</template>
