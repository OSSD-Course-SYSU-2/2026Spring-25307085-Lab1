// 注意：移除了原文件开头的多行版权注释（ArkTS不支持这种格式）
// 使用单行注释替代

import { gamePerformance } from '@kit.GameServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 移除了错误的 Card 导入

// 定义日志类型
type LogType = 'info' | 'success' | 'error' | 'event';

// 定义日志条目接口
interface LogEntry {
  time: string;
  message: string;
  type: 'info' | 'success' | 'error' | 'event';
}

// 成就接口
interface Achievement {
  id: string;
  name: string;
  desc: string;
  unlocked: boolean;
  icon: Resource;
}

@Entry
@Component
struct Index {
  // ===== 原有状态变量 =====
  @State logList: Array<LogEntry> = [];
  @State isInitialized: boolean = false;
  @State isSubscribed: boolean = false;
  @State currentTempLevel: number = -1;

  // ===== 新增游戏化状态变量 =====
  @State currentScore: number = 0;
  @State gameActive: boolean = false;
  @State achievements: Array<Achievement> = [];
  @State challengeTime: number = 60;
  @State graphicsQuality: string = '自动';

  // ===== 原有辅助函数 =====
  addLog(message: string, type: LogType = 'info') {
    const now = new Date();
    const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
    this.logList.unshift({ time: timeStr, message, type });
    if (this.logList.length > 50) this.logList.pop();
  }

  clearLogs() {
    this.logList = [];
    this.addLog('日志已清空', 'info');
  }

