<script lang="ts">
export default {
  name: "PresetImageModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import ChipRow from "@/shared/components/base/Chip/Row/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import {
  presetCatalogue,
  type PresetCatalogueName,
} from "@/shared/composables/usePresetImages";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  catalogue: PresetCatalogueName;
  selected?: string | null;
  /**
   * The record's own type, and the chip the picker opens on. Only ever the
   * starting point: every picture in the catalogue is one chip away, because
   * the art that suits a job is not always the art filed under it.
   */
  group?: string | null;
  onSelect: (key: string | null) => void;
};

const props = withDefaults(defineProps<Props>(), {
  selected: null,
  group: null,
});

const { t } = useI18n();
const comlink = useComlink();

const { presets, groups, groupLabelPrefix } = presetCatalogue(props.catalogue);

// `null` is "everything". A group that carries no art -- a contract kind still
// borrowing a mission cover -- would open on an empty grid, so it opens on all
// of them instead.
const activeGroup = ref<string | null>(
  props.group && groups.includes(props.group) ? props.group : null,
);

const groupLabel = (group: string) =>
  groupLabelPrefix ? t(`${groupLabelPrefix}.${group}`) : group;

const shown = computed(() =>
  activeGroup.value
    ? presets.filter((preset) => preset.group === activeGroup.value)
    : presets,
);

const chipState = (group: string | null) =>
  activeGroup.value === group
    ? ChipStatesEnum.INCLUDED
    : ChipStatesEnum.NEUTRAL;

const close = () => comlink.emit("close-modal");

const select = (key: string) => {
  props.onSelect(key);
  close();
};

const remove = () => {
  props.onSelect(null);
  close();
};
</script>

<template>
  <Modal :title="t('labels.presets.title')">
    <ChipRow
      v-if="groups.length > 1"
      :label="t('labels.presets.filter')"
      class="preset-images__filter"
    >
      <Chip :state="chipState(null)" @toggle="activeGroup = null">
        {{ t("labels.presets.all") }}
      </Chip>
      <Chip
        v-for="group in groups"
        :key="group"
        :state="chipState(group)"
        :data-test="`preset-group-${group}`"
        @toggle="activeGroup = group"
      >
        {{ groupLabel(group) }}
      </Chip>

      <template #menu>
        <Btn :active="!activeGroup" @click="activeGroup = null">
          {{ t("labels.presets.all") }}
        </Btn>
        <Btn
          v-for="group in groups"
          :key="`menu-${group}`"
          :active="activeGroup === group"
          @click="activeGroup = group"
        >
          {{ groupLabel(group) }}
        </Btn>
      </template>
    </ChipRow>

    <div v-if="shown.length" class="preset-images__grid">
      <button
        v-for="preset in shown"
        :key="preset.key"
        type="button"
        class="preset-image"
        :class="{ 'preset-image--active': selected === preset.key }"
        :aria-pressed="selected === preset.key"
        :data-test="`preset-image-${preset.key}`"
        @click="select(preset.key)"
      >
        <img :src="preset.url" :alt="preset.key" loading="lazy" />
      </button>
    </div>
    <p v-else class="text-muted">{{ t("labels.presets.empty") }}</p>

    <template #footer>
      <Btn
        v-if="selected"
        :tone="BtnTonesEnum.DANGER"
        data-test="preset-image-remove"
        @click="remove"
      >
        {{ t("actions.presets.remove") }}
      </Btn>
      <Btn @click="close">
        {{ t("actions.close") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
