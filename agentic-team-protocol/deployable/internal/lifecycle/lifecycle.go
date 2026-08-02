// Package lifecycle implements the ATP router decision table based on the
// latest durable record for a goal.
package lifecycle

import (
	"fmt"
	"sort"
	"strings"
	"time"
)

// Record mirrors the subset of fields the router needs.
type Record struct {
	ID       string
	Type     string // record_type or inferred from content/metadata
	Stage    string
	Owner    string // owner_role
	Status   string
	Metadata map[string]interface{}
	StoredAt time.Time
}

// NextRole tells the supervisor which role to invoke next and why.
type NextRole struct {
	Role   string
	Stage  string
	Reason string
	Done   bool
}

// Decide returns the next role given a slice of goal records.
func Decide(records []Record) (NextRole, error) {
	if len(records) == 0 {
		return NextRole{}, fmt.Errorf("no records for goal")
	}

	// Sort newest first.
	sort.Slice(records, func(i, j int) bool {
		return records[i].StoredAt.After(records[j].StoredAt)
	})

	latest := records[0]

	// Terminal: archival_record with no newer action_record.
	if latest.Type == "archival_record" || latest.Stage == "hand_off_or_closure" {
		newerAction := false
		for _, r := range records[1:] {
			if r.StoredAt.After(latest.StoredAt) && (r.Type == "action_record" || r.Stage == "action") {
				newerAction = true
				break
			}
		}
		if !newerAction {
			return NextRole{Done: true, Reason: "archival_record is terminal"}, nil
		}
	}

	// Blocked / pending_authorisation never advances automatically.
	if latest.Status == "blocked" || latest.Status == "pending_authorisation" {
		return NextRole{
			Role:   latest.Owner,
			Stage:  latest.Stage,
			Reason: fmt.Sprintf("goal is %s; requires manual resolution", latest.Status),
		}, nil
	}

	switch latest.Type {
	case "goal_record":
		return NextRole{Role: "dispatcher", Stage: "routing_and_assignment", Reason: "goal needs routing"}, nil
	case "dispatch_instruction":
		pkg := stringMeta(latest.Metadata, "package_type")
		if pkg == "research" {
			return NextRole{Role: "researcher", Stage: "context_gathering", Reason: "dispatch is research"}, nil
		}
		target := stringMeta(latest.Metadata, "target_role")
		if target == "" {
			target = "builder"
		}
		return NextRole{Role: target, Stage: "action", Reason: "dispatch assigned to " + target}, nil
	case "context_summary":
		target := stringMeta(latest.Metadata, "target_role")
		if target == "" {
			target = "builder"
		}
		return NextRole{Role: target, Stage: "action", Reason: "context gathered; proceed to action"}, nil
	case "action_record":
		return NextRole{Role: "verifier", Stage: "verification", Reason: "action complete; mandatory verifier gate"}, nil
	case "verdict":
		status := strings.ToLower(latest.Status)
		switch status {
		case "green":
			return NextRole{Role: "archivist", Stage: "recording_and_archival", Reason: "green verdict; archive"}, nil
		case "red":
			return NextRole{Role: "dispatcher", Stage: "routing_and_assignment", Reason: "red verdict; dispatcher issues rework"}, nil
		case "blocked":
			return NextRole{Role: latest.Owner, Stage: latest.Stage, Reason: "verdict is blocked; manual resolution required"}, nil
		default:
			return NextRole{Role: "verifier", Stage: "verification", Reason: "verdict status unclear; re-verify"}, nil
		}
	case "hand_off_record":
		next := stringMeta(latest.Metadata, "next_role")
		if next == "" {
			next = stringMeta(latest.Metadata, "receiving_role")
		}
		if next == "" {
			return NextRole{}, fmt.Errorf("hand_off_record has no next_role")
		}
		return NextRole{Role: next, Stage: "action", Reason: "continue from hand-off to " + next}, nil
	case "run_log":
		// Fallback: look at the record just before the run_log to infer state.
		for _, r := range records[1:] {
			if r.Type != "run_log" {
				return Decide([]Record{r})
			}
		}
		return NextRole{Role: "dispatcher", Stage: "routing_and_assignment", Reason: "run_log only; route via dispatcher"}, nil
	default:
		// Unknown record type: route to dispatcher.
		return NextRole{Role: "dispatcher", Stage: "routing_and_assignment", Reason: "unrecognized latest record type " + latest.Type}, nil
	}
}

func stringMeta(m map[string]interface{}, key string) string {
	if m == nil {
		return ""
	}
	v, ok := m[key]
	if !ok {
		return ""
	}
	s, ok := v.(string)
	if ok {
		return s
	}
	return fmt.Sprintf("%v", v)
}
