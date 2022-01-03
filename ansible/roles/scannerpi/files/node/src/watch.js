const chokidar = require('chokidar');
const mv = require('mv');

const watcher = chokidar.watch('../watch', { persistent: true });

watcher.on('add', path => {
    const now = new Date().toJSON().replace(/:/g, '');
    const renamedTo = `../outgoing/scan-${now}.pdf`;
    mv(path, renamedTo, err => {
        if (err) console.log(err);
        console.log(`Moved file to ${renamedTo}`);
    });
});

setInterval(function(){}, 1000);
