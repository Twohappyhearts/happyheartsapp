// Web implementation of the SoundCloud audio player — web platform only.
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

Object? createSoundCloudController(
  String trackUrl, {
  void Function(String state)? onState, // not tracked on web
}) => null;

Widget buildSoundCloudPlayer(String trackUrl, Object? mobileController) {
  final src = Uri.https('w.soundcloud.com', '/player/', {
    'url': trackUrl,
    'color': '#3b82f6',
    'auto_play': 'false',
    'hide_related': 'true',
    'show_comments': 'false',
    'show_reposts': 'false',
    'show_teaser': 'false',
    'visual': 'false',
  }).toString();
  final viewType = 'soundcloud-iframe-${trackUrl.hashCode}';
  try {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (
      int viewId, {
      Object? params,
    }) {
      return web.HTMLIFrameElement()
        ..src = src
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..allow = 'autoplay';
    });
  } catch (_) {
    // Already registered — ignore
  }
  return HtmlElementView(viewType: viewType);
}
