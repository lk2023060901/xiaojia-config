# xDooria 游戏配置系统

基于 Luban 4.5.0 的游戏配置数据管理系统，支持客户端和服务端配置分离、多态继承、自定义时间类型等高级特性。

## 目录结构

```
xDooria-config/
├── bin/                    # Luban 可执行文件
│   ├── macos/Luban        # macOS 版本
│   └── linux/Luban        # Linux 版本
├── datas/                 # 配置数据文件
│   ├── __tables__.xlsx    # 表定义
│   ├── __beans__.xlsx     # Bean 定义
│   ├── __enums__.xlsx     # 枚举定义
│   ├── GlobalConfig.xlsx  # 全局配置（纵表）
│   ├── Item.xlsx          # 道具配置
│   └── Shop.xlsx          # 商店配置（5个 Sheet，多态）
├── defines/               # 自定义类型定义
│   └── config.xml         # DateTime 等自定义类型
├── docs/                  # 文档
│   └── DateTime配置说明.md
├── output/                # 生成的输出文件
│   ├── json/             # JSON 配置文件
│   │   ├── client/       # 客户端配置
│   │   └── server/       # 服务端配置
│   └── code/             # 生成的代码
│       ├── csharp/       # C# 代码
│       └── go/           # Go 代码
├── luban.conf            # Luban 配置文件
└── generate_config.sh    # 配置生成脚本
```

## 快速开始

### 1. 生成配置

```bash
cd /Volumes/work/code/golang/xDooria/xDooria-config
./generate_config.sh
```

生成内容：
- **JSON 配置**：`output/json/client/` 和 `output/json/server/`
- **C# 代码**：`output/code/csharp/`
- **Go 代码**：`output/code/go/`（模块名：`xdooria/cfg`）

### 2. 使用生成的 Go 代码

```go
import "xdooria/cfg"

// 加载配置
tables, err := cfg.NewTables(func(file string) ([]byte, error) {
    return os.ReadFile("output/json/client/" + file + ".json")
})

// 读取全局配置
globalConfig := tables.TbGlobalConfig.Data
maxMembers := globalConfig.TeamMaxMembers  // 5

// 读取道具
item := tables.TbItem.Get(1001).(*cfg.Item)
fmt.Println(item.Name)  // "生命药水(小)"

// 读取商店道具（多态）
shopItem := tables.TbShopItem.Get(41)
if limitedItem, ok := shopItem.(*cfg.ShopItemTimeLimited); ok {
    // 检查是否在活动时间内
    now := time.Now().Unix()
    if now >= limitedItem.StartTime && now <= limitedItem.EndTime {
        fmt.Println("限时商品正在出售")
    }
}
```

## 核心特性

### 1. 客户端/服务端分组

使用 `c`、`s`、`e` 标记控制字段在不同目标的可见性：

- `c`：客户端可见
- `s`：服务端可见
- `e`：编辑器可见（默认不导出）
- `c;s`：客户端和服务端都可见

示例：`Item.can_drop` 字段仅标记为 `s`，只在服务端配置中出现。

### 2. 多态继承

商店配置使用多态继承避免字段冗余：

```
ShopItemBase（基类）
  ├── ShopItemNormal（普通商店）
  ├── ShopItemMystery（神秘商店，额外字段：weight）
  ├── ShopItemGuild（公会商店，额外字段：guild_level_require, guild_contribution_min）
  ├── ShopItemAlliance（联盟商店，额外字段：alliance_level_require, alliance_contribution_min）
  └── ShopItemTimeLimited（限时商店，额外字段：start_time, end_time）
```

在 `Shop.xlsx` 中使用 5 个 Sheet，每个 Sheet 对应一个子类型，通过 `__type__` 字段标识具体类型。

### 3. DateTime 类型支持

支持可读的日期时间格式，自动转换为 Unix 时间戳：

**Excel 中配置：**
```
start_time: "2025-01-28 00:00:00"
end_time: "2025-02-04 00:00:00"
```

**生成的 JSON：**
```json
{
  "start_time": 1737993600,
  "end_time": 1738598400
}
```

**Go 代码中：**
```go
type ShopItemTimeLimited struct {
    StartTime int64  // Unix 时间戳
    EndTime   int64  // Unix 时间戳
}
```

详见：[DateTime 配置说明](docs/DateTime配置说明.md)

### 4. 纵表（Singleton）配置

`GlobalConfig` 使用纵表模式（`mode=one`），每个字段占一行，适合全局单例配置。

## 配置表说明

### GlobalConfig（全局配置）

| 字段 | 类型 | 说明 |
|------|------|------|
| team_max_members | int | 组队人数上限 |
| team_invite_max_count | int | 同时邀请组队人数上限 |
| team_invite_expire_time | int | 邀请组队过期时间（秒） |
| enable_cross_server_team | bool | 是否开启跨服组队 |

### Item（道具）

包含 25 个字段，涵盖道具的各种属性：
- 基础信息：id, name, type, rarity, quality
- 堆叠与交易：max_stack, can_trade, can_sell, bind_type
- 使用限制：use_level, use_vocation
- 过期机制：expire_type, expire_time
- 技能与标签：use_skill_ids, tags
- 客户端展示：icon, model, description, sort_order

