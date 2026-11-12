<script lang="ts">
export default {
  name: "FleetSquadronSlotCandidatesModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import SlotCandidatesEditor from "@/frontend/components/Fleets/Squadrons/SlotCandidatesEditor/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { type LineupScope } from "@/frontend/components/Fleets/Missions/useLineupApi";
import { useSlotTitle } from "@/frontend/composables/useSlotTitle";
import { type FleetSquadronSlotCandidate } from "@/services/fyApi";

type Props = {
  slot: {
    id: string;
    title: string;
    lead?: boolean;
    candidates?: FleetSquadronSlotCandidate[];
  };
  scope: LineupScope;
};

const props = defineProps<Props>();

const { t } = useI18n();
const slotTitle = useSlotTitle();
const comlink = useComlink();

const editor = ref<InstanceType<typeof SlotCandidatesEditor>>();

useModalDirty(() => !!editor.value?.dirty);
</script>

<template>
  <Modal
    :title="
      t('headlines.fleets.squadrons.flights.candidates', {
        slot: slotTitle(props.slot),
      })
    "
  >
    <SlotCandidatesEditor
      ref="editor"
      :slot="props.slot"
      :scope="props.scope"
      @saved="comlink.emit('close-modal', true)"
    />

    <template #footer>
      <Btn
        :loading="editor?.pending"
        data-test="slot-candidates-save"
        @click="editor?.submit()"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
