import * as fs from 'node:fs/promises'
import * as sysPath from 'node:path'

import { processCommand } from './lib'

const args = process.argv.slice(2)

const { accept, method, path, data, url } = processCommand(args);

(async () => {
  const response = await fetch(url, {
    headers: {
      'Accept': accept
    },
    method
  })
  const contentType = response.headers.get('Content-Type')
  const disposition = response.headers.get('Content-Disposition')
  if (disposition?.startsWith('attachment')) { // save the file
    let outputFileName = 'output'
    const [ , fileNameBit ] = disposition.split(/;\s*/)
    if (fileNameBit.startsWith('filename=')) {
      const [ , rawFileName ] = fileNameBit.split(/=\s*/)
      outputFileName = sysPath.basename(rawFileName)
    }
    
    await fs.writeFile(outputFileName, (await response.blob()).stream())
    console.log(`Saved '${contentType}' file '${outputFileName}'.`)
  }
  else { // output to screen
    if (contentType.startsWith('application/json')) {
      console.log(JSON.stringify(await response.json(), null, '  '))
    }
    else {
      console.log(await response.text())
    }
  }
})()
