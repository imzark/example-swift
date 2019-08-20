package sugar

import (
	"os"
	"time"

	"github.com/Sirupsen/logrus"
	"github.com/spf13/viper"
)

var log *logrus.Logger

// Load for sugar
func Load() {
	path := viper.GetString("log.path")
	env := viper.GetString("log.env")
	log = logrus.New()
	date := time.Now().Format("2006-01-02")
	filePath := path + date + ".log"
	file, err := os.OpenFile(filePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err == nil && env == "production" {
		log.Out = file
	} else {
		log.Info("Failed to log to file, using default stderr")
	}
	// log.SetFormatter(&logrus.JSONFormatter{})
}

// GetLogger for sugar
func GetLogger() *logrus.Logger {
	return log
}

// Error fot sugar
func Error() {

}
