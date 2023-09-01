<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <template v-for="addon in addons">
          <div
            v-for="(addonId, index) in idsForAddon(addon.id)"
            :key="`${index}-${addonId}`"
            class="col-12 col-md-6 addon"
          >
            <Panel>
              <div
                v-tooltip="editable && selectTooltip(addon.id)"
                class="model-panel"
                :class="{
                  editable,
                }"
                @click.capture="changeAddon(addon.id)"
              >
                <div
                  :style="{
                    'background-image': `url(${addon.storeImage})`,
                  }"
                  class="model-panel-image"
                />
                <div class="model-panel-body">
                  <h3>{{ addon.name }}</h3>
                </div>
                <div
                  v-if="selectedAddon(addon.id)"
                  v-tooltip="editable && t('labels.selected')"
                  class="model-panel-selected"
                >
                  <i class="fa fa-check" />
                </div>
              </div>
            </Panel>
          </div>
        </template>
      </div>
    </div>
    <div v-if="editable" class="col-12 col-md-6 add-addons">
      <FilterGroup
        v-model="addonToAdd"
        :label="label"
        :options="addons"
        name="addons"
        value-attr="id"
        :searchable="true"
        @input="addAddon"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  addons: {
    id: string;
    name: string;
    storeImage: string;
  }[];
  label: string;
  value: string[];
  initialAddons: string[];
  editable: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
});

const { t } = useI18n();

const addonToAdd = ref<string | undefined>();

const internalAddons = ref<string[]>(props.value);

watch(
  () => props.value,
  () => {
    if (internalAddons.value !== props.value) {
      internalAddons.value = [...props.value];
    }
  },
);

watch(
  () => props.addons,
  () => {
    internalAddons.value = [...props.value];
  },
);

const emit = defineEmits(["update:modelValue"]);

watch(
  () => internalAddons.value,
  () => {
    emit("update:modelValue", internalAddons.value);
  },
);

const selectTooltip = (addonId: string) => {
  if (internalAddons.value.includes(addonId)) {
    return t("labels.deselect");
  }
  return null;
};

const addAddon = () => {
  if (!addonToAdd.value) {
    return;
  }

  internalAddons.value.push(addonToAdd.value);
  addonToAdd.value = undefined;
};

const idsForAddon = (addonId: string) => {
  const ids = internalAddons.value.filter((item) => item === addonId);
  if (ids.length) {
    return ids;
  }
  return [addonId];
};

const changeAddon = (addonId: string) => {
  if (!props.editable) {
    return;
  }

  if (internalAddons.value.includes(addonId)) {
    const index = internalAddons.value.findIndex(
      (itemId) => itemId === addonId,
    );
    if (index > -1) {
      internalAddons.value.splice(index, 1);
    }
  } else {
    internalAddons.value.push(addonId);
  }
};

const selectedAddon = (addonId: string) => {
  return internalAddons.value.includes(addonId);
};
</script>

<script lang="ts">
export default {
  name: "VehicleAddonsModalAddons",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
