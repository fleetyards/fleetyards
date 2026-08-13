<script lang="ts">
export default {
  name: "LogisticsComponentPicker",
};
</script>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Component as GameComponent,
  type Components,
  type FilterOption,
  components as fetchComponents,
  componentCategoriesFilters,
} from "@/services/fyApi";

const emit = defineEmits<{
  select: [component: GameComponent];
}>();

const { t } = useI18n();

const categoryOptions = ref<FilterOption[]>([]);
const category = ref<string | undefined>(undefined);
const selected = ref<string | undefined>(undefined);
const loaded = ref<GameComponent[]>([]);

const loadCategories = async () => {
  try {
    categoryOptions.value = await componentCategoriesFilters();
  } catch {
    categoryOptions.value = [];
  }
};

onMounted(() => {
  void loadCategories();
});

const componentQuery = ({ search, page }: { search?: string; page?: number }) =>
  fetchComponents({
    page: String(page || 1),
    q: {
      currentVersion: true,
      hiddenEq: false,
      ...(category.value ? { categoryIn: [category.value] } : {}),
      ...(search ? { nameCont: search } : {}),
    },
  });

const componentOptions = (response: Components): FilterOption[] => {
  const items = response.items || [];

  loaded.value = [
    ...loaded.value.filter(
      (known) => !items.some((item) => item.id === known.id),
    ),
    ...items,
  ];

  return items.map((item) => ({
    value: item.id,
    label: item.size ? `${item.name} (${item.size})` : item.name,
  }));
};

watch(category, () => {
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
        v-model="category"
        name="componentCategory"
        :options="categoryOptions"
        :label="t('labels.logistics.componentCategory')"
        :searchable="true"
        :nullable="true"
      />
    </div>
    <div class="col-12 col-md-7">
      <!-- Remounting on category change resets the option list, which is keyed
           to the FilterGroup instance and would otherwise keep stale entries. -->
      <FilterGroup
        :key="category || 'all'"
        v-model="selected"
        name="component"
        :query-fn="componentQuery"
        :query-response-formatter="componentOptions"
        :label="t('labels.logistics.component')"
        :searchable="true"
        :paginated="true"
        :nullable="true"
      />
    </div>
  </div>
</template>
