// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://0d3sa.com',
	base: '/',
	integrations: [
		starlight({
			title: 'eden-memory',
			description: 'Public releases and documentation for the eden-memory agent harness.',
			social: [
				{ icon: 'github', label: 'Source', href: 'https://github.com/yakovkhalinsky/eden-memory' },
				{ icon: 'github', label: 'Releases', href: 'https://github.com/yakovkhalinsky/eden-releases' },
			],
			sidebar: [
				{
					label: 'Guides',
					items: [
						{ label: 'Getting Started', slug: 'guides/getting-started' },
						{ label: 'Install', slug: 'guides/install' },
						{ label: 'MCP Clients', slug: 'guides/mcp-clients' },
					],
				},
				{
					label: 'Reference',
					items: [
						{ label: 'Tools', slug: 'reference/tools' },
					],
				},
			],
		}),
	],
});