### ShopItem（商店道具）

基类字段（13个）：
- id, shop_id, item_id
- currency_type, price, discount
- stock_type, stock_limit
- unlock_level, position
- is_hot, is_new, is_recommend

子类特有字段：
- **ShopItemMystery**：weight（权重）
- **ShopItemGuild**：guild_level_require, guild_contribution_min
- **ShopItemAlliance**：alliance_level_require, alliance_contribution_min
- **ShopItemTimeLimited**：start_time, end_time（datetime 类型）

## 枚举类型

| 枚举 | 说明 | 值 |
|------|------|---|
| ShopType | 商店类型 | Mystery(1), TimeLimited(2), Guild(3), Alliance(4), Item(5) |
| ItemType | 道具类型 | Consumable(1), Equipment(2), Currency(3), Material(7), GiftPack(6), QuestItem(8) |
| Rarity | 稀有度 | Common(1), Uncommon(2), Rare(3), Epic(4), Legendary(5), Mythic(6) |
| BindType | 绑定类型 | None(0), PickupBind(1), EquipBind(2) |
| ExpireType | 过期类型 | Permanent(0), Duration(1), FixedDate(2) |
| CurrencyType | 货币类型 | Coin(1), Diamond(2), GuildCoin(3), AllianceCoin(4), HonorPoint(5) |
| StockType | 库存类型 | Unlimited(0), Daily(1), Weekly(2), Monthly(3), Lifetime(4) |
| RefreshType | 刷新类型 | Never(0), Daily(1), Weekly(2), Monthly(3) |

## 修改配置流程

1. **修改 Excel 文件**（`datas/` 目录下的 `.xlsx` 文件）
2. **运行生成脚本**：`./generate_config.sh`
3. **验证生成结果**：检查 `output/` 目录
4. **集成到项目**：将生成的代码和 JSON 复制到对应项目

## 注意事项

- ✅ Excel 数据文件只需 `##` 行（字段名行），不需要 `##type` 行
- ✅ 所有类型定义在 `__beans__.xlsx` 中统一管理
- ✅ list 类型必须指定分隔符，如 `(list#sep=|),int`
- ✅ datetime 类型自动转换为 Unix 时间戳（int64）
- ✅ 多态表必须有 `__type__` 列标识具体类型
- ✅ `read_schema_from_file=False` 表示从 `__beans__.xlsx` 读取定义
- ✅ 纵表（mode=one）的 bean 定义必须在 `__beans__.xlsx` 中

## 技术栈

- **Luban**: 4.5.0
- **目标语言**: C#, Go
- **数据格式**: JSON
- **配置格式**: Excel (.xlsx)

## 相关文档

- [Luban 官方文档](https://luban.doc.code-philosophy.com/)
- [DateTime 配置说明](docs/DateTime配置说明.md)
- [复合类型配置说明](docs/复合类型配置说明.md) - List/Map/Set 详细用法

## 常见问题

### Q1: Excel 文件中需要配置 `##type` 行吗？

**不需要！** 

当 `__tables__.xlsx` 中设置 `read_schema_from_file=False` 时（这是我们项目的配置）：

- ✅ Bean 定义完全在 `__beans__.xlsx` 中维护
- ✅ Excel 数据文件只需要两行头部：
  - Row 1: `##` + 字段名
  - Row 2: `##` + 中文说明（可选）
- ❌ **不需要** `##type` 行

**优点：**
- 单一数据源，类型定义在 `__beans__.xlsx` 中集中管理
- Excel 文件更简洁，策划只需关注数据本身
- 修改字段类型只需改一处（`__beans__.xlsx`）

**示例对比：**

```
# ❌ 旧方式（冗余，不推荐）
Row 1: ##  | id   | name   | type
Row 2: ##type | int  | string | ItemType
Row 3: ##  | ID   | 名称   | 类型
Row 4:     | 1001 | 药水   | Consumable

# ✅ 新方式（推荐）
Row 1: ##  | id   | name | type
Row 2: ##  | ID   | 名称 | 类型
Row 3:     | 1001 | 药水 | Consumable
```

### Q2: 什么时候需要 `read_schema_from_file=True`？

仅在以下场景考虑：
- Excel 文件需要独立使用，不依赖 `__beans__.xlsx`
- 快速原型开发，不想先定义 Bean
- 每个 Excel 文件由不同团队维护

**我们项目不使用这种方式。**

### Q3: GlobalConfig 为什么是纵表格式？

纵表（mode=one）适合全局单例配置：
- 每个配置项占一行，便于阅读
- 适合配置项数量较多的场景
- 代码中直接访问对象属性，不需要查表

### Q4: 如何添加新的配置表？

1. 在 `__enums__.xlsx` 中添加需要的枚举（如果有）
2. 在 `__beans__.xlsx` 中定义 Bean 结构和字段
3. 在 `__tables__.xlsx` 中添加表定义
4. 在 `datas/` 创建对应的 Excel 数据文件
5. 运行 `./generate_config.sh` 生成

### Q5: 如何修改现有字段类型？

只需修改 `__beans__.xlsx` 中对应字段的 type 列，然后重新生成即可。
