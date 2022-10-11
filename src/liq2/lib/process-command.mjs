const methods = [ 'DELETE', 'GET', 'OPTIONS', 'POST', 'PUT', 'UNBIND' ]

const processCommand = (args) => {
  const pathBits = []
  const parameters = []
  let setParams = false

  let method
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
      parameters.push([ encodeURIComponent(name), encodeURIComponent(value) ])
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

  return [
    method,
    '/' + pathBits.join('/'),
    parameters
  ]
}

export { processCommand }
