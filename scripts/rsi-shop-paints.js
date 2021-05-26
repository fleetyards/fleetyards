window.open('https://robertsspaceindustries.com/store/pledge/browse/268')
// eslint-disable-next-line prefer-const
let paints = []
document.getElementsByClassName('CardItem').forEach(item => {
  const paint = {
    name: item.querySelector('.SkuWidget-main-title').textContent,
    store_url: item.querySelector('.SkuWidget-link a').href,
    image: item.querySelector('.SkuWidget-image img').src,
  }
  paints.push(paint)
})
// eslint-disable-next-line prefer-const
let dataStr = `data:text/json;charset=utf-8,${encodeURIComponent(
  JSON.stringify(paints),
)}`
// eslint-disable-next-line prefer-const
let downloadAnchorNode = document.createElement('a')
downloadAnchorNode.setAttribute('href', dataStr)
downloadAnchorNode.setAttribute('download', 'paints.json')
document.body.appendChild(downloadAnchorNode)
downloadAnchorNode.click()
downloadAnchorNode.remove()
