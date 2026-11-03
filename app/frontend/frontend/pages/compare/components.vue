<script lang="ts">
export default {
  name: "CompareComponentsPage",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import CompareLayout from "@/frontend/components/Compare/Layout/index.vue";
import CompareCatalogueAdd from "@/frontend/components/Compare/CatalogueAdd/index.vue";
import CompareCatalogueShare from "@/frontend/components/Compare/CatalogueShare/index.vue";
import { componentCompareCategory } from "@/frontend/components/Compare/category";
import { useComponentSections } from "@/frontend/components/Compare/sections/component";
import type { CompareColumn } from "@/frontend/components/Compare/types";
import { compareItemImage } from "@/frontend/components/Compare/image";
import { useCompareCatalogue } from "@/frontend/composables/useCompareCatalogue";
import { useComponentCategoryLabel } from "@/frontend/composables/useComponentCategoryLabel";
import { useI18n } from "@/shared/composables/useI18n";
import { component as fetchComponent, type Component } from "@/services/fyApi";

const { t } = useI18n();

const categoryLabel = useComponentCategoryLabel();

const { slugs, items, category, dropped, loading, asyncStatus, remove } =
  useCompareCatalogue({
    queryKey: "components",
    fetchItem: (slug): Promise<Component> => fetchComponent(slug),
    categoryOf: (item) => componentCompareCategory(item, categoryLabel),
  });

const { sections } = useComponentSections(() => items.value);

const columns = computed<CompareColumn[]>(() =>
  items.value.map((item) => ({
    key: item.slug,
    name: item.name,
    subtitle: item.manufacturer?.name,
    image: compareItemImage(item),
    imageFit: "contain",
    to: { name: "component", params: { slug: item.slug } },
  })),
);
</script>

<template>
  <Heading hidden>{{ t("headlines.compare.components") }}</Heading>

  <CompareLayout
    :columns="columns"
    :sections="sections"
    :async-status="asyncStatus"
    :loading="loading && !!items.length"
    :empty-title="t('headlines.compare.components')"
    :empty-info="t('texts.compare.components.info')"
    :count-label="t('labels.compare.componentCount', { count: items.length })"
    :remove-label="t('labels.compare.removeItem')"
    @remove="remove"
  >
    <template #add="{ compact }">
      <CompareCatalogueAdd
        kind="Component"
        query-key="components"
        :slugs="slugs"
        :lock="category"
        :label="t('labels.compare.selectComponents')"
        :compact="compact"
      />
    </template>
    <template #actions>
      <CompareCatalogueShare
        query-key="components"
        :slugs="slugs"
        :title="t('headlines.compare.components')"
      />
    </template>

    <template v-if="dropped.length" #notice>
      <Alert :variant="AlertVariantsEnum.WARNING" class="compare-notice">
        {{
          t("texts.compare.dropped", {
            items: dropped.join(", "),
            category: category?.label,
          })
        }}
      </Alert>
    </template>
  </CompareLayout>
</template>

<style lang="scss" scoped>
.compare-notice {
  margin-bottom: 18px;
}
</style>
