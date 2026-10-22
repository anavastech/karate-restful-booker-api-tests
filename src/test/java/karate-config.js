function fn() {
  var System = Java.type('java.lang.System');
  var setting = function (property, envVar, fallback) {
    return karate.properties[property] || System.getenv(envVar) || fallback;
  };

  var env = karate.env || 'dev';
  karate.log('karate.env =', env);

  var environments = {
    dev: { baseUrl: 'https://restful-booker.herokuapp.com' },
    // Local instance: docker run -p 3001:3001 mwinteringham/restfulbooker
    local: { baseUrl: 'http://localhost:3001' }
  };
  if (!environments[env]) {
    karate.fail('Unknown karate.env "' + env + '". Valid values: ' + Object.keys(environments));
  }

  var config = {
    env: env,
    baseUrl: setting('baseUrl', 'RB_BASE_URL', environments[env].baseUrl),
    credentials: {
      username: setting('username', 'RB_USERNAME', 'admin'),
      password: setting('password', 'RB_PASSWORD', 'password123')
    },
    maxResponseTime: Number(setting('maxResponseTime', 'RB_MAX_RESPONSE_TIME', 5000))
  };

  karate.configure('connectTimeout', 10000);
  karate.configure('readTimeout', 30000);
  karate.configure('headers', { Accept: 'application/json' });

  return config;
}
