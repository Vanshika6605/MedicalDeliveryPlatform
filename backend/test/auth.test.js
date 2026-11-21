const assert = require('node:assert/strict');
const { test } = require('node:test');
const { authorize, optionalProtect, protect } = require('../src/middleware/auth');

function response() {
  return {
    statusCode: 200,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
  };
}

test('a protected request without credentials receives HTTP 401', async () => {
  const res = response();
  await protect({ headers: {} }, res, () => assert.fail('request reached the handler'));
  assert.equal(res.statusCode, 401);
  assert.equal(res.body.message, 'Not authorized, no token');
});

test('a protected request with a malformed token receives HTTP 401', async () => {
  const res = response();
  await protect({ headers: { authorization: 'Bearer malformed' } }, res, () => assert.fail('request reached the handler'));
  assert.equal(res.statusCode, 401);
  assert.equal(res.body.message, 'Token invalid or expired');
});

test('an anonymous catalogue request continues as a guest', async () => {
  const req = { headers: {} };
  let called = false;
  await optionalProtect(req, {}, () => { called = true; });
  assert.equal(called, true);
  assert.equal(req.user, null);
});

test('retailer and admin routes permit the retailer role', () => {
  let called = false;
  authorize('retailer', 'admin')({ user: { role: 'retailer' } }, response(), () => { called = true; });
  assert.equal(called, true);
});

test('retailer and admin routes reject a customer role with HTTP 403', () => {
  const res = response();
  authorize('retailer', 'admin')({ user: { role: 'user' } }, res, () => assert.fail('request reached the handler'));
  assert.equal(res.statusCode, 403);
  assert.equal(res.body.message, 'Access denied');
});
