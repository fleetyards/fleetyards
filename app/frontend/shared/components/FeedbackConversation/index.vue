<script lang="ts">
export default {
  name: "FeedbackConversation",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

export type ConversationEntry = {
  id: string;
  body: string;
  fromAdmin: boolean;
  author: string;
  createdAt: string;
};

type Props = {
  entries: ConversationEntry[];
};

defineProps<Props>();

const { l } = useI18n();
</script>

<template>
  <ol class="feedback-conversation" data-test="feedback-conversation">
    <li
      v-for="entry in entries"
      :key="entry.id"
      class="feedback-conversation__entry"
      :class="{ 'feedback-conversation__entry--admin': entry.fromAdmin }"
      data-test="feedback-conversation-entry"
    >
      <div class="feedback-conversation__meta">
        <span class="feedback-conversation__author">{{ entry.author }}</span>
        <time :datetime="entry.createdAt">
          {{ l(entry.createdAt, "datetime.formats.short") }}
        </time>
      </div>
      <p class="feedback-conversation__body">{{ entry.body }}</p>
    </li>
  </ol>
</template>

<style lang="scss" scoped>
.feedback-conversation {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.feedback-conversation__entry {
  max-width: 85%;
  padding: 12px 16px;
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-surface-inner);
  background: var(--color-surface);
}

.feedback-conversation__entry--admin {
  align-self: flex-end;
  border-color: var(--color-primary);
}

.feedback-conversation__meta {
  display: flex;
  gap: 12px;
  margin-bottom: 4px;
  font-size: 0.8125rem;
  color: var(--color-text-dim);
}

.feedback-conversation__author {
  font-weight: 600;
}

.feedback-conversation__body {
  margin: 0;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
</style>
