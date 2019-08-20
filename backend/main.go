package main

import (
	config "./config"
	database "./database"
	middlewares "./middlewares"
	routes "./routes"
	sugar "./sugar"
	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
)

func main() {
	gin.SetMode(gin.DebugMode)
	app := gin.New()

	config.LoadConfig()

	sugar.Load()

	app.Use(middlewares.Logger())
	app.Use(gin.Recovery())

	// connection database
	database.Start()

	app.Use(middlewares.CORSMiddleware())
	// bind routes
	user := app.Group("/user")
	{
		user.GET("/info/:id", routes.GetUserInfo)
		user.GET("/list", routes.GetUserList)
		user.PUT("/register", routes.PutUser)
	}

	app.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "pong",
		})
	})

	host := viper.GetString("server.host")
	port := viper.GetString("server.port")
	link := host + ":" + port
	app.Run(link)
}

func initLogger() {

}
