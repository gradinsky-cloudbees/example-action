package main

import (
	"github.com/gradinsky-cloudbees/example-action/cmd"
	"log"
)

func main() {
	if err := cmd.Execute(); err != nil {
		log.Fatal(err)
	}
}
