#pragma once

#include <QString>
#include <QStringList>

namespace SessionUtil {

struct SessionInfo {
  QString type = QStringLiteral("unknown");
  QString source;
  QStringList evidence;
  bool isCertain = false;
};

// Detect the effective desktop graphics session from multiple signals.
// Returns "wayland" or "unknown".
SessionInfo detectSessionInfo();
QString detectSessionType();

} // namespace SessionUtil
