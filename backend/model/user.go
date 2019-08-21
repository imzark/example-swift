package model

import (
	"errors"
	"time"

	database "../database"
	"github.com/google/uuid"
	"github.com/jinzhu/gorm"
)

// User model
type User struct {
	ID           string     `gorm:"column:id;type:varchar(50);primary_key;not null;"`
	Mobile       string     `gorm:"column:mobile;type:varchar(20);"`
	Email        string     `gorm:"column:email;type:varchar(100);"`
	Level        int        `gorm:"column:level;type:int(10);"`
	UserName     string     `gorm:"column:username;type:varchar(100);"`
	Avatar       string     `gorm:"column:avatar;type:varchar(255);"`
	DeviceID     string     `gorm:"column:device_id;type:varchar(100);"`
	CityID       string     `gorm:"column:city_id;type:varchar(50);"`
	WechatID     string     `gorm:"column:wechat_id;type:varchar(50);"`
	CreatedAt    *time.Time `gorm:"column:created_at;"`
	UpdatedAt    *time.Time `gorm:"column:updated_at;"`
	BindMobileAt *time.Time `gorm:"column:bind_mobile_at;"`
	Password     string     `gorm:"column:password;"`
}

// BeforeCreate s
func (user *User) BeforeCreate(scope *gorm.Scope) error {
	scope.SetColumn("ID", uuid.New())
	user.ID = uuid.New().String()
	return nil
}

// TableName s
func (User) TableName() string {
	return "users"
}

// GetUserByID for
func (user *User) GetUserByID(id string) error {
	db := database.GetSession()
	if err := db.Limit(1).Where("id = ?", id).Find(&user).Error; err != nil {
		return err
	}
	return nil
}

// AddUser for User
func (user *User) AddUser() error {
	db := database.GetSession()
	count := 0
	db.Model(&User{}).Where("email = ?", user.Email).Count(&count)
	if count != 0 {
		return errors.New("email exist")
	}
	user.ID = uuid.New().String()
	db.Create(&user)
	return nil
}
