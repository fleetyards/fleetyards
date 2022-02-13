export default {
  name: 'FrontendApp',

  data() {
    return {
      text: 'Hello World',
    }
  },

  methods: {
    toggle() {
      this.text = 'Foo Bar'
    },
  },

  template: `<div @click="toggle">{{ text }}</div>`,
}
