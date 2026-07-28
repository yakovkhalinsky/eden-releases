// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://0d3sa.com',
	base: '/',
	integrations: [
		starlight({
			title: '0d3sa',
			description: 'Public releases and documentation for 0d3sa projects.',
			social: [
				{ icon: 'github', label: 'eden-memory source', href: 'https://github.com/yakovkhalinsky/eden-memory' },
				{ icon: 'github', label: 'Releases', href: 'https://github.com/yakovkhalinsky/eden-releases' },
			],
			sidebar: [
				{
					label: 'eden-memory',
					items: [
						{ label: 'Overview', slug: 'eden-memory' },
						{
							label: 'Guides',
							items: [
								{ label: 'Getting Started', slug: 'eden-memory/guides/getting-started' },
								{ label: 'Install', slug: 'eden-memory/guides/install' },
								{ label: 'MCP Clients', slug: 'eden-memory/guides/mcp-clients' },
							],
						},
						{
							label: 'Reference',
							items: [
								{ label: 'Tools', slug: 'eden-memory/reference/tools' },
							],
						},
					],
				},
			],
		}),
	],
});
