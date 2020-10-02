const routeLoader = require('auto-route-loader');
const { Router } = require('express');

const routerFactoryFn = () => {
  return Router({
    strict: true,
    caseSensitive: true,
    mergeParams: true
  });
};

const rootRouter = routerFactoryFn();

module.exports = (routerOptions = {}) => {
  const loader = routeLoader(routerFactoryFn, routerOptions);
  loader.loadRoutes(__dirname, rootRouter);
  return rootRouter;
};
