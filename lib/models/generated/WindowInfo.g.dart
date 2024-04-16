// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../WindowInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WindowInfoImpl _$$WindowInfoImplFromJson(Map<String, dynamic> json) =>
    _$WindowInfoImpl(
      name: json['name'] as String? ?? "Unknown",
      processId: json['processId'] as int,
      windowNumber: json['windowNumber'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      sharingState: json['sharingState'] as int,
      layer: json['layer'] as int,
      alpha: (json['alpha'] as num).toDouble(),
      bundleIdentifier: json['bundleIdentifier'] as String?,
      bundleURL: json['bundleURL'] as String?,
      onScreen: json['onScreen'] as bool?,
      hidden: json['hidden'] as bool?,
      active: json['active'] as bool?,
      fullScreen: json['fullScreen'] as bool? ?? false,
    );

Map<String, dynamic> _$$WindowInfoImplToJson(_$WindowInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'processId': instance.processId,
      'windowNumber': instance.windowNumber,
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'sharingState': instance.sharingState,
      'layer': instance.layer,
      'alpha': instance.alpha,
      'bundleIdentifier': instance.bundleIdentifier,
      'bundleURL': instance.bundleURL,
      'onScreen': instance.onScreen,
      'hidden': instance.hidden,
      'active': instance.active,
      'fullScreen': instance.fullScreen,
    };
