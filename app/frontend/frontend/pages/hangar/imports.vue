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
import Paginator from "@/shared/components/Paginator/index.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import {
  useImports,
  useImport,
  getImportsQueryKey,
  cancelImport,
  ImportStatusEnum,
  type Import,
  type ImportDetails,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";

const { t, l } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const RUNNING_STATES: ImportStatusEnum[] = [
  ImportStatusEnum.CREATED,
  ImportStatusEnum.STARTED,
];

const isRunning = (item: Import) => RUNNING_STATES.includes(item.status);

// Declared before the pagination it reads: both sides are computed, so the
// forward reference resolves on first access rather than at definition.
const queryKey = computed(() => getImportsQueryKey(queryParams.value));

const { perPage, page, updatePerPage } = usePagination(queryKey);

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
}));

const { data, isLoading } = useImports(queryParams, {
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

const expandedId = ref<string | null>(null);

const toggleExpanded = (item: Import) => {
  expandedId.value = expandedId.value === item.id ? null : item.id;
};

// Only the open row is fetched: the list payload deliberately omits `details`,
// and a run can name a couple of hundred ships.
const { data: expandedImport, isLoading: isLoadingDetails } = useImport(
  computed(() => expandedId.value ?? ""),
  { query: { enabled: computed(() => !!expandedId.value) } },
);

const DETAIL_SECTIONS = [
  "imported",
  "found",
  "movedToWanted",
  "missing",
  "missingComponents",
  "missingUpgrades",
] as const;

const detailSections = computed(() => {
  const details = expandedImport.value?.details as ImportDetails | undefined;

  if (!details) return [];

  return DETAIL_SECTIONS.flatMap((key) => {
    const names = details[key];

    return names?.length ? [{ key, names }] : [];
  });
});

// Keyed on nothing: a cancel has to invalidate whichever page the user is on,
// and the list is small enough that refetching every cached page is cheap.
const invalidateImports = () =>
  queryClient.invalidateQueries({ queryKey: ["imports"] });

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

  <ListGroup
    :items="items"
    :loading="isLoading"
    :expanded-id="expandedId"
    empty-name="imports"
  >
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

    <template #expanded="{ item }">
      <div v-if="item.id === expandedId" class="import-details">
        <SmallLoader :loading="isLoadingDetails" />

        <p
          v-if="!isLoadingDetails && !detailSections.length"
          class="import-details__empty"
        >
          {{ t("labels.imports.noDetails") }}
        </p>

        <div
          v-for="section in detailSections"
          :key="`${item.id}-${section.key}`"
          class="import-details__section"
        >
          <h4 class="import-details__title">
            {{ t(`labels.imports.details.${section.key}`) }}
            <span class="import-details__count">{{
              section.names.length
            }}</span>
          </h4>
          <ul class="import-details__list">
            <li v-for="name in section.names" :key="`${section.key}-${name}`">
              {{ name }}
            </li>
          </ul>
        </div>
      </div>
    </template>

    <template #actions="{ item }">
      <Btn
        :aria-label="t('actions.imports.toggleDetails')"
        data-test="import-toggle-details"
        @click="toggleExpanded(item)"
      >
        <i
          class="fa-light"
          :class="item.id === expandedId ? 'fa-chevron-up' : 'fa-chevron-down'"
        />
      </Btn>

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

  <Paginator
    :query-result-ref="data"
    :per-page="perPage"
    :update-per-page="updatePerPage"
  />
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

.import-details {
  padding: 0 1rem 1rem;
}

.import-details__section + .import-details__section {
  margin-top: 0.75rem;
}

.import-details__title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0 0 0.25rem;
  font-size: 0.8125rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--text-muted);
}

.import-details__count {
  font-variant-numeric: tabular-nums;
}

.import-details__list {
  margin: 0;
  padding-left: 1.25rem;
  columns: 2;

  @media (max-width: 767px) {
    columns: 1;
  }
}

.import-details__empty {
  margin: 0;
  color: var(--text-muted);
}

.import-info-text {
  margin: 0;
  color: var(--color-danger);
  font-size: 0.875rem;
}
</style>
