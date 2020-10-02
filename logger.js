// eslint-disable-next-line import/newline-after-import
const { config, createLogger, format, transports } = require('winston');
const { combine, timestamp, printf } = format;

const logFormat = printf(args => {
  return `${args.timestamp} ${args.level} - ${args.message}`;
});

module.exports = createLogger({
  levels: config.syslog.levels,
  format: combine(timestamp(), logFormat),
  transports: [new transports.Console()]
});
