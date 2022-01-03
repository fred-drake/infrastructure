const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');

const app = express();
app.use(cors());

let isRunning = false;
app.get('/scan', (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    console.log("Initiating scan...");
    const child = spawn('epsonscan2', [ '-s', 'ES-400', '../UserSettings.SF2' ]);
    isRunning = true;
    res.json({ running: isRunning});

    child.on('exit', function (code, signal) {
        isRunning = false;
        console.log('child process exited with ' +
                    `code ${code} and signal ${signal}`);
      });
});

app.get('/status', (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.json({ running: isRunning });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}...`);
});