#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { yosys2digitaljs, io_ui } = require('yosys2digitaljs/core');

const [jsonPath, outputDir, title] = process.argv.slice(2);

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

const yosysJson = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const circuit = yosys2digitaljs(yosysJson, {});
io_ui(circuit);

const htmlOut = path.join(outputDir, 'index.html');

const assetPath = path.relative(outputDir, path.join(assetsDir, 'main.js')).replaceAll(path.sep, '/');
const html = `<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>${escapeHtml(title)} DigitalJS</title>
    <script defer src="${assetPath}"></script>
    <style>
      body { margin: 0; font-family: system-ui, sans-serif; }
      header { display: flex; align-items: center; gap: 8px; padding: 8px 12px; border-bottom: 1px solid #ddd; }
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
