<template>
  <Btn
    :size="size"
    :variant="variant"
    :aria-label="$t('actions.import')"
    :disabled="disabled"
    @click.native="selectFile"
  >
    <i class="fal fa-upload" />
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
  </Btn>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import VueUploadComponent from 'vue-upload-component'
import Btn from 'frontend/components/Btn'

@Component({
  components: {
    VueUploadComponent,
    Btn,
  },
})
export default class HangarImportBtn extends Vue {
  fileExtensions = 'json'

  disabled = false

  acceptedMimeTypes = 'application/json'

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'transparent', 'link', 'danger'].indexOf(value) !== -1
    },
  })
  variant!: string

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'small', 'large'].indexOf(value) !== -1
    },
  })
  size!: string

  get fileExtensionsList() {
    return this.fileExtensions.split(',')
  }

  selectFile() {
    this.disabled = true

    // @ts-ignore
    this.$confirm({
      // @ts-ignore
      text: this.$t('messages.confirm.hangar.import'),
      onConfirm: async () => {
        // @ts-ignore
        this.$refs.upload.$el.querySelector('input').click()
      },
      onCancel: () => {
        this.disabled = false
      },
    })
  }

  inputFilter(newFile, oldFile, prevent) {
    if (newFile && !oldFile) {
      if (
        !this.fileExtensionsList.some(extension =>
          newFile.name.endsWith(extension),
        )
      ) {
        // @ts-ignore
        this.$alert({
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
  }

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
      // @ts-ignore
      this.$alert({
        // @ts-ignore
        text: this.$t('messages.hangarImport.failure'),
      })
      return
    }

    const { data } = response

    if (data.missing.length) {
      // @ts-ignore
      this.$warning({
        // @ts-ignore
        text: this.$t('messages.hangarImport.partialSuccess', {
          missing: `- ${data.missing.join('<br>- ')}`,
        }),
        timeout: null,
      })
    } else {
      // @ts-ignore
      this.$success({
        // @ts-ignore
        text: this.$t('messages.hangarImport.success'),
      })
    }

    this.$emit('uploaded')
  }
}
</script>
