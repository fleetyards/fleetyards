import { storiesOf } from '@storybook/vue'
import { withInfo } from 'storybook-addon-vue-info'
import { withKnobs, boolean } from '@storybook/addon-knobs'
import SmallLoader from '../index'

const info = {
  // https://github.com/pocka/storybook-addon-vue-info
}

storiesOf('SmallLoader', module)
  .addDecorator(withInfo)
  .addDecorator(withKnobs)
  .add('SmallLoader', () => ({
    components: { SmallLoader },
    props: {
      loading: {
        default: boolean('Loading', true),
      },
    },
    template: '<SmallLoader :loading="loading" />',
  }), { info })
