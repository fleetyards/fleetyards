import { storiesOf } from '@storybook/vue'
import { withInfo } from 'storybook-addon-vue-info'
import { withKnobs, text, boolean } from '@storybook/addon-knobs'
import Box from '../index'

const info = {
  // https://github.com/pocka/storybook-addon-vue-info
}

storiesOf('Box', module)
  .addDecorator(withInfo)
  .addDecorator(withKnobs)
  .add('Box', () => ({
    components: { Box },
    props: {
      large: {
        default: boolean('Large', false),
      },
    },
    template: `
      <Box
        :large="large"
      >
        ${text('Content', 'Test Content')}
      </Box>
    `,
  }), { info })
