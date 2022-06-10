const fs = require('fs')
const mv = require('mv');
const request = require('request')
const config = require('./config.json')

const main = async () => {
    console.log("Scanning watch directory every few seconds....")
    const authToken = `${config.paperless.token}`
    while(true) {
        const files = await fs.promises.readdir(`${__dirname}/../../watch`)
        for(const file of files) {
            console.log(`Found file to process ${file}`)
            const now = new Date().toJSON().replace(/:/g, '');
            const documentTitle = `scan-${now}`
            console.log(`Pushing to paperless as document ${documentTitle}`)
            const options = {
                method: "POST",
                url: `${config.paperless.apiPrefix}/documents/post_document/`,
                port: config.paperless.port,
                headers: {
                    "Authorization": `Token ${authToken}`,
                    "Content-Type": "multipart/form-data"
                },
                formData: {
                    "title": documentTitle,
                    "document": fs.createReadStream(`${__dirname}/../../watch/${file}`)
                }
            }

            request(options, function(err, res, body) {
                if (err) console.log(err)
                if (res) {
                    console.log(`Response from paperless: ${res.statusCode} (${res.statusMessage})`)
                } else {
                    console.log("No response captured from paperless")
                }

                mv(`${__dirname}/../../watch/${file}`, `${__dirname}/../../outgoing/${documentTitle}.pdf`, err => {
                    if (err) console.log(err);
                    console.log(`Moved file ${file} to outgoing directory as ${documentTitle}.pdf`);
                })
        
            })

        }

        await sleep(2000)
    }
}

main().then().catch(e => console.error(`Problem! ${e}`))
