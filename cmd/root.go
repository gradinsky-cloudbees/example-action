package cmd

import (
	"github.com/gradinsky-cloudbees/example-action/internal/example"
	"github.com/spf13/cobra"
	"log"
	"os"
	"path/filepath"
)

var (
	cmd = &cobra.Command{
		Use:   "example-action",
		Short: "CLI to execute REST API actions",
		Long:  "CLI to execute REST API actions",
		RunE:  run,
	}
	cfg example.Config
)

// These are the input flags. Created with internal/rest-api/types.go
func init() {
	cmd.Flags().StringVar(&cfg.Url, "url", "", "Enter some URL here")
}

func Execute() error {
	return cmd.Execute()
}

func run(*cobra.Command, []string) error {
	resp := cfg.ExampleCall()
	log.Println("Inside the run method")
	//Write output when successful, it parses the response body
	err := os.WriteFile(filepath.Join(os.Getenv("CLOUDBEES_OUTPUTS"), "output1"), []byte(resp), 0666)
	log.Println("Post writing output")
	log.Println(err)
	return err
}
