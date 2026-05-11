#!/usr/bin/env node
// check-command.mjs

import { createInterface } from 'readline'

async function readStdin() {
  const rl = createInterface({ input: process.stdin })
  const lines = []
  for await (const line of rl) {
    lines.push(line)
  }
  return JSON.parse(lines.join('\n'))
}

const input = await readStdin()
const { tool_name, tool_input } = input

// Check Bash commands
if (tool_name === 'Bash') {
  const command = tool_input?.command ?? ''
  const BLOCKED = ['rm -rf', 'git push --force', 'DROP TABLE']
  for (const pattern of BLOCKED) {
    if (command.includes(pattern)) {
      process.stderr.write(`Blocked: '${pattern}' is a prohibited command\n`)
      process.exit(2)
    }
  }
}

process.exit(0)
