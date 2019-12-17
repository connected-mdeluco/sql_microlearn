

module.exports = (router, opts) => {
    const options = opts || {};
    const logger = options.logger;

    router.route('').get((req, res, err) => {
        logger.info('Hello!');
        return res.sendStatus(200);
    })
};