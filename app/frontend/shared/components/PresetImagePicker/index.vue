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

const dialog = ref<HTMLElement | undefined>();

onMounted(() => {
  afterNextPaint(() => {
    entered.value = true;
  });

  /*
   * The dialog itself rather than the first tile: it carries the label, so a
   * screen reader announces what this is before reading out a grid of
   * pictures. Tab from here reaches the first control.
   */
  dialog.value?.focus();
});

const FOCUSABLE = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  '[tabindex]:not([tabindex="-1"])',
].join(", ");

const focusable = () =>
  Array.from(dialog.value?.querySelectorAll<HTMLElement>(FOCUSABLE) ?? []);

/*
 * `aria-modal` tells assistive tech that everything behind this is inert, and
 * the keyboard has to agree: without a trap, Tab walks straight out of the
 * dialog and into the form it is covering, which is still tabbable and still
 * looks focusable.
 */
const containFocus = (event: KeyboardEvent) => {
  const items = focusable();
  if (!items.length) return;

  const first = items[0];
  const last = items[items.length - 1];
  const active = document.activeElement as HTMLElement | null;

  // Focus escaped, or never arrived -- bring it back rather than letting Tab
  // carry on from wherever it is.
  if (!active || !dialog.value?.contains(active)) {
    event.preventDefault();
    first.focus();
    return;
  }

  if (event.shiftKey && active === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && active === last) {
    event.preventDefault();
    first.focus();
  }
};

const handleKeyDown = (event: KeyboardEvent) => {
  if (event.key === "Escape") {
    /*
     * The key is this picker's own: it is the topmost surface while it is open,
     * and a modal underneath must not read the same press and close as well.
     *
     * `stopImmediatePropagation`, because `stopPropagation` only stops the
     * later phases -- a second listener on `window` itself still runs, and
     * `window` is exactly where the surfaces underneath listen.
     */
    event.stopImmediatePropagation();
    emit("close");
    return;
  }

  if (event.key === "Tab") containFocus(event);
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
      data-test="preset-picker"
      @click.self="emit('close')"
    >
      <!-- The dialog is the panel, not the scrim behind it. `tabindex="-1"` so
           it can hold focus on open without joining the tab order. -->
      <div
        ref="dialog"
        class="preset-picker__dialog"
        role="dialog"
        aria-modal="true"
        :aria-label="t('labels.presets.title')"
        tabindex="-1"
      >
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
