#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { yosys2digitaljs, io_ui } = require('yosys2digitaljs/core');

const [jsonPath, outputDir, title] = process.argv.slice(2);
const levels = ['original', 'level1', 'level2', 'max'];

if (!jsonPath || !outputDir || !title) {
  console.error('usage: digitaljs_export.js <yosys.json> <output-dir> <title>');
  process.exit(2);
}

const root = path.resolve(__dirname, '..');
const digitaljsDist = path.join(root, 'node_modules', 'digitaljs', 'dist');
const mainJs = path.join(digitaljsDist, 'main.js');

if (!fs.existsSync(mainJs)) {
  console.error('digitaljs is not installed. Run: npm install');
  process.exit(1);
}

fs.mkdirSync(outputDir, { recursive: true });
const assetsDir = path.join(__dirname, 'viz', 'assets', 'digitaljs');
fs.mkdirSync(assetsDir, { recursive: true });
for (const entry of fs.readdirSync(digitaljsDist)) {
  if (entry.endsWith('.js') || entry.endsWith('.txt')) {
    fs.copyFileSync(path.join(digitaljsDist, entry), path.join(assetsDir, entry));
  }
}

const [gateName, viewName] = title.split(/\s+/, 2);
const yosysTop = gateName === 'Nand' ? 'NandPrimitiveView' : gateName;
const yosysJson = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
promoteNandPrimitive(yosysJson);
pruneUnreachableModules(yosysJson, yosysTop);
const circuit = yosys2digitaljs(yosysJson, {});
io_ui(circuit);

const htmlOut = path.join(outputDir, 'index.html');
const moduleDeps = parseModules(path.join(__dirname, 'v'));
const dashboardPath = rel(outputDir, path.join(__dirname, 'viz', 'index.html'));
const svgPath = rel(outputDir, path.join(outputDir, 'circuit.svg'));
const childNav = renderChildNav(outputDir, moduleDeps.get(gateName) || new Map());
const levelNav = renderLevelNav(outputDir, gateName, viewName);

const assetPath = path.relative(outputDir, path.join(assetsDir, 'main.js')).replaceAll(path.sep, '/');
const html = `<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>${escapeHtml(title)} DigitalJS</title>
    <script defer src="${assetPath}"></script>
    <style>
      body { margin: 0; font-family: system-ui, sans-serif; color: #1f2937; }
      header { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; padding: 8px 12px; border-bottom: 1px solid #ddd; position: sticky; top: 0; background: white; z-index: 10; }
      nav { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; padding: 8px 12px; border-bottom: 1px solid #e5e7eb; background: #f8fafc; }
      nav a { color: #075985; text-decoration: none; font-weight: 600; padding: 2px 6px; border-radius: 4px; }
      nav a.active { background: #dbeafe; color: #1e3a8a; }
      nav a:hover { text-decoration: underline; }
      .muted { color: #64748b; }
      #paper { min-height: 70vh; border-bottom: 1px solid #ddd; }
      #monitor, #iopanel { padding: 8px 12px; }
      button { font: inherit; }
    </style>
  </head>
  <body>
    <header>
      <strong>${escapeHtml(title)}</strong>
      <button name="start" type="button">Start</button>
      <button name="stop" type="button">Stop</button>
      <label><input name="fixed" type="checkbox"> Fixed layout</label>
      <button name="json" type="button">Reload JSON</button>
    </header>
    <nav>
      <a href="${dashboardPath}">All gates</a>
      <a href="${svgPath}">Static SVG</a>
      <span class="muted">Levels:</span>
      ${levelNav}
      <span class="muted">Subchips:</span>
      ${childNav}
    </nav>
    <div id="paper"></div>
    <div id="iopanel"></div>
    <div id="monitor"></div>
    <script>
      const circuitJson = ${JSON.stringify(circuit)};
      let circuit, monitor, monitorview, iopanel, paper;

      document.addEventListener('DOMContentLoaded', () => {
        const start = $('button[name=start]');
        const stop = $('button[name=stop]');
        const fixedInput = $('input[name=fixed]');
        const papers = {};

        function setFixed(fixed) {
          Object.values(papers).forEach((p) => p.fixed(fixed));
        }

        function loadCircuit(json) {
          if (monitorview) monitorview.shutdown();
          if (iopanel) iopanel.shutdown();
          if (circuit) circuit.stop();
          $('#paper').empty();
          $('#monitor').empty();
          $('#iopanel').empty();

          circuit = new digitaljs.Circuit(json);
          monitor = new digitaljs.Monitor(circuit);
          monitorview = new digitaljs.MonitorView({ model: monitor, el: $('#monitor') });
          iopanel = new digitaljs.IOPanelView({ model: circuit, el: $('#iopanel') });
          circuit.on('new:paper', (newPaper) => {
            newPaper.fixed(fixedInput.prop('checked'));
            papers[newPaper.cid] = newPaper;
            newPaper.on('element:pointerdblclick', (cellView) => {
              window.digitaljsCell = cellView.model;
              console.info('Double-clicked gate is available as window.digitaljsCell');
            });
          });
          circuit.on('changeRunning', () => {
            start.prop('disabled', circuit.running);
            stop.prop('disabled', !circuit.running);
          });
          paper = circuit.displayOn($('#paper'));
          setFixed(fixedInput.prop('checked'));
          circuit.start();
        }

        start.on('click', () => circuit.start());
        stop.on('click', () => circuit.stop());
        fixedInput.on('change', () => setFixed(fixedInput.prop('checked')));
        $('button[name=json]').on('click', () => loadCircuit(circuit.toJSON(false)));
        loadCircuit(circuitJson);
      });
    </script>
  </body>
</html>
`;

