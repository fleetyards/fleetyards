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
            <Panel
              v-tooltip="editable && selectTooltip(addon.id)"
              alignment="left"
              slim
              class="addon-panel"
              :class="{
                'addon-panel-editable': editable,
              }"
              @click.capture="changeAddon(addon.id)"
            >
              <PanelImage
                :image="storeImage(addon)"
                image-size="auto"
                rounded="left"
                class="addon-image"
                :alt="addon.name"
              />
              <div>
                <PanelHeading level="h3" title-align="right" multiline>{{
                  addon.name
                }}</PanelHeading>
                <div
                  v-if="selectedAddon(addon.id)"
                  v-tooltip="editable && t('labels.selected')"
                  class="addon-panel-selected"
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
        :options="options"
        name="addons"
        value-attr="id"
        :searchable="true"
        @update:model-value="addAddon"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelModule, type ModelUpgrade } from "@/services/fyApi";
import { FilterGroupOption } from "@/shared/components/base/FilterGroup/Option/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelImage from "@/shared/components/Panel/Image/index.vue";

type Props = {
  addons: (ModelModule | ModelUpgrade)[];
  label: string;
  initialAddons: string[];
  modelValue?: string[];
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  editable: false,
});

const { t } = useI18n();

const addonToAdd = ref<string | undefined>();

const internalAddons = ref<string[]>(props.modelValue || []);

const storeImage = (addon: ModelModule | ModelUpgrade) => {
  return addon.media?.storeImage?.small;
};

const options = computed((): FilterGroupOption[] => {
  return props.addons.map((addon) => {
    return {
      value: addon.id,
      label: addon.name,
      icon: addon.media.storeImage?.small,
    };
  });
});

watch(
  () => props.modelValue,
  () => {
    if (internalAddons.value !== props.modelValue) {
      internalAddons.value = [...(props.modelValue || [])];
    }
  },
);

watch(
  () => props.addons,
  () => {
    internalAddons.value = [...(props.modelValue || [])];
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
