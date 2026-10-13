<script lang="ts">
export default {
  name: "AnnouncementManualPosts",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import copyText from "@/shared/utils/CopyText";

type Props = {
  posts: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayInfo, displayAlert } = useAppNotifications();

const copy = (post: string) => {
  copyText(post).then(
    () => displayInfo({ text: t("messages.copy.success") }),
    () => displayAlert({ text: t("messages.copy.failure") }),
  );
};
</script>

<template>
  <div>
    <p class="announcement-manual-posts__info">
      {{ t("labels.admin.announcements.manualPostsInfo") }}
    </p>
    <ol class="announcement-manual-posts">
      <li
        v-for="(post, index) in props.posts"
        :key="index"
        class="announcement-manual-posts__post"
        data-test="announcement-manual-post"
      >
        <pre class="announcement-manual-posts__text">{{ post }}</pre>
        <Btn
          :size="BtnSizesEnum.SM"
          data-test="announcement-manual-post-copy"
          @click="copy(post)"
        >
          <i class="fa-duotone fa-copy" />
          {{ t("actions.copy") }}
        </Btn>
      </li>
    </ol>
  </div>
</template>

<style lang="scss" scoped>
.announcement-manual-posts {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.announcement-manual-posts__info {
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}

.announcement-manual-posts__post {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 8px;
}

.announcement-manual-posts__text {
  width: 100%;
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
}
</style>
