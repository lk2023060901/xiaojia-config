# 配置数据文件说明

本目录包含所有游戏配置的 Excel 数据文件。

## 文件结构

```
datas/
├── __tables__.xlsx    # 表定义
├── __beans__.xlsx     # Bean 结构定义（所有字段类型）
├── __enums__.xlsx     # 枚举定义
├── GlobalConfig.xlsx  # 全局配置（纵表）
├── Item.xlsx          # 道具配置
└── Shop.xlsx          # 商店配置（5个 Sheet）
```

## Excel 文件格式

### 普通表（Item.xlsx、Shop.xlsx）

```
Row 1:  ##  | id   | name | type
Row 2:  ##  | ID   | 名称 | 类型
Row 3:      | 1001 | 药水 | Consumable
```

- Row 1: `##` + 字段名
- Row 2: `##` + 中文说明（可选）
- Row 3+: 数据

**为什么不需要 `##type` 行？**

因为 `__tables__.xlsx` 中配置了 `read_schema_from_file=False`，类型定义统一在 `__beans__.xlsx` 中管理，Excel 只需提供字段名和数据。

### 纵表（GlobalConfig.xlsx）

```
Row 1:  ##column#var | ##type | ## | 
Row 4:  field1       | int    | 说明 | 5
Row 5:  field2       | bool   | 说明 | true
```

每个配置项占一行，适合全局单例配置。

### 多态表（Shop.xlsx）

- 多个 Sheet，每个对应一个子类型
- 必须有 `__type__` 列
- 示例：Sheet "道具商店" → `__type__` = `ShopItemNormal`

## 复合类型填写

### List

**`__beans__.xlsx` 定义：** `(list#sep=|),int`  
**Excel 填写：** `1|2|3`

### Map

**`__beans__.xlsx` 定义：** `map,int,int`  
**Excel 字段名：** `prices#sep=,`（必须加 `#sep`）  
**Excel 填写：** `1,100,2,200`（格式：key,value,key,value）

### 结构体列表

**Defines：** `<bean name="RewardItem" sep=":">`  
**`__beans__.xlsx` 定义：** `(list#sep=;),RewardItem`  
**Excel 填写：** `1001:10;1002:5;2003:1`

详见：[复合类型配置说明](../docs/复合类型配置说明.md)

## 注意事项

- ✅ 字段名必须与 `__beans__.xlsx` 定义一致
- ✅ 枚举值填名称（如 `Consumable`），不填数字
- ✅ bool 填 `true`/`false`（小写）
- ❌ 不要添加 `##type` 行
- ❌ Map 字段名必须加 `#sep=分隔符`

## 修改流程

1. 修改 `.xlsx` 文件
2. 运行 `../generate_config.sh/generate_config.bat`
3. 检查 `../output/` 生成结果
