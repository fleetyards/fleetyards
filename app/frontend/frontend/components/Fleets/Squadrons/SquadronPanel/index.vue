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

// The logo if there is one. A squadron without one is told apart by its colour
// instead -- the stripe down the body -- rather than by stand-in art, because
// there is no catalogue of squadron pictures to fall back to.
const image = computed(() => props.squadron.logo?.smallUrl ?? undefined);

// The stripe is the squadron's own colour where it has one, and the quiet grey
// a glyph takes where it does not -- never a colour nobody chose.
const markStyle = computed(() => ({
  backgroundColor: props.squadron.color || "var(--color-muted)",
}));
</script>

<template>
  <Panel
    :bg-image="image"
    :data-test="`squadron-panel-${squadron.slug}`"
    class="squadron-panel"
  >
    <PanelHeading shadow="top" :level="HeadingLevelEnum.H2">
      <template #default>
        <router-link :to="to">
          {{ squadron.name }}
        </router-link>
      </template>
      <template v-if="squadron.description" #subtitle>
        {{ squadron.description }}
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
      <span class="squadron-panel-mark" :style="markStyle" />
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
  .squadron-panel-body {
    flex: 1;
    display: flex;
    align-items: center;
    gap: 12px;
    min-height: 60px;
  }

  &-action {
    font-size: 18px;

    > :first-child {
      font-size: 18px;
    }
  }

  // The one place a squadron's colour is shown at any size. A stripe rather
  // than a dot: at badge size the colour is a hint, and here it is what the
  // card is recognised by across a grid of them.
  &-mark {
    width: 4px;
    align-self: stretch;
    min-height: 28px;
    border-radius: 2px;
    flex-shrink: 0;
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
