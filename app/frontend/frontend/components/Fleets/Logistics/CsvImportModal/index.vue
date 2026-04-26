<script lang="ts">
export default {
  name: "FleetLogisticsCsvImportModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { type Fleet, type FleetInventory } from "@/services/fyApi";
import { axiosClient } from "@/services/axiosClient";

type Props = {
  fleet: Fleet;
  inventory: FleetInventory;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const selectedFile = ref<File | null>(null);
const importing = ref(false);
const results = ref<{
  imported: number;
  errors: { row: number; message: string }[];
} | null>(null);

const onFileChange = (event: Event) => {
  const target = event.target as HTMLInputElement;
  selectedFile.value = target.files?.[0] ?? null;
  results.value = null;
};

const downloadTemplate = () => {
  const csv =
    "name,category,quantity,unit,notes\nQuantanium,commodity,100,scu,From mining run\nMedical Supplies,consumable,50,units,";
  const blob = new Blob([csv], { type: "text/csv" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "inventory_template.csv";
  a.click();
  URL.revokeObjectURL(url);
};

const importCsv = async () => {
  if (!selectedFile.value) return;

  importing.value = true;

  const formData = new FormData();
  formData.append("file", selectedFile.value);

  try {
    const response = (await axiosClient({
      url: `/fleets/${props.fleet.slug}/inventories/${props.inventory.slug}/items/import`,
      method: "POST",
      data: formData,
      headers: { "Content-Type": "multipart/form-data" },
    })) as {
      data: { imported: number; errors: { row: number; message: string }[] };
    };

    results.value = response.data;

    if (results.value.imported > 0) {
      displaySuccess({
        text: t("messages.fleets.logistics.csvImport.success", {
          count: results.value.imported,
        }),
      });
      comlink.emit("fleet-inventory-item-created");
    }

    if (results.value.errors.length === 0) {
      comlink.emit("close-modal");
    }
  } catch {
    displayAlert({
      text: t("messages.fleets.logistics.csvImport.failure"),
    });
  } finally {
    importing.value = false;
  }
};
</script>

<template>
  <Modal :title="t('headlines.fleets.logistics.importCsv')">
    <p class="text-muted">
      {{ t("labels.fleets.logistics.csvImportHelp") }}
    </p>

    <Btn size="small" :inline="true" @click="downloadTemplate">
      <i class="fa-duotone fa-download" />
      {{ t("actions.fleets.logistics.downloadTemplate") }}
    </Btn>

    <hr />

    <div class="mb-3">
      <input
        type="file"
        accept=".csv"
        class="form-control"
        @change="onFileChange"
      />
    </div>

    <template v-if="results">
      <div v-if="results.imported > 0" class="mb-2 text-success">
        {{ results.imported }} {{ t("labels.fleets.logistics.imported") }}
      </div>
      <div v-if="results.errors.length > 0" class="mb-2">
        <p class="text-danger">
          {{ results.errors.length }}
          {{ t("labels.fleets.logistics.importErrors") }}:
        </p>
        <ul class="text-danger small">
          <li v-for="(error, i) in results.errors" :key="i">
            Row {{ error.row }}: {{ error.message }}
          </li>
        </ul>
      </div>
    </template>

    <Btn
      :disabled="!selectedFile || importing"
      :loading="importing"
      @click="importCsv"
    >
      {{ t("actions.fleets.logistics.importCsv") }}
    </Btn>
  </Modal>
</template>
