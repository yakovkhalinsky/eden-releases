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
				{ icon: 'github', label: 'Releases', href: 'https://github.com/yakovkhalinsky/eden-releases' },
			],
			sidebar: [
				{
					label: 'eden-memory',
					items: [
						{ label: 'Overview', slug: 'eden-memory' },
						{ label: 'Install & get started', slug: 'eden-memory/getting-started' },
						{ label: 'Connect your client', slug: 'eden-memory/mcp-clients' },
						{
							label: 'Skills',
							items: [
								{ label: 'Skills registry', slug: 'eden-memory/skills' },
								{ label: 'eden-memory MCP usage', slug: 'eden-memory/skills/eden-memory-mcp-usage' },
								{ label: 'Claude Code CLI', slug: 'eden-memory/skills/eden-memory-claude' },
								{ label: 'Cursor', slug: 'eden-memory/skills/eden-memory-cursor' },
								{ label: 'Hermes Agent', slug: 'eden-memory/skills/eden-memory-hermes' },
							],
						},
						{ label: 'Tools reference', slug: 'eden-memory/reference/tools' },
					],
				},
				{
					label: 'Meta',
					items: [
						{ label: 'Site setup', slug: 'guides/site-setup' },
					],
				},
			],
		}),
	],
});
