package config

import (
	"strings"

	"github.com/spf13/viper"
)

// LoadConfig for
func LoadConfig() {
	viper.AddConfigPath("./conf") // 如果没有指定配置文件，则解析默认的配置文件
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")   // 设置配置文件格式为YAML
	viper.AutomaticEnv()          // 读取匹配的环境变量
	viper.SetEnvPrefix("CRAWLAB") // 读取环境变量的前缀为APISERVER
	replacer := strings.NewReplacer(".", "_")
	viper.SetEnvKeyReplacer(replacer)
	if err := viper.ReadInConfig(); err != nil { // viper解析配置文件
	}
}
