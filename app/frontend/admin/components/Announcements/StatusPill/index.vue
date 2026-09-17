<script lang="ts">
export default {
  name: "AnnouncementStatusPill",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { AnnouncementStatusEnum } from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  status: AnnouncementStatusEnum;
};

const props = defineProps<Props>();

const { t } = useI18n();

const variants: Record<AnnouncementStatusEnum, PillVariantsEnum> = {
  [AnnouncementStatusEnum.DRAFT]: PillVariantsEnum.NEUTRAL,
  [AnnouncementStatusEnum.SCHEDULED]: PillVariantsEnum.DEFAULT,
  [AnnouncementStatusEnum.PUBLISHING]: PillVariantsEnum.WARNING,
  [AnnouncementStatusEnum.PUBLISHED]: PillVariantsEnum.SUCCESS,
  [AnnouncementStatusEnum.FAILED]: PillVariantsEnum.DANGER,
};
</script>

<template>
  <Pill :variant="variants[props.status]" uppercase>
    {{ t(`labels.admin.announcements.statuses.${props.status}`) }}
  </Pill>
</template>
