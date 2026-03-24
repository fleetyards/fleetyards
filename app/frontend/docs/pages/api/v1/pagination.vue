<script lang="ts">
export default {
  name: "ApiPaginationPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'api-v1' }, label: t('nav.apiV1') }]"
  />

  <Heading :size="HeadingSizeEnum.HERO" hero>Pagination</Heading>

  <Panel>
    <PanelBody>
      <BaseText>
        Requests that return multiple items will be paginated to
        <code class="hljs p-1 rounded">30</code> items by default. You can
        specify further pages with the
        <code class="hljs p-1 rounded">?page</code> parameter. For some
        resources, you can also set a custom page size up to
        <code class="hljs p-1 rounded">200</code> with the
        <code class="hljs p-1 rounded">?perPage</code> parameter. Note that for
        technical reasons not all endpoints respect the
        <code class="hljs p-1 rounded">?perPage</code> parameter, see events for
        example.
      </BaseText>

      <BaseText>
        <code class="hljs p-1 rounded"
          >curl 'https://api.fleetyards.net/models?page=2&perPage=200'</code
        >
      </BaseText>
      <BaseText>
        Note that page numbering is 1-based and that omitting the
        <code class="hljs p-1 rounded">?page</code> parameter will return the
        first page.
      </BaseText>

      <h3 class="text-xl font-semibold">Link Header</h3>

      <BaseText>The Link header includes pagination information:</BaseText>

      <BaseText>
        <code class="hljs p-1 rounded"
          >Link: &lt;https://api.fleetyards.net/models?page=1&perPage=200&gt;;
          rel="next",<br />
          &lt;https://api.fleetyards.net/models?page=2&perPage=200&gt;;
          rel="last"</code
        >
      </BaseText>

      <BaseText>The example includes a line break for readability.</BaseText>

      <BaseText>
        This Link response header contains one or more Hypermedia link
        relations, some of which may require expansion as URI templates.
      </BaseText>

      <BaseText>
        The possible <code class="hljs p-1 rounded">rel</code> values are:
      </BaseText>

      <table class="table-auto w-full mb-4">
        <thead>
          <tr>
            <th class="px-4 py-2">Name</th>
            <th class="px-4 py-2">Description</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class="border px-4 py-2">next</td>
            <td class="border px-4 py-2">
              The link relation for the immediate next page of results.
            </td>
          </tr>
          <tr>
            <td class="border px-4 py-2">last</td>
            <td class="border px-4 py-2">
              The link relation for the last page of results.
            </td>
          </tr>
          <tr>
            <td class="border px-4 py-2">first</td>
            <td class="border px-4 py-2">
              The link relation for the first page of results.
            </td>
          </tr>
          <tr>
            <td class="border px-4 py-2">prev</td>
            <td class="border px-4 py-2">
              The link relation for the immediate previous page of results.
            </td>
          </tr>
        </tbody>
      </table>
    </PanelBody>
  </Panel>
</template>
