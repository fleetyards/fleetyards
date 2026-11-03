<script lang="ts">
export default {
  name: "CompareEquipmentPage",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import CompareLayout from "@/frontend/components/Compare/Layout/index.vue";
import CompareCatalogueAdd from "@/frontend/components/Compare/CatalogueAdd/index.vue";
import CompareCatalogueShare from "@/frontend/components/Compare/CatalogueShare/index.vue";
import { equipmentCompareCategory } from "@/frontend/components/Compare/category";
import { useEquipmentSections } from "@/frontend/components/Compare/sections/equipment";
import type { CompareColumn } from "@/frontend/components/Compare/types";
import { compareItemImage } from "@/frontend/components/Compare/image";
import { useCompareCatalogue } from "@/frontend/composables/useCompareCatalogue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  equipmentItem as fetchEquipmentItem,
  type Equipment,
} from "@/services/fyApi";

const { t } = useI18n();

const { slugs, items, category, dropped, loading, asyncStatus, remove } =
  useCompareCatalogue({
    queryKey: "equipment",
    fetchItem: (slug): Promise<Equipment> => fetchEquipmentItem(slug),
    categoryOf: equipmentCompareCategory,
  });

const { sections } = useEquipmentSections(() => items.value);

const columns = computed<CompareColumn[]>(() =>
  items.value.map((item) => ({
    key: item.slug,
    name: item.name,
    subtitle: item.manufacturer?.name,
    image: compareItemImage(item),
    imageFit: "contain",
    to: { name: "equipment-item", params: { slug: item.slug } },
  })),
);
</script>

<template>
  <Heading hidden>{{ t("headlines.compare.equipment") }}</Heading>

  <CompareLayout
    :columns="columns"
    :sections="sections"
    :async-status="asyncStatus"
    :loading="loading && !!items.length"
    :empty-title="t('headlines.compare.equipment')"
    :empty-info="t('texts.compare.equipment.info')"
    :count-label="t('labels.compare.equipmentCount', { count: items.length })"
    :remove-label="t('labels.compare.removeItem')"
    @remove="remove"
  >
    <template #add="{ compact }">
      <CompareCatalogueAdd
        kind="Equipment"
        query-key="equipment"
        :slugs="slugs"
        :lock="category"
        :label="t('labels.compare.selectEquipment')"
        :compact="compact"
      />
    </template>
    <template #actions>
      <CompareCatalogueShare
        query-key="equipment"
        :slugs="slugs"
        :title="t('headlines.compare.equipment')"
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
