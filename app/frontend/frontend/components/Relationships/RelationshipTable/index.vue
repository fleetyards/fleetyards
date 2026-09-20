<script lang="ts">
export default {
  name: "RelationshipsRelationshipTable",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import type { BaseTableCol } from "@/shared/components/base/Table/types";
import Avatar from "@/shared/components/Avatar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMemberPresence } from "@/frontend/composables/useMemberPresence";
import type { RelationshipRow } from "@/frontend/components/Relationships/types";

type Props = {
  rows: RelationshipRow[];
  loading?: boolean;
  busy?: boolean;
  // Which of the two things the other party is. Only the placeholder icon
  // depends on it -- everything else about a row is the same either way.
  kind: "user" | "fleet";
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  busy: false,
});

const emit = defineEmits<{
  accept: [RelationshipRow];
  decline: [RelationshipRow];
  ignore: [RelationshipRow];
  remove: [RelationshipRow];
}>();

const { t, l } = useI18n();

const { onlineFor } = useMemberPresence();

// A fleet is not online. `kind` is what tells the two apart, and the alliances
// view shares this table.
const rowOnline = (row: RelationshipRow) =>
  props.kind === "user" ? onlineFor(row) : undefined;

const columns = computed<BaseTableCol<RelationshipRow>[]>(() => [
  { name: "label", label: t("labels.relationships.party"), flexGrow: 2 },
  {
    name: "createdAt",
    label: t("labels.relationships.since"),
    width: "170px",
    mobile: false,
  },
  { name: "actions", label: "", width: "260px" },
]);

// Only a request you were sent can be answered. A request you sent can be
// withdrawn, and an accepted relationship ended -- both of which the API serves
// from one DELETE, so both are one button here.
const canAnswer = (row: RelationshipRow) =>
  row.state === "pending" && row.direction === "incoming";

const canWithdraw = (row: RelationshipRow) =>
  row.state === "pending" && row.direction === "outgoing";

const canEnd = (row: RelationshipRow) => row.state === "accepted";
</script>

<template>
  <BaseTable
    :records="rows"
    :columns="columns"
    primary-key="id"
    :loading="loading"
    :empty-visible="!loading && !rows.length"
  >
    <template #col-label="{ record }">
      <span class="relationship-party">
        <Avatar
          :avatar="(record as RelationshipRow).avatar?.smallUrl"
          size="small"
          :icon="
            kind === 'fleet' ? 'fa-duotone fa-users' : 'fa-duotone fa-user'
          "
          :online="rowOnline(record as RelationshipRow)"
        />
        <span class="relationship-party__label">
          {{ (record as RelationshipRow).label }}
        </span>
      </span>
    </template>

    <template #col-createdAt="{ record }">
      {{ l((record as RelationshipRow).createdAt, "datetime.formats.short") }}
    </template>

    <template #col-actions="{ record }">
      <BtnGroup>
        <Btn
          v-if="canAnswer(record as RelationshipRow)"
          :size="BtnSizesEnum.SM"
          :disabled="busy"
          data-test="relationship-accept"
          @click="emit('accept', record as RelationshipRow)"
        >
          {{ t("actions.relationships.accept") }}
        </Btn>
        <Btn
          v-if="canAnswer(record as RelationshipRow)"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          :disabled="busy"
          data-test="relationship-decline"
          @click="emit('decline', record as RelationshipRow)"
        >
          {{ t("actions.relationships.decline") }}
        </Btn>
        <Btn
          v-if="canAnswer(record as RelationshipRow)"
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          :disabled="busy"
          data-test="relationship-ignore"
          @click="emit('ignore', record as RelationshipRow)"
        >
          {{ t("actions.relationships.ignore") }}
        </Btn>
        <Btn
          v-if="
            canWithdraw(record as RelationshipRow) ||
            canEnd(record as RelationshipRow)
          "
          :size="BtnSizesEnum.SM"
          :tone="BtnTonesEnum.DANGER"
          :variant="BtnVariantsEnum.BARE"
          :disabled="busy"
          data-test="relationship-remove"
          @click="emit('remove', record as RelationshipRow)"
        >
          {{
            canWithdraw(record as RelationshipRow)
              ? t("actions.relationships.withdraw")
              : t("actions.relationships.end")
          }}
        </Btn>
      </BtnGroup>
    </template>
  </BaseTable>
</template>

<style lang="scss" scoped>
.relationship-party {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  min-width: 0;
}

.relationship-party__label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
