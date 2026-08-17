<script lang="ts">
export default {
  name: "LogisticsCommodityPicker",
};
</script>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Commodity,
  type Commodities,
  type FilterOption,
  commodities as fetchCommodities,
  commodityTypesFilters,
} from "@/services/fyApi";

const emit = defineEmits<{
  select: [commodity: Commodity];
}>();

const { t } = useI18n();

const typeOptions = ref<FilterOption[]>([]);
const commodityType = ref<string | undefined>(undefined);
const selected = ref<string | undefined>(undefined);
const loaded = ref<Commodity[]>([]);

const loadTypes = async () => {
  try {
    typeOptions.value = await commodityTypesFilters();
  } catch {
    typeOptions.value = [];
  }
};

onMounted(() => {
  void loadTypes();
});

const commodityQuery = ({ search, page }: { search?: string; page?: number }) =>
  fetchCommodities({
    page: String(page || 1),
    q: {
      ...(commodityType.value
        ? { commodityTypeIn: [commodityType.value] }
        : {}),
      ...(search ? { nameCont: search } : {}),
    },
  });

const commodityOptions = (response: Commodities): FilterOption[] => {
  const items = response.items || [];

  loaded.value = [
    ...loaded.value.filter(
      (known) => !items.some((item) => item.id === known.id),
    ),
    ...items,
  ];

  return items.map((item) => ({
    value: item.id,
    label: item.name,
  }));
};

watch(commodityType, () => {
  selected.value = undefined;
});

watch(selected, (val) => {
  if (!val) return;

  const picked = loaded.value.find((item) => item.id === val);

  if (picked) emit("select", picked);
});
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-5">
      <FilterGroup
        v-model="commodityType"
        name="commodityType"
        :options="typeOptions"
        :label="t('labels.logistics.commodityType')"
        :searchable="true"
        :nullable="true"
      />
    </div>
    <div class="col-12 col-md-7">
      <!-- Remounting on type change resets the option list, which is keyed
           to the FilterGroup instance and would otherwise keep stale entries. -->
      <FilterGroup
        :key="commodityType || 'all'"
        v-model="selected"
        name="commodity"
        :query-fn="commodityQuery"
        :query-response-formatter="commodityOptions"
        :label="t('labels.logistics.commodity')"
        :searchable="true"
        :paginated="true"
        :nullable="true"
      />
    </div>
  </div>
</template>
