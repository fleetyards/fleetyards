<script lang="ts">
export default {
  name: "AnnouncementActions",
};
</script>

<script lang="ts" setup>
import Items from "@/admin/components/Announcements/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type Announcement } from "@/services/fyAdminApi";

type Props = {
  announcement: Announcement;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile">
    <Items :announcement="props.announcement" with-labels />
  </BtnDropdown>
  <BtnGroup v-else>
    <Items :announcement="props.announcement" />
  </BtnGroup>
</template>
