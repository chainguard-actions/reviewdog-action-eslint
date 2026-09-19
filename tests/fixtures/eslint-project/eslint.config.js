module.exports = [
  {
    rules: {
      'no-unused-vars': 'error',
      'no-undef': 'error'
    },
    languageOptions: {
      ecmaVersion: 2018,
      sourceType: 'script',
      globals: {
        console: 'readonly'
      }
    }
  }
]
