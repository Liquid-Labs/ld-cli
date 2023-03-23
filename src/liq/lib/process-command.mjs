import * as fs from 'node:fs/promises'

import { PORT, PROTOCOL, SERVER } from './constants'

const methods = ['DELETE', 'GET', 'OPTIONS', 'POST', 'PUT', 'UNBIND']

const extToMime = (value) => {
  switch (value) {
  case 'txt':
    return 'text/plain'
  case 'terminal':
    return 'text/terminal'
  case 'md':
  case 'markdown':
    return 'text/markdown'
  case 'csv':
    return 'text/csv'
  case 'tsv':
    return 'text/tab-separated-values'
  case 'pdf':
    return 'application/pdf'
  case 'docx':
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  default:
    return 'application/json'
  }
}

const processCommand = async(args) => {
  let method
  const pathBits = []
  const data = []
  let accept = 'text/terminal, text/plain;q=0.8, application/json;q=0.5'
  let setParams = false

  if (methods.includes(args[0]?.toUpperCase())) {
    method = args[0]
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
      let [name, value = 'true', ...moreValue] = arg.split(/=/)
      // there may be '=' in the parameter value, so we re-build it
      value = [value, ...moreValue].join('=')
      if (name === 'format') {
        accept = extToMime(value)
        data.push([name, value]) // everything should work with our without this
      }
      else if (name !== 'sendFormParam') {
        data.push([name, value])
      }
    }
  }
  // if there are no parameters, then we need to
  const path = '/' + pathBits.join('/')
  const api = JSON.parse(await fs.readFile(process.env.HOME + '/.liq/core-api.json'))
  const endpointSpec = api.find((s) => path.match(new RegExp(s.matcher)))

  if (method === undefined && endpointSpec) {
    if (!endpointSpec && !process.env.TEST_MODE) {
      throw new Error(`Did not find endpoint for path: ${path}`)
    }

    method = endpointSpec?.method || (process.env.TEST_MODE && 'GET')
  }

  const query = data.length > 0 && method !== 'POST' ? '?' + new URLSearchParams(data).toString() : ''
  const url = `${PROTOCOL}://${SERVER}:${PORT}${path}${query}`

  const fetchOpts = {
    headers : {
      Accept : accept
    },
    method
  }

  if (method === 'POST') {
    fetchOpts.headers['Content-Type'] = 'application/json'

    const indexdData = data.reduce((acc, [n, v]) => {
      // if we got a bad path, then endpoint spec won't be defined; but we want the server to handle it, so we move on
      const paramSpec = endpointSpec?.parameters.find((p) => p.name === n)
      if (paramSpec?.isMultivalue === true) {
        const currArray = acc[n] || []
        currArray.push(v)
        acc[n] = currArray
      }
      else {
        acc[n] = v
      }

      return acc
    }, {})

    fetchOpts.body = JSON.stringify(indexdData)
  }

  return { // 'data', 'method', and 'path' are not currently consumed in the progarm, but are useful for testing
    data,
    fetchOpts,
    method,
    path,
    url
  }
}

export { processCommand }
