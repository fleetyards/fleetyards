<script lang="ts">
export default {
  name: "RelationshipsRelationshipView",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import RelationshipTable from "@/frontend/components/Relationships/RelationshipTable/index.vue";
import type {
  RelationshipRow,
  RelationshipTab,
} from "@/frontend/components/Relationships/types";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  crumbs: Crumb[];
  heading: string;
  kind: "user" | "fleet";
  tab: RelationshipTab;
  tabs: RelationshipTab[];
  rows: RelationshipRow[];
  asyncStatus: AsyncStatus;
  isLoading: boolean;
  busy: boolean;
  // Absent when the reader may see the list and not change it -- an officer
  // reading a fleet's allies, for instance.
  canManage?: boolean;
  onAdd: (handle: string) => Promise<boolean>;
};

const props = withDefaults(defineProps<Props>(), { canManage: true });

const emit = defineEmits<{
  "update:tab": [RelationshipTab];
  accept: [RelationshipRow];
  decline: [RelationshipRow];
  ignore: [RelationshipRow];
  remove: [RelationshipRow];
}>();

const { t } = useI18n();
const comlink = useComlink();

const TAB_ICONS: Record<RelationshipTab, string> = {
  accepted: "fa-user-group",
  incoming: "fa-arrow-right-to-bracket",
  outgoing: "fa-arrow-right-from-bracket",
  ignored: "fa-eye-slash",
};

const openAdd = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Relationships/AddRelationshipModal/index.vue"),
    props: {
      title: t(`headlines.relationships.${props.kind}.add`),
      label: t(`labels.relationships.${props.kind}.handle`),
      placeholder: t(`placeholders.relationships.${props.kind}.handle`),
      hint: t(`messages.relationships.${props.kind}.addHint`),
      submitLabel: t("actions.relationships.send"),
      onSubmit: props.onAdd,
    },
  });
};
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ heading }}
  </Heading>

  <FilteredList
    name="relationships"
    :records="rows"
    :async-status="asyncStatus"
    placeholders
    :hide-empty="true"
  >
    <!-- The same segmented control the transfers list uses, in the same slot.
         `ignored` sits at the end and is never the default: a list you have to
         ask for, so nothing the reader turned away is put back in front of
         them. -->
    <template #actions-left>
      <BtnGroup segmented>
        <Btn
          v-for="value in tabs"
          :key="value"
          :active="tab === value"
          mobile-icon-only
          :data-test="`relationships-${value}`"
          @click="emit('update:tab', value)"
        >
          <i class="fa-duotone" :class="TAB_ICONS[value]" />
          {{ t(`labels.relationships.tabs.${value}`) }}
        </Btn>
      </BtnGroup>
    </template>

    <template #actions-right>
      <Btn v-if="canManage" data-test="relationships-add" @click="openAdd">
        <i class="fa-duotone fa-plus" />
        {{ t(`actions.relationships.${kind}.add`) }}
      </Btn>
    </template>

    <template #default>
      <RelationshipTable
        :rows="rows"
        :kind="kind"
        :loading="isLoading"
        :busy="busy"
        @accept="emit('accept', $event)"
        @decline="emit('decline', $event)"
        @ignore="emit('ignore', $event)"
        @remove="emit('remove', $event)"
      />
    </template>
  </FilteredList>
</template>
