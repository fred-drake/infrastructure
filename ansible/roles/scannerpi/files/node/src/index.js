const util = require('util');
const express = require('express');
const cors = require('cors');
const spawn = require('child_process').spawn;
const exec = util.promisify(require('child_process').exec);
const { stderr } = require('process');

const app = express();
app.use(cors());

let isRunning = false;
app.get('/scan', (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    console.log("Initiating scan...");
    const child = spawn('epsonscan2', [ '-s', 'ES-400', '../UserSettings.SF2' ]);
    isRunning = true;
    setResponseStatus(res);

    child.on('exit', function (code, signal) {
        isRunning = false;
        console.log('child process exited with ' +
                    `code ${code} and signal ${signal}`);
      });
});

app.get('/status', (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    setResponseStatus(res);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}...`);
});

const setResponseStatus = async (res) => {
    await exec('epsonscan2 --list | grep "device ID" | wc -l | tr -d "\n"', (error, stdout, stderr) => {
        if (error) {
            res.json({ 
                running: isRunning,
                error: error.message 
            });
            return;
        }
        
        if (stderr) {
            res.json({ 
                running: isRunning,
                error: stderr 
            });
            return;
        }

        res.json({
            running: isRunning,
            deviceAvailable: parseInt(stdout, 10) > 0
        });
    });
}