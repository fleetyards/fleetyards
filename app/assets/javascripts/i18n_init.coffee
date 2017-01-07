$(document).on 'ready page:load', ->
  for bundledLocale of bundledLocales
    storedLocale = window.localStorage.getItem("res_#{bundledLocale}")?
    unless storedLocale?
      object = {}
      object[bundledLocale] = bundledLocales[bundledLocale]
      i18n.sync._storeLocal object

  i18n.init({
    # change default interpolation from __VARIABLE__ to rails-style %{VARIABLE}
    interpolationPrefix: '%{'
    interpolationSuffix: '}'
    fallbackLng: "en"

    # current locale to load
    lng: locale

    # rails-asset-localization path
    resGetPath: '/locales/%{lng}.json'

    # store locales for 1 day in localStorage
    useLocalStorage: true
    localStorageExpirationTime: 60 * 60 * 24 * 1000
  })
