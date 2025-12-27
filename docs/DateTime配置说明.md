# DateTime 时间类型配置说明

## 概述

xDooria-config 使用 Luban 原生的 `datetime` 类型来处理时间配置，策划可以使用可读的日期时间格式进行配置，Luban 会自动将其转换为 Unix 时间戳。

## 自定义类型定义

在 [defines/config.xml](../defines/config.xml) 中定义了以下自定义时间类型：

### 1. DateTime（日期时间）

基础的日期时间类型，支持多种配置格式。

```xml
<bean name="DateTime" comment="日期时间类型，支持多种格式">
    <var name="value" type="datetime" comment="时间值"/>
</bean>
```

### 2. DateTimeRange（时间范围）

时间范围类型，使用 `~` 分隔开始和结束时间。

```xml
<bean name="DateTimeRange" sep="~" comment="时间范围，格式: start~end">
    <var name="start_time" type="datetime" comment="开始时间"/>
    <var name="end_time" type="datetime" comment="结束时间"/>
</bean>
```

### 3. TimeOfDay（时间点）

表示一天中的某个时间点，使用 `:` 分隔。

```xml
<bean name="TimeOfDay" sep=":" comment="时间点，格式: HH:mm:ss">
    <var name="hour" type="int" comment="小时(0-23)"/>
    <var name="minute" type="int" comment="分钟(0-59)"/>
    <var name="second" type="int" comment="秒(0-59)"/>
</bean>
```

### 4. TimeOfDayRange（时间段范围）

一天内的时间段范围，使用 `;` 分隔。

```xml
<bean name="TimeOfDayRange" sep=";" comment="时间段范围，格式: HH:mm:ss;HH:mm:ss">
    <var name="start_time" type="TimeOfDay" comment="开始时间点"/>
    <var name="end_time" type="TimeOfDay" comment="结束时间点"/>
</bean>
```

## 支持的配置格式

### 格式1: 完整日期时间（推荐）

```
2025-01-28 00:00:00
2025-02-14 12:30:00
2025-12-31 23:59:59
```

**优点**：精确到秒，清晰明确
**适用场景**：限时活动、版本更新时间

### 格式2: 仅日期

```
2025-01-28
2025-02-14
```

**说明**：默认时间为 00:00:00
**适用场景**：按天计算的活动

### 格式3: Excel 日期格式

在 Excel 中直接设置单元格格式为"日期"或"日期时间"，然后选择日期。

**操作步骤**：
1. 选中单元格
2. 右键 → 设置单元格格式
3. 选择"日期"或"自定义"
4. 格式：`yyyy-mm-dd hh:mm:ss`

### 格式4: Unix时间戳（不推荐）

```
1735660800
```

**说明**：仅用于兼容旧配置，新配置不建议使用

## 实际应用示例

### 示例1: 限时商店配置

在 [Shop.xlsx](../datas/Shop.xlsx) 的"限时商店" Sheet 中：

```csv
__type__,id,item_id,start_time,end_time
ShopItemTimeLimited,18,1005,"2025-01-28 00:00:00","2025-02-04 00:00:00"
ShopItemTimeLimited,19,2003,"2025-02-14 00:00:00","2025-02-20 23:59:59"
ShopItemTimeLimited,20,4002,"2025-03-01 00:00:00","2025-03-07 23:59:59"
```

**含义**：
- 道具1005：春节活动期间出售（1月28日-2月4日）
- 道具2003：情人节活动期间出售（2月14日-2月20日）
- 道具4002：三月限时活动（3月1日-3月7日）

### 示例2: 使用 DateTimeRange

如果使用 `DateTimeRange` 类型（更紧凑）：

```csv
__type__,id,item_id,time_range
ShopItemTimeLimited,18,1005,"2025-01-28 00:00:00~2025-02-04 00:00:00"
ShopItemTimeLimited,19,2003,"2025-02-14~2025-02-20"
```

### 示例3: 每日刷新时间点

使用 `TimeOfDay` 配置每日刷新时间：

```csv
shop_type,refresh_time
Mystery,"05:00:00"
Guild,"00:00:00"
```

**含义**：
- 神秘商店：每天凌晨5点刷新
- 公会商店：每天0点刷新

### 示例4: 营业时间段

使用 `TimeOfDayRange` 配置每日营业时间：

```csv
shop_type,open_hours
Special,"10:00:00;22:00:00"
```

**含义**：特殊商店每天10:00-22:00营业

