import { PORT, PROTOCOL, SERVER } from './constants'

const methods = [ 'DELETE', 'GET', 'OPTIONS', 'POST', 'PUT', 'UNBIND' ]

const processCommand = (args) => {
  let method
  const pathBits = []
  const data = []
  let accept = 'text/plain, application/json;q=0.5'
  let setParams = false
  
  if (methods.includes(args[0])) {
    method = args[0].toLowerCase()
    args.shift()
  }

  for (const arg of args) {
    if (arg === '--' && setParams === false) {
      setParams = true
    }
    else if (setParams !== true) {
      pathBits.push(encodeURIComponent(arg))
    }
    else { // setup params
      let [ name, value = 'true', ...moreValue ] = arg.split(/\s*=\s*/)
      value = [value, ...moreValue].join('=')
      if (name === 'format') {
        switch (value) {
          case 'txt':
            accept='text/plain'; break
          case 'terminal':
            accept='text/terminal'; break
          case 'md':
          case 'markdown':
            accept='text/markdown'; break
          case 'csv':
            accept='text/csv'; break
          case 'tsv':
            accept='text/tab-separated-values'; break
          case 'pdf':
            accept='application/pdf'; break
          case 'docx':
            accept='application/vnd.openxmlformats-officedocument.wordprocessingml.document'; break
          default:
            accept='application/json'
        }
        // 'sendAcceptOnly' is a 'secret' parameter that supresses the default behavior of sending the 'format' as a URL
        // query param and instead only sends the 'Accept' headers (usually it does both).
        if (!args.includes('sendAcceptOnly')) {
          data.push([ name, value ]) // everything should work with our without this
        }
      }
      else if (name !== 'sendAcceptOnly') {
        data.push([ name, value ])
      }
    }
  }

  if (method === undefined) {
    switch (pathBits[pathBits.length - 1]) {
      case 'create':
        method = 'POST'; break
      case 'delete':
        method = 'DELETE'; break
      case 'options':
        method = 'OPTIONS'; break
      case 'update':
        method = 'PATCH'; break
      case 'build':
      case 'publish':
      case 'refresh':
        method = 'PUT'; break
      case 'quit':
      case 'stop':
        method = 'UNBIND'; break
      default:
        method = 'GET'
    }
  }
  
  const path = '/' + pathBits.join('/')
  
  const query = data.length > 0 && method !== 'post' ? '?' + new URLSearchParams(data).toString() : ''
  const url = `${PROTOCOL}://${SERVER}:${PORT}${path}${query}`

  return {
    accept,
    method,
    path,
    data,
    url,
  }
}

export { processCommand }
