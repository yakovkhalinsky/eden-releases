// Package eden wraps a subset of the eden-memory CLI so the supervisor can read
// and write durable records without depending on an MCP server.
package eden

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// Record mirrors the eden-memory search/recall output shape.
type Record struct {
	ID       string                 `json:"id"`
	Content  string                 `json:"content"`
	Metadata map[string]interface{} `json:"metadata"`
	Score    float64                `json:"score"`
}

// Client holds the scope and binary path for eden-memory CLI calls.
type Client struct {
	DB          string
	AgentID     string
	UserID      string
	OrgID       string
	WorkspaceID string
	Bin         string
	Verbose     bool
}

// Remember stores a durable record and returns its generated ID.
func (c *Client) Remember(content string, meta map[string]interface{}) (string, error) {
	metaJSON, err := json.Marshal(meta)
	if err != nil {
		return "", fmt.Errorf("marshal metadata: %w", err)
	}

	args := []string{
		"remember",
		"--db", c.DB,
		"--agent-id", c.AgentID,
		"--user-id", c.UserID,
		"--content", content,
		"--metadata", string(metaJSON),
	}
	if c.OrgID != "" {
		args = append(args, "--org-id", c.OrgID)
	}
	if c.WorkspaceID != "" {
		args = append(args, "--workspace-id", c.WorkspaceID)
	}

	out, err := c.run(args)
	if err != nil {
		return "", fmt.Errorf("eden-memory remember: %w", err)
	}

	var resp struct {
		ID     string `json:"id"`
		Status string `json:"status"`
	}
	if err := json.Unmarshal(out, &resp); err != nil {
		return "", fmt.Errorf("parse remember response %q: %w", string(out), err)
	}
	if resp.ID == "" {
		return "", fmt.Errorf("eden-memory remember returned no id: %s", out)
	}
	return resp.ID, nil
}

// SearchGoal returns all records whose content contains the goal ID, filtered
// to records that actually belong to the goal in metadata.
func (c *Client) SearchGoal(goalID string, limit int) ([]Record, error) {
	if limit <= 0 {
		limit = 50
	}

	args := []string{
		"search",
		"--db", c.DB,
		"--agent-id", c.AgentID,
		"--user-id", c.UserID,
		"--keywords", goalID,
		"--limit", fmt.Sprintf("%d", limit),
	}
	if c.OrgID != "" {
		args = append(args, "--org-id", c.OrgID)
	}
	if c.WorkspaceID != "" {
		args = append(args, "--workspace-id", c.WorkspaceID)
	}

	out, err := c.run(args)
	if err != nil {
		return nil, fmt.Errorf("eden-memory search: %w", err)
	}

	var envelope struct {
		Results []Record `json:"results"`
	}
	if err := json.Unmarshal(out, &envelope); err != nil {
		return nil, fmt.Errorf("parse search response %q: %w", string(out), err)
	}

	var filtered []Record
	for _, r := range envelope.Results {
		if r.Metadata == nil {
			continue
		}
		g, _ := r.Metadata["goal_id"].(string)
		if g == goalID {
			filtered = append(filtered, r)
		}
	}
	return filtered, nil
}

func (c *Client) run(args []string) ([]byte, error) {
	if c.Verbose {
		fmt.Fprintf(os.Stderr, "+ %s %s\n", c.Bin, strings.Join(args, " "))
	}
	cmd := exec.Command(c.Bin, args...)
	// Logs go to stderr; JSON response goes to stdout.
	cmd.Stderr = os.Stderr
	return cmd.Output()
}
