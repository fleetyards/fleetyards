<script lang="ts">
export default {
  name: "HangarImport",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import ImportDetails from "@/frontend/components/Hangar/ImportDetails/index.vue";
import { useImport, ImportStatusEnum } from "@/services/fyApi";

const { t, l } = useI18n();

const route = useRoute();

const importId = computed(() => String(route.params.id));

const RUNNING_STATES: ImportStatusEnum[] = [
  ImportStatusEnum.CREATED,
  ImportStatusEnum.STARTED,
];

// A sync linked from its modal is usually still running: the page follows it
// until it ends.
const { data: record } = useImport(importId, {
  query: {
    refetchInterval: (query) =>
      query.state.data && RUNNING_STATES.includes(query.state.data.status)
        ? 3000
        : false,
  },
});

const statusTone = computed(() => {
  switch (record.value?.status) {
    case ImportStatusEnum.FINISHED:
      return "import-status--finished";
    case ImportStatusEnum.FAILED:
      return "import-status--failed";
    case ImportStatusEnum.CANCELLED:
      return "import-status--cancelled";
    default:
      return "import-status--running";
  }
});
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      { to: { name: 'hangar' }, label: t('nav.hangar.index') },
      { to: { name: 'hangar-imports' }, label: t('nav.hangar.imports') },
    ]"
  />

  <Heading hero>
    {{
      record
        ? t(`labels.imports.types.${record.type}`)
        : t("headlines.hangar.imports")
    }}
  </Heading>

  <div v-if="record" class="import-meta" data-test="import-meta">
    <span class="import-status" :class="statusTone">
      {{ t(`labels.imports.statuses.${record.status}`) }}
    </span>
    <span>{{ l(record.createdAt) }}</span>
    <span v-if="record.hangarGroup">
      <i class="fa-duotone fa-layer-group" />
      {{ record.hangarGroup.name }}
    </span>
  </div>

  <p v-if="record?.info" class="import-info-text">{{ record.info }}</p>

  <ImportDetails :import-id="importId" />
</template>

<style lang="scss" scoped>
.import-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
  color: var(--text-muted);
  font-size: 0.875rem;
}

.import-status {
  text-transform: uppercase;
  font-size: 0.75rem;
  letter-spacing: 0.04em;
}

.import-status--running {
  color: var(--color-warning);
}

.import-status--finished {
  color: var(--color-success);
}

.import-status--failed {
  color: var(--color-danger);
}

.import-status--cancelled {
  color: var(--text-muted);
}

.import-info-text {
  margin: 0 0 1rem;
  color: var(--color-danger);
  font-size: 0.875rem;
}
</style>
