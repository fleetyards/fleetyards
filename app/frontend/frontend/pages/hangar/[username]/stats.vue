<script lang="ts">
export default {
  name: "PublicHangarStatsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import PublicHangarStats from "@/frontend/components/Hangar/PublicHangarStats/index.vue";
import { type UserPublic } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  user: UserPublic;
};

const props = defineProps<Props>();

const { t } = useI18n();

const router = useRouter();

const username = computed(() => props.user.username);

const usernamePlural = computed(() => {
  if (
    userTitle.value.endsWith("s") ||
    userTitle.value.endsWith("x") ||
    userTitle.value.endsWith("z")
  ) {
    return userTitle.value;
  }

  return `${userTitle.value}'s`;
});

const userTitle = computed(() => {
  return username.value[0].toUpperCase() + username.value.slice(1);
});

onMounted(async () => {
  if (!props.user.publicHangarStats) {
    await router.replace({
      name: "hangar-public",
      params: { username: username.value },
    });
  }
});
</script>

<template>
  <div class="row">
    <div class="col-12">
      <BreadCrumbs
        :crumbs="[
          {
            to: { name: 'hangar-public', params: { username: username } },
            label: t('headlines.hangar.public', { user: usernamePlural }),
          },
        ]"
      />
      <Heading size="hero" hero>{{
        t("headlines.hangar.publicStats", { user: usernamePlural })
      }}</Heading>
    </div>
  </div>

  <PublicHangarStats :username="username" />
</template>
