<template>
  <Btn
    :size="size"
    :variant="variant"
    :aria-label="$t('actions.import')"
    :disabled="disabled"
    @click.native="selectFile"
  >
    <i class="fal fa-upload" />
    <span>
      {{ $t('actions.import') }}
      <VueUploadComponent
        ref="upload"
        name="uploadAvatar"
        :extensions="fileExtensions"
        :accept="acceptedMimeTypes"
        class="hangar-importer"
        @input="importJson"
        @input-filter="inputFilter"
      />
    </span>
  </Btn>
</template>

<script>
import VueUploadComponent from 'vue-upload-component'
import Btn from '@/frontend/core/components/Btn/index.vue'
import {
  displayWarning,
  displayAlert,
  displaySuccess,
  displayConfirm,
} from '@/frontend/lib/Noty'

export default {
  name: 'HangarImportBtn',

  components: {
    Btn,
    VueUploadComponent,
  },

  props: {
    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },

    variant: {
      type: String,

      default: 'default',
      validator(value) {
        return (
          ['default', 'transparent', 'link', 'danger', 'dropdown'].indexOf(
            value
          ) !== -1
        )
      },
    },
  },

  data() {
    return {
      acceptedMimeTypes: 'application/json',
      disabled: false,
      fileExtensions: 'json',
    }
  },

  computed: {
    fileExtensionsList() {
      return this.fileExtensions.split(',')
    },
  },

  methods: {
    async importJson(value) {
      const importFile = (value && value[0]) || {}

      if (!importFile || !importFile.file) {
        return
      }

      const uploadData = new FormData()
      uploadData.append('import', importFile.file)

      // @ts-ignore
      const response = await this.$api.upload('vehicles/import', uploadData)

      this.disabled = false

      if (response.error || !response.data.success) {
        displayAlert({
          // @ts-ignore
          text: this.$t('messages.hangarImport.failure'),
        })
        return
      }

      const { data } = response

      if (data.missing.length) {
        displayWarning({
          // @ts-ignore
          text: this.$t('messages.hangarImport.partialSuccess', {
            missing: `- ${data.missing.join('<br>- ')}`,
          }),
          timeout: null,
        })
      } else {
        displaySuccess({
          // @ts-ignore
          text: this.$t('messages.hangarImport.success'),
        })
      }

      this.$emit('uploaded')
    },

    inputFilter(newFile, oldFile, prevent) {
      if (newFile && !oldFile) {
        if (
          !this.fileExtensionsList.some((extension) =>
            newFile.name.endsWith(extension)
          )
        ) {
          displayAlert({
            // @ts-ignore
            text: this.$t('messages.hangarImport.invalidExtension', {
              extensions: this.fileExtensions,
            }),
          })
          return prevent()
        }
      }
      if (newFile && (!oldFile || newFile.file !== oldFile.file)) {
        // eslint-disable-next-line no-param-reassign
        newFile.url = ''
        const URL = window.URL || window.webkitURL
        if (URL && URL.createObjectURL) {
          // eslint-disable-next-line no-param-reassign
          newFile.url = URL.createObjectURL(newFile.file)
        }
      }

      return null
    },

    selectFile() {
      this.disabled = true

      displayConfirm({
        onCancel: () => {
          this.disabled = false
        },
        onConfirm: async () => {
          this.$refs.upload.$el.querySelector('input').click()
        },
        text: this.$t('messages.confirm.hangar.import'),
      })
    },
  },
}
</script>
