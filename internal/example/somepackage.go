package example

import (
	"log"
)

// ExampleCall This just prints out the c.Url and then returns it to be set to the output parameter
func (c *Config) ExampleCall() string {
	log.Printf("Inside the example method %v\n", c.Url)
	return c.Url
}
