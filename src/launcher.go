package main

import (
	"bufio"
	"log"
	"os"
	"strings"
)

func is_launcher() bool {
	return len(os.Args) > 1 && os.Args[1] == "--launcher"
}

func remove(slice []string, s int) []string {
	return append(slice[:s], slice[s+1:]...)
}

func wait_for_launcher() {
	if is_launcher() {
		// Remove launcher tag
		os.Args = remove(os.Args, 1)

		if len(os.Args) == 1 {
			//Wait for stdin
			reader := bufio.NewReader(os.Stdin)
			line, err := reader.ReadString('\n')

			if err != nil {
				log.Fatal(err)
				os.Exit(1)
			}

			var launcherArgs = strings.Fields(line)

			os.Args = append(os.Args, launcherArgs...)
		}
	}
}
