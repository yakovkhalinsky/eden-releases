package config

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
)

// Config holds all CLI flags and derived paths for the supervisor.
type Config struct {
	DB                         string
	AgentID                    string
	UserID                     string
	OrgID                      string
	WorkspaceID                string
	MCPConfig                  string
	StrictMCP                  bool
	ClaudeBin                  string
	EdenBin                    string
	RolesDir                   string
	MaxLoops                   int
	MaxTurns                   int
	Goal                       string
	GoalFile                   string
	GoalID                     string
	Continue                   bool
	DangerouslySkipPermissions bool
	PermissionMode             string
	Verbose                    bool
}

func defaultString(a, b string) string {
	if a != "" {
		return a
	}
	return b
}

// Parse reads command-line flags and environment variables into Config.
func Parse(args []string) (*Config, error) {
	fs := flag.NewFlagSet("atp-run", flag.ContinueOnError)

	cfg := &Config{}

	fs.StringVar(&cfg.DB, "db", defaultString(os.Getenv("EDEN_MEMORY_DB"), filepath.Join(os.Getenv("HOME"), ".eden-memory", "default.db")), "Path to eden-memory SQLite database")
	fs.StringVar(&cfg.AgentID, "agent-id", defaultString(os.Getenv("EDEN_AGENT_ID"), "atp-run"), "Agent identity for Eden-memory records")
	fs.StringVar(&cfg.UserID, "user-id", defaultString(os.Getenv("EDEN_USER_ID"), os.Getenv("USER")), "User identity for Eden-memory records")
	fs.StringVar(&cfg.OrgID, "org-id", os.Getenv("EDEN_ORG_ID"), "Organization scope for Eden-memory records")
	fs.StringVar(&cfg.WorkspaceID, "workspace-id", os.Getenv("EDEN_WORKSPACE_ID"), "Workspace scope for Eden-memory records")
	fs.StringVar(&cfg.MCPConfig, "mcp-config", os.Getenv("ATP_MCP_CONFIG"), "Path to MCP config JSON for headless Claude role processes")
	fs.BoolVar(&cfg.StrictMCP, "strict-mcp-config", true, "Use only the supplied MCP config in role processes")
	fs.StringVar(&cfg.ClaudeBin, "claude-bin", defaultString(os.Getenv("CLAUDE_CODE_BIN"), "claude"), "Path to Claude Code CLI binary")
	fs.StringVar(&cfg.EdenBin, "eden-bin", defaultString(os.Getenv("EDEN_MEMORY_BIN"), filepath.Join(os.Getenv("HOME"), ".local", "bin", "eden-memory")), "Path to eden-memory binary")
	fs.StringVar(&cfg.RolesDir, "roles-dir", os.Getenv("ATP_ROLES_DIR"), "Directory containing role prompt templates")
	fs.IntVar(&cfg.MaxLoops, "max-loops", 20, "Maximum role transitions before giving up")
	fs.IntVar(&cfg.MaxTurns, "max-turns", 25, "Max turns passed to each headless Claude process")
	fs.StringVar(&cfg.Goal, "goal", "", "Goal text (inline)")
	fs.StringVar(&cfg.GoalFile, "goal-file", "", "Path to file containing goal text")
	fs.StringVar(&cfg.GoalID, "goal-id", "", "Goal ID; generated if empty")
	fs.BoolVar(&cfg.Continue, "continue", false, "Resume an existing goal (requires --goal-id)")
	fs.BoolVar(&cfg.DangerouslySkipPermissions, "dangerously-skip-permissions", false, "Skip permission prompts in role processes")
	fs.StringVar(&cfg.PermissionMode, "permission-mode", os.Getenv("ATP_PERMISSION_MODE"), "Permission mode for role processes (e.g. auto)")
	fs.BoolVar(&cfg.Verbose, "verbose", false, "Print Claude CLI output and eden-memory commands")

	if err := fs.Parse(args); err != nil {
		return nil, err
	}

	// If roles-dir is not set, default to ../roles relative to the binary.
	if cfg.RolesDir == "" {
		exe, err := os.Executable()
		if err != nil {
			return nil, fmt.Errorf("cannot locate executable: %w", err)
		}
		cfg.RolesDir = filepath.Join(filepath.Dir(exe), "roles")
	}

	if cfg.UserID == "" {
		u, err := os.UserHomeDir()
		_ = u
		if err == nil {
			cfg.UserID = os.Getenv("USER")
		}
		if cfg.UserID == "" {
			return nil, fmt.Errorf("--user-id is required; set EDEN_USER_ID or USER")
		}
	}

	if cfg.Continue {
		if cfg.GoalID == "" {
			return nil, fmt.Errorf("--continue requires --goal-id")
		}
		if cfg.Goal != "" || cfg.GoalFile != "" {
			return nil, fmt.Errorf("--goal and --goal-file are not allowed with --continue")
		}
	} else {
		if cfg.Goal == "" && cfg.GoalFile == "" {
			return nil, fmt.Errorf("--goal or --goal-file is required")
		}
		if cfg.Goal == "" {
			b, err := os.ReadFile(cfg.GoalFile)
			if err != nil {
				return nil, fmt.Errorf("reading --goal-file: %w", err)
			}
			cfg.Goal = string(b)
		}
	}

	return cfg, nil
}
