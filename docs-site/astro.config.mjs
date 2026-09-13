// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://0d3sa.com',
	base: '/',
	redirects: {
		'/memory/how-to/run-relay-server/': '/relay/how-to/run-relay-server/',
		'/memory/how-to/deploy-public-vps/': '/relay/how-to/deploy-public-vps/',
	},
	integrations: [
		starlight({
			title: '0d3sa',
			description: 'Public releases and documentation for 0d3sa projects.',
			customCss: [
				'./src/styles/starlight-custom.css',
			],
			head: [
				{
					tag: 'link',
					attrs: { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
				},
				{
					tag: 'link',
					attrs: { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: true },
				},
				{
					tag: 'link',
					attrs: {
						rel: 'stylesheet',
						href: 'https://fonts.googleapis.com/css2?family=Chakra+Petch:wght@400;500;700&family=Saira:wght@400;500;700&family=JetBrains+Mono:wght@400;500;700&display=swap',
					},
				},
				{
					tag: 'script',
					attrs: {},
					content: `(function(){ try { localStorage.setItem('starlight-theme','dark'); document.documentElement.dataset.theme = 'dark'; } catch(e){} })();`,
				},
			],
			social: [
				{ icon: 'github', label: 'Releases', href: 'https://github.com/yakovkhalinsky/eden-releases' },
			],
			sidebar: [
				{
					label: 'memory',
					items: [
						{ label: 'Overview', slug: 'memory' },
						{ label: 'Quick start', slug: 'memory/getting-started' },
						{
							label: 'Tutorials',
							items: [
								{ label: 'Connect Claude Code', slug: 'memory/tutorials/connect-claude-code' },
								{ label: 'Connect Cursor', slug: 'memory/tutorials/connect-cursor' },
								{ label: 'Connect another MCP client', slug: 'memory/mcp-clients' },
								{ label: 'Sync two devices with a relay', slug: 'memory/tutorials/sync-two-devices-relay' },
								{ label: 'Sync two databases locally', slug: 'memory/tutorials/sync-local-databases' },
							],
						},
						{
							label: 'How-to guides',
							items: [
								{ label: 'Back up and restore', slug: 'memory/how-to/backup-restore' },
								{ label: 'Relay-first sync topology', slug: 'memory/how-to/relay-first-sync-topology' },
								{ label: 'Build a knowledge packet', slug: 'memory/how-to/build-knowledge-packet' },
								{ label: 'Migrate a workspace', slug: 'memory/how-to/migrate-workspace' },
								{ label: 'Prune old memories', slug: 'memory/how-to/prune-memories' },
								{ label: 'Approve a peer key rotation', slug: 'memory/how-to/approve-peer-key-change' },
							],
						},
						{
							label: 'Concepts',
							items: [
								{ label: 'Dreaming', slug: 'memory/concepts/dreaming' },
								{ label: 'Knowledge packets', slug: 'memory/concepts/knowledge-packets' },
								{ label: 'Memory model and embeddings', slug: 'memory/concepts/memory-model' },
								{ label: 'Scopes and identity', slug: 'memory/concepts/scopes-identity' },
								{ label: 'How sync works', slug: 'memory/concepts/how-sync-works' },
								{ label: 'Sidecar files', slug: 'memory/concepts/sidecar-files' },
								{ label: 'Security model', slug: 'memory/concepts/security-model' },
								{ label: 'Multi-device sync overview', slug: 'memory/multi-device-sync' },
							],
						},
						{
							label: 'Reference',
							items: [
								{ label: 'Tools reference', slug: 'memory/reference/tools' },
								{ label: 'CLI reference', slug: 'memory/reference/cli' },
								{ label: 'Environment variables', slug: 'memory/reference/environment-variables' },
								{ label: 'Fallback slash commands', slug: 'memory/reference/fallback-slash-commands' },
								{ label: 'Troubleshooting', slug: 'memory/reference/troubleshooting' },
								{
									label: 'Skills registry',
									items: [
										{ label: 'Overview', slug: 'memory/skills' },
										{ label: 'MCP usage', slug: 'memory/skills/memory-mcp-usage' },
										{ label: 'Claude Code CLI', slug: 'memory/skills/memory-claude' },
										{ label: 'Cursor', slug: 'memory/skills/memory-cursor' },
										{ label: 'Hermes Agent', slug: 'memory/skills/memory-hermes' },
									],
								},
								{ label: 'Downloads and checksums', slug: 'memory/reference/downloads' },
							],
						},
					],
				},
				{
					label: 'relay',
					items: [
						{ label: 'Overview', slug: 'relay' },
						{
							label: 'How-to guides',
							items: [
								{ label: 'Run your own relay server', slug: 'relay/how-to/run-relay-server' },
								{ label: 'Deploy on a public VPS', slug: 'relay/how-to/deploy-public-vps' },
							],
						},
						{
							label: 'Reference',
							items: [{ label: 'CLI, env vars, and endpoints', slug: 'relay/reference' }],
						},
					],
				},
			],
		}),
	],
});
