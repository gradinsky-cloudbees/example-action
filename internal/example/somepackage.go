package example

import (
	"fmt"
)

func (c *Config) ExampleCall() string {
	fmt.Printf("Inside the example method %v\n", c.Url)
	return c.Url
}
