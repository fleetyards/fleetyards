<script lang="ts">
export default {
  name: "FleetSquadronPanel",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { FleetSquadron } from "@/services/fyApi";

type Props = {
  squadron: FleetSquadron;
  to: RouteLocationRaw;
  editable?: boolean;
  destroyable?: boolean;
  membersManageable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  destroyable: false,
  membersManageable: false,
});

const emit = defineEmits<{ edit: []; destroy: []; addMembers: [] }>();

const { t } = useI18n();

// The squadron's own colour where it has one, and the quiet grey a glyph takes
// where it does not -- never a colour nobody chose.
const railStyle = computed(() => ({
  backgroundColor: props.squadron.color || "var(--color-muted)",
}));
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    :data-test="`squadron-panel-${squadron.slug}`"
    class="squadron-panel"
    fill-height
  >
    <span class="squadron-panel-rail" :style="railStyle" />

    <PanelHeading compact divider :level="HeadingLevelEnum.H3">
      <template #leading>
        <SquadronEmblem :squadron="squadron" :size="56" />
      </template>
      <template #default>
        <router-link :to="to">
          {{ squadron.name }}
        </router-link>
      </template>
      <template v-if="squadron.shortDescription" #subtitle>
        <span class="squadron-panel-subtitle">
          {{ squadron.shortDescription }}
        </span>
      </template>
      <template v-if="membersManageable || editable || destroyable" #actions>
        <Btn
          v-if="membersManageable"
          v-tooltip="t('actions.fleet.squadrons.addMember')"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.fleet.squadrons.addMember')"
          class="squadron-panel-action"
          data-test="squadron-panel-add-members"
          @click.prevent="emit('addMembers')"
        >
          <i class="fa-duotone fa-user-plus" />
        </Btn>
        <Btn
          v-if="editable"
          v-tooltip="t('actions.edit')"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.edit')"
          class="squadron-panel-action"
          data-test="squadron-panel-edit"
          @click.prevent="emit('edit')"
        >
          <i class="fa-duotone fa-pen" />
        </Btn>
        <Btn
          v-if="destroyable"
          v-tooltip="t('actions.delete')"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('actions.delete')"
          class="squadron-panel-action"
          data-test="squadron-panel-destroy"
          @click.prevent="emit('destroy')"
        >
          <i class="fa-duotone fa-trash" />
        </Btn>
      </template>
    </PanelHeading>
    <PanelBody class="squadron-panel-body" rounded="bottom">
      <div class="squadron-panel-count">
        <span class="squadron-panel-count-number">
          {{ squadron.memberCount }}
        </span>
        <span class="squadron-panel-count-label">
          {{ t("labels.fleet.squadrons.members") }}
        </span>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.squadron-panel {
  // Clipped so the rail takes the panel's own corner radius at both ends.
  // Safe here: the only overflowing thing a card holds is a tooltip, and those
  // are fixed-position children of document.body.
  overflow: hidden;

  /*
   * The rail rather than a coloured frame: at this size a full edge in a
   * user-chosen colour surrounds the content and starts competing with it,
   * while a rail stays a marker you can still find across a grid. The same
   * language the row list uses, stood on its end.
   */
  .squadron-panel-rail {
    position: absolute;
    left: 0;
    top: 0;
    bottom: 0;
    width: 4px;
  }

  .squadron-panel-body {
    flex: 1;
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 16px;
  }

  &-action {
    font-size: 18px;

    > :first-child {
      font-size: 18px;
    }
  }

  // Written in a textarea, so the lines somebody typed are the lines drawn.
  &-subtitle {
    white-space: pre-line;
  }

  &-count {
    display: flex;
    align-items: baseline;
    gap: 6px;
  }

  &-count-number {
    font-size: 1.5em;
    line-height: 1;
  }

  &-count-label {
    color: var(--color-text-dim);
    font-size: 0.85em;
  }
}
</style>
