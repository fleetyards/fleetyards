export default {
  install(Vue) {
    Vue.mixin({
      methods: {
        groupBy(list, key) {
          return list.reduce((rv, x) => {
            const value = JSON.parse(JSON.stringify(rv))

            value[x[key]] = rv[x[key]] || []
            value[x[key]].push(x)

            return value
          }, {})
        },
        sortBy(list, key, decending = false) {
          return list.sort((a, b) => {
            if (decending) {
              if (a[key] < b[key]) {
                return 1
              }
              if (a[key] > b[key]) {
                return -1
              }
            } else {
              if (a[key] < b[key]) {
                return -1
              }
              if (a[key] > b[key]) {
                return 1
              }
            }
            return 0
          })
        },
      },
    })
  },
}
