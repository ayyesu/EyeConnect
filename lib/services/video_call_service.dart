import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class VideoCallService {
  late RtcEngine engine;

  Future<void> initializeAgora() async {
    engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(
      appId: 'YOUR_AGORA_APP_ID',
    ));
  }

  void startCall(String channelName) {
    engine.joinChannel(
      token: 'YOUR_AGORA_TOKEN',
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void endCall() {
    engine.leaveChannel();
  }
}
