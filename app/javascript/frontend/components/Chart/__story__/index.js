import { storiesOf } from '@storybook/vue'
import { withInfo } from 'storybook-addon-vue-info'
import { withKnobs, select, number } from '@storybook/addon-knobs'
import Chart from '../index'

const chartTypes = {
  label: 'Type',
  options: ['pie', 'bar', 'line', 'column', 'area'],
  default: 'pie',
}

storiesOf('Chart', module)
  .addDecorator(withInfo)
  .addDecorator(withKnobs)
  .add('Chart', () => ({
    components: { Chart },
    props: {
      type: {
        default: select(
          chartTypes.label,
          chartTypes.options,
          chartTypes.default,
        ),
      },
      height: {
        default: number('Height', 400),
      },
    },
    template: `
      <Chart
        :load-data="() => {
          if (type === 'pie') {
            return [
              {
                name: 'Combat', y: 47, selected: true, sliced: true,
              },
              { name: 'Transport', y: 24 },
              { name: 'Exploration', y: 17 },
              { name: 'Competition', y: 14 },
            ]
          }
          return [
            { label: 'May. 18', count: 5, tooltip: 'May 2018' },
            { label: 'Jun. 18', count: 1, tooltip: 'June 2018' },
            { label: 'Jul. 18', count: 3, tooltip: 'July 2018' },
            { label: 'Aug. 18', count: 1, tooltip: 'August 2018' },
          ]
        }"
        :type="type"
        tooltip-type="ship"
        :height="height"
      />
    `,
  }))
