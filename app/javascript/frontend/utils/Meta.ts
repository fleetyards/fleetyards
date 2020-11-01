import { I18n } from 'frontend/lib/I18n'

export function metaTitle($route) {
  const { title } = $route.meta
  if (title) {
    return I18n.t(`title.${title}`)
  }

  return null
}

export function head($route) {
  console.log('bar')
  return {
    title: metaTitle($route),
    titleTemplate(title) {
      if (title) {
        return `foo ${title} | ${I18n.t('app')}`
      }

      return I18n.t('app')
    },
  }
}
