<script lang="ts">
export default {
  name: "HangarImportsList",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import ListGroup from "@/shared/components/ListGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import {
  useImports,
  getImportsQueryKey,
  cancelImport,
  ImportStatusEnum,
  type Import,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";

const { t, l } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const RUNNING_STATES: ImportStatusEnum[] = [
  ImportStatusEnum.CREATED,
  ImportStatusEnum.STARTED,
];

const isRunning = (item: Import) => RUNNING_STATES.includes(item.status);

const { data, isLoading } = useImports(undefined, {
  query: {
    // A running import reports through the database, not a socket. Polling
    // stops as soon as nothing on the page is still working, so an idle
    // history costs nothing.
    refetchInterval: (query) => {
      const items = query.state.data?.items ?? [];

      return items.some((item) => isRunning(item)) ? 3000 : false;
    },
  },
});

const items = computed<Import[]>(() => data.value?.items ?? []);

const invalidateImports = () =>
  queryClient.invalidateQueries({ queryKey: getImportsQueryKey() });

const confirmCancel = (item: Import) => {
  displayConfirm({
    text: t("messages.confirm.import.cancel"),
    onConfirm: async () => {
      try {
        await cancelImport(item.id);
        void invalidateImports();
        displaySuccess({ text: t("messages.imports.cancel.success") });
      } catch {
        displayAlert({ text: t("messages.imports.cancel.error") });
      }
    },
  });
};

const typeLabel = (item: Import) => t(`labels.imports.types.${item.type}`);

const statusLabel = (item: Import) =>
  t(`labels.imports.statuses.${item.status}`);

const statusTone = (item: Import) => {
  switch (item.status) {
    case ImportStatusEnum.FINISHED:
      return "import-status--finished";
    case ImportStatusEnum.FAILED:
      return "import-status--failed";
    case ImportStatusEnum.CANCELLED:
      return "import-status--cancelled";
    default:
      return "import-status--running";
  }
};

// `output` is free-form per import type; only the counts both types agree on
// are read here.
const summary = (item: Import) => {
  const output = item.output as Record<string, unknown> | undefined;

  if (!output) return null;

  const counted = (key: string) => {
    const value = output[key];

    return Array.isArray(value) ? value.length : undefined;
  };

  const parts = [
    ["imported", counted("imported") ?? counted("importedVehicles")],
    ["missing", counted("missing") ?? counted("missingModels")],
    ["found", counted("foundVehicles")],
  ] as const;

  const listed = parts
    .filter(([, count]) => count !== undefined && count > 0)
    .map(([key, count]) => `${t(`labels.imports.summary.${key}`)}: ${count}`);

  return listed.length ? listed.join(" · ") : null;
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar.index') }]"
  />

  <Heading hero>{{ t("headlines.hangar.imports") }}</Heading>

  <p class="imports-intro">{{ t("labels.imports.intro") }}</p>

  <ListGroup :items="items" :loading="isLoading" empty-name="imports">
    <template #display="{ item }">
      <div class="import-info">
        <span class="import-type">{{ typeLabel(item) }}</span>

        <div class="import-meta">
          <span class="import-status" :class="statusTone(item)">
            {{ statusLabel(item) }}
          </span>

          <span class="import-meta-item">
            {{ l(item.createdAt) }}
          </span>

          <span v-if="item.hangarGroup" class="import-meta-item">
            <i class="fa-duotone fa-layer-group" />
            {{ item.hangarGroup.name }}
          </span>

          <span v-if="summary(item)" class="import-meta-item">
            {{ summary(item) }}
          </span>
        </div>

        <p v-if="item.info" class="import-info-text">{{ item.info }}</p>
      </div>
    </template>

    <template #actions="{ item }">
      <Btn
        v-if="isRunning(item)"
        :tone="BtnTonesEnum.DANGER"
        :aria-label="t('actions.imports.cancel')"
        data-test="import-cancel"
        @click="confirmCancel(item)"
      >
        <i class="fa-duotone fa-ban" />
        <span>{{ t("actions.imports.cancel") }}</span>
      </Btn>
    </template>
  </ListGroup>
</template>

<style lang="scss" scoped>
.imports-intro {
  margin-bottom: 1rem;
  color: var(--text-muted);
}

.import-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 0;
}

.import-type {
  font-weight: 600;
}

.import-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
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
  margin: 0;
  color: var(--color-danger);
  font-size: 0.875rem;
}
</style>