## 代码中的使用

### Go 代码示例

```go
// Luban 生成的 ShopItemTimeLimited 结构
type ShopItemTimeLimited struct {
    *ShopItemBase
    StartTime int64  // 自动转换为 Unix 时间戳
    EndTime   int64  // 自动转换为 Unix 时间戳
}

// 检查道具是否在售
func IsItemOnSale(item *ShopItemTimeLimited) bool {
    now := time.Now().Unix()
    return now >= item.StartTime && now <= item.EndTime
}

// 获取剩余时间
func GetTimeLeft(item *ShopItemTimeLimited) time.Duration {
    now := time.Now().Unix()
    if now >= item.EndTime {
        return 0
    }
    return time.Duration(item.EndTime - now) * time.Second
}
```

### 客户端显示倒计时

```go
// 显示活动倒计时
func ShowCountdown(item *ShopItemTimeLimited) string {
    now := time.Now().Unix()

    if now < item.StartTime {
        // 活动未开始
        timeLeft := item.StartTime - now
        return fmt.Sprintf("距离开始: %s", FormatDuration(timeLeft))
    }

    if now >= item.EndTime {
        // 活动已结束
        return "活动已结束"
    }

    // 活动进行中
    timeLeft := item.EndTime - now
    return fmt.Sprintf("剩余时间: %s", FormatDuration(timeLeft))
}

func FormatDuration(seconds int64) string {
    days := seconds / 86400
    hours := (seconds % 86400) / 3600
    minutes := (seconds % 3600) / 60

    if days > 0 {
        return fmt.Sprintf("%d天%d小时", days, hours)
    }
    if hours > 0 {
        return fmt.Sprintf("%d小时%d分钟", hours, minutes)
    }
    return fmt.Sprintf("%d分钟", minutes)
}
```

## 常见问题

### Q1: 为什么配置的是日期时间，生成的代码是 int64？

**A**: Luban 的 `datetime` 类型在配置文件中使用可读的日期时间格式，但在生成代码时会自动转换为 Unix 时间戳（int64），这样程序中比较和计算更高效。

### Q2: 时区如何处理？

**A**: Luban 解析 datetime 时默认使用 UTC 时区。如果需要特定时区，建议：
- 服务器统一使用 UTC 时间
- 客户端根据玩家时区显示本地时间

### Q3: 如何配置"永久有效"？

**A**: 可以设置一个很远的未来时间，或者：
- `start_time`: 留空或 0
- `end_time`: `2099-12-31 23:59:59`

### Q4: Excel 中显示的是数字怎么办？

**A**: 这是 Excel 的日期序列号。解决方法：
1. 选中单元格
2. 设置单元格格式为"自定义"
3. 格式码：`yyyy-mm-dd hh:mm:ss`

### Q5: 支持相对时间吗（如"+7天"）？

**A**: Luban 原生不支持。如需此功能，需要在代码层实现：
```go
// 配置版本更新时间
versionUpdateTime := int64(1735660800)

// 代码中计算相对时间
sevenDaysLater := versionUpdateTime + 7*24*3600
```

## 最佳实践

### ✅ 推荐做法

1. **使用完整日期时间格式**
   ```
   2025-01-28 00:00:00  ✓ 清晰明确
   ```

2. **活动结束时间精确到秒**
   ```
   2025-02-04 23:59:59  ✓ 精确到最后一秒
   ```

3. **统一时区**
   ```
   所有配置使用 UTC 时区  ✓ 避免混乱
   ```

4. **添加注释**
   ```csv
   # 春节活动
   start_time,end_time
   "2025-01-28 00:00:00","2025-02-04 23:59:59"
   ```

### ❌ 避免做法

1. **混用时间戳和日期**
   ```
   1735660800, "2025-02-04"  ✗ 风格不统一
   ```

2. **省略时间部分导致歧义**
   ```
   "2025-02-04"  ✗ 到底是0点还是24点？
   ```

3. **使用本地时间**
   ```
   "2025-01-28 08:00:00 CST"  ✗ 时区标识会导致解析失败
   ```

## 总结

使用 Luban 的 `datetime` 类型配置时间：
- ✅ 策划直接看懂配置
- ✅ 减少配置错误
- ✅ 支持多种格式
- ✅ 自动转换为时间戳
- ✅ 代码无需额外处理

推荐使用 `YYYY-MM-DD HH:mm:ss` 格式进行配置！
