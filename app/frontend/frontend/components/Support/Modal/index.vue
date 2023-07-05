<template>
  <Modal :title="t('headlines.support')">
    <div class="support-body">
      <br />
      <div class="row">
        <div class="col-12">
          <p v-html="t('texts.support.info')" />
        </div>
      </div>
      <br />
      <div class="row">
        <div class="col-12">
          <p v-html="t('texts.support.code')" />
          <a
            href="https://robertsspaceindustries.com/enlist?referral=STAR-5F32-SJZ4"
            class="support-referral-link"
            target="_blank"
            rel="noopener"
          >
            <b>STAR-5F32-SJZ4</b>
          </a>
        </div>
      </div>
      <br />
      <p>
        {{ t("texts.support.subline") }}
      </p>
      <div class="page-actions page-actions-center">
        <Btn
          href="https://www.buymeacoffee.com/mortik"
          variant="link"
          class="support-buymeacoffee"
        >
          <img
            src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=martenk&button_colour=428bca&font_colour=ffffff&font_family=Cookie&outline_colour=ffffff&coffee_colour=FFDD00"
          />
        </Btn>
        &nbsp; &nbsp;
        <Btn href="https://paypal.me/mortik" size="large">
          <i class="fab fa-paypal" />
          PayPal
        </Btn>
        &nbsp; &nbsp;
        <Btn href="https://www.patreon.com/fleetyards" size="large">
          <i class="fab fa-patreon" />
          Patreon
        </Btn>
      </div>
    </div>
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/frontend/core/components/AppModal/Inner/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "SupportModal",
};
</script>

<style scoped lang="scss">
.support-referral-link {
  font-size: 130%;
}
</style>
