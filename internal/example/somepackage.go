package example

import (
	"log"
)

func (c *Config) ExampleCall() string {
	log.Printf("Inside the example method %v\n", c.Url)
	return c.Url
}
