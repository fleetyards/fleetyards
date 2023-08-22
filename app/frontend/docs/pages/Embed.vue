<template>
  <main class="embed-page">
    <div class="px-4 sm:px-6 lg:px-8 py-6">
      <div class="p-6 bg-brand-grayBgDark/80 rounded">
        <h1 class="font-hero text-4xl mb-5">Embed Fleetview</h1>

        <h2 class="text-2xl my-5">Setup</h2>

        <p>
          To get a custom Ship List on your Website you can just paste the
          example code on the right side at the position where you want to
          render a Ship List.
        </p>

        <div
          class="md:mx-24 my-10 relative group cursor-pointer"
          @click="copyExample"
        >
          <i
            class="fas fa-copy absolute right-2 top-8 opacity-0 transition-opacity group-hover:opacity-100"
          ></i>
          <pre v-highlightjs="widgetExample">
            <code class="javascript rounded !py-5 !px-4">
            </code>
          </pre>
        </div>

        <h2 class="text-2xl my-5">Options</h2>

        <h3 class="text-xl my-5">Show Details</h3>

        <p class="mb-3">
          <span class="bg-gray-700 px-2 py-1 mr-1 rounded">
            <strong>details</strong>: true|false
          </span>
          (boolean) default is `true`
        </p>

        <p>Display details about the given Ship or just a minimal version.</p>

        <h3 class="text-xl my-5">Grouped View</h3>

        <p class="mb-3">
          <span class="bg-gray-700 px-2 py-1 mr-1 rounded">
            <strong>grouped</strong>: true|false
          </span>
          (boolean) default is `true`
        </p>
        <p>Group duplicated Ships and Show a count on each Ship Panel.</p>

        <h3 class="text-xl my-5">Render as Fleetchart</h3>

        <p class="mb-3">
          <span class="bg-gray-700 px-2 py-1 mr-1 rounded">
            <strong>fleetchart</strong>: true|false
          </span>
          (boolean) default is `false`
        </p>
        <p>
          Display the Fleetview as a Fleetchart with correct Ship Dimensions.
        </p>

        <h3 class="text-xl my-5">Grouped View for Fleetchart</h3>

        <p class="mb-3">
          <span class="bg-gray-700 px-2 py-1 mr-1 rounded">
            <strong>fleetchartGrouped</strong>: true|false
          </span>
          (boolean) default is `false`
        </p>
        <p>Group duplicated Ships in the Fleetchart</p>

        <h3 class="text-xl my-5">Initial Fleetchart Scale</h3>

        <p class="mb-3">
          <span class="bg-gray-700 px-2 py-1 mr-1 rounded">
            <strong>fleetchartScale</strong>: 50
          </span>
          (int) default is `50`
        </p>
        <p>
          Set the initial Scale of the Fleetchart, can be between 10 - 300 for
          Desktop and 10 - 100 for Mobile.
        </p>

        <h3 class="text-xl my-5">Show Fleetchart Slider</h3>

        <p class="mb-3">
          <span class="bg-gray-700 px-2 py-1 mr-1 rounded">
            <strong>fleetchartSlider</strong>: true|false
          </span>
          (boolean) default is `false`
        </p>
        <p>Display a slider to allow users to scale the Fleetchart.</p>

        <h3 class="text-xl my-5">Ships List</h3>

        <p class="mb-3">
          <span class="bg-gray-700 px-2 py-1 mr-1 rounded">
            <strong>ships</strong>: []
          </span>
          (Array of Strings) default is `[]`
        </p>
        <p>
          The Fleetview expects a List of Shipnames (slugs). If you want to have
          Ships multiple times in the Fleetview just add them multiple times to
          the list. To be able to resolve the correct Ships from the
          Fleetyards.net API you need to provide every Shipname (slug) in the
          correct Format. Please use
          <a href="https://api.fleetyards.net/v1/models/slugs" target="_blank">
            https://api.fleetyards.net/v1/models/slugs
          </a>
          to fetch the latest Shipnames.
        </p>

        <h3 class="text-xl my-5">Users List</h3>

        <p class="mb-3">
          <span class="bg-gray-700 px-2 py-1 mr-1 rounded">
            <strong>users</strong>: []
          </span>
          (Array of Strings) default is `[]`
        </p>
        <p>
          As an alternative to the Ships List you can also provide a list of
          Fleetyards usernames. You will than get a list of all Ships those
          Users have in there public Hangar.
        </p>
      </div>
    </div>
  </main>
</template>

<script lang="ts" setup>
import "highlight.js";
import "highlight.js/styles/atom-one-dark.css";
import copyText from "@/shared/utils/CopyText";
import { useI18n } from "@/docs/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";

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
        users: ['torlekmaru', 'johndoe'], // Replace the Array with a list of Fleetyards.net usernames, alternative to the ships option.
        fleetId: 'maru', // Replace the value with a your Fleetyards.net fleet id, alternative to the ships option.
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

const { displayInfo, displayAlert } = useNoty(t);

const copyExample = () => {
  copyText(widgetExample).then(
    () => {
      displayInfo({
        text: t("messages.copyWidgetExample.success"),
      });
    },
    () => {
      displayAlert({
        text: t("messages.copyWidgetExample.failure"),
      });
    },
  );
};
</script>

<script lang="ts">
export default {
  name: "EmbedPage",
};
</script>

<style lang="scss">
.code-highlight {
  .v-code-block--tab-highlightjs-atom-one-dark-icon {
    color: $primary !important;
    fill: $primary !important;
  }

  pre > code {
    padding: 20px 15px;
  }
}
</style>
