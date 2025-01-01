Android Desktop Mode

## 1. 概述

从Android 10开始，Android系统内置了“桌面模式”。该模式下，App可以自由拖动显示位置，并调整窗口大小（跟PC操作系统一样）。

有趣的是，“开发者选项”里开启了“模拟辅助显示设备”，就可以启用桌面模式，而且基本不影响手机正常显示模式。可以认为同一个Android手机上同时运行“手机模式”和“桌面模式”，App能在这两个模式之间显示。

最后，利用`scrcpy`把“模拟辅助显示设备”投屏到PC端，就可以使用大屏幕显示“桌面模式”，并且利用鼠标键盘进行输入。

据说手机直连显示器（需要手机直接输出HDMI功能），或者无线连接Miracast，都可以显示“桌面模式”。但是手上没有相关设备，不能验证。

## 2. 部署配置

### 2.1. PC端软件

- adb
  - https://developer.android.com/tools/releases/platform-tools?hl=zh-cn
  - 下载对应操作系统的版本即可。
  - Debian/Ubuntu可以使用`sudo apt install adb`进行安装。
- scrcpy
  - https://github.com/Genymobile/scrcpy
  - 当前最新版v2.4。
  - Release里只提供Windows的预编译版，其它操作系统需要自己编译。Debian/Ubuntu上编译还算容易。

### 2.2. Android必要配置

- 启用“开发者模式”。
- 进入“设置” -> “系统” -> “开发者选项”，勾选“启用可自由调整的窗口”、“强制使用桌面模式”。
  - 其中“强制使用桌面模式”，就是“模拟辅助显示设备”启用桌面模式。

### 2.3. Android端App

#### 2.3.1. 任务栏

建议安装`Taskbar`，用于启动和切换App，实现类似桌面操作系统的任务栏功能。

- F-Droid链接：https://f-droid.org/packages/com.farmerbb.taskbar/
- 项目源码：https://github.com/farmerbb/Taskbar

按以下设置，实现打开桌面模式后，自动显示`Taskbar`，并且不影响手机模式的显示和使用。

- 在“桌面模式” -> “设置 任务栏 为默认主屏幕应用”，“默认主屏幕应用”选`Taskbar`。
- 在“桌面模式” -> “首要启动器”，选当前使用的Launcher。

已知问题：

- 设置`Taskbar`为“默认主屏幕应用”，浏览器不能在Launcher创建网站的快捷方式。需要把使用的Launcher设为“默认主屏幕应用”才可操作。

可替代方案：[Smart Dock](https://f-droid.org/packages/cu.axel.smartdock/)

#### 2.3.2 输入法

`Fcitx5-Android`能识别当前模式并自适应显示。在“桌面模式”中，它能自动隐藏虚拟键盘、悬浮显示候选词、可通过数字键选词等，实现类似PC端输入法的体验。

- F-Droid链接：https://f-droid.org/packages/org.fcitx.fcitx5.android/
- 项目源码：https://github.com/fcitx5-android/fcitx5-android

可替代方案：[GBoard](https://play.google.com/store/apps/details?id=com.google.android.inputmethod.latin)


### 2.4. 连接方式

- 建议使用有线连接。利用数据线，把Android端连上PC端。
- 需要无线连接的话，Android端开启“无线调试模式”，PC端与Andoid端处于同一局域网即可。脚本支持无线配对功能。

## 3. 脚本说明

这里只实现了Linux（使用Bash）和Windows（使用CMD）的脚本。由于没有Mac设备，所以没有实现Mac的脚本。

### 3.1 运行

在PC端运行脚本：

- 直接运行。默认取已连接的第一个Android设备，开启并连接该设备的“桌面模式”。
- 脚本的第一个参数，可以填设备序列号或者无线调试的IP和端口，用于指定要连接的Android设备。
- 检测到没有连接Android设备时，会提示进行配对。

### 3.2 相关说明

脚本的内部变量说明：

- `PHONE_NAME`设置手机名称，作为投屏窗口的标题。
- `CMD_ADB`设置`adb`命令所在位置。
- `ADB_SERIAL`设置设备序列号，多设备时指定连接的设备。连接无线adb时，可设置`IP:端口`。脚本第一个参数传入后会更新此变量。
- `CMD_SCRCPY`设置`scrcpy`命令所在位置。
- `DISPLAY_W`设置`scrcpy`窗口的宽度，单位像素。
- `DISPLAY_H`设置`scrcpy`窗口的高度，单位像素。
- `DISPLAY_DPI`设置`scrcpy`窗口内容的DPI。
- `DISPLAY_ID`是“模拟辅助显示设备”的“display-id”，用于`scrcpy`投屏。由于`scrcpy`已实现自动创建“模拟辅助显示设备”，此变量暂时没用。


