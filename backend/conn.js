const mongoose = require('mongoose')
const URL = process.env.MONGO_URI
const connectionOptions = process.env.MONGO_PASSWORD_BASE64
	? {
			user: process.env.MONGO_USER,
			pass: Buffer.from(process.env.MONGO_PASSWORD_BASE64, 'base64').toString('utf8'),
			authSource: process.env.MONGO_AUTH_SOURCE
		}
	: {}

mongoose.connect(URL, connectionOptions)
mongoose.Promise = global.Promise

const db = mongoose.connection
db.on('error', console.error.bind(console, 'DB ERROR: '))

module.exports = {db, mongoose}