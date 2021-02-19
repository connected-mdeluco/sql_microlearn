/* eslint-disable no-unused-vars */

/* eslint-disable no-template-curly-in-string */
const queryListAuth = 'SELECT * FROM auth.get_json($1)';
const queryCreateOrUpdateAuth = 'SELECT * FROM auth.create_or_update($1)';
const queryAuthenticate = 'SELECT * FROM auth.authenticate($1)';
const queryRemove = 'SELECT * FROM auth.remove($1)';
/* eslint-enable no-template-curly-in-string */

module.exports = (router, opts) => {
  const options = opts || {};
  const { db, logger } = options;

  router
    .route('/')
    .get(async (req, res, _err) => {
      try {
        const results = await db.one(queryListAuth, req.body);
        return res.send(results['out_json']);
      } catch (e) {
        logger.info(`Error get auth list: ${e}`);
        return res.status(500).end();
      }
    })
    .post(async (req, res, _err) => {
      try {
        const results = await db.one(queryCreateOrUpdateAuth, req.body);
        return results.create_or_update ? res.status(201).end() : res.status(401).end();
      } catch (e) {
        logger.info(`Error creating or updating auth entry: ${e}`);
        return res.status(500).end();
      }
    })
    .put(async (req, res, _err) => {
      try {
        const results = await db.one(queryAuthenticate, req.body);
        return results.authenticate ? res.status(200).end() : res.status(401).end();
      } catch (e) {
        logger.info(`Error with authorization: ${e}`);
        return res.status(500).end();
      }
    })
    .delete(async (req, res, _err) => {
      try {
        const results = await db.one(queryRemove, req.body);
        return res.send(results['remove'] || []);
      } catch (e) {
        logger.info(`Error deleting auth entry: ${e}`);
        return res.status(500).end();
      }
    });
};
