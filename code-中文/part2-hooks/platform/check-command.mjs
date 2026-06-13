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

// 檢查 Bash 指令
if (tool_name === 'Bash') {
  const command = tool_input?.command ?? ''
  const BLOCKED = ['rm -rf', 'git push --force', 'DROP TABLE']
  for (const pattern of BLOCKED) {
    if (command.includes(pattern)) {
      process.stderr.write(`已阻擋：'${pattern}' 是被禁止的指令\n`)
      process.exit(2)
    }
  }
}

process.exit(0)
