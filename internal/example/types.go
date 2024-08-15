package example

import "context"

type Config struct {
	context.Context
	Url string `json:"url"`
}
