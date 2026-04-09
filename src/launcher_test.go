package main

import (
	"reflect"
	"testing"
)

func TestParseLauncherArgs(t *testing.T) {
	testCases := []struct {
		name    string
		input   string
		want    []string
		wantErr bool
	}{
		{
			name:  "simple whitespace-separated arguments",
			input: "status query\n",
			want:  []string{"status", "query"},
		},
		{
			name:  "double-quoted argument with spaces",
			input: "tx bank send \"memo text with spaces\"\n",
			want:  []string{"tx", "bank", "send", "memo text with spaces"},
		},
		{
			name:  "escaped whitespace stays in one argument",
			input: "query wasm contract-state smart osmo\\ one\n",
			want:  []string{"query", "wasm", "contract-state", "smart", "osmo one"},
		},
		{
			name:  "single quotes are preserved as one argument",
			input: "keys add 'validator one'\n",
			want:  []string{"keys", "add", "validator one"},
		},
		{
			name:    "unterminated quote returns an error",
			input:   "tx bank send \"missing end\n",
			wantErr: true,
		},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			got, err := parseLauncherArgs(testCase.input)
			if testCase.wantErr {
				if err == nil {
					t.Fatalf("expected an error, got args %v", got)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if !reflect.DeepEqual(got, testCase.want) {
				t.Fatalf("unexpected args: got %v want %v", got, testCase.want)
			}
		})
	}
}
