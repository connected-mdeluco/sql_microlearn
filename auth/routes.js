/* eslint-disable no-unused-vars */

/* eslint-disable no-template-curly-in-string */
const queryListAuth = 'SELECT * FROM auth.get()';
const queryCreateOrUpdateAuth = 'SELECT auth.create_or_update(${auth.email}, ${auth.password})';
const queryAuthenticate = 'SELECT auth.authenticate(${auth.email}, ${auth.password})';
const queryRemove = 'SELECT auth.remove(${auth.email}, ${auth.password})';
/* eslint-enable no-template-curly-in-string */

module.exports = (router, opts) => {
  const options = opts || {};
  const { db, logger } = options;

  router
    .route('/')
    .get(async (_req, res, _err) => {
      const results = await db.manyOrNone(queryListAuth);
      return res.send(results);
    })
    .post(async (req, res, _err) => {
      try {
        const results = await db.one(queryCreateOrUpdateAuth, { auth: req.body });
        return results.create_or_update ? res.status(201).end() : res.status(401).end();
      } catch (e) {
        logger.info(`Error creating or updating auth entry: ${e}`);
        return res.status(500).end();
      }
    })
    .put(async (req, res, _err) => {
      try {
        const results = await db.one(queryAuthenticate, { auth: req.body });
        return results.authenticate ? res.status(200).end() : res.status(401).end();
      } catch (e) {
        logger.info(`Error with authorization: ${e}`);
        return res.status(500).end();
      }
    })
    .delete(async (req, res, _err) => {
      try {
        const results = await db.one(queryRemove, { auth: req.body });
        return results.remove === req.body.email ? res.status(204).end() : res.status(401).end();
      } catch (e) {
        logger.info(`Error deleting auth entry: ${e}`);
        return res.status(500).end();
      }
    });
};
