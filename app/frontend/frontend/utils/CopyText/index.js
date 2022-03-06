import Clipboard from 'clipboard'

const copyText = function copyText(text, container) {
  return new Promise((resolve, reject) => {
    const fakeElement = document.createElement('button')
    const clipboard = new Clipboard(fakeElement, {
      action() {
        return 'copy'
      },
      container: typeof container === 'object' ? container : document.body,
      text() {
        return text
      },
    })
    clipboard.on('success', (e) => {
      clipboard.destroy()
      resolve(e)
    })
    clipboard.on('error', (e) => {
      clipboard.destroy()
      reject(e)
    })
    document.body.appendChild(fakeElement)
    fakeElement.click()
    document.body.removeChild(fakeElement)
  })
}

export default copyText
