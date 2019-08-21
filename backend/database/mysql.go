package database

import (
	sugar "../sugar"
	"github.com/jinzhu/gorm"
	"github.com/spf13/viper"

	_ "github.com/jinzhu/gorm/dialects/mysql" // sd
)

// MySQLDB golbal instance
var MySQLDB *gorm.DB

// Start open db
func Start() {
	host := viper.GetString("mysql.host")
	port := viper.GetString("mysql.port")
	username := viper.GetString("mysql.username")
	password := viper.GetString("mysql.password")
	database := viper.GetString("mysql.db")

	link := username + ":" + password + "@tcp(" + host + ":" + port + ")/" + database + "?charset=utf8&parseTime=True&loc=Local"
	db, err := gorm.Open("mysql", link)

	MySQLDB = db
	if err != nil {
		sugar.Error(err)
	}
	// defer db.Close()
	db.LogMode(true)
	db.SetLogger(sugar.GetGormLogger())
}

// GetSession for
func GetSession() *gorm.DB {
	return MySQLDB
}
