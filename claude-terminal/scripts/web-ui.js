#!/usr/bin/env node
/**
 * Claude Terminal Web UI
 * Serves a custom page with action buttons + embedded ttyd terminal.
 * Buttons control the tmux session via a small API.
 */

const http = require('http');
const { execSync, exec } = require('child_process');
const TTYD_PORT = 7682;
const UI_PORT = 7681;
const TMUX_SESSION = 'claude';

// Ensure tmux session exists
function ensureTmux() {
  try {
    execSync(`tmux has-session -t ${TMUX_SESSION} 2>/dev/null`);
  } catch {
    // Create session with a waiting bash
    execSync(`tmux new-session -d -s ${TMUX_SESSION} -x 200 -y 50 bash`);
  }
}

// Send command to tmux session
function tmuxSend(cmd) {
  ensureTmux();
  // Kill any running process first (Ctrl-C), then send command
  execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`);
  execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`);
  // Small delay then send
  setTimeout(() => {
    execSync(`tmux send-keys -t ${TMUX_SESSION} '${cmd}' Enter`);
  }, 300);
}

const HTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<script>
  // Ensure base URL ends with / for relative paths to work with HA ingress
  if (!window.location.pathname.endsWith('/')) {
    window.location.pathname += '/';
  }
</script>
<base href="">
<title>Claude Terminal</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { height: 100%; background: #1a1b26; color: #c0caf5; font-family: -apple-system, system-ui, sans-serif; overflow: hidden; }

  .toolbar {
    display: flex;
    gap: 8px;
    padding: 8px 12px;
    background: #24283b;
    border-bottom: 1px solid #414868;
    flex-shrink: 0;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }

  .toolbar button {
    flex-shrink: 0;
    padding: 10px 18px;
    border: 1px solid #414868;
    border-radius: 8px;
    background: #1a1b26;
    color: #c0caf5;
    font-size: 15px;
    font-weight: 500;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: all 0.15s;
    -webkit-tap-highlight-color: transparent;
    user-select: none;
  }

  .toolbar button:active {
    background: #414868;
    transform: scale(0.96);
  }

  .toolbar button.primary {
    background: #364a82;
    border-color: #7aa2f7;
    color: #c0caf5;
  }

  .toolbar button.danger {
    border-color: #f7768e;
  }

  .toolbar button.danger:active {
    background: #4a2030;
  }

  .toolbar .status {
    margin-left: auto;
    display: flex;
    align-items: center;
    font-size: 12px;
    color: #565f89;
    flex-shrink: 0;
  }

  .toolbar .status .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #9ece6a;
    margin-right: 6px;
  }

  .quickkeys {
    display: flex;
    gap: 6px;
    padding: 6px 12px;
    background: #1a1b26;
    border-bottom: 1px solid #2a2b3d;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
    flex-shrink: 0;
  }

  .quickkeys button {
    flex-shrink: 0;
    min-width: 44px;
    height: 36px;
    padding: 0 10px;
    border: 1px solid #2a2b3d;
    border-radius: 6px;
    background: #24283b;
    color: #a9b1d6;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    -webkit-tap-highlight-color: transparent;
    user-select: none;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .quickkeys button:active {
    background: #414868;
    transform: scale(0.93);
  }

  .quickkeys button.yes  { border-color: #9ece6a; color: #9ece6a; }
  .quickkeys button.no   { border-color: #f7768e; color: #f7768e; }
  .quickkeys button.num  { color: #e0af68; border-color: #3a3b4d; }
  .quickkeys button.ctrl { color: #bb9af7; border-color: #3a3b4d; font-size: 12px; }

  .terminal-frame {
    flex: 1;
    width: 100%;
    border: none;
  }

  .container {
    display: flex;
    flex-direction: column;
    height: 100%;
  }

  .toast {
    position: fixed;
    bottom: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: #414868;
    color: #c0caf5;
    padding: 10px 20px;
    border-radius: 8px;
    font-size: 14px;
    opacity: 0;
    transition: opacity 0.3s;
    pointer-events: none;
    z-index: 100;
  }

  .toast.show { opacity: 1; }
</style>
</head>
<body>
<div class="container">
  <div class="toolbar">
    <button class="primary" onclick="action('resume')" title="Resume last conversation">▶ Resume</button>
    <button onclick="action('new')" title="Start new session">✦ New</button>
    <button onclick="action('list')" title="Pick from conversation list">☰ List</button>
    <button onclick="action('shell')" title="Drop to shell">⌨ Shell</button>
    <button class="danger" onclick="action('interrupt')" title="Send Ctrl-C">■ Stop</button>
    <div class="status"><span class="dot" id="statusDot"></span><span id="statusText">Ready</span></div>
  </div>
  <div class="quickkeys">
    <button class="yes"  onclick="sendKey('y\n')" title="Yes / 確認">Y</button>
    <button class="no"   onclick="sendKey('n\n')" title="No / 取消">N</button>
    <button class="num"  onclick="sendKey('1\n')">1</button>
    <button class="num"  onclick="sendKey('2\n')">2</button>
    <button class="num"  onclick="sendKey('3\n')">3</button>
    <button class="num"  onclick="sendKey('4\n')">4</button>
    <button class="num"  onclick="sendKey('5\n')">5</button>
    <button class="ctrl" onclick="sendKey('\r')"   title="Enter">↵</button>
    <button class="ctrl" onclick="sendKey('\x1b')" title="Escape">Esc</button>
    <button class="ctrl" onclick="sendKey('\x03')" title="Ctrl+C">^C</button>
  </div>
  <iframe id="term" class="terminal-frame" src="ttyd/"></iframe>
  <noscript><p style="padding:20px">JavaScript required. <a href="ttyd/">Open terminal directly</a></p></noscript>
</div>
<div class="toast" id="toast"></div>

<script>
function toast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2000);
}

async function sendKey(key) {
  try {
    // Map actual JS char sequences to server-understood tokens
    const keyMap = {
      '\r': '\r',
      '\x1b': '\x1b',
      '\x03': '\x03',
    };
    // If ends with actual newline, convert to \n marker for server
    let serverKey = key;
    if (key.length === 2 && key[1] === '\n') {
      serverKey = key[0] + '\\n';  // e.g. "y\n" → server sees "y\\n"
    } else if (key === '\r') {
      serverKey = '\r';
    } else if (key === '\x1b') {
      serverKey = '\x1b';
    } else if (key === '\x03') {
      serverKey = '\x03';
    }
    await fetch('api/key', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key: serverKey })
    });
  } catch(e) {
    toast('Error: ' + e.message);
  }
}

