<script lang="ts">
export default {
  name: "SupportModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import SupportProgress from "@/frontend/components/SupportProgress/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { useMySupporterClaimKey } from "@/services/fyApi";
import kofiIcon from "@/images/icons/kofi_s_logo_nolabel.png";

const { t } = useI18n();
const sessionStore = useSessionStore();

// Reading generates the key, so it is here the moment somebody opens the modal
// to donate rather than after a detour through settings.
const { data: claimKey } = useMySupporterClaimKey({
  query: { enabled: computed(() => sessionStore.isAuthenticated) },
});

const key = computed(() => claimKey.value?.key ?? "");

const platforms = [
  {
    id: "paypal",
    label: "PayPal",
    icon: "fa-brands fa-paypal",
    href: "https://paypal.me/mortik",
  },
  {
    id: "kofi",
    label: "Ko-fi",
    icon: "",
    href: "https://ko-fi.com/fleetyardsnet",
  },
  {
    id: "bmac",
    label: "Buy me a coffee",
    icon: "fa-solid fa-mug-hot",
    href: "https://www.buymeacoffee.com/mortik",
  },
];

const copiedFrom = ref<string | null>(null);
let resetTimer: ReturnType<typeof setTimeout> | undefined;

// The three platforms that carry a donor message copy the key on the way out,
// so it is on the clipboard when the payment form asks for one. Ko-fi has no
// URL parameter to prefill it with, so this is as close as it gets.
//
// Deliberately not awaited: the link opens in a new tab and awaiting first
// would put the navigation outside the user gesture. Failure is silent by
// design -- the clipboard is a convenience here, and the key is still visible
// in the hint below.
const copyKeyFor = (platform: string) => {
  if (!key.value) return;

  void navigator.clipboard?.writeText(key.value).then(
    () => {
      copiedFrom.value = platform;
      clearTimeout(resetTimer);
      resetTimer = setTimeout(() => {
        copiedFrom.value = null;
      }, 4000);
    },
    () => {},
  );
};

onBeforeUnmount(() => clearTimeout(resetTimer));
</script>

<template>
  <Modal :title="t('headlines.support')">
    <div class="support-body">
      <SupportProgress />

      <p class="support-section__note">{{ t("texts.support.goal") }}</p>

      <div class="support-section">
        <div class="support-platforms">
          <Btn
            v-for="platform in platforms"
            :key="platform.id"
            :href="platform.href"
            :data-test="`support-${platform.id}`"
            class="support-platform"
            @click="copyKeyFor(platform.id)"
          >
            <img
              v-if="platform.id === 'kofi'"
              :src="kofiIcon"
              alt="Ko-fi Icon"
              width="22"
            />
            <i v-else :class="platform.icon" class="support-platform__icon" />
            <span class="support-platform__label">{{ platform.label }}</span>
            <span
              v-if="key"
              class="support-platform__copied"
              :class="{
                'support-platform__copied--on': copiedFrom === platform.id,
              }"
            >
              {{ t("messages.account.supporterClaimKey.copy.success") }}
            </span>
          </Btn>
        </div>

        <p
          v-if="key"
          class="support-claim-key__hint"
          data-test="claim-key-hint"
        >
          <i class="fa-light fa-key support-claim-key__icon" />
          <span>
            <code class="support-claim-key" data-test="claim-key">{{
              key
            }}</code>
            {{ t("labels.account.supporterClaimKey.howTo") }}
          </span>
        </p>

        <Btn
          href="https://www.patreon.com/fleetyards"
          class="support-platform support-platform--wide"
          data-test="support-patreon"
        >
          <i class="fa-brands fa-patreon support-platform__icon" />
          <span class="support-platform__label">Patreon</span>
          <span v-if="key" class="support-platform__note">
            {{ t("labels.account.supporterClaimKey.patreonNote") }}
          </span>
        </Btn>
      </div>

      <hr class="support-rule" />

      <div class="support-secondary">
        <p v-html="t('texts.support.info')" />
        <p>
          <span v-html="t('texts.support.code')" />
          <a
            href="https://robertsspaceindustries.com/enlist?referral=STAR-5F32-SJZ4"
            class="support-referral-link"
            target="_blank"
            rel="noopener"
          >
            <b>STAR-5F32-SJZ4</b>
          </a>
        </p>
      </div>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
