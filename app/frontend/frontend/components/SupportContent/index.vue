<script lang="ts">
export default {
  name: "SupportContent",
};
</script>

<script lang="ts" setup>
import SupportProgress from "@/frontend/components/SupportProgress/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputAlignmentsEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalQuery } from "@/frontend/composables/useModalQuery";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import { useMySupporterClaimKey } from "@/services/fyApi";
import kofiIcon from "@/images/icons/kofi_s_logo_nolabel.png";

interface Props {
  // The support page shows this content on its own. In the modal it is false,
  // and the difference is only where a login has to come back to.
  standalone?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  standalone: false,
});

const { t } = useI18n();
const sessionStore = useSessionStore();
const redirectBackStore = useRedirectBackStore();
const { modalRoute } = useModalQuery();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

// Reading generates the key, so it is here the moment somebody opens the modal
// to donate rather than after a detour through settings.
const { data: claimKey } = useMySupporterClaimKey({
  query: { enabled: computed(() => sessionStore.isAuthenticated) },
});

// Gated on the session rather than on the query alone: a disabled query keeps
// serving its cached data, so after a logout the key would still be here.
const key = computed(() =>
  sessionStore.isAuthenticated ? (claimKey.value?.key ?? "") : "",
);

const platforms = [
  {
    id: "paypal",
    label: "PayPal",
    icon: "fa-brands fa-paypal",
    href: "https://paypal.me/mortik",
    carriesMessage: true,
  },
  {
    id: "patreon",
    label: "Patreon",
    icon: "fa-brands fa-patreon",
    href: "https://www.patreon.com/fleetyards",
    carriesMessage: false,
  },
  {
    id: "kofi",
    label: "Ko-fi",
    icon: "",
    href: "https://ko-fi.com/fleetyardsnet",
    carriesMessage: true,
  },
  {
    id: "bmac",
    label: "Buy me a coffee",
    icon: "fa-solid fa-mug-hot",
    href: "https://www.buymeacoffee.com/mortik",
    carriesMessage: true,
  },
];

// The three platforms that carry a donor message copy the key on the way out,
// so it is on the clipboard when the payment form asks for one. Ko-fi has no
// URL parameter to prefill it with, so this is as close as it gets.
const copyKey = () => {
  if (!key.value) return;

  const failed = () => {
    displayAlert({
      text: t("messages.account.supporterClaimKey.copy.failure"),
    });
  };

  // Not awaited: a platform link opens in a new tab, and awaiting first would
  // put the navigation outside the user gesture that permits the write. Which
  // is also why this cannot be the try/catch every other copy in the app is.
  const written = navigator.clipboard?.writeText(key.value);

  // Compared rather than tested for truth: a promise in a boolean conditional
  // is the mistake the rule is there to catch, and this one is looking for the
  // browser that has no clipboard to return one.
  if (written === undefined) {
    failed();

    return;
  }

  void written.then(() => {
    displaySuccess({
      text: t("messages.account.supporterClaimKey.copy.success"),
    });
  }, failed);
};

// Somebody sent to the login to claim a key came here to donate, so the login
// brings them back to where they were: the page, or the page the modal was
// over -- with the flag that puts the modal back up.
//
// The dismissal stays here rather than being handed in by each caller: on the
// support page there is no modal open and nothing listens.
const leaveForLogin = () => {
  redirectBackStore.setBackRoute(
    props.standalone ? { name: "support" } : modalRoute("support"),
  );

  comlink.emit("close-modal");
};
</script>

<template>
  <div class="support-body">
    <SupportProgress />

    <hr class="support-rule" />

    <div class="support-section">
      <div class="support-section__label">
        {{ t("texts.support.subline") }}
      </div>

      <div class="support-platforms">
        <Btn
          v-for="platform in platforms"
          :key="platform.id"
          :href="platform.href"
          :data-test="`support-${platform.id}`"
          @click="platform.carriesMessage && copyKey()"
        >
          <img
            v-if="platform.id === 'kofi'"
            :src="kofiIcon"
            alt=""
            width="20"
          />
          <i v-else :class="platform.icon" />
          <span>{{ platform.label }}</span>
        </Btn>
      </div>

      <template v-if="key">
        <FormInput
          name="supporterClaimKey"
          :model-value="key"
          :prefix="t('labels.account.supporterClaimKey.label')"
          :alignment="InputAlignmentsEnum.CENTER"
          no-label
          class="support-claim-key"
          data-test="claim-key"
        >
          <template #suffix>
            <button
              type="button"
              class="support-claim-key__copy"
              :aria-label="t('actions.copy')"
              :title="t('actions.copy')"
              data-test="copy-claim-key"
              @click="copyKey"
            >
              <i class="fa-light fa-copy" />
            </button>
          </template>
        </FormInput>

        <p class="support-claim-key__hint">
          {{ t("labels.account.supporterClaimKey.hint") }}
        </p>
      </template>

      <router-link
        v-else-if="!sessionStore.isAuthenticated"
        :to="{ name: 'login' }"
        class="support-claim-key__hint support-claim-key__hint--signed-out"
        data-test="claim-key-signed-out"
        @click="leaveForLogin"
      >
        {{ t("labels.account.supporterClaimKey.signedOut") }}
      </router-link>
    </div>

    <hr class="support-rule" />

    <div class="support-section">
      <div class="support-section__label">
        {{ t("texts.support.otherWays") }}
      </div>

      <div class="support-secondary">
        <p v-html="t('texts.support.info')" />
        <p class="support-secondary__referral">
          {{ t("texts.support.code") }}
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
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
