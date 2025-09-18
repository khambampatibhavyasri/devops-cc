// Basic smoke test
test('basic test passes', () => {
  expect(true).toBe(true);
});

test('React is available', () => {
  const React = require('react');
  expect(React).toBeDefined();
});
