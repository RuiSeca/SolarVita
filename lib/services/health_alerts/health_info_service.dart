import 'package:flutter/material.dart';

/// Service providing comprehensive health and environmental information
/// for educational purposes in the pulse modal
class HealthInfoService {
  static HealthInfoService? _instance;
  static HealthInfoService get instance => _instance ??= HealthInfoService._();
  HealthInfoService._();

  /// UV Index information with color-coded severity levels
  Map<String, dynamic> getUVIndexInfo(double? uvIndex) {
    if (uvIndex == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'UV index data unavailable',
        'recommendations': ['Check local weather services for UV information'],
        'icon': Icons.help_outline,
      };
    }

    if (uvIndex <= 2) {
      return {
        'level': 'Low (0-2)',
        'color': Colors.green,
        'description': 'Minimal sun protection required for normal activity.',
        'recommendations': [
          'Wear sunglasses on bright days',
          'If outside for more than one hour, cover up and use sunscreen',
          'Reflection off snow can nearly double UV strength - wear sunglasses and apply sunscreen on your face',
          'Safe for normal outdoor activities'
        ],
        'icon': Icons.wb_sunny_outlined,
        'riskLevel': 'Minimal Risk',
      };
    } else if (uvIndex < 6) {
      return {
        'level': 'Moderate (3-5)',
        'color': Colors.yellow[700],
        'description': 'Take precautions by covering up, and wearing a hat, sunglasses and sunscreen.',
        'recommendations': [
          'Cover up and wear a hat, sunglasses and sunscreen',
          'Take precautions if you will be outside for 30 minutes or more',
          'Look for shade near midday when the sun is strongest',
          'Moderate risk of harm from unprotected sun exposure'
        ],
        'icon': Icons.wb_sunny,
        'riskLevel': 'Moderate Risk',
      };
    } else if (uvIndex <= 7) {
      return {
        'level': 'High (6-7)',
        'color': Colors.orange,
        'description': 'Protection required - UV damages the skin and can cause sunburn.',
        'recommendations': [
          'Reduce time in the sun between 11 a.m. and 3 p.m.',
          'Take full precaution by seeking shade',
          'Cover up exposed skin, wear a hat and sunglasses',
          'Apply broad-spectrum SPF 30+ sunscreen every 2 hours',
          'High risk of harm from unprotected sun exposure'
        ],
        'icon': Icons.warning_amber,
        'riskLevel': 'High Risk',
      };
    } else if (uvIndex <= 10) {
      return {
        'level': 'Very High (8-10)',
        'color': Colors.red,
        'description': 'Extra precaution required - unprotected skin will be damaged and can burn quickly.',
        'recommendations': [
          'Avoid the sun between 11 a.m. and 3 p.m.',
          'Seek shade, cover up, and wear a hat and sunglasses',
          'Apply broad-spectrum SPF 30+ sunscreen generously every 2 hours',
          'Very high risk of harm from unprotected sun exposure',
          'Skin can burn in 15-25 minutes'
        ],
        'icon': Icons.error_outline,
        'riskLevel': 'Very High Risk',
      };
    } else {
      return {
        'level': 'Extreme (11+)',
        'color': Colors.purple,
        'description': 'Take full precaution. Unprotected skin will be damaged and can burn in minutes.',
        'recommendations': [
          'Avoid the sun between 11 a.m. and 3 p.m.',
          'Cover up completely, wear a hat and sunglasses',
          'Apply broad-spectrum SPF 30+ sunscreen generously every 2 hours',
          'White sand and other bright surfaces reflect UV and increase exposure',
          'Skin can burn in less than 15 minutes',
          'Extreme risk - take all precautions'
        ],
        'icon': Icons.dangerous,
        'riskLevel': 'Extreme Risk',
      };
    }
  }

  /// Temperature information with health guidelines
  Map<String, dynamic> getTemperatureInfo(double? temperature) {
    if (temperature == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'Temperature data unavailable',
        'recommendations': ['Check local weather services'],
        'icon': Icons.device_thermostat,
      };
    }

    if (temperature < -10) {
      return {
        'level': 'Extremely Cold',
        'color': Colors.blue[900],
        'description': 'Dangerous cold conditions. Risk of frostbite and hypothermia.',
        'recommendations': [
          'Avoid prolonged outdoor exposure',
          'Dress in multiple layers with waterproof outer layer',
          'Cover all exposed skin',
          'Wear insulated boots and gloves',
          'Stay dry and warm',
          'Limit outdoor exercise to short periods'
        ],
        'icon': Icons.ac_unit,
        'riskLevel': 'High Risk',
      };
    } else if (temperature < 0) {
      return {
        'level': 'Very Cold',
        'color': Colors.blue[700],
        'description': 'Freezing temperatures. Risk of frostbite with prolonged exposure.',
        'recommendations': [
          'Dress warmly in layers',
          'Protect extremities with gloves, hat, and warm socks',
          'Limit time outdoors',
          'Stay dry to maintain body heat',
          'Warm up frequently if working outside'
        ],
        'icon': Icons.ac_unit,
        'riskLevel': 'Moderate Risk',
      };
    } else if (temperature < 10) {
      return {
        'level': 'Cold',
        'color': Colors.blue,
        'description': 'Cold weather conditions. Dress appropriately to maintain comfort.',
        'recommendations': [
          'Wear warm clothing and layers',
          'Use gloves and hat for outdoor activities',
          'Stay active to maintain body temperature',
          'Hot beverages can help maintain warmth'
        ],
        'icon': Icons.thermostat,
        'riskLevel': 'Low Risk',
      };
    } else if (temperature < 20) {
      return {
        'level': 'Cool',
        'color': Colors.lightBlue,
        'description': 'Cool and comfortable conditions. Light layers recommended.',
        'recommendations': [
          'Light jacket or sweater recommended',
          'Perfect for most outdoor activities',
          'Comfortable for exercise and walking',
          'May need extra layer for evening activities'
        ],
        'icon': Icons.thermostat,
        'riskLevel': 'No Risk',
      };
    } else if (temperature < 25) {
      return {
        'level': 'Comfortable',
        'color': Colors.green,
        'description': 'Ideal temperature conditions for most activities.',
        'recommendations': [
          'Perfect weather for outdoor activities',
          'Comfortable clothing sufficient',
          'Great for exercise and sports',
          'Enjoy outdoor activities comfortably'
        ],
        'icon': Icons.thermostat,
        'riskLevel': 'No Risk',
      };
    } else if (temperature < 30) {
      return {
        'level': 'Warm',
        'color': Colors.orange[300],
        'description': 'Warm conditions. Stay hydrated and dress appropriately.',
        'recommendations': [
          'Wear light, breathable clothing',
          'Stay hydrated with plenty of water',
          'Take breaks in shade during activities',
          'Good weather for most outdoor activities'
        ],
        'icon': Icons.wb_sunny,
        'riskLevel': 'Low Risk',
      };
    } else if (temperature < 35) {
      return {
        'level': 'Hot',
        'color': Colors.orange,
        'description': 'Hot weather conditions. Take precautions to prevent heat-related illness.',
        'recommendations': [
          'Stay hydrated - drink water regularly',
          'Wear light-colored, loose-fitting clothing',
          'Avoid prolonged sun exposure during peak hours (11 AM - 3 PM)',
          'Take frequent breaks in cool/shaded areas',
          'Monitor for signs of heat exhaustion'
        ],
        'icon': Icons.wb_sunny,
        'riskLevel': 'Moderate Risk',
      };
    } else if (temperature < 40) {
      return {
        'level': 'Very Hot',
        'color': Colors.red,
        'description': 'Dangerous heat conditions. High risk of heat-related illness.',
        'recommendations': [
          'Stay indoors during peak heat if possible',
          'Drink water constantly - don\'t wait until thirsty',
          'Avoid strenuous outdoor activities',
          'Use air conditioning or fans',
          'Wear minimal, light-colored clothing',
          'Never leave anyone in parked vehicles',
          'Watch for heat stroke symptoms'
        ],
        'icon': Icons.warning_amber,
        'riskLevel': 'High Risk',
      };
    } else {
      return {
        'level': 'Extremely Hot',
        'color': Colors.red[900],
        'description': 'Life-threatening heat conditions. Extreme risk of heat stroke.',
        'recommendations': [
          'Stay indoors with air conditioning',
          'Avoid all outdoor activities',
          'Drink water continuously',
          'Seek immediate medical attention for heat-related symptoms',
          'Check on elderly and vulnerable individuals',
          'Never leave anyone or pets in vehicles',
          'Emergency heat protocols in effect'
        ],
        'icon': Icons.dangerous,
        'riskLevel': 'Extreme Risk',
      };
    }
  }

  /// Humidity information with comfort and health guidelines
  Map<String, dynamic> getHumidityInfo(double? humidity) {
    if (humidity == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'Humidity data unavailable',
        'recommendations': ['Check local weather services'],
        'icon': Icons.opacity,
      };
    }

    if (humidity < 30) {
      return {
        'level': 'Very Low (< 30%)',
        'color': Colors.orange,
        'description': 'Dry air conditions. May cause discomfort and health issues.',
        'recommendations': [
          'Use a humidifier indoors if possible',
          'Stay hydrated with plenty of fluids',
          'Use moisturizing lotions for skin',
          'Consider nasal saline rinses',
          'Static electricity may be noticeable',
          'May worsen respiratory conditions'
        ],
        'icon': Icons.water_drop_outlined,
        'riskLevel': 'Discomfort Risk',
      };
    } else if (humidity < 40) {
      return {
        'level': 'Low (30-40%)',
        'color': Colors.yellow[700],
        'description': 'Below optimal humidity levels. Some discomfort possible.',
        'recommendations': [
          'Monitor comfort levels, especially indoors',
          'Stay well hydrated',
          'Use moisturizer for skin and lips',
          'Good for those with mold allergies',
          'May feel cooler than actual temperature'
        ],
        'icon': Icons.water_drop,
        'riskLevel': 'Mild Discomfort',
      };
    } else if (humidity <= 60) {
      return {
        'level': 'Comfortable (40-60%)',
        'color': Colors.green,
        'description': 'Ideal humidity range for human comfort and health.',
        'recommendations': [
          'Perfect conditions for most activities',
          'Comfortable for indoor and outdoor activities',
          'Optimal for respiratory health',
          'Good conditions for exercise',
          'Minimal risk of mold or dryness issues'
        ],
        'icon': Icons.water_drop,
        'riskLevel': 'No Risk',
      };
    } else if (humidity <= 70) {
      return {
        'level': 'Moderately High (60-70%)',
        'color': Colors.blue,
        'description': 'Slightly elevated humidity. May feel warmer than actual temperature.',
        'recommendations': [
          'May feel muggy, especially when combined with heat',
          'Good ventilation helps maintain comfort',
          'Stay hydrated during physical activity',
          'Monitor indoor humidity to prevent mold',
          'Dehumidifier may help indoor comfort'
        ],
        'icon': Icons.opacity,
        'riskLevel': 'Mild Discomfort',
      };
    } else if (humidity <= 80) {
      return {
        'level': 'High (70-80%)',
        'color': Colors.orange,
        'description': 'High humidity conditions. Discomfort and health impacts possible.',
        'recommendations': [
          'Feels much warmer than actual temperature',
          'Reduced effectiveness of sweating for cooling',
          'Take frequent breaks during physical activity',
          'Stay in air-conditioned areas when possible',
          'Increased risk of heat-related illness',
          'Monitor for mold growth indoors'
        ],
        'icon': Icons.opacity,
        'riskLevel': 'Moderate Risk',
      };
    } else {
      return {
        'level': 'Very High (> 80%)',
        'color': Colors.red,
        'description': 'Dangerous humidity levels. High risk of heat-related illness.',
        'recommendations': [
          'Significant increase in apparent temperature',
          'Body cooling through sweating severely impaired',
          'High risk of heat exhaustion and heat stroke',
          'Avoid strenuous outdoor activities',
          'Stay in air-conditioned environments',
          'Drink water constantly',
          'Watch for signs of heat-related illness'
        ],
        'icon': Icons.warning_amber,
        'riskLevel': 'High Risk',
      };
    }
  }

  /// Air Quality Index information with health guidelines
  Map<String, dynamic> getAQIInfo(int? aqi) {
    if (aqi == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'Air quality data unavailable',
        'recommendations': ['Check local air quality monitoring services'],
        'icon': Icons.air,
      };
    }

    if (aqi <= 50) {
      return {
        'level': 'Good (0-50)',
        'color': Colors.green,
        'description': 'Air quality is satisfactory and poses little or no health risk.',
        'recommendations': [
          'Perfect conditions for outdoor activities',
          'No health precautions necessary',
          'Great air quality for exercise',
          'Safe for sensitive individuals',
          'Enjoy outdoor activities freely'
        ],
        'icon': Icons.check_circle,
        'riskLevel': 'No Risk',
      };
    } else if (aqi <= 100) {
      return {
        'level': 'Moderate (51-100)',
        'color': Colors.yellow[700],
        'description': 'Air quality is acceptable. Unusually sensitive people may experience minor symptoms.',
        'recommendations': [
          'Generally safe for outdoor activities',
          'Unusually sensitive people should consider limiting prolonged outdoor exertion',
          'Good conditions for most people',
          'Monitor symptoms if you have respiratory conditions',
          'No significant restrictions needed'
        ],
        'icon': Icons.info_outline,
        'riskLevel': 'Low Risk',
      };
    } else if (aqi <= 150) {
      return {
        'level': 'Unhealthy for Sensitive Groups (101-150)',
        'color': Colors.orange,
        'description': 'Sensitive individuals may experience health effects. General public unlikely to be affected.',
        'recommendations': [
          'People with heart or lung disease, older adults, and children should limit prolonged outdoor exertion',
          'Consider moving activities indoors or rescheduling',
          'Sensitive individuals should avoid outdoor exercise',
          'General public can continue normal activities',
          'Monitor air quality if you have health conditions'
        ],
        'icon': Icons.warning_amber,
        'riskLevel': 'Moderate Risk for Sensitive',
      };
    } else if (aqi <= 200) {
      return {
        'level': 'Unhealthy (151-200)',
        'color': Colors.red,
        'description': 'Everyone may experience health effects. Sensitive groups may experience serious effects.',
        'recommendations': [
          'Everyone should limit outdoor exertion',
          'People with heart or lung disease, older adults, and children should avoid outdoor activities',
          'Consider postponing outdoor activities',
          'Move activities indoors or reschedule',
          'Wear N95 or P100 masks if you must go outside',
          'Keep windows closed'
        ],
        'icon': Icons.error_outline,
        'riskLevel': 'High Risk',
      };
    } else if (aqi <= 300) {
      return {
        'level': 'Very Unhealthy (201-300)',
        'color': Colors.purple,
        'description': 'Health alert. Everyone may experience serious health effects.',
        'recommendations': [
          'Everyone should avoid outdoor exertion',
          'People with heart or lung disease, older adults, and children should remain indoors',
          'Cancel outdoor activities',
          'Stay indoors with windows and doors closed',
          'Use air purifiers if available',
          'Wear N95 or P100 masks if you must go outside',
          'Seek medical attention if experiencing symptoms'
        ],
        'icon': Icons.dangerous,
        'riskLevel': 'Very High Risk',
      };
    } else {
      return {
        'level': 'Hazardous (300+)',
        'color': Colors.red[900],
        'description': 'Emergency conditions. Everyone is likely to be affected by serious health effects.',
        'recommendations': [
          'Stay indoors at all times',
          'Avoid all outdoor activities',
          'Keep windows and doors closed',
          'Use air purifiers and create a clean room if possible',
          'Wear N95 or P100 masks even for short outdoor exposure',
          'Consider evacuation if possible',
          'Seek immediate medical attention for any respiratory symptoms',
          'Emergency health alert in effect'
        ],
        'icon': Icons.dangerous,
        'riskLevel': 'Emergency',
      };
    }
  }

  /// Heart Rate information with health guidelines
  Map<String, dynamic> getHeartRateInfo(int? heartRate, {int age = 30, String gender = 'unknown'}) {
    if (heartRate == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'Heart rate data unavailable',
        'recommendations': ['Connect a fitness tracker or manually check pulse'],
        'icon': Icons.favorite_outline,
      };
    }

    // Calculate target zones based on age
    int maxHR = 220 - age;
    int restingLow = 50;
    int restingHigh = 100;
    int fatBurnLow = (maxHR * 0.5).round();
    int fatBurnHigh = (maxHR * 0.7).round();
    int cardioLow = (maxHR * 0.7).round();
    int cardioHigh = (maxHR * 0.85).round();

    if (heartRate < 40) {
      return {
        'level': 'Very Low (< 40 bpm)',
        'color': Colors.blue,
        'description': 'Unusually low heart rate. May indicate excellent fitness or medical condition.',
        'recommendations': [
          'Consult healthcare provider if experiencing symptoms',
          'May be normal for well-trained athletes',
          'Monitor for dizziness, fatigue, or fainting',
          'Consider medical evaluation if new occurrence',
          'Track patterns and symptoms'
        ],
        'icon': Icons.favorite,
        'riskLevel': 'Monitor',
        'zones': 'Below normal resting range'
      };
    } else if (heartRate <= restingHigh) {
      return {
        'level': 'Resting ($restingLow-$restingHigh bpm)',
        'color': Colors.green,
        'description': 'Normal resting heart rate range. Indicates good cardiovascular health.',
        'recommendations': [
          'Excellent resting heart rate',
          'Indicates good cardiovascular fitness',
          'Continue regular exercise routine',
          'Monitor trends over time',
          'Perfect for recovery and rest periods'
        ],
        'icon': Icons.favorite,
        'riskLevel': 'Normal',
        'zones': 'Resting/Recovery Zone'
      };
    } else if (heartRate <= fatBurnHigh) {
      return {
        'level': 'Fat Burn Zone ($fatBurnLow-$fatBurnHigh bpm)',
        'color': Colors.blue[300],
        'description': 'Light to moderate exercise intensity. Optimal for fat burning and endurance.',
        'recommendations': [
          'Great for steady-state cardio',
          'Optimal for fat burning during exercise',
          'Can maintain this pace for extended periods',
          'Perfect for building aerobic base',
          'Safe for daily exercise'
        ],
        'icon': Icons.local_fire_department,
        'riskLevel': 'Exercise Zone',
        'zones': 'Fat Burning Zone (50-70% max HR)'
      };
    } else if (heartRate <= cardioHigh) {
      return {
        'level': 'Cardio Zone ($cardioLow-$cardioHigh bpm)',
        'color': Colors.orange,
        'description': 'Moderate to vigorous exercise intensity. Excellent for cardiovascular fitness.',
        'recommendations': [
          'Great for improving cardiovascular fitness',
          'Ideal for interval training',
          'Monitor exertion level during exercise',
          'Stay hydrated during workouts',
          'Perfect for fitness improvements'
        ],
        'icon': Icons.directions_run,
        'riskLevel': 'Exercise Zone',
        'zones': 'Aerobic Zone (70-85% max HR)'
      };
    } else if (heartRate <= maxHR) {
      return {
        'level': 'Peak Zone (${cardioHigh + 1}-$maxHR bpm)',
        'color': Colors.red,
        'description': 'High-intensity exercise zone. Should only be maintained for short periods.',
        'recommendations': [
          'High-intensity exercise zone',
          'Should only maintain for short intervals',
          'Excellent for improving VO2 max',
          'Take recovery breaks between efforts',
          'Monitor for signs of overexertion',
          'Stay well hydrated'
        ],
        'icon': Icons.flash_on,
        'riskLevel': 'High Intensity',
        'zones': 'Anaerobic Zone (85-100% max HR)'
      };
    } else {
      return {
        'level': 'Very High (> $maxHR bpm)',
        'color': Colors.red[900],
        'description': 'Extremely high heart rate. May indicate overexertion or medical concern.',
        'recommendations': [
          'Reduce exercise intensity immediately',
          'Take a rest and allow heart rate to decrease',
          'Stay hydrated and cool down',
          'Consider medical evaluation if persistent',
          'Monitor for symptoms like chest pain or dizziness',
          'Consult healthcare provider about exercise limits'
        ],
        'icon': Icons.warning,
        'riskLevel': 'Caution',
        'zones': 'Above maximum predicted heart rate'
      };
    }
  }

  /// Hydration information with health guidelines
  Map<String, dynamic> getHydrationInfo(double? hydrationLevel) {
    if (hydrationLevel == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'Hydration data unavailable',
        'recommendations': ['Track water intake manually or use hydration apps'],
        'icon': Icons.water_drop_outlined,
      };
    }

    double percentage = hydrationLevel * 100;

    if (percentage < 30) {
      return {
        'level': 'Severely Dehydrated (< 30%)',
        'color': Colors.red[900],
        'description': 'Dangerously low hydration levels. Immediate action required.',
        'recommendations': [
          'Drink water immediately - small sips frequently',
          'Add electrolytes to water (salt, sports drinks)',
          'Rest in a cool environment',
          'Seek medical attention if severe symptoms present',
          'Monitor for signs of severe dehydration',
          'Avoid alcohol and caffeine'
        ],
        'icon': Icons.warning,
        'riskLevel': 'Emergency',
      };
    } else if (percentage < 50) {
      return {
        'level': 'Dehydrated (30-50%)',
        'color': Colors.red,
        'description': 'Below optimal hydration levels. Increase fluid intake.',
        'recommendations': [
          'Increase water intake gradually',
          'Drink 8-10 glasses of water today',
          'Include electrolyte-rich foods',
          'Monitor urine color (should be light yellow)',
          'Avoid excessive caffeine and alcohol',
          'Set reminders to drink water regularly'
        ],
        'icon': Icons.water_drop,
        'riskLevel': 'High Priority',
      };
    } else if (percentage < 70) {
      return {
        'level': 'Low Hydration (50-70%)',
        'color': Colors.orange,
        'description': 'Below recommended hydration levels. Focus on fluid intake.',
        'recommendations': [
          'Drink water regularly throughout the day',
          'Aim for 6-8 glasses of water',
          'Include hydrating foods (fruits, vegetables)',
          'Monitor thirst and respond promptly',
          'Increase intake before, during, and after exercise'
        ],
        'icon': Icons.water_drop,
        'riskLevel': 'Moderate Priority',
      };
    } else if (percentage < 85) {
      return {
        'level': 'Good Hydration (70-85%)',
        'color': Colors.blue,
        'description': 'Approaching optimal hydration levels. Continue good habits.',
        'recommendations': [
          'Maintain current water intake',
          'Continue drinking water regularly',
          'Perfect hydration for most activities',
          'Monitor during exercise or hot weather',
          'Keep up the good habits!'
        ],
        'icon': Icons.water_drop,
        'riskLevel': 'Good',
      };
    } else if (percentage <= 100) {
      return {
        'level': 'Excellent Hydration (85-100%)',
        'color': Colors.green,
        'description': 'Optimal hydration levels. Excellent for health and performance.',
        'recommendations': [
          'Perfect hydration levels!',
          'Maintain this excellent hydration',
          'Ideal for exercise and daily activities',
          'Continue your hydration routine',
          'Great for cognitive and physical performance'
        ],
        'icon': Icons.water_drop,
        'riskLevel': 'Optimal',
      };
    } else {
      return {
        'level': 'Over-hydrated (> 100%)',
        'color': Colors.blue[900],
        'description': 'Possible over-hydration. Consider moderating fluid intake.',
        'recommendations': [
          'Consider reducing fluid intake slightly',
          'Ensure electrolyte balance',
          'Monitor for symptoms of water intoxication',
          'Balance water with electrolytes',
          'Consult healthcare provider if concerned'
        ],
        'icon': Icons.water_drop,
        'riskLevel': 'Monitor',
      };
    }
  }

  /// Sleep Quality information with health guidelines
  Map<String, dynamic> getSleepQualityInfo(String sleepQuality) {
    switch (sleepQuality.toLowerCase()) {
      case 'excellent':
        return {
          'level': 'Excellent Sleep',
          'color': Colors.green,
          'description': 'Outstanding sleep quality. You\'re well-rested and ready for the day.',
          'recommendations': [
            'Maintain your excellent sleep routine',
            'Keep consistent sleep and wake times',
            'Your body and mind are well-recovered',
            'Perfect foundation for daily activities',
            'Continue your healthy sleep habits'
          ],
          'icon': Icons.bedtime,
          'riskLevel': 'Optimal',
        };
      case 'good':
        return {
          'level': 'Good Sleep',
          'color': Colors.lightGreen,
          'description': 'Good sleep quality. Minor improvements could enhance rest.',
          'recommendations': [
            'Generally good sleep quality',
            'Consider optimizing sleep environment',
            'Maintain regular sleep schedule',
            'Good foundation for daily performance',
            'Small improvements could boost quality further'
          ],
          'icon': Icons.bedtime,
          'riskLevel': 'Good',
        };
      case 'fair':
        return {
          'level': 'Fair Sleep',
          'color': Colors.yellow[700],
          'description': 'Average sleep quality. Room for improvement in sleep habits.',
          'recommendations': [
            'Focus on improving sleep routine',
            'Ensure 7-9 hours of sleep nightly',
            'Create a relaxing bedtime routine',
            'Limit screen time before bed',
            'Consider sleep environment optimization'
          ],
          'icon': Icons.bedtime_outlined,
          'riskLevel': 'Needs Attention',
        };
      case 'poor':
        return {
          'level': 'Poor Sleep',
          'color': Colors.orange,
          'description': 'Below optimal sleep quality. Significant improvement needed.',
          'recommendations': [
            'Prioritize sleep hygiene improvements',
            'Establish consistent sleep schedule',
            'Create dark, quiet, cool sleep environment',
            'Limit caffeine and alcohol before bed',
            'Consider stress management techniques',
            'May benefit from sleep assessment'
          ],
          'icon': Icons.bedtime_outlined,
          'riskLevel': 'High Priority',
        };
      case 'very poor':
        return {
          'level': 'Very Poor Sleep',
          'color': Colors.red,
          'description': 'Severely compromised sleep quality. Immediate attention needed.',
          'recommendations': [
            'Consult healthcare provider about sleep issues',
            'Implement comprehensive sleep hygiene program',
            'Address potential underlying sleep disorders',
            'Consider sleep study if problems persist',
            'Focus on stress reduction and relaxation',
            'May need professional sleep intervention'
          ],
          'icon': Icons.warning_amber,
          'riskLevel': 'Critical',
        };
      default:
        return {
          'level': 'Unknown Sleep Quality',
          'color': Colors.grey,
          'description': 'Sleep quality data unavailable.',
          'recommendations': [
            'Track sleep quality using sleep apps or devices',
            'Monitor sleep patterns manually',
            'Maintain regular sleep schedule',
            'Focus on good sleep hygiene'
          ],
          'icon': Icons.bedtime_outlined,
          'riskLevel': 'Unknown',
        };
    }
  }

  /// Activity Level information with health guidelines
  Map<String, dynamic> getActivityLevelInfo(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return {
          'level': 'Sedentary',
          'color': Colors.red,
          'description': 'Very low activity level. Health risks associated with prolonged sitting.',
          'recommendations': [
            'Aim to move every 30-60 minutes',
            'Start with 5-10 minute walks',
            'Take stairs when possible',
            'Consider standing desk or walking meetings',
            'Gradually increase daily activity',
            'Set movement reminders throughout day'
          ],
          'icon': Icons.accessible,
          'riskLevel': 'High Risk',
        };
      case 'light':
        return {
          'level': 'Light Activity',
          'color': Colors.orange,
          'description': 'Below recommended activity levels. Increase movement for better health.',
          'recommendations': [
            'Aim for 150 minutes moderate activity weekly',
            'Include daily walks or light exercise',
            'Take active breaks during work',
            'Find enjoyable physical activities',
            'Gradually increase activity duration and intensity'
          ],
          'icon': Icons.directions_walk,
          'riskLevel': 'Moderate Risk',
        };
      case 'moderate':
        return {
          'level': 'Moderate Activity',
          'color': Colors.yellow[700],
          'description': 'Good activity level meeting basic health guidelines.',
          'recommendations': [
            'Maintain current activity level',
            'Consider adding strength training',
            'Include variety in exercise routine',
            'Great foundation for health',
            'Consider increasing intensity for additional benefits'
          ],
          'icon': Icons.directions_bike,
          'riskLevel': 'Good',
        };
      case 'active':
        return {
          'level': 'Active',
          'color': Colors.lightGreen,
          'description': 'Excellent activity level supporting optimal health.',
          'recommendations': [
            'Excellent activity level!',
            'Maintain your active lifestyle',
            'Include both cardio and strength training',
            'Great for overall health and fitness',
            'Continue balancing activity with recovery'
          ],
          'icon': Icons.directions_run,
          'riskLevel': 'Excellent',
        };
      case 'very active':
        return {
          'level': 'Very Active',
          'color': Colors.green,
          'description': 'Outstanding activity level. Optimal for health and fitness.',
          'recommendations': [
            'Outstanding activity level!',
            'Perfect balance of activity for health',
            'Ensure adequate recovery between sessions',
            'Maintain proper nutrition and hydration',
            'Consider variety to prevent overuse injuries'
          ],
          'icon': Icons.fitness_center,
          'riskLevel': 'Optimal',
        };
      default:
        return {
          'level': 'Unknown Activity Level',
          'color': Colors.grey,
          'description': 'Activity level data unavailable.',
          'recommendations': [
            'Track daily activity with fitness apps or devices',
            'Aim for 150 minutes moderate activity weekly',
            'Include both cardio and strength training',
            'Monitor activity patterns'
          ],
          'icon': Icons.help_outline,
          'riskLevel': 'Unknown',
        };
    }
  }

  /// Weather condition information
  Map<String, dynamic> getWeatherConditionInfo(String? condition) {
    if (condition == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'Weather condition data unavailable.',
        'recommendations': ['Check local weather services for current conditions'],
        'icon': Icons.help_outline,
      };
    }

    final conditionLower = condition.toLowerCase();
    
    if (conditionLower.contains('sunny') || conditionLower.contains('clear')) {
      return {
        'level': 'Clear & Sunny',
        'color': Colors.amber,
        'description': 'Clear skies with bright sunshine. Perfect weather for outdoor activities with proper sun protection.',
        'recommendations': [
          'Apply sunscreen regularly if spending time outdoors',
          'Stay hydrated during outdoor activities',
          'Wear sunglasses and protective clothing',
          'Great weather for exercise and outdoor sports'
        ],
        'icon': Icons.wb_sunny,
        'riskLevel': 'Low Risk',
      };
    } else if (conditionLower.contains('cloud') || conditionLower.contains('overcast')) {
      return {
        'level': 'Cloudy',
        'color': Colors.blueGrey,
        'description': 'Cloudy conditions with reduced direct sunlight. Still suitable for most outdoor activities.',
        'recommendations': [
          'UV rays can still penetrate clouds - use sunscreen',
          'Comfortable temperature for extended outdoor activities',
          'Good conditions for photography and sightseeing',
          'May be cooler than sunny conditions'
        ],
        'icon': Icons.cloud,
        'riskLevel': 'Very Low Risk',
      };
    } else if (conditionLower.contains('rain') || conditionLower.contains('shower')) {
      return {
        'level': 'Rainy',
        'color': Colors.blue,
        'description': 'Wet conditions requiring protective gear. Indoor activities recommended.',
        'recommendations': [
          'Use umbrella or waterproof clothing',
          'Drive carefully - roads may be slippery',
          'Consider indoor exercise alternatives',
          'Good time for indoor activities and rest'
        ],
        'icon': Icons.grain,
        'riskLevel': 'Moderate Risk',
      };
    } else if (conditionLower.contains('storm') || conditionLower.contains('thunder')) {
      return {
        'level': 'Stormy',
        'color': Colors.red,
        'description': 'Severe weather conditions. Stay indoors for safety.',
        'recommendations': [
          'Stay indoors and avoid outdoor activities',
          'Avoid using electronic devices during lightning',
          'Keep away from windows and tall objects',
          'Emergency preparedness recommended'
        ],
        'icon': Icons.bolt,
        'riskLevel': 'High Risk',
      };
    }

    return {
      'level': condition.toUpperCase(),
      'color': Colors.blue,
      'description': 'Current weather conditions as reported by local weather services.',
      'recommendations': [
        'Check current weather conditions before outdoor activities',
        'Dress appropriately for current conditions',
        'Stay informed about weather changes',
      ],
      'icon': Icons.wb_cloudy,
    };
  }

  /// Air quality description information
  Map<String, dynamic> getAirQualityDescriptionInfo(String? description) {
    if (description == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'Air quality description unavailable.',
        'recommendations': ['Check local air quality monitoring stations'],
        'icon': Icons.help_outline,
      };
    }

    final descLower = description.toLowerCase();
    
    if (descLower.contains('good')) {
      return {
        'level': 'Good Air Quality',
        'color': Colors.green,
        'description': 'Air quality is satisfactory and air pollution poses little or no risk.',
        'recommendations': [
          'Perfect conditions for outdoor activities',
          'Great time for exercise and sports',
          'Enjoy fresh air and outdoor recreation',
          'No special precautions needed'
        ],
        'icon': Icons.check_circle,
        'riskLevel': 'No Risk',
      };
    } else if (descLower.contains('moderate')) {
      return {
        'level': 'Moderate Quality',
        'color': Colors.yellow[700],
        'description': 'Air quality is acceptable. Sensitive individuals may experience minor issues.',
        'recommendations': [
          'Most people can enjoy outdoor activities',
          'Sensitive individuals should limit prolonged outdoor exertion',
          'Monitor symptoms if you have respiratory conditions',
          'Generally safe for normal activities'
        ],
        'icon': Icons.info,
        'riskLevel': 'Low Risk',
      };
    } else if (descLower.contains('unhealthy')) {
      return {
        'level': 'Unhealthy Quality',
        'color': Colors.red,
        'description': 'Air quality is unhealthy. Everyone may experience health effects.',
        'recommendations': [
          'Limit outdoor activities, especially strenuous exercise',
          'Keep windows closed and use air purifiers',
          'Wear masks when going outside',
          'Sensitive groups should stay indoors'
        ],
        'icon': Icons.warning,
        'riskLevel': 'High Risk',
      };
    }

    return {
      'level': description,
      'color': Colors.blue,
      'description': 'Current air quality conditions as measured by environmental monitoring stations.',
      'recommendations': [
        'Check air quality index for specific health guidance',
        'Monitor local air quality reports',
        'Adjust outdoor activities based on conditions',
      ],
      'icon': Icons.air,
    };
  }

  /// Data source information
  Map<String, dynamic> getSourceInfo(String? source) {
    if (source == null) {
      return {
        'level': 'Unknown Source',
        'color': Colors.grey,
        'description': 'Data source information unavailable.',
        'recommendations': ['Verify data source reliability'],
        'icon': Icons.help_outline,
      };
    }

    // Handle OpenWeatherMap specifically
    if (source.toLowerCase().contains('openweather')) {
      return {
        'level': 'OpenWeatherMap',
        'color': Colors.blue,
        'description': 'Air quality data provided by OpenWeatherMap, which aggregates data from multiple environmental monitoring stations and satellite observations.',
        'recommendations': [
          'Data updated hourly with current air quality measurements',
          'Covers PM2.5, PM10, NO2, SO2, O3, CO, and NH3 pollutants',
          'Uses WHO air quality guidelines for health classifications',
          'Combines ground stations with satellite data for accuracy',
          'Trusted by developers and environmental apps worldwide'
        ],
        'icon': Icons.verified,
        'riskLevel': 'Verified API Provider',
        'zones': 'OpenWeatherMap collects data from over 10,000 weather stations globally and combines it with satellite observations for comprehensive air quality monitoring.',
      };
    }

    return {
      'level': source,
      'color': Colors.blue,
      'description': 'This data is provided by $source, a verified environmental monitoring service that collects real-time measurements.',
      'recommendations': [
        'Data is updated regularly throughout the day',
        'Measurements follow international standards',
        'Cross-reference with multiple sources when possible',
        'Contact source directly for detailed methodology'
      ],
      'icon': Icons.verified,
      'riskLevel': 'Trusted Source',
    };
  }

  /// PM2.5 pollutant information
  Map<String, dynamic> getPM25Info(double? pm25) {
    if (pm25 == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'PM2.5 measurement unavailable.',
        'recommendations': ['Check local air quality monitoring for PM2.5 levels'],
        'icon': Icons.help_outline,
      };
    }

    if (pm25 <= 12) {
      return {
        'level': 'Good (0-12 μg/m³)',
        'color': Colors.green,
        'description': 'PM2.5 particles are fine particulate matter smaller than 2.5 micrometers. Current levels are within WHO guidelines for healthy air.',
        'recommendations': [
          'Safe for all outdoor activities',
          'No special precautions needed',
          'Great air quality for exercise',
          'Perfect conditions for sensitive individuals'
        ],
        'icon': Icons.check_circle,
        'riskLevel': 'No Risk',
      };
    } else if (pm25 <= 35) {
      return {
        'level': 'Moderate (12-35 μg/m³)',
        'color': Colors.yellow[700],
        'description': 'PM2.5 levels are acceptable but may pose minor risks for very sensitive individuals.',
        'recommendations': [
          'Generally safe for most people',
          'Sensitive individuals should monitor symptoms',
          'Consider reducing prolonged outdoor exertion',
          'Good ventilation indoors recommended'
        ],
        'icon': Icons.info,
        'riskLevel': 'Low Risk',
      };
    } else if (pm25 <= 55) {
      return {
        'level': 'Unhealthy for Sensitive (35-55 μg/m³)',
        'color': Colors.orange,
        'description': 'PM2.5 levels may cause health effects for sensitive groups including children, elderly, and those with heart/lung conditions.',
        'recommendations': [
          'Sensitive groups should limit outdoor activities',
          'Reduce prolonged or heavy outdoor exertion',
          'Keep windows closed, use air purifiers',
          'Wear N95 masks if going outside'
        ],
        'icon': Icons.warning,
        'riskLevel': 'Moderate Risk',
      };
    } else {
      return {
        'level': 'Unhealthy (55+ μg/m³)',
        'color': Colors.red,
        'description': 'PM2.5 levels are unhealthy for all groups. Everyone should limit outdoor activities.',
        'recommendations': [
          'Avoid outdoor activities when possible',
          'Keep windows and doors closed',
          'Use air purifiers with HEPA filters',
          'Wear N95 or P100 masks when outside'
        ],
        'icon': Icons.dangerous,
        'riskLevel': 'High Risk',
      };
    }
  }

  /// PM10 pollutant information
  Map<String, dynamic> getPM10Info(double? pm10) {
    if (pm10 == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'PM10 measurement unavailable.',
        'recommendations': ['Check local air quality monitoring for PM10 levels'],
        'icon': Icons.help_outline,
      };
    }

    if (pm10 <= 20) {
      return {
        'level': 'Good (0-20 μg/m³)',
        'color': Colors.green,
        'description': 'PM10 particles are coarse particulate matter smaller than 10 micrometers. Current levels are within WHO guidelines.',
        'recommendations': [
          'Safe for all outdoor activities',
          'No respiratory concerns',
          'Great conditions for exercise',
          'Excellent air quality'
        ],
        'icon': Icons.check_circle,
        'riskLevel': 'No Risk',
      };
    } else if (pm10 <= 50) {
      return {
        'level': 'Moderate (20-50 μg/m³)',
        'color': Colors.yellow[700],
        'description': 'PM10 levels are acceptable but may cause minor issues for very sensitive individuals.',
        'recommendations': [
          'Generally safe for most activities',
          'Monitor air quality if sensitive to dust',
          'Consider indoor exercise if very sensitive',
          'Acceptable for normal outdoor activities'
        ],
        'icon': Icons.info,
        'riskLevel': 'Low Risk',
      };
    } else {
      return {
        'level': 'Unhealthy (50+ μg/m³)',
        'color': Colors.red,
        'description': 'PM10 levels exceed recommended guidelines and may cause respiratory irritation.',
        'recommendations': [
          'Limit outdoor activities if sensitive to dust',
          'Keep windows closed during high PM10 periods',
          'Use air filtration indoors',
          'Consider masks for sensitive individuals'
        ],
        'icon': Icons.warning,
        'riskLevel': 'Moderate Risk',
      };
    }
  }

  /// NO2 pollutant information
  Map<String, dynamic> getNO2Info(double? no2) {
    if (no2 == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'NO₂ measurement unavailable.',
        'recommendations': ['Check local air quality monitoring for nitrogen dioxide levels'],
        'icon': Icons.help_outline,
      };
    }

    if (no2 <= 40) {
      return {
        'level': 'Good (0-40 μg/m³)',
        'color': Colors.green,
        'description': 'Nitrogen dioxide levels are within safe ranges. NO₂ is primarily from vehicle emissions and power plants.',
        'recommendations': [
          'Safe for all outdoor activities',
          'No respiratory concerns from NO₂',
          'Good air quality overall',
          'Normal outdoor exercise is safe'
        ],
        'icon': Icons.check_circle,
        'riskLevel': 'No Risk',
      };
    } else if (no2 <= 100) {
      return {
        'level': 'Moderate (40-100 μg/m³)',
        'color': Colors.yellow[700],
        'description': 'NO₂ levels are elevated but generally acceptable. May affect individuals with respiratory sensitivities.',
        'recommendations': [
          'Most people can continue normal activities',
          'Those with asthma should monitor symptoms',
          'Avoid exercising near heavy traffic',
          'Consider indoor alternatives if sensitive'
        ],
        'icon': Icons.info,
        'riskLevel': 'Low Risk',
      };
    } else {
      return {
        'level': 'Unhealthy (100+ μg/m³)',
        'color': Colors.red,
        'description': 'NO₂ levels are unhealthy and may cause respiratory problems, especially for sensitive groups.',
        'recommendations': [
          'Limit outdoor activities near traffic',
          'Keep windows closed during peak traffic hours',
          'Use public transport to reduce emissions',
          'Sensitive individuals should stay indoors'
        ],
        'icon': Icons.warning,
        'riskLevel': 'High Risk',
      };
    }
  }

  /// SO2 (Sulfur Dioxide) pollutant information
  Map<String, dynamic> getSO2Info(double? so2) {
    if (so2 == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'SO₂ measurement unavailable.',
        'recommendations': ['Check local air quality monitoring for sulfur dioxide levels'],
        'icon': Icons.help_outline,
      };
    }

    if (so2 <= 20) {
      return {
        'level': 'Good (0-20 μg/m³)',
        'color': Colors.green,
        'description': 'Sulfur dioxide levels are safe. SO₂ comes from burning fossil fuels and industrial processes.',
        'recommendations': [
          'Safe for all outdoor activities',
          'No respiratory concerns from SO₂',
          'Good air quality overall',
          'Normal outdoor exercise is safe'
        ],
        'icon': Icons.check_circle,
        'riskLevel': 'No Risk',
      };
    } else if (so2 <= 80) {
      return {
        'level': 'Moderate (20-80 μg/m³)',
        'color': Colors.yellow[700],
        'description': 'SO₂ levels are elevated. May cause throat irritation in sensitive individuals.',
        'recommendations': [
          'Most people can continue normal activities',
          'Those with asthma should monitor symptoms',
          'Avoid areas near industrial emissions',
          'Consider indoor alternatives if sensitive'
        ],
        'icon': Icons.info,
        'riskLevel': 'Low Risk',
      };
    } else {
      return {
        'level': 'Unhealthy (80+ μg/m³)',
        'color': Colors.red,
        'description': 'SO₂ levels are unhealthy. Can cause respiratory irritation and breathing difficulties.',
        'recommendations': [
          'Limit outdoor exposure',
          'Stay away from industrial areas',
          'Keep windows closed',
          'Sensitive individuals should stay indoors',
          'Use air purifiers if available'
        ],
        'icon': Icons.warning,
        'riskLevel': 'High Risk',
      };
    }
  }

  /// O3 (Ozone) pollutant information
  Map<String, dynamic> getO3Info(double? o3) {
    if (o3 == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'O₃ measurement unavailable.',
        'recommendations': ['Check local air quality monitoring for ozone levels'],
        'icon': Icons.help_outline,
      };
    }

    if (o3 <= 60) {
      return {
        'level': 'Good (0-60 μg/m³)',
        'color': Colors.green,
        'description': 'Ozone levels are safe. Ground-level ozone forms from pollutants reacting in sunlight.',
        'recommendations': [
          'Safe for all outdoor activities',
          'No respiratory concerns from ozone',
          'Good air quality overall',
          'Perfect for outdoor exercise'
        ],
        'icon': Icons.check_circle,
        'riskLevel': 'No Risk',
      };
    } else if (o3 <= 120) {
      return {
        'level': 'Moderate (60-120 μg/m³)',
        'color': Colors.yellow[700],
        'description': 'Ozone levels are moderate. May affect unusually sensitive individuals.',
        'recommendations': [
          'Most people can exercise outdoors',
          'Reduce prolonged outdoor exertion',
          'Those with lung disease should limit outdoor activities',
          'Exercise during morning hours when ozone is lower'
        ],
        'icon': Icons.info,
        'riskLevel': 'Low Risk',
      };
    } else {
      return {
        'level': 'Unhealthy (120+ μg/m³)',
        'color': Colors.red,
        'description': 'Ozone levels are unhealthy. Can cause breathing problems and lung irritation.',
        'recommendations': [
          'Limit outdoor activities, especially exercise',
          'Exercise indoors or early morning',
          'Children and adults with lung disease should avoid outdoor activities',
          'Reduce time spent outdoors'
        ],
        'icon': Icons.warning,
        'riskLevel': 'High Risk',
      };
    }
  }

  /// CO (Carbon Monoxide) pollutant information
  Map<String, dynamic> getCOInfo(double? co) {
    if (co == null) {
      return {
        'level': 'Unknown',
        'color': Colors.grey,
        'description': 'CO measurement unavailable.',
        'recommendations': ['Check local air quality monitoring for carbon monoxide levels'],
        'icon': Icons.help_outline,
      };
    }

    if (co <= 4400) {
      return {
        'level': 'Good (0-4400 μg/m³)',
        'color': Colors.green,
        'description': 'Carbon monoxide levels are safe. CO is colorless, odorless gas from incomplete fuel combustion.',
        'recommendations': [
          'Safe for all outdoor activities',
          'No health concerns from CO',
          'Good air quality overall',
          'Normal outdoor activities are safe'
        ],
        'icon': Icons.check_circle,
        'riskLevel': 'No Risk',
      };
    } else if (co <= 9400) {
      return {
        'level': 'Moderate (4400-9400 μg/m³)',
        'color': Colors.yellow[700],
        'description': 'CO levels are elevated. Generally acceptable but may affect those with heart conditions.',
        'recommendations': [
          'Most people can continue normal activities',
          'Those with heart disease should limit strenuous activities',
          'Avoid exercising near heavy traffic',
          'Well-ventilated areas are preferable'
        ],
        'icon': Icons.info,
        'riskLevel': 'Low Risk',
      };
    } else {
      return {
        'level': 'Unhealthy (9400+ μg/m³)',
        'color': Colors.red,
        'description': 'CO levels are unhealthy. Can reduce oxygen delivery to organs and tissues.',
        'recommendations': [
          'Limit outdoor exposure near traffic',
          'Avoid prolonged outdoor activities',
          'Those with heart disease should stay indoors',
          'Ensure good ventilation indoors',
          'Seek medical attention if experiencing symptoms'
        ],
        'icon': Icons.warning,
        'riskLevel': 'High Risk',
      };
    }
  }
}