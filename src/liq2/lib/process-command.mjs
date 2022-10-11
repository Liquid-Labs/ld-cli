import { PORT, PROTOCOL, SERVER } from './constants'

const methods = [ 'DELETE', 'GET', 'OPTIONS', 'POST', 'PUT', 'UNBIND' ]

const processCommand = (args) => {
  let method
  const pathBits = []
  const data = []
  let accept = 'application/json'
  let setParams = false
  
  if (methods.includes(args[0])) {
    method = args[0].toLowerCase()
    args.shift()
  }

  for (const arg of args) {
    if (arg === '--') {
      setParams = true
    }
    else if (!setParams === true) {
      pathBits.push(encodeURIComponent(arg))
    }
    else { // setup params
      const [ name, value = 'true' ] = arg.split(/\s*=\s*/)
      if (name === 'format') {
        switch (value) {
          case 'md':
          case 'markdown':
            accept='text/markdown'; break
          case 'csv':
            accept='text/csv'; break
          case 'tsv':
            accept='text/tab-separated-values'; break
          case 'pdf':
            accept='application/pdf'
          case 'docx':
            accept='application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          default:
            accept='application/json'
        }
      }
      else {
        data.push([ name, value ])
      }
    }
  }

  if (method === undefined) {
    switch (pathBits[pathBits.length - 1]) {
      case 'create':
        method = 'post'; break
      case 'delete':
        method = 'delete'; break
      case 'options':
        method = 'options'; break
      case 'update':
        method = 'put'; break
      case 'quit':
        method = 'unbind'; break
      default:
        method = 'get'
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
