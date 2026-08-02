// Package role loads headless role prompts and invokes Claude Code CLI with them.
package role

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/yakovkhalinsky/eden-releases/agentic-team-protocol/deployable/internal/record"
)

// Runner executes a single role process.
type Runner struct {
	ClaudeBin                  string
	MCPConfig                  string
	StrictMCP                  bool
	MaxTurns                   int
	DangerouslySkipPermissions bool
	PermissionMode             string
	Verbose                    bool
}

// RolePrompt loads the prompt template for a named role.
func RolePrompt(rolesDir, role string) (string, error) {
	path := filepath.Join(rolesDir, role+".md")
	b, err := os.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("read role prompt %s: %w", path, err)
	}
	return string(b), nil
}

// Context is the runtime context passed to a role process.
type Context struct {
	GoalID         string                 `json:"goal_id"`
	Goal           string                 `json:"goal"`
	CurrentStage   string                 `json:"current_stage"`
	CurrentRole    string                 `json:"current_role"`
	PreviousRecord map[string]interface{} `json:"previous_record"`
	History        []map[string]interface{} `json:"history"`
}

// Run invokes Claude Code CLI headlessly with the role prompt and context.
func (r *Runner) Run(role, rolesDir string, ctx Context) (*record.RoleReport, error) {
	prompt, err := RolePrompt(rolesDir, role)
	if err != nil {
		return nil, err
	}

	ctxJSON, err := json.MarshalIndent(ctx, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("marshal context: %w", err)
	}

	userPrompt := fmt.Sprintf("%s\n\n## Current ATP context\n\n```json\n%s\n```\n\nFollow the obligations in the role prompt above. Produce ONLY the required JSON output object in your final response. Do not add commentary outside the JSON object.", prompt, string(ctxJSON))

	args := []string{}
	if r.MCPConfig != "" {
		if r.StrictMCP {
			args = append(args, "--strict-mcp-config")
		}
		args = append(args, "--mcp-config", r.MCPConfig)
	}
	if r.DangerouslySkipPermissions {
		args = append(args, "--dangerously-skip-permissions")
	} else if r.PermissionMode != "" {
		args = append(args, "--permission-mode", r.PermissionMode)
	}
	args = append(args,
		"--output-format", "json",
		"--max-turns", fmt.Sprintf("%d", r.MaxTurns),
		"-p", userPrompt,
	)

	if r.Verbose {
		fmt.Fprintf(os.Stderr, "+ %s %s\n", r.ClaudeBin, strings.Join(args, " "))
	}

	cmd := exec.Command(r.ClaudeBin, args...)
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("claude process failed: %w", err)
	}

	var resp struct {
		Result string `json:"result"`
	}
	if err := json.Unmarshal(out, &resp); err != nil {
		return nil, fmt.Errorf("parse claude JSON response: %w\nRaw: %s", err, string(out))
	}

	report, err := record.FromClaudeResult(resp.Result)
	if err != nil {
		return record.AsRunLog(role, fmt.Sprintf("role %s produced non-JSON result: %s", role, resp.Result)), nil
	}
	return report, nil
}
