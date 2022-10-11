import { processCommand } from './lib'

const args = process.argv.slice(2)

const [ method, path, data, url ] = processCommand(args);

console.log(url);

(async () => {
  const response = await fetch(url)
  const contentType = response.headers.get('content-type')
  if (contentType.startsWith('application/json')) {
    // console.log(JSON.stringify(await response.json(), null, '  '))
  }
  else {
    // console.log(await response.text())
  }
})()
