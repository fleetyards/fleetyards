<script lang="ts">
export default {
  name: "AdminVersionHistory",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useQueryClient } from "@tanstack/vue-query";
import {
  type Version,
  type VersionChange,
  type VersionItemTypeEnum,
  useVersions as useVersionsQuery,
  useRevertVersion as useRevertVersionMutation,
  getVersionsQueryKey,
} from "@/services/fyAdminApi";
import Panel from "@/shared/components/base/Panel/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import BtnConfirm from "@/shared/components/base/BtnConfirm/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

type Props = {
  itemId: string;
  itemType: VersionItemTypeEnum;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const queryClient = useQueryClient();

const { data, isLoading } = useVersionsQuery({
  perPage: "50",
  itemType: props.itemType,
  itemId: props.itemId,
});

const versions = computed(() => data.value?.items ?? []);

const invalidateVersions = () =>
  queryClient.invalidateQueries({ queryKey: getVersionsQueryKey() });

const revertMutation = useRevertVersionMutation({
  mutation: { onSettled: invalidateVersions },
});

const onRevert = async (version: Version, change: VersionChange) => {
  await revertMutation.mutateAsync({
    id: version.id,
    data: { field: change.field },
  });
};

// An admin edit carries a username; everything else was a loader, and `reason`
// is what says which one.
const sourceLabel = (version: Version) => {
  if (version.author) return version.author.username;

  if (version.reason)
    return t(`labels.admin.versions.sources.${version.reason}`);

  return t("labels.admin.versions.sources.unknown");
};

// A create records every column from nothing, so there is no earlier value to
// go back to. The API refuses those; this keeps the button off them.
const revertable = (version: Version) => version.event === "update";

const displayValue = (value?: string | null) =>
  value ?? t("labels.admin.versions.blank");
</script>

<template>
  <Loader v-if="isLoading" />

  <Empty v-else-if="versions.length === 0" />

  <div v-else class="flex flex-col gap-4">
    <Panel
      v-for="version in versions"
      :key="version.id"
      inset
      :outer-spacing="false"
    >
      <div class="flex flex-wrap items-center gap-2 mb-3">
        <span class="text-white">{{ l(version.createdAt ?? "") }}</span>
        <BasePill
          :variant="
            version.author ? PillVariantsEnum.DEFAULT : PillVariantsEnum.NEUTRAL
          "
        >
          {{ sourceLabel(version) }}
        </BasePill>
        <span v-if="version.reasonDescription" class="text-sm">
          {{ version.reasonDescription }}
        </span>
      </div>

      <ul class="flex flex-col gap-2 pb-5">
        <li
          v-for="change in version.changes"
          :key="`${version.id}-${change.field}`"
          class="flex flex-wrap items-center gap-2"
        >
          <span class="font-bold">{{ change.field }}</span>
          <span class="line-through opacity-60">{{
            displayValue(change.from)
          }}</span>
          <i class="fa-duotone fa-arrow-right text-xs" />
          <span>{{ displayValue(change.to) }}</span>

          <BtnConfirm
            v-if="revertable(version)"
            :size="BtnSizesEnum.SM"
            :question="t('labels.admin.versions.revertQuestion')"
            hide-question
            :disabled="revertMutation.isPending.value"
            @click="onRevert(version, change)"
          >
            {{ t("actions.revert") }}
          </BtnConfirm>
        </li>
      </ul>
    </Panel>
  </div>
</template>
