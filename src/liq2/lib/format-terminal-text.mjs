// https://misc.flogisoft.com/bash/tip_colors_and_formatting
const tCodes = {
  rst : "\x1b[0m",
  
  bright : "\x1b[1m",
  bold : "\x1b[1m",
  dim : "\x1b[2m",
  underscore : "\x1b[4m",
  blink : "\x1b[5m",
  
  reverse : "\x1b[7m",
  hidden : "\x1b[8m",
  
  black : "\x1b[30m",
  red : "\x1b[31m",
  green : "\x1b[32m",
  yellow : "\x1b[33m",
  blue : "\x1b[34m",
  magenta : "\x1b[35m",
  cyan : "\x1b[36m",
  white : "\x1b[37m",
  
  bGreen: "\x1b[92m",
  bYellow: "\x1b[93m",
  
  dYellow: "\x1b[33m\x1b[2m",
  
  bgBlack : "\x1b[40m",
  bgRed : "\x1b[41m",
  bgGreen : "\x1b[42m",
  bgYellow : "\x1b[43m",
  bgBlue : "\x1b[44m",
  bgMagenta : "\x1b[45m",
  bgCyan : "\x1b[46m",
  bgWhite : "\x1b[47m",
  
  dBgGreen : "\x1b[48;5;22m",
}

const formatTerminalText = (tText) => {
  for (const [ key, code ] of Object.entries(tCodes)) {
    const replacer = new RegExp('<' + key + '>', 'g')
    tText = tText.replaceAll(replacer, code)
  }
  
  return tText
}

export { formatTerminalText }
