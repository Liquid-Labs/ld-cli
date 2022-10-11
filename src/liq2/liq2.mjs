import { processCommand } from './lib'

const args = process.argv.slice(2)


const [ method, path, data, url ] = processCommand(args)
