package routes

import (
	"io"
	"net/http"
	"os"

	sugar "../sugar"
	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
)

// UploadVideos for routes
func UploadVideos(c *gin.Context) {
	name := c.PostForm("name")
	sugar.Info(name)
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		sugar.Error(err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status": "fail",
			"data":   "Bad request",
		})
		return
	}
	// header调用Filename方法，就可以得到文件名
	filename := header.Filename
	sugar.Info(file, filename)

	// 创建一个文件，文件名为filename，这里的返回值out也是一个File指针
	path := viper.GetString("video.path")
	out, err := os.Create(path + filename)
	if err != nil {
		sugar.Error(err)
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"status": "fail",
			"data":   err,
		})
		return
	}
	defer out.Close()

	// 将file的内容拷贝到out
	_, err = io.Copy(out, file)
	if err != nil {
		sugar.Error(err)
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"status": "fail",
			"data":   err,
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   "{}",
	})
}
