import * as fs from 'node:fs/promises'
import * as fsPath from 'node:path'

import { readFJSON } from '@liquid-labs/federated-json'
import { formatTerminalText } from '@liquid-labs/terminal-text'

import { processCommand } from './lib'

const args = process.argv.slice(2);

(async() => {
  let settings
  try {
    settings = readFJSON(fsPath.join(process.env.HOME, '.liq', 'local-settings.yaml'))
  }
  catch (e) {
    if (e.code === 'ENOENT') {
      settings = {}
    }
    else {
      throw e
    }
  }

  const { fetchOpts, url } = await processCommand(args)

  fetchOpts.headers['X-CWD'] = fsPath.resolve(process.cwd())

  const response = await fetch(url, fetchOpts)

  const contentType = response.headers.get('Content-Type')
  const disposition = response.headers.get('Content-Disposition')
  // const status = response.status

  if (disposition?.startsWith('attachment')) { // save the file
    let outputFileName = 'output'
    const [, fileNameBit] = disposition.split(/;\s*/)
    if (fileNameBit.startsWith('filename=')) {
      const [, rawFileName] = fileNameBit.split(/=\s*/)
      outputFileName = fsPath.basename(rawFileName.replace(/^['"]/, '').replace(/['"]$/, ''))
    }

    await fs.writeFile(outputFileName, (await response.blob()).stream())
    console.log(`Saved '${contentType}' file '${outputFileName}'.`)
  }
  else { // output to screen
    /* if (status >= 400) { // TODO: make optional?
      const errorSource = status < 500 ? 'Client' : 'Server'
      console.error(formatTerminalText(`<error>${errorSource} error ${status}: ${response.statusText}<rst>`))
    } */
    if (contentType.startsWith('application/json')) {
      console.log(JSON.stringify(await response.json(), null, '  '))
    }
    else {
      const terminalOpts = settings?.TERMINAL || {}
      console.log(formatTerminalText(await response.text(), terminalOpts))
    }
  }
})()
