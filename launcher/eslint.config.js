import eslint from '@eslint/js';
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';
import svelteParser from 'svelte-eslint-parser';
import sveltePlugin from 'eslint-plugin-svelte';
import globals from 'globals';

export default defineConfig([
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    ignores: [
      'dist/**',
      'build/**',
      'node_modules/**',
      'renderer/node_modules/**',
      'shared/*.js', // Compiled output
      '*.config.js',
      '*.config.ts',
      'renderer/*.config.ts',
      'renderer/*.config.js',
    ],
  },
  // Node.js environment for Electron main process and shared
  {
    files: ['electron/**/*.ts', 'shared/**/*.ts'],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        project: './electron/tsconfig.json',
      },
      globals: {
        ...globals.node,
      },
    },
    rules: {
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/no-require-imports': 'warn',
      'no-console': 'off', // We use our logger utility
    },
  },
  // Browser environment for renderer
  {
    files: ['renderer/src/**/*.ts'],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        project: './renderer/tsconfig.json',
      },
      globals: {
        ...globals.browser,
      },
    },
    rules: {
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'off',
      'no-console': 'off',
    },
  },
  // Svelte components
  {
    files: ['**/*.svelte'],
    languageOptions: {
      parser: svelteParser,
      parserOptions: {
        parser: tseslint.parser,
      },
      globals: {
        ...globals.browser,
      },
    },
    plugins: {
      svelte: sveltePlugin,
    },
    rules: {
      ...sveltePlugin.configs.recommended.rules,
      'svelte/no-at-html-tags': 'warn',
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      'no-undef': 'off', // TypeScript handles this
    },
  },
]);
