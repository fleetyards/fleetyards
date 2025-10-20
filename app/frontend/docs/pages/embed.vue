<script lang="ts">
export default {
  name: "EmbedPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import BaseSpacer from "@/shared/components/base/Spacer/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import "highlight.js";
import copyText from "@/shared/utils/CopyText";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const widgetExample = `\<div id="fleetyards-view"\>\</div\>
\<script\>
    window.FleetYardsFleetchartConfig = {
        details: true, // Set to false if you want to display a minimal version of the Ship Panel
        grouped: true, // Set to false if you want to display the same Ships multiple times in your Fleetview.
        fleetchart: false, // Set to true if you want to display a Fleetchart instead of the normal Ship Panels.
        fleetchartGrouped: false, // Set to true if you want to group the Ships on the Fleetchart View or not.
        fleetchartScale: 50, // Initial Scale of the Fleetchart
        groupedButton: false, // Allow the User to toggle Groupped Views
        fleetchartSlider: false, // Set to true to display a slider which allows users to scale the Fleetchart
        ships: ['100i', '300i', '600i-touring', '890-jump'], // Replace the Array with a List of Shipnames (slugs) you want to display,
        users: ['torlekmaru', 'johndoe'], // Replace the Array with a list of Fleetyards.net usernames, alternative to the ships option. Hint: make sure the users hangar is set to public.
        fleetId: 'maru', // Replace the value with a your Fleetyards.net fleet id, alternative to the ships option. Hint: make sure the fleets ship list is set to public.
    };
    (function() {
        var d = document, s = d.createElement('script');
        s.src = 'https://fleetyards.net/embed-v2.js#' + new Date().getTime();
        (d.head || d.body).appendChild(s);
    })();
\</script\>
\<noscript\>Please enable JavaScript to view your custom Fleetview powered by FleetYards.net.\</noscript\>
`;

const { t } = useI18n();

const { displayInfo, displayAlert } = useAppNotifications();

const copyExample = () => {
  copyText(widgetExample).then(
    () => {
      displayInfo({
        text: t("messages.copy.success"),
      });
    },
    () => {
      displayAlert({
        text: t("messages.copy.failure"),
      });
    },
  );
};
</script>

<template>
  <Heading :size="HeadingSizeEnum.HERO" hero mb>Embed Fleetview</Heading>
  <Panel>
    <PanelHeading>Setup</PanelHeading>
    <PanelBody>
      <BaseText>
        To get a custom Ship List on your Website you can just paste the example
        code on the right side at the position where you want to render a Ship
        List.
      </BaseText>

      <div class="code-highlight" @click="copyExample">
        <i class="fas fa-copy copy-icon"></i>
        <pre
          v-highlightjs="widgetExample"
        ><code class="javascript rounded !py-5 !px-4"></code></pre>
      </div>
    </PanelBody>
  </Panel>

  <BaseSpacer />

  <Panel>
    <PanelHeading>Options</PanelHeading>
    <PanelBody>
      <Heading :size="HeadingSizeEnum.XL">Show Details</Heading>
      <BaseText>
        <BasePill> <strong>details</strong>: true|false </BasePill>
        (boolean) default is `true`
      </BaseText>

      <BaseText
        >Display details about the given Ship or just a minimal
        version.</BaseText
      >

      <Heading :size="HeadingSizeEnum.XL">Grouped View</Heading>

      <BaseText>
        <BasePill> <strong>grouped</strong>: true|false </BasePill>
        (boolean) default is `true`
      </BaseText>
      <BaseText
        >Group duplicated Ships and Show a count on each Ship Panel.</BaseText
      >

      <Heading :size="HeadingSizeEnum.XL">Render as Fleetchart</Heading>

      <BaseText>
        <BasePill> <strong>fleetchart</strong>: true|false </BasePill>
        (boolean) default is `false`
      </BaseText>
      <BaseText
        >Display the Fleetview as a Fleetchart with correct Ship Dimensions.
      </BaseText>

      <Heading :size="HeadingSizeEnum.XL">Grouped View for Fleetchart</Heading>

      <BaseText>
        <BasePill> <strong>fleetchartGrouped</strong>: true|false </BasePill>
        (boolean) default is `false`
      </BaseText>
      <BaseText>Group duplicated Ships in the Fleetchart</BaseText>

      <Heading :size="HeadingSizeEnum.XL">Initial Fleetchart Scale</Heading>

      <BaseText>
        <BasePill> <strong>fleetchartScale</strong>: 50 </BasePill>
        (int) default is `50`
      </BaseText>
      <BaseText>
        Set the initial Scale of the Fleetchart, can be between 10 - 300 for
        Desktop and 10 - 100 for Mobile.
      </BaseText>

      <Heading :size="HeadingSizeEnum.XL">Show Fleetchart Slider</Heading>

      <BaseText>
        <BasePill> <strong>fleetchartSlider</strong>: true|false </BasePill>
        (boolean) default is `false`
      </BaseText>
      <BaseText
        >Display a slider to allow users to scale the Fleetchart.</BaseText
      >

      <Heading :size="HeadingSizeEnum.XL">Ships List</Heading>

      <BaseText>
        <BasePill> <strong>ships</strong>: [] </BasePill>
        (Array of Strings) default is `[]`
      </BaseText>
      <BaseText>
        The Fleetview expects a List of Shipnames (slugs). If you want to have
        Ships multiple times in the Fleetview just add them multiple times to
        the list. To be able to resolve the correct Ships from the
        Fleetyards.net API you need to provide every Shipname (slug) in the
        correct Format. Please use
        <a href="https://api.fleetyards.net/v1/models/slugs" target="_blank">
          https://api.fleetyards.net/v1/models/slugs
        </a>
        to fetch the latest Shipnames.
      </BaseText>

      <Heading :size="HeadingSizeEnum.XL">Users List</Heading>

      <BaseText>
        <BasePill><strong>users</strong>: []</BasePill>
        (Array of Strings) default is `[]`
      </BaseText>
      <BaseText>
        As an alternative to the Ships List you can also provide a list of
        Fleetyards usernames. You will than get a list of all Ships those Users
        have in there public Hangar.
      </BaseText>
    </PanelBody>
  </Panel>
</template>

<style lang="scss">
.code-highlight {
  position: relative;
  cursor: pointer;
  margin-top: 2.5rem;
  margin-bottom: 2.5rem;
  margin-left: 6rem;
  margin-right: 6rem;

  .v-code-block--tab-highlightjs-atom-one-dark-icon {
    color: $primary !important;
    fill: $primary !important;
  }

  pre {
    margin: 0 !important;
    border-radius: 0.375rem !important; // rounded
    border: 0.3em solid hsl(30, 20%, 40%);
    padding: 0.3rem;
  }

  pre > code {
    padding: 20px 15px;
    background: #282c34 !important; // atom-one-dark background
  }

  .copy-icon {
    position: absolute;
    right: 2rem;
    top: 2rem;
    opacity: 0;
    transition: opacity 0.2s;
  }

  &:hover .copy-icon {
    opacity: 1;
  }
}
</style>
