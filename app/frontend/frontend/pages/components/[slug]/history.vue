<script lang="ts">
export default {
  name: "ComponentHistoryPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import Empty from "@/shared/components/Empty/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import {
  type Component,
  type ComponentBuildChange,
  useComponentChanges as useComponentChangesQuery,
} from "@/services/fyApi";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const { t, tExists, l } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: changes } = useComponentChangesQuery(slug);

const metaTitle = computed(() =>
  t("title.componentHistory", { name: props.component.name }),
);

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "components" },
    label: t("nav.components.index"),
  },
  {
    to: { name: "component", params: { slug: slug.value } },
    label: props.component.name,
  },
]);

/*
 * One group per patch, newest first. The endpoint already orders by
 * `recordedAt` and then by field, so the groups come out in order and the rows
 * inside them stay alphabetical -- building a Map preserves that insertion
 * order rather than re-sorting it here.
 */
const patches = computed(() => {
  const groups = new Map<string, ComponentBuildChange[]>();

  (changes.value ?? []).forEach((change) => {
    const rows = groups.get(change.toVersion);

    if (rows) {
      rows.push(change);
    } else {
      groups.set(change.toVersion, [change]);
    }
  });

  return [...groups.entries()].map(([version, rows]) => ({ version, rows }));
});

/*
 * A metric is a `typeData` key and the hardpoint stats already name every one
 * of them in all seven locales; a build fact is a column and the detail page
 * names those. Both fall back to the key made readable, which beats showing
 * `component_sub_type` to a reader.
 */
const fieldLabel = (change: ComponentBuildChange) => {
  const key = change.field.replace(/_(\w)/g, (_, character: string) =>
    character.toUpperCase(),
  );

  const paths = change.metric
    ? [`labels.hardpoint.${key}`]
    : [`labels.component.${key}`, `labels.hardpoint.${key}`];

  const path = paths.find((candidate) => tExists(candidate));

  if (path) {
    return t(path);
  }

  const words = change.field.replace(/_/g, " ");

  return words.charAt(0).toUpperCase() + words.slice(1);
};

// Null means the build did not carry the fact at all -- on the old side a fact
// the patch introduced, on the new side one it took away. Neither is a value,
// and printing an empty cell for them would read as a blank rather than an
// absence.
const displayValue = (value?: string | null) => value ?? "—";

const date = (value?: string | null) =>
  value ? l(value, "datetime.formats.date") : "—";

const updateTitle = () =>
  updateMetaInfo({
    title: metaTitle.value,
    description: props.component.description || undefined,
  });

onMounted(() => updateTitle());

watch(() => props.component, updateTitle);
</script>

<template>
  <div class="component-history">
    <BreadCrumbs :crumbs="crumbs" />
    <h1>{{ metaTitle }}</h1>

    <!-- Recording starts with the next load, so a component with nothing here
         is the normal case for a while rather than a fault. -->
    <Empty
      v-if="!patches.length"
      inline
      hide-actions
      :name="t('headlines.component.history')"
    >
      <template #info>{{ t("labels.component.notRecordedYet") }}</template>
    </Empty>

    <Panel v-for="patch in patches" v-else :key="patch.version">
      <PanelHeading :level="HeadingLevelEnum.H2">
        {{ patch.version }}
        <span class="component-history__date">
          {{ date(patch.rows[0].recordedAt) }}
        </span>
      </PanelHeading>
      <PanelBody>
        <ul class="component-history__list" data-test="component-changes">
          <li v-for="change in patch.rows" :key="change.id">
            <span class="component-history__field">
              {{ fieldLabel(change) }}
            </span>
            <span class="component-history__values">
              {{ displayValue(change.oldValue) }}
              →
              {{ displayValue(change.newValue) }}
            </span>
          </li>
        </ul>
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.component-history__date {
  margin-left: 0.5rem;
  color: var(--color-text-dim);
  font-size: 0.875rem;
}

.component-history__list {
  margin: 0;
  padding: 0;
  list-style: none;

  li {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
    padding: 0.5rem 0;
    border-bottom: 1px solid rgb(255 255 255 / 8%);

    &:last-child {
      border-bottom: 0;
    }
  }
}

.component-history__values {
  color: var(--color-text-dim);
  text-align: right;
}
</style>
