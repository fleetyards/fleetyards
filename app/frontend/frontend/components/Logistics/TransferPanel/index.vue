<script lang="ts">
export default {
  name: "LogisticsTransferPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { InventoryTransfer } from "@/services/fyApi";

type Props = {
  transfer: InventoryTransfer;
  // Which side the viewer is on, which decides what they can do about it.
  direction: "incoming" | "outgoing";
  busy?: boolean;
};

const props = withDefaults(defineProps<Props>(), { busy: false });

const emit = defineEmits<{
  accept: [InventoryTransfer];
  decline: [InventoryTransfer];
  cancel: [InventoryTransfer];
  report: [InventoryTransfer];
}>();

const { t } = useI18n();

const pending = computed(() => props.transfer.state === "pending");

// Only a transfer still waiting can be answered, and only the side that did not
// send it answers. The API decides this too -- this is what to render, not what
// is permitted.
const canAnswer = computed(
  () => pending.value && props.direction === "incoming",
);
const canCancel = computed(
  () => pending.value && props.direction === "outgoing",
);

const counterparty = computed(() =>
  props.direction === "incoming"
    ? props.transfer.sender?.name
    : (props.transfer.recipient?.name ?? props.transfer.destination?.name),
);

const totalLines = computed(() => props.transfer.lines?.length ?? 0);
</script>

<template>
  <Panel :data-test="`transfer-panel-${transfer.id}`">
    <PanelHeading :level="HeadingLevelEnum.H3">
      <template #default>
        {{ counterparty }}
      </template>
      <template #subtitle>
        {{ t(`labels.logistics.transferStates.${transfer.state}`) }}
      </template>
    </PanelHeading>

    <PanelBody>
      <ul class="transfer-lines">
        <li v-for="line in transfer.lines" :key="line.id">
          <span class="transfer-line-name">{{ line.name }}</span>
          <span class="transfer-line-qty">
            {{ line.quantity }} {{ t(`labels.logistics.units.${line.unit}`) }}
          </span>
        </li>
      </ul>

      <p v-if="transfer.note" class="transfer-note">{{ transfer.note }}</p>

      <p v-if="totalLines === 0" class="transfer-note">
        {{ t("labels.logistics.noStock") }}
      </p>

      <div v-if="canAnswer || canCancel" class="transfer-actions">
        <Btn
          v-if="canAnswer"
          :size="BtnSizesEnum.SM"
          :disabled="busy"
          :data-test="`transfer-accept-${transfer.id}`"
          @click="emit('accept', transfer)"
        >
          {{ t("actions.logistics.acceptTransfer") }}
        </Btn>
        <Btn
          v-if="canAnswer"
          :size="BtnSizesEnum.SM"
          :tone="BtnTonesEnum.DANGER"
          :disabled="busy"
          :data-test="`transfer-decline-${transfer.id}`"
          @click="emit('decline', transfer)"
        >
          {{ t("actions.logistics.declineTransfer") }}
        </Btn>
        <Btn
          v-if="canAnswer"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          :disabled="busy"
          :data-test="`transfer-report-${transfer.id}`"
          @click="emit('report', transfer)"
        >
          {{ t("actions.logistics.reportTransfer") }}
        </Btn>
        <Btn
          v-if="canCancel"
          :size="BtnSizesEnum.SM"
          :tone="BtnTonesEnum.DANGER"
          :disabled="busy"
          :data-test="`transfer-cancel-${transfer.id}`"
          @click="emit('cancel', transfer)"
        >
          {{ t("actions.logistics.cancelTransfer") }}
        </Btn>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.transfer-lines {
  padding: 0;
  margin: 0 0 0.5rem;
  list-style: none;

  li {
    display: flex;
    justify-content: space-between;
    padding: 0.125rem 0;
  }
}

.transfer-line-qty {
  opacity: 0.7;
}

.transfer-note {
  margin-bottom: 0.5rem;
  opacity: 0.75;
}

.transfer-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
</style>
