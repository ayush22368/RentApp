import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/property_constants.dart';

class AvailabilityBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const AvailabilityBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    IconData iconData;

    switch (status) {
      case PropertyConstants.statusAvailable:
        textColor = AppTheme.statusAvailable;
        bgColor = AppTheme.statusAvailable.withValues(alpha: 0.12);
        iconData = Icons.check_circle_rounded;
        break;
      case PropertyConstants.statusLimited:
        textColor = AppTheme.statusLimited;
        bgColor = AppTheme.statusLimited.withValues(alpha: 0.14);
        iconData = Icons.timelapse_rounded;
        break;
      case PropertyConstants.statusRented:
        textColor = AppTheme.statusUnavailable;
        bgColor = AppTheme.statusUnavailable.withValues(alpha: 0.12);
        iconData = Icons.do_not_disturb_on_rounded;
        break;
      case PropertyConstants.statusUnavailable:
      default:
        textColor = AppTheme.statusInactive;
        bgColor = AppTheme.statusInactive.withValues(alpha: 0.12);
        iconData = Icons.pause_circle_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: isCompact ? 12 : 14,
            color: textColor,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
