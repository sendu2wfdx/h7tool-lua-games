# H7-TOOL Lua 像素游戏合集

给安富莱 [H7-TOOL](https://forum.anfulai.cn/forum.php?mod=forumdisplay&fid=61&filter=typeid&typeid=370) 做的一组竖屏像素游戏。全部使用板端 Lua 编写，适配 240 × 320 LCD 和机身五键，复制到 EMMC 后即可脱机运行。

- 8 个可玩游戏，统一的深蓝像素风界面
- 统一的暂停、结算和过关横幅
- 针对上、下按键长按连发，以及 OK / 电源键的软件长按做了适配
- 俄罗斯方块和贪吃蛇内置逻辑自测

## 游戏画廊

以下画面均由 H7-TOOL 实机帧缓冲直接截取。

| 俄罗斯方块 | 贪吃蛇 |
|:---:|:---:|
| <img src="screenshots/tetris-play.png" width="240" alt="俄罗斯方块游戏画面"> | <img src="screenshots/snake-play.png" width="240" alt="贪吃蛇游戏画面"> |

| 打砖块 | 小蜜蜂 |
|:---:|:---:|
| <img src="screenshots/breakout-play.png" width="240" alt="打砖块游戏画面"> | <img src="screenshots/invaders-play.png" width="240" alt="小蜜蜂游戏画面"> |

| 像素小鸟 | 2048 |
|:---:|:---:|
| <img src="screenshots/flappy-play.png" width="240" alt="像素小鸟游戏画面"> | <img src="screenshots/2048-play.png" width="240" alt="2048游戏画面"> |

| 推箱子 | 炸弹人 |
|:---:|:---:|
| <img src="screenshots/sokoban-play.png" width="240" alt="推箱子游戏画面"> | <img src="screenshots/bomber-play.png" width="240" alt="炸弹人游戏画面"> |

<details>
<summary>查看结算画面</summary>

| 俄罗斯方块 | 贪吃蛇 |
|:---:|:---:|
| <img src="screenshots/tetris-over.png" width="240" alt="俄罗斯方块结算画面"> | <img src="screenshots/snake-over.png" width="240" alt="贪吃蛇结算画面"> |

</details>

## 游戏与操作

机身按键布局：

```text
上       OK
下       C    电源
```

| 文件 | 游戏 | 操作 |
|---|---|---|
| [`tetris.lua`](tetris.lua) | 俄罗斯方块 | 上左移，OK 右移，下落底，C 旋转，电源暂停 |
| [`snake.lua`](snake.lua) | 贪吃蛇 | 上左转，OK 右转，下切换加速，C 切换穿墙，电源暂停 |
| [`breakout.lua`](breakout.lua) | 打砖块 | 上左移，OK 右移，下发球，电源暂停 |
| [`invaders.lua`](invaders.lua) | 小蜜蜂 | 上左移，OK 右移，下开火，电源暂停 |
| [`flappy.lua`](flappy.lua) | 像素小鸟 | 上或 OK 跳跃，电源暂停 |
| [`game2048.lua`](game2048.lua) | 2048 | 上/下移动，C 向左，电源向右，OK 重开 |
| [`sokoban.lua`](sokoban.lua) | 推箱子 | 上/下移动，C 向左，电源向右，OK 撤销，长按 OK 重开 |
| [`bomber.lua`](bomber.lua) | 炸弹人 | 上/下移动，C 向左，电源向右，OK 放炸弹 |

所有游戏均可**长按 C 退出**。这是固件提供的“用户中止”行为，不由游戏脚本自行实现。

## 安装

把需要的 `.lua` 文件复制到 H7-TOOL EMMC：

```text
0:/H7-TOOL/Lua/My/
```

可以使用 H7-TOOL 的 U 盘模式直接复制，也可以通过 PC 软件或 HID 文件接口在线传输。建议使用便于识别的中文文件名，例如：

```text
俄罗斯方块.lua  贪吃蛇.lua  打砖块.lua  小蜜蜂.lua
像素小鸟.lua    2048.lua    推箱子.lua  炸弹人.lua
```

然后在设备上打开：

```text
工具菜单 → Lua 脚本 → My → 选择游戏
```

> 必须从设备菜单启动正式游戏。PC 端临时执行 Lua 时，固件不会按菜单脚本的方式处理 `--GUIMODE=1`，按键可能直接中止脚本。

## 游戏说明

### 俄罗斯方块

- 10 × 20 棋盘、下一个方块预览、得分/行数/等级
- 使用 7-bag 随机算法，避免每次启动出现固定方块顺序
- 随等级提升自动加速，等级数字闪烁提示，不遮挡游戏画面
- 17 项逻辑自测，覆盖旋转、碰撞和消行

### 贪吃蛇

- 使用相对转向，连续按键也不会直接 180° 掉头
- 加速可随时开关，C 键切换穿墙，电源键暂停
- 分数越高速度越快，并设有合理上限
- 27 项逻辑自测

### 打砖块 / 小蜜蜂 / 像素小鸟

- 打砖块支持多关卡、生命和清场横幅
- 小蜜蜂包含敌群移动、射击、敌方子弹和生命
- 像素小鸟使用重新绘制的像素鸟，管道离屏后立即回收，避免边缘卡顿

### 2048 / 推箱子 / 炸弹人

- 2048 显示当前分数与最高方块，并使用统一的结束横幅
- 推箱子内置 5 个递进关卡，支持撤销与长按 OK 重开
- 炸弹人包含随机可破坏木箱、连锁爆炸、敌人、得分与连续关卡

## 按键事件码

下表来自 APP V2.33 实机测试。按键号码并非连续排列，编写新游戏时不要根据键序号推算事件码。

| 键 | 按下 | 短按松开 | 长按 | 长按连发 | 长按后松开 |
|---|---:|---:|---:|---:|---:|
| 上 | 1 | 2 | 3 | 5 | 4 |
| 下 | 8 | 9 | 10 | 12 | 11 |
| OK | 15 | 100 | 17 | 19（实测不连续产生） | 18 |
| C | 22 | 101 | 24 | 26 | 25 |
| 电源 | 29 | 30 | 31 | — | 32 |

实现时需要注意：

- 不要同时把“按下”和“松开”都当作单击，否则一次按键会移动两次。
- 上、下适合使用固件长按连发；OK 和电源需要由脚本计时实现连续动作或长按语义。
- 长按 C 会被固件截获并退出脚本。

## Lua GUI 开发经验

### `lcd_fill_rect` 参数顺序

```lua
lcd_fill_rect(x, y, height, width, color)
```

这里是**高度在前、宽度在后**，并且高度和宽度的合法范围是 1～240。参数写反或越界可能破坏显存，严重时需要重启工具。

### GUI 标记必须位于第一行

```lua
--GUIMODE=1
```

固件只检查它直接加载的脚本。A 脚本通过 `dofile` 运行 B 脚本时，B 文件第一行的标记不会替代 A 的启动模式。

### 使用整屏重绘

这组游戏采用每帧 `lcd_clr`、完整重画、最后调用一次 `lcd_refresh()` 的方式。H7-TOOL 上局部刷新容易留下脏画面，而 240 × 320 的整屏像素游戏仍能保持足够流畅。

### 自测钩子

俄罗斯方块和贪吃蛇支持只运行逻辑测试、不进入游戏循环：

```lua
_G.H7_TETRIS_TEST = true
dofile("tetris.lua")

_G.H7_SNAKE_TEST = true
dofile("snake.lua")
```

测试结果通过 `print` 输出，适合在改动旋转、碰撞、消行或移动逻辑后先做板端回归。

## 已知限制

- 所有游戏按竖屏 240 × 320 设计。Lua 侧没有读取当前屏幕方向的接口。
- 字库中的部分符号不可用；需要的三角形等图案由矩形或线段绘制。
- `os.remove` / `os.rename` 在当前固件中不可用，`f_dir()` 也不适合在游戏脚本中调用。

## 许可

MIT License，详见 [LICENSE](LICENSE)。
