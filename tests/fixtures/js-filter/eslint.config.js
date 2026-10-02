const js = require('@eslint/js');
module.exports = [
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2018,
      sourceType: 'script',
      globals: {
        module: 'readonly',
      },
    },
  },
];