fs.writeFileSync(htmlOut, html);
console.log(`wrote ${htmlOut}`);

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function rel(fromDir, toPath) {
  return path.relative(fromDir, toPath).replaceAll(path.sep, '/') || '.';
}

function parseModules(vDir) {
  const modules = new Map();
  if (!fs.existsSync(vDir)) return modules;
  for (const entry of fs.readdirSync(vDir).sort()) {
    if (!entry.endsWith('.v')) continue;
    const text = fs.readFileSync(path.join(vDir, entry), 'utf8');
    const moduleRe = /\bmodule\s+(\w+)\s*\((.*?)\);([\s\S]*?)\bendmodule/g;
    let moduleMatch;
    while ((moduleMatch = moduleRe.exec(text)) !== null) {
      const name = moduleMatch[1];
      const body = moduleMatch[3];
      const deps = new Map();
      const cellRe = /^\s*(\w+)\s+\w+\s*\(/gm;
      let cellMatch;
      while ((cellMatch = cellRe.exec(body)) !== null) {
        const child = cellMatch[1];
        if (['assign', 'if', 'for', 'module', 'wire'].includes(child)) continue;
        deps.set(child, (deps.get(child) || 0) + 1);
      }
      modules.set(name, deps);
    }
  }
  return modules;
}

function promoteNandPrimitive(yosysJson) {
  for (const moduleData of Object.values(yosysJson.modules || {})) {
    for (const cell of Object.values(moduleData.cells || {})) {
      if (cell.type !== 'Nand') continue;
      cell.type = '$nand';
      cell.parameters = {
        A_SIGNED: 0,
        B_SIGNED: 0,
        A_WIDTH: 1,
        B_WIDTH: 1,
        Y_WIDTH: 1,
      };
      cell.port_directions = { A: 'input', B: 'input', Y: 'output' };
      cell.connections = {
        A: cell.connections.a,
        B: cell.connections.b,
        Y: cell.connections.out,
      };
    }
  }
  delete yosysJson.modules?.Nand;
}

function pruneUnreachableModules(yosysJson, topModule) {
  const modules = yosysJson.modules || {};
  const reachable = new Set();

  function visit(moduleName) {
    if (reachable.has(moduleName) || !modules[moduleName]) return;
    reachable.add(moduleName);
    for (const cell of Object.values(modules[moduleName].cells || {})) {
      if (modules[cell.type]) visit(cell.type);
    }
  }

  visit(topModule);
  for (const moduleName of Object.keys(modules)) {
    if (!reachable.has(moduleName)) delete modules[moduleName];
  }
}

function renderLevelNav(outputDir, gateName, viewName) {
  return levels.map((level) => {
    const target = path.join(__dirname, 'viz', gateName, level, 'index.html');
    const active = level === viewName ? ' class="active"' : '';
    return `<a${active} href="${rel(outputDir, target)}">${escapeHtml(level)}</a>`;
  }).join('');
}

function renderChildNav(outputDir, deps) {
  if (!deps.size) return '<span class="muted">leaf</span>';
  return Array.from(deps.entries()).sort(([a], [b]) => a.localeCompare(b)).map(([child, count]) => {
    const target = path.join(__dirname, 'viz', child, 'original', 'index.html');
    const label = count > 1 ? `${count}x ${child}` : child;
    return `<a href="${rel(outputDir, target)}">${escapeHtml(label)}</a>`;
  }).join('');
}
