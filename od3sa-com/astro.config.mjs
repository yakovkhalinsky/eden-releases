import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://od3sa.com',
  output: 'static',
  build: {
    assets: 'assets'
  }
});
