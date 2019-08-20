package routes

import (
	"net/http"

	model "../model"
	"github.com/gin-gonic/gin"
)

// GetUserInfo for routes
func GetUserInfo(c *gin.Context) {
	id := c.Param("id")
	user := model.User{}
	err := user.GetUser(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status": "fail",
			"data":   user,
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   user,
	})
}

// GetUserList for routes
func GetUserList(c *gin.Context) {

}

// PutUser for routes
func PutUser(c *gin.Context) {
	email := c.PostForm("email")
	username := c.PostForm("username")
	password := c.PostForm("password")
	if email == "" || username == "" || password == "" {
		c.JSON(http.StatusOK, gin.H{
			"status": "fail",
			"data":   "",
		})
		return
	}
	user := model.User{Email: email, UserName: username, Password: password}
	err := user.AddUser()
	if err != nil {

	}
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   user,
	})
	return
}
