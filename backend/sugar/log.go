package sugar

import (
	"fmt"
	"time"
	"unicode"

	"github.com/jinzhu/gorm"
	"github.com/spf13/viper"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var sugar *zap.SugaredLogger

// Load for sugar
func Load() {
	path := viper.GetString("log.path")
	// env := viper.GetString("log.env")
	date := time.Now().Format("2006-01-02")
	filePath := path + date + ".log"

	// logger, _ := zap.NewProduction()

	encoderConfig := zapcore.EncoderConfig{
		TimeKey:        "time",
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		MessageKey:     "msg",
		StacktraceKey:  "stacktrace",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.LowercaseLevelEncoder, // 小写编码器
		EncodeTime:     zapcore.ISO8601TimeEncoder,    // ISO8601 UTC 时间格式
		EncodeDuration: zapcore.SecondsDurationEncoder,
		EncodeCaller:   zapcore.FullCallerEncoder, // 全路径编码器
	}

	// 设置日志级别
	atom := zap.NewAtomicLevelAt(zap.DebugLevel)

	config := zap.Config{
		Level:         atom,          // 日志级别
		Development:   true,          // 开发模式，堆栈跟踪
		Encoding:      "json",        // 输出格式 console 或 json
		EncoderConfig: encoderConfig, // 编码器配置
		// InitialFields:    map[string]interface{}{"serviceName": "spikeProxy"}, // 初始化字段，如：添加一个服务器名称
		OutputPaths:      []string{"stdout", filePath}, // 输出到指定文件 stdout（标准输出，正常颜色） stderr（错误输出，红色）
		ErrorOutputPaths: []string{"stderr", filePath},
	}

	// 构建日志
	logger, _ := config.Build()
	defer logger.Sync() // flushes buffer, if any
	sugar = logger.Sugar()
	// sugar.SetFormatter(&logrus.JSONFormatter{})
}

// Info for sugar
func Info(args ...interface{}) {
	sugar.Info(args)
}

// Error fot sugar
func Error(args ...interface{}) {
	sugar.Error(args)
}

// GetLogger for sugar
func GetLogger() *zap.SugaredLogger {
	return sugar
}

// GetGormLogger for gorm log
func GetGormLogger() *Logger {
	return &Logger{
		sugar: sugar,
	}
}

// Logger is an alternative implementation of *gorm.Logger
type Logger struct {
	sugar *zap.SugaredLogger
}

// Print passes arguments to Println
func (l *Logger) Print(values ...interface{}) {
	l.Println(values)
}

// Println format & print log
func (l *Logger) Println(values []interface{}) {
	l.sugar.Info(createLog(values).toZapFields())
}

type log struct {
	occurredAt time.Time
	source     string
	duration   time.Duration
	sql        string
	values     []string
	other      []string
}

func (l *log) toZapFields() []zapcore.Field {
	return []zapcore.Field{
		zap.Time("occurredAt", l.occurredAt),
		zap.String("source", l.source),
		zap.Duration("duration", l.duration),
		zap.String("sql", l.sql),
		zap.Strings("values", l.values),
		zap.Strings("other", l.other),
	}
}

func createLog(values []interface{}) *log {
	ret := &log{}
	ret.occurredAt = gorm.NowFunc()

	if len(values) > 1 {
		var level = values[0]
		ret.source = getSource(values)

		if level == "sql" {
			ret.duration = getDuration(values)
			ret.values = getFormattedValues(values)
			ret.sql = values[3].(string)
		} else {
			ret.other = append(ret.other, fmt.Sprint(values[2:]))
		}
	}

	return ret
}

func isPrintable(s string) bool {
	for _, r := range s {
		if !unicode.IsPrint(r) {
			return false
		}
	}
	return true
}

func getFormattedValues(values []interface{}) []string {
	rawValues := values[4].([]interface{})
	formattedValues := make([]string, 0, len(rawValues))
	for _, value := range rawValues {
		switch v := value.(type) {
		case time.Time:
			formattedValues = append(formattedValues, fmt.Sprint(v))
		case []byte:
			if str := string(v); isPrintable(str) {
				formattedValues = append(formattedValues, fmt.Sprint(str))
			} else {
				formattedValues = append(formattedValues, "<binary>")
			}
		default:
			str := "NULL"
			if v != nil {
				str = fmt.Sprint(v)
			}
			formattedValues = append(formattedValues, str)
		}
	}
	return formattedValues
}

func getSource(values []interface{}) string {
	return fmt.Sprint(values[1])
}

func getDuration(values []interface{}) time.Duration {
	return values[2].(time.Duration)
}
