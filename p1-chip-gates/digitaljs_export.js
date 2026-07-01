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

const repoRoot = path.resolve(__dirname, '..');
const digitaljsDist = path.join(repoRoot, 'node_modules', 'digitaljs', 'dist');
const mainJs = path.join(digitaljsDist, 'main.js');

if (!fs.existsSync(mainJs)) {
  console.error('digitaljs is not installed. Run: npm install');
  process.exit(1);
}

fs.mkdirSync(outputDir, { recursive: true });
const assetsDir = path.join(repoRoot, 'viz', 'assets', 'digitaljs');
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
promoteDffPrimitive(circuit);
io_ui(circuit);

const htmlOut = path.join(outputDir, 'index.html');
const moduleDeps = parseModules(repoRoot);
const dashboardPath = rel(outputDir, path.join(repoRoot, 'viz', 'index.html'));
const svgPath = rel(outputDir, path.join(outputDir, 'circuit.svg'));
const childNav = renderChildNav(outputDir, moduleDeps.get(gateName) || new Map());
const levelNav = renderLevelNav(outputDir, gateName, viewName);
const deviceCount = Object.keys(circuit.devices || {}).length;
const defaultZoomLevel = deviceCount > 500 ? -4 : deviceCount > 150 ? -3 : deviceCount > 60 ? -2 : 0;

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
      #paper { height: calc(100vh - 170px); min-height: 520px; border-bottom: 1px solid #ddd; overflow: auto; background: #fff; }
      #monitor, #iopanel { padding: 8px 12px; }
      button, select { font: inherit; }
      .zoom-readout { min-width: 52px; text-align: right; font-variant-numeric: tabular-nums; }
    </style>
  </head>
  <body>
    <header>
      <strong>${escapeHtml(title)}</strong>
      <button name="start" type="button">Start</button>
      <button name="stop" type="button">Stop</button>
      <label><input name="fixed" type="checkbox"> Fixed layout</label>
      <label>Layout
        <select name="layout">
          <option value="dagre">Compact</option>
          <option value="elkjs">Orthogonal</option>
        </select>
      </label>
      <button name="zoomOut" type="button">Zoom -</button>
      <button name="zoomReset" type="button">100%</button>
      <button name="zoomIn" type="button">Zoom +</button>
      <button name="zoomFit" type="button">Fit</button>
      <span class="zoom-readout" data-zoom>100%</span>
      <button name="clearCache" type="button">Clear Layout Cache</button>
      <span class="muted" data-cache>layout cache ready</span>
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
      const circuitHash = '${hashString(JSON.stringify(circuit))}';
      const defaultZoomLevel = ${defaultZoomLevel};
      let circuit, monitor, monitorview, iopanel, paper;
      let zoomLevel = defaultZoomLevel;

      document.addEventListener('DOMContentLoaded', () => {
        const start = $('button[name=start]');
        const stop = $('button[name=stop]');
        const fixedInput = $('input[name=fixed]');
        const layoutSelect = $('select[name=layout]');
        const zoomLabel = $('[data-zoom]');
        const cacheLabel = $('[data-cache]');
        const papers = {};

        function cacheKey() {
          return 'jacputer-layout-v2:' + circuitHash + ':' + layoutSelect.val();
        }

        function updateCacheStatus(message) {
          cacheLabel.text(message);
        }

        function openLayoutCache() {
          return new Promise((resolve) => {
            if (!('indexedDB' in window)) return resolve(null);
            const request = indexedDB.open('jacputer-layout-cache', 1);
            request.onupgradeneeded = () => request.result.createObjectStore('layouts');
            request.onerror = () => resolve(null);
            request.onsuccess = () => resolve(request.result);
          });
        }

        async function readLayoutCache(key) {
          const db = await openLayoutCache();
          if (!db) return null;
          return new Promise((resolve) => {
            const tx = db.transaction('layouts', 'readonly');
            const request = tx.objectStore('layouts').get(key);
            request.onerror = () => resolve(null);
            request.onsuccess = () => resolve(request.result || null);
            tx.oncomplete = () => db.close();
          });
        }

        async function writeLayoutCache(key, json) {
          const db = await openLayoutCache();
          if (!db) return updateCacheStatus('layout cache unavailable');
          return new Promise((resolve) => {
            const tx = db.transaction('layouts', 'readwrite');
            tx.objectStore('layouts').put(json, key);
            tx.onerror = () => {
              updateCacheStatus('layout cache failed');
              resolve();
            };
            tx.oncomplete = () => {
              db.close();
              updateCacheStatus('layout cached');
              resolve();
            };
          });
        }

        async function deleteLayoutCache(key) {
          const db = await openLayoutCache();
          if (!db) return;
          return new Promise((resolve) => {
            const tx = db.transaction('layouts', 'readwrite');
            tx.objectStore('layouts').delete(key);
            tx.oncomplete = () => {
              db.close();
              resolve();
            };
            tx.onerror = () => resolve();
          });
        }

        function setFixed(fixed) {
          Object.values(papers).forEach((p) => p.fixed(fixed));
        }

        function zoomScale(level) {
          return Math.pow(1.1, level);
        }

        function updateZoomLabel() {
          zoomLabel.text(Math.round(zoomScale(zoomLevel) * 100) + '%');
        }

        function setZoom(level) {
          if (!paper || !circuit) return;
          zoomLevel = Math.max(-30, Math.min(20, level));
          circuit.scaleAndRefreshPaper(paper, zoomLevel);
          updateZoomLabel();
        }

        function fitToWindow() {
          if (!paper) return;
          if (typeof paper.scaleContentToFit === 'function') {
            paper.scaleContentToFit({ padding: 30, minScale: 0.02, maxScale: 2 });
            const current = paper.scale && paper.scale();
            const scale = current && current.sx ? current.sx : zoomScale(zoomLevel);
            zoomLevel = Math.round(Math.log(scale) / Math.log(1.1));
            updateZoomLabel();
          } else {
            setZoom(defaultZoomLevel - 2);
          }
        }

        async function loadCircuit(json, options = {}) {
          const useCache = options.useCache !== false;
          updateCacheStatus(useCache ? 'checking layout cache...' : 'rebuilding layout...');
          const key = cacheKey();
          const cachedJson = useCache ? await readLayoutCache(key) : null;
          const renderJson = cachedJson || json;

          if (monitorview) monitorview.shutdown();
          if (iopanel) iopanel.shutdown();
          if (circuit) circuit.stop();
          Object.keys(papers).forEach((key) => delete papers[key]);
          $('#paper').empty();
          $('#monitor').empty();
          $('#iopanel').empty();

          circuit = new digitaljs.Circuit(renderJson, { layoutEngine: layoutSelect.val() });
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
          zoomLevel = defaultZoomLevel;
          updateZoomLabel();
          paper.once('render:done', () => {
            setZoom(zoomLevel);
            if (cachedJson) {
              updateCacheStatus('using cached layout');
            } else {
              updateCacheStatus('caching layout...');
              window.requestAnimationFrame(() => writeLayoutCache(key, circuit.toJSON(true)));
            }
          });
          setFixed(fixedInput.prop('checked'));
          circuit.start();
        }

        start.on('click', () => circuit.start());
        stop.on('click', () => circuit.stop());
        fixedInput.on('change', () => setFixed(fixedInput.prop('checked')));
        layoutSelect.on('change', () => loadCircuit(circuitJson));
        $('button[name=zoomOut]').on('click', () => setZoom(zoomLevel - 1));
        $('button[name=zoomReset]').on('click', () => setZoom(0));
        $('button[name=zoomIn]').on('click', () => setZoom(zoomLevel + 1));
        $('button[name=zoomFit]').on('click', fitToWindow);
        $('#paper').on('wheel', (event) => {
          if (!event.ctrlKey && !event.metaKey) return;
          event.preventDefault();
          setZoom(zoomLevel + (event.originalEvent.deltaY < 0 ? 1 : -1));
        });
        $('button[name=clearCache]').on('click', async () => {
          await deleteLayoutCache(cacheKey());
          updateCacheStatus('layout cache cleared');
          loadCircuit(circuitJson, { useCache: false });
        });
        $('button[name=json]').on('click', () => loadCircuit(circuitJson, { useCache: false }));
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

function hashString(value) {
  let hash = 2166136261;
  for (let i = 0; i < value.length; i += 1) {
    hash ^= value.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16);
}

function rel(fromDir, toPath) {
  return path.relative(fromDir, toPath).replaceAll(path.sep, '/') || '.';
}

function parseModules(rootDir) {
  const modules = new Map();
  if (!fs.existsSync(rootDir)) return modules;
  for (const project of fs.readdirSync(rootDir).sort()) {
    const vDir = path.join(rootDir, project, 'v');
    if (!fs.existsSync(vDir) || !fs.statSync(vDir).isDirectory()) continue;
    for (const entry of fs.readdirSync(vDir).sort()) {
      if (!entry.endsWith('.v')) continue;
      const text = fs.readFileSync(path.join(vDir, entry), 'utf8');
      parseModuleText(text, modules);
    }
  }
  return modules;
}

function parseModuleText(text, modules) {
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

function promoteDffPrimitive(circuitJson) {
  function visit(data) {
    let clockId = null;
    let nextAutoId = 0;

    function makeAutoId(prefix) {
      let id;
      do {
        id = `${prefix}${nextAutoId++}`;
      } while (data.devices?.[id]);
      return id;
    }

    function ensureClock() {
      if (clockId) return clockId;
      data.devices ||= {};
      clockId = makeAutoId('autoClock');
      data.devices[clockId] = {
        type: 'Clock',
        label: 'implicit clock',
      };
      return clockId;
    }

    for (const device of Object.values(data.devices || {})) {
      if (device.type === 'Subcircuit' && device.celltype === 'DFF') {
        device.type = 'Dff';
        device.bits = 1;
        device.polarity = { clock: true };
        delete device.celltype;
      }
    }
    for (const [id, device] of Object.entries(data.devices || {})) {
      if (device.type !== 'Dff') continue;
      data.connectors ||= [];
      if (data.connectors.some((conn) => conn.to?.id === id && conn.to?.port === 'clk')) continue;
      data.connectors.push({
        from: { id: ensureClock(), port: 'out' },
        to: { id, port: 'clk' },
        name: 'implicit clock',
      });
    }
    delete data.subcircuits?.DFF;
    for (const subcircuit of Object.values(data.subcircuits || {})) visit(subcircuit);
  }

  visit(circuitJson);
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
  return levels.flatMap((level) => {
    const target = path.join(repoRoot, 'viz', gateName, level, 'index.html');
    if (level !== viewName && !fs.existsSync(target)) return [];
    const active = level === viewName ? ' class="active"' : '';
    return [`<a${active} href="${rel(outputDir, target)}">${escapeHtml(level)}</a>`];
  }).join('');
}

function renderChildNav(outputDir, deps) {
  if (!deps.size) return '<span class="muted">leaf</span>';
  return Array.from(deps.entries()).sort(([a], [b]) => a.localeCompare(b)).map(([child, count]) => {
    const target = path.join(repoRoot, 'viz', child, 'original', 'index.html');
    const label = count > 1 ? `${count}x ${child}` : child;
    return `<a href="${rel(outputDir, target)}">${escapeHtml(label)}</a>`;
  }).join('');
}
