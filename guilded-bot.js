const WebSocket = require('ws')

// config
const token =
  'c9aIvGbaayMzP3nNmIblARHyjYqvyAsk571NrJ1QV2+mWAAeGKRPM3kOG8eXfEEsVBV8x0T5xZoPuXhgmEr1Eg=='

let reconnectTimer = null
function stopOtherReconnects() {
  if (reconnectTimer) {
    clearTimeout(reconnectTimer)
    reconnectTimer = null
  }
}

function connect() {
  const socket = new WebSocket(`wss://api.guilded.gg/v1/websocket`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  })

  socket.on('open', () => {
    stopOtherReconnects()
    console.info('connected to Guilded!')
  })

  socket.on('close', () => {
    socket.terminate()
    stopOtherReconnects()
    reconnectTimer = setTimeout(reconnect, 5000)
  })

  socket.on('message', (data) => {
    const { t: eventType, d: eventData } = JSON.parse(data)

    if (
      eventType === 'ChatMessageCreated' ||
      eventType === 'ChatMessageUpdated'
    ) {
      const {
        message: { id: messageId, content, channelId },
      } = eventData

      if (content.indexOf('yards bot') >= 0) {
        console.log(content)
      }
    }
  })

  return socket
}

function reconnect() {
  console.info('attempting to connect...')
  stopOtherReconnects()
  const socket = connect()
  reconnectTimer = setTimeout(() => {
    socket.terminate()
    reconnect()
  }, 5000)
}

reconnect()
