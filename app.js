const express = require('express'),
    fs = require('fs'),
    winston = require('winston'),
    logger = winston.createLogger({
        levels: winston.config.syslog.levels,
        format: winston.format.printf(({level, message, label, timestamp}) => message),
        transports: [
            new winston.transports.Console({ level: 'info' })
        ]
    });

var app = express();

let routerFactory = (options = {strict: false, caseSensitive: false, mergeParams: true}) =>
    express.Router(options);

let sub_router_options = {
    logger: logger
};

const route_dir_white_list = [
    'auth'
];

let loadRoutes = (path, router) => {
    let has_routes = false;
    fs.readdirSync(path).forEach(file => {
        let new_path = `${path}/${file}`;
        let file_stat = fs.statSync(new_path);
        if (file_stat.isDirectory() && route_dir_white_list.includes(file)) {
            let sub_router = routerFactory();
            if (loadRoutes(new_path, sub_router)) {
                router.use(`/${file}`, sub_router);
                has_routes = true;
            }
        } else if (file_stat.isFile() && /routes\.js/.test(file)) {
            try {
                require(new_path)(router, sub_router_options);
                has_routes = true;
            } catch(err) {
                logger.error(`Could not load route ${new_path}: ${err}`);
            }
        }
    });
    return has_routes;
};

let router = routerFactory();
loadRoutes(__dirname, router);
app.use('/api', router);

var server = app.listen(parseInt(process.env.port), () => {
    logger.info(`Server running on port ${process.env.port}`);
});

module.exports = server;
