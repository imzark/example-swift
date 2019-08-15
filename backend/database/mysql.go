package database

import (
	"fmt"

	// model
	"github.com/jinzhu/gorm"

	_ "github.com/jinzhu/gorm/dialects/mysql" // sd
)

// MySQLDB golbal instance
var MySQLDB *gorm.DB

// Start open db
func Start() {
	db, err := gorm.Open("mysql", "root:123456@tcp(127.0.0.1:3306)/test?charset=utf8&parseTime=True&loc=Local")
	MySQLDB = db
	if err != nil {
		fmt.Println(err)
	}
	defer db.Close()
	db.LogMode(true)

	// db.AutoMigrate(&model.User{})
}

// GetSession for
func GetSession() *gorm.DB {
	return MySQLDB
}
