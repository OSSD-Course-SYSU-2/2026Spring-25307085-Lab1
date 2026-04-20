/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { gamePerformance } from '@kit.GameServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
// 定义日志类型
type LogType = 'info' | 'success' | 'error' | 'event';

// 定义日志条目接口
interface LogEntry {
  time: string;
  message: string;
  type: 'info' | 'success' | 'error' | 'event';
}

@Entry
@Component
struct Index {
  // 状态变量：存储所有日志条目
  @State logList: Array<LogEntry> = [];
  // 状态变量：控制按钮状态
  @State isInitialized: boolean = false;
  @State isSubscribed: boolean = false;
  // 状态变量：当前设备温度等级（用于展示）
  @State currentTempLevel: number = -1;

  // 添加日志的辅助函数
  addLog(message: string, type: LogType = 'info') {
    const now = new Date();
    const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;

    // 将新日志添加到数组开头，使最新日志显示在最上方
    this.logList.unshift({
      time: timeStr,
      message: message,
      type: type
    });

    // 限制日志数量，避免内存占用过多
    if (this.logList.length > 50) {
      this.logList.pop();
    }
  }

  // 清空日志
  clearLogs() {
    this.logList = [];
    this.addLog('日志已清空', 'info');
  }

  // 1. 初始化游戏性能服务
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
      }).catch((error: BusinessError) => {
        this.addLog(`初始化失败: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
      });
    } catch (err) {
      const error = err as BusinessError;
      this.addLog(`初始化异常: 错误码 ${error.code}, 信息: ${error.message}`, 'error');
    }
  }

  // 2. 订阅设备状态变化
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

        // 根据温度等级提供建议
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

  // 3. 取消订阅设备状态
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

  // 4. 查询设备信息
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

  // 5. 更新游戏场景信息
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

  // 根据温度等级获取画质建议（辅助函数）
  private getGraphicsSuggestion(tempLevel: number): string {
    switch (tempLevel) {
      case 0:
        return '极高画质';
      case 1:
        return '高画质';
      case 2:
        return '中等画质';
      case 3:
        return '低画质';
      default:
        return '自动画质';
    }
  }

  aboutToAppear() {
    this.addLog('应用已启动，请点击"初始化场景感知"开始', 'info');
  }

  build() {
    Column() {
      // 标题区域
      Text('游戏场景感知演示')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      // 状态显示区域
      Row() {
        Text('服务状态: ')
          .fontSize(14)
        Text(this.isInitialized ? '已初始化' : '未初始化')
          .fontSize(14)
          .fontColor(this.isInitialized ? 0xFF00AA00 : 0xFFFF0000)
          .margin({ left: 5 })
      }
      .margin({ bottom: 5 })

      Row() {
        Text('订阅状态: ')
          .fontSize(14)
        Text(this.isSubscribed ? '已订阅' : '未订阅')
          .fontSize(14)
          .fontColor(this.isSubscribed ? 0xFF00AA00 : 0xFFFF0000)
          .margin({ left: 5 })
      }
      .margin({ bottom: 5 })

      Row() {
        Text('当前温度等级: ')
          .fontSize(14)
        Text(this.currentTempLevel >= 0 ? this.currentTempLevel.toString() : '未知')
          .fontSize(14)
          .fontColor(0xFF0000FF)
          .margin({ left: 5 })
      }
      .margin({ bottom: 20 })

      // 按钮区域
      Button($r('app.string.init'), {
        type: ButtonType.Capsule,
        stateEffect: true
      })
        .fontSize('16fp')
        .stateStyles({
          pressed: { .backgroundColor(Color.Black) },
          normal: { .backgroundColor(this.isInitialized ? 0xFFCCCCCC : Color.Blue) }
        })
        .fontWeight(500)
        .width('80%')
        .height(40)
        .enabled(!this.isInitialized) // 初始化后禁用
        .onClick(() => {
          this.gamePerformanceInit();
        })
        .margin({ top: 10 })

      Button($r('app.string.subscribe'), {
        type: ButtonType.Capsule,
        stateEffect: true
      })
        .fontSize('16fp')
        .stateStyles({
          pressed: { .backgroundColor(Color.Black) },
          normal: { .backgroundColor(this.isSubscribed ? 0xFFCCCCCC : (this.isInitialized ? Color.Blue : 0xFFCCCCCC)) }
        })
        .fontWeight(500)
        .width('80%')
        .height(40)
        .enabled(this.isInitialized && !this.isSubscribed) // 已初始化且未订阅时可用
        .onClick(() => {
          this.subscribeDeviceState();
        })
        .margin({ top: 10 })

      Button($r('app.string.unSubscribe'), {
        type: ButtonType.Capsule,
        stateEffect: true
      })
        .fontSize('16fp')
        .stateStyles({
          pressed: { .backgroundColor(Color.Black) },
          normal: { .backgroundColor(this.isSubscribed ? Color.Blue : 0xFFCCCCCC) }
        })
        .fontWeight(500)
        .width('80%')
        .height(40)
        .enabled(this.isSubscribed) // 已订阅时可用
        .onClick(() => {
          this.unSubscribeDeviceState();
        })
        .margin({ top: 10 })

      Button($r('app.string.update'), {
        type: ButtonType.Capsule,
        stateEffect: true
      })
        .fontSize('16fp')
        .stateStyles({
          pressed: { .backgroundColor(Color.Black) },
          normal: { .backgroundColor(this.isInitialized ? Color.Blue : 0xFFCCCCCC) }
        })
        .fontWeight(500)
        .width('80%')
        .height(40)
        .enabled(this.isInitialized) // 初始化后可用
        .onClick(() => {
          this.updateGameSceneInfo();
        })
        .margin({ top: 10 })

      Button($r('app.string.query'), {
        type: ButtonType.Capsule,
        stateEffect: true
      })
        .fontSize('16fp')
        .stateStyles({
          pressed: { .backgroundColor(Color.Black) },
          normal: { .backgroundColor(this.isInitialized ? Color.Blue : 0xFFCCCCCC) }
        })
        .fontWeight(500)
        .width('80%')
        .height(40)
        .enabled(this.isInitialized) // 初始化后可用
        .onClick(() => {
          this.queryDeviceInfo();
        })
        .margin({ top: 10, bottom: 20 })

      // 清空日志按钮
      Button('清空日志', {
        type: ButtonType.Normal,
        stateEffect: true
      })
        .fontSize('14fp')
        .fontColor(Color.White)
        .backgroundColor(0xFF666666)
        .width('40%')
        .height(30)
        .onClick(() => {
          this.clearLogs();
        })
        .margin({ bottom: 10 })

      // 日志显示区域
      Text('操作日志:')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 5 })
        .width('90%')
        .textAlign(TextAlign.Start)

      List() {
        ForEach(this.logList, (item: LogEntry) => {
          ListItem() {
            Row() {
              // 时间戳
              Text(`[${item.time}]`)
                .fontSize(12)
                .fontColor(0xFF888888)
                .width(70)

              // 日志内容
              Text(item.message)
                .fontSize(14)
                .textAlign(TextAlign.Start)
                .layoutWeight(1)
                .fontColor(
                  item.type === 'error' ? 0xFFFF0000 :
                    item.type === 'success' ? 0xFF00AA00 :
                      item.type === 'event' ? 0xFF0000FF :
                        0xFF000000
                )
            }
            .width('100%')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          }
        }, (item: LogEntry) => `${item.time}-${item.message}`)
      }
      .width('90%')
      .height(200)
      .border({ width: 1, color: 0xFFCCCCCC })
      .padding(5)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}