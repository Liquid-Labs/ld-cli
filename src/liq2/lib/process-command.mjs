import { PORT, PROTOCOL, SERVER } from './constants'

const methods = [ 'DELETE', 'GET', 'OPTIONS', 'POST', 'PUT', 'UNBIND' ]

const extToMime = (value) => {
  switch (value) {
    case 'txt':
      return 'text/plain'; break
    case 'terminal':
      return 'text/terminal'; break
    case 'md':
    case 'markdown':
      return 'text/markdown'; break
    case 'csv':
      return 'text/csv'; break
    case 'tsv':
      return 'text/tab-separated-values'; break
    case 'pdf':
      return 'application/pdf'; break
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'; break
    default:
      return 'application/json'
  }
}

const processCommand = (args) => {
  let method
  const pathBits = []
  const data = []
  let accept = 'text/terminal, text/plain;q=0.8, application/json;q=0.5'
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
        accept = extToMime(value)
        data.push([ name, value ]) // everything should work with our without this
      }
      else if (name !== 'sendFormParam') {
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
