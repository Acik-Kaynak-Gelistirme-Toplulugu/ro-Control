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

// Birden fazla sinyalden geçerli grafik oturumu tespit eder.
// type "wayland", "x11" veya "unknown" doner.
SessionInfo detectSessionInfo();
QString detectSessionType();

} // namespace SessionUtil
