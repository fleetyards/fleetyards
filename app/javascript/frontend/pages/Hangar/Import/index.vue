<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <BreadCrumbs
          :crumbs="[{ to: { name: 'hangar' }, label: $t('nav.hangar') }]"
        />
        <h1>
          {{ $t('headlines.hangar.import') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <input
          type="file"
          :disabled="loading"
          @input="importData"
        >
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 col-animated">
        <Panel>
          <transition-group
            name="fade"
            class="flex-list"
            tag="div"
            appear
          >
            <div
              key="heading"
              class="fade-list-item col-xs-12 flex-list-heading"
            >
              <div class="flex-list-row">
                <div class="name">
                  Name
                </div>
                <div class="manufacturer">
                  Manufacturer
                </div>
                <div class="state">
                  Status
                </div>
              </div>
            </div>
            <div
              v-for="(item, index) in sortedData"
              :key="`import-${index}`"
              class="fade-list-item col-xs-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="store-image">
                  <LazyImage
                    v-if="item.found"
                    :src="item.found.storeImageMedium"
                    :alt="item.name"
                    :title="item.name"
                    class="image"
                  />
                </div>
                <div class="name">
                  {{ item.model }}
                </div>
                <div class="manufacturer">
                  {{ item.manufacturer }}
                </div>
                <div class="state">
                  {{ item.state }}
                </div>
              </div>
            </div>
          </transition-group>
        </Panel>
        <EmptyBox :visible="emptyBoxVisible" />
      </div>
    </div>
  </section>
</template>

<script>
import Papa from 'papaparse'
import Panel from 'frontend/components/Panel'
import MetaInfo from 'frontend/mixins/MetaInfo'
import LazyImage from 'frontend/components/LazyImage'
import BreadCrumbs from 'frontend/components/BreadCrumbs'

export default {
  components: {
    Panel,
    LazyImage,
    BreadCrumbs,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      ships: null,
      loading: true,
      data: null,
    }
  },

  computed: {
    emptyBoxVisible() {
      return this.data && this.data.length === 0
    },

    sortedData() {
      return this.sortBy(this.data || [], 'state')
    },
  },

  mounted() {
    this.fetchHangar()
  },

  methods: {
    async fetchHangar() {
      this.loading = true
      const response = await this.$api.get('vehicles/hangar')

      this.loading = false

      if (!response.errors) {
        this.ships = response.data
      }
    },

    async importData(event) {
      const file = event.target.files[0]

      if (!['text/csv', 'application/json'].includes(file.type)) {
        this.$alert({
          text: this.$t('messages.hangarImport.wrongFileType'),
        })
        // eslint-disable-next-line no-param-reassign
        event.target.value = ''
        return
      }

      const reader = new FileReader()

      if (file.type === 'text/csv') {
        reader.onload = await this.parseCSV
      } else {
        reader.onload = await this.parseJSON
      }

      reader.readAsText(file)
    },

    async parseCSV(event) {
      this.data = await this.matchWithHangar(this.transformData(Papa.parse(event.target.result, {
        header: true,
        skipEmptyLines: true,
      }).data))
    },

    async parseJSON(event) {
      this.data = await this.matchWithHangar(this.transformData(JSON.parse(event.target.result)))
    },

    transformData(result) {
      if (result.length === 0) {
        return []
      }

      if (!result[0].model && !result[0].name) {
        this.$alert({
          text: this.$t('messages.hangarImport.wrongStructure'),
        })
        return null
      }

      if (result[0].model) {
        return result
      }

      return result.map((item) => ({
        ...item,
        model: item.name,
        modelSlug: this.transformSlug(item.name),
      }))
    },

    async matchWithHangar(items) {
      const currentHangar = JSON.parse(JSON.stringify(this.ships))

      const matchedItems = await items.map((item) => {
        const found = currentHangar.find((vehicle) => vehicle.modelSlug === item.modelSlug)

        let state = 'new'

        if (found) {
          const index = currentHangar.findIndex((vehicle) => vehicle.modelSlug === found.modelSlug)
          currentHangar.splice(index, 1)
          state = 'replace'
        }

        return {
          ...item,
          state,
          found,
        }
      })

      matchedItems.forEach(async (item) => {
        if (item.found) {
          return
        }
        const response = await this.$api.get(`models/${item.modelSlug}`)
        if (!response.errors) {
          // eslint-disable-next-line no-param-reassign
          item.found = response.data
        }
      })

      return [
        ...matchedItems,
        ...currentHangar.map((vehicle) => ({
          ...vehicle,
          state: 'destroy',
        })),
      ]
    },

    transformSlug(text) {
      let slug = text.trim()
      slug = slug.replace(/[ö]/g, 'oe')
      slug = slug.replace(/[ü]/g, 'ue')
      slug = slug.replace(/[ä]/g, 'ae')
      slug = slug.replace(/[ß]/g, 'ss')
      slug = slug.replace(/[Ä]/g, 'Ae')
      slug = slug.replace(/[Ö]/g, 'Oe')
      slug = slug.replace(/[Ü]/g, 'Ue')
      slug = slug.replace(/[éèê]/g, 'e')
      slug = slug.replace(/[àáâ]/g, 'a')
      slug = slug.replace(/[óòô]/g, 'o')
      slug = slug.replace(/[íìî]/g, 'i')
      slug = slug.replace(/[ùúû]/g, 'u')
      slug = slug.replace(/\s/g, '-')
      slug = slug.replace(/\-\-/g, '-')
      slug = slug.replace(/\-\-/g, '-')
      slug = slug.replace(/\./g, '')
      slug = slug.toLowerCase()

      return slug
    },

    rowState(item) {
      if (item.found) {
        return 'nothing'
      }

      return 'create'
    },
  },
}
</script>
