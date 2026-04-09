package main

import (
	"bufio"
	"fmt"
	"io"
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

func parseLauncherArgs(line string) ([]string, error) {
	var args []string
	var current strings.Builder

	inSingleQuote := false
	inDoubleQuote := false
	escaping := false

	flushCurrent := func() {
		if current.Len() > 0 {
			args = append(args, current.String())
			current.Reset()
		}
	}

	for _, r := range strings.TrimSpace(line) {
		if escaping {
			current.WriteRune(r)
			escaping = false
			continue
		}

		switch r {
		case '\\':
			escaping = true
		case '\'':
			if inDoubleQuote {
				current.WriteRune(r)
			} else {
				inSingleQuote = !inSingleQuote
			}
		case '"':
			if inSingleQuote {
				current.WriteRune(r)
			} else {
				inDoubleQuote = !inDoubleQuote
			}
		case ' ', '\t', '\n', '\r':
			if inSingleQuote || inDoubleQuote {
				current.WriteRune(r)
			} else {
				flushCurrent()
			}
		default:
			current.WriteRune(r)
		}
	}

	if escaping {
		return nil, fmt.Errorf("unterminated escape sequence")
	}

	if inSingleQuote || inDoubleQuote {
		return nil, fmt.Errorf("unterminated quoted argument")
	}

	flushCurrent()
	return args, nil
}

func wait_for_launcher() {
	if is_launcher() {
		os.Args = remove(os.Args, 1)

		if len(os.Args) == 1 {
			reader := bufio.NewReader(os.Stdin)
			line, err := reader.ReadString('\n')

			if err != nil && err != io.EOF {
				log.Fatal(err)
				os.Exit(1)
			}

			launcherArgs, err := parseLauncherArgs(line)
			if err != nil {
				log.Fatal(err)
				os.Exit(1)
			}

			os.Args = append(os.Args, launcherArgs...)
		}
	}
}
