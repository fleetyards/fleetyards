<script lang="ts">
export default {
  name: "PresetImagePicker",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import ChipRow from "@/shared/components/base/Chip/Row/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  presetCatalogue,
  type PresetCatalogueName,
} from "@/shared/composables/usePresetImages";
import { useI18n } from "@/shared/composables/useI18n";
import { afterNextPaint } from "@/shared/utils/Transitions";

type Props = {
  catalogue: PresetCatalogueName;
  selected?: string | null;
  /**
   * The record's own type, and the chip the picker opens on. Only ever the
   * starting point: every picture in the catalogue is one chip away, because
   * the art that suits a job is not always the art filed under it.
   */
  group?: string | null;
};

const props = withDefaults(defineProps<Props>(), {
  selected: null,
  group: null,
});

const emit = defineEmits<{
  select: [key: string | null];
  close: [];
}>();

const { t } = useI18n();

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

const select = (key: string | null) => {
  emit("select", key);
  emit("close");
};

/*
 * Its own overlay rather than the app modal, and this is the whole reason: the
 * field that opens it is itself inside a modal half the time -- the two
 * inventory forms are modals -- and the app has one modal, so opening a second
 * replaces the first and takes the form being filled in with it.
 *
 * Above the modal layer for the same reason. The value it sits on is
 * AppConfirm's, which answers over a modal already.
 */
const entered = ref(false);

onMounted(() => {
  afterNextPaint(() => {
    entered.value = true;
  });
});

const handleKeyDown = (event: KeyboardEvent) => {
  if (event.key === "Escape") {
    // The picker is the topmost surface while it is open, so the key is its own
    // -- a modal underneath must not also read it and close as well.
    event.stopPropagation();
    emit("close");
  }
};

onMounted(() => {
  window.addEventListener("keydown", handleKeyDown, true);
});

onUnmounted(() => {
  window.removeEventListener("keydown", handleKeyDown, true);
});
</script>

<template>
  <Teleport to="body">
    <div
      class="preset-picker fade"
      :class="{ in: entered }"
      role="dialog"
      aria-modal="true"
      :aria-label="t('labels.presets.title')"
      data-test="preset-picker"
      @click.self="emit('close')"
    >
      <div class="preset-picker__dialog">
        <Panel :outer-spacing="false">
          <PanelHeading :level="HeadingLevelEnum.H2">
            {{ t("labels.presets.title") }}
          </PanelHeading>
          <PanelBody>
            <ChipRow
              v-if="groups.length > 1"
              :label="t('labels.presets.filter')"
              class="preset-picker__filter"
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

            <div v-if="shown.length" class="preset-picker__grid">
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
          </PanelBody>
        </Panel>

        <!-- Outside the panel, as the modal footer and the confirm dialog both
             put them: the actions belong to the dialog, not to the surface
             holding what it offers. -->
        <div class="preset-picker__actions">
          <Btn
            v-if="selected"
            :tone="BtnTonesEnum.DANGER"
            :variant="BtnVariantsEnum.GHOST"
            data-test="preset-image-remove"
            @click="select(null)"
          >
            {{ t("actions.presets.remove") }}
          </Btn>
          <Btn data-test="preset-picker-close" @click="emit('close')">
            {{ t("actions.close") }}
          </Btn>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style lang="scss" scoped>
@import "index";
</style>
