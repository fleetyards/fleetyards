export const scrollToAnchor = function scrollToAnchor(hash) {
  if (!hash) {
    return
  }

  const element = document.getElementById(hash.slice(1))
  if (element) {
    element.scrollIntoView()
    window.scrollBy(0, -120)
  }
}
