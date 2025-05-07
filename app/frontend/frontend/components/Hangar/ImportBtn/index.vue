<script lang="ts">
export default {
  name: "HangarImportBtn",
};
</script>

<script lang="ts" setup>
import VueUploadComponent from "vue-upload-component";
import type { VueUploadItem } from "vue-upload-component";
import Btn from "@/shared/components/base/Btn/index.vue";
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

const { displayWarning, displayAlert, displaySuccess } = useAppNotifications();

const fileExtensions = "json";
const acceptedMimeTypes = "application/json";

const disabled = ref(false);

const fileExtensionsList = computed(() => {
  return fileExtensions.split(",");
});

const upload = ref<InstanceType<typeof VueUploadComponent> | undefined>();

const selectFile = () => {
  disabled.value = true;

  displayConfirm({
    text: t("messages.confirm.hangar.import"),
    onConfirm: async () => {
      upload.value?.$el.querySelector("input").click();
    },
    onCancel: () => {
      disabled.value = false;
    },
  });
};

const inputFilter = (
  newFile: VueUploadItem,
  oldFile: VueUploadItem,
  prevent: () => void,
) => {
  if (newFile && !oldFile) {
    if (
      !fileExtensionsList.value.some((extension) =>
        newFile.name?.endsWith(extension),
      )
    ) {
      displayAlert({
        text: t("messages.hangarImport.invalidExtension", {
          extensions: fileExtensions,
        }),
      });
      return prevent();
    }
  }
  if (newFile && (!oldFile || newFile.file !== oldFile.file)) {
    // eslint-disable-next-line no-param-reassign
    newFile.url = "";
    const URL = window.URL || window.webkitURL;
    if (URL && URL.createObjectURL && newFile.file) {
      // eslint-disable-next-line no-param-reassign
      newFile.url = URL.createObjectURL(newFile.file);
    }
  }

  return null;
};

const emit = defineEmits(["finished"]);

const importJson = async (value: VueUploadItem) => {
  const importFile = (value && value[0]) || {};

  if (!importFile || !importFile.file) {
    return;
  }

  try {
    const result = await hangarImport({
      import: importFile.file,
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
    <i class="fal fa-upload" />
    <span>
      {{ t("actions.import") }}
      <VueUploadComponent
        ref="upload"
        name="uploadAvatar"
        :extensions="fileExtensions"
        :accept="acceptedMimeTypes"
        class="hangar-importer"
        @input="importJson"
        @input-filter="inputFilter"
      />
    </span>
  </Btn>
</template>
