// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://0d3sa.com',
	base: '/',
	redirects: {
		'/eden-memory/how-to/run-relay-server/': '/eden-relay/how-to/run-relay-server/',
		'/eden-memory/how-to/deploy-public-vps/': '/eden-relay/how-to/deploy-public-vps/',
		'/agentic-team-protocol/tutorials/headless-supervisor/': '/eden-team/tutorials/headless-supervisor/',
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
					label: 'agentic-team-protocol',
					items: [
						{ label: 'Overview', slug: 'agentic-team-protocol' },
						{ label: 'Quick start', slug: 'agentic-team-protocol/getting-started' },
						{
							label: 'Tutorials',
							items: [
								{ label: 'Run your first team goal', slug: 'agentic-team-protocol/tutorials/first-team-goal' },
								{ label: 'Ratify a project charter', slug: 'agentic-team-protocol/tutorials/ratify-charter' },
							],
						},
						{
							label: 'How-to guides',
							items: [
								{ label: 'Run goals in parallel', slug: 'agentic-team-protocol/how-to/parallel-goals' },
							],
						},
						{
							label: 'Concepts',
							items: [
								{ label: 'Lite mode', slug: 'agentic-team-protocol/lite-mode' },
								{ label: 'Lifecycle', slug: 'agentic-team-protocol/lifecycle' },
								{ label: 'Roles and agents', slug: 'agentic-team-protocol/agents' },
								{ label: 'Charter anatomy', slug: 'agentic-team-protocol/charter-anatomy' },
								{ label: 'Record kinds and schema', slug: 'agentic-team-protocol/concepts/record-kinds' },
							],
						},
						{
							label: 'Reference',
							items: [
								{ label: 'Slash commands', slug: 'agentic-team-protocol/reference/slash-commands' },
								{ label: 'Agent prompts', slug: 'agentic-team-protocol/reference/agent-prompts' },
								{ label: 'Default charter', slug: 'agentic-team-protocol/reference/default-charter' },
							],
						},
					],
				},
				{
					label: 'Components',
					items: [
						{
							label: 'eden-memory',
							items: [
								{ label: 'Overview', slug: 'eden-memory' },
								{ label: 'Quick start', slug: 'eden-memory/getting-started' },
								{
									label: 'Tutorials',
									items: [
										{ label: 'Connect Claude Code', slug: 'eden-memory/tutorials/connect-claude-code' },
										{ label: 'Connect Cursor', slug: 'eden-memory/tutorials/connect-cursor' },
										{ label: 'Connect another MCP client', slug: 'eden-memory/tutorials/connect-mcp-client' },
										{ label: 'Sync two devices with a relay', slug: 'eden-memory/tutorials/sync-two-devices-relay' },
										{ label: 'Sync two databases locally', slug: 'eden-memory/tutorials/sync-local-databases' },
									],
								},
								{
									label: 'How-to guides',
									items: [
										{ label: 'Back up and restore', slug: 'eden-memory/how-to/backup-restore' },
										{ label: 'Relay-first sync topology', slug: 'eden-memory/how-to/relay-first-sync-topology' },
										{ label: 'Build a knowledge packet', slug: 'eden-memory/how-to/build-knowledge-packet' },
										{ label: 'Migrate a workspace', slug: 'eden-memory/how-to/migrate-workspace' },
										{ label: 'Prune old memories', slug: 'eden-memory/how-to/prune-memories' },
										{ label: 'Approve a peer key rotation', slug: 'eden-memory/how-to/approve-peer-key-change' },
									],
								},
								{
									label: 'Concepts',
									items: [
										{ label: 'Dreaming', slug: 'eden-memory/concepts/dreaming' },
										{ label: 'Knowledge packets', slug: 'eden-memory/concepts/knowledge-packets' },
										{ label: 'Memory model and embeddings', slug: 'eden-memory/concepts/memory-model' },
										{ label: 'Scopes and identity', slug: 'eden-memory/concepts/scopes-identity' },
										{ label: 'How sync works', slug: 'eden-memory/concepts/how-sync-works' },
										{ label: 'Sidecar files', slug: 'eden-memory/concepts/sidecar-files' },
										{ label: 'Security model', slug: 'eden-memory/concepts/security-model' },
										{ label: 'Multi-device sync overview', slug: 'eden-memory/multi-device-sync' },
									],
								},
								{
									label: 'Reference',
									items: [
										{ label: 'Tools reference', slug: 'eden-memory/reference/tools' },
										{ label: 'CLI reference', slug: 'eden-memory/reference/cli' },
										{ label: 'Environment variables', slug: 'eden-memory/reference/environment-variables' },
										{ label: 'Fallback slash commands', slug: 'eden-memory/reference/fallback-slash-commands' },
										{
											label: 'Skills registry',
											items: [
												{ label: 'Overview', slug: 'eden-memory/skills' },
												{ label: 'MCP usage', slug: 'eden-memory/skills/eden-memory-mcp-usage' },
												{ label: 'Claude Code CLI', slug: 'eden-memory/skills/eden-memory-claude' },
												{ label: 'Cursor', slug: 'eden-memory/skills/eden-memory-cursor' },
												{ label: 'Hermes Agent', slug: 'eden-memory/skills/eden-memory-hermes' },
											],
										},
										{ label: 'Downloads and checksums', slug: 'eden-memory/reference/downloads' },
									],
								},
							],
						},
						{
							label: 'eden-relay',
							items: [
								{ label: 'Overview', slug: 'eden-relay' },
								{
									label: 'How-to guides',
									items: [
										{ label: 'Run your own relay server', slug: 'eden-relay/how-to/run-relay-server' },
										{ label: 'Deploy on a public VPS', slug: 'eden-relay/how-to/deploy-public-vps' },
									],
								},
							],
						},
						{
							label: 'eden-team',
							items: [
								{ label: 'Overview', slug: 'eden-team' },
								{
									label: 'Tutorials',
									items: [
										{ label: 'Set up a headless supervisor', slug: 'eden-team/tutorials/headless-supervisor' },
									],
								},
							],
						},
					],
				},
			],
		}),
	],
});
