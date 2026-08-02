// Package record defines the structured output the supervisor expects from each
// headless role process, plus helpers to extract it from Claude CLI JSON.
package record

import (
	"encoding/json"
	"fmt"
	"regexp"
	"strings"
)

// RoleReport is the JSON object each role must return in its final output.
type RoleReport struct {
	RecordType string                 `json:"record_type"`
	Stage      string                 `json:"stage"`
	OwnerRole  string                 `json:"owner_role"`
	Status     string                 `json:"status"`
	Summary    string                 `json:"summary"`
	Content    string                 `json:"content"`
	Metadata   map[string]interface{} `json:"metadata"`
	HandOff    *HandOff               `json:"hand_off"`
}

// HandOff captures the next role and transfer details.
type HandOff struct {
	NextRole          string `json:"next_role"`
	Reason            string `json:"reason"`
	SuccessCriteria   string `json:"success_criteria"`
	Deadline          string `json:"deadline"`
	EscalationTrigger string `json:"escalation_trigger"`
}

// FromClaudeResult extracts a RoleReport from the `result` string of a headless
// Claude JSON response. It tolerates markdown fences and trailing prose.
func FromClaudeResult(result string) (*RoleReport, error) {
	text := strings.TrimSpace(result)

	// Strip markdown fences if present.
	if strings.HasPrefix(text, "```json") {
		text = strings.TrimPrefix(text, "```json")
		text = strings.TrimSpace(text)
		if idx := strings.LastIndex(text, "```"); idx >= 0 {
			text = strings.TrimSpace(text[:idx])
		}
	} else if strings.HasPrefix(text, "```") {
		text = strings.TrimPrefix(text, "```")
		text = strings.TrimSpace(text)
		if idx := strings.LastIndex(text, "```"); idx >= 0 {
			text = strings.TrimSpace(text[:idx])
		}
	}

	// Try the whole payload first.
	var report RoleReport
	if err := json.Unmarshal([]byte(text), &report); err == nil && report.RecordType != "" {
		return &report, nil
	}

	// Otherwise look for the first JSON object in the text.
	obj := findFirstJSONObject(text)
	if obj == "" {
		return nil, fmt.Errorf("no JSON object found in Claude result")
	}
	if err := json.Unmarshal([]byte(obj), &report); err != nil {
		return nil, fmt.Errorf("failed to parse role report JSON: %w\nJSON: %s", err, obj)
	}
	if report.RecordType == "" {
		return nil, fmt.Errorf("parsed JSON is not a role report (missing record_type): %s", obj)
	}
	return &report, nil
}

// AsRunLog returns a free-text result as a synthetic run_log report.
func AsRunLog(role, summary string) *RoleReport {
	return &RoleReport{
		RecordType: "run_log",
		Stage:      "action",
		OwnerRole:  role,
		Status:     "completed",
		Summary:    summary,
		Content:    summary,
	}
}

var braceRe = regexp.MustCompile(`(?s)\{.*\}`)

func findFirstJSONObject(s string) string {
	match := braceRe.FindString(s)
	return match
}
