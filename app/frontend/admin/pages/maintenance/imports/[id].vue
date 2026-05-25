<script lang="ts">
export default {
  name: "MaintenanceImportDetailPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import {
  useImport,
  type Import,
  ImportStatusEnum,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";

const route = useRoute();

const { t, l } = useI18n();

const { data: importRecord, ...asyncStatus } = useImport(
  route.params.id as string,
);

const formatType = (type: string): string =>
  type
    .replace("Imports::", "")
    .replace("::", " ")
    .replace(/([A-Z])/g, " $1")
    .replace(/^ /, "")
    .trim();

const statusVariant = (
  status: ImportStatusEnum,
): "default" | "success" | "warning" | "danger" => {
  switch (status) {
    case ImportStatusEnum.FINISHED:
      return "success";
    case ImportStatusEnum.FAILED:
      return "danger";
    case ImportStatusEnum.STARTED:
      return "warning";
    default:
      return "default";
  }
};

const formatPayload = (value: string | undefined | null): string | null => {
  if (value === undefined || value === null || value === "") return null;
  try {
    return JSON.stringify(JSON.parse(value), null, 2);
  } catch {
    return value;
  }
};

const inputPayload = computed(() => formatPayload(importRecord.value?.input));
const outputPayload = computed(() => formatPayload(importRecord.value?.output));
const importDataPayload = computed(() =>
  formatPayload(importRecord.value?.importData),
);

const metaRows = computed(() => {
  const record = importRecord.value;
  if (!record) return [];

  const rows: { label: string; value: string }[] = [
    { label: t("labels.imports.type"), value: formatType(record.type) },
  ];

  if (record.version) {
    rows.push({ label: t("labels.imports.version"), value: record.version });
  }

  rows.push({
    label: t("labels.createdAt"),
    value: l(record.createdAt, "datetime.formats.short"),
  });

  if (record.startedAt) {
    rows.push({
      label: t("labels.imports.startedAt"),
      value: l(record.startedAt, "datetime.formats.short"),
    });
  }

  if (record.finishedAt) {
    rows.push({
      label: t("labels.imports.finishedAt"),
      value: l(record.finishedAt, "datetime.formats.short"),
    });
  }

  if (record.failedAt) {
    rows.push({
      label: t("labels.imports.failedAt"),
      value: l(record.failedAt, "datetime.formats.short"),
    });
  }

  return rows;
});

const headlineTitle = (record: Import) => formatType(record.type);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <template v-if="importRecord">
        <BreadCrumbs
          :crumbs="[
            {
              to: { name: 'imports' },
              label: t('headlines.admin.imports.index'),
            },
            { label: headlineTitle(importRecord) },
          ]"
        />
        <Heading hero>
          {{ headlineTitle(importRecord) }}
        </Heading>

        <div class="import-detail">
          <div class="import-detail__meta">
            <div class="import-detail__status">
              <BasePill :variant="statusVariant(importRecord.status)" uppercase>
                {{ t(`labels.imports.statuses.${importRecord.status}`) }}
              </BasePill>
            </div>
            <dl class="import-detail__meta-list">
              <template v-for="row in metaRows" :key="row.label">
                <dt>{{ row.label }}</dt>
                <dd>{{ row.value }}</dd>
              </template>
            </dl>
            <div v-if="importRecord.info" class="import-detail__info">
              <h3>{{ t("labels.imports.info") }}</h3>
              <pre>{{ importRecord.info }}</pre>
            </div>
            <div v-if="importRecord.import" class="import-detail__file">
              <h3>{{ t("labels.imports.file") }}</h3>
              <a :href="importRecord.import" target="_blank" rel="noopener">
                {{ t("actions.open") }}
              </a>
            </div>
          </div>

          <div v-if="inputPayload" class="import-detail__payload">
            <h3>{{ t("labels.imports.input") }}</h3>
            <pre>{{ inputPayload }}</pre>
          </div>

          <div v-if="outputPayload" class="import-detail__payload">
            <h3>{{ t("labels.imports.output") }}</h3>
            <pre>{{ outputPayload }}</pre>
          </div>

          <div v-if="importDataPayload" class="import-detail__payload">
            <h3>{{ t("labels.imports.importData") }}</h3>
            <pre>{{ importDataPayload }}</pre>
          </div>
        </div>
      </template>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.import-detail {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;

  &__status {
    margin-bottom: 0.75rem;
  }

  &__meta-list {
    display: grid;
    grid-template-columns: max-content 1fr;
    gap: 0.25rem 1rem;
    margin: 0;

    dt {
      font-weight: 600;
      opacity: 0.7;
    }

    dd {
      margin: 0;
    }
  }

  &__info pre,
  &__payload pre {
    background: rgba(0, 0, 0, 0.3);
    padding: 0.75rem 1rem;
    border-radius: 4px;
    overflow: auto;
    max-height: 600px;
    font-size: 0.85rem;
    white-space: pre-wrap;
    word-break: break-word;
  }

  h3 {
    font-size: 1rem;
    margin: 0 0 0.5rem;
  }
}
</style>
