import ViewNotFound from 'frontend/pages/NotFound'

export default (componentImport) => async () => {
  const { default: component } = await componentImport()

  const props = component.props || {}

  if (component.mixins) {
    component.mixins.forEach((mixin) => {
      if (mixin.props) {
        Object.assign(props, mixin.props)
      }
    })
  }

  return {
    name: 'NotFound',

    props,

    metaInfo() {
      if (this.is404) {
        return {
          title: 'Seite nicht gefunden (Error 404)',
          meta: [
            {
              vmid: 'robots',
              name: 'robots',
              content: 'noindex,follow',
            },
          ],
        }
      }

      return {}
    },

    computed: {
      is404() {
        return this.$route.meta.httpCode === 404
      },
    },

    render(h) {
      return this.is404
        ? h(ViewNotFound)
        : h(component, { props: this.$options.propsData })
    },
  }
}
