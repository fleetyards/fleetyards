<script lang="ts">
export default {
  name: "LogisticsEquipmentPicker",
};
</script>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Equipment,
  type Equipments,
  type FilterOption,
  equipment as fetchEquipment,
  equipmentItemTypesFilters,
} from "@/services/fyApi";

// One table holds guns, armour, clothing and attachments alike, so a picker
// opened for a weapon has to say so — otherwise its type filter offers all
// hundred-odd types the other categories contribute.
type Props = {
  equipmentTypes?: string[];
};

const props = withDefaults(defineProps<Props>(), {
  equipmentTypes: undefined,
});

const emit = defineEmits<{
  select: [equipment: Equipment];
}>();

const { t } = useI18n();

const typeOptions = ref<FilterOption[]>([]);
const itemType = ref<string | undefined>(undefined);
const selected = ref<string | undefined>(undefined);
const loaded = ref<Equipment[]>([]);

const equipmentTypeQuery = computed(() =>
  props.equipmentTypes?.length ? { equipmentTypeIn: props.equipmentTypes } : {},
);

const loadTypes = async () => {
  try {
    typeOptions.value = await equipmentItemTypesFilters({
      q: equipmentTypeQuery.value,
    });
  } catch {
    typeOptions.value = [];
  }
};

onMounted(() => {
  void loadTypes();
});

watch(
  () => props.equipmentTypes,
  () => {
    itemType.value = undefined;
    void loadTypes();
  },
);

const equipmentQuery = ({ search, page }: { search?: string; page?: number }) =>
  fetchEquipment({
    page: String(page || 1),
    q: {
      ...equipmentTypeQuery.value,
      ...(itemType.value ? { itemTypeIn: [itemType.value] } : {}),
      ...(search ? { nameCont: search } : {}),
    },
  });

const equipmentOptions = (response: Equipments): FilterOption[] => {
  const items = response.items || [];

  loaded.value = [
    ...loaded.value.filter(
      (known) => !items.some((item) => item.id === known.id),
    ),
    ...items,
  ];

  // CIG reuses a display name across two makers' guns, so the size keeps the
  // options apart the way the component picker does.
  return items.map((item) => ({
    value: item.id,
    label: item.size ? `${item.name} (${item.size})` : item.name,
  }));
};

watch(itemType, () => {
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
        v-model="itemType"
        name="equipmentItemType"
        :options="typeOptions"
        :label="t('labels.logistics.equipmentItemType')"
        :searchable="true"
        :nullable="true"
      />
    </div>
    <div class="col-12 col-md-7">
      <!-- Remounting on type change resets the option list, which is keyed to
           the FilterGroup instance and would otherwise keep stale entries. -->
      <FilterGroup
        :key="`${equipmentTypes?.join(',') || 'all'}-${itemType || 'all'}`"
        v-model="selected"
        name="equipment"
        :query-fn="equipmentQuery"
        :query-response-formatter="equipmentOptions"
        :label="t('labels.logistics.equipment')"
        :searchable="true"
        :paginated="true"
        :nullable="true"
      />
    </div>
  </div>
</template>
