export default {
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

  name: 'FrontendApp',

  template: `<div @click="toggle">{{ text }}</div>`,
}
