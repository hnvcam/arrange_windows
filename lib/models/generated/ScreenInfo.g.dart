// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../ScreenInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScreenInfoImpl _$$ScreenInfoImplFromJson(Map<String, dynamic> json) =>
    _$ScreenInfoImpl(
      name: json['name'] as String? ?? "Unknown",
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      visibleX: (json['visibleX'] as num).toDouble(),
      visibleY: (json['visibleY'] as num).toDouble(),
      visibleWidth: (json['visibleWidth'] as num).toDouble(),
      visibleHeight: (json['visibleHeight'] as num).toDouble(),
      safeTop: (json['safeTop'] as num).toDouble(),
      safeLeft: (json['safeLeft'] as num).toDouble(),
      safeBottom: (json['safeBottom'] as num).toDouble(),
      safeRight: (json['safeRight'] as num).toDouble(),
    );

Map<String, dynamic> _$$ScreenInfoImplToJson(_$ScreenInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'width': instance.width,
      'height': instance.height,
      'x': instance.x,
      'y': instance.y,
      'visibleX': instance.visibleX,
      'visibleY': instance.visibleY,
      'visibleWidth': instance.visibleWidth,
      'visibleHeight': instance.visibleHeight,
      'safeTop': instance.safeTop,
      'safeLeft': instance.safeLeft,
      'safeBottom': instance.safeBottom,
      'safeRight': instance.safeRight,
    };