async function action(name) {
  const dot = document.getElementById('statusDot');
  const txt = document.getElementById('statusText');
  dot.style.background = '#e0af68';
  txt.textContent = name + '...';
  
  try {
    const res = await fetch('api/' + name, { method: 'POST' });
    const data = await res.json();
    toast(data.message || 'Done');
    dot.style.background = '#9ece6a';
    txt.textContent = 'Ready';
  } catch(e) {
    toast('Error: ' + e.message);
    dot.style.background = '#f7768e';
    txt.textContent = 'Error';
    setTimeout(() => { dot.style.background = '#9ece6a'; txt.textContent = 'Ready'; }, 3000);
  }
  
  // Refocus terminal iframe
  setTimeout(() => document.getElementById('term').focus(), 500);
}
</script>
</body>
</html>`;

const server = http.createServer((req, res) => {
  // API endpoints
  if (req.method === 'POST' && req.url.startsWith('/api/')) {
    const action = req.url.replace('/api/', '');
    
    try {
      ensureTmux();
      
      switch (action) {
        case 'resume':
          // Ctrl-C any running process, then resume
          execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`);
          setTimeout(() => {
            try { execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`); } catch {}
            setTimeout(() => {
              try { execSync(`tmux send-keys -t ${TMUX_SESSION} 'claude -c' Enter`); } catch {}
            }, 200);
          }, 200);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, message: '⏩ Resuming last conversation...' }));
          break;

        case 'new':
          execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`);
          setTimeout(() => {
            try { execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`); } catch {}
            setTimeout(() => {
              try { execSync(`tmux send-keys -t ${TMUX_SESSION} 'claude' Enter`); } catch {}
            }, 200);
          }, 200);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, message: '🆕 Starting new session...' }));
          break;

        case 'list':
          execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`);
          setTimeout(() => {
            try { execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`); } catch {}
            setTimeout(() => {
              try { execSync(`tmux send-keys -t ${TMUX_SESSION} 'claude -r' Enter`); } catch {}
            }, 200);
          }, 200);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, message: '📋 Opening conversation list...' }));
          break;

        case 'shell':
          execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`);
          setTimeout(() => {
            try { execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`); } catch {}
          }, 200);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, message: '⌨ Shell ready' }));
          break;

        case 'interrupt':
          execSync(`tmux send-keys -t ${TMUX_SESSION} C-c 2>/dev/null || true`);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, message: '■ Interrupted' }));
          break;

        case 'key': {
          // Send key to tmux session
          let body = '';
          req.on('data', d => body += d);
          req.on('end', () => {
            try {
              const { key } = JSON.parse(body);
              if (!key || key.length > 20) throw new Error('invalid key');
              ensureTmux();
              // Map special keys to tmux key names
              const keyMap = {
                '\r': 'Enter',
                '\n': 'Enter',
                '\x1b': 'Escape',
                '\x03': 'C-c',
                '\x04': 'C-d',
              };
              // Check if it ends with \n (like "y\n") — send literal then Enter
              if (key.endsWith('\\n')) {
                const literal = key.slice(0, -2);
                execSync(`tmux send-keys -t ${TMUX_SESSION} -l ${JSON.stringify(literal)}`);
                execSync(`tmux send-keys -t ${TMUX_SESSION} Enter`);
              } else if (keyMap[key]) {
                execSync(`tmux send-keys -t ${TMUX_SESSION} ${keyMap[key]}`);
              } else {
                execSync(`tmux send-keys -t ${TMUX_SESSION} -l ${JSON.stringify(key)}`);
              }
              res.writeHead(200, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ ok: true }));
            } catch(e) {
              res.writeHead(400, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({ ok: false, message: e.message }));
            }
          });
          return; // async, don't fall through
        }

        default:
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: false, message: 'Unknown action' }));
      }
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ok: false, message: e.message }));
    }
    return;
  }

  // Proxy ttyd requests
  if (req.url.startsWith('/ttyd/')) {
    const ttydUrl = `http://127.0.0.1:${TTYD_PORT}${req.url}`;
    
    // Handle WebSocket upgrade separately (handled below)
    const proxyReq = http.request(ttydUrl, {
      method: req.method,
      headers: { ...req.headers, host: `127.0.0.1:${TTYD_PORT}` },
    }, (proxyRes) => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res);
    });
    
    proxyReq.on('error', () => {
      res.writeHead(502, { 'Content-Type': 'text/plain' });
      res.end('Terminal not ready yet. Refresh in a moment.');
    });
    
    req.pipe(proxyReq);
    return;
  }

  // Serve main page (any path that's not /ttyd/ or /api/)
  // This handles HA ingress which may add path prefixes
  if (!req.url.startsWith('/ttyd/') && !req.url.startsWith('/api/')) {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(HTML);
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

// Handle WebSocket upgrade for ttyd
server.on('upgrade', (req, socket, head) => {
  if (!req.url.startsWith('/ttyd/')) {
    socket.destroy();
    return;
  }

  const net = require('net');
  const ttydSocket = net.connect(TTYD_PORT, '127.0.0.1', () => {
    const path = req.url;
    const headers = Object.entries(req.headers)
      .map(([k, v]) => `${k}: ${v}`)
      .join('\r\n');
    
    ttydSocket.write(
      `GET ${path} HTTP/1.1\r\n` +
      `Host: 127.0.0.1:${TTYD_PORT}\r\n` +
      `${headers}\r\n` +
      `\r\n`
    );
    
    if (head.length > 0) ttydSocket.write(head);
    
    socket.pipe(ttydSocket);
    ttydSocket.pipe(socket);
  });

  ttydSocket.on('error', () => socket.destroy());
  socket.on('error', () => ttydSocket.destroy());
});

// Start tmux session and ttyd
ensureTmux();

const { spawn } = require('child_process');
const ttyd = spawn('ttyd', [
  '--port', String(TTYD_PORT),
  '--interface', '127.0.0.1',
  '--writable',
  '--ping-interval', '30',
  '--base-path', '/ttyd',
  'tmux', 'attach-session', '-t', TMUX_SESSION,
], { stdio: 'inherit' });

ttyd.on('error', (err) => {
  console.error('Failed to start ttyd:', err);
  process.exit(1);
});

server.listen(UI_PORT, '0.0.0.0', () => {
  console.log(`Claude Terminal UI running on http://0.0.0.0:${UI_PORT}`);
  console.log(`ttyd running on http://127.0.0.1:${TTYD_PORT}`);
});

process.on('SIGTERM', () => {
  ttyd.kill();
  server.close();
  process.exit(0);
});
