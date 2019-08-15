package main

import (
	database "./database"
	routes "./routes"
	"github.com/gin-gonic/gin"
)

func main() {
	gin.SetMode(gin.DebugMode)
	app := gin.Default()
	// TODO config init

	// TODO Logs init

	// TODO SQL init
	database.Start()
	// TODO set routes

	// TODO users routes
	user := app.Group("/user")
	{
		user.GET("/info/:id", routes.GetUserInfo)
		user.GET("/list", routes.GetUserList)
	}

	app.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "pong",
		})
	})

	app.Run(":8081") // listen and serve on 0.0.0.0:8080
}
