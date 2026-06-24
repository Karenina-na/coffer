package com.coffer.coffer

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth 的 Android 实现走 androidx BiometricPrompt，宿主 Activity 必须是
// FragmentActivity 的子类；继承 FlutterActivity 会导致 authenticate() 直接抛
// `no_fragment_activity` 异常，表现为生物识别弹窗无法成功，用户看到反复提示。
class MainActivity : FlutterFragmentActivity()
