package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/gocql/gocql"
)

// Configuration
type Config struct {
	Nodes       []string
	Keyspace    string
	StartTime   time.Time
	EndTime     time.Time
	PhoneNumber string
}

// CallStats holds statistics about calls
type CallStats struct {
	TotalCalls      int
	SuccessfulCalls int
	FailedCalls     int
	SuccessRate     float64
}

func main() {
	// Parse command line flags
	config := parseFlags()

	// Connect to Scylla
	session := connectToScylla(config)
	defer session.Close()

	// Calculate success rate
	stats := calculateSuccessRate(session, config)

	// Display results
	displayResults(config, stats)
}

func parseFlags() Config {
	var config Config

	// Define flags
	nodesStr := flag.String("nodes", "127.0.0.1", "Comma-separated list of Scylla node IPs")
	keyspace := flag.String("keyspace", "calldrop", "Keyspace name")
	startTimeStr := flag.String("start-time", "", "Start time (RFC3339 format, e.g., 2024-01-01T00:00:00Z)")
	endTimeStr := flag.String("end-time", "", "End time (RFC3339 format, e.g., 2024-01-31T23:59:59Z)")
	phoneNumber := flag.String("phone-number", "", "Optional: Filter by specific phone number")

	flag.Parse()

	// Validate required flags
	if *startTimeStr == "" || *endTimeStr == "" {
		fmt.Println("Error: --start-time and --end-time are required")
		fmt.Println("\nUsage:")
		flag.PrintDefaults()
		fmt.Println("\nExample:")
		fmt.Println("  go run call-success-rate.go \\")
		fmt.Println("    --nodes=10.0.1.10,10.0.1.11,10.0.1.12 \\")
		fmt.Println("    --start-time=2024-01-01T00:00:00Z \\")
		fmt.Println("    --end-time=2024-01-31T23:59:59Z \\")
		fmt.Println("    --phone-number=+1234567890")
		os.Exit(1)
	}

	// Parse nodes
	config.Nodes = strings.Split(*nodesStr, ",")
	config.Keyspace = *keyspace
	config.PhoneNumber = *phoneNumber

	// Parse times
	var err error
	config.StartTime, err = time.Parse(time.RFC3339, *startTimeStr)
	if err != nil {
		log.Fatalf("Error parsing start-time: %v", err)
	}

	config.EndTime, err = time.Parse(time.RFC3339, *endTimeStr)
	if err != nil {
		log.Fatalf("Error parsing end-time: %v", err)
	}

	// Validate time range
	if config.EndTime.Before(config.StartTime) {
		log.Fatal("Error: end-time must be after start-time")
	}

	return config
}

func connectToScylla(config Config) *gocql.Session {
	fmt.Println("Connecting to Scylla cluster...")
	fmt.Printf("  Nodes: %s\n", strings.Join(config.Nodes, ", "))
	fmt.Printf("  Keyspace: %s\n\n", config.Keyspace)

	// Create cluster configuration
	cluster := gocql.NewCluster(config.Nodes...)
	cluster.Keyspace = config.Keyspace
	cluster.Consistency = gocql.Quorum
	cluster.Timeout = 10 * time.Second
	cluster.ConnectTimeout = 10 * time.Second

	// Create session
	session, err := cluster.CreateSession()
	if err != nil {
		log.Fatalf("Failed to connect to Scylla: %v", err)
	}

	fmt.Println("✓ Connected successfully\n")
	return session
}

func calculateSuccessRate(session *gocql.Session, config Config) CallStats {
	var stats CallStats

	fmt.Println("Calculating call success rate...")
	fmt.Printf("  Time Range: %s to %s\n", config.StartTime.Format(time.RFC3339), config.EndTime.Format(time.RFC3339))
	if config.PhoneNumber != "" {
		fmt.Printf("  Phone Number: %s\n", config.PhoneNumber)
	} else {
		fmt.Println("  Phone Number: All users")
	}
	fmt.Println()

	if config.PhoneNumber != "" {
		// Query for specific phone number
		stats = calculateForUser(session, config)
	} else {
		// Query for all users
		stats = calculateForAllUsers(session, config)
	}

	// Calculate success rate
	if stats.TotalCalls > 0 {
		stats.SuccessRate = (float64(stats.SuccessfulCalls) / float64(stats.TotalCalls)) * 100
	}

	return stats
}

func calculateForUser(session *gocql.Session, config Config) CallStats {
	var stats CallStats

	// Query all calls for the user in the time range
	query := `
		SELECT call_completed 
		FROM call_records 
		WHERE source_phone_number = ? 
		AND call_timestamp >= ? 
		AND call_timestamp <= ?
	`

	iter := session.Query(query, config.PhoneNumber, config.StartTime, config.EndTime).Iter()

	var callCompleted bool
	for iter.Scan(&callCompleted) {
		stats.TotalCalls++
		if callCompleted {
			stats.SuccessfulCalls++
		} else {
			stats.FailedCalls++
		}
	}

	if err := iter.Close(); err != nil {
		log.Fatalf("Error querying data: %v", err)
	}

	return stats
}

