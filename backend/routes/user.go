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
