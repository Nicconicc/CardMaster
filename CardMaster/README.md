# CardMaster 卡牌大师

适用于正式服、无限服及各经典客户端的模块化卡牌视觉增强插件。

## 安装

1. 将安装包中的 `CardMaster`、`CardMasterCollection`、`CardMaster_UuoBros`、`CardMaster_NerfCoop` 四个文件夹一起放入对应客户端的 `Interface/AddOns/`。
2. 首次由旧版升级后完全退出并重启游戏，使客户端发现三个新增模块；这次升级不能只用 `/reload`。
3. 启用四个模块。UuoBros 为第一套，NerfLegacy 为第二套（目录为 `CardMaster_NerfCoop`）。

输入 `/cm` 打开设置，`/cm reset` 恢复全部默认，`/cm welcome` 打开欢迎窗口。
也可以通过小地图按钮或“设置 → 插件 → CardMaster”进入。
由旧名称升级时需要完全退出并重启游戏；更名加载文件后，单独 `/reload` 不会重新发现插件目录。
旧导出字符串仍可导入，新导出字符串以 `CMCFG1:` 开头。

## 功能

- 单张技能、进入战斗、AFK、BOSS、物品掉落、升级、倒计时七类卡牌反馈
- 独立启用、测试、拖拽定位和缩放
- 单张技能卡牌完整入场/停留/出场参数
- 普通战斗与首领战斗触发过滤
- 全局正面/背面卡牌样式
- 中文/英文界面和小地图快捷按钮
- `CardMasterDB` 全局持久化配置
- 两套独立收藏，共用一个已勾选分类抽卡池，不重复获卡，不影响七项动画
- 合格击杀 15%、交付任务 50%、采集及钓鱼 15%、副本及战场完成 100%，每次成功一张
- 收藏存于账户 `SavedVariables/CardMasterCollection.lua`；设置存于 `SavedVariables/CardMaster.lua`
- 分享 WTF 时排除 `CardMasterCollection.lua` 和 `.bak`，可保留主插件设置；恢复默认不清空收藏
- 本地卡名悬浮／点击预览、分通道扫光、Xylophone 音效和可关闭的外部表情播报

## 兼容说明

自动表情、插件通信及部分击杀身份数据受客户端限制，不可用时会提示并保留本地收藏。收藏 BattleTag 暂不可读取或与存档不符时暂停授予，原数据不会清空。同账号不同角色共享，各客户端目录之间不自动同步。

优先使用已注册的 Xylophone 音效；未安装共享媒体时使用随包提供、独立合成的木琴提示音，不依赖 WeakAuras。

更新卡牌目录时需同时维护稳定 ID 映射 `CardIdentity.lua`；改名或分类迁移保留原 ID，移除卡保留历史记录。总数按有效目录计算，不固定为 1339。