func calculateForAllUsers(session *gocql.Session, config Config) CallStats {
	var stats CallStats

	// First, get all unique phone numbers
	phoneNumbers := getAllPhoneNumbers(session)

	fmt.Printf("Found %d users, analyzing calls...\n", len(phoneNumbers))

	// Query each user's calls in the time range
	for _, phoneNumber := range phoneNumbers {
		query := `
			SELECT call_completed 
			FROM call_records 
			WHERE source_phone_number = ? 
			AND call_timestamp >= ? 
			AND call_timestamp <= ?
		`

		iter := session.Query(query, phoneNumber, config.StartTime, config.EndTime).Iter()

		var callCompleted bool
		for iter.Scan(&callCompleted) {
			stats.TotalCalls++
			if callCompleted {
				stats.SuccessfulCalls++
			} else {
				stats.FailedCalls++
			}
		}

		if err := iter.Close(); err != nil {
			log.Printf("Warning: Error querying user %s: %v", phoneNumber, err)
		}
	}

	return stats
}

func getAllPhoneNumbers(session *gocql.Session) []string {
	var phoneNumbers []string

	// Query to get all unique phone numbers
	// Note: This is not efficient for large datasets
	// In production, consider maintaining a separate users table
	query := `SELECT DISTINCT source_phone_number FROM call_records`
	iter := session.Query(query).Iter()

	var phoneNumber string
	for iter.Scan(&phoneNumber) {
		phoneNumbers = append(phoneNumbers, phoneNumber)
	}

	if err := iter.Close(); err != nil {
		log.Fatalf("Error getting phone numbers: %v", err)
	}

	return phoneNumbers
}

func displayResults(config Config, stats CallStats) {
	fmt.Println("\n" + strings.Repeat("=", 70))
	fmt.Println("CALL SUCCESS RATE ANALYSIS")
	fmt.Println(strings.Repeat("=", 70))

	// Time range
	fmt.Println("\nTime Range:")
	fmt.Printf("  Start: %s\n", config.StartTime.Format("2006-01-02 15:04:05 MST"))
	fmt.Printf("  End:   %s\n", config.EndTime.Format("2006-01-02 15:04:05 MST"))
	duration := config.EndTime.Sub(config.StartTime)
	fmt.Printf("  Duration: %s\n", formatDuration(duration))

	// Filter
	fmt.Println("\nFilter:")
	if config.PhoneNumber != "" {
		fmt.Printf("  Phone Number: %s\n", config.PhoneNumber)
	} else {
		fmt.Println("  Phone Number: All users")
	}

	// Results
	fmt.Println("\nResults:")
	fmt.Println(strings.Repeat("-", 70))
	fmt.Printf("  Total Calls:       %d\n", stats.TotalCalls)
	fmt.Printf("  Successful Calls:  %d\n", stats.SuccessfulCalls)
	fmt.Printf("  Failed Calls:      %d\n", stats.FailedCalls)
	fmt.Println(strings.Repeat("-", 70))
	fmt.Printf("  Success Rate:      %.2f%%\n", stats.SuccessRate)
	fmt.Printf("  Failure Rate:      %.2f%%\n", 100-stats.SuccessRate)
	fmt.Println(strings.Repeat("=", 70))

	// Visual representation
	if stats.TotalCalls > 0 {
		fmt.Println("\nVisual Representation:")
		displayBar("Successful", stats.SuccessfulCalls, stats.TotalCalls, "✓")
		displayBar("Failed", stats.FailedCalls, stats.TotalCalls, "✗")
	}

	fmt.Println()
}

func displayBar(label string, count int, total int, symbol string) {
	percentage := 0.0
	if total > 0 {
		percentage = (float64(count) / float64(total)) * 100
	}

	barLength := 50
	filledLength := int((percentage / 100) * float64(barLength))

	bar := strings.Repeat("█", filledLength) + strings.Repeat("░", barLength-filledLength)

	fmt.Printf("  %-12s [%s] %6d (%.1f%%)\n", label+" "+symbol, bar, count, percentage)
}

func formatDuration(d time.Duration) string {
	days := int(d.Hours() / 24)
	hours := int(d.Hours()) % 24
	minutes := int(d.Minutes()) % 60

	if days > 0 {
		return fmt.Sprintf("%d days, %d hours, %d minutes", days, hours, minutes)
	} else if hours > 0 {
		return fmt.Sprintf("%d hours, %d minutes", hours, minutes)
	} else {
		return fmt.Sprintf("%d minutes", minutes)
	}
}

// Made with Bob
