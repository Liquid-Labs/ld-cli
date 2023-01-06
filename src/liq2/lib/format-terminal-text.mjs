// https://misc.flogisoft.com/bash/tip_colors_and_formatting
// for testing:
// function colors() { local i=1; while (( $i <= $# )); do printf "\e[48;5;${!i}m "; i=$(( $i + 1 )); done; printf "\e[0m\n"; }
// then: colors 11 220 8
const tCodes = {
  // universal reset
  rst : { '*': "\x1b[0m" },
  // basic non-color / functional codes
  bright : { '*': "\x1b[1m" },
  bold : { '*': "\x1b[1m" }, // bold and bright are aliases
  dim : { '*': "\x1b[2m" },
  underscore : { '*': "\x1b[4m" },
  underline : { '*': "\x1b[4m" },
  blink : { '*': "\x1b[5m" },
  reverse : { '*': "\x1b[7m" },
  hidden : { '*': "\x1b[8m" },
  // semantic codes
  h1: { 
    greenOnBlack: "\x1b[38;5;226m\x1b[4m"/* canary yellow + underscore */, 
    dark: "\x1b[38;5;226m\x1b[4m", 
    light: "\x1b[92m\x1b[4m" /* bright green + underscore */ 
  },
  h2: {
    greenOnBlack: "\x1b[38;5;226m"/* canary yellow */, 
    dark: "\x1b[38;5;226m", 
    light: "\x1b[92m" /* bright green */ 
  },
  code: { greenOnBlack: "\x1b[96m"/* birght cyan */, dark: "\x1b[96m", light: "\x1b[37m"/* cyan */ }, 
  danger: { "*": "\x1b[97m\x1b[91m"/* white on bright red bg */ },
  em: { greenOnBlack: "\x1b[35m"/* magenta */, dark: "\x1b[35m", light: "\x1b[95m"/* bright magenta */ },
  error: { greenOnBlack: "\x1b[91m"/* bright red */, dark: "\x1b[91m", light: "\x1b[31m"/* red */ },
  warn: { greenOnBlack: "\x1b[93m"/* bright yellow/gold */, dark: "\x1b[93m", light: "\x1b[63m"/* yellow/gold */ },
  // alias for 'warn'
  warning: { greenOnBlack: "\x1b[93m"/* bright yellow/gold */, dark: "\x1b[93m", light: "\x1b[63m"/* yellow/gold */ },
  // standard foreground colors
  black : { '*': "\x1b[30m" },
  red : { '*': "\x1b[31m" },
  green : { '*': "\x1b[32m" },
  yellow : { '*': "\x1b[33m" }, // more of a gold, but we'll stick with the traditional names
  gold : { '*': "\x1b[33m" }, // alias for 'yellow'
  blue : { '*': "\x1b[34m" },
  magenta : { '*': "\x1b[35m" },
  cyan : { '*': "\x1b[36m" },
  lightGrey : { '*': "\x1b[37m" },
  // standard background colors
  bgBlack : { '*': "\x1b[40m" },
  bgRed : { '*': "\x1b[41m" },
  bgGreen : { '*': "\x1b[42m" },
  bgYellow : { '*': "\x1b[43m" },
  bgBlue : { '*': "\x1b[44m" },
  bgMagenta : { '*': "\x1b[45m" },
  bgCyan : { '*': "\x1b[46m" },
  bgWhite : { '*': "\x1b[47m" },
  // standard bright colors; these are the same as 'bright'/'bold' + standard color
  darkGrey : { '*': "\x1b[90m" }, // 'bright black == dark grey'
  bRed : { '*': "\x1b[91m" },
  bGreen: { '*': "\x1b[92m" },
  bYellow: { '*': "\x1b[93m" },
  bGold: { '*': "\x1b[93m" }, // == 38;5;11m
  bBlue: { '*': "\x1b[94m" },
  bMagenta: { '*': "\x1b[95m" },
  bCyan: { '*': "\x1b[96m" },
  white: { '*': "\x1b[97m" }, // 'bright grey == white'
  // extended color codes; TODO: break these out into a plugin? Really more of a demonstratino that useful atm.
  forestGreen : { '*': "\x1b[38;5;22m" },
  richYellow: { '*': "\x1b[38;5;220m" }, // brightest yellow
  canaryYellow: { '*': "\x1b[38;5;226m" }, // brightest yellow
  dYellow: { '*': "\x1b[33m\x1b[2m" },
  bgForestGreen : { '*': "\x1b[48;5;22m" }
}

const formatTerminalText = (tText) => {
  // TODO: find for now, but probably more efficient to extract the tags we need. 
  for (const [ key, code ] of Object.entries(tCodes)) {
    const replacer = new RegExp('<' + key + '>', 'g')
    tText = tText.replaceAll(replacer, code['*'] || code.greenOnBlack)
  }
  // general color code support
  tText = tText.replaceAll(/<fgc:(\d+)>/g, "\x1b[38;5;$1m")
  tText = tText.replaceAll(/<bgc:(\d+)>/g, "\x1b[48;5;$1m")
  
  return tText
}

export { formatTerminalText }
