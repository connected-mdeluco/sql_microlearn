const express = require('express');
const bodyParser = require('body-parser');
const db = require('./database');
const logger = require('./logger');
const router = require('./router')({
  directoryWhiteList: ['auth'],
  routerOptions: { db, logger }
});

const app = express();

app.use(bodyParser.text({
  type: ['', 'application/json']
}));

app.use((req) => {
  if (!req.get('content-type')) {
    req.body = null;
  }
  req.next();
});

app.use('/api', router);

const server = app.listen(process.env.NODE_PORT, () => {
  logger.info(`Server running on port ${process.env.NODE_PORT}`);
});

module.exports = server;
