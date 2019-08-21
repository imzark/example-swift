package main

import (
	config "./config"
	database "./database"
	middlewares "./middlewares"
	model "./model"
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
	database.GetSession().AutoMigrate(&model.User{})

	app.Use(middlewares.CORSMiddleware())
	// bind routes
	user := app.Group("/user")
	{
		user.GET("/info/:id", routes.GetUserInfo)
		user.GET("/list", routes.GetUserList)
		user.PUT("/register", routes.PutUser)
	}

	upload := app.Group("/upload")
	{
		upload.POST("/video", routes.UploadVideos)
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