  // ===== 原有性能服务函数 =====
  private gamePerformanceInit() {
    if (this.isInitialized) {
      this.addLog('服务已初始化，无需重复操作', 'info');
      return;
    }

    let gamePageInfo: gamePerformance.GamePackageInfo = {
      messageType: 0,
      extra: '',
      appVersion: '1.0',
      bundleName: 'com.xxx.xxx.huawei'
    };

    try {
      this.addLog('正在初始化游戏性能服务...', 'info');
      gamePerformance.init(gamePageInfo).then(() => {
        this.addLog('gamePerformance 初始化成功', 'success');
        this.isInitialized = true;
        this.checkAchievements();
      }).catch((error: BusinessError) => {
        this.addLog(`初始化失败: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
      });
    } catch (err) {
      const error = err as BusinessError;
      this.addLog(`初始化异常: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
    }
  }

  private subscribeDeviceState() {
    if (!this.isInitialized) {
      this.addLog('请先初始化服务', 'error');
      return;
    }

    if (this.isSubscribed) {
      this.addLog('已订阅设备状态，无需重复操作', 'info');
      return;
    }

    try {
      gamePerformance.on('deviceStateChanged', (data: gamePerformance.DeviceInfo) => {
        console.info(`设备温度等级变更为: ${data.tempLevel}`);
        this.currentTempLevel = data.tempLevel;
        let suggestion = this.getGraphicsSuggestion(data.tempLevel);
        this.addLog(`设备温度等级变更为: ${data.tempLevel}，建议画质: ${suggestion}`, 'event');
      });

      this.addLog('订阅设备状态事件成功', 'success');
      this.isSubscribed = true;
    } catch (err) {
      const error = err as BusinessError;
      this.addLog(`订阅失败: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
    }
  }

  private unSubscribeDeviceState() {
    if (!this.isSubscribed) {
      this.addLog('当前未订阅设备状态', 'info');
      return;
    }

    try {
      gamePerformance.off('deviceStateChanged');
      this.addLog('取消订阅设备状态成功', 'success');
      this.isSubscribed = false;
      this.currentTempLevel = -1;
    } catch (err) {
      const error = err as BusinessError;
      this.addLog(`取消订阅失败: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
    }
  }

  private queryDeviceInfo() {
    if (!this.isInitialized) {
      this.addLog('请先初始化服务', 'error');
      return;
    }

    try {
      this.addLog('正在查询设备信息...', 'info');
      let gpuParam: gamePerformance.DeviceInfoParameter = {
        deviceInfoType: gamePerformance.DeviceInfoType.GPU
      };
      let thermalParam: gamePerformance.DeviceInfoParameter = {
        deviceInfoType: gamePerformance.DeviceInfoType.THERMAL
      };
      let gameInfos: Array<gamePerformance.DeviceInfoParameter> = [gpuParam, thermalParam];

      gamePerformance.getDeviceInfoByScope(gameInfos).then((deviceInfo: gamePerformance.DeviceInfo) => {
        console.info(`查询设备信息成功, tempLevel: ${deviceInfo.tempLevel}`);
        this.addLog(`查询设备信息成功，当前温度等级: ${deviceInfo.tempLevel}`, 'success');
        this.currentTempLevel = deviceInfo.tempLevel;
      }).catch((error: BusinessError) => {
        this.addLog(`查询失败: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
      });
    } catch (err) {
      const error = err as BusinessError;
      this.addLog(`查询异常: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
    }
  }

  private updateGameSceneInfo() {
    if (!this.isInitialized) {
      this.addLog('请先初始化服务', 'error');
      return;
    }

    try {
      let gameSceneInfo: gamePerformance.GameSceneInfo = {
        messageType: 2,
        extra: '',
        sceneID: 1111,
        importanceLevel: 1111
      };

      this.addLog('正在更新游戏场景信息...', 'info');
      gamePerformance.updateGameInfo(gameSceneInfo).then(() => {
        this.addLog('更新游戏场景信息成功', 'success');
      }).catch((error: BusinessError) => {
        this.addLog(`更新失败: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
      });
    } catch (err) {
      const error = err as BusinessError;
      this.addLog(`更新异常: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
    }
  }

  private getGraphicsSuggestion(tempLevel: number): string {
    switch (tempLevel) {
      case 0: return '极高画质';
      case 1: return '高画质';
      case 2: return '中等画质';
      case 3: return '低画质';
      default: return '自动画质';
    }
  }

  // ===== 新增游戏化函数 =====
  private startPerformanceChallenge() {
    if (!this.isInitialized || this.gameActive) return;

    this.gameActive = true;
    this.currentScore = 0;
    this.challengeTime = 60;
    this.addLog('性能挑战开始！保持设备低温以获取高分', 'event');

    const timer = setInterval(() => {
      this.challengeTime--;
      if (this.challengeTime <= 0) {
        clearInterval(timer);
        this.endChallenge();
      }
    }, 1000);

    gamePerformance.on('deviceStateChanged', (data: gamePerformance.DeviceInfo) => {
      if (!this.gameActive) return;
      const scoreMultiplier = Math.max(0.5, 1 - data.tempLevel * 0.2);
      this.currentScore += Math.floor(10 * scoreMultiplier);
      this.addLog(`温度等级${data.tempLevel}，得分系数x${scoreMultiplier.toFixed(1)}`, 'info');
    });
  }

  private endChallenge() {
    this.gameActive = false;
    this.addLog(`挑战结束！最终得分：${this.currentScore}`, 'success');
    this.checkAchievements();
  }

  private checkAchievements() {
    this.achievements.forEach((achievement: Achievement) => {
      if (achievement.unlocked) return;

      switch (achievement.id) {
        case 'init_first':
          if (this.isInitialized) {
            achievement.unlocked = true;
            this.addLog(`解锁成就：${achievement.name}`, 'success');
          }
          break;
        case 'cool_master':
          if (this.currentTempLevel <= 1 && this.currentScore > 0) {
            achievement.unlocked = true;
            this.addLog(`解锁成就：${achievement.name}`, 'success');
          }
          break;
      }
    });
  }

  private changeGraphicsQuality(quality: string) {
    this.graphicsQuality = quality;
    this.addLog(`手动切换至${quality}，正在验证性能...`, 'info');

    setTimeout(() => {
      const testResult = this.testGraphicsPerformance(quality);
      this.addLog(`画质${quality}测试结果：${testResult}`, 'event');
    }, 1500);
  }

  private testGraphicsPerformance(quality: string): string {
    const baseFps = 60;
    let fps = baseFps;
    if (quality === '极低') fps = baseFps;
    else if (quality === '低') fps = baseFps - 5;
    else if (quality === '中') fps = baseFps - 15;
    else if (quality === '高') fps = baseFps - 25;
    else if (quality === '极高') fps = baseFps - 40;

    const powerConsumption = (quality === '极高') ? '高' : '中低';
    return `预计帧率${fps}fps，功耗${powerConsumption}`;
  }

  aboutToAppear() {
    this.addLog('应用已启动，请点击"初始化场景感知"开始', 'info');
    this.achievements = [
      {
        id: 'init_first',
        name: '初探者',
        desc: '首次初始化性能服务',
        unlocked: false,
        icon: $r('app.media.app_icon') // 使用默认图标
      },
      {
        id: 'cool_master',
        name: '降温大师',
        desc: '在温度等级≤1时完成挑战',
        unlocked: false,
        icon: $r('app.media.app_icon') // 使用默认图标
      }
    ];
  }

  build() {
    Column() {
      // ===== 原有UI部分 =====
      Text('游戏场景感知演示')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      Row() {
        Text('服务状态: ').fontSize(14)
        Text(this.isInitialized ? '已初始化' : '未初始化')
          .fontSize(14)
          .fontColor(this.isInitialized ? 0xFF00AA00 : 0xFFFF0000)
      }.margin({ bottom: 5 })

      Row() {
        Text('订阅状态: ').fontSize(14)
        Text(this.isSubscribed ? '已订阅' : '未订阅')
          .fontSize(14)
          .fontColor(this.isSubscribed ? 0xFF00AA00 : 0xFFFF0000)
      }.margin({ bottom: 5 })

      Row() {
        Text('当前温度等级: ').fontSize(14)
        Text(this.currentTempLevel >= 0 ? this.currentTempLevel.toString() : '未知')
          .fontSize(14)
          .fontColor(0xFF0000FF)
      }.margin({ bottom: 20 })

      // 功能按钮
      Button('初始化场景感知', { type: ButtonType.Capsule })
        .enabled(!this.isInitialized)
        .onClick(() => this.gamePerformanceInit())
        .margin({ top: 10 })

      Button('订阅设备状态', { type: ButtonType.Capsule })
        .enabled(this.isInitialized && !this.isSubscribed)
        .onClick(() => this.subscribeDeviceState())
        .margin({ top: 10 })

      Button('取消订阅', { type: ButtonType.Capsule })
        .enabled(this.isSubscribed)
        .onClick(() => this.unSubscribeDeviceState())
        .margin({ top: 10 })

      Button('更新游戏场景', { type: ButtonType.Capsule })
        .enabled(this.isInitialized)
        .onClick(() => this.updateGameSceneInfo())
        .margin({ top: 10 })

      Button('查询设备信息', { type: ButtonType.Capsule })
        .enabled(this.isInitialized)
        .onClick(() => this.queryDeviceInfo())
        .margin({ top: 10, bottom: 20 })

      // ===== 新增游戏化UI部分 =====
      if (this.isInitialized) {
        // 性能挑战卡片 - 使用 Column 替代 Card
        Column() {
          Text('🔥 性能生存挑战')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)

          Text(`得分: ${this.currentScore} | 剩余时间: ${this.challengeTime}s`)
            .fontSize(14)
            .margin({ top: 5 })

          Button(this.gameActive ? '挑战中...' : '开始挑战')
            .onClick(() => this.startPerformanceChallenge())
            .enabled(!this.gameActive)
            .margin({ top: 10 })
        }
        .padding(15)
        .backgroundColor(0xFFF5F5F5)
        .borderRadius(10)
        .margin({ top: 20 })
        .width('90%')

        // 成就展示
        Text('🏆 我的成就')
          .fontSize(16)
          .margin({ top: 20 })

        Grid() {
          ForEach(this.achievements, (achievement: Achievement) => {
            GridItem() {
              Column() {
                Image(achievement.icon)
                  .width(40)
                  .height(40)
                  .opacity(achievement.unlocked ? 1 : 0.3)

                Text(achievement.name)
                  .fontSize(12)
                  .margin({ top: 5 })
              }
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .height(120)
        .width('90%')

        // 画质实验室
        Text('🎮 画质实验室')
          .fontSize(16)
          .margin({ top: 20 })

        // 使用 @Builder 装饰的画质按钮组
        this.QualityButtonGroup()
      }

      // 日志区域
      Text('操作日志:')
        .fontSize(16)
        .margin({ top: 20 })

      List() {
        ForEach(this.logList, (item: LogEntry) => {
          ListItem() {
            Row() {
              Text(`[${item.time}]`).fontSize(12).fontColor(0xFF888888).width(70)
              Text(item.message)
                .fontSize(14)
                .layoutWeight(1)
                .fontColor(
                  item.type === 'error' ? 0xFFFF0000 :
                    item.type === 'success' ? 0xFF00AA00 :
                      item.type === 'event' ? 0xFF0000FF : 0xFF000000
                )
            }
            .padding(8)
          }
        })
      }
      .width('90%')
      .height(200)
      .border({ width: 1, color: 0xFFCCCCCC })
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  // 使用 @Builder 装饰的画质按钮组
  @Builder
  private QualityButtonGroup() {
    Row() {
      this.CreateQualityButton('极低')
      this.CreateQualityButton('低')
      this.CreateQualityButton('中')
      this.CreateQualityButton('高')
      this.CreateQualityButton('极高')
    }
    .margin({ top: 10 })
  }

  // 创建画质按钮的 @Builder 方法
  @Builder
  private CreateQualityButton(quality: string) {
    Button(quality)
      .onClick(() => this.changeGraphicsQuality(quality))
      .backgroundColor(this.graphicsQuality === quality ? Color.Blue : 0xFFEEEEEE)
      .fontColor(this.graphicsQuality === quality ? Color.White : Color.Black)
      .margin({ right: 5 })
  }
}